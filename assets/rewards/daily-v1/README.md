# Phần thưởng trong ngày — asset v1

Bộ gốc đồng bộ phong cách thú đã chốt. Sau phê duyệt apply code, bản sao cắt khoảng trống alpha được tích hợp tại `apps/mobile/assets/rewards/daily-v1/`; ảnh nguồn ở đây giữ nguyên. Chi tiết kiểm tra: `document/qa/daily-rewards-web.md`.

| Thú | Vật phẩm đeo | Lớp hiệu ứng |
|---|---|---|
| Nemo | nemo-crown.png — vương miện vỏ sò | nemo-bubbles-fx.png — bong bóng lấp lánh |
| Corgi | corgi-scarf.png — khăn quàng xanh | corgi-confetti-fx.png — giấy màu |
| Mèo Cam | meo-cam-badge.png — huy hiệu cá vàng | meo-cam-stars-fx.png — ánh sao |

PNG có kênh alpha. Vật phẩm và hiệu ứng là các file tách biệt, không có nhân vật hoặc cảnh nền vẽ sẵn. Chỉ giữ các vật phẩm trong ngày khi tích hợp sau; không giữ lớp hiệu ứng sáng liên tục.

## Hướng dẫn dùng sau khi duyệt

- Crown căn theo đỉnh đầu Nemo, scarf theo cổ Corgi, badge theo ngực Mèo Cam. Cần hiệu chỉnh vị trí/xoay theo từng tư thế; đây không phải accessory đã rig tự bám nhân vật.
- Lớp hiệu ứng có khoảng trống giữa để nhân vật dễ nhìn. Có thể phát một lần bằng dịch chuyển, scale và fade khi đạt mục tiêu; ảnh PNG tự nó chưa là animation.
- Corgi đã có khăn trong một số tư thế GOAL của atlas hiện tại. Khi tích hợp phải tránh ghép hai khăn lên cùng tư thế.
- Trạng thái vật phẩm nay suy ra từ tổng nước và mục tiêu của ngày hiện tại: tự gỡ khi sang ngày mới hoặc hoàn tác xuống dưới mục tiêu; tự khôi phục từ lịch sử đã lưu. Không có bản ghi XP/phần thưởng cộng dồn mới.

Tạo bằng công cụ ảnh tích hợp (built-in), không dùng CLI/API fallback. Tham chiếu phong cách: `assets/pets/storyboard-v1/*-keyposes.png`, trong đó Mèo Cam theo v1. Prompt cuối cùng: [prompts.md](prompts.md). Asset gốc và code ứng dụng được giữ nguyên.
