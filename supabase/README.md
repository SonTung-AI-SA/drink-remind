# Backend local — Little Island

Backend chạy bằng Supabase CLI **2.122.0** và Docker Desktop Linux engine trên máy phát triển. Đây là backend local phục vụ phát triển/kiểm thử, không phải deployment production.

## Địa chỉ

| Dịch vụ | Địa chỉ |
| --- | --- |
| API / Auth / REST | http://127.0.0.1:15421 |
| Studio quản trị | http://127.0.0.1:15423 |
| Hộp thư kiểm thử | http://127.0.0.1:15424 |
| PostgreSQL | 127.0.0.1:15422 |
| Frontend Flutter | http://localhost:5174 |

Không dùng cổng mặc định 54321–54324 vì Windows trên máy này dành riêng dải 54288–54387. Network dự án là `little-island-local`; không dùng chung network/container với các dự án khác.

## Lệnh từ thư mục gốc project

```powershell
./scripts/backend.ps1 Start
./scripts/backend.ps1 Status
./scripts/backend.ps1 Migrate
./scripts/backend.ps1 Test
./scripts/test-backend-http.ps1
./scripts/backend.ps1 Stop
```

`Stop` giữ dữ liệu; không dùng `db reset` hoặc `stop --no-backup` khi cần giữ dữ liệu. Không đổi phiên bản CLI/image mà chưa backup. Các container không liên quan vẫn được giữ nguyên.

CLI được tải từ release chính thức và kiểm tra SHA256. Nếu thiếu `.tools/supabase/supabase.exe`, tải `supabase_2.122.0_windows_amd64.zip` và kiểm tra `checksums.txt` tại [release v2.122.0](https://github.com/supabase/cli/releases/tag/v2.122.0), giải nén vào `.tools/supabase/`.

## Dịch vụ

Đang dùng PostgreSQL 17, Auth, PostgREST, Kong, postgres-meta, Studio và Mailpit. Realtime, Storage, Edge Runtime, Analytics và Pooler chưa bật vì app chưa cần; asset hiện đóng gói trong Flutter.

CLI mặc định publish port Docker lên interface host. Network đã đặt default bind 127.0.0.1, nhưng CLI 2.122.0 trên Docker Desktop này vẫn khai báo HostIp 0.0.0.0/IPv6 trong port binding. Đây là môi trường development; chưa coi là cấu hình production hoặc xác nhận chỉ nghe loopback. Không mở/router-forward các cổng này ra Internet. Nếu cần giới hạn truy cập tuyệt đối, phải chọn runtime/compose có bind address tường minh trước khi dùng dữ liệu thật.

## Schema và API đã có

- `profiles`: mục tiêu mặc định, khung giờ, hồ sơ; tự tạo sau khi Auth tạo người dùng.
- `daily_goals`: mục tiêu lịch sử theo từng ngày/tài khoản.
- `water_intakes`: lịch sử uống nước, ngày địa phương, UTC/offset, revision và tombstone.
- `sync_receipts`: kết quả command để retry không ghi trùng.
- RLS theo `auth.uid()`, không dùng email làm khóa.
- Ghi/sửa/xóa intake qua RPC `apply_intake_command`; không cho client ghi thẳng bảng.

Ví dụ body cho `POST /rest/v1/rpc/apply_intake_command` sau khi có session:

```json
{
  "p_command_id": "UUID mới cho mỗi thao tác, giữ nguyên khi retry",
  "p_operation": "intake.upsert",
  "p_payload": {
    "id": "UUID của lần uống",
    "amount": 250,
    "occurred_at": "2026-10-28T01:00:00Z",
    "local_day": "2026-10-28",
    "offset_minutes": 420,
    "on_time": false
  },
  "p_expected_revision": null
}
```

Khi sửa, gửi revision đã biết. Khi xóa dùng `intake.delete` với `id` và revision đã biết. Retry cùng command ID nhưng nội dung khác bị từ chối. Bản ghi đã xóa không được upsert sống lại. `on_time` hiện là thông tin client, chưa dùng để cấp thưởng đáng tin cậy trên server.

## Cấu hình và giới hạn

Migration `202610290002_pet_preferences.sql` thêm `profiles.pet` (cat/dog/fish) và cập nhật `apply_settings_command`, giữ tương thích payload client cũ không có pet.

Runtime credential ở `.tools/supabase/status.json`, được Git ignore. Không đưa file này vào chat, frontend hoặc Git: nó chứa cả khóa quản trị. Chỉ URL và public/publishable key được đưa vào cấu hình client khi nối app.

Google/Apple/Facebook chưa bật vì chưa có provider credentials và định danh app chính thức. Email signup được bật cho kiểm thử local; thư chỉ vào Mailpit, không gửi qua nhà cung cấp email bên ngoài.

App Flutter đã có Auth UI, nhập dữ liệu khách vào tài khoản và outbox sync nối backend qua cấu hình public. Dùng `scripts/run-mobile.ps1` tại thư mục gốc. Migration `202610290001_settings_sync.sql` bổ sung revision và `apply_settings_command` cho profile/daily goal; quyền ghi trực tiếp bị thu hồi. Xem [giao thức](../document/sync-protocol.md), [OAuth setup](../document/oauth-setup.md). Phần thưởng do server xác nhận chưa triển khai.

## Kiểm thử

Đã chạy thành công trên máy này: SQL integration checks; HTTP Auth/Studio 200; signup, profile RLS, intake RPC và replay đều passed; không còn tài khoản test sau cleanup. Các container có health check đều healthy.

- `backend.ps1 Test`: SQL transaction rollback, xác minh RLS, insert/edit/delete, chống trùng, revision conflict, cấm ghi thẳng và chống hồi sinh tombstone; không để fixture trong DB.
- `test-backend-http.ps1`: kiểm tra Auth/Studio, tạo tài khoản synthetic local, gọi RPC và retry qua HTTP, sau đó xóa tài khoản cùng dữ liệu bằng admin API. Không in token/password.
- `test-mobile-sync.ps1`: kiểm thử Flutter repository/SQLite và RPC thật, offline/replay/conflict/restore/pagination; credentials admin chỉ trong môi trường test process.
- `test-mobile-android.ps1`: kiểm thử tài khoản local và đồng bộ trên emulator; không chứng minh OAuth đã hoạt động.

Tham khảo [Supabase local development](https://supabase.com/docs/guides/local-development/cli/getting-started). Khi chuyển lên VPS, xem [hướng dẫn self-host](../infra/self-host/README.md); không dùng nguyên cấu hình dev này làm production.
