# Douyin — bản thử cá nhân 0.18

Douyin 40.6.0/build 406019/arm64, tên ứng dụng **Douyin**. Bản này sửa bố trí bình luận, mở rộng đọc phân tích AI và thay Vbee bằng luồng Claude/Nam Minh từ backend của extension Youtube Dubbing.

- **Bình luận:** GTX tự dịch chữ đang thấy; Google 429 thì dùng Gemini dự phòng đã được chấp thuận. Bản Việt nằm trong bảng cuộn có chiều cao từng dòng tự đo, tránh ghi đè vào khung chữ Trung. Một bảng/nút trạng thái duy nhất. Chọn **Bản gốc** để trả lời, xem ảnh hoặc cuộn danh sách native; nút **Đọc thêm bình luận** đưa các dòng tiếp theo vào vùng dịch.
- **Phân tích AI:** đọc renderer native đã đối chiếu ABI, nội dung web trong vùng AI, rồi OCR tiếng Trung tại máy nếu chữ chỉ được vẽ. Hai lần OCR giống nhau mới gửi chữ tới Claude; ảnh không được tải lên. OCR ghi rõ chỉ dịch vùng đang hiển thị. Bản Việt cuộn riêng, bỏ thẻ `<mark>` và giữ nội dung; hỏi đáp Gemini vẫn dùng nguồn gốc.
- **Phụ đề/lồng tiếng:** chạm nhanh **4 lần** vùng video. Video dừng trước Apify → Nova-3 `zh-CN` → Claude `claude-sonnet-5` → **Nam Minh** `vi-VN-NamMinhNeural`. Transcript tối đa 10 phút được dịch toàn bộ một lượt, giữ ngữ cảnh; ASR/cache độc lập với nhà cung cấp dịch. Vbee đã bỏ khỏi mã chạy và gói IPA.
- **Phát từng nhóm:** chuẩn bị ba câu ở vị trí đang xem, cho phát khi nhóm đầu đã tải/xuất/đồng bộ, rồi chuẩn bị tối đa 60 giây tiếp theo. Tua ưu tiên ngay vị trí mới và hủy job cũ; đổi video hủy kết quả cũ. Thiếu nhóm thì dừng để đệm; nhóm lỗi giữ phụ đề Việt và tiếng gốc.
- **Khớp giọng:** ghép các mảnh ASR quá ngắn vào câu liền trước, đệm khoảng lặng thật, xếp hàng audio và sửa dao động đồng hồ bằng tốc độ nhỏ. Câu dài có thể làm video chậm lại để giữ đủ lời; app trả tốc độ cũ khi tắt và tôn trọng tốc độ bạn tự chọn. Phát nền được giữ từ bản đã được người dùng xác nhận hoạt động.

API thật: mẫu Mandarin Nova-3 67,454 giây được ghép từ 17 thành 15 câu, giữ đủ chữ. Claude dịch đủ trong **12,078 giây**; tải ba câu Nam Minh đầu **3,234 giây**; cả 15 audio đều thành công và khớp chữ yêu cầu. Đây là một mẫu và thời gian từng bước, chưa tính lấy video, ASR, xuất audio/player.

Đạt **21 Python, 29 Gemini, 38 dịch AI, 69 media, 22 audio và 225 UIKit checks**; build arm64 với warnings-as-errors. Simulator iPhone 15/iOS 18.2 kiểm tra chữ dài, ảnh/trả lời, bảng lồng nhau, web/OCR, tua giữa TTS, biên nhóm, cache/hủy, lỗi API và tốc độ người dùng. **Chưa nghiệm thu 0.18 trên iPhone thật**, nên chưa thể cam kết mọi video/mạng đều ổn định.

IPA riêng: `dist/Douyin-40.6.0-0.18.0-CLAUDE-NAMMINH-PRIVATE-TEST.ipa`; cần ký lại như các bản trước. SHA-256: `a97c939667c6a310f007146c5e9ad82d76f4492928228f4c6e4830c5879f51e4`. Cấu hình tài khoản/key riêng được đối chiếu với IPA, không đưa vào Git/CI.

[Nghiên cứu và phương án chi tiết](docs/PLAN-0.18.md) · [Kết quả API thật](docs/evidence/0.18-service-probes.json) · [Nghiệm thu iPhone](docs/DEVICE_TESTS.md) · [Trạng thái](docs/STATUS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37099954414).
