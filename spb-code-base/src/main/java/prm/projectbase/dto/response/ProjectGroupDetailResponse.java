package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

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
    List<UserResponse> members;
}
