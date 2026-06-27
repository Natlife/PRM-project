package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomListResponse {

    Long id;
    String code;
    String name;
    String semesterCode;
    UserResponse teacher;
    Integer studentCount;
    Boolean active;
    LocalDateTime createdAt;
}
