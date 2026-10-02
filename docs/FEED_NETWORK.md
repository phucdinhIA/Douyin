# Featured/Tips — trạng thái 0.9

0.8 không chọn luồng tương thích lần nào trong hai log. Báo cáo thứ hai tích lũy từ báo cáo trước: 20 callback DC, 12 lỗi AwemeNetwork/-11001, 7 lỗi domain chưa phân loại/-4 và 1 success. Đây không phải số request riêng theo tab. JSON app-wide có 22 HTTP200/NSData nhưng 10 rỗng và 12 prefix số/strict decode invalid. Tips có video mới rồi bị Retry che; Featured không có video. Không đủ bằng chứng để quy lỗi do đăng nhập hay IPA hỏng.

Native CSP-Domain/-4 được tạo trong nhánh EOF chưa hoàn chỉnh. Hai bộ tải hai cột có cờ enableChunkRequest điều khiển is_tidy. 0.9 chọn NO ở các class/ABI đã kiểm tra để bộ dựng body và bộ tải native chọn định dạng thông thường; outer manager cũng nhận diện hai controller này. Không tự giải mã payload hoặc đổi trạng thái thành công.

Diagnostics: tên cố định `AWEFeedDoubleColumnListDataController enableChunkRequest standard format selected` hoặc `AWESearchCachalotDCFeedDataController enableChunkRequest standard format selected`, `DC transport standard selected`, CSP/domain/code, HTTP/MIME/size/prefix. Counter selection chứng minh hook chạy, chưa chứng minh tải video mới thành công. Không xuất URL, cookie, buffer hoặc userInfo.

**Bản thử có cơ sở tĩnh và kiểm tra contracts, chưa nghiệm thu trên iPhone.** [Kế hoạch](PLAN-0.9.md) · [Nghiên cứu](RESEARCH-0.9.md) · [Test](DEVICE_TESTS.md) · [Lịch sử](evidence/feed_network-0.8.0.md).
