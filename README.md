# Douyin Guest — bản thử 0.10.0

Dành riêng cho Douyin **40.6.0/build406019/arm64**, iPhone 15/iOS18.5. Cần ký bằng Sideloadly. IPA gốc và các bản cũ giữ cục bộ; không đăng binary độc quyền lên repo.

**Đã triển khai bản thử sửa feed và thông báo phát nền. Chưa xác nhận hiệu quả trên iPhone thật.**

- Feed: bộ dựng body của đường tải JSON bỏ đúng cờ `is_tidy = "true"` trong dictionary tạm khi Feed compatibility ON. Giữ lỗi thật, nội dung và phân trang. Log phân loại bộ tải đang được gọi để phân biệt đường chưa được hỗ trợ.
- Background audio: phục hồi thông báo bị bỏ lỡ chỉ khi đúng model/delegate native, đúng chủ phiên Now Playing, không bị người dùng tạm dừng và quyết định native cho phép phát nền. Không tự gọi play hoặc chiếm phiên âm thanh khác.
- Thêm 5 nhãn/placeholder AI tiếng Anh; có 898 mục dịch. UI hybrid trong ảnh chưa được xác nhận dịch hết. Không mở chat AI bằng phiên đăng nhập giả; không bảo đảm search/bình luận guest không giới hạn.
- Featured/Tips vẫn được giữ. OFF rồi restart khôi phục hành vi gốc; không xóa data/cache.

File cục bộ: `dist/Douyin-40.6.0-Guest-0.10.0-iPhone15-TEST.ipa`. SHA-256 `c6d934945066f8830642e3ff5a3b64cc832b4730651b932f7fb4221753b31f9b`.

[Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.10.md) · [Nghiên cứu](docs/RESEARCH-0.10.md) · [Validation](docs/VALIDATION.json) · [Test iPhone](docs/DEVICE_TESTS.md).

[CI thành công](https://github.com/phucdinhIA/Douyin/actions/runs/36979226991): 18 Python, Foundation contracts, arm64 warnings-as-errors/signature, 105/105 UIKit fixture. Fixture không chạy Douyin/máy chủ.

```text
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.10.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_SUCCESSFUL_ARTIFACT
```

Không thay schema dữ liệu; giữ cùng định danh ký và các bản trước để rollback.
