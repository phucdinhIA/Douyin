# Douyin — bản thử cá nhân 0.16

Douyin 40.6.0/build 406019/arm64, tên ứng dụng **Douyin**. Bản này sửa các lỗi người dùng báo ở 0.15 và thêm lồng tiếng Việt Vbee.

- Mở biểu tượng bình luận: GTX tự dịch các bình luận đang nhìn thấy ngay tại chỗ. Cuộn tới bình luận mới để dịch tiếp. Bỏ qua tên tác giả, chữ đang nhập, phần AI và bình luận ngoài màn hình. Nút GTX cho biết đang dịch/lỗi và cho thử lại thủ công. Google GTX là endpoint miễn phí không có SLA; khi giới hạn mạng/quota, giữ chữ gốc và báo trạng thái.
- **Chạm nhanh 4 lần bằng một ngón vào vùng video** để bật phụ đề/lồng tiếng cho video đó. Video dừng trước Apify → Nova-3 tiếng Trung → Gemini tiếng Việt → Vbee giọng nam Mạnh Dũng. Nếu CDN chặn Deepgram lấy URL, app tải nguồn và gửi âm thanh trực tiếp. Chỉ phát lại sau khi phụ đề hoàn chỉnh và audio đã tải, ghép, về đúng mốc. Nếu Vbee lỗi, thông báo lỗi và dùng phụ đề đã hoàn tất; không tự tổng hợp lại trả phí.
- Audio từng câu được đặt đúng khoảng phụ đề, giữ khoảng lặng và điều chỉnh tốc độ bằng spectral time-pitch khi cần. Tua/dừng/lặp bám clock video; đổi video hủy công việc cũ và trả lại tiếng gốc. Audio không vừa khoảng ở mức tối đa 3x sẽ được báo lỗi và dùng phụ đề. Cần đợi lần xử lý đầu; cache giảm gọi API cho lần sau. Video không có lời nói nhận dạng được sẽ được báo rõ. Ưu tiên video dưới 10 phút; không hứa mọi clip có phụ đề hoặc lồng tiếng tức thì.
- Phát nền dùng player riêng từ nguồn video hiện tại, audio playback session, điều khiển dừng/phát ở màn hình khóa và đồng bộ lại khi vào app. Tôn trọng trạng thái pause, thay đổi video, ngắt tai nghe và cuộc gọi. Phần này chưa được nghiệm thu trên iPhone thật.
- Bản dịch phân tích AI bỏ thẻ `<mark>` nhưng giữ nội dung. Luồng hỏi đáp Gemini vẫn nhận bản phân tích gốc.

Đã đạt 56 media, 10 audio timeline, 29 Gemini, 36 dịch AI, 21 Python và 193 UIKit checks trên iPhone 15 Simulator/iOS 18.2; build arm64 warnings-as-errors. Provider probes thực: clip 13,5 giây bị HTTP 460 ở CDN đã nhận dạng thành công bằng binary upload, Gemini dịch giữ mốc và Vbee tạo đủ ba câu; clip 67 giây được nhận dạng 209 từ. Các kiểm tra này **không thay thế việc chạy Douyin thật trên iPhone**.

IPA cá nhân: `dist/Douyin-40.6.0-0.16.0-VIETSUB-VBEE-PRIVATE-TEST.ipa`. SHA-256: `1bfe8a615ff3863527f6ddaf2a7295c6cc515a211d1d795ea3374bdf8f967139`. Key/token riêng chỉ nằm trong cấu hình ngoài Git và IPA riêng.

[Kế hoạch](docs/PLAN-0.16.md) · [Nghiên cứu và probe](docs/evidence/0.16-service-probes.json) · [Test iPhone](docs/DEVICE_TESTS.md) · [Trạng thái](docs/STATUS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37021955203).
