# Nghiệm thu 0.15 — iPhone/iOS 18.5

Ký/cài IPA riêng bằng Sideloadly, khởi động lại app. Copy diagnostics phải ghi **0.15.0-test**. Không gửi key.

1. Trước khi bật phụ đề, vuốt 3 video: không có yêu cầu Apify/Nova-3/Gemini cho phụ đề. Chạm 1–3 lần không chạy pipeline. Kiểm tra pause/double-tap gốc vẫn hoạt động.
2. Chọn clip có lời tiếng Trung, dài 30–90 giây. Một ngón chạm nhanh 4 lần ở vùng video, tránh nút/tên/comment/tab: video dừng, thấy tiến trình, `Captions four taps recognized`/`Captions opt-in` tăng. Thử cả video thiếu nút. Chạm thêm 4 lần lúc chờ không hủy/thêm yêu cầu.
3. Track hoàn tất: video chạy tiếp, phụ đề Việt theo tiếng nói. Tạm dừng/tua/lặp: chữ theo thời gian player; khoảng lặng không giữ câu cũ. Thử thêm clip 5–9 phút. Lần đầu API có thể mất hàng chục giây hoặc hơn.
4. Tắt/hiện phụ đề, mở lại video và restart app: cache còn thì không tăng counter provider. Bấm Hủy lúc đang làm cho video chạy tiếp; vuốt sang video khác/chuyển nền hủy mà không tự phát lại video cũ hoặc hiện chữ cũ.
5. Mất mạng/quota/lỗi: thấy thông báo; video vẫn dừng cho đến khi bấm **Bỏ qua · phát video**. Bỏ qua rồi chạm 4 lần để retry thủ công; ASR còn cache thì không nhận dạng/lấy nguồn lại. Không tự lặp request trả phí.
6. Mở bình luận thông thường, bấm **Dịch bình luận**. Nếu thiếu nút, mở menu hai ngón/chạm 3 lần rồi chọn **Dịch bình luận · GTX**. Danh sách có chữ bình luận gốc đang thấy, không tên/AI/view ẩn. Chọn một dòng: chữ Việt hiện cạnh bản gốc; GTX sent/HTTP tăng, không tăng provider trả phí. Chọn lại dùng cache.
7. Cuộn đến bình luận khác rồi đóng/mở sheet để lấy danh sách mới. GTX 429 phải hiện giới hạn, không tự retry; sau khi dịch vụ sẵn sàng chọn dòng để thử lại. Lỗi mạng sau tối đa thời gian chờ phải báo; đóng sheet/chuyển nền hủy callback.
8. Bốn chạm trên nút, ô nhập, comment/AI và modal không được bật phụ đề phía sau. Mở lại tab phân tích AI để kiểm tra bản dịch đã hoạt động trước đây vẫn đúng; thử Ask Gemini.
9. Nếu còn lỗi, Copy diagnostics ngay sau thao tác. Chú ý `media.caption_shortcut_taps`, `four_tap_windows`, `caption_waiting`, `Captions shortcut player unavailable`, `Captions video ID unavailable`, `Captions playback clock unavailable`, `Captions pause unavailable`, `GTX fallback comments unavailable`, provider HTTP/transport counters. Chỉ gửi diagnostics và video ID công khai; không gửi key/media URL ký tạm.

CI chạy lớp giả và mock, chưa chạy Douyin gốc trên iPhone. Bản 0.14 đã thất bại trên máy người dùng; 0.15 cần xác nhận qua các bước trên, không thể nghiệm thu máy thật bằng ZIP/Simulator.
