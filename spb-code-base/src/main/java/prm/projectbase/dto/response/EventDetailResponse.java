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
public class EventDetailResponse {

    Long id;
    Long classroomId;
    String classroomCode;
    String classroomName;
    String title;
    String description;
    LocalDateTime startAt;
    LocalDateTime endAt;
    Integer sessionDurationMinutes;
    String status;
    UserResponse teacher;
    String myRole;
    Boolean canManage;
    Boolean canJoinRoom;
    Boolean canWatchRecording;
    Boolean canUploadEvidence;
    Boolean canAskQuestions;
    EventAssignmentResponse myAssignment;
    List<EventAssignmentResponse> assignments;
    List<EventQuestionResponse> questionBank;
    List<UserResponse> availableStudents;
    List<ProjectGroupListResponse> availableGroups;
}
