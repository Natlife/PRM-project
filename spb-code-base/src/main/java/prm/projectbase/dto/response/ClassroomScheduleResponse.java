package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomScheduleResponse {

    Long id;
    Integer dayOfWeek;
    String slotLabel;
    LocalTime startTime;
    LocalTime endTime;
    String roomName;
}
