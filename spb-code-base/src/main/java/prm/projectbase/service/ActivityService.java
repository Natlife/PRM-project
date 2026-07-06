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
    private final NotificationService notificationService;

    public ActivityDetailResponse createActivity(Long classroomId, ActivityCreateRequest request) {
        log.info("Teacher creating activity in classroom {}", classroomId);

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (request.getOpenAt() != null && request.getOpenAt().isAfter(request.getDueAt())) {
            throw new AppException(ErrorCode.INVALID_ACTIVITY_DATES);
        }

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

    public ActivityDetailResponse updateActivity(Long activityId, ActivityUpdateRequest request) {
        log.info("Updating activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        ActivityWorkflowStatus oldStatus = activity.getStatus();
        
        User currentUser = userService.getCurrentUser();
        if (!activity.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (activity.getStatus() == ActivityWorkflowStatus.CLOSED) {
            throw new AppException(ErrorCode.ACTIVITY_ALREADY_CLOSED);
        }

        LocalDateTime newDueAt = request.getDueAt() != null ? request.getDueAt() : activity.getDueAt();
        LocalDateTime newOpenAt = request.getOpenAt() != null ? request.getOpenAt() : activity.getOpenAt();
        
        if (newOpenAt != null && newOpenAt.isAfter(newDueAt)) {
            throw new AppException(ErrorCode.INVALID_ACTIVITY_DATES);
        }

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
        
        if (updated.getStatus() == ActivityWorkflowStatus.PUBLISHED && oldStatus != ActivityWorkflowStatus.PUBLISHED) {
            notificationService.sendNotificationToAllEnrolled(
                    updated.getClassroom(),
                    "New Activity Assigned",
                    "A new activity '" + updated.getTitle() + "' has been assigned in class " + updated.getClassroom().getName(),
                    prm.projectbase.entity.enums.NotificationType.ACTIVITY_ASSIGNED,
                    "Activity",
                    updated.getId()
            );
        }
        
        return toDetailResponse(updated);
    }

    @Transactional(readOnly = true)
    public List<ActivityListResponse> getClassroomActivitiesForTeacher(Long classroomId) {
        log.info("Fetching activities for classroom {} (teacher view)", classroomId);

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        List<LearningActivity> activities = activityRepository.findByClassroomIdOrderByDueAtAsc(classroomId);
        return activities.stream()
                .map(activity -> {
                    try {
                        return toListResponse(activity);
                    } catch (Exception ex) {
                        log.error("Failed to map teacher activity {} in classroom {}", activity.getId(), classroomId, ex);
                        return null;
                    }
                })
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ActivityListResponse> getClassroomActivitiesForStudent(Long classroomId) {
        log.info("Fetching published activities for classroom {} (student view)", classroomId);

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
                .map(activity -> {
                    try {
                        return toListResponse(activity);
                    } catch (Exception ex) {
                        log.error("Failed to map student activity {} in classroom {}", activity.getId(), classroomId, ex);
                        return null;
                    }
                })
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ActivityDetailResponse getActivityDetail(Long activityId) {
        log.info("Fetching activity detail {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));

        if (activity.getStatus() == ActivityWorkflowStatus.DRAFT) {
            User currentUser = userService.getCurrentUser();
            if (!activity.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }
        
        return toDetailResponse(activity);
    }

    public boolean isActivityEditableForSubmission(LearningActivity activity) {
        LocalDateTime now = LocalDateTime.now();
        return activity.getStatus() != ActivityWorkflowStatus.CLOSED
                && now.isBefore(activity.getDueAt());
    }

    public boolean isActivityOpenForStudent(LearningActivity activity) {
        LocalDateTime now = LocalDateTime.now();
        boolean isAfterOpen = activity.getOpenAt() == null || now.isAfter(activity.getOpenAt());
        boolean isBeforeDue = now.isBefore(activity.getDueAt());
        return isAfterOpen && isBeforeDue;
    }

    private ActivityDetailResponse toDetailResponse(LearningActivity activity) {
        return ActivityDetailResponse.builder()
                .id(activity.getId())
                .classroomId(activity.getClassroom().getId())
                .title(activity.getTitle())
                .description(activity.getDescription())
                .activityType(activity.getActivityType() != null ? activity.getActivityType().toApiValue() : null)
                .openAt(activity.getOpenAt())
                .dueAt(activity.getDueAt())
                .maxScore(activity.getMaxScore())
                .status(activity.getStatus() != null ? activity.getStatus().name() : null)
                .createdAt(activity.getCreatedAt())
                .updatedAt(activity.getUpdatedAt())
                .build();
    }
    
    private ActivityListResponse toListResponse(LearningActivity activity) {
        return ActivityListResponse.builder()
                .id(activity.getId())
                .title(activity.getTitle())
                .description(activity.getDescription())
                .activityType(activity.getActivityType() != null ? activity.getActivityType().toApiValue() : null)
                .dueAt(activity.getDueAt())
                .maxScore(activity.getMaxScore())
                .status(activity.getStatus() != null ? activity.getStatus().name() : null)
                .build();
    }
}
