# Trạng thái 0.17.0-test

0.16: người dùng xác nhận phát nền tốt; GTX bị 429 và lồng tiếng gặp 504. 0.17 thêm Gemini dự phòng đã được chấp thuận, dịch toàn bộ transcript ngắn và phát Vbee từng nhóm theo kỹ thuật extension. Một nhóm lỗi giữ phụ đề/âm thanh gốc và không hủy các nhóm sau.

IPA: `dist/Douyin-40.6.0-0.17.0-PROGRESSIVE-VBEE-PRIVATE-TEST.ipa`; 704,997,922 byte. SHA-256 `e274a660a580bfbc51f988935ef8477c335818baba21ab9c62d3207134602743`. Library `83ac4f52139bbe569ee5fa68f12011ec8c3e0b12757b87685322742abb38fc24`. Source `029a68903c69b870890908dd6a8dcead22fc1d5a`.

| Kiểm tra | Kết quả |
|---|---|
| Python đóng gói | 21 đạt |
| Gemini / dịch AI | 29 / 36 đạt |
| Media / audio timeline và progressive | 62 / 18 đạt |
| UIKit iPhone 15 Simulator | 206 đạt, không overflow |
| API thật | GTX batch 200, markers đúng; Gemini full-context 200 và comment fallback 200; 3 Vbee 200 |
| Đối chiếu IPA | 5,632 mục, 0 mismatch; core gốc giữ nguyên |
| Douyin 0.17 thật trên iPhone | Chưa nghiệm thu |

Fixture kiểm tra nhóm đầu phát trước các nhóm sau, đệm khi thiếu audio, tua/loop, biên nhóm đã preload, lỗi 504 cô lập, đổi video, cache, hủy, GTX 429/cooldown/Gemini dự phòng. Timing API thật không bao gồm Apify/ASR/xuất audio/player. Phát nền đã được người dùng xác nhận ở 0.16; đồng bộ lồng tiếng khi khóa máy vẫn cần kiểm tra thiết bị.

[Kế hoạch](PLAN-0.17.md) · [Validation](VALIDATION.json) · [Hướng dẫn nghiệm thu](DEVICE_TESTS.md) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37093712664).
