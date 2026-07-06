package prm.projectbase.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectMilestoneCreateRequest {

    @NotBlank(message = "Title is required")
    String title;

    String description;

    @NotNull(message = "Due date is required")
    LocalDateTime dueAt;
}
