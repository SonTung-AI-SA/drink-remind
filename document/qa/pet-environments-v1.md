# Ba môi trường theo storyboard

Phê duyệt 2026-10-29: bỏ cảnh đảo cũ, dùng ba nền riêng theo bộ storyboard đã chốt. Các phần còn lại của app giữ nguyên.

Nguồn tạo hình: `document/storyboards/nemo-storyboard-v1.png`, `corgi-storyboard-v1.png`, `meo-cam-storyboard-v1.png`.

Ảnh nền mới được dựng từ tham chiếu storyboard bằng công cụ tạo ảnh tích hợp, không phải cắt nguyên một ô storyboard. Không có thú vẽ sẵn; thú động vẫn là bộ tư thế đã chốt.

| Thú | Asset nguồn | Runtime copy |
|---|---|---|
| Nemo | assets/backgrounds/nemo-scene-v1.png | apps/mobile/assets/backgrounds/nemo-scene-v1.png |
| Corgi | assets/backgrounds/corgi-scene-v1.png | apps/mobile/assets/backgrounds/corgi-scene-v1.png |
| Mèo Cam | assets/backgrounds/meo-cam-scene-v1.png | apps/mobile/assets/backgrounds/meo-cam-scene-v1.png |

Ảnh 1536×1024, nền đặc. Tất cả prompt cuối cùng: [pet-scenes-v1-prompts.md](../../assets/backgrounds/pet-scenes-v1-prompts.md). Không dùng CLI/API fallback.

`IslandScene` nay chỉ ghép nền theo loại thú, nhân vật động, lời thoại và nhãn tên/cấp độ. Không tham chiếu sky-sea, island-base, island-props, bát/hoa cũ hoặc mặt nước oval bằng code. Asset cũ vẫn giữ trên đĩa để không xóa nguồn ngoài phạm vi yêu cầu.

Nemo ở dưới nước với san hô/hải quỳ; Corgi ở bãi cỏ có nhà mái xanh; Mèo Cam v1 ở bãi cỏ nắng có thùng giấy. Ảnh cover căn giữa để giữ nội dung khi thay đổi kích thước viewport. Nhãn có nền sáng để đọc được trên cả ba môi trường.

Chỉ build lại web trong đợt này, chưa build Android/iOS.

## Xác minh

- 8 test liên quan qua: pet scene, pets, app flow, responsive widget. Test scene kiểm tra đủ ba loại thú, đúng nền, không có tham chiếu asset đảo/trang trí cũ trong cây widget, kể cả complete=true.
- Flutter analyzer không lỗi/cảnh báo; web release build thành công với cấu hình backend local.
- Trình duyệt đã reload bản build cuối: Nemo hiển thị cùng rạn san hô ở 390×844; không sửa hồ sơ hoặc dữ liệu uống nước trong lần kiểm tra này. Viewport tạm đã reset.
- Ảnh minh chứng: [web-pet-environments-v1.png](web-pet-environments-v1.png).
