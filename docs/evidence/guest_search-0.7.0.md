# Search — trạng thái 0.7

0.5 có sáu status2483 và native handler báo limit; 0.6 không có Search callback trong phiên được gửi. Không suy ra Search đã được sửa. Native guest policy/quota và yêu cầu tài khoản vẫn giữ nguyên; không giả phiên đăng nhập.

0.7 thêm **Find public profiles (web)**: mở Bing với truy vấn tên giới hạn vào Douyin /user/. **Open public profile link** kiểm tra miền HTTPS/path chính thức, bỏ tracking query rồi mở browser. Chỉ gửi tên khi người dùng chạm Search; không ghi tên vào diagnostics. Đây là phương án tìm kênh qua web; chưa chứng minh tất cả kênh/video có thể xem guest. Không tăng quota native.

[Nghiên cứu đã đọc](../RESEARCH-0.7.md) không tìm thấy bằng chứng tương thích 40.6.0 iOS cho unlimited native guest search trong các file đã kiểm tra. Điều đó không khẳng định toàn bộ internet không có giải pháp. [Kiểm tra thiết bị](../DEVICE_TESTS.md). [Lịch sử 0.6](guest_search-0.6.0.md).
