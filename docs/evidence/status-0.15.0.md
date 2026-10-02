# Trạng thái 0.15.0-test

Đã sửa đường vào phụ đề/GTX và đóng gói bản thử riêng. Chạm 4 lần vào video bật pipeline; pause đến khi track hoàn tất. Lỗi giữ pause và có nút bỏ qua. GTX đọc thêm model ô bình luận, phạm vi window và có đường vào menu.

`dist/Douyin-40.6.0-0.15.0-iPhone15-FOUR-TAPS-PRIVATE-TEST.ipa`; 704,944,764 byte. SHA-256 `0291eecc939c0b0fd47aa5cc88a25c81cdaa70451d8a0cfc3b09f1b08ea8ab5a`. Source `ab44048ab94a964d33d2aec435e9edf3dd548eda`.

| Kiểm tra | Kết quả |
|---|---|
| iPhone 0.14 | Người dùng báo phụ đề/GTX không chạy; GTX source unavailable 4 lần, chưa thấy request phụ đề |
| Routing/điều khiển 0.15 | Bốn chạm, player nhúng/lifecycle bỏ qua/lớp phủ, pause/ready/error/skip/cancel/background đã qua fixture |
| GTX 0.15 | Model/label, render sibling, wrapper 0-size, clipping/offscreen; cache/429/thử lại thủ công đã qua fixture |
| GTX thật | Probe Windows trả 429, chưa xác nhận dịch thành công trong lượt này; không phải test transport iPhone |
| CI | [Run 37011642974](https://github.com/phucdinhIA/Douyin/actions/runs/37011642974); 21 Python/29 Gemini/36 AI/49 media/184 UIKit đạt |
| IPA | 5,631 mục đối chiếu, 0 mismatch; main/localized display name Douyin |
| Nghiệm thu | Douyin thật trên iPhone cho hai chức năng mới vẫn cần kiểm tra; dịch AI được người dùng xác nhận trước đó |

[Kế hoạch](../PLAN-0.15.md) · [Test](../DEVICE_TESTS.md) · [Validation](validation-0.15.0.json) · [Lịch sử 0.14](status-0.14.0.md). Featured/Tips, phát nền, xoay/search không có bằng chứng sửa mới trong bản này.
