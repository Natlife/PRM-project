package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.SubmissionComment;
import prm.projectbase.entity.enums.CommentScope;

import java.util.List;

@Repository
public interface SubmissionCommentRepository extends JpaRepository<SubmissionComment, Long> {

    @Query("SELECT c FROM SubmissionComment c WHERE c.submission.id = :submissionId ORDER BY c.createdAt ASC")
    List<SubmissionComment> findBySubmissionIdOrderByCreatedAt(@Param("submissionId") Long submissionId);

    @Query("SELECT c FROM SubmissionComment c WHERE c.submission.id = :submissionId AND c.commentScope = :scope ORDER BY c.createdAt ASC")
    List<SubmissionComment> findBySubmissionAndScope(@Param("submissionId") Long submissionId, @Param("scope") CommentScope scope);

    Long countBySubmissionId(Long submissionId);

    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN TRUE ELSE FALSE END FROM SubmissionComment c WHERE c.id = :commentId AND c.submission.id = :submissionId")
    boolean commentBelongsToSubmission(@Param("commentId") Long commentId, @Param("submissionId") Long submissionId);
}
