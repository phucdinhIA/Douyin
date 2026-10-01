# Trạng thái kiểm chứng

Candidate: **0.1.0-test**. Chưa phát hành bản hoàn chỉnh.

| Hạng mục | Trạng thái |
|---|---|
| Hash/identity mẫu gốc | Đã đối chiếu với audit trước |
| Metadata của 30 hook | Đã đối chiếu selector, kiểu và method kind |
| Từ điển | 278 label, chưa kiểm chứng bao phủ toàn giao diện |
| Python tests | 13 tests đạt trên Windows và macOS |
| Foundation policy/hook tests | Đạt trên runner macOS arm64; bao gồm forwarding object/BOOL, metaclass, override kế thừa, direct-ivar response, bật/tắt và sai chữ ký hàm |
| Build arm64 | Đạt với warnings-as-errors; Xcode 15.4 / SDK iOS 17.5 / deployment target 15.0 |
| Chữ ký ad-hoc thư viện | `codesign --verify --strict` đạt; toàn IPA cần Sideloadly ký lại |
| Đóng gói và hash toàn bộ IPA output | Đạt; đọc lại 5.629 entry, hash toàn bộ khớp manifest |
| So sánh audit độc lập | 4.977 file không sửa khớp SHA-256 của audit trước; 5.620 entry không sửa khớp CRC/size/mode |
| Giữ IPA gốc | SHA-256 trước/sau khớp |
| Cài và mở trên iPhone 15/iOS 18.5 | Chưa kiểm tra |
| Không popup, không ad, layout tiếng Anh | Chưa kiểm chứng runtime |
| Video máy chủ hạn chế | Không mở vượt quyền xác thực |

Build đầu: [36822883058](https://github.com/phucdinhIA/Douyin/actions/runs/36822883058), commit `4d898ce9554ced1b3d78ff721f9be37144fe9f24`.

Build bổ sung các ca ABI: [36823436441](https://github.com/phucdinhIA/Douyin/actions/runs/36823436441), commit `db0a0e87b23d9923854c316b3045a8968df63e6d`. Hai build tạo thư viện có cùng SHA-256; candidate dùng đúng thư viện này.

Candidate cục bộ: `dist/Douyin-40.6.0-Guest-TEST.ipa`, **704.810.782 byte**.

SHA-256 IPA output:

`8f889997482cc93c0725202690c45e68ae4ffc5ed8027413ede95ecdc272d283`

SHA-256 thư viện:

`5d37fde7a87395d09b241528708f5f359026a2a69b310143fcf7f1d632e71936`

[Tóm tắt kiểm chứng máy](VALIDATION.json). Báo cáo chi tiết chứa hash mọi entry nằm cạnh IPA cục bộ dưới đuôi `.validation.json`. Không suy ra thành công chức năng từ việc biên dịch thành công. Bước còn thiếu để chốt là kiểm tra D01–D14 trên iPhone thật và sửa các lỗi tìm được.
