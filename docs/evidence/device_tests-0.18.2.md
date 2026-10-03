# Nghiệm thu iPhone — 0.18.2

Chưa thực hiện trên máy thật. Ký/cài IPA riêng; kiểm tra Copy diagnostics là `0.18.2-test`, `native_source_fast_path: false`, `tts_enabled: false`.

1. Bấm Phụ đề Việt trên các video trước đây đều báo duration mismatch. Chờ Apify → Nova-3 → Claude, sau đó video phát tiếng gốc và phụ đề. Không được có counter native source selected/binary upload chỉ vì player có currentPlayURL.
2. Kiểm tra liên tiếp ít nhất 5 video, video 10–30 giây, 1–3 phút và 5–9 phút; quay lại clip đã thành công phải dùng cache. So start/end với lời nói, khoảng lặng, cuối video, pause, tua và loop.
3. Video có đoạn cuối không có audio: khi cần, chỉ kiểm tra nguồn một lần rồi dùng lại ASR. Diagnostics có `input_mode: source_verified_remote`, `source_video_seconds`, `source_audio_seconds`, `deepgram_audio_seconds`, `duration_check: matched_audio`; không gửi lại Deepgram khi kết quả đã thành công.
4. Phụ đề chỉ 3 dòng dọc/2 ngang, kéo không vượt vùng an toàn; câu dài phân trang trong chính mốc câu gốc. Video dài đang dịch tiếp phải dừng khi tua vào lời nói chưa dịch và tiếp tục khi đúng đoạn đã sẵn sàng.
5. Hủy/đổi video/mất mạng lúc kiểm tra nguồn: không nhận kết quả cũ, không tự retry trả phí. Track không có audio hoặc audio thực sự không khớp phải báo lỗi rõ. Nếu lỗi mới, gửi Copy diagnostics ngay sau đó; phần `last_caption_timing` có các con số và stage để chẩn đoán đúng bước.
6. Kiểm tra lại GTX/Gemini bình luận, dịch phân tích AI và phát nền/khóa máy. Giữ âm thanh gốc, không tạo TTS.

Phân trang không khẳng định forced alignment từng từ Việt; mốc câu vẫn lấy từ ASR. Không cần gửi key/session hoặc URL CDN có chữ ký.
