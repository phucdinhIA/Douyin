# Sửa dịch Claude và bố cục 0.18.3

## Bằng chứng và nguyên nhân

Diagnostics 0.18.2 có `matched_audio`: video 116,100 giây / audio 116,075 giây. Không có counter ASR rejected trong báo cáo mới. Hai lượt caption thất bại ở Claude và hai lượt dịch phân tích AI thất bại; chưa có phản hồi API nguyên gốc từ thiết bị nên không kết luận cả hai có cùng nguyên nhân.

Thử endpoint thật với 400 ký tự tiếng Trung: HTTP 200, một đoạn Việt dài 1.401 ký tự, không còn chữ Trung. Bộ đọc cũ dùng giới hạn 500 ký tự cho cả văn bản phân tích và phụ đề, rồi báo chung “AI chưa trả đủ bản dịch theo từng mốc phụ đề”. Đây là lỗi app tái hiện được. Extension `AiTranslationProvider` kiểm tra số phần tử, lấy `translateResult` và xem `useAiTranslate` là thông tin chọn engine, không phải điều kiện bản dịch đầy đủ. Backend thực tế không trả index nên phải giữ contract thứ tự; nếu có index đầy đủ thì ghép bằng ID.

Ảnh thiết bị có hai switch ngôn ngữ: reader bình luận còn hiện khi tab AI mở. Reader AI cộng thêm 64 điểm vào nội dung controller đã được nhúng, đặt controls giữa phân tích. Phụ đề lấy width trừ rail bên phải nhưng x không căn lại nên lệch trái; đáy còn chừa 144–230 điểm nên quá cao so với yêu cầu mới.

## Thay đổi

1. Tách bộ đọc phân tích: chia ở ranh giới câu/đoạn, giữ mọi ký tự; nhận tối đa 4.096 ký tự mỗi đoạn và 96.000 tổng. Cache vẫn 32 mục / 2 MB, nhận prose mở rộng tới 96.000 ký tự. Không cắt nội dung khi vượt giới hạn.
2. Phụ đề nhận tối đa 2.000 ký tự Việt/cue và phân trang bằng đo font hiện có. Giữ IDs/start/end của nguồn. Backend không được đổi timeline. Chấp nhận ID số/chuỗi thập phân khi tất cả IDs rõ và duy nhất; thiếu ID, trùng, lạ, thiếu câu, chữ Trung, sai cấu trúc vẫn bị từ chối với lý do riêng. `useAiTranslate` không chặn văn bản Việt hợp lệ.
3. Dịch nhóm đầu tối đa 8 cue / 1.600 ký tự; sau đó 12 cue / 2.400 ký tự. Video dưới 600 giây, transcript dưới 12.000 ký tự gửi toàn ngữ cảnh trước/sau trên hai cue ranh giới của mỗi nhóm; các cue giữa có 3 câu trước/2 câu sau như extension. Đoạn đã đủ được hiển thị và lưu ngay, không cần chờ cả track. Cache ASR và các nhóm đã dịch giữ nguyên; quota/timeout không tự gọi lại.
4. Theo dõi response HTTP, số đoạn mong đợi/trả về, đoạn trống, đoạn còn Han, độ dài lớn nhất, thời gian phản hồi và kết quả kiểm tra. Không ghi text, URL, token. Lỗi dịch được phân biệt với ASR và kiểm tra thời lượng.
5. Tab AI tạm ẩn reader bình luận cùng cửa sổ, ngừng quét/gửi nhóm mới; trả reader về khi rời AI. Reader Việt có nền riêng, controls ở đáy; Bản gốc không hiện lỗi/status đè lên chữ và thêm bottom inset cho scroll native. Top reader lấy vị trí renderer thực tế, bỏ offset thừa. Retry nằm trong pane Việt. Khởi tạo lạnh WebKit/Vision có deadline lấy nguồn tối đa 90 giây (native ổn định vẫn gửi sớm), không gửi API khi chưa lấy được chữ. Fixture kiểm tra DOM đã sẵn sàng và tiếp tục tick qua lượt OCR xác nhận thứ hai; không dừng harness ở 45 giây khi model lạnh chưa khởi tạo xong.
6. Phụ đề căn giữa vùng safe bằng lề đối xứng 16 điểm, đáy trên navigation 64 điểm dọc / 16 điểm ngang. Dùng preference vị trí mới để bản cài cũ không giữ vị trí cao; vẫn kéo được. Giữ 3 dòng dọc/2 dòng ngang, từng trang nằm trong đúng start/end cue gốc. TTS vẫn tắt hoàn toàn; audio gốc và phát nền giữ nguyên.

## Kiểm chứng và giới hạn

API thật: prose 400 → 1.401 ký tự trong 5,11 giây; 24 cue trong 19,30 giây; 8 cue + ngữ cảnh cả 24 trong 6,72 giây. Thêm một probe 8 cue + context lân cận trong 6,53 giây. Các lượt dùng dữ liệu tổng hợp, không phải đúng video thiết bị; thời gian phụ thuộc backend, không cam kết cùng tốc độ trên mọi clip. Không thay mô hình Claude để lấy số đo nhanh.

Regression cần kiểm tra: mở rộng prose, expansion caption, missing/empty/count/ID/Chinese residue, số nhóm và ngữ cảnh xuyên nhóm, cache, cancellation/quota, source duration/ASR cũ, pause/tua/loop, reader AI nhúng trong comment sheet có switch đang hoạt động, nguyên bản scroll inset, error pane và phụ đề center/bottom. Web/OCR phải dùng visible owner khi contentVC là wrapper không có bounds nhưng không clip các con đang vẽ. Biên dịch arm64 + Foundation + UIKit Simulator trước khi đóng gói. IPA phải đối chiếu SHA và từng entry với IPA gốc. iPhone thật iOS 18.5 vẫn cần nghiệm thu sau cài; không tuyên bố đã kiểm tra trên thiết bị thật.
