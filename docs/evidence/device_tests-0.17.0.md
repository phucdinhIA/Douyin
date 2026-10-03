# Nghiệm thu Douyin thật — 0.17

Ký/cài IPA cá nhân bằng Sideloadly như trước; xác nhận tên app Douyin và diagnostics `0.17.0-test`. Môi trường này chưa chạy bản gốc trên iPhone.

1. Mở bình luận thường có chữ Trung: các dòng đang thấy phải chuyển sang Việt. Cuộn, mở trả lời, đóng/mở lại và tua video khác. Tên tác giả/chữ đang nhập/phần AI không được gửi GTX. Google trả 429 thì trạng thái Gemini và bản dịch vẫn xuất hiện; panel mở lại không tạo nhiều GTX trong cooldown. Bản dịch cache không gọi paid API lại.
2. Chạm 4 lần vùng video có lời Trung; video dừng và hiện từng bước. Thử 15–60 giây, 1–3 phút, 5–9 phút. Gemini dịch đủ toàn đoạn, Vbee chuẩn bị nhóm đầu rồi video phát trong lúc các nhóm sau tiếp tục. Không phải đợi toàn bộ TTS. Bốn chạm thêm trong khi xử lý không tạo job trùng; nút Hủy/Tắt cho xem tiếp.
3. Tua tới đoạn chưa có audio: video dừng, ưu tiên đoạn đó, phát lại đúng mốc. Tua lùi/loop dùng audio đã có. Kiểm tra các biên nhóm, khoảng lặng, pause/resume và tốc độ phát. Đổi video liên tiếp không còn phụ đề/audio từ video cũ.
4. Khi một nhóm Vbee lỗi hoặc mất mạng, giữ phụ đề và tiếng gốc cho nhóm đó, các nhóm sau tiếp tục nếu kết nối được. Không tự tổng hợp lại trả phí sau 504. Tắt/bật lại là thử lại chủ động; ASR/bản dịch/MP3 đã cache được dùng lại. Video không nhận dạng được lời nói phải báo rõ.
5. Kiểm tra hồi quy phát nền đã hoạt động ở 0.16: khóa máy/chuyển app 30–60 giây, dừng/phát màn hình khóa, quay lại app, pause trước khi khóa, rút tai nghe và cuộc gọi. Thử cả tiếng gốc và lồng tiếng; âm thanh và video không bị lệch hoặc chồng giọng.
6. Mở phần phân tích AI: bản Việt không còn `<mark>`/`</mark>`, nội dung bên trong vẫn đủ và hỏi đáp dùng phân tích gốc.

Sau lỗi, Copy diagnostics kèm link video, vị trí tua, thao tác và trạng thái. Trường mới: `gtx_cooldown_seconds`, `gtx_gemini_fallback`, `caption_full_context_seconds`, `vbee_chunk_cues`, `vbee_prefetch_seconds`, `dubbing_chunks_ready/failed/total`, `dubbing_buffering`. Counters: `Comments Gemini fallback ...`, `Captions Gemini full context`, `Vbee rolling chunk ...`, `Dubbing buffer waiting/ready`, `Dubbing rolling anchor/playback failed`. Không cần gửi key/token hoặc signed URL.
