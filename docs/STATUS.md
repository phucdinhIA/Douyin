# Trạng thái 0.13.0-test

**Đã đóng gói bản sửa đọc nội dung AI rỗng và bỏ thời gian chờ cố định. Cần nghiệm thu tự dịch trên iPhone.**

`dist/Douyin-40.6.0-Guest-0.13.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`, 704,898,703 byte. SHA-256 `af8fdfdbe0f72d3ae9f8f029416ad5fbe49cd77008c184e7d8ee205c21ffca74`. Source `a9577829b3b46883360b37d011c097d02336d0a6`.

| Hạng mục | Kết quả |
|---|---|
| Lỗi 0.12 | 198 lần capture rỗng, chưa ghi nhận request dịch; renderer thực tế chưa xác định |
| Capture | Typed Objective-C ivars legacy/V2 đã kiểm ABI; fallback đúng owner khi contentVC trống |
| Thời điểm dịch | Cache ngay; legacy complete ngay; còn lại 750ms không đổi, không fixed entry delay |
| Lấy mẫu | 250ms/common run-loop modes; timeout 20s báo capture rỗng cụ thể |
| UI | Giữ nguồn gốc hiện/cuộn trong lúc chờ, tự chuyển bản dịch khi ready nếu chưa chọn ngôn ngữ |
| Chi phí/hủy | Một request tự động/entry, không tự retry; cache/cancel/stale checks giữ nguyên |
| CI | [Run 36995139017](https://github.com/phucdinhIA/Douyin/actions/runs/36995139017): 20 Python, Foundation hooks, 29 Gemini, 36 translation, 142 UIKit đạt |
| Archive | 5,630 mục readback/hash; 0 mismatch; binary core gốc giữ nguyên |
| Máy thật | Chưa xác nhận tự dịch 0.13 trên iPhone; cần theo dõi counters capture mới |

[Kế hoạch](PLAN-0.13.md) · [Test](DEVICE_TESTS.md) · [Validation](VALIDATION.json) · [UI](evidence/ui-gemini-translation-0.13.0.png) · [Lịch sử](evidence/status-0.12.0.md).

V2/Serval vẫn dùng heuristic ổn định, chưa có tín hiệu hoàn tất đã xác minh. Giới hạn nguồn 24.000 đơn vị UTF-16; chỉ renderer trong cây view comment-AI, không đọc app-wide payload hoặc giả phiên Douyin. Các lỗi feed/phát nền/xoay/guest trước đó vẫn cần nghiệm thu riêng. Diagnostics không ghi nguồn hay key.
