package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StudentDashboardResponse {

    Integer enrolledClassroomsCount;
    Integer pendingActivitiesCount;
    Long unreadNotificationsCount;
    List<ActivityListResponse> upcomingActivities;
    List<ProjectGroupListResponse> activeGroups;
}
