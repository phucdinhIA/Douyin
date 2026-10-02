# Nghiệm thu 0.14 — iPhone 15/iOS18.5

Ký/cài IPA cá nhân mới bằng Sideloadly với cùng định danh, giữ dữ liệu. Restart app; tên app Douyin, Copy diagnostics phải ghi 0.14.0-test. Không gửi lại key.

1. Vuốt qua video trước khi bấm phụ đề: counters `Captions Apify request`, `Captions Deepgram sent`, `Captions Gemini batch sent` không tăng. Không có phụ đề của video trước.
2. Chọn video tiếng Trung rõ, dài khoảng 30–90 giây. Bấm **Phụ đề Việt**: thấy tiến trình Apify/Nova-3/Gemini; có từng nhóm chữ Việt. So sánh lời nói/tên/số, chú ý API có thể mất hàng chục giây lần đầu. Chưa mở nút không phát sinh yêu cầu phụ đề.
3. Dừng/tua trước/tua sau/lặp video: phụ đề theo player, khoảng lặng ẩn câu cũ. Thử khi đang chờ nhận dạng/dịch; nhóm tiếp theo ưu tiên đoạn vừa tua tới. Thử thêm video 5–9 phút.
4. Tắt/hiện phụ đề, mở lại video và restart: track đã hoàn tất dùng cache, counters provider không tăng nếu cache còn. Cache có giới hạn, có thể bị loại mục cũ.
5. Bấm hủy hoặc đổi video/chuyển nền khi đang làm: dừng, overlay cũ không hiện trên video mới, không tự retry. Yêu cầu đã gửi vẫn có thể bị tính phí. Mất mạng/quota phải báo lỗi, không vòng lặp. Thử lại sau lỗi dịch không tăng Apify/Deepgram nếu ASR còn trong cache.
6. Bình luận → **Dịch bình luận**: danh sách chỉ chữ bình luận đang hiện, không tên/AI/view ẩn. Chạm dòng: có chữ Việt cạnh nguồn, nguồn native giữ nguyên. Chạm lại cùng dòng không tăng `GTX sent`. Cuộn native đến bình luận khác rồi đóng/mở lại để lấy danh sách mới.
7. GTX mất mạng/rate-limit: báo lỗi; đóng sheet/chuyển nền hủy, callback cũ không thay nội dung mới. GTX không dùng Apify/Deepgram/Gemini.
8. Hồi quy tab phân tích AI: vẫn dịch Việt như 0.13; chuyển Bản gốc/Việt và mở lại cache không tính phí thêm. Ask Gemini tiếp tục dùng phân tích gốc làm ngữ cảnh.
9. Kiểm tra bố trí nút/phụ đề với video dọc/ngang trên máy. Nếu thiếu nút/capture rỗng/lệch chữ, ghi video ID và Copy diagnostics sau thao tác; không gửi media URL ký tạm, API key hoặc nội dung riêng tư. Ghi riêng Featured/Tips/phát nền/xoay/search nếu còn lỗi.

Fixture và API probe đã đạt nhưng không chạy Douyin gốc trên iPhone. Không thể xác nhận nghiệm thu máy thật chỉ bằng kiểm tra ZIP hay simulator. IPA có key riêng, giữ cho cá nhân.
