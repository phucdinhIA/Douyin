# Trạng thái kiểm chứng

Candidate: **0.1.0-test**. Chưa phát hành bản hoàn chỉnh.

| Hạng mục | Trạng thái |
|---|---|
| Hash/identity mẫu gốc | Đã đối chiếu với audit trước |
| Metadata của 30 hook | Đã đối chiếu selector, kiểu và method kind |
| Từ điển | 278 label, chưa kiểm chứng bao phủ toàn giao diện |
| Python tests | Đang hoàn thiện/chạy; kết quả CI là nguồn xác nhận |
| Foundation tests và build arm64 | Chờ workflow chạy |
| Đóng gói và hash toàn bộ IPA output | Chờ artifact build |
| Cài và mở trên iPhone 15/iOS 18.5 | Chưa kiểm tra |
| Không popup, không ad, layout tiếng Anh | Chưa kiểm chứng runtime |
| Video máy chủ hạn chế | Không mở vượt quyền xác thực |

Các báo cáo build/đóng gói sẽ cập nhật sau khi có kết quả thực tế. Không suy ra thành công chức năng từ việc biên dịch thành công.
