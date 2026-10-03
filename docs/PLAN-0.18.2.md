# 0.18.2 — đối chiếu thời lượng audio

Diagnostics 0.18.1 trên iOS 18.5 cho thấy 11 lượt native binary upload HTTP 200 rồi 11 ASR rejected; hai lượt remote qua Apify đã đến Claude và hoàn tất. Thông báo phát sinh trong `consumeASR`, sau Deepgram và trước dịch. Diagnostics cũ không ghi các con số thời lượng nên chưa đủ để khẳng định mọi video có cùng cấu trúc audio.

Một probe có lời Mandarin thật đã tái hiện điều kiện lỗi: video/container 19,533333 giây, track audio 13,537007 giây, Deepgram 13,537 giây và 34 từ. Điều kiện bằng nhau của 0.18.1 từ chối kết quả hợp lệ này. Probe thứ hai với audio bắt đầu muộn cho kết quả decode bị rút ngắn; vì vậy không được đơn giản bỏ mọi kiểm tra thời lượng hoặc tự kéo giãn các mốc.

Phương án đã triển khai:

- Bỏ qua shortcut native-file của phụ đề; dùng URL canonical do Apify lấy theo đúng video ID. Giữ nguyên getter/player cho phát nền. Giữ cache, long-poll actor và dịch toàn ngữ cảnh dưới 10 phút.
- Hint thời lượng Apify được so với thời lượng audio của Deepgram. Nếu khớp, luồng tiếp tục trực tiếp. Hệ số milliseconds chỉ được chuẩn hóa khi kết quả audio xác nhận hệ số 1000.
- Khi audio và hint video không khớp, tải cùng nguồn một lần để đọc video duration, audio start và audio duration bằng AVFoundation. Không export audio ở bước chỉ kiểm tra; không gửi lại Deepgram. Nếu track bắt đầu gần 0 và duration audio khớp kết quả ASR, dùng lại kết quả thành công và giữ nguyên các mốc từ.
- Binary recovery cho remote rỗng/REMOTE_CONTENT_ERROR vẫn có tối đa một lượt. Đối chiếu duration với track audio thay vì container. Track bắt đầu muộn, audio bị cắt thật, nguồn không có audio, metadata sai và mốc hỏng vẫn dừng rõ ràng; không sinh phụ đề giả hoặc đổi tốc độ mốc.
- `media.last_caption_timing` ghi stage, input_mode và thời lượng hint/video/audio/Deepgram bằng giây, trạng thái kiểm tra và đơn vị đã chuẩn hóa. Không ghi transcript, URL, video ID, key hoặc session; giữ số liệu gần nhất sau tắt/hủy.

Kiểm thử hồi quy dùng MP4 thật có video 8 giây/audio 2 giây, kết quả ASR có lời, binary recovery cùng loại tệp, hint milliseconds, decode bị cắt thật và metadata quá lớn. Kiểm tra không thêm ASR cho kết quả thành công, không thay start/end, không translate khi thực sự không đồng bộ. UIKit đưa native play URL vào nút phụ đề để kiểm tra đường chạy thực tế đã bỏ shortcut.

Bản giao cần build arm64, Foundation/media, UIKit Simulator, đóng gói private và đối chiếu IPA độc lập. Chưa có iPhone vật lý để nghiệm thu bản 0.18.2. Hai probe mới chỉ là mẫu thử, không chứng minh mọi clip/codec/mạng đều thành công.
