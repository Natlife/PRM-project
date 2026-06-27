package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.LearningActivity;

import java.util.List;

public interface LearningActivityRepository extends JpaRepository<LearningActivity, Integer> {
    List<LearningActivity> findByClassroomIdOrderByDueAtAsc(Integer classroomId);
}
