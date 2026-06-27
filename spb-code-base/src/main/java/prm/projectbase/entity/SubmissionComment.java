package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.CommentScope;

@Entity
@Table(name = "submission_comments", indexes = {
        @Index(name = "idx_submission_comments_submission_id", columnList = "submission_id"),
        @Index(name = "idx_submission_comments_author_id", columnList = "author_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class SubmissionComment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    ActivitySubmission submission;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_id", nullable = false)
    User author;

    @Column(nullable = false, length = 2000)
    String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "comment_scope", nullable = false, length = 20)
    @Builder.Default
    CommentScope commentScope = CommentScope.SHARED;
}
