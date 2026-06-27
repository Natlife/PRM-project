package prm.projectbase.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomUpdateRequest {

    @Size(min = 3, max = 255, message = "Classroom name must be between 3 and 255 characters")
    String name;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    String description;

    @Size(min = 2, max = 30, message = "Semester code must be between 2 and 30 characters")
    String semesterCode;

    @Valid
    @Size(max = 10, message = "Classroom can have at most 10 schedules")
    List<ClassroomScheduleRequest> schedules;

    Boolean active;
}
