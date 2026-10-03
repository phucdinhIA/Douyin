# Douyin 40.6.0 — 0.18.1-test

Bản mới chỉ hiển thị phụ đề Việt và giữ tiếng gốc. Đã loại bỏ toàn bộ tạo/phát TTS, Nam Minh, Vbee và việc đổi tốc độ video để khớp giọng. Giữ dịch bình luận GTX/Gemini dự phòng, dịch phân tích AI bằng Claude và phát nền từ bản trước.

- Sửa thông báo gộp “không có lời nói hoặc quá 60 phút”: phân biệt thời lượng, cấu trúc phản hồi, track âm thanh và kết quả nhận dạng rỗng. Đọc nhánh/kênh có lời nói và mốc câu thật khi thiếu mốc từ.
- Sửa mốc bằng 0, làm tròn và lùi nhỏ trong giới hạn kiểm chứng, giữ chữ và khoảng im lặng. Mốc hỏng nghiêm trọng vẫn báo lỗi rõ để tránh hiển thị sai thời gian.
- Giữ Nova-3 `zh-CN`. Thử thật phát hiện tự đoán ngôn ngữ nhận nhầm đoạn Mandarin 13,5 giây thành `pt` và trả rỗng; chế độ đó đã loại khỏi mã chạy.
- Tăng tốc bằng nguồn video trực tiếp khi lấy được từ player, bỏ qua Apify. Tệp được kiểm tra track/thời lượng và trích âm thanh có mốc khớp. Nguồn hết hạn hoặc tải chậm quá 20 giây thì dùng Apify trước khi gọi ASR.
- Kết quả remote rỗng cho phép **một** lần gửi âm thanh trực tiếp sau kiểm tra, có thể phát sinh thêm một lượt phí ASR; rỗng lần nữa thì dừng. Không lặp yêu cầu vô hạn. Cache hợp lệ của bản cũ được dùng lại.
- Transcript dưới 10 phút vẫn dịch toàn ngữ cảnh với Claude. Video dài có thể phát đoạn đã dịch trong khi dịch tiếp; tua vào lời nói chưa dịch thì dừng chờ đúng đoạn.
- Phụ đề dọc tối đa 3 dòng, ngang tối đa 2 dòng, nền tối/chữ trắng có đệm và chừa nút/mô tả. Kéo lên/xuống để đổi vị trí. Câu dài chia trang trong chính mốc câu gốc; không dồn toàn video lên màn hình. Chuyển trang dựa trên độ dài chữ, không khẳng định đồng bộ từng từ dịch.

Đạt **21 kiểm thử Python, 29 Gemini, 38 dịch AI, 229 media và 219 UIKit checks**. Bao gồm 128 biến thể mốc thật, source MP4 có/không có audio, rỗng/khôi phục/hủy, kênh đầu im lặng, tua lúc dịch tiếp, trang phụ đề dài và giới hạn kéo. Nova-3 tải âm thanh thật xử lý mẫu 13,538 giây trong 1,938 giây và mẫu 67,78 giây trong 2,891 giây; chỉ là hai mẫu, chưa tính tải/trích/dịch/giao diện.

IPA riêng: `dist/Douyin-40.6.0-0.18.1-SUBTITLES-PRIVATE-TEST.ipa`. Cần ký/cài như các bản trước. **Chưa nghiệm thu bản này trên iPhone thật**, nên chưa thể cam kết mọi video và mạng đều không lỗi.

[Chi tiết sửa và nghiên cứu](docs/PLAN-0.18.1.md) · [Trạng thái/kiểm thử](docs/STATUS.md) · [API thật](docs/evidence/0.18.1-service-probes.json) · [Nghiệm thu iPhone](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37105020512).
