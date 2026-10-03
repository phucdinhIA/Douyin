# Douyin — bản thử cá nhân 0.17

Douyin 40.6.0/build 406019/arm64, tên ứng dụng **Douyin**. Giữ phần phát nền 0.16 đã được người dùng xác nhận hoạt động trên iOS 18.5.

- Mở biểu tượng bình luận: dịch các bình luận đang hiển thị, gộp tối đa 8 dòng mỗi lượt GTX. Giữ cache từng bình luận, giãn lượt dịch và chờ theo Retry-After khi Google giới hạn. Nếu GTX trả 429, dùng **Gemini dự phòng theo lựa chọn đã được người dùng chấp thuận**, kể cả trong thời gian GTX đang bị giới hạn. Trạng thái ghi Gemini khi dùng dự phòng; không xoay endpoint để né hạn mức. Chỉ gửi chữ bình luận đang thấy, bỏ qua tên tác giả, chữ nhập và phần AI.
- **Chạm nhanh 4 lần bằng một ngón vào vùng video** để bật phụ đề/lồng tiếng. Video dừng trước Apify → Nova-3 tiếng Trung (`zh-CN`) → Gemini tiếng Việt → Vbee nam Mạnh Dũng. Video ngắn tối đa 10 phút được dịch toàn bộ transcript trong một lượt để giữ ngữ cảnh; giữ nguyên mọi ID/mốc. Nguồn video, ASR và bản dịch được cache để tránh lặp bước trả phí.
- Áp dụng kỹ thuật từ extension Youtube Dubbing: chuẩn bị nhóm 3 câu tại vị trí đang xem, phát khi nhóm đó đã tải/xuất/đồng bộ xong, rồi tạo các nhóm sau trong lúc xem. Đệm tối đa 60 giây phía trước; audio đã có được xếp hàng bằng AVQueuePlayer, có khoảng lặng thật để khớp biên nhóm. Tua ưu tiên vị trí mới, dừng nếu chưa đủ audio; tắt/đổi video hủy job cũ và trả tiếng gốc.
- Một nhóm Vbee lỗi 504 không hủy cả video: đoạn đó dùng phụ đề Việt và âm thanh gốc, các nhóm sau tiếp tục. Không tự lặp POST trả phí sau timeout mơ hồ. Audio quá dài để vừa mốc ở mức nén tối đa 3x cũng chuyển sang phụ đề/tiếng gốc. API, tốc độ mạng và nội dung ảnh hưởng thời gian chờ; không hứa mọi video có lời nói nhận dạng được.
- Bản dịch phân tích AI tiếp tục bỏ thẻ `<mark>` nhưng giữ nội dung; hỏi đáp Gemini nhận phân tích gốc. Phát nền giữ nguồn native/companion và đồng bộ lại khi trở về app.

Kiểm thử thật: transcript Nova-3 67,454 giây/17 câu được Gemini dịch đủ trong 2,95 giây; Vbee tải đủ 3 câu đầu trong 6,56 giây, không cần đợi 14 câu sau. Đây là thời gian từng bước, **không phải tổng thời gian bật phụ đề**, và không chứng minh Douyin thật đã ổn định trên iPhone.

Đạt 62 media, 18 audio, 29 Gemini, 36 dịch AI, 21 Python và 206 UIKit checks trên iPhone 15 Simulator/iOS 18.2; build arm64 warnings-as-errors. Chưa nghiệm thu 0.17 trên iPhone thật.

IPA cá nhân: `dist/Douyin-40.6.0-0.17.0-PROGRESSIVE-VBEE-PRIVATE-TEST.ipa`. SHA-256: `e274a660a580bfbc51f988935ef8477c335818baba21ab9c62d3207134602743`. Cấu hình riêng đã được đối chiếu đúng với IPA; không nằm trong Git.

[Kế hoạch và nghiên cứu extension](docs/PLAN-0.17.md) · [Probe](docs/evidence/0.17-service-probes.json) · [Test iPhone](docs/DEVICE_TESTS.md) · [Trạng thái](docs/STATUS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37093712664).
