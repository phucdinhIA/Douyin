# Nghiệm thu iPhone — 0.18.3

Chưa thực hiện trên máy thật. Ký/cài IPA riêng; Copy diagnostics phải là `0.18.3-test`, `native_source_fast_path: false`, `tts_enabled: false`.

1. Mở AI phân tích ở bình luận với đoạn dài từng báo “chưa trả đủ bản dịch theo từng mốc”. Bản Việt phải đủ nội dung, cuộn tới cuối được; không còn lỗi nhầm mốc khi câu Việt dài hơn 500 ký tự. Chỉ thấy một switch; chuyển Bản gốc phải đọc/scroll native, không bị status/retry che giữa nội dung. Rời AI trở về bình luận phải có lại reader bình luận.
2. Thử phân tích native/web/render vẽ, lần OCR đầu và mở lại cùng nội dung dùng cache. Đóng tab/đổi video khi đang dịch không được nhận kết quả cũ. Nếu lỗi, pane Việt báo lý do cụ thể và Dịch lại, không đè lên chữ gốc; diagnostics `gemini.translation_response` chỉ chứa số đếm/độ dài.
3. Bấm Phụ đề Việt trên các clip từng lỗi Claude: 10–30 giây, 1–3 phút, 5–9 phút, trên 10 phút. Đoạn đầu phải phát khi nhóm dịch đầu đã đủ; các nhóm sau tiếp tục đúng context và mốc. Video ít cue chỉ cần một lượt. Tua tới đoạn chưa có bản dịch phải đợi đúng đoạn; đã có phải phát được. Không ghép theo mốc backend.
4. Phụ đề phải cân bằng giữa hai bên, ở dưới ngay trên thanh điều hướng. Tối đa 3 dòng dọc/2 dòng ngang; kéo lên/xuống được và không vượt vùng an toàn. Pause/tua/loop/speech gap/cuối video không hiện nhầm câu; trang dài phải nằm trong start/end cue gốc. Không có TTS, chỉ audio gốc.
5. Trên clip đã chạy: quay lại phải dùng cache, không ASR lại. Thử khóa màn hình/phát nền. Mất mạng/quota không tự gửi lại; có nút bỏ qua/phát video. Kiểm tra duration fix 0.18.2 vẫn chạy cho video có audio ngắn hơn container và tiếng Trung Nova-3.
6. Nếu còn lỗi, Copy diagnostics ngay sau lỗi: xem `media.last_caption_timing.translation_response`, `translation_seconds`, `translation_check`, `stage`; không gửi key/session/audio/URL CDN có chữ ký. Phần timing matched_audio không đồng nghĩa dịch đã đủ, phải xem thêm translation_check.

Backend đôi lúc có thể trả thiếu hoặc trễ; kiểm thử hiện tại không chứng minh mọi clip/mạng đều hoàn hảo. Mốc câu lấy từ Nova-3; phân trang theo cue không phải forced alignment từng từ Việt.
