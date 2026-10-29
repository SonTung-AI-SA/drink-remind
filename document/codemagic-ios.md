# Build IPA bằng Codemagic từ Windows

Workflow `ios-sideload-unsigned` trong `codemagic.yaml` chạy trên macOS, thư mục `apps/mobile`, dùng Flutter 3.47.8. Có analyze và bộ test offline trước khi build release cho iPhone thật.

Không cần chứng chỉ Apple cho bước build chưa ký. Workflow tạo `Runner.app` bằng `flutter build ios --release --no-codesign`, đóng gói vào `Payload/Runner.app` trong IPA rồi xuất checksum. **IPA chưa ký không tự cài hoặc chạy trên iPhone**; tải về và dùng Sideloadly để ký bằng Apple ID của bạn. Không dùng file này để upload TestFlight.

## Chạy

1. Đăng nhập Codemagic và thêm repository `SonTung-AI-SA/drink-remind`.
2. Dùng cấu hình YAML, nhánh `main`, workflow `ios-sideload-unsigned`.
3. Start new build. Khi thành công, tải `LittleIsland-unsigned.ipa` trong Artifacts.
4. Chọn IPA trong Sideloadly trên Windows, kết nối iPhone và tự đăng nhập Apple ID để ký/cài. Không đưa mật khẩu hoặc token vào Git.

Bản mặc định không chứa endpoint/key backend local và dùng dữ liệu offline. Khi cần sync trên iPhone, phải cấu hình server iPhone truy cập được; localhost và địa chỉ emulator Android không phù hợp. OAuth vẫn chờ cấu hình riêng. Signing miễn phí có thể không hỗ trợ đầy đủ entitlement của dịch vụ Apple; cần kiểm tra trên thiết bị thật.

Nguồn: [Codemagic Flutter](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/), [YAML](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/), [Sideloadly](https://sideloadly.io/faq).

Không tự kích hoạt build theo mọi commit; workflow chạy thủ công để tránh dùng phút build ngoài dự kiến. Không publish TestFlight/App Store.

## Build đã xác minh

Workflow YAML đã chạy thành công trên Codemagic: [build 6ae3cafcefa74786046ee4c3](https://codemagic.io/app/6ae369716b6fb3823d372bae/build/6ae3cafcefa74786046ee4c3), nguồn commit `6f07bc83fc794dea92d610fdae530bbcdded0af9`.

- IPA: `output/ios/LittleIsland-unsigned.ipa`, 39.355.930 byte (~37,53 MiB).
- SHA-256: `be05f6319776c8766cb045037c9c7f7979e4b57b2007f3937856016f21dbe944`, khớp checksum tải từ artifact Codemagic.
- Có `Payload/Runner.app/Info.plist`, executable ARM64 và `Frameworks/App.framework/App`.
- Chưa ký để cài trực tiếp, chưa kiểm thử iPhone thật. Dùng Sideloadly để ký/cài; không phải IPA cho TestFlight.
- `output/` được ignore để không commit artifact build vào repository.
