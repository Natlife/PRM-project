package prm.projectbase.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UserUpdateRequest {

    @Size(min = 6, message = "INVALID_PASSWORD")
    String password;

    @Email(message = "EMAIL_EXISTED")
    String email;

    String fullName;

    String phone;

    String avatarUrl;

    String institutionalId;

    Boolean active;

    Long roleId;
}
