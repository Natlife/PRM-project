package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.ActivitySubmission;
import prm.projectbase.entity.LearningActivity;
import prm.projectbase.entity.User;
import prm.projectbase.entity.enums.SubmissionWorkflowStatus;

import java.util.List;
import java.util.Optional;

@Repository
public interface ActivitySubmissionRepository extends JpaRepository<ActivitySubmission, Long> {
    
    /**
     * Find all submissions for an activity
     */
    List<ActivitySubmission> findByActivityId(Long activityId);
    
    /**
     * Find submissions for an activity with specific status
     */
    @Query("SELECT s FROM ActivitySubmission s WHERE s.activity.id = :activityId AND s.status = :status ORDER BY s.submittedAt DESC")
    List<ActivitySubmission> findByActivityAndStatus(@Param("activityId") Long activityId, @Param("status") SubmissionWorkflowStatus status);
    
    /**
     * Find a student's submission for an activity
     */
    Optional<ActivitySubmission> findByActivityIdAndStudentId(Long activityId, Long studentId);
    
    /**
     * Find all submissions by a student in a classroom (for current enrollment check)
     */
    @Query("SELECT s FROM ActivitySubmission s WHERE s.student.id = :studentId AND s.activity.classroom.id = :classroomId")
    List<ActivitySubmission> findByStudentInClassroom(@Param("studentId") Long studentId, @Param("classroomId") Long classroomId);
    
    /**
     * Count submissions for an activity
     */
    Long countByActivityId(Long activityId);
    
    /**
     * Count submitted (graded) submissions for an activity
     */
    @Query("SELECT COUNT(s) FROM ActivitySubmission s WHERE s.activity.id = :activityId AND s.status = 'GRADED'")
    Long countGradedSubmissions(@Param("activityId") Long activityId);
    
    /**
     * Find ungraded submissions (submitted but not graded)
     */
    @Query("SELECT s FROM ActivitySubmission s WHERE s.activity.id = :activityId AND s.status IN ('SUBMITTED', 'LATE_SUBMITTED') ORDER BY s.submittedAt ASC")
    List<ActivitySubmission> findUngradedSubmissions(@Param("activityId") Long activityId);
    
    /**
     * Check if submission belongs to activity
     */
    @Query("SELECT CASE WHEN COUNT(s) > 0 THEN TRUE ELSE FALSE END FROM ActivitySubmission s WHERE s.id = :submissionId AND s.activity.id = :activityId")
    boolean submissionBelongsToActivity(@Param("submissionId") Long submissionId, @Param("activityId") Long activityId);
}
