package prm.projectbase.dto.request;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectGroupUpdateRequest {

    String groupName;
    String projectName;
    String description;
    Long leaderId;
    String status; 
    List<Long> studentIds;
}
