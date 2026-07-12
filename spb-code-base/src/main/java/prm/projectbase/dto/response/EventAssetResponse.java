package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventAssetResponse {

    Long id;
    Long assignmentId;
    String assetType;
    String visibility;
    String fileUrl;
    String originalFileName;
    String contentType;
    Long sizeBytes;
    Long uploadedById;
    String uploadedByName;
    Long ownerStudentId;
    LocalDateTime createdAt;
}
