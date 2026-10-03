# Douyin 40.6.0 — 0.18.3-test

Sửa lỗi dịch phân tích AI dùng nhầm giới hạn 500 ký tự của phụ đề. API thật tái hiện 400 ký tự Trung → 1.401 ký tự Việt đầy đủ nhưng bị bản cũ từ chối. Bộ đọc phân tích nay có ngân sách riêng, kiểm tra phản hồi theo contract của extension Transduck và thông báo lý do chính xác.

Phụ đề dịch theo nhóm đầu tối đa 8 cue, nhóm sau 12 cue, kèm toàn transcript ngắn trong context để hiển thị đoạn đầu sớm hơn. Giữ mốc ASR gốc, phân trang 3 dòng dọc/2 dòng ngang. Chữ căn giữa hai bên và nằm ngay trên thanh điều hướng phía dưới, vẫn kéo được. Tab AI chỉ có một switch, reader Việt riêng và Bản gốc không bị status/lỗi che giữa nội dung. TTS vẫn đã bỏ; giữ audio gốc và phát nền.

Đạt 21 kiểm thử Python, 29 Gemini, 40 dịch AI, 257 media và 229 UIKit. Bốn probe Claude thật; mẫu 8 cue + context của 24 cue trả trong 6,72 giây so với 19,30 giây khi dịch cả 24. Đây là mẫu thử, không cam kết tốc độ mọi video.

IPA riêng: `dist/Douyin-40.6.0-0.18.3-CLAUDE-LAYOUT-PRIVATE-TEST.ipa`. Ký/cài như trước; chưa nghiệm thu bản mới trên iPhone thật iOS 18.5.

[Phân tích và cách sửa](docs/PLAN-0.18.3.md) · [Kết quả](docs/STATUS.md) · [API thật](docs/evidence/0.18.3-service-probes.json) · [Nghiệm thu](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37114315629).
