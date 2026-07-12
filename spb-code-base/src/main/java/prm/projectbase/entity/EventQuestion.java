package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.EventQuestionType;

import java.time.LocalDateTime;

@Entity
@Table(name = "event_questions", indexes = {
        @Index(name = "idx_event_questions_event_id", columnList = "event_id"),
        @Index(name = "idx_event_questions_assignment_id", columnList = "assignment_id"),
        @Index(name = "idx_event_questions_author_id", columnList = "author_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventQuestion extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    Event event;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id")
    EventAssignment assignment;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_id", nullable = false)
    User author;

    @Enumerated(EnumType.STRING)
    @Column(name = "question_type", nullable = false, length = 20)
    EventQuestionType questionType;

    @Column(nullable = false, length = 4000)
    String content;

    @Column(name = "asked_at", nullable = false)
    LocalDateTime askedAt;
}
