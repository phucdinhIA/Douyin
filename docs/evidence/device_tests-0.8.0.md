# Nghiệm thu 0.8 trên iPhone 15 / iOS 18.5

Ký/cài IPA 0.8 bằng Sideloadly. Giữ dữ liệu app và bản đã ký trước đó. Đóng hẳn rồi mở lại. Hai ngón tay chạm ba lần → Douyin Guest: Feed compatibility phải ON; Copy diagnostics phải ghi 0.8.0-test/app40.6.0/expected76. Installed/active không đủ để chứng minh bộ tải đã chạy.

1. **Featured riêng:** vào tab, Retry/refresh một lần, kéo qua ít nhất 20 video hoặc tới cuối dữ liệu app cho phép. Kiểm tra có video mới khi tải trang tiếp, không chỉ vài video lặp; không có lỗi chuyển dictionary. Copy diagnostics ngay.
2. **Tips riêng:** đóng/mở app để tách phiên, vào Tips, Retry một lần, chờ 30 giây, mở video và kéo thêm trang. Kiểm tra không chớp danh sách rồi bị error page che. Copy diagnostics ngay.
3. **Khi còn lỗi:** gửi hai JSON theo từng tab cùng thông báo hiển thị. `DC transport standard selected` chứng minh tương thích đã được áp dụng; `original standard` nghĩa app vốn dùng đường thường, hook không đổi nó; `compatibility unavailable` nghĩa không ép vào bộ tải thiếu/sai ABI. HTTP/content/prefix/decode giúp chọn bước tiếp, không cần cookie/token/payload.
4. **Rollback nếu hành vi xấu đi:** Feed compatibility OFF rồi restart. Không cần gỡ app/xóa cache. Đối chiếu cùng tab, gửi kết quả ON/OFF nếu khác nhau.
5. **Hồi quy:** feed thường/Nearby/LIVE, Search/web finder, mở bình luận/ảnh, phát nền khóa màn hình và video ngang theo [bộ test 0.7](device_tests-0.7.0.md). Những tính năng này chưa được nghiệm thu chỉ từ CI.

Chỉ cần một lần thử mỗi tab và một lần cuộn nhiều trang; không cần bấm Retry liên tục. Nếu có crash, dừng bản thử và dùng bản đã ký trước. Bản 0.8 chưa thể gọi là hết lỗi trước kết quả thiết bị.
