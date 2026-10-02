# Featured/Tips — 0.10

0.9 vẫn lỗi: 22 callback DC đều thất bại, 13 conversion/-11001 và 9 CSP/-4. Cả hai hook direct format không có invocation counters và outer manager không chọn standard. Không tuyên bố 0.9 đã sửa đường thực tế hoặc gây regression qua một nhánh chưa chạy.

0.10 can thiệp bộ dựng body của đường JSON thông thường: original một lần, bỏ duy nhất is_tidy string true trong dictionary tạm; không đổi config, cursor, hasMore, auth hoặc lỗi. Đây là giả thuyết định dạng có cơ sở tĩnh, chưa phải nguyên nhân server đã được chứng minh. Nếu builder không chạy/không có flag, không có tác động sửa từ thao tác này.

Diagnostics mới: DC normal controller/inner controller với tên cố định; DC normal body builder calls, tidy negotiation removed/no tidy negotiation. Counter body removal xác nhận thao tác, chưa chứng minh request thành công. Unknown controller không bị cast/ép định dạng. Không xuất tên lớp tùy ý, URL hoặc body.

[Kế hoạch](../PLAN-0.10.md) · [Nghiên cứu](../RESEARCH-0.10.md) · [Test](../DEVICE_TESTS.md) · [Lịch sử](feed_network-0.9.0.md).

## 0.11

Giữ chiến lược feed 0.10; vòng này tích hợp Gemini, chưa có kết quả nghiệm thu feed mới trên máy thật. [Test](../DEVICE_TESTS.md).
