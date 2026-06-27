package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomEnrollmentResponse {

    Long id;
    ClassroomListResponse classroom;
    UserResponse student;
    String status;
    LocalDateTime joinedAt;
}
