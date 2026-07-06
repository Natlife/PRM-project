# Spring Boot Base Project - MySQL & Role-Based Security

Dự án Base Spring Boot chuẩn sản xuất (Production-ready) tích hợp cơ chế bảo mật stateless JWT, phân quyền dạng Role động qua AOP Custom Annotation và sử dụng cơ sở dữ liệu **MySQL**.

---

## CÁC TÍNH NĂNG CỐT LÕI

1. **Kiến trúc Tối giản (Direct DI)**: Sử dụng trực tiếp Concrete Service Class (không dùng Interface trung gian), tiêm trực tiếp vào Controller qua Constructor.
2. **Bảo mật stateless JWT**: Phân quyền hoàn toàn không trạng thái. Đọc thông tin User và Role trực tiếp từ token claim giúp giảm tải truy vấn DB.
3. **Custom Annotation `@AuthFilter`**: Phân quyền trực tiếp qua vai trò Role (ví dụ: `ADMIN`, `USER`). Tự động so sánh ID người dùng từ Token với tham số `id` của phương thức để cho phép truy cập tài nguyên chính chủ (Self-service Owner Check) mà không cần viết SpEL phức tạp.
4. **Bộ xử lý lỗi tập trung**: Quản lý lỗi bằng `ErrorCode` Enum. Mọi lỗi nghiệp vụ và hệ thống được đóng gói thành chuỗi JSON phản hồi chuẩn hóa, mã lỗi nghiệp vụ trùng khớp với mã trạng thái HTTP thực tế (e.g. 400, 401, 403, 404).

---

## CẤU HÌNH CƠ SỞ DỮ LIỆU (MYSQL)

Cấu hình mặc định được thiết lập sẵn trong file **[application.properties](src/main/resources/application.properties)**:

```properties
# Active Database: MySQL
spring.datasource.url=jdbc:mysql://localhost:3306/project_base_db?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=
spring.datasource.driverClassName=com.mysql.cj.jdbc.Driver

# JPA & HIBERNATE
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

> **Lưu ý**: Tham số `createDatabaseIfNotExist=true` sẽ tự động tạo cơ sở dữ liệu `project_base_db` trên MySQL của bạn khi Server khởi động nếu nó chưa tồn tại.

---

## VÍ DỤ PHÂN QUYỀN ĐỘNG VỚI `@AuthFilter`

Được khai báo ngắn gọn trên các phương thức trong **[UserController.java](src/main/java/prm/projectbase/controller/UserController.java)**:

```java
// Chỉ tài khoản có Role "ROLE_ADMIN" mới được phép gọi
@PostMapping
@AuthFilter(permission = "ADMIN")
public BaseResponse<UserResponse> createUser(@RequestBody @Valid UserCreateRequest request) { ... }

// Quyền ADMIN toàn cục HOẶC User thường tự xem/sửa chính ID của mình (Dynamic Owner check)
@GetMapping("/{id}")
@AuthFilter(permission = "ADMIN")
public BaseResponse<UserResponse> getUserById(@PathVariable Long id) { ... }
```

---

## HƯỚNG DẪN CHẠY VÀ DỮ LIỆU MẪU

### 1. Khởi chạy Server

Mở Terminal tại thư mục gốc và chạy lệnh:

```powershell
.\mvnw.cmd spring-boot:run
```

Server sẽ tự sinh cấu trúc bảng MySQL và ghi sẵn dữ liệu thử nghiệm (Seeded Data):

| Tài khoản (Username) | Mật khẩu (Password) | Vai trò (Role) | Mô tả quyền hạn                                          |
| :------------------- | :------------------ | :------------- | :------------------------------------------------------- |
| **`admin`**          | `admin123`          | `ROLE_ADMIN`   | Có toàn quyền CRUD tất cả User                           |
| **`user`**           | `user123`           | `ROLE_USER`    | Chỉ tự xem/sửa thông tin cá nhân của chính mình (ID = 2) |

---

## KIỂM THỬ API QUA cURL / POSTMAN

### Bước 1: Đăng nhập (Lấy Token bảo mật)

```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username": "admin", "password": "admin123"}'
```

_Response trả về chuỗi `"token": "eyJhbGciOi..."` dùng làm Bearer Token._

### Bước 2: Truy xuất danh sách User (Quyền ADMIN)

```bash
curl -X GET http://localhost:5001/api/v1/users \
     -H "Authorization: Bearer <DÁN_TOKEN_ADMIN_VÀO_ĐÂY>"
```

### Bước 3: Đăng nhập sai mật khẩu (Lỗi 402 Custom)

```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username": "admin", "password": "wrongpassword"}'
```

_Kết quả trả về mã lỗi nghiệp vụ chuẩn hóa:_

```json
{
  "code": 402,
  "message": "Invalid parameters",
  "timestamp": "2026-05-18T06:36:56"
}
```

### Bước 4: User thường tự truy cập chính mình (Thành công - Dynamic Owner)

```bash
curl -X GET http://localhost:5001/api/v1/users/2 \
     -H "Authorization: Bearer <TOKEN_CỦA_USER_THƯỜNG>"
```

_Hệ thống tự nhận diện ID = 2 khớp với tài khoản đăng nhập và cho phép xem thành công._

### Bước 5: User thường cố tình truy cập Admin (Bị cấm - 403 Forbidden)

```bash
curl -X GET http://localhost:5001/api/v1/users/1 \
     -H "Authorization: Bearer <TOKEN_CỦA_USER_THƯỜNG>"
```

_Bị chặn và trả về lỗi:_

```json
{
  "code": 403,
  "message": "You do not have permission",
  "timestamp": "2026-05-18T06:38:12"
}
```
# spb-project-base
