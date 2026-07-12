package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventAssignmentResponse {

    Long id;
    String assignmentType;
    Integer orderIndex;
    String status;
    Long presenterStudentId;
    String presenterStudentName;
    Long presenterGroupId;
    String presenterGroupName;
    Long reviewerStudentId;
    String reviewerStudentName;
    String myRole;
    Boolean currentUserInPresenterTeam;
    List<EventQuestionResponse> questions;
    List<EventAssetResponse> evidences;
    EventAssetResponse recording;
}
