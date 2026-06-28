package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.LearningActivity;
import prm.projectbase.entity.enums.ActivityWorkflowStatus;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface LearningActivityRepository extends JpaRepository<LearningActivity, Long> {

    List<LearningActivity> findByClassroomIdOrderByDueAtAsc(Long classroomId);

    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.status = :status ORDER BY a.dueAt ASC")
    List<LearningActivity> findByClassroomAndStatus(@Param("classroomId") Long classroomId, @Param("status") ActivityWorkflowStatus status);

    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.status != 'DRAFT' ORDER BY a.dueAt ASC")
    List<LearningActivity> findPublishedInClassroom(@Param("classroomId") Long classroomId);

    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.dueAt >= :afterDate ORDER BY a.dueAt ASC")
    List<LearningActivity> findUpcomingActivities(@Param("classroomId") Long classroomId, @Param("afterDate") LocalDateTime afterDate);

    @Query("SELECT CASE WHEN COUNT(a) > 0 THEN TRUE ELSE FALSE END FROM LearningActivity a WHERE a.id = :activityId AND a.classroom.id = :classroomId")
    boolean activityBelongsToClassroom(@Param("activityId") Long activityId, @Param("classroomId") Long classroomId);

    Long countByClassroomId(Long classroomId);
}
