package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "roles")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Role extends BaseEntity{

    @Column(unique = true, nullable = false)
    String name; // e.g. "ROLE_ADMIN", "ROLE_TEACHER", "ROLE_STUDENT"

    String description;

}
