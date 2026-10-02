> Thiết kế/nghiên cứu hiện tại: [vòng 0.5.0](ROUND_0.5.md). Các phần 0.1–0.4 bên dưới lưu lịch sử; ép guest quota đã bỏ trong 0.5.0, chưa đạt quyền server không giới hạn.

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

Bằng chứng quyết định cuối cùng là metadata của mẫu đã kiểm tra, không phải tên hàm trong tài liệu internet. Ở vòng triển khai đầu, `resources/hooks.json` chứa 30 mục đã đối chiếu với metadata, gồm type encoding và địa chỉ tĩnh. Địa chỉ dùng làm bằng chứng; runtime lookup theo tên nên không phụ thuộc ASLR. Có method không đồng nghĩa đã chứng minh toàn bộ call path thực tế; hook counts và hành vi trên thiết bị phải được kiểm tra tiếp.

## Vòng nghiên cứu bổ sung cho 0.2.0-test

Đọc mã nguồn tại các commit cố định sau; không thực thi mã tải về, không đưa thư viện có sẵn của các dự án này vào app. Tên “no login” trong README chỉ là mô tả của tác giả, không phải bằng chứng rằng Douyin iOS 40.6.0 sẽ cấp mọi video cho khách.

| Dự án / commit đã đọc | Quan sát | Quyết định |
|---|---|---|
| [huami1314/DYYY](https://github.com/huami1314/DYYY/tree/6c3dfbd911822b4d0f758f184c196566e8142291) — MIT | Có kiểm tra `isAds`; nhánh lọc tại model initializer có thể trả `nil`. | Tham khảo nhận diện, không dùng initializer trả `nil`: chưa chứng minh mọi caller của 40.6.0 xử lý được model rỗng. |
| [pxx917144686/DYYY](https://github.com/pxx917144686/DYYY/tree/39561aef7fff5ac039eb2f6a202dd05beba42d89) — không thấy license qua metadata đã lấy | `DYYYUtils.m`, `isAdvertisementAwemeModel:` đọc `checkIsAd`, `isHardAdModel`, `isHardAd`, `isAds`; phân biệt model quảng cáo và container tìm kiếm. | Viết bộ đọc BOOL riêng có kiểm tra ABI. Ba dấu hiệu bổ sung chỉ đọc trên `AWEAwemeModel`; không sao chép implementation, không suy diễn mọi search container là quảng cáo. |
| [sleep1234/DYYY-for-Douyin-39-9-0](https://github.com/sleep1234/DYYY-for-Douyin-39-9-0/tree/59dff1216626d924485d0dbd4008bbeb7d61d213) — MIT | Hook feed/splash trên phiên bản cũ. | Chỉ dùng các selector đã đối chiếu với chính mẫu 40.6.0; không cài toàn bộ tweak. |
| [YU-1021/better-douyin](https://github.com/YU-1021/better-douyin/tree/322845e1fd12f11c2ff7c9d832d9bc7e49bffc13) — có LICENSE MIT | Userscript xóa DOM của login dialog, guide và overlay, chuyển đường dẫn tìm kiếm web. | Hỗ trợ nguyên tắc loại UI nhắc đăng nhập; DOM/JavaScript không thể áp nguyên vào UIKit và không chứng minh có thể vượt yêu cầu của API native. |
| [Feng-zheng666/potplay](https://github.com/Feng-zheng666/potplay/tree/22c2a42ae5e6d2219c82e8857d95615ff43d33dc) — có LICENSE MIT | Đã đọc tài liệu `抖音无登录查看.txt`, phục vụ đường xem web/player. | Không thay native feed bằng giao thức khác chỉ dựa trên hướng dẫn này. |
| [lyf9528/douyin-dl](https://github.com/lyf9528/douyin-dl/tree/037f11cabf39d3e0769209d5b2de948e2fab800f) — không thấy license qua metadata đã lấy | README mô tả tải video không đăng nhập. | Đây là downloader, không phải bằng chứng giải quyết native feed, giới hạn số video hoặc popup iOS. Không đưa dependency vào app. |
| [Theos Logos](https://theos.dev/docs/logos-syntax) | Cú pháp hook và chuyển tiếp implementation gốc. | Dùng Objective-C runtime trực tiếp, kiểm tra type encoding và operation trước khi thay IMP; không cần thêm toolchain Theos. |

Không tìm thấy giải pháp bỏ nhắc đăng nhập native trong các file `.xm`, header và README DYYY đã tải/đọc. Phạm vi đọc không bao gồm mọi file của mọi fork; không kết luận toàn bộ GitHub không có giải pháp đó. Cấu hình 11 hook nhắc đăng nhập hiện tại vẫn dựa trên metadata đúng mẫu và cần xác nhận trên iPhone.

### Đối chiếu bộ nhận diện quảng cáo với mẫu gốc

| Selector trên `AWEAwemeModel` | IMP tĩnh | Type encoding | Độ dài đến function kế tiếp |
|---|---|---|---|
| `checkIsAd` | `0x13407934` | `B16@0:8` | 136 byte |
| `isHardAdModel` | `0xf3b6b18` | `B16@0:8` | 180 byte |
| `isHardAd` | `0x13088d54` | `B16@0:8` | 72 byte |
| `isAds` | `0x130aeb90` | `B16@0:8` | 12 byte |

Disassembly được giới hạn bằng `LC_FUNCTION_STARTS`, tránh đọc tràn sang hàm kế tiếp khi implementation kết thúc bằng tail branch. Các hàm có gọi helper và Objective-C messages; việc đã kiểm tra ranh giới và chữ ký không chứng minh tất cả helper không có side effect hoặc loại hết mọi định dạng quảng cáo. Không patch các địa chỉ này trực tiếp. Runtime tra class/selector và chỉ gọi method có đúng kiểu BOOL, hai argument ẩn; model không phù hợp được giữ lại. Kiểm thử Foundation bao gồm từng cờ, trường hợp không ad, unrelated model, danh sách chỉ có ad và đường gán ivar trực tiếp.

### Sửa độ ổn định và phạm vi kiểm thử

Vòng mới sửa fitting sau UIKit setter, giữ fallback state của UIButton khi thay normal title, bảo vệ tiêu đề profile/creator, thêm đường lấy `delegate.window` và notification key window cho bảng chẩn đoán. Registry lưu IMP để phân biệt hook đã cài với hook còn active; khi implementation khác ghi đè thì ghi chẩn đoán, không tự chồng thêm hook.

App fixture riêng trên Simulator dùng UIKit thật với lớp AWE giả. Nó kiểm tra 278 chuỗi trong ngữ cảnh Settings, fitting, label reuse/nil, button states, attributed styles, caption/comment/search content, tab/profile, dark appearance và bảng chẩn đoán. Fixture không chứa Douyin, không kết nối máy chủ Douyin và không thể chạy executable arm64 thiết bị của IPA trên Simulator. Kết quả và lỗi kiểm thử được ghi trong [STATUS.md](STATUS.md); không suy ra thành công feed/popup/splash từ fixture.

## Vòng tìm kiếm/giao diện 0.4.0

Đã đọc lại nguồn DYYY và better-douyin tại commit cố định và tìm issues theo guest-search selectors. Không tìm được patch native phù hợp trong các file/queries đã đọc; không dùng mô tả web làm bằng chứng iOS. Implementation mới dựa trên class getter/call path của chính mẫu và xác minh ABI adapter lúc chạy. [Chi tiết và nguồn có hash](GUEST_SEARCH.md).

Rà AwemeCore/AWESearchFramework, resource catalogs và metadata YYLabel. 853 exact labels, 752 khóa thấy trong hai binary, 104 file catalog; bằng chứng tĩnh không đại diện mọi màn runtime. SDK English fallback dùng key/table sẵn có, không gửi chữ người dùng tới API dịch. [Rà soát có phạm vi và giới hạn](evidence/localization-audit-0.4.0.json).
