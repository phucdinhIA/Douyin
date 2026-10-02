# Douyin Guest — bản thử 0.9.0

Dành riêng cho Douyin **40.6.0 / build 406019 / arm64**. IPA gốc và các bản thử cũ được giữ cục bộ. IPA/binary không đăng lên repo public. Cần ký lại bằng Sideloadly.

**Đã sửa điểm chọn định dạng và bộ tải Featured/Tips; chưa xác nhận hết lỗi trên iPhone thật.**

- 0.8 chưa áp dụng luồng tương thích trong log người dùng. 0.9 hỗ trợ hai bộ tải hai cột native mà guard cũ bỏ sót; đồng bộ cờ yêu cầu dữ liệu dạng khối với nhánh đọc thông thường có sẵn. Feed compatibility mặc định ON, OFF và restart khôi phục quyết định gốc.
- Giữ lỗi thật, nội dung và phân trang. Không giả phiên đăng nhập, không thay nguồn video hoặc làm giả kết quả thành công. Featured/Tips vẫn được giữ.
- Giữ 893 bản dịch và các tính năng cũ; vòng này tập trung lỗi feed. Phát nền, xoay, guest search, toàn bộ bình luận và độ trễ ảnh chưa được nghiệm thu trên thiết bị.

File cục bộ: `dist/Douyin-40.6.0-Guest-0.9.0-iPhone15-TEST.ipa`. SHA-256 `20200a54134741c6f8e80f16bd6655ab9115941cb8d4b50cf893cec2edf519aa`.

[Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.9.md) · [Nghiên cứu](docs/RESEARCH-0.9.md) · [Validation](docs/VALIDATION.json) · [Kiểm tra iPhone](docs/DEVICE_TESTS.md).

[CI thành công](https://github.com/phucdinhIA/Douyin/actions/runs/36969913287): 17 kiểm tra Python, Foundation runtime contracts, build arm64 với warnings-as-errors, signature và 101/101 kiểm tra UIKit fixture. Fixture không chạy app Douyin hoặc máy chủ.

```text
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.9.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_SUCCESSFUL_ARTIFACT
```

Giữ cùng định danh ký khi nâng cấp và giữ bản đã ký trước đó để rollback. Không cần xóa app/data; không thay schema dữ liệu.
