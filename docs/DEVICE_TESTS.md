# Nghiệm thu Douyin thật — 0.18.1

Các bước này còn cần chạy trên iPhone thật. Ký/cài IPA riêng như trước, kiểm tra Copy diagnostics là `0.18.1-test`, `tts_enabled: false`, `source_language: zh-CN`.

1. Mở các video tiếng Trung 10–30 giây, 1–3 phút và 5–9 phút, đặc biệt video từng báo rỗng/mốc không nhất quán. Chạm nhanh 4 lần. Video phải dừng, có phụ đề rồi mới phát tiếng gốc; không tạo giọng và không đổi tốc độ. Bấm Hủy/Bỏ qua phải phát lại chủ động.
2. Xem video kế tiếp liên tục, quay lại video cũ, tắt/bật phụ đề: không giữ chữ/video/job cũ, cache thành công không gọi lại API. Thử nguồn native hết hạn: dùng Apify hữu hạn, không bị kẹt sau video đầu.
3. Đọc câu dài, thoại nhanh, khoảng lặng, nhiều người nói và lời ở cuối video. Mỗi màn hình chỉ có tối đa 3 dòng dọc/2 dòng ngang. Trang chỉ hiện trong mốc câu gốc; khoảng im lặng không giữ chữ câu trước. Pause không chuyển trang; tua lùi/loop đưa đúng câu/trang theo đồng hồ video.
4. Kéo phụ đề lên/xuống, xoay ngang/dọc, đổi cỡ chữ hệ thống. Không che rail nút phải/thanh điều hướng; mô tả mở rộng có thể cần kéo phụ đề cao hơn. Không cắt dấu tiếng Việt hoặc hiện dấu ba chấm thay phần nội dung chưa đọc.
5. Video trên 10 phút: đoạn đầu đã dịch có thể phát khi phần sau đang dịch. Tua vào đoạn chưa có bản Việt phải dừng chờ đúng đoạn; đoạn dịch xong thì phát lại, không hiện câu của đoạn khác. Hủy/đổi video trong lúc tải/dịch không áp dụng kết quả trễ.
6. Mất mạng, quota, tệp không có audio, kết quả ASR rỗng: thông báo phân biệt đúng lỗi. Remote rỗng có tối đa một lượt gửi audio kiểm chứng; rỗng lần nữa dừng, không gọi API liên tục. Không được báo quá 60 phút chỉ vì không nhận ra lời.
7. Kiểm tra lại bình luận GTX/Gemini, bảng Việt có cuộn, Bản gốc có ảnh/trả lời; phân tích AI không hiện `<mark>`, native/web/OCR chỉ lấy đúng vùng đang thấy. Các chức năng giữ từ 0.18 đã có kiểm thử Simulator.
8. Phát nền tiếng gốc: khóa máy/chuyển app, pause/play màn hình khóa, quay lại đúng mốc, dừng trước khóa, rút tai nghe và cuộc gọi. Không chồng tiếng, không giữ mute từ video cũ.

Sau lỗi, gửi Copy diagnostics, link video và thao tác/mốc xảy ra. Counters mới gồm `Captions native source selected/fallback`, `Captions Deepgram empty remote recovery`, `Captions Deepgram binary upload`, `Captions Deepgram empty verified audio`, `Captions ASR rejected`, `Captions timed utterance fallback`, `Captions timing repaired`, `Captions translation buffer waiting/ready`. Không gửi key, session hoặc signed URL.
