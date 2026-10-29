# Supabase tự triển khai — chuẩn bị vận hành

Người dùng đã chốt dùng server riêng cho production. Backend development đã được dựng local trên Docker, xem [supabase/README.md](../../supabase/README.md). Chưa triển khai VPS production.

## Cấu hình khởi đầu đề xuất

Người dùng chưa có server, cần chọn cấu hình trước khi triển khai mạng:

| Hạng mục | Đề xuất cho MVP |
| --- | --- |
| Hệ điều hành | Ubuntu Server 24.04 LTS, x86_64 |
| CPU | 4 vCPU |
| RAM | 8 GB |
| Lưu trữ | SSD/NVMe 80–100 GB, theo dõi dung lượng và retention log |
| Khu vực | Singapore nếu phần lớn người dùng ở Việt Nam; xác minh độ trễ thực tế |
| HTTPS | Domain riêng cho API, reverse proxy TLS |
| Backup | Backup database hằng ngày ra nơi khác server; kiểm tra phục hồi |

Đây là mức khởi đầu, không phải cam kết số người dùng tối đa. Cần đo tải, dung lượng và khả năng phục hồi trước production. Một VPS vẫn là điểm lỗi đơn; backup ngoài máy không thay thế HA.

[Tài liệu Supabase Docker](https://supabase.com/docs/guides/self-hosting/docker) được kiểm tra ngày 28/10/2026: tối thiểu 2 cores / 4 GB RAM / 40 GB SSD, khuyến nghị 4 cores+ / 8 GB+ / 80 GB+ SSD. Lựa chọn khu vực và hệ điều hành ở trên là đề xuất cho dự án. Chưa chọn nhà cung cấp hoặc mua dịch vụ; giá cần kiểm tra khi chọn nhà cung cấp.

## Cách chuẩn bị

1. Chọn server Linux và dung lượng/backup theo ngân sách, xác định domain API.
2. Dùng Docker Compose chính thức của Supabase theo [hướng dẫn self-host](https://supabase.com/docs/guides/self-hosting/docker). Pin phiên bản/revision đã kiểm tra thay vì tự động nâng cấp production.
3. Tạo khóa, mật khẩu database và secrets trên server; không đưa vào Git hoặc gửi plaintext trong chat.
4. Cấu hình HTTPS, API gateway, Auth callback và mạng nội bộ giữa dịch vụ. Không mở database/admin dashboard công khai không kiểm soát.
5. Tách môi trường staging và production. Chuẩn bị backup database và storage, kiểm tra phục hồi.
6. Cấu hình Google OAuth, Apple và Facebook trên tài khoản nhà cung cấp; khai báo callback, bundle ID/application ID phù hợp.
7. Chạy migration và kiểm thử RLS/đồng bộ trên staging trước khi nối dữ liệu thật.

Không tạo bộ compose độc lập chắp vá ở giai đoạn này; dùng cấu hình chính thức, giữ bản pin trong repository khi chọn được server và phiên bản triển khai.

## Thông tin cần khi nối backend

- Server, hệ điều hành, cách truy cập đã được người dùng cho phép và domain.
- Supabase API URL và public/publishable key; khóa quản trị chỉ đặt trong môi trường server.
- Tên ứng dụng, bundle ID/application ID chính thức; ID hiện tại `com.littleisland.little_island` là tạm.
- Cấu hình ba nhà cung cấp và quyền tài khoản Apple/Google/Meta.
- Chính sách lưu giữ/xóa dữ liệu và hợp nhất tài khoản.

## Phạm vi app hiện tại

App dùng SQLite và outbox dưới chủ thể `local-device` cho giai đoạn đầu. Chưa tự động gán dữ liệu local cho một tài khoản mạng. Giai đoạn auth phải có thao tác nhận dữ liệu thiết bị rõ ràng, đồng bộ idempotent và cách ly/đóng outbox khi đổi tài khoản. Không đưa local owner ID lên server như danh tính người dùng.

Đã có migration và RPC intake được xác minh trên local; chưa xác minh triển khai production hoặc đồng bộ app đầy đủ. Không áp dụng chính sách chỉ dựa vào email; dùng danh tính từ Supabase Auth.
