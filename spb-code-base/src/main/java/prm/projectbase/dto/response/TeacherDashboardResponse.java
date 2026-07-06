package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class TeacherDashboardResponse {

    Integer managedClassroomsCount;
    Integer totalStudentsCount;
    Integer pendingGradingCount;
    Integer activeGroupsCount;
    List<ClassroomListResponse> classrooms;
}
