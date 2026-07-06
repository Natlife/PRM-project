package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.PeerReview;

import java.util.List;
import java.util.Optional;

public interface PeerReviewRepository extends JpaRepository<PeerReview, Long> {
    List<PeerReview> findByClassroomIdAndReviewerStudentId(Long classroomId, Long reviewerStudentId);
    Optional<PeerReview> findByReviewerStudentIdAndReviewedGroupId(Long reviewerStudentId, Long reviewedGroupId);
}
