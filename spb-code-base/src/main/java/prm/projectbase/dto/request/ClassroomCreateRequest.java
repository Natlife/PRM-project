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
public class ClassroomCreateRequest {

    @NotBlank(message = "Classroom code is required")
    @Size(min = 3, max = 50, message = "Classroom code must be between 3 and 50 characters")
    @Pattern(regexp = "^[A-Z0-9-]+$", message = "Classroom code must contain only uppercase letters, numbers, and hyphens")
    String code;

    @NotBlank(message = "Classroom name is required")
    @Size(min = 3, max = 255, message = "Classroom name must be between 3 and 255 characters")
    String name;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    String description;

    @NotBlank(message = "Semester code is required")
    @Size(min = 2, max = 30, message = "Semester code must be between 2 and 30 characters")
    String semesterCode;

    @Valid
    @Size(min = 1, max = 10, message = "Classroom must have at least 1 and at most 10 schedules")
    List<ClassroomScheduleRequest> schedules;
}
