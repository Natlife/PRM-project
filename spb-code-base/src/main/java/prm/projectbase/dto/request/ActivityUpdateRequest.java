package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import prm.projectbase.entity.enums.ActivityWorkflowStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityUpdateRequest {
    
    @Size(min = 1, max = 255, message = "Title must be between 1 and 255 characters")
    private String title;
    
    private String description;
    
    private LocalDateTime openAt;
    
    private LocalDateTime dueAt;
    
    @DecimalMin(value = "0.01", message = "Max score must be greater than 0")
    @DecimalMax(value = "100", message = "Max score must not exceed 100")
    private BigDecimal maxScore;
    
    private ActivityWorkflowStatus status;
}
