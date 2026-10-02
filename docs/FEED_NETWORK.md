# Featured/Tips — trạng thái 0.7

0.6 trên thiết bị: DC callbacks14, unknown App -4:5/-11001:9; feed thường initial4/loadmore7 lần thành công. Đây là hai luồng khác nhau. Chưa có bằng chứng rằng hai tab lỗi do đăng nhập hay original IPA hỏng; báo cáo không chỉ rõ domain.

Static native JSON serializer tạo **com.aweme.network.error -11001** khi input không đúng dạng hoặc chuyển NSData thành dictionary thất bại. Domain phải khớp mới áp dụng nghĩa này. 0.7 thêm whitelist domain và observer giữ nguyên return/error pointer, phân loại input/HTTP/MIME và transport error phù hợp; không ghi raw payload/URL/header. Không giả thành công, không đổi chunk/protobuf/JSON transport hay xóa tab khi chưa có bằng chứng.

Hai tab quan trọng nếu cần chính các feed đó; lỗi hiện tại không làm feed thường/Nearby/LIVE đồng loạt hỏng theo dữ liệu đã cung cấp. 0.7 chưa sửa root cause của hai tab. [Kế hoạch](PLAN-0.7.md) và [test từng phiên](DEVICE_TESTS.md). [Lịch sử 0.6](evidence/feed_network-0.6.0.md).
