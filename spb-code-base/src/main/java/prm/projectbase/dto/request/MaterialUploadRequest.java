package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.entity.enums.ClassroomMaterialType;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialUploadRequest {
    
    @NotBlank(message = "Material title is required")
    @Size(min = 1, max = 255, message = "Title must be between 1 and 255 characters")
    private String title;
    
    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;
    
    @NotNull(message = "Material type is required")
    private ClassroomMaterialType materialType;
    
    @NotNull(message = "File is required")
    private MultipartFile file;
    
    @Builder.Default
    private Boolean publishImmediately = true;
    
    private LocalDateTime schedulePublishAt;
}
