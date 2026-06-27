package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubmissionUpdateRequest {
    
    private String content;
    
    private List<MultipartFile> attachmentFiles;
}
