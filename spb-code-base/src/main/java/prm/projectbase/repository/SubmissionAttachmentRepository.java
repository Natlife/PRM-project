package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.SubmissionAttachment;

import java.util.List;

@Repository
public interface SubmissionAttachmentRepository extends JpaRepository<SubmissionAttachment, Long> {

    List<SubmissionAttachment> findBySubmissionId(Long submissionId);

    Long countBySubmissionId(Long submissionId);

    @Query("SELECT CASE WHEN COUNT(a) > 0 THEN TRUE ELSE FALSE END FROM SubmissionAttachment a WHERE a.id = :attachmentId AND a.submission.id = :submissionId")
    boolean attachmentBelongsToSubmission(@Param("attachmentId") Long attachmentId, @Param("submissionId") Long submissionId);

    Long deleteBySubmissionId(Long submissionId);
}
