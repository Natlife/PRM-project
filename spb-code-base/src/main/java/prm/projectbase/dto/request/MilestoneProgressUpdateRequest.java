package prm.projectbase.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MilestoneProgressUpdateRequest {

    @NotNull(message = "Progress percent is required")
    @Min(value = 0, message = "Progress must be at least 0")
    @Max(value = 100, message = "Progress must be at most 100")
    Integer progressPercent;

    @NotNull(message = "Status is required")
    String status; // NOT_STARTED, IN_PROGRESS, COMPLETED, OVERDUE
}
