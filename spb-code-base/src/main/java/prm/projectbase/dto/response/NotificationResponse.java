package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class NotificationResponse {

    Long id;
    String title;
    String body;
    String notificationType;
    String referenceType;
    Long referenceId;
    LocalDateTime readAt;
    LocalDateTime createdAt;
}
