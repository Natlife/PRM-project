package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.SubmissionAttachment;

import java.util.List;

@Repository
public interface SubmissionAttachmentRepository extends JpaRepository<SubmissionAttachment, Long> {
    
    /**
     * Find all attachments for a submission
     */
    List<SubmissionAttachment> findBySubmissionId(Long submissionId);
    
    /**
     * Count attachments for a submission
     */
    Long countBySubmissionId(Long submissionId);
    
    /**
     * Check if attachment belongs to submission
     */
    @Query("SELECT CASE WHEN COUNT(a) > 0 THEN TRUE ELSE FALSE END FROM SubmissionAttachment a WHERE a.id = :attachmentId AND a.submission.id = :submissionId")
    boolean attachmentBelongsToSubmission(@Param("attachmentId") Long attachmentId, @Param("submissionId") Long submissionId);
    
    /**
     * Delete all attachments for a submission (used on submission reset)
     */
    Long deleteBySubmissionId(Long submissionId);
}
