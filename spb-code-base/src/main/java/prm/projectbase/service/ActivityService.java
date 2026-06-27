package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.request.ActivityCreateRequest;
import prm.projectbase.dto.request.ActivityUpdateRequest;
import prm.projectbase.dto.response.ActivityDetailResponse;
import prm.projectbase.dto.response.ActivityListResponse;
import prm.projectbase.dto.response.ClassroomScheduleResponse;
import prm.projectbase.entity.Classroom;
import prm.projectbase.entity.LearningActivity;
import prm.projectbase.entity.User;
import prm.projectbase.entity.enums.ActivityWorkflowStatus;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.ClassroomRepository;
import prm.projectbase.repository.LearningActivityRepository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ActivityService {
    
    private final LearningActivityRepository activityRepository;
    private final ClassroomRepository classroomRepository;
    private final UserService userService;
    
    /**
     * Teacher creates a learning activity in a classroom
     * @param classroomId the classroom
     * @param request the activity creation request
     * @return the created activity
     */
    public ActivityDetailResponse createActivity(Long classroomId, ActivityCreateRequest request) {
        log.info("Teacher creating activity in classroom {}", classroomId);
        
        // Verify classroom exists and teacher owns it
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        // Validate request
        if (request.getOpenAt() != null && request.getOpenAt().isAfter(request.getDueAt())) {
            throw new AppException(ErrorCode.INVALID_ACTIVITY_DATES);
        }
        
        // Create activity entity
        LearningActivity activity = LearningActivity.builder()
                .classroom(classroom)
                .title(request.getTitle())
                .description(request.getDescription())
                .activityType(request.getActivityType())
                .openAt(request.getOpenAt())
                .dueAt(request.getDueAt())
                .maxScore(request.getMaxScore() != null ? request.getMaxScore() : BigDecimal.TEN)
                .status(ActivityWorkflowStatus.DRAFT)
                .build();
        
        LearningActivity saved = activityRepository.save(activity);
        log.info("Activity saved with id {}", saved.getId());
        
        return toDetailResponse(saved);
    }
    
    /**
     * Teacher updates an activity
     * @param activityId the activity to update
     * @param request the update request
     * @return the updated activity
     */
    public ActivityDetailResponse updateActivity(Long activityId, ActivityUpdateRequest request) {
        log.info("Updating activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!activity.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        // Can only update DRAFT or PUBLISHED activities
        if (activity.getStatus() == ActivityWorkflowStatus.CLOSED) {
            throw new AppException(ErrorCode.ACTIVITY_ALREADY_CLOSED);
        }
        
        // Validate dates if provided
        LocalDateTime newDueAt = request.getDueAt() != null ? request.getDueAt() : activity.getDueAt();
        LocalDateTime newOpenAt = request.getOpenAt() != null ? request.getOpenAt() : activity.getOpenAt();
        
        if (newOpenAt != null && newOpenAt.isAfter(newDueAt)) {
            throw new AppException(ErrorCode.INVALID_ACTIVITY_DATES);
        }
        
        // Update fields
        if (request.getTitle() != null) {
            activity.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            activity.setDescription(request.getDescription());
        }
        if (request.getDueAt() != null) {
            activity.setDueAt(request.getDueAt());
        }
        if (request.getOpenAt() != null) {
            activity.setOpenAt(request.getOpenAt());
        }
        if (request.getMaxScore() != null) {
            activity.setMaxScore(request.getMaxScore());
        }
        if (request.getStatus() != null) {
            activity.setStatus(request.getStatus());
        }
        
        LearningActivity updated = activityRepository.save(activity);
        log.info("Activity {} updated", activityId);
        
        return toDetailResponse(updated);
    }
    
    /**
     * Get all activities in a classroom for teacher
     * @param classroomId the classroom
     * @return list of activities
     */
    @Transactional(readOnly = true)
    public List<ActivityListResponse> getClassroomActivitiesForTeacher(Long classroomId) {
        log.info("Fetching activities for classroom {} (teacher view)", classroomId);
        
        // Verify classroom exists and teacher owns it
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        List<LearningActivity> activities = activityRepository.findByClassroomIdOrderByDueAtAsc(classroomId);
        
        return activities.stream()
                .map(this::toListResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Get published activities in a classroom for student
     * @param classroomId the classroom
     * @return list of published activities
     */
    @Transactional(readOnly = true)
    public List<ActivityListResponse> getClassroomActivitiesForStudent(Long classroomId) {
        log.info("Fetching published activities for classroom {} (student view)", classroomId);
        
        // Verify classroom exists and student is enrolled
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        boolean isEnrolled = classroom.getEnrollments().stream()
                .anyMatch(e -> e.getStudent().getId().equals(currentUser.getId()));
        
        if (!isEnrolled) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        List<LearningActivity> activities = activityRepository.findPublishedInClassroom(classroomId);
        
        return activities.stream()
                .map(this::toListResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Get activity detail
     * @param activityId the activity
     * @return activity detail
     */
    @Transactional(readOnly = true)
    public ActivityDetailResponse getActivityDetail(Long activityId) {
        log.info("Fetching activity detail {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        // If draft, only teacher can view
        if (activity.getStatus() == ActivityWorkflowStatus.DRAFT) {
            User currentUser = userService.getCurrentUser();
            if (!activity.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }
        
        return toDetailResponse(activity);
    }
    
    /**
     * Check if an activity is editable by student (not closed and not past due)
     * @param activity the activity
     * @return true if editable
     */
    public boolean isActivityEditableForSubmission(LearningActivity activity) {
        LocalDateTime now = LocalDateTime.now();
        return activity.getStatus() != ActivityWorkflowStatus.CLOSED
                && now.isBefore(activity.getDueAt());
    }
    
    /**
     * Check if activity is open for student submission
     * @param activity the activity
     * @return true if open
     */
    public boolean isActivityOpenForStudent(LearningActivity activity) {
        LocalDateTime now = LocalDateTime.now();
        boolean isAfterOpen = activity.getOpenAt() == null || now.isAfter(activity.getOpenAt());
        boolean isBeforeDue = now.isBefore(activity.getDueAt());
        return isAfterOpen && isBeforeDue;
    }
    
    // DTO Conversion Methods
    
    private ActivityDetailResponse toDetailResponse(LearningActivity activity) {
        return ActivityDetailResponse.builder()
                .id(activity.getId())
                .classroomId(activity.getClassroom().getId())
                .title(activity.getTitle())
                .description(activity.getDescription())
                .activityType(activity.getActivityType().name())
                .openAt(activity.getOpenAt())
                .dueAt(activity.getDueAt())
                .maxScore(activity.getMaxScore())
                .status(activity.getStatus().name())
                .createdAt(activity.getCreatedAt())
                .updatedAt(activity.getUpdatedAt())
                .build();
    }
    
    private ActivityListResponse toListResponse(LearningActivity activity) {
        return ActivityListResponse.builder()
                .id(activity.getId())
                .title(activity.getTitle())
                .description(activity.getDescription())
                .activityType(activity.getActivityType().name())
                .dueAt(activity.getDueAt())
                .maxScore(activity.getMaxScore())
                .status(activity.getStatus().name())
                .build();
    }
}
