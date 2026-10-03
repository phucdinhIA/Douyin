# Trạng thái 0.18.0-test

Đã đóng gói IPA riêng `Douyin-40.6.0-0.18.0-CLAUDE-NAMMINH-PRIVATE-TEST.ipa` sau khi build và toàn bộ kiểm tra CI đạt. Source `545ee7b58df77d1788e283a928930af967b9594c`; library SHA-256 `20b97d53ef55714b5ba6082cb596819fcec9e345d9d0ebbdd46ac4dfd25033a9`; IPA SHA-256 `a97c939667c6a310f007146c5e9ad82d76f4492928228f4c6e4830c5879f51e4`; kích thước 705,023,982 byte.

| Kiểm tra | Kết quả |
|---|---|
| Python đóng gói | 21 đạt |
| Gemini / dịch AI | 29 / 38 đạt |
| Media / audio progressive | 69 / 22 đạt |
| UIKit iPhone 15 Simulator | 225 đạt, không overflow theo fixture |
| Backend thật | Claude dịch đủ 15 câu; Nam Minh tải đủ 15 audio, echo đúng chữ |
| Đối chiếu IPA độc lập | 5,632 mục, 0 mismatch; core gốc giữ nguyên |
| Vbee trong mã/gói mới | Đã loại bỏ |
| Douyin 0.18 trên iPhone thật | Chưa nghiệm thu |

Sửa nguyên nhân đã kiểm chứng: khung cố định của chữ Trung không đủ cho bản Việt; bảng/nút trùng do controller lồng nhau; view wrapper zero-size và snapshot view con không lấy được chữ; ngữ cảnh backend sai kiểu gây HTTP 400; mảnh ASR quá ngắn gây nén giọng cực lớn; tua giữa job TTS chưa ưu tiên ngay vị trí mới. OCR chỉ dịch vùng thấy và không bảo đảm đọc đủ phần phân tích chưa cuộn. Hạn mức, mạng, đăng nhập và chất lượng ASR vẫn ảnh hưởng kết quả.

Giữ phát nền đã được người dùng xác nhận ở bản trước. Chưa xác minh đồng bộ lồng tiếng khi khóa máy trên thiết bị thật.

[Kế hoạch](PLAN-0.18.md) · [API thật](evidence/0.18-service-probes.json) · [Validation](VALIDATION.json) · [Nghiệm thu](DEVICE_TESTS.md) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37099954414).
