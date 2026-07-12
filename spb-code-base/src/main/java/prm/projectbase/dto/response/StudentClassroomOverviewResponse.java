package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StudentClassroomOverviewResponse {

    ClassroomDetailResponse classroom;
    List<ActivityListResponse> activities;
    List<MaterialListResponse> materials;
    ProjectGroupDetailResponse projectGroup;
}
