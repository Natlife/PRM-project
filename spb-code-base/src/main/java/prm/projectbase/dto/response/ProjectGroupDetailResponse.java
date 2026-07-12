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
public class ProjectGroupDetailResponse {

    Long id;
    Long classroomId;
    String groupName;
    String projectName;
    String description;
    UserResponse leader;
    String status;
    String classroomCode;
    String classroomName;
    Integer memberCount;
    Double progressPercent;
    LocalDateTime latestMilestoneDueAt;
    List<UserResponse> members;
    List<ProjectMilestoneResponse> milestones;
}
