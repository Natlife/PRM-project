package prm.projectbase.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventAssignmentRequest {

    @NotBlank(message = "assignmentType is required")
    String assignmentType;

    Long presenterStudentId;

    Long presenterGroupId;

    @NotNull(message = "reviewerStudentId is required")
    Long reviewerStudentId;

    @NotNull(message = "orderIndex is required")
    @Min(value = 1, message = "orderIndex must be greater than 0")
    Integer orderIndex;
}
