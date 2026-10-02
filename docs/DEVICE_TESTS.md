# Kiểm tra 0.5.0 trên iPhone 15 / iOS 18.5

0.4.0 đã được người dùng chạy; 0.5.0 chưa chạy. Ký/cài `Douyin-40.6.0-Guest-0.5.0-iPhone15-TEST.ipa` bằng Sideloadly, chọn lại đúng file; giữ dữ liệu/candidate cũ. Không đổi hẳn bundle ID. Hai ngón tay chạm ba lần → Douyin Guest → Copy diagnostics.

## Vòng ngắn để lấy bằng chứng đúng lỗi

| Ca | Thao tác | Ghi nhận |
|---|---|---|
| Phiên bản | Mở app, Copy diagnostics | 0.5.0-test; fixed expected 50; active/installed và mọi mismatch/overwritten |
| Featured | Đóng hẳn/mở, chỉ Retry Featured 1 lần, Copy diagnostics | DC/generic feed callbacks, numeric response status và category/code; tab vẫn giữ, chữ không cắt |
| Tips | Đóng hẳn/mở, chỉ Retry Tips 1 lần, Copy diagnostics | Tách khỏi lần Featured để ghép lỗi; toast tiếng Anh, không fake success |
| Search | Đóng/mở, Search diagnostics ON, nhập từ khóa công khai 2 lần, Copy diagnostics khi lỗi | Invocation/nil/compatible, status2483 hoặc mã khác; native quota giữ nguyên, adapter installed/active0 theo thiết kế |
| Ảnh comment | Đóng/mở, mở comment, ghi thời gian ảnh trắng; Copy diagnostics lúc trắng rồi sau 15–30 giây hoặc sau chạm/đợi | So sánh image failures/finish counters; image SDK bao phủ toàn app nên không kết luận mọi counter là ảnh comment |
| Bình luận | Cuộn đến khi không tải thêm hoặc nhắc login, Copy diagnostics | CommentArray accesses/item samples và response status; samples không phải số comment duy nhất; ghi còn cuộn được hay không |

Chạm ảnh để xem và nhấn giữ để mở menu là hai luồng khác nhau. Không đăng nhập để lấy bằng chứng này. Nếu app hỏi login khi đọc thêm/search, ghi nhận yêu cầu thật; bản sửa chưa chứng minh quyền đó có cho guest.

## Giao diện và hồi quy

- Comment header/count, AI summary, prefix collection, reply controls, survey question/five ratings, bottom login notice, toast; comment bodies/usernames/titles gốc giữ nguyên. Kiểm vùng link collection bấm đúng và Back trở về đúng.
- Search/filter/sidebar/Settings/player/privacy/notifications; font mặc định/lớn, light/dark, portrait/landscape. Chữ không tràn, vùng bấm và nội dung không bị rewrite. Ghi control còn Trung hoặc bị cắt; không coi toàn bộ Lynx đã dịch chỉ vì fixture đạt.
- LIVE/Nearby/luồng public khác: pause/resume/seek, video ảnh/ngang/dài, cuộn 30 phút, 5 cold start và 5 background/foreground; ghi crash/màn đen hoặc server dừng cấp feed.
- OFF từng ad/login/English, đóng/mở để đối chiếu; đổi Wi-Fi/di động; tắt/bật mạng và Retry. Không xóa cache/tài khoản hay dùng retry liên tục. Like/post/follow giữ yêu cầu tài khoản; không báo thành công giả.

**Chưa đạt nghiệm thu hoàn chỉnh** nếu Featured/Tips vẫn lỗi, ảnh vẫn trắng chậm, control bị cắt/dịch nhầm, app crash hoặc guest không được server cấp kết quả. Gửi diagnostics từng phiên cùng hành vi tương ứng để phân biệt các nhánh; không cần gửi cookie/token.
