# Trạng thái 0.12.0-test

**Đã tạo IPA cá nhân với tự dịch phân tích AI sang tiếng Việt khi vào tab. Chưa nghiệm thu tự dịch trên iPhone.**

`dist/Douyin-40.6.0-Guest-0.12.0-iPhone15-GEMINI-PRIVATE-TEST.ipa`, 704,896,889 byte. SHA-256 `94f9de96087063cfba96cbe0fde61dbf0269edc30db1dd051f668d572122e192`. Source `a7e32ad127cf017f6bb10f72d1094bc0a270f7cf`.

| Hạng mục | Kết quả |
|---|---|
| Kích hoạt | Chỉ sau AI-tab entry; bình luận thường không gọi API dịch |
| Chi phí | Một request tự động/entry; cache digest nguồn tối đa 32 mục/2 MiB; không tự retry |
| Chất lượng | Dịch đầy đủ bằng Flash-Lite; giữ tên/số/cấu trúc; chỉ lưu STOP trong giới hạn |
| UI | Panel cuộn Tiếng Việt, toggle Bản gốc, giữ hỏi đáp/ngữ cảnh gốc |
| Hủy | Rời tab, đóng controller, chuyển nền; callback cũ và nguồn đổi bị từ chối |
| CI | [Run 36991564379](https://github.com/phucdinhIA/Douyin/actions/runs/36991564379): 20 Python, Foundation hooks, 29 Gemini, 33 translation, 136 UIKit đạt |
| Archive | 5,630 mục readback/hash; 0 mismatch; core/code gốc giữ nguyên |
| Máy thật | Hỏi đáp 0.11 có vẻ hoạt động theo người dùng; tự dịch 0.12 chưa xác nhận |

[Kế hoạch](../PLAN-0.12.md) · [Test](../DEVICE_TESTS.md) · [Validation](validation-0.12.0.json) · [UI](ui-gemini-translation-0.12.0.png) · [Lịch sử](status-0.11.0.md).

Stability debounce chưa chứng minh đã hết streaming; capture giới hạn renderer markdown đã kiểm ABI, tối đa 24.000 đơn vị UTF-16. Không đọc video/bình luận chưa tải hay giả phiên Douyin. Các lỗi feed/phát nền/xoay/guest trước đó vẫn cần nghiệm thu riêng. Diagnostics chỉ có trạng thái/model/counters, không nội dung hay key.
