package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ReviewWorkflowStatus;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "peer_reviews",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_peer_review_reviewer_target", columnNames = {"reviewer_student_id", "reviewed_group_id"})
        },
        indexes = {
                @Index(name = "idx_peer_reviews_classroom_id", columnList = "classroom_id"),
                @Index(name = "idx_peer_reviews_reviewer_student_id", columnList = "reviewer_student_id"),
                @Index(name = "idx_peer_reviews_reviewed_group_id", columnList = "reviewed_group_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class PeerReview extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reviewer_student_id", nullable = false)
    User reviewerStudent;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reviewed_group_id", nullable = false)
    ProjectGroup reviewedGroup;

    @Column(name = "code_quality_score")
    Integer codeQualityScore;

    @Column(name = "ui_ux_score")
    Integer uiUxScore;

    @Column(name = "feature_score")
    Integer featureScore;

    @Column(name = "presentation_score")
    Integer presentationScore;

    @Column(length = 3000)
    String comment;

    @Column(name = "submitted_at")
    LocalDateTime submittedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    ReviewWorkflowStatus status = ReviewWorkflowStatus.DRAFT;
}
