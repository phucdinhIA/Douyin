# Nghiệm thu Douyin thật — 0.18

Ký/cài IPA riêng như trước; kiểm tra tên Douyin và diagnostics `0.18.0-test`. Các bước dưới đây còn cần chạy trên iPhone thật; môi trường hiện tại chỉ có build, Simulator và API thật.

1. Mở bình luận chữ Trung ngắn/dài, có ảnh và trả lời. Bảng Tiếng Việt phải xuống dòng/cuộn đầy đủ. Chọn Bản gốc: trả lời/xem ảnh/cuộn phải hoạt động, chữ đầu không bị thanh ngôn ngữ che. Đóng/mở lại, mở replies và controller lồng nhau phải chỉ có một bảng. GTX 429 phải ghi Gemini và dịch dự phòng; lỗi cả hai phải dừng tới khi bấm thử lại.
2. Mở Phân tích AI có renderer native/web/chữ vẽ. Bản dịch phải cuộn được, không hiện `<mark>`. OCR phải ghi “vùng phân tích đang hiển thị”; không được tự nhận đó là toàn bộ bài. Rời tab trong lúc capture/dịch không đưa kết quả cũ sang tab/video khác. Hỏi đáp vẫn đọc nguồn gốc.
3. Chạm bốn lần video lời Trung 15–60 giây, 1–3 phút và 5–9 phút: dừng trước xử lý, Claude dịch toàn transcript, ba câu Nam Minh đầu sẵn thì phát và tạo phần tiếp trong lúc xem. Bốn chạm thêm không tạo job trùng. Thử video tiếp theo liên tục để tìm lỗi trạng thái cũ.
4. Tua xa khi TTS đang tải: ưu tiên vị trí mới, dừng nếu nhóm đó chưa sẵn; tua lùi/loop dùng cache. Kiểm tra biên nhóm, khoảng lặng, pause/resume, câu cuối, nhiều người nói và tốc độ 1x/1.5x. Tắt hoặc đổi video phải trả tiếng gốc và tốc độ trước đó; tốc độ người dùng đổi sau khi lồng tiếng bắt đầu phải được giữ.
5. Mất mạng/nhóm TTS lỗi: giữ phụ đề và tiếng gốc cho nhóm đó, không lặp POST trả phí vô hạn; nhóm sau tiếp tục khi có thể. Bật lại chủ động dùng ASR/bản dịch/MP3 đã cache. Kiểm tra tài khoản hết phiên và hạn mức: đăng nhập lại hữu hạn hoặc thông báo rõ.
6. Phát nền: khóa máy/chuyển app 30–60 giây, điều khiển màn hình khóa, trở lại app, dừng trước khóa, rút tai nghe và cuộc gọi. Thử tiếng gốc và lồng tiếng, không chồng giọng hoặc sai mốc.

Sau lỗi, Copy diagnostics kèm link video, vị trí/thao tác và trạng thái. Trường mới: `translation_model: claude-sonnet-5`, `narration_voice: vi-VN-NamMinhNeural`, `narration_chunk_cues`, `narration_prefetch_seconds`, `dubbing_buffering`, `dubbing_chunks_ready/failed/total`. Counters có `AI local OCR started`, `AI rendered source captured`, `AI Claude translation sent`, `Comments translated rows`, `Nam Minh rolling chunk ready/failed`, `Nam Minh seek reprioritized`, `Dubbing balanced video rate`. Không gửi key/session/signed URL.
