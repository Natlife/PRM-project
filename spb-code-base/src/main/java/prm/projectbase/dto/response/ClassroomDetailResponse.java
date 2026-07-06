package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomDetailResponse {

    Long id;
    String code;
    String name;
    String description;
    String semesterCode;
    String joinCode;
    Boolean active;
    UserResponse teacher;
    Integer studentCount;
    List<ClassroomScheduleResponse> schedules;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
}
