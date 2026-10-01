# Nguồn tham khảo và quyết định

Đã đọc trực tiếp nguồn sau trong phiên triển khai ngày 2026-10-01. Nguồn internet được dùng làm tài liệu tham khảo, không chạy script hoặc đưa binary tải từ các dự án này vào IPA.

| Nguồn | Điều quan sát và cách sử dụng |
|---|---|
| [DYYY cho 39.9.0](https://github.com/sleep1234/DYYY-for-Douyin-39-9-0/blob/main/DYYY.xm) | Nhánh lọc dùng `AWEAwemeModel.isAds`; hook `AWESplashManager.tryToShowSplash`. Đã đối chiếu lớp, selector và kiểu với mẫu 40.6.0; không giả định bản 39.9.0 tương thích nguyên trạng. |
| [DYAll](https://github.com/xingyou9/DYAll/blob/main/DYYY.xm) | Có nhánh nội dung dùng `isAds`, đồng thời có nhánh whitelist giữ quảng cáo. Không chọn cả dự án vì nhiều tính năng ngoài yêu cầu và không phải mọi nhánh đều loại quảng cáo. |
| [DouYinTweak](https://github.com/tuxi/DouYinTweak/blob/master/DouYinDylib/Logos/DouYinDylib.xm) | Ví dụ kỹ thuật hook Objective-C ở bản cũ. Không thấy giấy phép repository qua metadata API; không sao chép mã. Không dùng anti-debug/Cycript/debug server của dự án. |
| [insert_dylib](https://github.com/Tyilo/insert_dylib/blob/master/README.md) | Cơ chế thêm `LC_LOAD_DYLIB` và yêu cầu ký lại. Viết bộ đóng gói riêng có kiểm tra padding/bounds; không chạy công cụ bên ngoài. |
| [objc4 của Apple](https://github.com/apple-oss-distributions/objc4/blob/main/runtime/objc-runtime-new.mm) | Đối chiếu API runtime thêm/thay implementation. Tạo override cục bộ khi method kế thừa để không sửa superclass. |
| [MonkeyDev](https://github.com/AloneMonkey/MonkeyDev) | Quy trình app + dylib trong toolchain Xcode; không thêm toàn bộ dependency hoặc SDK sao chép từ nguồn không xác minh. |
| [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) | Chọn macOS standard runner, SDK có sẵn trong Xcode; không cần Mac cá nhân. |

DYYY và DYAll được GitHub API khai báo MIT tại thời điểm đọc. Mã implementation trong repository này được viết riêng; không lấy framework đóng sẵn hoặc các khối code của dự án tham khảo. Workflow pin checkout và upload-artifact tới commit SHA cụ thể.

Bằng chứng quyết định cuối cùng là metadata của mẫu đã kiểm tra, không phải tên hàm trong tài liệu internet. `resources/hooks.json` chứa đúng 30 mục đã đối chiếu với metadata, gồm type encoding và địa chỉ tĩnh. Địa chỉ dùng làm bằng chứng; runtime lookup theo tên nên không phụ thuộc ASLR. Có method không đồng nghĩa đã chứng minh toàn bộ call path thực tế; hook counts và hành vi trên thiết bị phải được kiểm tra tiếp.
