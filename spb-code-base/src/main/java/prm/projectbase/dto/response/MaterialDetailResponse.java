package prm.projectbase.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialDetailResponse {
    
    private Long id;
    
    private Long classroomId;
    
    private String title;
    
    private String description;
    
    private String materialType;
    
    private String originalFileName;
    
    private String contentType;
    
    private Long sizeBytes;

    private String fileUrl;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime publishedAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
}
