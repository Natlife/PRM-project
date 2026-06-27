package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import prm.projectbase.entity.enums.CommentScope;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubmissionCommentRequest {
    
    @NotBlank(message = "Comment content is required")
    @Size(min = 1, max = 4000, message = "Comment must be between 1 and 4000 characters")
    private String content;
    
    @NotNull(message = "Comment scope is required")
    private CommentScope scope;
}
