# PLAN.md — Kế hoạch xây dựng Trợ lý đi làm

Đặt file này tại `docs/PLAN.md`. Đọc `CLAUDE.md` trước.

Ký hiệu: **[AGENT]** agent tự làm · **[NGƯỜI]** người dùng phải làm, agent viết hướng dẫn rồi chờ.

App chia **2 giai đoạn lớn** (chốt 2026-11-12, xem `docs/TECH_DECISIONS.md`):

- **A — Không API kẹt xe, không billing Google.** Số phút đi đường học từ GPS chuyến đi thật. Google chỉ dùng qua **URL dẫn đường** (không cần key).
- **B — Có API kẹt xe.** Gắn billing, dùng Routes API `TWO_WHEELER`, kết hợp với dữ liệu đã học ở A.

---

## Lịch đi lại của người dùng (chốt 2026-11-13)

Ngày làm việc: Thứ 2–Thứ 6. Tọa độ thật nằm trong `server/seed.local.json` (gitignored); `server/seed.example.json` là mẫu với tọa độ giả.

| Kế hoạch | Lộ trình | Ràng buộc giờ | App làm gì |
|---|---|---|---|
| **Sáng** (`morning`) | Nhà → **Cửa Hàng** (dừng ~2') → Công ty — **một chuyến, 2 phần** | tới Cửa Hàng **trước 08:30**; tới Công ty **trước 08:45** | Tính giờ đi muộn nhất (lấy giờ sớm hơn của 2 ràng buộc), nhắc trước 5' |
| **Chiều 1** (`evening_1`) | Công ty → Cửa Hàng — 1 phần | không có; bắt đầu từ 18:00 | Đề xuất tuyến nhanh nhất lúc tan làm |
| **Chiều 2** (`evening_2`) | Cửa Hàng → Nhà — 1 phần | đi lúc **21:30** | Gửi thông báo lúc **21:25** |

Thói quen hiện tại: rời nhà 08:15–08:20 → mục tiêu là đề xuất khớp thói quen, không cộng dư.

Thông số ước lượng (chốt):

| Thông số | Giá trị |
|---|---|
| Cách ước lượng | **trung vị** số phút thực tế |
| Dự phòng (`buffer_min`) | **0** phút |
| Dừng ở Cửa Hàng buổi sáng | **2** phút ban đầu, sau đó học từ GPS |
| Số phút ban đầu (chưa có chuyến) | Nhà → Cửa Hàng **10'**, Cửa Hàng → Công ty **13'**; chiều: tạm dùng số của chiều ngược lại |
| Nhắc trước giờ đi | **5** phút |

---

## Khái niệm

- **place**: điểm cố định — `home`, `work`, `stop` (Cửa Hàng), mỗi điểm có `radius_m`.
- **plan**: một kế hoạch đi trong ngày (`morning`, `evening_1`, `evening_2`), gồm 1+ **leg** theo thứ tự.
- **leg**: một phần đường giữa 2 place, có thể có `arrive_by` (giờ phải tới) và `stop_after_min` (dừng ở cuối phần trước khi đi tiếp).
- **template** (tuyến mẫu): một cách đi cụ thể của một leg, **ghi lại từ trace GPS** của chuyến đi thật (không khai báo bằng điểm đi qua — đường chặt hẻm không mô tả được). Trace là dữ liệu GPS của chính người dùng, được phép lưu (khác polyline của Google).
- **trip**: một chuyến đi thật (một plan); **trip_leg**: thời gian thật của từng leg trong chuyến, khớp với một template.

---

## Tổng quan kiến trúc

### Giai đoạn lớn A

```
[App Flutter Android] ──► Google Maps URL (dẫn đường, không key, không billing)
   │  drift: trace GPS thô của mọi chuyến (giữ trên máy, ghi từ A1)
   │  HTTPS + Bearer APP_TOKEN
   ▼
[Cloudflare Worker (hono)] ──► Open-Meteo (mưa)
   │        │                ──► Trang dự báo triều (scrape, nhiều nguồn)
   │        └─ Cron: tính giờ đi + nhắc (mỗi 5 phút trong cửa sổ), scrape triều (1 lần/ngày/nguồn)
   ▼
[Cloudflare D1]
   │
   └─► FCM HTTP v1 ──► thông báo về app
```

### Giai đoạn lớn B (thêm vào A)

```
[Cloudflare Worker] ──► Google Routes API (key chỉ ở server, quota 30/ngày)
[App] ──► Maps SDK for Android (tùy chọn, hiển thị bản đồ)
```

Dẫn đường: app luôn mở URL Google Maps, không tự dẫn đường.

---

## Mô hình dữ liệu (D1)

### Giai đoạn lớn A

```sql
places(id TEXT PK, kind TEXT CHECK(kind IN ('home','work','stop')), name TEXT,
       lat REAL, lng REAL, radius_m INTEGER DEFAULT 100)

plans(id TEXT PK,                    -- 'morning' | 'evening_1' | 'evening_2'
       name TEXT, direction TEXT CHECK(direction IN ('to_work','to_home')),
       window_start TEXT NULL,       -- 'HH:MM' bắt đầu cửa sổ kiểm tra / đề xuất
       depart_at TEXT NULL,          -- 'HH:MM' giờ đi cố định (evening_2 = '21:30')
       active INTEGER DEFAULT 1)

legs(id TEXT PK, plan_id TEXT, seq INTEGER,
       from_place_id TEXT, to_place_id TEXT,
       arrive_by TEXT NULL,          -- 'HH:MM' phải tới to_place trước giờ này
       stop_after_min REAL NULL,     -- dừng ở to_place trước leg kế tiếp (sáng: 2)
       default_min REAL,             -- số phút ban đầu khi chưa có chuyến
       UNIQUE(plan_id, seq))

templates(id TEXT PK, leg_id TEXT, name TEXT,
       trace_json TEXT,              -- trace GPS đã rút gọn (~30 m/điểm), dữ liệu của người dùng
       distance_m INTEGER, created_from_trip_id TEXT NULL,
       active INTEGER DEFAULT 1, created_at TEXT)

settings(id INTEGER PK CHECK(id=1),
       work_days TEXT DEFAULT '1,2,3,4,5',  -- 1=Thứ 2
       buffer_min INTEGER DEFAULT 0,
       notify_before_min INTEGER DEFAULT 5,
       explore_enabled INTEGER DEFAULT 1,   -- gợi ý thử tuyến mẫu ít đi
       fcm_token TEXT)

trips(id TEXT PK, plan_id TEXT, started_at TEXT, ended_at TEXT,
       actual_min REAL,
       predicted_min REAL NULL,      -- A: số phút đã học lúc xuất phát
       rain_mm REAL NULL, tide_alert INTEGER NULL)

trip_legs(trip_id TEXT, leg_id TEXT,
       template_id TEXT NULL,        -- NULL = không khớp tuyến mẫu nào
       started_at TEXT, ended_at TEXT, actual_min REAL,
       stop_min REAL NULL,           -- thời gian dừng thật ở cuối leg (sáng: Cửa Hàng)
       matched_by TEXT,              -- 'trace' | 'manual' | 'none'
       PRIMARY KEY(trip_id, leg_id))

notify_state(date TEXT, plan_id TEXT, last_template_ids TEXT,
       last_latest_departure TEXT, count INTEGER, PRIMARY KEY(date, plan_id))

tide_forecast(date TEXT, station TEXT,          -- 'phu_an' | 'nha_be'
       peak_time TEXT, peak_level_m REAL,
       source TEXT,                             -- tên nguồn, hoặc 'lunar_rule'
       fetched_at TEXT, PRIMARY KEY(date, station, source))

source_health(source TEXT PK, last_ok_at TEXT, last_error_at TEXT, last_error TEXT)

alley_notes(id TEXT PK, lat REAL, lng REAL, radius_m INTEGER DEFAULT 50,
       kind TEXT,                    -- 'dead_end' | 'flood' | 'market' | 'other'
       active_from TEXT NULL, active_to TEXT NULL,  -- 'HH:MM', NULL = cả ngày
       rain_only INTEGER DEFAULT 0, note TEXT)
```

Tuyến mẫu nào đi qua ghi chú nào: tính bằng hàm thuần từ `templates.trace_json`, không lưu bảng riêng.

### Thêm ở giai đoạn lớn B

```sql
checks(id INTEGER PK, checked_at TEXT, leg_id TEXT,
       departure_time TEXT, google_min REAL, google_static_min REAL, distance_m INTEGER)

api_usage(date TEXT PK, routes_calls INTEGER DEFAULT 0)
```

Không có bảng nào lưu polyline của Google.

---

## API server

Tất cả cần `Authorization: Bearer APP_TOKEN`, trừ `GET /health`.

| Method | Path | Mô tả | Giai đoạn |
|---|---|---|---|
| GET | `/health` | `{ok:true}` | A2 |
| GET/PUT | `/places` | nhà, công ty, Cửa Hàng | A2 |
| GET/PUT | `/plans` | kế hoạch + các leg (giờ hẹn, dừng, số phút ban đầu) | A2 |
| GET/PUT | `/settings` | cài đặt | A2 |
| GET | `/today?plan=morning` | đề xuất: tuyến mẫu từng leg, số phút, giờ đi muộn nhất, giờ tới từng điểm, `nav_url` | A2 (số ban đầu), A3 (số đã học) |
| POST | `/trips` | tóm tắt chuyến + từng leg (A2); kèm trace rút gọn để tạo tuyến mẫu mới (A3) | A2 |
| GET/PUT/DELETE | `/templates` | tuyến mẫu: xem, đổi tên, tắt, xoá | A3 |
| POST | `/device` | lưu FCM token | A3 |
| GET | `/tide` | dự báo triều đã tổng hợp + tình trạng nguồn | A4 |
| CRUD | `/alley-notes` | ghi chú hẻm / điểm ngập | A4 |
| GET | `/stats` | thống kê | A5 |
| POST | `/legs/:id/preview` | Google: phút + mét (+ polyline tạm, KHÔNG lưu) | B3 |

### URL mở dẫn đường (dùng từ A2)

```
https://www.google.com/maps/dir/?api=1
  &destination=<lat>,<lng>
  &waypoints=<lat>,<lng>          -- chỉ các place bắt buộc (sáng: Cửa Hàng)
  &travelmode=two-wheeler
  &dir_action=navigate
```

- Bỏ `origin` để Google Maps dùng vị trí hiện tại. Không cần API key, không cần billing.
- **Không** đưa điểm của tuyến mẫu vào link: Google Maps không đi theo được đường hẻm; người dùng tự đi theo trí nhớ, Google Maps chỉ để xem kẹt xe và giờ đến (phương án (a), chốt 2026-11-13).
- Sáng: đích Công ty, waypoint Cửa Hàng. Chiều 1: đích Cửa Hàng. Chiều 2: đích Nhà.

### Gọi Routes API (chỉ giai đoạn lớn B, đã xác minh tài liệu — xem `TECH_DECISIONS.md`)

```
POST https://routes.googleapis.com/directions/v2:computeRoutes
X-Goog-Api-Key: <ROUTES_API_KEY>
X-Goog-FieldMask: routes.duration,routes.staticDuration,routes.distanceMeters

{
  "origin": {"location": {"latLng": {...}}},
  "destination": {"location": {"latLng": {...}}},
  "travelMode": "TWO_WHEELER",
  "routingPreference": "TRAFFIC_AWARE",
  "departureTime": "<RFC3339 tương lai, hoặc bỏ trống>",
  "languageCode": "vi",
  "regionCode": "VN"
}
```

- Gọi theo **leg** (from → to), không theo tuyến mẫu (Google không đi được hẻm).
- Chỉ thêm `routes.polyline.encodedPolyline` vào field mask ở preview.
- Mỗi lần gọi phải kiểm tra rồi tăng `api_usage.routes_calls`.

---

# GIAI ĐOẠN LỚN A — Không API kẹt xe, không billing

**Thứ tự (chốt 2026-11-16):** ghi chuyến đi thật **trước tiên** (A1), vì dữ liệu cần vài tuần mới đủ; server, tuyến mẫu, học và nhắc giờ làm song song trong lúc dữ liệu tích lũy.

## A0 — Chuẩn bị

- [x] **[AGENT]** Tạo cấu trúc repo theo `CLAUDE.md`, `.gitignore`, `docs/TECH_DECISIONS.md`.
- [x] **[AGENT]** Tạo trang HTML tĩnh / danh sách link mẫu để test URL dẫn đường.
- [x] **[NGƯỜI]** Cung cấp tọa độ nhà, công ty, Cửa Hàng, các mốc khác, giờ hẹn và lịch đi lại (đã lưu `server/seed.local.json`).
- [x] **[AGENT]** Tạo link thử L1–L4 với tọa độ thật (L4: 6 điểm để thử giới hạn số waypoint).
- [x] **[NGƯỜI]** Cài Flutter SDK + Android SDK (agent viết hướng dẫn nếu chưa có), bật USB debugging trên điện thoại. Báo `flutter --version` và hãng / đời máy / bản Android (để viết hướng dẫn tắt tối ưu pin). → Flutter 3.44.8; máy OPPO CPH2159, Android 13 (2026-11-16).

**Điều kiện qua giai đoạn:** build được app Flutter lên điện thoại thật. (Các việc chuẩn bị khác chuyển xuống phase cần đến chúng: thử link L1–L4 → A2; Cloudflare, `node -v` → A2; Firebase → A3; khảo sát triều, quy tắc lịch âm → A4.)

---

## A1 — Ghi chuyến đi thật (làm đầu tiên, chỉ app, chưa cần server)

Mục tiêu: cài app và đi làm bình thường ngay, không cần chạm gì; mọi chuyến được ghi đầy đủ trên máy để các phase sau học.

- [x] **[AGENT]** Khởi tạo Flutter project (Android only), riverpod, `drift`, `geolocator`, `flutter_foreground_task`. **Không** dùng `google_maps_flutter` ở giai đoạn A.
- [x] **[AGENT]** Màn **Địa điểm & lịch** (lưu cục bộ trong `drift`): nhà / công ty / Cửa Hàng (dán tọa độ hoặc link chia sẻ Google Maps), bán kính, nút “Dùng vị trí hiện tại”. (Ngày làm việc / giờ hẹn: A2, đồng bộ từ server.)
- [x] **[AGENT]** Hàm thuần `parseLatLng(text)` nhận tọa độ thuần và các dạng link Google Maps phổ biến + test.
- [x] **[AGENT]** Bảng `drift` cục bộ: `local_trips(id, plan_id NULL, started_at, ended_at, start_reason 'auto'|'manual', end_reason, synced)`, `trace_points(trip_id, t, lat, lng, speed_mps, accuracy_m, heading, altitude)`. Lưu **mọi điểm thô** (không rút gọn) để sau còn phân tích tốc độ từng khúc đường.
- [x] **[AGENT]** Nút lớn **“Sẵn sàng”** trên màn chính (bấm lúc chuẩn bị đi, còn ở nhà / công ty / Cửa Hàng). Bấm → khởi động foreground service (`flutter_foreground_task`, loại `location`; khởi động từ app đang mở nên hợp lệ với Android 14+), thông báo cố định “Sẵn sàng — sẽ tự ghi khi bạn đi”. Không có service chạy thường trực, không cửa sổ giờ.
- [x] **[AGENT]** Hai trạng thái của service:
  - **Chờ đi**: lấy vị trí ~10 giây/lần; khi **rời bán kính place đang đứng** (hoặc đi xa > 150 m nếu không ở place nào) → chuyển sang **Ghi**. Giờ xuất phát = điểm cuối cùng còn trong bán kính. Quá 60 phút chưa đi → tự hủy, báo “Đã hủy chờ”.
  - **Ghi**: `geolocator` mỗi ~5 giây hoặc ~20 m (đủ dày để phân biệt hẻm).
- [x] **[AGENT]** Trên thông báo cố định: nút **“Hủy”** (khi Chờ đi) / **“Dừng”** (khi Ghi). Màn chính có thêm nút “Ghi ngay” cho trường hợp đã lỡ đi mà quên bấm.
- [x] **[AGENT]** Tự kết thúc khi: ở trong `radius_m` của **đích cuối của plan** ≥ 60 giây; HOẶC bấm dừng; HOẶC quá 3 giờ. Dừng ở Cửa Hàng buổi sáng (place giữa) không kết thúc chuyến. Chuyến < 2 phút hoặc < 300 m → bỏ (đi lòng vòng gần nhà).
- [x] **[AGENT]** Hàm thuần `detectPlan(trace, places, now)`: đoán chuyến thuộc plan nào theo place đầu / cuối / giữa và giờ; không khớp → `plan_id = NULL` (vẫn lưu).
- [x] **[AGENT]** Hàm thuần `splitTraceByLegs(trace, plan, places)`: cắt trace tại các place giữa; tính `actual_min` từng leg và `stop_min` (thời gian đứng yên trong bán kính place giữa). Không ghé place giữa → leg đó không khớp, vẫn có tổng chuyến. Test với trace giả.
- [x] **[AGENT]** Màn **Chuyến đi**: danh sách chuyến (ngày, plan, giờ đi – giờ đến, tổng phút, phút từng leg, dừng Cửa Hàng, tốc độ trung bình, số điểm GPS, độ chính xác GPS trung bình). Sửa tay plan của chuyến, xóa chuyến.
- [x] **[AGENT]** Xuất toàn bộ dữ liệu (GPX + JSON) để sao lưu và phân tích. Ghi vào thư mục riêng của app (`Android/data/<package>/files/exports`), copy qua cáp USB; không thêm `share_plus` (người dùng chọn mặc định, 2026-11-16).
- [x] **[AGENT]** Màn hướng dẫn **tắt tối ưu pin**, có nút mở cài đặt pin; ghi chú riêng cho hãng máy của người dùng (Xiaomi, Oppo, Vivo, Samsung…). Xin quyền vị trí “khi dùng ứng dụng” (đủ vì service khởi động khi app đang mở) và quyền thông báo, giải thích bằng tiếng Việt.
- [x] **[AGENT]** Màn chính hiện trạng thái (Tắt / Chờ đi / Đang ghi) để biết app còn sống.
- [x] **[AGENT]** Giữ **toàn bộ** trace thô trên máy (không tự xóa); hiện dung lượng đã dùng.
- [ ] **[NGƯỜI]** Cài APK, nhập 3 địa điểm, tắt tối ưu pin. Mỗi lần chuẩn bị đi: bấm **“Sẵn sàng”** rồi đi bình thường. Sau 2–3 ngày: báo chuyến nào bị mất, không tự bắt đầu / không tự dừng, pin tốn bao nhiêu. **Tiếp tục ghi suốt các phase sau.**

**Điều kiện qua giai đoạn:** ≥ 90% chuyến đi làm thật được ghi đầy đủ chỉ với một chạm “Sẵn sàng” trước khi đi; không cần chạm gì khi đang chạy.

---

## A2 — Server, kế hoạch trong ngày, mở dẫn đường, đồng bộ chuyến

### Chuẩn bị

- [ ] **[NGƯỜI]** Tạo tài khoản Cloudflare (gói Free). Chạy `node -v`, báo kết quả (wrangler cần Node hiện hành).
- [ ] **[NGƯỜI]** Mở L1–L4 trên điện thoại Android, báo lại: vào thẳng dẫn đường không, đúng chế độ xe máy không, đi qua đủ điểm không. (L4 chỉ để tham khảo — link thật chỉ có Cửa Hàng + đích.)

### Server

- [ ] **[AGENT]** Khởi tạo Worker (hono, TypeScript), `wrangler.toml`, binding D1, migration đầu tiên với schema giai đoạn A.
- [ ] **[AGENT]** Script seed: đọc `server/seed.local.json` (hoặc `seed.example.json`) → tạo `places`, `plans`, `legs`, `settings`.
- [ ] **[AGENT]** Middleware xác thực Bearer token.
- [ ] **[AGENT]** Endpoint `/places`, `/plans`, `/settings`, `/today`.
- [ ] **[AGENT]** `POST /trips`: lưu `trips`, `trip_legs` (chưa khớp tuyến mẫu → `matched_by = 'none'`); idempotent theo `trip.id` để app gửi lại an toàn.
- [ ] **[AGENT]** Hàm thuần `computeRecommendation(now, plan, legEstimates, settings)`:
  - Thời gian tích lũy theo thứ tự leg (gồm `stop_after_min`).
  - Với mỗi leg có `arrive_by`: `departure_i = arrive_by_i − (tổng phút từ lúc xuất phát tới hết leg i) − buffer_min`.
  - `latest_departure` = **giờ sớm nhất** trong các `departure_i`; trả kèm leg nào đang quyết định.
  - Plan có `depart_at` (chiều 2): `latest_departure = depart_at`.
  - Plan không có ràng buộc (chiều 1): chỉ đề xuất tuyến mẫu nhanh nhất cho mỗi leg.
  - Trả về: tuyến mẫu chọn cho từng leg, `estimated_min`, `latest_departure`, giờ tới dự kiến từng place, `status` ∈ {`early`, `leave_soon`, `leave_now`, `late`}.
- [ ] **[AGENT]** Hàm thuần `buildNavigationUrl(destination, requiredStops)` + test.
- [ ] **[AGENT]** Test: auth, `computeRecommendation` (2 ràng buộc buổi sáng — ràng buộc nào quyết định, có dừng; `depart_at`; không ràng buộc), `POST /trips` gửi trùng, validate input.
- [ ] **[NGƯỜI]** `wrangler login`, tạo D1, đặt secret `APP_TOKEN`, chạy seed, deploy theo hướng dẫn agent.

### App

- [ ] **[AGENT]** dio, `--dart-define` cho `API_BASE_URL`, `APP_TOKEN`. Địa điểm & lịch đồng bộ với `/places`, `/plans` (server là nguồn chính; bản cục bộ dùng khi mất mạng).
- [ ] **[AGENT]** Đồng bộ chuyến: gửi tóm tắt chuyến + từng leg lên `POST /trips`, **kể cả mọi chuyến đã ghi từ A1**; mất mạng → xếp hàng, gửi lại sau. Không gửi trace thô.
- [ ] **[AGENT]** Màn **Hôm nay**: tự chọn plan theo giờ và vị trí (trước 12h → `morning`; chiều, ở gần công ty → `evening_1`; ở gần Cửa Hàng hoặc sau 20:30 → `evening_2`; đổi tay được). Hiện: **giờ đi muộn nhất** (chữ to), giờ tới Cửa Hàng / Công ty dự kiến, ràng buộc nào quyết định, nút lớn **“Bắt đầu”** (bắt đầu ghi chuyến của plan đó + mở Google Maps).
- [ ] **[AGENT]** Nút lớn, chữ to, dùng được một tay khi đeo găng (vùng chạm tối thiểu 56dp).
- [ ] **[NGƯỜI]** Cài bản mới, dùng 2–3 ngày.

**Điều kiện qua giai đoạn:** các chuyến từ A1 đã lên server; mở app → thấy giờ đi của plan hiện tại → bấm “Bắt đầu” → Google Maps dẫn đường tới đúng đích (sáng: qua Cửa Hàng) và chuyến được ghi.

---

## A3 — Tuyến mẫu, học từ chuyến đi và tự nhắc giờ đi

### Tuyến mẫu

- [ ] **[AGENT]** Hàm thuần `simplifyTrace(trace)` (~30 m/điểm) và `matchTemplate(segment, templates)`: khớp nếu ≥ 85% điểm của đoạn nằm trong 40 m quanh trace mẫu **và** ngược lại (tránh khớp đoạn con); nhiều mẫu khớp → mẫu có tỉ lệ cao nhất; không khớp → `none`. Ngưỡng ghi vào `TECH_DECISIONS.md`, chỉnh trên dữ liệu thật đã ghi từ A1. Test với trace giả (2 hẻm song song cách 60 m phải phân biệt được).
- [ ] **[AGENT]** **Gom tuyến mẫu từ dữ liệu cũ**: chạy trên mọi chuyến đã ghi từ A1, gom các leg giống nhau thành nhóm → đề xuất danh sách tuyến mẫu để người dùng đặt tên (làm khi đã dừng xe). Gắn `template_id` cho các `trip_legs` cũ.
- [ ] **[AGENT]** Phát hiện tuyến mới cho chuyến sau này: leg không khớp mẫu nào → sau khi chuyến kết thúc, gửi thông báo “Hôm nay bạn đi đường mới — lưu thành tuyến mẫu?”.
- [ ] **[AGENT]** Màn **Tuyến mẫu**: danh sách theo leg, số chuyến, số phút trung vị; đổi tên, tắt, xoá, gộp 2 mẫu thực ra là một.
- [ ] **[AGENT]** Server: `POST /trips` nhận thêm `template_id` / trace rút gọn khi tạo tuyến mẫu mới; `/templates`: xem, đổi tên, tắt, xoá; gộp mẫu (chuyển `trip_legs` sang mẫu còn lại).

### Học và nhắc giờ đi (server)

- [ ] **[AGENT]** Hàm thuần `estimateDuration(tripLegs, template, weekday, departureTime)`:
  - Gom chuyến theo ô **thứ trong tuần × khung 15 phút** giờ xuất phát leg.
  - Ô có < 3 chuyến → gộp rộng dần: cùng khung 15 phút mọi ngày làm việc → khung 1 giờ → mọi chuyến của mẫu.
  - Ước lượng = **trung vị** `actual_min`.
  - Mẫu chưa có chuyến nào ngoài chuyến tạo mẫu → dùng chuyến đó; leg chưa có mẫu → `legs.default_min`.
  - Trả kèm: số chuyến dùng, mức gộp, chuyến gần nhất (hiện “dữ liệu cũ” nếu > 21 ngày).
- [ ] **[AGENT]** Hàm thuần `estimateStop(tripLegs, leg)`: trung vị `stop_min` (cần ≥ 3), không thì `legs.stop_after_min`.
- [ ] **[AGENT]** `computeRecommendation` dùng số đã học; chọn mẫu nhanh nhất cho mỗi leg.
- [ ] **[AGENT]** Gợi ý thử tuyến mẫu ít đi: nếu `explore_enabled`, còn dư ≥ 10 phút so với `latest_departure`, và có mẫu ít dữ liệu / dữ liệu cũ → gợi ý mẫu đó (không thay đề xuất chính).
- [ ] **[AGENT]** Hàm thuần `shouldNotify(prevState, rec, now, settings)`:
  - Nhắc chính lúc `latest_departure − notify_before_min` (sáng ~08:10–08:13; chiều 2 = 21:25).
  - Gửi thêm khi: tuyến mẫu đề xuất đổi; `latest_departure` lệch ≥ 3 phút; chuyển sang `leave_now`. Tối đa 4 thông báo / plan / ngày.
  - Chiều 1: 1 thông báo lúc `window_start` (18:00).
- [ ] **[AGENT]** Cron trigger `*/5 * * * *`: quy đổi giờ VN → ngày làm việc và trong cửa sổ của plan → tính đề xuất → `shouldNotify` → gửi FCM → cập nhật `notify_state`. Ngoài cửa sổ: thoát ngay.
- [ ] **[AGENT]** Module `fcm.ts`: ký JWT RS256 bằng Web Crypto, cache access token, gửi FCM HTTP v1. Payload `data` chứa `nav_url`, `plan_id`.
- [ ] **[AGENT]** Endpoint `POST /device`.
- [ ] **[AGENT]** Test: `estimateDuration` (đủ / thiếu dữ liệu, gộp, trung vị), `estimateStop`, `shouldNotify`, quy đổi múi giờ, cửa sổ qua nửa đêm UTC.
- [ ] **[NGƯỜI]** Tạo Firebase project **mới, tách khỏi project Google Cloud `throttlepath`**, gói Spark, tắt Google Analytics. Lấy `google-services.json` cho app và service account JSON → secret `FCM_SERVICE_ACCOUNT`.

### App

- [ ] **[AGENT]** Tích hợp `firebase_messaging`, xin quyền thông báo (Android 13+), gửi token lên `/device`.
- [ ] **[AGENT]** Bấm thông báo → mở thẳng `nav_url` và ghi chuyến của đúng plan (cả khi app đang tắt; tương đương bấm “Sẵn sàng”: chờ đi rồi tự ghi).
- [ ] **[AGENT]** Màn **Cài đặt**: ngày làm việc, dự phòng, nhắc trước, bật/tắt gợi ý thử tuyến.
- [ ] **[AGENT]** Màn Hôm nay hiện nguồn số phút (“ban đầu” / “học từ N chuyến”), nhãn “dữ liệu cũ”.
- [ ] **[NGƯỜI]** Đặt tên các tuyến mẫu được gom; dùng 1 tuần: tuyến có bị nhận sai không, thông báo có đúng lúc không, giờ đi có khớp thói quen (08:15–08:20) không.

**Điều kiện qua giai đoạn:** tuyến mẫu được nhận đúng; không cần mở app; thông báo tự đến với giờ đi dựa trên dữ liệu thật; bấm vào là dẫn đường và ghi chuyến.

---

## A4 — Mưa, triều cường, điểm ngập

### Chuẩn bị (chuyển từ A0)

- [ ] **[AGENT]** Khảo sát nguồn dự báo triều cường (Đài KTTV khu vực Nam Bộ, Trung tâm Dự báo KTTV quốc gia, …): dữ liệu có ở dạng bảng HTML không (hay chỉ ảnh/PDF), có chặn bot không, điều khoản có cấm thu thập không, trạm nào (Phú An, Nhà Bè), mức báo động I/II/III. Ghi kết quả vào `docs/TECH_DECISIONS.md`.
- [ ] **[AGENT]** Ghi quy tắc dự phòng lịch âm (mùa triều cường, ngày quanh rằm / mùng 1, khung giờ đỉnh triều) vào `docs/TECH_DECISIONS.md` kèm nguồn. Nếu không có nguồn nào scrape được → chỉ dùng quy tắc này, báo người dùng.

### Mưa

- [ ] **[AGENT]** Cron gọi Open-Meteo lượng mưa theo giờ cho TP.HCM; lưu `rain_mm` vào `trips`.
- [ ] **[AGENT]** Hàm thuần `rainPenalty(tripLegs, template)`: phút cộng thêm khi mưa lớn = chênh lệch trung vị giữa chuyến mưa và không mưa (cần ≥ 3 chuyến mưa, không thì giá trị mặc định ghi trong `TECH_DECISIONS.md`).

### Triều cường (scrape nhiều nguồn rồi tổng hợp)

- [ ] **[AGENT]** Mỗi nguồn một module scraper (dùng `HTMLRewriter` có sẵn của Workers, không thêm package), trả cùng dạng `{date, station, peak_time, peak_level_m, source}`. Có fixture HTML để test không cần mạng.
- [ ] **[AGENT]** Mỗi nguồn một cron riêng, lệch giờ nhau, 1 lần/ngày (giữ CPU < 10 ms mỗi lần chạy; tổng cron ≤ 5 trên gói Free).
- [ ] **[AGENT]** Bắt đầu với **2 nguồn chính thức** + **quy tắc lịch âm** (luôn có). Nguồn báo chí: chỉ thêm sau khi 2 nguồn đầu chạy ổn.
- [ ] **[AGENT]** Hàm thuần `aggregateTide(readings)`: bỏ giá trị vô lý (ngoài 0,5–2,5 m); lấy **mức cao nhất** giữa các nguồn còn tốt, theo từng trạm; lệch > 0,2 m giữa các nguồn → log; mọi nguồn lỗi → dùng quy tắc lịch âm.
- [ ] **[AGENT]** Ngưỡng cảnh báo: **từ báo động I** (giá trị cụ thể theo khảo sát ở đầu A4). Lưu ý: chuyến chiều 2 lúc 21:30 có thể trùng đỉnh triều buổi tối.
- [ ] **[AGENT]** Theo dõi `source_health`; nguồn lỗi → gửi FCM “Không đọc được dữ liệu triều từ <nguồn>”, tối đa 1 lần/ngày.

### Điểm ngập và ghi chú hẻm

- [ ] **[AGENT]** App: màn thêm ghi chú (dán tọa độ / link chia sẻ, hoặc “đánh dấu vị trí hiện tại” khi dừng xe), loại, khung giờ, chỉ khi mưa.
- [ ] **[AGENT]** Hàm thuần `templateNoteHits(templateTrace, notes)`: tuyến mẫu đi qua ghi chú nếu trace mẫu đi trong bán kính ghi chú. Không cần polyline Google.
- [ ] **[AGENT]** Server: tuyến mẫu đi qua điểm `flood` VÀ (mưa lớn gần giờ đi HOẶC triều ≥ ngưỡng gần giờ đi) → gắn cảnh báo / hạ hạng; đưa vào `computeRecommendation` và nội dung thông báo.
- [ ] **[AGENT]** Test: `aggregateTide`, quy tắc lịch âm, `rainPenalty`, `templateNoteHits`, quy tắc cảnh báo ngập.
- [ ] **[NGƯỜI]** Đánh dấu các điểm ngập / hẻm cụt trên tuyến của mình; báo lại cảnh báo có đúng không.

**Điều kiện qua giai đoạn:** ngày mưa lớn / triều cường, tuyến mẫu qua điểm ngập bị cảnh báo; scraper hỏng thì người dùng được báo và app vẫn chạy bằng quy tắc lịch âm.

---

## A5 — Tiện ích thêm (làm từng task độc lập)

- [ ] **[AGENT] Thống kê** (`GET /stats` + màn Thống kê): thời gian theo tuyến mẫu × thứ, giờ xuất phát tốt nhất, thời gian dừng Cửa Hàng, biểu đồ đơn giản.
- [ ] **[AGENT] Điểm chậm**: hàm thuần `slowSpots(traces)` gom điểm GPS thô theo ô ~50 m × khung giờ, tìm khúc đường / hẻm lặp lại tốc độ thấp hoặc đứng lâu; màn danh sách điểm chậm (mỗi điểm có link mở vị trí trên Google Maps); so tốc độ các tuyến mẫu theo từng khúc.
- [ ] **[AGENT] Chế độ “Trễ rồi”**: quá `latest_departure` mà chưa bắt đầu chuyến → thông báo tuyến mẫu nhanh nhất + giờ tới dự kiến, nút sao chép tin nhắn “Em đến trễ khoảng X phút”.

### Cân nhắc cho tương lai (chưa lên lịch, người dùng quyết định khi nào làm)

- [ ] **Địa điểm tự do** (đề xuất 2026-11-16, người dùng: "tạm như cũ, cân nhắc làm sau"). Hiện app chỉ có 3 địa điểm cố định (Nhà / Công ty / Cửa Hàng) và 3 plan đi làm; đi tới chỗ khác (vd. về quê) vẫn ghi nhưng không tự dừng khi tới nơi, bị cắt ở 3 giờ, hiện “Không rõ plan”. Hướng mở rộng:
  - Địa điểm thành danh sách tên tùy ý; ghi chuyến giữa 2 địa điểm bất kỳ, đặt tên theo cặp (“Nhà → Quê”); tới địa điểm đã lưu ở lại 60 giây → tự dừng.
  - Học số phút / tuyến mẫu theo **cặp điểm**; lịch đi làm (sáng, chiều 1, chiều 2) chỉ là các cặp điểm có giờ hẹn và nhắc giờ; sau này thêm được lịch khác (vd. “Thứ 7 về quê, tới trước 10:00”).
  - Chuyến tới chỗ chưa lưu: hiện “Nhà → (chỗ mới)”, nút “Lưu điểm cuối thành địa điểm”; nâng giới hạn 3 giờ lên ~12 giờ.
  - Cần đổi: `PlaceKind` cố định → bảng địa điểm tự do, chuyến lưu điểm đi / đến, migration dữ liệu đã ghi; sửa PLAN, CLAUDE.md (phạm vi sản phẩm rộng hơn đi làm), ghi `TECH_DECISIONS.md`. Nên quyết trước A2 nếu muốn schema server theo cặp điểm ngay từ đầu.

---

# GIAI ĐOẠN LỚN B — Có API kẹt xe (gắn billing)

Chỉ bắt đầu khi người dùng đồng ý gắn billing.

## B0 — Chuẩn bị Google Cloud

- [ ] **[NGƯỜI]** Project Google Cloud (`throttlepath`): bật **Routes API** (và **Maps SDK for Android** nếu làm B3), gắn thanh toán.
- [ ] **[NGƯỜI]** **Budget alert** 1 USD; **quota theo ngày** Routes API (Compute Routes) = **30 request/ngày**.
- [ ] **[NGƯỜI]** Tạo `ROUTES_API_KEY` (chỉ Routes API); nếu làm B3: `MAPS_ANDROID_KEY` (chỉ Maps SDK for Android, giới hạn package name + SHA-1 — agent cung cấp lệnh lấy SHA-1).
- [x] **[AGENT]** Script `server/scripts/spike-routes.ts` gọi Routes API `TWO_WHEELER` với 0 và 2 điểm `via`, `departureTime` +30 phút.
- [ ] **[NGƯỜI]** Chạy script, gửi kết quả cho agent.
- [ ] **[AGENT]** Ghi vào `docs/TECH_DECISIONS.md`: `TWO_WHEELER` + `TRAFFIC_AWARE` có hoạt động ở TP.HCM không, so sánh với số phút đã học ở giai đoạn A.

## B1 — Gọi Routes API

- [ ] **[AGENT]** Migration thêm `checks`, `api_usage`.
- [ ] **[AGENT]** Module `routesClient.ts`: gọi Routes API theo leg, parse `duration` / `staticDuration` (`"1234s"`) → phút, kiểm tra và tăng `api_usage` (`ROUTES_DAILY_LIMIT` = 28, theo ngày giờ VN), coi 429 / `RESOURCE_EXHAUSTED` là bình thường, không retry. Fixture JSON để test.
- [ ] **[AGENT]** Cron trong cửa sổ giờ đi gọi Routes API cho các leg của plan sắp tới, lưu `checks`. Ngoài cửa sổ: không gọi. Ngân sách: 3 leg có ràng buộc giờ × ~3 lần/ngày ≈ 9–12 lượt.
- [ ] **[AGENT]** Test: parse duration, giới hạn quota, múi giờ.
- [ ] **[NGƯỜI]** Đặt secret `ROUTES_API_KEY`, deploy.

## B2 — Kết hợp dữ liệu kẹt xe với dữ liệu đã học

- [ ] **[AGENT]** Hệ số kẹt xe hôm nay của leg: `traffic_factor = google_min / google_static_min` (Google đi đường chính, không đi hẻm, nên chỉ dùng **tỉ lệ**, không dùng số phút tuyệt đối).
- [ ] **[AGENT]** Số phút tuyến mẫu = `estimateDuration × f(traffic_factor)`, với `f` học từ chuyến thật (hồi quy đơn giản giữa tỉ lệ kẹt và độ lệch so với trung vị; < 5 chuyến có `checks` → `f(x) = x`, giới hạn 0,8–1,5).
- [ ] **[AGENT]** Mất Google (hết quota / lỗi) → quay về `estimateDuration` của giai đoạn A.
- [ ] **[AGENT]** Màn Hôm nay hiện nguồn số phút (“học + kẹt xe hôm nay” / “học từ chuyến đi”).
- [ ] **[NGƯỜI]** Dùng 1–2 tuần, so sánh độ chính xác với giai đoạn A.

## B3 — Bản đồ trong app (tùy chọn)

- [ ] **[AGENT]** Thêm `google_maps_flutter`, Maps key qua `local.properties` / manifest placeholder.
- [ ] **[AGENT]** Hiện trace tuyến mẫu (dữ liệu của người dùng) và ghi chú trên bản đồ; chọn place / ghi chú bằng chạm; `POST /legs/:id/preview` vẽ polyline Google (chỉ trong bộ nhớ, không lưu).

---

## Ước lượng chi phí (để agent kiểm tra lại)

**Giai đoạn lớn A: 0 đồng, không cần thẻ.** Cloudflare Workers / D1 Free, Firebase Spark (FCM), Open-Meteo không key, Google Maps URL không key. Không gọi bất kỳ API nào của Google Maps Platform (mọi API của nền tảng này đều yêu cầu project có billing, kể cả SKU miễn phí như Maps SDK for Android). Cron `*/5` = 288 lần/ngày, thoát ngay ngoài cửa sổ → xa dưới 100.000 request/ngày của Workers Free.

**Giai đoạn lớn B:** gọi theo leg, ~3 leg có ràng buộc giờ × ~3 lần/ngày ≈ 9–12 lượt/ngày làm việc → ~260 lượt/tháng. **Đã xác minh (2026-11-11):** `TWO_WHEELER` tính theo SKU *Compute Routes Enterprise*, miễn phí **1.000 lượt/tháng**, sau đó 15 USD/1.000. Chặn cứng bằng quota Google Cloud 30 request/ngày (tối đa 930/tháng) + `ROUTES_DAILY_LIMIT` = 28 ở server. Không nâng hạn mức. Maps SDK for Android: miễn phí không giới hạn nhưng cần billing. Chi tiết: `docs/TECH_DECISIONS.md`.
