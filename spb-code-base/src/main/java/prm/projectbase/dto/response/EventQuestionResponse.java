package prm.projectbase.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventQuestionResponse {

    Long id;
    Long assignmentId;
    String questionType;
    String content;
    Long authorId;
    String authorName;
    String authorRole;
    LocalDateTime askedAt;
}
