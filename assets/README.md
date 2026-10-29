# Little Island — Asset pack v0.1

Bộ asset đầu tiên theo mockup Đảo nhỏ, khung thiết kế tham chiếu 390 × 844. Bộ này phục vụ đánh giá mỹ thuật và tích hợp bản đầu; chưa phải bộ hoạt ảnh production hoàn chỉnh.

## Danh mục

- `backgrounds/sky-sea.png`: nền trời/biển không trong suốt.
- `island/island-base.png`: nền đảo và hồ nước có alpha, không chứa thú hoặc nhà/cây để có thể ghép lớp.
- `pets/mochi-states.png`: atlas 3 cột × 2 hàng, thứ tự chờ, ngủ, vui / ăn, chơi, nhảy.
- `decorations/island-props.png`: atlas 3 cột × 2 hàng, thứ tự cây, nhà, bát ăn / hoa, mầm cây, đá và cỏ.
- `icons/*.svg`: 6 icon tự vẽ, nét 1.8, viewBox 28 × 28, màu `currentColor`.
- `design-tokens.json`: bảng màu và kích thước tham chiếu.
- `manifest.json`: thông số ảnh, ô atlas và thứ tự ghép lớp.
- `prompts.md`: mô tả tạo ảnh và nguồn gốc.
- `preview.html`: mở trong trình duyệt để xem ghép cảnh, atlas và icon. Không yêu cầu thư viện hoặc kết nối backend.

## Dùng atlas

Mỗi atlas có 3 cột và 2 hàng. Với ảnh W × H, ô (cột c, hàng r) có hình chữ nhật nguồn `(c*W/3, r*H/2, W/3, H/2)`. Giá trị cụ thể lấy từ manifest; nếu kích thước không chia hết, dùng ranh giới ô trong manifest.

Trong Flutter có thể vẽ hình chữ nhật nguồn qua `Canvas.drawImageRect`. Chưa thêm package hoặc mã tích hợp Flutter trong phạm vi tạo asset.

Giữ toàn bộ padding của ô để chuyển trạng thái không đổi kích thước khung hiển thị. Ảnh tạo sinh có thể lệch nhẹ căn chỉnh giữa tư thế; cần kiểm tra/chỉnh trước khi dùng cho hoạt ảnh liên tục. Sáu tư thế không phải sáu frame chuyển động nối tiếp; không phát tuần tự như một animation.

## Thứ tự ghép cảnh

1. Nền trời và biển.
2. Đảo và hồ nước.
3. Cây, nhà và đồ vật phía sau thú.
4. Thú nuôi.
5. Bát ăn, hoa và hiệu ứng tương tác phía trước.
6. UI: lời thoại, tiến độ và nút bấm (không nằm trong PNG).

Các vật trang trí nằm chung atlas nhưng có thể vẽ riêng từng ô. Không chỉnh sửa alpha của ảnh đầu ra. Lựa chọn palette là định hướng; màu pixel minh họa có thể không khớp tuyệt đối token UI.

## Icon và khả năng tiếp cận

Ba nút chính dùng `island.svg`, `journey.svg`, `profile.svg`; không hiển thị chữ. Vẫn gắn nhãn đọc màn hình. Hiển thị icon 26–28 đơn vị logic, vùng chạm tối thiểu 48 × 48. Trạng thái active dùng nền xanh nhạt và màu chính; không chỉ dựa vào thay đổi màu.

## Nguồn gốc và giới hạn

Icon được viết riêng cho dự án; minh họa tạo bằng công cụ imagegen tích hợp, không lấy từ kho asset bên thứ ba. Không gán tuyên bố CC0 hoặc đảm bảo quyền độc quyền cho ảnh tạo sinh. Điều kiện công cụ, kiểm tra thương hiệu và các tài nguyên được bổ sung sau cần được xem xét trước khi phát hành thương mại.

Chưa bao gồm chó, cá, các giai đoạn trưởng thành hoặc chuỗi frame chuyển động hoàn chỉnh. Các mục đó làm sau khi duyệt phong cách bộ Mochi đầu tiên. Không thay đổi mã app hoặc mockup hiện có trong lần tạo asset này.
# Bổ sung giai đoạn 3

`branding/app-icon.svg` là vector gốc giọt nước/đảo nhỏ, xuất PNG Android/iOS/web bằng `scripts/generate-branding.cjs` (sharp). Chó Biscuit và cá Bubbles được vẽ trực tiếp bằng Flutter CustomPainter tại `apps/mobile/lib/features/pets/presentation/pet_avatar.dart`, không cần atlas tải ngoài. Mèo vẫn dùng atlas Mochi hiện có. Chuyển động phản hồi và ba giai đoạn tăng trưởng được điều khiển trong app; atlas mèo gốc vẫn là ảnh trạng thái tĩnh.
