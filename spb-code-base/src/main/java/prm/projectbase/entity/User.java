package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class User extends BaseEntity{

    @Column(unique = true, nullable = false)
    String userName;
        
    @Column(nullable = false)
    String password;

    @Column(unique = true, nullable = false)
    String email;

    @Column(name = "full_name")
    String fullName;

    @Column(name = "phone", length = 20)
    String phone;

    @Column(name = "avatar_url", length = 512)
    String avatarUrl;

    @Column(name = "institutional_id", unique = true, length = 50)
    String institutionalId;

    @Builder.Default
    @Column(nullable = false)
    boolean active = true;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "role_id")
    Role role;
}
