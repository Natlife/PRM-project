package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.EventWorkflowStatus;

import java.time.LocalDateTime;

@Entity
@Table(name = "events", indexes = {
        @Index(name = "idx_events_classroom_id", columnList = "classroom_id"),
        @Index(name = "idx_events_status", columnList = "status"),
        @Index(name = "idx_events_start_at", columnList = "start_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Event extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @Column(nullable = false, length = 255)
    String title;

    @Column(length = 4000)
    String description;

    @Column(name = "start_at", nullable = false)
    LocalDateTime startAt;

    @Column(name = "end_at", nullable = false)
    LocalDateTime endAt;

    @Column(name = "session_duration_minutes", nullable = false)
    Integer sessionDurationMinutes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    EventWorkflowStatus status = EventWorkflowStatus.SCHEDULED;
}
