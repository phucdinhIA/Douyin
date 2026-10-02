# Nghiệm thu 0.9 — iPhone 15 / iOS 18.5

Ký/cài IPA 0.9 bằng Sideloadly cùng định danh trước đó; giữ dữ liệu app và bản đã ký cũ. Đóng hẳn/mở lại app. Hai ngón tay chạm ba lần → Douyin Guest → Feed compatibility ON. Copy diagnostics phải ghi 0.9.0-test/app40.6.0/expected78.

1. **Featured:** mở riêng, Retry một lần nếu cần, kéo xuống refresh rồi cuộn vài trang. Ghi có video mới hay chỉ lặp/không có video, có conversion/CSP/Retry che nội dung không. Copy diagnostics ngay.
2. **Tips:** đóng/mở lại để tách bộ đếm phiên, mở Tips, chờ 30 giây rồi mở video và cuộn thêm trang. Ghi có hết nháy danh sách rồi quay về Retry không; có video mới không. Copy diagnostics ngay.
3. **Nếu vẫn lỗi:** gửi JSON theo từng tab và thông báo chính xác. Counter `enableChunkRequest standard format selected` cho thấy định dạng được chuyển; `DC transport standard selected` cho thấy outer manager chuyển luồng; Installed chỉ cho biết gắn hook. Nếu không thấy counter selection, cần xác định controller thực sự thay vì tiếp tục đoán decoder.
4. **Đối chiếu/rollback:** Feed compatibility OFF rồi restart; thử lại một lần mỗi tab, giữ nguyên tùy chọn khác. Không xóa data/cache. Giữ bản đã ký trước đó nếu cần quay lại.
5. **Hồi quy:** feed thường/Nearby/LIVE, bình luận/ảnh, Search/web finder, âm thanh khi khóa màn hình, video ngang theo [bộ test 0.7](device_tests-0.7.0.md). CI không thay thế kiểm tra thiết bị.

Không cần Retry liên tục. Bản này vẫn là TEST cho đến khi refresh/phân trang và lỗi hiển thị được xác nhận trên iPhone.
