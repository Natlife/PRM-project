package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MilestoneAttachmentResponse {

    Long id;
    String storageKey;
    String originalFileName;
    String contentType;
    Long sizeBytes;
    Long uploadedById;
    String uploadedByName;
}
