# Trạng thái 0.11.0-test

**Đã tạo IPA cá nhân có Gemini. Chưa nghiệm thu trên iPhone.**

`dist/Douyin-40.6.0-Guest-0.11.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`, 704,880,275 byte. SHA-256 `321c5493233df47c0aa099bb0a58a2e2986736f704312ebfdeeb2a1ca2fb185d`. Source `8c175153fd6dbc3a3bea74e202a5b04130eff016`.

| Hạng mục | Kết quả |
|---|---|
| Gemini | Quality 3.8 Flash / Fast 3.5 Flash-Lite; key cá nhân chỉ nhúng trong IPA cục bộ |
| Phân tích gốc | Chỉ đọc markdown làm ngữ cảnh, không thay dữ liệu/phân tích của Douyin |
| Luồng hỏi đáp | Nút riêng và override submit chỉ trên comment-AI; bản nháp rồi Send; chưa nghiệm thu máy thật |
| Context | Đọc renderer đã kiểm ABI, giới hạn 24.000 đơn vị UTF-16; có thể xem/sửa/dán khi thiếu |
| Network | HTTPS Google, API header, không cookie/cache tài khoản, timeout/cancel, không retry tự động |
| CI | [Run 36983694958](https://github.com/phucdinhIA/Douyin/actions/runs/36983694958): 20 Python, Foundation, 29 Gemini và 122/122 UIKit đạt |
| Archive | 5,630 mục readback/hash; 0 mismatch; AwemeCore/code executable giữ nguyên |
| Còn mở | Featured/Tips/phát nền/xoay/search/bình luận guest, renderer hybrid và routing/capture thật |

[Hướng dẫn](../DEVICE_TESTS.md) · [Nghiên cứu](../RESEARCH-0.11.md) · [Validation](validation-0.11.0.json) · [UI Gemini](ui-gemini-0.11.0.png) · [Context](ui-gemini-context-0.11.0.png) · [Lịch sử](status-0.10.0.md).

IPA có key thật, cần giữ riêng. Diagnostics chỉ có model/trạng thái/counters, không chứa key hay nội dung chat. Installed không chứng minh đã chạy trên máy thật.
