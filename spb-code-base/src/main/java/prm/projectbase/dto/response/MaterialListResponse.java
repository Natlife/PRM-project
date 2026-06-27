package prm.projectbase.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialListResponse {
    
    private Long id;
    
    private String title;
    
    private String description;
    
    private String materialType;
    
    private String originalFileName;
    
    private Long sizeBytes;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime publishedAt;
}
