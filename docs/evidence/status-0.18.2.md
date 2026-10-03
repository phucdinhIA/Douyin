# Trạng thái 0.18.2-test

Đã đóng gói `Douyin-40.6.0-0.18.2-AUDIO-TIMING-PRIVATE-TEST.ipa` sau kiểm tra. Source `f1c5e2378af32e3cd2758c52a4e4df759910a6a7`; IPA SHA-256 `859b53b4f9e1d0969b3d2a5ccab1a0f4c3856a43157e9f17697378799bb077fe`; library SHA-256 `931fe42919c107f2f672b3188d3366eadbf407ddf9d3af754659228f82f37af9`; 705,009,375 byte.

Lỗi nằm sau HTTP 200 Deepgram và trước Claude, ở điều kiện so audio duration với toàn bộ video. Diagnostics người dùng khoanh vùng 11 native upload thất bại; hai lượt remote đã hoàn tất. API thật chứng minh video 19,533333 giây/audio 13,537007 giây trả ASR 13,537 giây với 34 từ nhưng điều kiện cũ từ chối. Chưa có số liệu từng video người dùng để khẳng định tất cả thuộc cùng kiểu container.

| Kiểm tra | Kết quả |
|---|---|
| Python | 21 đạt |
| Gemini / dịch AI | 29 / 38 đạt |
| Media/source/ASR/cache | 243 đạt |
| UIKit iPhone 15 / iOS 18.2 | 220 đạt; không overflow theo fixture |
| API thật | 2 mẫu kiểm tra riêng duration và audio bắt đầu muộn |
| IPA độc lập | 5,632 mục, 0 mismatch |
| iPhone thật iOS 18.5 | Chưa nghiệm thu bản mới |

Shortcut native-file của phụ đề đã bỏ qua; phát nền không đổi. Audio/video khác duration được xác minh từ track, không thay mốc nhận dạng hoặc gửi lại ASR thành công. Bước chỉ kiểm tra không export M4A. Kết quả thực sự bị cắt hoặc không đối chiếu được vẫn bị từ chối để tránh chữ lệch. Copy diagnostics bổ sung `media.last_caption_timing` với stage và các số giây, không có transcript/URL/key/session.

[Cách sửa](../PLAN-0.18.2.md) · [API thật](../evidence/0.18.2-service-probes.json) · [Diagnostics đầu vào](../evidence/0.18.2-user-diagnostics-summary.json) · [Validation](validation-0.18.2.json) · [Nghiệm thu](../DEVICE_TESTS.md) · [Ảnh phụ đề](../evidence/ui-captions-long-0.18.2.png) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37111088703).
