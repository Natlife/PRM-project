package prm.projectbase.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityListResponse {
    
    private Long id;
    
    private String title;
    
    private String description;
    
    private String activityType;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dueAt;
    
    private BigDecimal maxScore;
    
    private String status;
}
