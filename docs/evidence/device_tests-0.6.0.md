# Kiểm tra 0.6.0 trên iPhone 15 / iOS 18.5

0.5.0 đã chạy trên thiết bị theo diagnostics người dùng; 0.6.0 chưa chạy. Ký/cài `Douyin-40.6.0-Guest-0.6.0-iPhone15-TEST.ipa` bằng Sideloadly, giữ dữ liệu và IPA cũ. Hai ngón tay chạm ba lần mở Douyin Guest. `Background audio` mặc định ON; thay đổi rồi đóng hẳn/mở lại. Copy diagnostics phải báo 0.6.0-test, expected63; ghi active/installed/mismatch/overwritten.

## Nghiệm thu âm thanh nền

| Ca | Thao tác và tiêu chí |
|---|---|
| Khóa màn hình | Video công khai đang phát có tiếng, khóa 30 giây rồi 2 phút; tiếng còn phát, mở khóa không mất hình/vị trí; ghi độ dài video và thời gian ngừng nếu có |
| Pause | Pause video rồi khóa; không tự phát lại |
| Đổi app | Đang phát → Home/app khác → quay lại; không hai luồng âm thanh hoặc màn đen |
| Cuộc gọi | Khi khóa có audio, nhận cuộc gọi; app phải nhường âm thanh, không tự phát đè cuộc gọi |
| Tai nghe | Rút tai nghe/disconnect Bluetooth; giữ xử lý route của app, ghi có dừng hay phát qua loa; không giả định native xử lý đã đạt |
| Remote controls | Nếu native hiện lockscreen media controls, thử Pause/Play; không tạo remote controls giả nếu app không cấp |
| OFF | Background audio OFF → đóng/mở, đối chiếu cùng video; OFF trả preference gốc, nếu người dùng đã bật native background trước đó thì OFF không ép native thành tắt |
| Tương thích | Video ngắn/dài/ngang/ảnh, LIVE; chuyển foreground/background 5 lần, không crash/tự phát khi đã pause |

Chạy từng ca rồi Copy diagnostics; quan sát `switchState/audioSwitchState/audioSceneState preference ON`, native `shouldEnterBackgroundPlayMode original YES/NO`, entry/exit calls, `backgroundIsPlaying original YES/NO`. Cài hook không chứng minh hook được gọi hay audio nghe được. Không retry playback loop để ép vượt quyết định native.

## LIVE và các chức năng còn lỗi

- Năm control 明星/聊天/唱歌/团播/颜值: Stars/Chat/Singing/Groups/Beauty; ô rất hẹp có Sing/Team/Looks. Kiểm đủ chữ, vùng bấm, xoay màn, cỡ chữ lớn; tên phòng/chat của người dùng không bị dịch. Mở menu LIVE, Quality và background settings nếu có; ghi nguyên chữ control còn sót.
- Featured và Tips: từng tab trong **phiên riêng**, Retry một lần rồi Copy diagnostics. Tách DCFeed/DataNetwork/TTNetwork/URL/App và numeric code/underlying, không equate generic feed success với hai tab. Hai tab vẫn giữ.
- Search: nhập từ khóa công khai hai lần, Copy diagnostics ngay khi 2483/login/blank/error; không fake thành công. `search_adapter_hooks installed/active0` theo thiết kế.
- Comments: mở và cuộn đến khi dừng/login; status0 getter samples không chứng minh toàn bộ comment đã được cấp. Ảnh trắng: ghi thời gian, diagnostics lúc trắng và sau 15–30 giây/chạm; image counters là toàn app và có retry. Chạm và nhấn giữ là luồng khác nhau.
- Kiểm feed/Nearby/LIVE 30 phút, 5 cold start, mất mạng/khôi phục và Retry, ad/login/English OFF so sánh sau restart. Giữ yêu cầu tài khoản cho Like/Follow/post; không ghi thành công giả.

**Chưa nghiệm thu hoàn chỉnh** nếu bất kỳ tính năng yêu cầu còn lỗi, guest bị máy chủ giới hạn, audio nền không hoạt động hoặc UI dịch nhầm/cắt chữ. Không gửi cookie/token; chỉ cần hành vi và diagnostics từng phiên.
