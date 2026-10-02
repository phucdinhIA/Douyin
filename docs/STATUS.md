# Trạng thái 0.6.0-test

**Đã tạo candidate LIVE/phát nền cục bộ và kiểm tra build/fixture/IPA. Chưa nghiệm thu trên iPhone thật, chưa hoàn thành tính năng guest phía máy chủ.** Search, toàn bộ bình luận, Featured/Tips và độ trễ ảnh vẫn chưa được khắc phục/chứng nhận. Hai tab vẫn giữ.

File `dist/Douyin-40.6.0-Guest-0.6.0-iPhone15-TEST.ipa` — 704,842,179 byte. SHA-256 `30c5efc6db43d33bf48cf3251c6ed53ad897b8f1c401ca4b7afa06119be62d68`. Dylib `f6ac1f3df2c910f50061eaf6e05f15d32d5295772feab10b909688dac98bf575`, source `d6dab646f39c607ead57abf94bab18e03b4affeb`. Commit tài liệu sau đó không đổi binary.

| Kiểm tra | Kết quả thực tế |
|---|---|
| macOS CI | [Vòng 36954417420](https://github.com/phucdinhIA/Douyin/actions/runs/36954417420): 14 Python tests, Foundation, arm64 warnings-as-errors và signature đạt |
| UIKit fixture | 94/94 checks; iPhone 15 Simulator/iOS 18.2; 893 nhãn ở 120pt, LIVE 63/32pt và khôi phục khi nới rộng; bảo vệ room/chat/comment |
| IPA độc lập | 5,629 entry đọc lại/hash, 5,620 entry CRC/size/mode nguyên vẹn, 4,977 SHA so audit, 0 mismatch |
| Binary gốc | AwemeCore nguyên vẹn; executable chỉ đổi 51 byte header, giữ size/code |
| Preference âm thanh | 3 getter cục bộ, OFF trả giá trị gốc, không sửa listenVideoStatus/quyền/account/session; giữ background modes |
| iPhone 15/iOS 18.5 | **0.6.0 chưa được cài/chạy; chưa xác nhận audio khóa màn hình, interruption hoặc UI Douyin thật** |

Đã review bảy ảnh **fixture**, không phải app Douyin thật: [LIVE](evidence/ui-live-0.6.0.png), [comments](evidence/ui-comments-0.6.0.png), [Featured hẹp](evidence/ui-featured-narrow-0.6.0.png), [sidebar](evidence/ui-sidebar-0.6.0.png), [error](evidence/ui-network-error-0.6.0.png), [Search](evidence/ui-search-0.6.0.png), [Settings](evidence/ui-settings-0.6.0.png). Chữ Trung ở sample room/chat/comment/result là nội dung được giữ.

Vòng 36953743503 bị trùng biến trong Foundation test; vòng 36953877340 bị trùng biến trong UIKit visual fixture. Đã sửa và chạy lại; không dùng artifacts thất bại để đóng gói. Các vòng fixture không đạt bổ sung, nếu có, được ghi trong [kế hoạch/kiểm tra](ROUND_0.6.md).

[Kế hoạch và nghiên cứu](ROUND_0.6.md), [13 ABI mới](evidence/0.6-native-hook-abi.json), [nguồn HTTPS đã đọc](evidence/0.6-research.json), [validation máy đọc được](VALIDATION.json), [nghiệm thu thiết bị](DEVICE_TESTS.md). Lịch sử [0.5](evidence/status-0.5.0.md) giữ nguyên.
