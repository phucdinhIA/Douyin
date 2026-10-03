# Trạng thái 0.18.3-test

IPA riêng `Douyin-40.6.0-0.18.3-CLAUDE-LAYOUT-PRIVATE-TEST.ipa` đã đóng gói và đối chiếu từng entry. Source `9319247874838aed46a3d3456ae2cfd5a0e3ad3e`; IPA SHA-256 `169c499e75ff22e8f5a8ee8ae6f561ea7794c599b8f6ab6cd3892dc92c7e0d19`; library SHA-256 `03bce2251153a5f168e5af4cfdf4046750843411130606a7822fdd7a4e874e39`; 705,015,800 byte.

| Kiểm tra | Kết quả |
|---|---|
| Python | 21 đạt |
| Gemini / dịch AI | 29 / 40 đạt |
| Media/source/ASR/cache | 257 đạt |
| UIKit iPhone 15 / iOS 18.2 | 229 đạt; không overflow trong fixture |
| API Claude thật | 4 mẫu tổng hợp; prose mở rộng và nhóm phụ đề có context |
| IPA độc lập | 5,632 entry; 0 mismatch |
| iPhone thật iOS 18.5 | Chưa nghiệm thu bản mới |

Lỗi prose tái hiện được là giới hạn 500 ký tự đầu ra dùng chung với phụ đề, không phải thiếu mốc: mẫu 400 ký tự Trung trả đủ 1 đoạn Việt 1.401 ký tự. Bản mới nhận prose tối đa 4.096 ký tự/đoạn, 96.000 tổng; caption tối đa 2.000 ký tự/cue và phân trang. Engine flag `useAiTranslate` là metadata. ID/timing gốc không bị đổi, trả thiếu/trùng/ID lạ/blank/chữ Trung vẫn bị chặn với lý do riêng.

Nhóm đầu 8 cue / 1.600 ký tự, nhóm sau 12 / 2.400. Transcript dưới 600 giây và 12.000 ký tự gửi toàn context trên hai cue ranh giới, giữ ngữ cảnh xuyên nhóm. Cache các nhóm đã đủ ngay; không retry quota/timeout tự động. Diagnostics tách response count/length/latency/accepted khỏi kiểm tra ASR duration. Bốn probe thật đo 5,11 giây prose; 19,30 giây 24 cue; 6,53 giây 8 cue context lân cận; 6,72 giây 8 cue context cả 24. Không dùng số đo này làm SLA.

Reader AI ẩn panel bình luận trong cùng cửa sổ. Controls nằm dưới khu đọc; Bản gốc ẩn status/retry, có chỗ cuộn cuối nội dung và khôi phục inset khi rời. Reader top bám renderer thay cho +64 cố định trên controller nhúng. Phụ đề có lề 16 điểm đối xứng, đáy trên navigation 64 điểm dọc; preference V2 đặt lại vị trí mặc định cho bản nâng cấp. Audio gốc/phát nền/TTS tắt không đổi.

[Cách sửa](PLAN-0.18.3.md) · [API thật](evidence/0.18.3-service-probes.json) · [Validation](VALIDATION.json) · [Nghiệm thu](DEVICE_TESTS.md) · [Phụ đề](evidence/ui-captions-long-0.18.3.png) · [AI nhúng](evidence/ui-ai-embedded-0.18.3.png) · [Error pane](evidence/ui-ai-translation-error-0.18.3.png) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37114315629).
