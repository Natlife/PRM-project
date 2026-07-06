package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectMilestoneResponse {

    Long id;
    Long groupId;
    String title;
    String description;
    LocalDateTime dueAt;
    Integer progressPercent;
    String status;
    List<MilestoneAttachmentResponse> attachments;
}
