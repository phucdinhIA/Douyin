# Douyin Guest — bản thử cá nhân 0.11.0

Douyin **40.6.0/build406019/arm64**, iPhone 15/iOS18.5. Cần ký bằng Sideloadly.

Gemini hỏi đáp độc lập trong phần AI phân tích bình luận. Giữ nguyên phân tích AI của Douyin. Mặc định **Gemini 3.8 Flash (Quality)**; nút Mode chuyển **3.5 Flash-Lite (Fast)**. Send gửi câu hỏi, ngữ cảnh và tối đa ba lượt đã trả lời sang Google. Không gửi khi gõ; không tự dịch lại phân tích gốc.

Mở AI phân tích bình luận → **Ask Gemini · Your AI** → xem **Context** → nhập câu hỏi → **Send**. Đường gửi native cũng chuyển câu hỏi thành bản nháp Gemini, rồi bấm Send trong sheet. Nếu không thấy nút, menu hai ngón tay chạm ba lần → Gemini Q&A. Khi thiếu ngữ cảnh, Context cho dán/sửa phần phân tích; Gemini không xem video hay bình luận chưa được cung cấp.

**IPA cá nhân có nhúng API key theo yêu cầu: không chia sẻ IPA.** Key chỉ được đưa vào lúc đóng gói cục bộ; GitHub/CI dùng key giả trong test. Bản gốc/candidate cũ vẫn giữ nguyên.

File `dist/Douyin-40.6.0-Guest-0.11.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`; SHA-256 `321c5493233df47c0aa099bb0a58a2e2986736f704312ebfdeeb2a1ca2fb185d`.

Kiểm tra: 20 Python, Foundation hooks, 29 Gemini contracts/mock transport, arm64/signature và 122/122 UIKit fixture. Hai probe dịch độc lập với Google trả HTTP200. Chưa xác nhận routing/đọc ngữ cảnh trong Douyin thật; chưa chứng minh Featured/Tips/phát nền/xoay/search guest đã hết lỗi.

[CI](https://github.com/phucdinhIA/Douyin/actions/runs/36983694958) · [Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.11.md) · [Nghiên cứu](docs/RESEARCH-0.11.md) · [Test iPhone](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json).

```text
python scripts/ipa_patch.py ORIGINAL.ipa VERIFIED_DYLIB.dylib NEW_PERSONAL.ipa --library-sha256 VERIFIED_HASH --gemini-config PATH_TO_LOCAL_PRIVATE_CONFIG.json
```

Không cấp quyền endpoint AI của Douyin bằng phiên giả. Gemini dùng key riêng; lỗi quota/API được hiển thị và giữ câu hỏi để thử lại thủ công. Đóng sheet sẽ hủy yêu cầu; lịch sử chỉ giữ trong bộ nhớ của sheet.
