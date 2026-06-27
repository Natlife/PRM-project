package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectGroupListResponse {

    Long id;
    String groupName;
    String projectName;
    UserResponse leader;
    String status;
    Integer memberCount;
}
