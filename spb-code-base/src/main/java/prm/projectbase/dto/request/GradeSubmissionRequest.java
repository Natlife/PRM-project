package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GradeSubmissionRequest {
    
    @NotNull(message = "Score is required")
    @DecimalMin(value = "0", message = "Score must be at least 0")
    @DecimalMax(value = "100", message = "Score must not exceed 100")
    private BigDecimal score;
    
    @Size(max = 4000, message = "Feedback must not exceed 4000 characters")
    private String feedback;
}
