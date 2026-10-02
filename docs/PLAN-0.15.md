# Sửa đường vào GTX và phụ đề — 0.15

## Bằng chứng từ iPhone

Người dùng báo nút phụ đề chỉ hiện trên một số video, bấm không thấy phản hồi; GTX không dịch được. Diagnostics 0.14: cấu hình media có đủ, 7 hook đã cài, `GTX visible comments unavailable` = 4. Không có counter `Captions opt-in` hay counter gọi nhà cung cấp phụ đề. Vì vậy lỗi đọc bình luận đã được xác nhận; chưa có bằng chứng cho lỗi API phụ đề. Việc hook được cài không chứng minh đúng màn hình đã đi qua hook hoặc nút nhận được chạm.

## Thứ tự xử lý

1. Gắn recognizer một ngón/chạm nhanh 4 lần lên key window, độc lập với `viewDidAppear`. Không chạy API khi chỉ gắn gesture hoặc khôi phục UI. Giữ thao tác gốc, không chặn touch.
2. Tìm player thực đang hiển thị dưới điểm chạm qua responder/hệ cây controller. Loại control, ô nhập, bàn phím, bình luận/AI, player ẩn và player phía sau modal. Đọc getter đúng ABI; bổ sung `itemID` của player đã kiểm chứng trong IPA.
3. Gắn nút/phụ đề lên window để lớp điều khiển video cùng cấp không che thao tác. Chỉ hiển thị bộ điều khiển của player hiện tại. Khôi phục UI khi app/key window được kích hoạt; gesture vẫn có thể gắn UI theo yêu cầu nếu lifecycle bị bỏ qua.
4. Tạm dừng player trước Apify. Giữ dừng trong lúc nhận dạng/dịch toàn bộ; theo dõi `isPlaying` để ngăn native tự chạy trước. `ready`/`cached` cho phát lại cùng video. Lỗi vẫn giữ dừng theo yêu cầu: hiện nút **Bỏ qua · phát video** để người dùng quyết định. Hủy thủ công trả quyền phát lại; đổi video, rời màn hình/chuyển nền hủy mà không phát lại video cũ.
5. Đọc GTX từ các lớp ô bình luận đã kiểm chứng (`commentModel` → `AWECommentModel.content`) và label bình luận native. Duyệt window để bao phủ phần render cùng cấp nằm ngoài controller được hook. Không bỏ cây con của wrapper không clipping có kích thước 0. Tôn trọng clipping, ẩn và vị trí ngoài màn hình; không đọc label tùy ý, tên hay phân tích AI.
6. Thêm đường vào **Dịch bình luận · GTX** trong menu hai ngón/chạm 3 lần. Chỉ gửi Google khi người dùng chọn dòng, giữ bản gốc và cache riêng.
7. Test nhỏ và tổng thể: biên dịch arm64 với warnings-as-errors, fixture iOS, service/cache regressions, đóng gói riêng và đối chiếu toàn archive với IPA gốc. Sau đó mới bàn giao IPA thử trên iPhone; không suy diễn test lớp giả thành nghiệm thu máy thật.

## Luồng phụ đề

Chạm 4 lần → chọn đúng player/ID/clock → tạm dừng → cache hoặc Apify `videoUrl` → Nova-3 Mandarin/word timestamps → Gemini Việt theo nhóm 8 rồi 16 cue → kiểm tra cấu trúc/ngôn ngữ → lưu track hoàn tất → phát lại → cập nhật chữ theo clock player mỗi 100 ms. Bấm lại 4 lần khi đang làm/đang hiện không hủy và không thêm yêu cầu trả phí; nút **Hủy phụ đề** thực hiện hủy.

Dịch vụ và tối ưu clip dưới 10 phút giữ từ [nghiên cứu 0.14](MEDIA-0.14.md): prerecorded toàn clip, ưu tiên nhóm quanh vị trí phát, không tự retry trả phí, cache ASR/partial/final, giới hạn 60 phút. Không cam kết độ trễ tức thì; lần đầu cần chờ API, lần sau dùng cache.

## Xác minh IPA và giới hạn

Đã đọc metadata và disassembly gốc của `pause` (BOOL), `resumePlayVideo` (void), `isPlaying` (BOOL), `itemID` (object) và `AWECommentNewFeedCell.commentModel`. Player pause/resume có nhánh container mới và nhánh player cũ; dùng entry native của controller, không đọc offset ivar đoán hoặc giả trạng thái đăng nhập.

Test mới phải bao phủ: recognizer chỉ 4 tap/1 ngón, idempotence, player nhúng/lifecycle bỏ qua, overlay native, modal/control/player ẩn, pause trước request, tự chạy lại trong lúc chờ, resume khi hoàn tất/lỗi/hủy, không resume khi chuyển nền, GTX model không label/wrapper/clipping/offscreen/render sibling, đường vào menu. Provider thật đã được probe ở 0.14; thay đổi này chủ yếu sửa UI/routing, không lặp thêm request trả phí khi không cần.

Tại thời điểm nhận lỗi, chưa có truy cập iPhone để chạy Douyin thật. Nghiệm thu máy thật vẫn cần quan sát nút, chạm 4 lần, video dừng/chạy lại, chữ Việt theo lời nói và GTX sau khi cài bản mới.
