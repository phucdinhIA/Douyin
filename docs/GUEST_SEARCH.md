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

## Bổ sung: tìm được một trong bốn lần trên 0.2.0

Người dùng xác nhận đã thử bốn lần tìm kiếm trên **0.2.0**, một lần có kết quả, ba lần không ra kết quả. Chưa có diagnostics hoặc thông báo cụ thể của ba lần thất bại. 0.2.0 chưa có gateway/adapter Guest search và observer search-status của 0.4.0. Không dùng kết quả đó để kết luận 0.4.0 thất bại hoặc máy chủ chỉ cho một lượt tìm kiếm.

Đã mở rộng sáu truy vấn GitHub issues; các kết quả DYYY liên quan ẩn control hoặc refactor, chưa có bằng chứng sửa tìm kiếm khách cho iOS 40.6.0. Truy vấn ban đầu `douyin "2483"` trả cả issue số 2483 không liên quan; đã thu hẹp `in:title,body`, không dùng kết quả nhiễu làm bằng chứng. [Truy vấn và kết quả](evidence/search-followup-0.4.0.json).

Hai hướng có thông tin cụ thể:

- [bb-sites PR 41](https://github.com/epiral/bb-sites/pull/41), chưa merge tại thời điểm đọc: đã đọc toàn bộ `douyin/search.js` tại commit `f290f4ec1e83eabaf967f814abe3a42c8f2e996a`, SHA-256 `03ba9f6b75bfc7963cd45ec1441b8402cf6fb903431b469347b9bb77ee4c8cc0`. Nó thao tác trang web và đọc DOM của kết quả công khai, hỗ trợ general/video; chính mã ghi user search có thể rỗng và báo lỗi nếu không có kết quả công khai. Không phải patch native hoặc bằng chứng tìm kiếm vô hạn; không thực thi hay đưa mã này vào IPA.
- [VideoGet PR 4](https://github.com/Loccao102/VideoGet/pull/4) mô tả ghi nhận response web và báo rõ cần cookie đăng nhập khi gặp 2483. [Báo cáo cũ python-spider issue 35](https://github.com/Jack-Cherish/python-spider/issues/35) có response 2483 kèm thông báo yêu cầu đăng nhập. Đây là báo cáo bên ngoài ở web/phiên bản khác, chưa xác nhận response của iPhone hiện tại. Đối chiếu với disassembly chỉ làm giả thuyết giới hạn guest đáng kiểm tra hơn, không chứng minh có cách vượt giới hạn.

Chưa có giải pháp được kiểm chứng để buộc máy chủ cấp tìm kiếm không giới hạn cho mẫu hiện tại. Bước phân biệt là thử IPA 0.4.0 đã giao với Guest search ON, xem số adapter active và numeric search status sau một lần thất bại. Nếu adapter chưa cài, xem đường client; nếu có status 2483, phân biệt yêu cầu server với lỗi kết nối. Đổi một lỗi thành success hoặc bỏ popup không tạo ra kết quả thiếu. Chưa sửa thêm mã production hoặc tạo IPA mới theo phỏng đoán.
