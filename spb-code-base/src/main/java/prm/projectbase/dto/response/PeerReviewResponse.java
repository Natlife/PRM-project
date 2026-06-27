package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class PeerReviewResponse {

    Long id;
    Long classroomId;
    Long reviewerStudentId;
    String reviewerStudentName;
    Long reviewedGroupId;
    String reviewedGroupName;
    Integer codeQualityScore;
    Integer uiUxScore;
    Integer featureScore;
    Integer presentationScore;
    String comment;
    LocalDateTime submittedAt;
    String status;
}
