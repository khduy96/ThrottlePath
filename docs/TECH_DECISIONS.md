# TECH_DECISIONS.md — Quyết định kỹ thuật

Mỗi mục: ngày, quyết định, lý do, hệ quả. Mục mới thêm ở cuối.

---

## 2026-11-11 — Backend: giữ Cloudflare Workers + D1

**Quyết định:** Backend dùng Cloudflare Workers (hono, TypeScript) + D1 + Cron Triggers, gói Free. Firebase chỉ dùng cho FCM (gửi/nhận thông báo đẩy).

**Đã cân nhắc:**

| Phương án | Lý do không chọn |
|---|---|
| Firebase (Firestore + Cloud Functions) | Cloud Functions bắt buộc gói Blaze (gắn thẻ, trả theo mức dùng); không có trần chi tiêu chung — budget alert chỉ gửi email. Trái với ràng buộc "chỉ gói miễn phí" trong CLAUDE.md. |
| Back4app (gói Free) | 25.000 request/tháng, 250 MB DB, 1 GB băng thông, chỉ 1 background job; tài liệu không xác nhận job chạy được mỗi 10 phút; máy chủ chỉ ở Mỹ. |

**Giới hạn gói Free cần nhớ (tra ngày 2026-11-11):**

- Workers: 100.000 request/ngày (reset 00:00 UTC); **10 ms CPU mỗi lần chạy** (HTTP và cron; thời gian chờ mạng không tính); 50 subrequest mỗi lần chạy; 5 Cron Trigger/tài khoản; cron tối đa 15 phút wall-clock; 128 MB RAM.
- D1: 500 MB/DB, 5 GB/tài khoản; 5 triệu dòng đọc và 100.000 dòng ghi mỗi ngày; 50 query mỗi lần chạy. Vượt hạn mức thì query lỗi tới 00:00 UTC, không tính tiền.

**Hệ quả:**

- Giữ CPU mỗi lần chạy dưới 10 ms: cache access token FCM (~1 giờ) thay vì ký JWT RS256 mỗi lần cron; không lấy `polyline` ở `/compare` và cron; tránh parse JSON lớn.
- Đo CPU thực tế bằng `wrangler tail` / số liệu Worker ở Giai đoạn 1–2. Nếu thường xuyên vượt 10 ms → cân nhắc Workers Paid (5 USD/tháng) và hỏi người dùng trước.

**Nguồn:**
- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/d1/platform/limits/
- https://developers.cloudflare.com/d1/platform/pricing/
- https://firebase.google.com/pricing
- https://firebase.google.com/docs/projects/billing/avoid-surprise-bills
- https://www.back4app.com/pricing/backend-as-a-service

---

## 2026-11-11 — Routes API: giữ `TWO_WHEELER`, chặn cứng để 0 đồng

**Bối cảnh:** PLAN giả định Routes API nằm trong hạn mức miễn phí. Xác minh trên trang SKU chính thức cho thấy **"Two-wheeled vehicle routing" thuộc SKU _Routes: Compute Routes Enterprise_**: miễn phí **1.000 lượt/tháng**, sau đó **15 USD / 1.000** (bậc 1.001–100.000). Mỗi request chỉ bị tính một SKU (SKU cao nhất trong các tính năng đã dùng), nên `TRAFFIC_AWARE` (Pro) đi cùng `TWO_WHEELER` vẫn chỉ tính Enterprise.

**Quyết định:** Người dùng yêu cầu **không trả bất kỳ phí nào**. Giữ `TWO_WHEELER` (xe máy, có hỗ trợ ở Việt Nam) và chặn cứng:

| Lớp chặn | Giá trị | Ai thực thi |
|---|---|---|
| Quota theo ngày của Routes API (Compute Routes) trên Google Cloud | **30 request/ngày** → tối đa 930/tháng | Google (vượt quota thì request bị từ chối tới hết ngày, reset 0h giờ Pacific) |
| `ROUTES_DAILY_LIMIT` ở server (bảng `api_usage`) | **28/ngày**, theo ngày giờ VN | Worker |
| Budget alert | 1 USD | Chỉ gửi email, KHÔNG chặn |

Cách tính theo hướng dẫn của Google: hạn mức miễn phí tháng ÷ 31, làm tròn xuống, rồi đặt thấp hơn một chút vì hệ thống quota và billing tách biệt (1.000 ÷ 31 ≈ 32 → 30).

**Đã cân nhắc:** `DRIVE` + `TRAFFIC_AWARE` (SKU Pro, 5.000 lượt miễn phí/tháng): thoải mái hơn nhưng tính theo ô tô (không đi hẻm, thời gian lệch với xe máy). Không chọn; có thể dùng làm phương án dự phòng.

**Hệ quả:**
- Ngân sách ~28 lượt/ngày làm việc: ~3 tuyến × ~4 lần kiểm tra × 2 chiều ≈ 24, còn ~4 cho mở app / preview. Nếu không đủ → giãn cron (15 phút), giảm số lần kiểm tra hoặc số tuyến; **không nâng hạn mức**.
- Server phải kiểm tra `api_usage` TRƯỚC khi gọi, và coi lỗi quota của Google (HTTP 429 / `RESOURCE_EXHAUSTED`) là bình thường, không retry.
- API key Routes phải giới hạn chỉ Routes API (phòng tuyến chính chống lạm dụng; quota là lưới an toàn).

**Các giả định khác của PLAN đã xác minh:**
- Endpoint `POST https://routes.googleapis.com/directions/v2:computeRoutes`, header `X-Goog-FieldMask` bắt buộc; `duration`/`staticDuration` dạng chuỗi `"123s"`; `distanceMeters` số nguyên; tối đa 25 intermediates.
- `routingPreference` chỉ dùng được với `DRIVE` hoặc `TWO_WHEELER`. `via: true` chỉ đặt cho điểm trung gian (đặt cho điểm đầu/cuối thì request lỗi).
- `departureTime` dạng RFC 3339; thời điểm trong quá khứ chỉ được phép với `TRANSIT`, nên script/cron phải luôn gửi giờ tương lai hoặc bỏ trống.
- Việt Nam (VN) có trong danh sách hỗ trợ routing xe hai bánh.
- URL dẫn đường: `travelmode=two-wheeler` hợp lệ (chỉ ở nước có hỗ trợ); `waypoints` ngăn cách bằng `|` (`%7C`), tối đa 3 trên trình duyệt di động, 9 ở nơi khác, và có thể bị bỏ qua trên một số sản phẩm Google Maps; bỏ `origin` + `dir_action=navigate` → dẫn đường từ vị trí hiện tại. **Cần thử trên máy thật** (app Google Maps có tôn trọng waypoints + two-wheeler không).
- Maps SDK for Android: miễn phí không giới hạn (SKU Essentials).

**Nguồn:**
- https://developers.google.com/maps/billing-and-pricing/sku-details/routes
- https://developers.google.com/maps/billing-and-pricing/pricing
- https://developers.google.com/maps/billing-and-pricing/manage-costs
- https://developers.google.com/maps/documentation/routes/reference/rest/v2/TopLevel/computeRoutes
- https://developers.google.com/maps/documentation/routes/reference/rest/v2/Waypoint
- https://developers.google.com/maps/documentation/routes/coverage-two-wheeled
- https://developers.google.com/maps/documentation/urls/get-started

---

## 2026-11-12 — Chia app thành 2 giai đoạn lớn; giai đoạn A không billing, tự học từ chuyến đi

**Quyết định (người dùng chốt):**

| # | Quyết định |
|---|---|
| 1 | Giai đoạn lớn **A: không dùng API kẹt xe**; giai đoạn lớn **B: dùng API kẹt xe** (Routes API `TWO_WHEELER`). |
| 2 | Giai đoạn A **không gắn billing Google** → không gọi Routes API, không dùng Maps SDK for Android / `google_maps_flutter`. |
| 3 | Vẫn dùng Google ở A qua **Google Maps URL** để dẫn đường (không cần key, không cần billing). |
| 4 | Số phút đi đường ở A **học từ GPS chuyến đi thật**: gom theo thứ × khung 15 phút, gộp rộng dần khi thiếu dữ liệu, lấy **p80**. Tuyến < 3 chuyến dùng số **người dùng tự nhập** (`routes.manual_min`). |
| 5 | Có **gợi ý thử tuyến ít đi** khi dư ≥ 15 phút (tắt được trong Cài đặt). |
| 6 | Thông báo vẫn qua **FCM từ server** (không thêm `flutter_local_notifications`). |
| 7 | Không có bản đồ trong app ở A: nhập điểm bằng tọa độ / link chia sẻ từ Google Maps. Bản đồ chuyển sang B3 (tùy chọn). |
| 8 | Dữ liệu triều cường: **scrape nhiều nguồn rồi tổng hợp**. Bắt đầu 2 nguồn chính thức + quy tắc lịch âm dự phòng; lấy **mức cao nhất** giữa các nguồn; cảnh báo **từ báo động I**. |
| 9 | Điểm ngập: người dùng tự đánh dấu (ghi chú hẻm loại `flood`). Tuyến đi qua điểm nào được tính từ **trace GPS chuyến đã đi** trên app, không cần polyline Google. |

**Lý do:**
- Mọi API của Google Maps Platform (kể cả SKU miễn phí) yêu cầu project gắn billing; người dùng chưa muốn gắn thẻ ở giai đoạn này.
- Không có nguồn API miễn phí, chính thức, đọc được bằng máy cho điểm ngập ở TP.HCM; dự báo triều chỉ có trên trang web của cơ quan KTTV → phải scrape.
- Dữ liệu chuyến đi thật đo đúng xe, đúng thói quen của người dùng.

**Đã cân nhắc:**
- Gọi Routes API 1 lần/tuyến để lấy số phút ban đầu: cần billing → bỏ.
- Chờ đủ chuyến mới đề xuất: 2–3 tuần đầu app vô dụng → bỏ, dùng số tự nhập.
- Trung vị thay vì p80: sát thực tế hơn nhưng dễ trễ → chọn p80.
- OpenStreetMap (`flutter_map`) cho bản đồ: package ngoài danh sách → chưa dùng.
- Thông báo cục bộ: cần thêm package, mất khả năng server tổng hợp mưa/triều → giữ FCM.

**Hệ quả:**
- Thứ tự mới: A0 chuẩn bị → A1 MVP → A2 ghi chuyến (đưa lên sớm vì cần dữ liệu để học) → A3 học + nhắc giờ đi → A4 mưa/triều/ngập → A5 tiện ích → B0–B3.
- Schema A thêm `routes.manual_min`, `settings.explore_enabled`, `trips.tide_alert`, bảng `tide_forecast`, `source_health`, `route_note_hits`. `checks` và `api_usage` chỉ tạo ở B1.
- Scraper dùng `HTMLRewriter` có sẵn của Workers (không thêm package); mỗi nguồn một cron riêng để giữ CPU < 10 ms/lần; gói Free tối đa 5 Cron Trigger/tài khoản → tối đa 4 nguồn scrape (1 cron cho tính giờ đi).
- Scrape dễ hỏng khi trang nguồn đổi giao diện: bắt buộc có kiểm tra giá trị hợp lý, `source_health`, báo người dùng qua FCM và quy tắc lịch âm dự phòng.
- **Cần kiểm tra ở A0 (chưa xác minh):** URL và cấu trúc trang các nguồn triều, chặn bot, điều khoản sử dụng, mức báo động cụ thể tại Phú An / Nhà Bè.
- Đính chính mục 2026-11-11: "Maps SDK for Android miễn phí không giới hạn" đúng về giá, nhưng vẫn cần project gắn billing.
- Mục backend 2026-11-11 nhắc endpoint `/compare`: endpoint này đổi thành `GET /today` (giai đoạn A); ở giai đoạn B, cron gọi Routes API vẫn không lấy `polyline`.
- `CLAUDE.md` đã cập nhật: mô tả 2 giai đoạn; `google_maps_flutter` và Routes API ghi rõ chỉ dùng ở giai đoạn B.

---

## 2026-11-13 — Lịch đi lại thật, tuyến mẫu ghi từ GPS, ước lượng sát giờ

**Bối cảnh:** người dùng cung cấp lịch thật và cho biết thường **chặt hẻm** — đi qua rất nhiều hẻm và đường phụ, không mô tả được bằng 1–3 điểm `via`.

**Quyết định (người dùng chốt):**

| # | Quyết định |
|---|---|
| 1 | Bỏ khai báo tuyến bằng điểm đi qua. **Tuyến mẫu (template) ghi lại từ trace GPS** của chuyến thật; leg không khớp mẫu nào → app hỏi “lưu thành tuyến mẫu?”; leg chưa có mẫu → chuyến đầu tự thành mẫu. |
| 2 | Nhận diện tuyến bằng **độ trùng trace** (mặc định ≥ 85% điểm trong 40 m, hai chiều), thay cho `matchRoute` theo waypoint. |
| 3 | Dẫn đường kiểu **(a)**: link Google Maps chỉ chứa place bắt buộc (sáng: Cửa Hàng) và đích; không đưa điểm tuyến mẫu vào link (Google không đi theo được hẻm). Người dùng tự đi theo trí nhớ. |
| 4 | Lịch: **Sáng** Nhà → Cửa Hàng (dừng ~2') → Công ty, một chuyến 2 leg, tới Cửa Hàng trước **08:30** và Công ty trước **08:45**, `latest_departure` = giờ sớm hơn của 2 ràng buộc. **Chiều 1** Công ty → Cửa Hàng từ 18:00, không ràng buộc. **Chiều 2** Cửa Hàng → Nhà lúc **21:30**, nhắc 21:25. Thứ 2–Thứ 6, ngày nào cũng ghé Cửa Hàng. |
| 5 | Ước lượng **trung vị** (thay p80 của mục 2026-11-12), dự phòng **0**, dừng Cửa Hàng **2'** ban đầu rồi học, nhắc trước **5'**. Thói quen thật: rời nhà 08:15–08:20 — người dùng không chấp nhận app cộng dư nhiều. |
| 6 | Bỏ `routes.manual_min` bắt buộc; thay bằng `legs.default_min` (Nhà → Cửa Hàng 10', Cửa Hàng → Công ty 13', chiều tạm dùng số chiều ngược lại), có thể sửa. |

**Đã cân nhắc:**
- Hành trình chia phần, mỗi phần nhiều tuyến khai báo bằng ≤ 3 điểm `via`: không mô tả được đường chặt hẻm → bỏ.
- Dẫn đường (c) đưa 3–9 điểm của trace vào link: Google Maps dễ bắt quay đầu / tính lại → bỏ.
- Coi Tân Thành, vòng xoay Lê Đại Hành là mốc chia phần: không phải mọi tuyến đều qua → chỉ dùng làm điểm tham chiếu (`landmarks` trong seed).
- p80 + dự phòng 5': dư ~8–10' so với thói quen → bỏ.

**Hệ quả:**
- Schema A: `places.kind` thêm `stop`; bảng `routes` thay bằng `plans`, `legs`, `templates` (lưu `trace_json` rút gọn — dữ liệu GPS của người dùng, không phải polyline Google, nên được phép lưu); `trips` + `trip_legs` (`matched_by` = `trace` | `manual` | `none`, có `stop_min`); bỏ `route_note_hits` (tính từ trace mẫu bằng hàm thuần).
- GPS ghi dày hơn (~5 s / ~20 m) để phân biệt hẻm song song; cần đo pin ở A2.
- Lịch sát giờ nên cron nhắc đổi thành `*/5` (288 lần/ngày, thoát ngay ngoài cửa sổ); gửi lại khi `latest_departure` lệch ≥ 3'; gợi ý thử tuyến ít đi khi dư ≥ 10' (thay 15').
- Ràng buộc Công ty 08:45 gần như luôn quyết định giờ đi (Cửa Hàng → Công ty ~12–15'); màn Hôm nay hiển thị ràng buộc nào đang quyết định.
- Giai đoạn B: Routes API gọi theo **leg**, chỉ dùng **tỉ lệ** `duration / staticDuration` làm hệ số kẹt xe nhân vào số phút đã học (Google không đi hẻm nên số phút tuyệt đối không dùng được); ~9–12 lượt/ngày.
- Tọa độ thật lưu ở `server/seed.local.json` (gitignored, `server/*.local.json`); mẫu `server/seed.example.json` dùng tọa độ giả.
- **Cần xác minh ở A0:** giới hạn số waypoint khi app Google Maps mở link (link thử L4 có 6 điểm); ngưỡng khớp trace cần chỉnh sau khi chạy thật ở A2.

---

## 2026-11-16 — Ghi chuyến đi thật trước tiên

**Bối cảnh:** người dùng chỉ ra thứ tự cũ (A0 thử link Google Maps → A1 server + giờ đi bằng số phút ban đầu → A2 mới ghi GPS) làm mất vài tuần không thu được dữ liệu, trong khi ước lượng cần ≥ 3 chuyến mỗi khung giờ.

**Quyết định (người dùng đồng ý):**

| # | Quyết định |
|---|---|
| 1 | **A1 mới = app ghi chuyến đi, chỉ cục bộ, chưa cần server.** Người dùng cài và để app ghi suốt các phase sau. |
| 2 | **Tự động ghi** (mặc định agent chọn, người dùng chưa phản đối): foreground service chạy thường trực, 3 chế độ Nghỉ (ngoài cửa sổ giờ, không GPS) / Canh (trong cửa sổ, vị trí ~1 phút/lần, rời bán kính place xuất phát → ghi) / Ghi (~5 s / ~20 m). Vẫn có nút bấm tay. |
| 3 | Lưu **mọi điểm GPS thô** (lat, lng, thời gian, tốc độ, độ chính xác, hướng, độ cao) trong `drift` và **giữ toàn bộ** trên máy (thay quy tắc xóa sau 30 ngày). Ước tính ~50 KB/chuyến. Server chỉ nhận tóm tắt + trace rút gọn của tuyến mẫu, như cũ. |
| 4 | Thứ tự mới: A0 (chỉ cần build được app) → A1 ghi chuyến → A2 server + Hôm nay + dẫn đường + đồng bộ chuyến cũ → A3 tuyến mẫu (gom từ dữ liệu đã ghi) + học + nhắc → A4 mưa/triều (khảo sát triều chuyển vào đầu A4) → A5 tiện ích (thêm "Điểm chậm": phân tích tốc độ từng khúc đường từ trace thô). |
| 5 | Thử link L1–L4 chuyển sang A2, không còn chặn việc khác; Cloudflare/`node -v` → A2; Firebase → A3. |

**Rủi ro / cần đo ở A1:** Android (nhất là Xiaomi/Oppo/Vivo) có thể giết service thường trực; foreground service loại `location` phải khởi động khi app ở foreground hoặc lúc boot (Android 14+). Đo pin %/ngày; nếu tốn quá → thu hẹp cửa sổ Canh hoặc chỉ ghi bằng nút.

**Package:** xuất file dữ liệu bằng chia sẻ cần package ngoài danh sách (vd. `share_plus`) → hỏi người dùng trước khi thêm.

**Sửa cùng ngày (người dùng chốt):** bỏ service thường trực theo cửa sổ giờ (mục 2 ở trên). Thay bằng nút **“Sẵn sàng”**: người dùng bấm trước khi đi → service bật ở trạng thái **Chờ đi** (vị trí ~10 s/lần) → rời bán kính place đang đứng (hoặc đi xa > 150 m) thì tự chuyển sang **Ghi**; 60 phút chưa đi thì tự hủy. Lý do: một chạm trước khi đi đã chấp nhận được, tiết kiệm pin, và service được khởi động khi app đang mở nên tránh được hạn chế khởi động foreground service `location` từ nền của Android 14+. Từ A3, bấm thông báo nhắc giờ đi tương đương bấm “Sẵn sàng”.

---

## 2026-11-16 — A1: phiên bản và cách làm app ghi chuyến

**Môi trường:** Flutter 3.44.8 stable, Dart 3.12.2, Android SDK 36. `minSdk = 26` (Android 8.0). Package id `com.throttlepath.throttle_path`.

**Package (bản stable mới nhất lúc khởi tạo, `flutter pub add`):** `flutter_riverpod` ^3.5.0, `drift` ^2.35.4, `drift_flutter` ^0.3.1, `geolocator` ^14.1.2, `flutter_foreground_task` ^11.0.3, `path_provider` ^2.1.6; dev: `drift_dev` ^2.35.3, `build_runner` ^2.15.1.
- `drift_flutter` và `path_provider` không có tên riêng trong bảng công nghệ của CLAUDE.md nhưng là phần cài đặt chuẩn của `drift` trên Flutter (mở file SQLite, tìm thư mục app). Không thêm package nào khác.
- Không thêm `share_plus` (người dùng chọn mặc định): xuất GPX + JSON vào `getExternalStorageDirectory()/exports` (thư mục riêng của app), copy qua USB.

**Kiến trúc ghi chuyến:**
- Logic thuần trong `app/lib/domain/`: `recorder_machine.dart` (state machine Tắt → Chờ đi → Ghi, nhận fix GPS / tick / nút bấm, trả action), `trip_analysis.dart` (`detectPlan`, `splitTraceByLegs`, `isTooShort`, `tripStats`), `parse_lat_lng.dart`, `export_format.dart`. Có test trong `app/test/domain/`.
- Service (`app/lib/recorder/recorder_task.dart`) chạy trong isolate riêng của `flutter_foreground_task`, mở **kết nối drift riêng** tới cùng file SQLite (WAL, `busy_timeout`); UI không dùng stream của drift cho bảng chuyến mà làm mới khi service gửi sự kiện. Trạng thái machine lưu bằng `saveData` để service bị hệ thống khởi động lại thì ghi tiếp đúng chuyến; chuyến bị bỏ dở được đóng tại điểm cuối với `end_reason = 'interrupted'`.
- `detectPlan` hiện chỉ dùng place đầu / cuối (đủ phân biệt 3 plan); chưa dùng giờ.
- Quyền vị trí chỉ cần “khi dùng ứng dụng” vì service luôn khởi động khi app đang mở (nút “Sẵn sàng”).
- Kết thúc chuyến tại **giờ vào bán kính đích** (không tính 60 giây chờ xác nhận). Dừng ở place giữa quá 20 phút → kết thúc chuyến tại đó (`long_stop`).

**Build:** project ở ổ D:, pub cache ở ổ C: → Kotlin incremental cache lỗi “Could not close incremental caches”. Đặt `kotlin.incremental=false` trong `app/android/gradle.properties`.

**Đã kiểm tra:** `flutter analyze` sạch; 20 test domain qua; build APK debug; chạy trên emulator Android 12: Sẵn sàng → Chờ đi (GPS chạy), Ghi ngay → thông báo “Đang ghi chuyến đi”, Dừng → service tắt. **Chưa kiểm tra:** tự chuyển Chờ đi → Ghi khi di chuyển thật, tự kết thúc khi tới nơi, pin, OEM tắt app — cần chạy trên máy thật.

## 2026-11-16 — Giao diện: theme riêng, font nhúng, vẽ tuyến từ GPS

**Bối cảnh:** UI A1 dùng Material 3 mặc định (`colorSchemeSeed: teal`), danh sách `ListTile` và chuỗi ghép bằng “·” → nhìn thô. Người dùng yêu cầu làm đẹp toàn bộ.

**Quyết định:**
- Theme theo chế độ sáng/tối của máy, làm kỹ cả hai (`app/lib/ui/theme/app_theme.dart`). Màu chính cam đậm đặt cứng (`#EA5A0C` sáng / `#FF7A2E` tối) vì bảng màu tonal của M3 làm cam thành hồng đào nhạt ở chế độ tối. Màu theo trạng thái (Tắt / Chờ đi / Đang ghi) và theo plan (Sáng / Chiều 1 / Chiều 2) gom trong `ThemeExtension` `AppColors`.
- Font **Be Vietnam Pro** (OFL) nhúng thẳng file `.ttf` trong `app/assets/fonts/` (kèm `OFL.txt`) — **không** dùng package `google_fonts`, không tải font lúc chạy. Số dùng `tabularFigures` để đồng hồ / số phút không nhảy.
- Widget dùng chung trong `app/lib/ui/widgets/` (`common.dart`, `charts.dart`); không thêm package biểu đồ.
- Trang chi tiết chuyến vẽ **trace GPS của chính người dùng** bằng `CustomPainter` (chiếu equirectangular, màu theo tốc độ, vòng tròn địa điểm). Không phải bản đồ Google → hợp lệ ở giai đoạn A (không Maps SDK, không billing).
- Nút chính cao 112dp, rung nhẹ (`HapticFeedback`) khi bấm; giữ nguyên nguyên tắc một chạm.
- Màn hình chính mới chỉ là khung; ở A2 thẻ “Giờ đi muộn nhất” (`/today`) sẽ chen vào giữa phần chào và nút Sẵn sàng.
