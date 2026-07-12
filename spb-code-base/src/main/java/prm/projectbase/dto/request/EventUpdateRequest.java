package prm.projectbase.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventUpdateRequest {

    @Size(max = 255, message = "title must not exceed 255 characters")
    String title;

    @Size(max = 4000, message = "description must not exceed 4000 characters")
    String description;

    LocalDateTime startAt;

    LocalDateTime endAt;

    @Min(value = 1, message = "sessionDurationMinutes must be greater than 0")
    Integer sessionDurationMinutes;

    String status;
}
