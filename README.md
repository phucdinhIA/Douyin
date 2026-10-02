# Douyin Guest — bản thử cá nhân 0.12.0

Douyin **40.6.0/build406019/arm64**, iPhone 15/iOS18.5. Cần ký bằng Sideloadly.

Mở video → bình luận → **tab phân tích AI**: ứng dụng chờ nội dung ổn định rồi tự dịch sang tiếng Việt bằng Gemini 3.5 Flash-Lite. Mở bình luận thường không gọi API dịch. Chọn **Bản gốc / Tiếng Việt** để đối chiếu; **Ask Gemini · Your AI** vẫn mở hỏi đáp với phân tích gốc.

Mỗi lần vào tab có tối đa một yêu cầu dịch tự động. Bản dịch hoàn tất được lưu trên máy (tối đa 32 mục/2 MiB); mở lại cùng nguồn hoặc chuyển ngôn ngữ không gọi lại API. Nguồn mới, mục bị xóa/loại khỏi cache, hoặc thử lại thủ công có thể phát sinh phí. Rời tab/đóng controller/chuyển nền hủy tác vụ; yêu cầu đã tới Google vẫn có thể bị tính phí. Lỗi không tự retry; **Dịch lại** cho thử thủ công.

Nội dung AI được gửi sang Google khi tab AI đang mở, không kèm lịch sử chat. Phân tích gốc của Douyin không bị ghi đè. Chờ 4 giây sau entry và 3 giây không đổi nguồn là heuristic; chưa xác định tín hiệu kết thúc streaming native. Cache chỉ lưu digest nguồn/bản dịch; không lưu API key hay nguyên văn nguồn.

**IPA cá nhân có nhúng API key theo yêu cầu: giữ riêng.** Key được đưa vào khi đóng gói cục bộ; GitHub/CI chỉ dùng key giả.

`dist/Douyin-40.6.0-Guest-0.12.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`; SHA-256 `94f9de96087063cfba96cbe0fde61dbf0269edc30db1dd051f668d572122e192`.

Kiểm tra: 20 Python, Foundation hooks, 29 Gemini, 33 translation contracts, arm64/signature, 136/136 UIKit fixture với mock transport. Người dùng báo hỏi đáp 0.11 có vẻ hoạt động; tự dịch 0.12 cần nghiệm thu trên iPhone. Các lỗi Featured/Tips/phát nền/xoay/search trước đó không được xác nhận đã sửa trong bản này.

[CI](https://github.com/phucdinhIA/Douyin/actions/runs/36991564379) · [Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.12.md) · [Test iPhone](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json) · [Giao diện dịch](docs/evidence/ui-gemini-translation-0.12.0.png).
