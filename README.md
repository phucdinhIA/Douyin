# Douyin — bản thử cá nhân 0.15

Douyin 40.6.0/build 406019/arm64, tên hiển thị **Douyin**. Ký/cài IPA riêng bằng Sideloadly.

- **Chạm nhanh 4 lần bằng một ngón vào vùng video** để bật phụ đề Việt, kể cả khi nút không hiện. Video tạm dừng trước Apify → Deepgram Nova-3 tiếng Trung → Gemini tiếng Việt, và chỉ phát lại khi track đã hoàn tất/cache. Chạm 4 lần khi đang chạy không hủy hoặc gửi thêm yêu cầu. Có lỗi: video vẫn dừng; **Bỏ qua · phát video** cho xem tiếp. Sau khi bỏ qua, chạm 4 lần để thử lại thủ công. Nút **Hủy phụ đề** hủy và cho phát tiếp.
- Trong bình luận, bấm **Dịch bình luận**, chọn dòng để dịch GTX. Nếu thiếu nút: hai ngón chạm 3 lần → **Dịch bình luận · GTX**. Nguồn đọc từ label/model ô bình luận đang thấy, giữ nguyên bản gốc. GTX không dùng key trả phí.
- Dịch phân tích AI/Gemini giữ như bản người dùng đã xác nhận hoạt động. Cache phụ đề/bình luận riêng, không tự retry API trả phí. Ưu tiên video dưới 10 phút; prerecorded toàn clip, lần đầu cần chờ API. Chi tiết dịch vụ ở [nghiên cứu 0.14](docs/MEDIA-0.14.md).

0.14 đã bị người dùng báo lỗi trên iPhone: GTX không đọc được nguồn và phụ đề chưa bắt đầu request. 0.15 sửa routing, lớp phủ nút, phạm vi đọc và điều khiển pause. Đã đạt 21 Python, 29 Gemini, 36 dịch AI, 49 media và 184 UIKit checks trên iPhone 15 Simulator/iOS 18.2; build arm64 warnings-as-errors. Đây là mock/lớp giả, chưa nghiệm thu Douyin thật trên iPhone. GTX probe Windows lần này trả HTTP 429; app báo giới hạn và chỉ thử lại khi chọn dòng, không hứa endpoint miễn phí luôn sẵn sàng.

IPA: `dist/Douyin-40.6.0-0.15.0-iPhone15-FOUR-TAPS-PRIVATE-TEST.ipa`. SHA-256: `0291eecc939c0b0fd47aa5cc88a25c81cdaa70451d8a0cfc3b09f1b08ea8ab5a`. Đã đối chiếu 5,631 mục, 0 mismatch; core gốc giữ nguyên. Key cá nhân chỉ trong IPA riêng, không ở Git/CI.

[Kế hoạch](docs/PLAN-0.15.md) · [Test iPhone](docs/DEVICE_TESTS.md) · [Trạng thái](docs/STATUS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37011642974).
