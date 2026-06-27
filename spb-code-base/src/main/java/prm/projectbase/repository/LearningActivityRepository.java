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
    
    /**
     * Find all activities in a classroom ordered by due date
     */
    List<LearningActivity> findByClassroomIdOrderByDueAtAsc(Long classroomId);
    
    /**
     * Find activities in a classroom by status
     */
    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.status = :status ORDER BY a.dueAt ASC")
    List<LearningActivity> findByClassroomAndStatus(@Param("classroomId") Long classroomId, @Param("status") ActivityWorkflowStatus status);
    
    /**
     * Find published activities (not draft) in a classroom
     */
    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.status != 'DRAFT' ORDER BY a.dueAt ASC")
    List<LearningActivity> findPublishedInClassroom(@Param("classroomId") Long classroomId);
    
    /**
     * Find activities due after a certain date
     */
    @Query("SELECT a FROM LearningActivity a WHERE a.classroom.id = :classroomId AND a.dueAt >= :afterDate ORDER BY a.dueAt ASC")
    List<LearningActivity> findUpcomingActivities(@Param("classroomId") Long classroomId, @Param("afterDate") LocalDateTime afterDate);
    
    /**
     * Check if activity belongs to classroom
     */
    @Query("SELECT CASE WHEN COUNT(a) > 0 THEN TRUE ELSE FALSE END FROM LearningActivity a WHERE a.id = :activityId AND a.classroom.id = :classroomId")
    boolean activityBelongsToClassroom(@Param("activityId") Long activityId, @Param("classroomId") Long classroomId);
    
    /**
     * Count activities in classroom
     */
    Long countByClassroomId(Long classroomId);
}
