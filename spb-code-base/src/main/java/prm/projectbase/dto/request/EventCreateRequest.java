package prm.projectbase.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventCreateRequest {

    @NotNull(message = "classroomId is required")
    Long classroomId;

    @NotBlank(message = "title is required")
    @Size(max = 255, message = "title must not exceed 255 characters")
    String title;

    @Size(max = 4000, message = "description must not exceed 4000 characters")
    String description;

    @NotNull(message = "startAt is required")
    LocalDateTime startAt;

    @NotNull(message = "endAt is required")
    LocalDateTime endAt;

    @NotNull(message = "sessionDurationMinutes is required")
    @Min(value = 1, message = "sessionDurationMinutes must be greater than 0")
    Integer sessionDurationMinutes;
}
