package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ActivityType;
import prm.projectbase.entity.enums.ActivityWorkflowStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "learning_activities", indexes = {
        @Index(name = "idx_learning_activities_classroom_id", columnList = "classroom_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class LearningActivity extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @Column(nullable = false, length = 255)
    String title;

    @Column(nullable = false, length = 4000)
    String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_type", nullable = false, length = 20)
    ActivityType activityType;

    @Column(name = "open_at")
    LocalDateTime openAt;

    @Column(name = "due_at", nullable = false)
    LocalDateTime dueAt;

    @Column(name = "max_score", precision = 5, scale = 2)
    @Builder.Default
    BigDecimal maxScore = BigDecimal.TEN;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    ActivityWorkflowStatus status = ActivityWorkflowStatus.DRAFT;
}
