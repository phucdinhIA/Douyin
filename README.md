# Douyin 40.6.0 — 0.18.2-test

Sửa lỗi “Thời lượng âm thanh không khớp video” của 0.18.1. Bỏ shortcut native-file gây 11 lỗi trên máy người dùng, trở lại URL canonical qua Apify. Khi thời lượng video khác audio, xác minh track audio thực tế và dùng lại kết quả Deepgram đã thành công; không kéo giãn mốc và không gọi ASR lần nữa chỉ để xác minh.

Giữ Nova-3 `zh-CN`, Claude toàn ngữ cảnh dưới 10 phút, cache, phụ đề 3 dòng dọc/2 dòng ngang có kéo vị trí, GTX/Gemini cho bình luận và phát nền. TTS vẫn đã bỏ hoàn toàn. Đường canonical có thêm thời gian Apify so với shortcut cũ; ưu tiên tránh lỗi hơn tái sử dụng đường nhanh chưa được xác minh trên iPhone.

Đạt 21 kiểm thử Python, 29 Gemini, 38 dịch AI, 243 media và 220 UIKit. API thật tái hiện video 19,53 giây/audio 13,54 giây nhận dạng thành công; kiểm thử có tệp MP4 video 8 giây/audio 2 giây, milliseconds, decode bị cắt và binary recovery.

IPA riêng: `dist/Douyin-40.6.0-0.18.2-AUDIO-TIMING-PRIVATE-TEST.ipa`. Cần ký/cài như trước. Chưa nghiệm thu 0.18.2 trên iPhone thật iOS 18.5; không khẳng định mọi video/codec/mạng đều không lỗi.

[Nguyên nhân và cách sửa](docs/PLAN-0.18.2.md) · [Kết quả](docs/STATUS.md) · [API thật](docs/evidence/0.18.2-service-probes.json) · [Nghiệm thu](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37111088703).
