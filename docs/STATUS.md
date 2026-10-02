# Trạng thái 0.16.0-test

Đã triển khai GTX tự dịch trong bảng bình luận, sửa tải nguồn Deepgram bị CDN chặn, thêm Vbee ghép audio theo cue và player phát nền, đồng thời bỏ thẻ mark khỏi bản dịch AI. 0.15 đã được người dùng báo lỗi trên iPhone; bản 0.16 chưa được người dùng xác nhận trên thiết bị thật.

IPA: `dist/Douyin-40.6.0-0.16.0-VIETSUB-VBEE-PRIVATE-TEST.ipa`; 704,980,031 byte. SHA-256 `1bfe8a615ff3863527f6ddaf2a7295c6cc515a211d1d795ea3374bdf8f967139`. Library `0b1924111a509f61784c2ba7bfccaa92d2f7125ca6c8334c3e4016327adc58c1`. Source biên dịch `5291cace67d9318e2a45faf6fafe6b02907b1cca`.

| Kiểm tra | Kết quả |
|---|---|
| Python đóng gói | 21 đạt |
| Gemini / dịch AI | 29 / 36 đạt |
| Media / Vbee audio timeline | 56 / 10 đạt |
| UIKit iPhone 15 Simulator | 193 đạt, không overflow |
| API thật | GTX 200; Nova-3 binary 200; Gemini 200; ba câu Vbee 200 |
| Đối chiếu IPA | 5,632 mục, 0 mismatch; core gốc giữ nguyên |
| Douyin thật trên iPhone | Chưa nghiệm thu |

Phát nền có đường AVPlayer/audio session mới và kiểm tra điều khiển audio cục bộ, nhưng các chuyển trạng thái native trên iOS 18.5 cần kiểm tra thiết bị. GTX miễn phí có thể trả 429; Vbee có thể lỗi token/số dư hoặc câu quá dài để khớp mốc. App báo lỗi, không tự gọi lại các API trả phí. Video dừng trong lúc chuẩn bị; có nút hủy/bỏ qua để xem tiếp.

[Kế hoạch](PLAN-0.16.md) · [Validation](VALIDATION.json) · [Hướng dẫn nghiệm thu](DEVICE_TESTS.md) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37021955203).
