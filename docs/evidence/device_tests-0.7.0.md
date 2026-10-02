# Nghiệm thu 0.7 trên iPhone 15 / iOS 18.5

Ký/cài `Douyin-40.6.0-Guest-0.7.0-iPhone15-TEST.ipa` bằng Sideloadly. Giữ bản cũ và dữ liệu app; không cần gỡ app. Hai ngón tay chạm ba lần → Douyin Guest; Copy diagnostics phải ghi 0.7.0-test, app40.6.0, expected75. Kiểm tra installed/active/mismatch/overwritten.

| Ca | Thao tác / tiêu chí |
|---|---|
| Ngang | Tắt Portrait Orientation Lock trong Control Center. Mở video ngang có Full screen, chạm nút rồi xoay hai phía; quay lại portrait. Ghi nút không xuất hiện, không chuyển hướng hay layout lỗi. Feed dọc không bắt buộc tự xoay |
| Khóa màn hình | Background audio ON, đóng/mở app, phát video có tiếng; khóa 30 giây, mở khóa, tiếp tục thử 2 phút. Ghi thời điểm dừng và độ dài video |
| Pause | Pause trước khi khóa: không tự bật tiếng |
| Lifecycle | Chuyển Home/app khác rồi quay lại 5 lần: không hai luồng âm thanh/màn đen/crash; thử interruption và tháo tai nghe, giữ native handling |
| Background OFF | Tắt rồi restart, đối chiếu cùng video; trả native config, không ép preference gốc thành OFF nếu đã được bật từ trước |
| Featured | Phiên riêng: vào Featured → Retry một lần → Copy diagnostics ngay |
| Tips | Phiên riêng: vào Tips → Retry một lần → Copy diagnostics ngay |
| Search native | Nhập tên hai lần, ghi lỗi/login/kết quả và Copy diagnostics; không cần đăng nhập |
| Web finder | Hai ngón tay chạm ba lần → Find public profiles (web) → tên → Search. Kiểm tra browser mở; chọn official profile nếu có, ghi guest có xem được video không. Tên tiếng Trung chính xác thường hữu ích hơn phiên âm |
| Profile link | Open public profile link → dán official HTTPS /user/ URL. Kiểm tra không mở link ngoài miền hoặc path không hợp lệ |
| Comments/LIVE/UI | Mở bình luận, kéo thêm và thử thumbnail trắng sau 15–30 giây/chạm. Kiểm tra năm tag LIVE, menu, font lớn và nút không tràn; comment/chat/tên người dùng không bị dịch |
| Hồi quy | Feed/Nearby/LIVE 30 phút, 5 cold start, mất/khôi phục mạng; so ad/login/English OFF sau restart nếu gặp lỗi |

Diagnostics mới cần phân biệt `AwemeNetwork`/`AwemeAPI`/domain khác, `JSON response input`, `HTTP`, `content type` nếu đúng nhánh serializer. Nếu không có các counter này, không suy ra có HTTP thành công hoặc JSON hợp lệ. Các counter ảnh là toàn app/có retry, không phải số ảnh bình luận duy nhất.

Phát nền cần quan sát `enableBGPlayComponent preference ON`, module `viewDidAppear`, notification, player/module decision YES/NO, entry/exit/backgroundIsPlaying. Hook installed không chứng minh đã chạy hoặc nghe được tiếng. Xoay có `AWELandscapeFeedViewController shouldAutorotate` nếu đúng màn hình native.

Chỉ gửi diagnostics và hành vi; không cần cookie/token hoặc payload mạng. **Chưa nghiệm thu** khi bất kỳ chức năng yêu cầu vẫn lỗi hoặc chưa được thử trên thiết bị.
