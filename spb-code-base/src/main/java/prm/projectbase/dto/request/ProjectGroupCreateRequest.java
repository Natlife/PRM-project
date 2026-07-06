package prm.projectbase.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectGroupCreateRequest {

    @NotBlank(message = "Group name is required")
    String groupName;

    String projectName;
    String description;
    Long leaderId;
    List<Long> studentIds;
}
