package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UserResponse {

    Long id;
    String userName;
    String email;
    String fullName;
    String phone;
    String avatarUrl;
    String institutionalId;
    boolean active;
    RoleResponse role;

    public UserResponse(Long id, String username, String email, String fullName, boolean active) {
        this.id = id;
        this.userName = username;
        this.email = email;
        this.fullName = fullName;
        this.active = active;
    }
}
