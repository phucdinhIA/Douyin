# Nghiệm thu Douyin thật — 0.16

Chưa thực hiện trên iPhone trong môi trường này. Ký/cài IPA cá nhân bằng Sideloadly như các bản trước, xác nhận tên app Douyin và diagnostics ghi `0.16.0-test`.

1. Mở bình luận video có chữ Trung rõ. Chờ dịch tại chỗ; cuộn qua nhiều dòng và mở trả lời. Kiểm tra tên người dùng, chữ nhập, phần AI không bị GTX dịch. Đóng rồi mở lại, kiểm tra cache. Khi GTX báo giới hạn/lỗi, giữ chữ gốc; nút thử lại chỉ gọi khi bấm.
2. Mở phần bình luận AI, xác nhận bản dịch Việt không còn hiển thị `<mark>`/`</mark>`, nội dung bên trong vẫn đủ và hỏi đáp Gemini dùng phân tích gốc.
3. Chạm nhanh bốn lần bằng một ngón vào vùng video có lời Trung. Video phải dừng trước request, hiện bước xử lý và chỉ phát lại khi hoàn tất. Bốn lần nữa trong lúc xử lý không tạo job trùng. Nút Hủy cho xem tiếp; đổi video không được phát audio của video cũ.
4. Thử ít nhất ba video khác nhau: khoảng 15–60 giây, 1–3 phút, 5–9 phút. Kiểm tra phụ đề/giọng nam Mạnh Dũng bám mốc, khoảng lặng, tua tới/lùi, pause/resume, tốc độ phát và vòng lặp. Tiếng gốc phải được trả lại khi tắt/đổi video. Clip không có lời nói nhận dạng được phải báo rõ. Vbee lỗi phải hiển thị lý do và dùng phụ đề, không tổng hợp lại tự động.
5. Khi video đang phát, khóa màn hình và chuyển sang app khác ít nhất 30 giây; thử cả tiếng gốc và lồng tiếng. Âm thanh tiếp tục, không chồng hai giọng. Dừng/phát ở màn hình khóa; quay lại app phải đồng bộ thời gian. Video đã chủ động pause trước khi khóa không được tự phát. Thử rút tai nghe và một cuộc gọi, tránh tự phát bất ngờ.
6. Bật lại cùng video để xác nhận cache, thử hủy khi đang gọi từng nhà cung cấp và mất mạng. Theo dõi số request; không lặp paid calls ngoài thao tác chủ động của người dùng.

Copy diagnostics ngay sau mỗi lỗi, kèm link video, thao tác và trạng thái hiện trên màn hình. Các trường mới gồm `gtx_automatic_visible`, `deepgram_upload_fallback`, `vbee_configured`, `dubbing_active`, `background_companion`; counters cho biết GTX gửi/áp bản dịch, Deepgram bị CDN chặn/upload HTTP, Vbee HTTP/timeline ready và background companion prepared/playing/source failed. Không cần gửi key/token hoặc signed media URL.
