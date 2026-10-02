# Douyin Guest — bản thử cá nhân 0.13.0

Douyin **40.6.0/build406019/arm64**, iPhone 15/iOS18.5. Ký/cài bằng Sideloadly.

Sửa tình trạng tự dịch tab AI đứng ở thông báo chờ: diagnostics 0.12 ghi 198 lần không đọc được nguồn và chưa ghi nhận request dịch. Bản này đọc trực tiếp renderer Markdown legacy/V2 đã kiểm ABI, fallback sang view của comment-AI controller nếu contentVC trống. Chưa xác định renderer thực tế trên iPhone chỉ từ diagnostics cũ.

Mở bình luận → **Phân tích AI**. Nội dung gốc vẫn hiện và cuộn được trong lúc chờ. Cache hiển thị ngay; nguồn legacy báo hoàn tất được dịch ngay; nguồn khác chờ 0,75 giây không đổi. Timer 0,25 giây chạy cả khi cuộn. Sau 20 giây không đọc được chữ sẽ báo lỗi cụ thể và nút **Đọc lại**.

Tối đa một request dịch tự động mỗi lần vào tab, không tự retry. Bình luận thường và chuyển Bản gốc/Tiếng Việt không gọi dịch. Cache tối đa 32 bản/2 MiB; nguồn mới hoặc thử lại thủ công có thể phát sinh phí. Rời tab/đóng controller/chuyển nền hủy công việc; Google vẫn có thể tính phí request đã nhận. Phân tích gốc giữ nguyên và tiếp tục dùng làm ngữ cảnh hỏi đáp Gemini.

**IPA cá nhân có nhúng API key theo yêu cầu: giữ riêng.** Key được đưa vào khi đóng gói cục bộ; GitHub/CI chỉ dùng key giả. Nội dung AI đang mở được gửi tới Google để dịch, không kèm lịch sử chat.

`dist/Douyin-40.6.0-Guest-0.13.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`; SHA-256 `af8fdfdbe0f72d3ae9f8f029416ad5fbe49cd77008c184e7d8ee205c21ffca74`.

Đã đạt 20 Python, Foundation hooks, 29 Gemini, 36 translation và 142 UIKit checks bằng mock. Fixture xác minh typed ivars không có UILabel con, contentVC trống, native completion, cache và timer khi cuộn; chưa thay thế nghiệm thu Douyin trên máy thật. Các lỗi Featured/Tips/phát nền/xoay/search trước đó vẫn cần xử lý riêng.

[CI](https://github.com/phucdinhIA/Douyin/actions/runs/36995139017) · [Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.13.md) · [Test iPhone](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json) · [Giao diện dịch](docs/evidence/ui-gemini-translation-0.13.0.png).
