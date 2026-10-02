# Featured/Tips — trạng thái 0.8

0.7: serializer có 23 lỗi AwemeNetwork/-11001 với NSData; DC feed có 8 lỗi cùng domain/code và 7 App/-4 chưa rõ domain. Không quy tất cả counter serializer cho Featured/Tips. Feed thường có initial/load-more thành công. Thông báo chuyển dictionary khớp native serializer; chưa có bằng chứng do chưa đăng nhập hoặc IPA bị hỏng.

Featured vài video lặp và Tips chớp rồi báo lỗi phù hợp với placeholder/nội dung sẵn có bị request lỗi đưa về dataState8 → error page10. Nguồn vài video đó chưa được chứng minh.

0.8 chọn bộ tải thông thường native nếu đường khối được bật và bộ tải thay thế đủ class/ABI. Giữ cursor, hasMore, response/error và retry; không gán thành công khi request thất bại, không xóa tab. **Đây là sửa tương thích theo giả thuyết có cơ sở, chưa có kết quả iPhone chứng minh đã hết lỗi.**

Diagnostics mới: DC transport original chunk/standard, standard selected/unavailable; DC completion request initial/refresh/load more; HTTP/MIME và JSON size/prefix/strict decode. Không gửi dữ liệu mạng nhạy cảm. [Kế hoạch](PLAN-0.8.md), [research](RESEARCH-0.8.md), [test](DEVICE_TESTS.md), [lịch sử 0.7](evidence/feed_network-0.7.0.md).
