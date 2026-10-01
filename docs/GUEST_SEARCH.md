# Tìm kiếm khách — 0.4.0-test

Người dùng báo Douyin 40.6.0 / 406019 yêu cầu đăng nhập **sau khi nhập từ khóa**. Bản 0.3.0 chưa được người dùng cài/thử; 0.4.0 gộp các thay đổi trước đó và phần tìm kiếm để chỉ cần cài một candidate mới.

## Bằng chứng và cách xử lý

Disassembly của `AWESearchResultHybridViewController handleSearchKeywordDidChangedNotification:` trong đúng IPA có kiểm tra `enableGuestSearch` và `hasRemainingGuestSearchCount` trên service adapter; nhánh không đủ điều kiện đi tới `requireLoginWithContext:completion:`. `AWESearchHomeNewStyleDetailBottomBarController` cũng kiểm tra lượt tìm kiếm khách trước khi mở kết quả. Đây là bằng chứng về cổng kiểm tra phía client, chưa chứng minh máy chủ sẽ cấp kết quả cho bản ký lại.

Adapter được lấy qua `aAWESearchModuleServiceDOUYINSSAdaperClass`, return type `#16@0:8`. Có nhiều implementation cùng selector trên một số lớp; tất cả địa chỉ đã thấy trong lớp được lưu ở [bằng chứng metadata](evidence/search-methods-0.4.0.json). Không patch địa chỉ code trực tiếp.

0.4.0 chuyển tiếp nguyên class getter của năm gateway: `AWESearchResultHybridViewController`, `AWESearchHomeNewStyleDetailBottomBarController`, `AWESearchModuleService`, `AWESearchBaseUtility`, `AWECustomSearchBar`. Khi **Guest search ON**, lấy class thật mà app trả về, kích hoạt cơ chế lazy method resolution thông thường và kiểm tra **cả hai method thực tế** trước khi cài:

- `+enableGuestSearch` — BOOL không tham số, `B16@0:8`;
- `+hasRemainingGuestSearchCount` — cùng ABI.

Nếu cả hai hợp lệ, wrapper trả YES khi tùy chọn ON để mở đường guest có sẵn. OFF gọi implementation gốc; gateway luôn trả nguyên class gốc. Nếu một method thiếu, chỉ có forwarding hoặc sai kiểu, **không tạo method giả và không sửa nửa chừng**; diagnostics ghi `Search adapter unavailable or incompatible`. Registry đồng bộ bảo vệ cài lặp, chỉ override cục bộ metaclass khi kế thừa và không chồng hook lên replacement lạ.

Hai method adapter chưa được xác nhận có implementation trực tiếp từ bảng class metadata tĩnh; ABI được kiểm tra khi adapter được resolve trên thiết bị. Kiểm thử fixture xác nhận cơ chế cài, không chứng minh service thật đã được cài hook. Vì vậy phải xem `search_adapter_hooks` sau khi thử Search: `installed` và `active` kỳ vọng 2 cho một adapter được resolve, `adapter_classes` cho biết số adapter. Khi chưa tìm kiếm hoặc chưa resolve, số 0 không tự chứng minh có lỗi.

Tùy chọn này độc lập với **Hide login reminders**. Giữ nguyên `isLogin`, tài khoản/keychain, request headers/signing, TLS, response, kết quả máy chủ, callback login và chức năng yêu cầu tài khoản. Không gọi tìm kiếm trong vòng lặp hoặc tạo retry tự động. Các luồng AI/SuperAgent có điều kiện riêng; không tuyên bố chúng được mở khóa.

## Phân biệt giới hạn máy chủ

`AWESearchFrequencyManager checkHitLimitWithStatusCode:andStatusMsg:` so sánh mã NSNumber **2483** rồi đặt `shouldLoginLimit`. Observer mới gọi hàm gốc với nguyên code/message, giữ nguyên BOOL và state; chỉ ghi mã số cùng số lần kiểm tra. Không ghi từ khóa, status message, URL, cookie/token, nội dung kết quả hoặc tài khoản. Mã 2483 ở đây là app status được đọc từ code, không phải HTTP status và chưa quan sát trên iPhone của người dùng.

Không sửa `shouldLoginLimit`, `hitLimit` hay `needsLogin` của response. Nếu máy chủ trả yêu cầu đăng nhập, thay đổi client không tự tạo được kết quả. Khi adapter đã active mà app vẫn yêu cầu đăng nhập, cần diagnostics/màn hình thực tế để tìm tiếp đúng đường; không báo giả rằng tìm kiếm đã thành công.

## Nghiên cứu công khai

Đã đọc lại DYYY tại commit cố định `6c3dfbd911822b4d0f758f184c196566e8142291` (huami1314) và `39561aef7fff5ac039eb2f6a202dd05beba42d89` (pxx917144686). Các file DYYY.xm và README đã đọc không chứa giải pháp guest-search phù hợp. Tìm GitHub issues theo hai repo và hai selector guest không có kết quả phù hợp; phạm vi này không đại diện toàn GitHub.

[better-douyin](https://github.com/YU-1021/better-douyin/tree/322845e1fd12f11c2ff7c9d832d9bc7e49bffc13) mô tả chuyển tìm kiếm web tới `/root/search/`. DOM/userscript không áp trực tiếp cho UIKit hoặc chứng minh API native cấp kết quả. Implementation hiện tại viết riêng từ call path của IPA, không đưa binary/SDK hay mã tải về vào app. [URL, commit, hash và truy vấn đã đọc](evidence/research-search-0.4.0.json).

## Kiểm tra trên iPhone

Cài candidate 0.4.0, bật **Guest search** và **English controls**, đóng hẳn/mở lại app. Thử hai từ khóa không nhạy cảm; thử tab All/Videos/Users/LIVE, cuộn kết quả, đổi từ khóa và Back. Ghi thời điểm nếu popup còn xuất hiện. Sau đó mở bảng Douyin Guest bằng hai ngón tay chạm ba lần, Copy diagnostics. Mong đợi `patch_version: 0.4.0-test`, 39 fixed hooks và `search_adapter_hooks` riêng. Không cần đăng nhập để làm vòng thử này.

Kiểm tra Search/filters/Settings/sidebar/menu player ở font mặc định và font lớn; các chuỗi caption, tên tác giả và từ khóa vừa nhập phải giữ nguyên. Featured/Tips vẫn giữ, lỗi Network error trước đó chưa được xác định nguyên nhân; diagnostics feed của 0.3.0 tiếp tục có trong 0.4.0.
