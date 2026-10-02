# Phụ đề và dịch bình luận 0.14

Chỉ tạo phụ đề sau khi bấm **Phụ đề Việt** trên video. App lấy `itemID` từ model đang phát, gửi URL Douyin chuẩn cho actor, lấy `videoUrl`, gửi URL đó tới Nova-3 với `language=zh-CN`, rồi dịch chữ sang tiếng Việt bằng Gemini Flash-Lite. `audioUrl` của actor có thể chỉ là nhạc nền, nên không dùng làm nguồn lời nói.

Ứng dụng giữ các mốc thời gian; Gemini nhận ID/chữ và tiêu đề để hỗ trợ tên riêng. Schema yêu cầu đúng số dòng, bản dịch dài 1–500 ký tự; parser kiểm tra ID/thứ tự/STOP và chữ không rỗng. Nếu một câu vẫn lẫn chữ Hán, app dịch lại nguyên câu Trung gốc bằng GTX miễn phí, giữ ID/thời gian và không gọi lại Gemini. Chỉ các nhóm hợp lệ được lưu và hiển thị; GTX fallback lỗi hoặc vẫn còn chữ Hán thì báo lỗi để thử lại thủ công. Từ chồng thời gian được giữ trong cùng cue; phần đuôi vượt thời lượng tối đa 2 giây được kẹp và đánh dấu, sai lệch lớn hơn báo lỗi.

Video dưới 10 phút được ưu tiên: nhóm đầu tối đa 8 cue để sớm có chữ, các nhóm sau tối đa 16 cue. Timer đọc `currentPlaybackTime` thật mỗi 100ms và ưu tiên vị trí mới nhất trong lúc chờ. Các nhóm đã dịch hiện ngay; không chờ dịch cả clip. Tua/dừng/lặp dùng thời gian player, khoảng lặng ẩn chữ. Video tối đa 60 phút được hỗ trợ trong giới hạn 50.000 từ/2.400 cue; link người dùng cung cấp dài khoảng 45 phút.

Cache phụ đề lưu transcript, tiêu đề và từng nhóm dịch, tối đa 32 mục/8 MiB, tách cache bình luận GTX để các lượt dịch bình luận không đẩy transcript trả phí ra khỏi cache. Bật lại track hoàn tất không gọi API; thử lại sau lỗi Gemini dùng transcript đã lưu. Đổi video/đóng màn/chuyển nền hủy và xóa overlay, callback cũ không cập nhật màn mới. Không tự lặp yêu cầu trả phí; actor giới hạn 90 giây, một kết quả và $0,05 mỗi run. Nhà cung cấp vẫn có thể tính phí yêu cầu đã nhận trước khi hủy.

**Dịch bình luận** mở danh sách bình luận đang nhìn thấy. Chạm một dòng để dịch GTX sang Việt; chữ gốc giữ nguyên. Chỉ lấy exact native comment-label class, loại view ẩn, tên người dùng và renderer AI. Kết quả được cache. GTX là endpoint công khai không có cam kết SLA/quota; khi lỗi mạng hoặc giới hạn lượt, app báo lỗi để thử lại thủ công.

## Tài liệu và lựa chọn actor

- [Deepgram models/languages](https://developers.deepgram.com/docs/models-languages-overview): Nova-3 hỗ trợ Mandarin/`zh-CN`.
- [Prerecorded audio](https://developers.deepgram.com/docs/pre-recorded-audio) và [utterances](https://developers.deepgram.com/docs/utterances): nhận URL/binary, word timestamps và punctuation.
- [Apify chạy actor](https://docs.apify.com/api/v2/act-runs-post), [dataset items](https://docs.apify.com/api/v2/dataset-items-get), [abort](https://docs.apify.com/api/v2/actor-run-abort-post).
- [apple_yang/douyin-video-audio-downloader](https://apify.com/apple_yang/douyin-video-audio-downloader), build 0.1.43: input `videoUrls`, output `url/title/videoUrl/audioUrl/duration/errMsg`. Schema được lấy từ build vì endpoint input-schema không truy cập được trong lần nghiên cứu.
- [Gemini structured output](https://ai.google.dev/gemini-api/docs/structured-output), [API discovery Schema](https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta): hỗ trợ min/maxItems và min/maxLength. Các ràng buộc này đã được gọi API thật thành công.

Trên mẫu 67,8 giây, apple_yang mất 8,82 giây để trích link; zen-studio mất 15,86 giây. easyapi bị dừng ở mức chi phí thử $0,05, nên không có kết quả thành công tương đương để so tốc độ. apple_yang cũng trích được mẫu người dùng trong 8,57 giây. Đây là so sánh giới hạn trên hai mẫu, không chứng minh nhanh nhất trên mọi video.

Nova-3 xử lý mẫu ngắn trong 31,53 giây; nhóm dịch đầu 8 cue trong 2,34 giây, cả 15 cue trong 4,23 giây. Cộng các chặng đã đo khoảng 43 giây tới nhóm đầu, **không phải phép đo trực tiếp toàn luồng trên iPhone**. Lần xem lại có cache không cần các chặng này. Prerecorded nhận dạng cả clip; phụ đề chưa có ngay khi vừa nhấn.

Thử tách âm thanh AAC bằng ffmpeg rồi upload: 22,73 giây tách + 4,47 giây nhận dạng. Chưa đo được AVFoundation trên iPhone; bản giao dùng URL trực tiếp đã thử, tránh thêm tải/chuyển mã trên thiết bị. Không gửi hai lượt nhận dạng song song để thử vận may.

Mẫu 45 phút: Nova-3 trả 7.626 từ/149 utterances trong 140,69 giây; có 594 cue tiếng Việt hợp lệ sau các lần thử dịch thủ công dùng lại transcript. Đã có hai thử nghiệm batch không đạt do dòng rỗng/gộp ý; chúng bị từ chối. Bốn câu còn lẫn chữ Trung đã được thử GTX trên câu gốc: cả bốn trả chữ Việt, mỗi câu 0,62–1,36 giây. SRT mẫu được sửa bằng các kết quả fallback đó. Số 45,25 giây trong evidence chỉ đo phần tiếp tục 234 cue cuối sau sửa schema, không phải thời gian dịch toàn video. Tên riêng và độ chính xác lời nói vẫn cần đánh giá trên video thực; confidence không phải chứng nhận chất lượng.

[Probe đã lọc thông tin](evidence/0.14-service-probes.json) · [ABI](evidence/0.14-media-abi.json) · [SRT mẫu ngắn](evidence/0.14-short-video-vi.srt) · [SRT video người dùng](evidence/0.14-user-video-vi.srt).

Key cá nhân chỉ được nhúng khi đóng gói tại máy; Git/CI dùng key giả. Các request provider tách credentials, không cookie Douyin và không chuyển key theo redirect. Diagnostics chỉ lưu trạng thái/counters, không transcript, media URL hay key. Phụ đề là tích hợp riêng, không thay đổi xác thực Douyin.
