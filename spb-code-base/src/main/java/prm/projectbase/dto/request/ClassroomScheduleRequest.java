package prm.projectbase.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomScheduleRequest {

    @NotNull(message = "Day of week is required")
    @Min(value = 0, message = "Day of week must be between 0 (Sunday) and 6 (Saturday)")
    @Max(value = 6, message = "Day of week must be between 0 (Sunday) and 6 (Saturday)")
    Integer dayOfWeek;

    @Size(max = 50, message = "Slot label cannot exceed 50 characters")
    String slotLabel;

    @NotNull(message = "Start time is required")
    LocalTime startTime;

    @NotNull(message = "End time is required")
    LocalTime endTime;

    @Size(max = 100, message = "Room name cannot exceed 100 characters")
    String roomName;
}
