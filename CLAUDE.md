# CLAUDE.md — Trợ lý đi làm (Commute Assistant)

File này dành cho coding agent (Claude Code hoặc tương tự). Đọc hết file này và `docs/PLAN.md` trước khi làm bất cứ việc gì.

## Sản phẩm là gì

App Android cá nhân (1 người dùng) giúp chủ app đi làm bằng **xe máy** ở **TP.HCM** đúng giờ:

- So sánh các **tuyến mẫu** của người dùng (ghi lại từ GPS chuyến đi thật — người dùng hay chặt hẻm nên tuyến KHÔNG khai báo bằng điểm đi qua), đề xuất tuyến cho từng đoạn và **giờ xuất phát muộn nhất** theo lịch đi lại trong `docs/PLAN.md` (có điểm dừng giữa đường).
- Gửi **thông báo đẩy** trước giờ đi; bấm thông báo là mở **Google Maps** dẫn đường (app KHÔNG tự dẫn đường).
- Tự ghi lại chuyến đi thật (GPS) để học thói quen và hiệu chỉnh dự đoán.
- Cảnh báo mưa, triều cường và điểm ngập trên tuyến.

App làm theo **2 giai đoạn lớn** (chi tiết trong `docs/PLAN.md`):

- **Giai đoạn A — không API kẹt xe, không billing Google.** Số phút đi đường học từ GPS chuyến đi thật (trung vị, không cộng dư; đoạn chưa có dữ liệu dùng số phút ban đầu `legs.default_min`, người dùng sửa được). Google chỉ dùng qua **URL dẫn đường** (không key). KHÔNG gọi bất kỳ API nào của Google Maps Platform (Routes API, Maps SDK…).
- **Giai đoạn B — có API kẹt xe.** Chỉ bắt đầu khi người dùng đã gắn billing. Thêm Routes API (và bản đồ trong app nếu cần), kết hợp với dữ liệu đã học.

Người dùng đi xe máy, **không thể thao tác điện thoại khi đang chạy**. Mọi thiết kế phải ưu tiên: một chạm trước khi đi, không cần chạm gì trong lúc chạy.

## Những điều KHÔNG làm

- KHÔNG tự xây dẫn đường từng ngã rẽ. Dẫn đường luôn chuyển sang Google Maps qua URL.
- KHÔNG đặt Google Routes API key trong app. Chỉ server giữ key này.
- KHÔNG lưu lâu dài polyline / chỉ dẫn trả về từ Google (điều khoản Google Maps Platform). Chỉ lưu số tóm tắt (phút, mét). Polyline chỉ dùng tạm để hiển thị hoặc tính toán rồi bỏ.
- KHÔNG commit bất kỳ secret nào (API key, service account, token). Dùng `.dev.vars`, `wrangler secret`, `--dart-define`, và đảm bảo các file này nằm trong `.gitignore`.
- KHÔNG dùng `flutter_background_geolocation` (cần license trả phí cho bản release Android).
- KHÔNG thêm package/dịch vụ trả phí. Mọi thứ phải chạy trong gói miễn phí.
- KHÔNG thêm package ngoài danh sách bên dưới mà không hỏi người dùng trước.

## Công nghệ (đã chốt)

| Phần | Công nghệ |
|---|---|
| App | Flutter (chỉ Android), Dart 3, state management: `riverpod` |
| Bản đồ | **Chỉ giai đoạn B (B3, tùy chọn):** `google_maps_flutter` (Maps SDK for Android). Giai đoạn A không có bản đồ trong app. |
| Mở dẫn đường | `url_launcher` |
| GPS chạy nền | `geolocator` + `flutter_foreground_task` |
| Thông báo | `firebase_core` + `firebase_messaging` (chỉ dùng FCM) |
| Lưu cục bộ | `drift` (SQLite) |
| HTTP | `dio` |
| Server | Cloudflare Workers, TypeScript, router `hono` |
| CSDL server | Cloudflare D1, migration bằng `wrangler d1 migrations` |
| Cron | Cloudflare Workers Cron Triggers |
| Ước lượng số phút | Giai đoạn A: học từ chuyến đi thật (hàm thuần trên server). **Giai đoạn B:** thêm Google Routes API `computeRoutes`, `travelMode: TWO_WHEELER` |
| Thời tiết | Open-Meteo (không cần key) |
| Triều cường | Scrape nhiều nguồn dự báo triều bằng `HTMLRewriter` có sẵn của Workers (không thêm package), quy tắc lịch âm dự phòng |
| Test server | `vitest` + `@cloudflare/vitest-pool-workers` |

## Cấu trúc repo

```
/
├── CLAUDE.md
├── docs/
│   ├── PLAN.md          # kế hoạch theo giai đoạn, checklist task
│   └── TECH_DECISIONS.md  # agent ghi lại quyết định kỹ thuật quan trọng
├── app/                 # Flutter app
└── server/              # Cloudflare Worker
    ├── src/
    ├── migrations/
    ├── test/
    └── wrangler.toml
```

## Quy ước

- **Múi giờ**: mọi tính toán giờ giấc dùng `Asia/Ho_Chi_Minh` (UTC+7). Cron của Cloudflare chạy theo UTC — handler phải tự quy đổi.
- **Ngôn ngữ giao diện**: tiếng Việt. Tên biến, hàm, commit, comment code: tiếng Anh.
- **Xác thực server**: app một người dùng → dùng header `Authorization: Bearer <APP_TOKEN>`. `APP_TOKEN` là secret trên Worker và được truyền vào app bằng `--dart-define=APP_TOKEN=...`. Mọi endpoint (trừ health check) phải kiểm tra token.
- **Chống tốn tiền** (giai đoạn B): server có bộ đếm số lần gọi Routes API theo ngày (lưu D1). Vượt `ROUTES_DAILY_LIMIT` (mặc định 28, theo ngày giờ VN) thì dừng gọi và log lỗi. Hạn mức miễn phí của `TWO_WHEELER` chỉ 1.000 lượt/tháng; chặn cứng thật sự là quota 30 request/ngày đặt trên Google Cloud (xem `docs/TECH_DECISIONS.md`). Mục tiêu: 0 đồng.
- **Logic thuần tách riêng**: thuật toán đề xuất, tính giờ đi, khớp tuyến GPS phải là hàm thuần (không I/O) để test dễ.
- Commit nhỏ, mỗi task một hoặc vài commit, message dạng `feat(server): ...`, `fix(app): ...`.

## Cách làm việc với người dùng

- Làm **từng giai đoạn** theo `docs/PLAN.md`. Hết mỗi giai đoạn: dừng lại, tóm tắt đã làm gì, liệt kê cách người dùng kiểm tra, và chờ xác nhận trước khi sang giai đoạn sau.
- Task đánh dấu **[NGƯỜI]** là việc agent không tự làm được (tạo tài khoản, lấy key, cài lên điện thoại, đi thử ngoài đường). Khi gặp: viết hướng dẫn từng bước rõ ràng cho người dùng, rồi chờ.
- Đánh dấu `[x]` vào checklist trong `docs/PLAN.md` khi xong task.
- Nếu tài liệu Google/Cloudflare thực tế khác với giả định trong PLAN (tên field, giới hạn, giá) → tin tài liệu chính thức, ghi lại vào `docs/TECH_DECISIONS.md`, báo người dùng.
- Không chắc thì hỏi. Đừng đoán những thứ ảnh hưởng tới chi phí hoặc bảo mật.

## Memory Bank

Always loaded:
- @memory-bank/projectbrief.md
- @memory-bank/activeContext.md

Read on demand (only when the task touches it):
- `memory-bank/systemPatterns.md`: architecture, patterns, module boundaries
- `memory-bank/techContext.md`: stack, commands, build and environment
- `memory-bank/decisions.md`: before proposing an alternative approach
- `memory-bank/progress.md`: planning, status questions

After a significant change, run the memory-update command. Never record what the code already shows. Trust the code when the memory bank disagrees with it.
