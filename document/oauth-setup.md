# Cấu hình Google, Apple và Facebook

Cập nhật 29/10/2026. App dùng Supabase Auth, OAuth qua trình duyệt và PKCE. Chưa có ứng dụng OAuth của chủ dự án nên ba nút hiện **Chờ cấu hình**. Không gửi secret, khóa `.p8` hoặc service-role key trong chat; lưu ở biến môi trường/secret của server.

## 1. Hai loại callback

Ví dụ domain backend sau này là `https://api.example.com`:

| Mục đích | Địa chỉ |
| --- | --- |
| Nhà cung cấp trả về Supabase Auth | `https://api.example.com/auth/v1/callback` |
| Supabase trả về app Android/iOS | `com.littleisland.little_island://login-callback/` |
| Bản web local | `http://localhost:5174/` |

Callback đăng ký ở Google/Apple/Meta là URL HTTPS của **server**, không phải URI của app. URI app được đặt trong allowlist redirect của Supabase. Scheme/app ID hiện là định danh tạm; nếu đổi phải cập nhật AndroidManifest, Info.plist, BackendConfig và allowlist cùng nhau.

Android emulator gọi API host qua `http://10.0.2.2:15421`. Trình duyệt trên emulator coi `127.0.0.1` là chính emulator; callback loopback dùng trên PC không tự hoạt động trên Android. Để thử đủ ba provider trên điện thoại, chuẩn bị domain HTTPS truy cập được từ cả thiết bị và nhà cung cấp. Chưa tự mở tunnel hoặc công khai backend local. Cấu hình dev cho phép HTTP chỉ với loopback/emulator và chỉ ở bản Android debug.

## 2. Google

1. Tạo project trong Google Cloud/Google Auth Platform, cấu hình thông tin ứng dụng và consent screen; thêm tài khoản thử khi app còn ở chế độ Testing.
2. Tạo OAuth client loại Web application cho luồng trình duyệt đang dùng.
3. Đăng ký chính xác callback Supabase ở Authorized redirect URIs. Nếu dùng bản web, khai báo origin của website khi được yêu cầu.
4. Lưu Client ID và Client Secret vào cấu hình Auth server. Chỉ bật provider trong app sau khi server đã cấu hình.

Hướng dẫn chính thức: [Supabase Google OAuth](https://supabase.com/docs/guides/auth/social-sign-in/auth-google).

## 3. Apple

1. Chuẩn bị Apple Developer team, App ID với Sign in with Apple và Services ID gắn với App ID đó.
2. Khai báo domain HTTPS của backend và Return URL là callback Supabase.
3. Tạo signing key; lưu riêng Team ID, Key ID và file `.p8`. Sinh client secret JWT ở môi trường server. Services ID là client ID cho luồng OAuth trình duyệt.
4. Theo dõi hạn client secret và thay trước khi hết hạn. Hoàn thiện signing/Keychain trên macOS/Xcode; source hiện có URL scheme và entitlement Keychain nhưng chưa được build iOS trên Windows.

Apple có thể cấp email relay khi người dùng chọn ẩn email; cần liên kết nhà cung cấp khi đã đăng nhập tài khoản muốn giữ. Hướng dẫn: [Supabase Apple OAuth](https://supabase.com/docs/guides/auth/social-sign-in/auth-apple).

## 4. Facebook

1. Tạo ứng dụng trong Meta for Developers, thêm Facebook Login/use case đăng nhập phù hợp.
2. Khai báo callback Supabase tại Valid OAuth Redirect URIs; kiểm tra App Domains và các thông tin ứng dụng được yêu cầu.
3. Cấu hình App ID, App Secret trên Auth server; kiểm tra quyền email và tài khoản tester/developer khi còn Development.
4. Trước khi phát hành, hoàn thiện URL chính sách riêng tư, hướng dẫn/yêu cầu xóa dữ liệu và các bước duyệt Meta yêu cầu. Kiểm tra tài khoản ngoài nhóm phát triển sau khi chuyển Live.

Hướng dẫn: [Supabase Facebook OAuth](https://supabase.com/docs/guides/auth/social-sign-in/auth-facebook).

## 5. Supabase local và server riêng

CLI local: các mục `[auth.external.google]`, `[auth.external.apple]`, `[auth.external.facebook]` có sẵn trong `supabase/config.toml`, mặc định disabled. Điền client ID, secret qua môi trường; bật từng provider khi đủ thông tin rồi restart dịch vụ dự án. Apple `client_id` hiện để trống, thay bằng Services ID.

Tên biến Google/Facebook hiện dùng trong config:

```text
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET
SUPABASE_AUTH_EXTERNAL_FACEBOOK_CLIENT_ID
SUPABASE_AUTH_EXTERNAL_FACEBOOK_SECRET
SUPABASE_AUTH_EXTERNAL_APPLE_SECRET
```

Với Docker self-host production, khai báo biến `GOTRUE_EXTERNAL_<PROVIDER>_ENABLED`, `_CLIENT_ID`, `_SECRET`, `_REDIRECT_URI` trong service Auth của Compose. Đặt `_REDIRECT_URI` bằng callback HTTPS đầy đủ phía trên; cấu hình external URL, site URL và redirect allowlist cho đúng domain. CLI `config.toml` không tự cấu hình Compose production. Bật manual linking (`GOTRUE_SECURITY_MANUAL_LINKING_ENABLED`) nếu dùng nút liên kết. Xem [hướng dẫn OAuth self-host chính thức](https://supabase.com/docs/guides/self-hosting/self-hosted-oauth).

Build app sau khi cấu hình server:

```powershell
# Chỉ liệt kê provider đã cấu hình thành công trên backend.
./scripts/run-mobile.ps1 -OAuthProviders 'google,apple,facebook'
```

Production truyền `SUPABASE_URL` HTTPS, `SUPABASE_ANON_KEY` public/publishable key và `OAUTH_PROVIDERS` qua `--dart-define-from-file`. Không nhúng secret của provider/service-role vào APK/IPA. `ALLOW_LOCAL_AUTH` chỉ hoạt động ở bản debug với backend loopback/emulator; release không hiện đăng nhập thử.

## 6. Liên kết và dữ liệu

Khi đã đăng nhập, nút nhà cung cấp chuyển sang Liên kết và gọi `linkIdentity`. Supabase quản lý các identity cùng user ID; xem [chính sách linking](https://supabase.com/docs/guides/auth/auth-identity-linking). Nếu identity đã thuộc tài khoản khác, app báo lỗi và không tự chuyển lịch sử giữa hai tài khoản. Hợp nhất hai tài khoản đã tồn tại cần luồng xác minh quyền sở hữu riêng, chưa có trong bản này.

Lịch sử khách chỉ nhập khi người dùng chọn và xác nhận. Sau lần nhập đầu, dữ liệu khách được gắn với một tài khoản để tránh chuyển sang tài khoản khác. Nếu tài khoản đã có hồ sơ/mục tiêu, giữ dữ liệu tài khoản; chỉ bổ sung lần uống chưa có và mục tiêu ngày chưa tồn tại.

## 7. Checklist sau khi có credentials

- Mỗi provider: thành công, người dùng hủy, lỗi callback, mở app khi đang đóng và đang chạy.
- Làm mới phiên, mở lại app, đăng xuất rồi vào tài khoản khác, đăng nhập trên máy mới.
- Liên kết provider mới, provider đã liên kết và identity thuộc tài khoản khác.
- Apple ẩn email; Facebook không trả email; callback không thuộc allowlist phải bị từ chối.
- Android/iOS thật; không coi kiểm thử fixture email local là bằng chứng OAuth đã hoạt động.
