# Nghiệm thu Gemini 0.11 — iPhone 15/iOS18.5

Ký/cài IPA cá nhân bằng Sideloadly với cùng định danh; giữ dữ liệu và bản đã ký trước. Restart app. Menu hai ngón tay chạm ba lần → Copy diagnostics phải ghi 0.11.0-test. Native hook JSON vẫn expected79; ba hook Gemini được báo riêng trong gemini.

1. Mở video → bình luận → AI phân tích. Chờ phân tích gốc xuất hiện. Chạm Ask Gemini · Your AI. Context phải hiện đúng phần phân tích; đoạn đó không bị sửa trên Douyin. Nếu thiếu, dán/sửa trong Context. Gemini chỉ có ngữ cảnh này, không có quyền xem video hoặc toàn bộ bình luận.
2. Nhập “Dịch phần phân tích này sang tiếng Việt, giữ nguyên tên và số” → Send. Kiểm tra có câu trả lời tiếng Việt, có giữ nghĩa/chi tiết và không hiện đăng nhập Douyin. Send chuyển câu hỏi/ngữ cảnh/recent answers tới Google bằng key của bạn. Còn phần phân tích do Douyin tạo vẫn giữ nguyên.
3. Hỏi tiếp một câu dựa vào phân tích. Chuyển Mode sang Fast rồi hỏi lại câu ngắn; model trên notice phải đổi. Khi chưa có phân tích, hỏi thử: câu trả lời không được giả vờ biết video.
4. Thử gửi từ ô native: phải vào draft Gemini với đúng câu hỏi rồi bấm Send. Nếu chạm ô native vẫn mở login trước submit, dùng nút Ask Gemini và báo thao tác/diagnostics; chưa giả định đã chặn được mọi renderer.
5. Bấm Cancel khi đang trả lời; câu hỏi giữ lại, phản hồi muộn không được ghi vào sheet. Đóng/mở lại: lịch sử cũ không tự xuất hiện. Tạm mất mạng: lỗi rõ và câu hỏi giữ lại, không gửi lặp liên tục.
6. Gemini routing OFF → thoát/mở lại tab: hành vi native được giữ. Nút fallback menu Gemini Q&A vẫn có cho kiểm tra, nhưng Send báo disabled. Bật lại khi dùng Gemini.
7. Hồi quy: Featured/Tips refresh/phân trang, feed thường, ảnh bình luận, LIVE, phát video rồi khóa màn hình 30 giây, video ngang. Bản này giữ chiến lược 0.10, không tuyên bố đã sửa các lỗi đó.

Nếu lỗi, Copy diagnostics sau thao tác; không cần gửi key hoặc nội dung cá nhân. Báo có nút Gemini không, context có được lấy không, model/mã lỗi hiển thị. IPA chứa key riêng của bạn, không chia sẻ cho người khác.

**Chưa nghiệm thu máy thật; đây vẫn là TEST.**
