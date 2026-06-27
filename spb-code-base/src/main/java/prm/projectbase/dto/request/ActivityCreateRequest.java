package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import prm.projectbase.entity.enums.ActivityType;
import prm.projectbase.entity.enums.ActivityWorkflowStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityCreateRequest {
    
    @NotBlank(message = "Activity title is required")
    @Size(min = 1, max = 255, message = "Title must be between 1 and 255 characters")
    private String title;
    
    @NotBlank(message = "Activity description is required")
    private String description;
    
    @NotNull(message = "Activity type is required")
    private ActivityType activityType;
    
    private LocalDateTime openAt;
    
    @NotNull(message = "Due date is required")
    private LocalDateTime dueAt;
    
    @DecimalMin(value = "0.01", message = "Max score must be greater than 0")
    @DecimalMax(value = "100", message = "Max score must not exceed 100")
    private BigDecimal maxScore;
}
