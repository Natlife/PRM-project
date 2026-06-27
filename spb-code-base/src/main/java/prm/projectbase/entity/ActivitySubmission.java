package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.SubmissionWorkflowStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "activity_submissions",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_activity_student_submission", columnNames = {"activity_id", "student_id"})
        },
        indexes = {
                @Index(name = "idx_activity_submissions_activity_id", columnList = "activity_id"),
                @Index(name = "idx_activity_submissions_student_id", columnList = "student_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ActivitySubmission extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "activity_id", nullable = false)
    LearningActivity activity;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    User student;

    @Column(name = "submitted_at")
    LocalDateTime submittedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    SubmissionWorkflowStatus status = SubmissionWorkflowStatus.NOT_SUBMITTED;

    @Column(precision = 5, scale = 2)
    BigDecimal score;

    @Column(name = "teacher_feedback", length = 4000)
    String teacherFeedback;
}
