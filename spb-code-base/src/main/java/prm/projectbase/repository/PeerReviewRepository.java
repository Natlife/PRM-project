package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.PeerReview;

import java.util.List;
import java.util.Optional;

public interface PeerReviewRepository extends JpaRepository<PeerReview, Integer> {
    List<PeerReview> findByClassroomIdAndReviewerStudentId(Integer classroomId, Integer reviewerStudentId);
    Optional<PeerReview> findByReviewerStudentIdAndReviewedGroupId(Integer reviewerStudentId, Integer reviewedGroupId);
}
