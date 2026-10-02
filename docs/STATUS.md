# Trạng thái 0.14.0-test

Đã đóng gói **Douyin** với phụ đề Việt theo nút bấm và dịch bình luận GTX. Dịch phân tích AI 0.13 đã được người dùng xác nhận hoạt động và giữ nguyên.

`dist/Douyin-40.6.0-0.14.0-iPhone15-SUBTITLES-PRIVATE-TEST.ipa`; 704,937,925 byte. SHA-256 `b09c82dbfe1a244d3680141145f80558944973e6a41787e03333f04f4b538a35`. Source `93997c6986d6290ec1ceef45ad6d216cc3f0f635`.

| Hạng mục | Kết quả |
|---|---|
| Phụ đề | Apify videoUrl → Nova-3 Mandarin → Gemini Việt; ID/thời gian kiểm tra riêng |
| Video ngắn | Nhóm đầu 8 cue, sau 16 cue; ưu tiên vị trí phát, hiện từng nhóm, cache |
| Bình luận | GTX theo dòng được chọn; giữ nguồn, loại tên/AI/view ẩn, cache riêng |
| Giao diện | Nút opt-in, hủy/tắt/hiện; pause/seek/loop, đổi model/chuyển nền đã qua fixture |
| API thật | Mẫu 67,8 giây và 45 phút nhận dạng được; 15/594 cue dịch đủ sau kiểm tra và các lần thử thủ công |
| CI | [Run 37005881752](https://github.com/phucdinhIA/Douyin/actions/runs/37005881752), 21 Python/29 Gemini/36 AI translation/49 media/161 UIKit đạt |
| IPA | 5,631 mục readback/hash, 0 mismatch, core gốc giữ nguyên; tên app/localized Douyin |
| Máy thật | Phụ đề và GTX mới chưa nghiệm thu trên iPhone; dịch AI 0.13 được người dùng xác nhận |

Hai run đầu không đạt strict compile: signed comparison trong UI và malformed-array test với generic Objective-C. Đã sửa, các assertions được giữ. Sau run thành công đầu, sửa hiển thị title nút và tách cache GTX; bản bàn giao dùng run cuối.

[Kế hoạch](PLAN-0.14.md) · [Nghiên cứu](MEDIA-0.14.md) · [Test](DEVICE_TESTS.md) · [Validation](VALIDATION.json) · [Lịch sử](evidence/status-0.13.0.md).

Featured/Tips, phát nền, xoay và guest search trước đó vẫn cần xử lý/kiểm thử riêng; phiên bản này không có bằng chứng mới cho các lỗi đó. Phụ đề mới không thay đổi xác thực Douyin.
