# Trạng thái 0.18.1-test

IPA `Douyin-40.6.0-0.18.1-SUBTITLES-PRIVATE-TEST.ipa` đã đóng gói sau khi các bước CI đạt. Source `7998308bc5d78a605e450077b27a3f510cdd013e`; library SHA-256 `4e50eb6cea1e63e61666388632b041f98a1c99ef44187cdf07cf4728aeaa944a`; IPA SHA-256 `ddb08e263315ac5014d66d100ec700edebc501a2ffb18b251cc238e1ea8135ad`; kích thước 705,006,639 byte.

| Kiểm tra | Kết quả |
|---|---|
| Python đóng gói | 21 đạt |
| Gemini / dịch AI | 29 / 38 đạt |
| Media/ASR/source/cache | 229 đạt, gồm 128 biến thể mốc thật |
| UIKit iPhone 15 Simulator / iOS 18.2 | 219 đạt, không overflow theo fixture |
| Nova-3 thật | Fixed Mandarin nhận 35 từ/13,538 giây và 197 từ/67,78 giây; stereo kênh đầu rỗng/kênh sau 34 từ |
| TTS trong thư viện mới | Không có mã tạo giọng, endpoint, Nam Minh, Vbee hoặc đổi tốc độ theo giọng |
| Đối chiếu IPA độc lập | 5,632 mục, 0 mismatch; core và background modes gốc giữ nguyên |
| Douyin 0.18.1 trên iPhone thật | Chưa nghiệm thu |

Diagnostics 0.18 chỉ chứng minh ba lần HTTP 200 rồi thất bại; chưa có phản hồi/video cụ thể để quy một nguyên nhân duy nhất. Các lỗi bộ đọc kênh/mốc và thông báo gộp đã tái hiện bằng fixture; tự đoán ngôn ngữ sai được tái hiện bằng API thật và không được đưa vào bản giao. Khi nguồn có audio nhưng ASR vẫn rỗng, app báo đúng trạng thái và dừng sau phục hồi hữu hạn.

Các mốc chính được giữ từ ASR. Phân trang bản Việt giữ trong khoảng câu gốc; vị trí từng từ dịch chưa được forced-align. Nguồn/CDN, hạn mức, dialect, nhạc át lời và thời gian backend vẫn ảnh hưởng kết quả. Phát nền giữ cơ chế trước đã được người dùng xác nhận; chưa kiểm tra thiết bị thật cho bản này.

[Chi tiết](../PLAN-0.18.1.md) · [Ảnh phụ đề ngắn](ui-captions-0.18.1.png) · [Ảnh trang phụ đề dài](ui-captions-long-0.18.1.png) · [API thật](0.18.1-service-probes.json) · [Validation](validation-0.18.1.json) · [Nghiệm thu](../DEVICE_TESTS.md) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37105020512).
