# Smart Attendance Mobile

Flutter client cho backend Laravel trong repo này.

## Yêu cầu trước khi chạy

- Đã cài Flutter SDK
- Có Android Studio hoặc VS Code + Flutter extension
- Có ít nhất một thiết bị để chạy thử:
  - Android Emulator
  - điện thoại Android thật
  - hoặc iPhone nếu bạn build trên macOS
- Backend Laravel trong repo này phải chạy được trước

## Luồng đã triển khai

- Splash + khôi phục phiên đăng nhập
- Login + lưu token
- Cấu hình `baseUrl` ngay trong app
- Home dashboard
- Kiểm tra mạng trước khi chấm công
- Check-in / Check-out với GPS, network info, device info
- Lịch sử attendance + log chấm công
- Hồ sơ cá nhân + cập nhật profile + logout

## Cấu hình nhanh

`baseUrl` mặc định:

```txt
http://10.0.2.2:8000/api
```

Có thể đổi bằng 2 cách:

1. Truyền lúc chạy app:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

2. Hoặc mở sheet `API` / `Đổi base URL` ngay trong app

Ví dụ:

- Android Emulator: `http://10.0.2.2:8000`
- Máy thật: `https://<your-ngrok-domain>.ngrok-free.app`
- Nếu nhập chưa có `/api`, app sẽ tự thêm

## Tài khoản test

```txt
nv001 / password123
admin01 / password123
```

## Chạy từ đầu

### 1. Chạy backend trước

Từ thư mục gốc của project:

```bash
docker compose up -d --build
docker compose exec app composer install
docker compose exec app php artisan migrate
docker compose exec app php artisan db:seed
docker compose exec app php artisan optimize:clear
```

Nếu backend đã được chạy sẵn từ trước thì chỉ cần chắc rằng API dùng được ở một trong các URL sau:

- `http://localhost:8000`
- hoặc URL public/ngrok của bạn

### 2. Mở Flutter app

Từ thư mục gốc của project:

```bash
cd flutter_app
```

### 3. Cài package

```bash
flutter pub get
```

### 4. Kiểm tra thiết bị đang sẵn sàng

```bash
flutter devices
```

Nếu chưa có emulator thì mở Android Studio rồi start một emulator trước.

### 5. Chạy app

Chạy cách cơ bản:

```bash
flutter run
```

Nếu có nhiều thiết bị:

```bash
flutter run -d <device-id>
```

Ví dụ:

```bash
flutter run -d emulator-5554
```

### 6. Đăng nhập

Sau khi app mở lên, dùng một trong hai tài khoản:

```txt
nv001 / password123
admin01 / password123
```

## Chạy theo từng môi trường

### Android Emulator

Đây là cách dễ nhất khi demo local.

Base URL nên dùng:

```txt
http://10.0.2.2:8000/api
```

Chạy:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Nếu Android báo lỗi về `NDK`, `compileSdk` hoặc `AAR metadata`, hãy kiểm tra trong Android Studio SDK Manager rằng bạn đã cài:

- Android SDK Platform 36
- Android SDK Build-Tools 36.x
- Android NDK `27.0.12077973`

Project hiện đang dùng:

- `compileSdk 36`
- `minSdk 23`
- `Android Gradle Plugin 8.10.1`
- `Gradle 8.11.1`
- `Kotlin Gradle Plugin 2.2.0`

### Điện thoại Android thật

Nếu điện thoại không truy cập được `localhost`, hãy dùng ngrok hoặc một URL public.

Base URL ví dụ:

```txt
https://<your-ngrok-domain>.ngrok-free.app/api
```

Chạy:

```bash
flutter run --dart-define=API_BASE_URL=https://<your-ngrok-domain>.ngrok-free.app/api
```

Hoặc bạn có thể chạy app trước rồi vào nút `API` / `Đổi base URL` trong app để sửa trực tiếp.

## Cách đổi base URL trong app

App hỗ trợ đổi API ngay trên giao diện:

1. Ở màn hình login bấm nút `API`
2. Hoặc vào tab `Tài khoản` rồi bấm `Đổi base URL`
3. Nhập URL backend
4. Nếu bạn nhập `http://10.0.2.2:8000` thì app sẽ tự thêm `/api`

## Lệnh chạy nhanh hay dùng

Từ thư mục `flutter_app`:

```bash
flutter pub get
flutter devices
flutter run
flutter run -d emulator-5554
flutter analyze --no-pub
flutter test --no-pub
```

## Cách update package và Flutter

Từ thư mục `flutter_app`:

### 1. Xem package nào đang cũ

```bash
flutter pub outdated
```

Lệnh này sẽ cho bạn thấy:

- `Current`: version hiện đang dùng
- `Upgradable`: version mới nhất vẫn phù hợp với `pubspec.yaml`
- `Resolvable`: version có thể lên được nếu nới constraint
- `Latest`: version mới nhất trên pub.dev

### 2. Update an toàn trong constraint hiện tại

```bash
flutter pub upgrade
```

Cách này an toàn nhất vì chỉ update những version còn tương thích với `pubspec.yaml` hiện tại.

### 3. Update mạnh hơn lên version mới hơn

```bash
flutter pub upgrade --major-versions
```

Lệnh này sẽ cố gắng nâng lên version mới nhất có thể và có thể cập nhật luôn constraint trong `pubspec.yaml`.

Sau khi update nên chạy lại:

```bash
flutter analyze
flutter test
```

### 4. Update Flutter SDK

Nếu bạn muốn update chính Flutter SDK chứ không chỉ package:

```bash
flutter upgrade
```

### 5. Quy trình update khuyến nghị cho project này

```bash
flutter pub outdated
flutter pub upgrade
flutter analyze
flutter test
```

Nếu mọi thứ ổn rồi mà vẫn muốn lên version mới hơn nữa thì mới chạy:

```bash
flutter pub upgrade --major-versions
flutter analyze
flutter test
```

## Luồng test nhanh đề xuất

1. Chạy backend
2. Chạy emulator Android
3. Trong `flutter_app`, chạy:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

4. Đăng nhập bằng `nv001 / password123`
5. Ở Home, chọn địa điểm làm việc
6. Bấm `Kiểm tra` để test network
7. Bấm `Check-in` hoặc `Check-out`

## Nếu chạy không được thì kiểm tra gì

- Backend đã chạy chưa
- URL API có đúng chưa
- Nếu chạy trên emulator Android thì phải dùng `10.0.2.2`, không dùng `localhost`
- Nếu chạy trên máy thật thì không dùng `localhost`, nên dùng ngrok/public URL
- GPS của máy đã bật chưa
- App đã được cấp quyền vị trí chưa
- Seeder đã chạy chưa để có tài khoản test

## Lưu ý trên Windows

Nếu `flutter pub get` báo lỗi symlink/plugin, hãy bật **Developer Mode** trong Windows trước rồi chạy lại:

```powershell
start ms-settings:developers
```

## File quan trọng

- `lib/src/app_session.dart`: quản lý token, base URL, bootstrap session
- `lib/src/screens/home_screen.dart`: luồng chấm công, GPS, network check
- `lib/src/screens/history_screen.dart`: bản ghi attendance và logs
- `lib/src/screens/profile_screen.dart`: profile + logout
