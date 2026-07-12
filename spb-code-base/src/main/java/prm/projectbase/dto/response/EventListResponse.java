package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventListResponse {

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
    String myRole;
    Boolean canJoinRoom;
    Boolean canWatchRecording;
    Integer assignmentCount;
}
