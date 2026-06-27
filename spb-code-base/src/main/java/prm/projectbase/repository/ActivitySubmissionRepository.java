package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.ActivitySubmission;

import java.util.List;
import java.util.Optional;

public interface ActivitySubmissionRepository extends JpaRepository<ActivitySubmission, Integer> {
    List<ActivitySubmission> findByActivityId(Integer activityId);
    Optional<ActivitySubmission> findByActivityIdAndStudentId(Integer activityId, Integer studentId);
}
