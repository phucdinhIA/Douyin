# Trạng thái kiểm chứng — 0.3.0-test

Đã xử lý mã dịch/fitting theo ảnh iPhone và bổ sung chẩn đoán feed. **Lỗi Network error chưa xác định root cause và chưa được sửa; chưa phát hành bản hoàn chỉnh.**

Candidate: `dist/Douyin-40.6.0-Guest-0.3.0-iPhone15-TEST.ipa`, **704,817,323 byte**.

SHA-256 IPA:

`513d5846f8f4869fe4c87fd16b82df4ee07f3103322efeee3a08c7e10037808a`

SHA-256 thư viện:

`72577d73f696d5da646c78be073dd29411a7bc7da899b23d7f1941930cfab61c`

| Kiểm tra | Kết quả |
|---|---|
| CI [36844285286](https://github.com/phucdinhIA/Douyin/actions/runs/36844285286) | Thành công; commit deec7b0fa9584ab0fde5a88a46e66e6f1b2262da |
| Python | 14/14 packaging regressions đạt; có ca loại device thinning trong app/extension |
| Foundation | Policy/hook regressions đạt; observer chuyển tiếp nguyên result/error/BOOL, không làm lỗi thành success, không ghi URL/token/description |
| Build | arm64 / iOS 15.0, Xcode 15.4 / SDK iOS 17.5, warnings-as-errors và ad-hoc signature verification đạt |
| UIKit | **37/37 checks đạt**, iPhone 15 Simulator / iOS 18.2 |
| Bản dịch | 302 cặp; 241 tìm thấy trong CFString lõi; toàn từ điển đi qua hook trong fixture |
| Bố cục | Menu 94pt, control Settings 32pt, width 120pt với compact variants, đổi font sau attachment, attributed styles, reuse/nil và dark appearance đạt |
| Bảo vệ nội dung | Caption/comment/search/profile và nickname trong sidebar user card được giữ trong các ca fixture |
| Native hooks | 33 selector/types khớp metadata; 11 login, 19 ads, 3 observer feed; **chưa kiểm tra active trên iPhone bản 0.3.0** |
| Ảnh fixture | Đã xem [menu](evidence/ui-sidebar-0.3.0.png) và [màn lỗi](evidence/ui-network-error-0.3.0.png), chữ hiển thị rõ, không cắt trong bố cục fixture |
| ZIP | Hash/read-back 5.629 entry đạt; 5.620 entry không sửa khớp CRC/size/mode; 4.977 file khớp audit SHA-256; không sai lệch |
| Thinning | Quét 287 Info.plist: không còn UISupportedDevices; giữ device family/capability/minimum OS |
| Binary gốc | AwemeCore không đổi; executable chỉ đổi 51 byte vùng header, kích thước/code phía sau giữ nguyên |
| iPhone bản 0.3.0 | **Chưa cài/chạy** |
| Featured / Tips | **Network error chưa được sửa**, giữ nguyên hai mục |
| An toàn toàn IPA internet | Không được chứng minh bởi kiểm thử patch |

## Những gì đã thay đổi

Thêm 24 chuỗi từ ba ảnh và các biến thể tên Creator hub. Nhận diện ngữ cảnh sidebar/error/empty page, nhưng loại các lớp user card/recent user để giữ nickname. Fitting được áp lại khi layout sau khi app thay font/width hoặc reset property; chỉ ghi property khi cần, không đổi frame/constraints. Khi chữ đầy đủ không vừa ở tỷ lệ tối thiểu 65% và bản rút gọn vừa, dùng compact label (Settings → Setup, hướng dẫn kết nối → Check connection). Khi chiều rộng tăng, khôi phục chữ đầy đủ. Cache phân biệt setter plain và attributed để tránh khóa font cũ; nội dung thông thường được khôi phục fitting khi reuse.

Hai lỗi vòng kiểm thử đã được xử lý trước đóng gói: câu hướng dẫn dài cần compact variant cho control hẹp; nhãn plain bị UIKit biểu diễn thành attributed text nên font cũ bị giữ. Các ca tái hiện đều đạt trong vòng cuối. [Kết quả nguyên bản từ artifact](evidence/ui-results-0.3.0.json).

Ảnh ở trên là app fixture riêng dùng UIKit thật với lớp AWE giả, **không phải Douyin chạy trên Simulator hoặc ảnh iPhone thật sau sửa**. Hình menu được dựng để kiểm tra chữ/chiều rộng, không tái dựng mọi constraint của app gốc. Layout thực tế cần kiểm tra lại trên iPhone.

## Bằng chứng iPhone của bản trước

Người dùng đã cài/mở bản 0.2.0 sau sửa thinning, gửi diagnostics 30/30 hook active và ảnh sidebar/error page. LIVE/Nearby phát mượt theo báo cáo; Featured/经验 vẫn Network error khi tắt riêng ads và khi tắt cả ads/login. Các nhóm tùy chọn này ít có khả năng là nguyên nhân; chưa đủ để kết luận lỗi server, bắt buộc login hay lỗi ký lại. [Điều tra và bước chẩn đoán](FEED_NETWORK.md).

0.3.0 chỉ thêm observer callback đã đối chiếu ABI và bộ đếm list, không tự tạo request, sửa TLS, giả login, đổi endpoint hoặc giấu lỗi. Mã lỗi trong diagnostics mới trên iPhone là phần còn thiếu để chọn cách khắc phục.

## Bảng dịch bổ sung

| Chữ gốc | Chữ tiếng Anh |
|---|---|
| 工具服务 | Tools & services |
| 我的客服 | Support |
| 我的预约 | Bookings |
| 直播缓存 | Live cache |
| 创作与经营 | Creator tools |
| 上热门 | Promote |
| 生活娱乐 | Lifestyle |
| 社区共建 | Community |
| 券包 | Coupons |
| 常用功能 | Quick tools |
| 离线缓存 | Offline videos |
| 抖音创作者中心 | Creator hub |
| 抖音创作者服务中心 | Creator hub |
| 抖音创作者 | Creator hub |
| 抖音创作者… | Creator hub |
| 抖音创作者... | Creator hub |
| 直播广场 | Live hub |
| 使用管理助手 | Screen time |
| 定时关闭 | Sleep timer |
| 我的二维码 | My QR code |
| 未成年人保护 | Teen safety |
| 经验 | Tips |
| 请检查网络连接后重试 | Check your connection and retry |
| 查看解决方案 | Troubleshoot |

Bản trước và IPA gốc vẫn giữ nguyên. [Tóm tắt kiểm chứng máy](VALIDATION.json); manifest hash chi tiết và đối chiếu audit nằm cạnh IPA cục bộ. Lưu trạng thái trước ở [0.2.0-r1](evidence/status-0.2.0-r1.md).

**Bước còn thiếu:** ký/cài đúng IPA 0.3.0 bằng Sideloadly, kiểm tra lại ba màn hình đã gửi, thử Retry trên Featured/Tips và gửi Copy diagnostics (mong đợi patch_version 0.3.0-test, native_hooks_expected 33).
