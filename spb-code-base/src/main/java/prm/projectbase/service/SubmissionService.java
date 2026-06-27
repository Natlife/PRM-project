package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.SubmissionUpdateRequest;
import prm.projectbase.dto.request.GradeSubmissionRequest;
import prm.projectbase.dto.request.SubmissionCommentRequest;
import prm.projectbase.dto.response.SubmissionDetailResponse;
import prm.projectbase.dto.response.SubmissionListResponse;
import prm.projectbase.dto.response.SubmissionCommentResponse;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.SubmissionWorkflowStatus;
import prm.projectbase.entity.enums.CommentScope;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class SubmissionService {
    
    private final ActivitySubmissionRepository submissionRepository;
    private final LearningActivityRepository activityRepository;
    private final ClassroomRepository classroomRepository;
    private final SubmissionAttachmentRepository attachmentRepository;
    private final SubmissionCommentRepository commentRepository;
    private final UserService userService;
    private final FileService fileService;
    private final ActivityService activityService;
    private final NotificationService notificationService;
    
    /**
     * Student creates or updates their submission for an activity
     * @param activityId the activity
     * @param request the submission content and files
     * @return the submission detail
     */
    public SubmissionDetailResponse submitActivity(Long activityId, SubmissionUpdateRequest request) {
        log.info("Student submitting activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        User student = userService.getCurrentUser();
        
        // Verify student is enrolled in classroom
        boolean isEnrolled = activity.getClassroom().getEnrollments().stream()
                .anyMatch(e -> e.getStudent().getId().equals(student.getId()));
        if (!isEnrolled) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        // Get or create submission
        ActivitySubmission submission = submissionRepository
                .findByActivityIdAndStudentId(activityId, student.getId())
                .orElse(null);
        
        if (submission == null) {
            // Create new submission
            submission = ActivitySubmission.builder()
                    .activity(activity)
                    .student(student)
                    .status(SubmissionWorkflowStatus.DRAFT)
                    .build();
        }
        
        // Check if student can still edit (activity open and submission not locked)
        LocalDateTime now = LocalDateTime.now();
        boolean isAfterOpen = activity.getOpenAt() == null || now.isAfter(activity.getOpenAt());
        
        if (!isAfterOpen) {
            throw new AppException(ErrorCode.ACTIVITY_NOT_YET_OPEN);
        }
        
        if (!isAfterOpen && submission.getStatus() == SubmissionWorkflowStatus.GRADED) {
            throw new AppException(ErrorCode.SUBMISSION_LOCKED);
        }
        
        // Update submission content
        submission.setStatus(SubmissionWorkflowStatus.DRAFT);
        
        ActivitySubmission saved = submissionRepository.save(submission);
        log.info("Submission {} saved", saved.getId());
        
        // Handle file attachments if provided
        if (request.getAttachmentFiles() != null && !request.getAttachmentFiles().isEmpty()) {
            // Remove old attachments
            attachmentRepository.deleteBySubmissionId(saved.getId());
            
            // Store new attachments
            for (MultipartFile file : request.getAttachmentFiles()) {
                FileService.StorageResult storageResult = fileService.storeFile(
                        file,
                        "submissions/" + saved.getId()
                );
                
                SubmissionAttachment attachment = SubmissionAttachment.builder()
                        .submission(saved)
                        .storageKey(storageResult.getStorageKey())
                        .originalFileName(storageResult.getOriginalFileName())
                        .contentType(storageResult.getContentType())
                        .sizeBytes(storageResult.getSizeBytes())
                        .build();
                
                attachmentRepository.save(attachment);
            }
        }
        
        return toDetailResponse(saved);
    }
    
    /**
     * Student finalizes their submission (marks as submitted)
     * @param activityId the activity
     * @return the submission detail
     */
    public SubmissionDetailResponse finalizeSubmission(Long activityId) {
        log.info("Student finalizing submission for activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        User student = userService.getCurrentUser();
        
        ActivitySubmission submission = submissionRepository
                .findByActivityIdAndStudentId(activityId, student.getId())
                .orElseThrow(() -> new AppException(ErrorCode.SUBMISSION_NOT_FOUND));
        
        LocalDateTime now = LocalDateTime.now();
        
        // Determine if submission is late
        boolean isLate = now.isAfter(activity.getDueAt());
        
        submission.setSubmittedAt(now);
        submission.setStatus(isLate ? SubmissionWorkflowStatus.LATE_SUBMITTED : SubmissionWorkflowStatus.SUBMITTED);
        
        ActivitySubmission saved = submissionRepository.save(submission);
        log.info("Submission {} finalized as {}", saved.getId(), saved.getStatus());
        
        return toDetailResponse(saved);
    }
    
    /**
     * Student gets their submission for an activity
     * @param activityId the activity
     * @return the submission detail
     */
    @Transactional(readOnly = true)
    public SubmissionDetailResponse getStudentSubmission(Long activityId) {
        log.info("Fetching student submission for activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        User student = userService.getCurrentUser();
        
        ActivitySubmission submission = submissionRepository
                .findByActivityIdAndStudentId(activityId, student.getId())
                .orElse(null);
        
        if (submission == null) {
            // Create draft submission for response
            submission = ActivitySubmission.builder()
                    .activity(activity)
                    .student(student)
                    .status(SubmissionWorkflowStatus.NOT_SUBMITTED)
                    .build();
        }
        
        return toDetailResponse(submission);
    }
    
    /**
     * Teacher gets all submissions for an activity
     * @param activityId the activity
     * @return list of submissions
     */
    @Transactional(readOnly = true)
    public List<SubmissionListResponse> getActivitySubmissions(Long activityId) {
        log.info("Fetching all submissions for activity {}", activityId);
        
        LearningActivity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new AppException(ErrorCode.ACTIVITY_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!activity.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        List<ActivitySubmission> submissions = submissionRepository.findByActivityId(activityId);
        
        return submissions.stream()
                .map(this::toListResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Teacher gets a specific submission
     * @param submissionId the submission
     * @return submission detail
     */
    @Transactional(readOnly = true)
    public SubmissionDetailResponse getSubmission(Long submissionId) {
        log.info("Fetching submission {}", submissionId);
        
        ActivitySubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new AppException(ErrorCode.SUBMISSION_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!submission.getActivity().getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        return toDetailResponse(submission);
    }
    
    /**
     * Teacher grades a submission
     * @param submissionId the submission to grade
     * @param request grade and feedback
     * @return updated submission
     */
    public SubmissionDetailResponse gradeSubmission(Long submissionId, GradeSubmissionRequest request) {
        log.info("Grading submission {}", submissionId);
        
        ActivitySubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new AppException(ErrorCode.SUBMISSION_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!submission.getActivity().getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        // Validate score
        BigDecimal maxScore = submission.getActivity().getMaxScore();
        if (request.getScore().compareTo(BigDecimal.ZERO) < 0 
                || request.getScore().compareTo(maxScore) > 0) {
            throw new AppException(ErrorCode.INVALID_SCORE);
        }
        
        submission.setScore(request.getScore());
        submission.setTeacherFeedback(request.getFeedback());
        submission.setStatus(SubmissionWorkflowStatus.GRADED);
        
        ActivitySubmission saved = submissionRepository.save(submission);
        log.info("Submission {} graded with score {}", submissionId, request.getScore());
        
        notificationService.createNotification(
                saved.getStudent(),
                "Activity Graded",
                "Your submission for activity '" + saved.getActivity().getTitle() + "' has been graded. Score: " + request.getScore(),
                prm.projectbase.entity.enums.NotificationType.ACTIVITY_GRADED,
                "Submission",
                saved.getId()
        );
        
        return toDetailResponse(saved);
    }
    
    /**
     * Add a comment to a submission (teacher or student)
     * @param submissionId the submission
     * @param request comment content and scope
     * @return comment response
     */
    public SubmissionCommentResponse addComment(Long submissionId, SubmissionCommentRequest request) {
        log.info("Adding comment to submission {}", submissionId);
        
        ActivitySubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new AppException(ErrorCode.SUBMISSION_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        
        // Verify user is either teacher or student owner
        boolean isTeacher = submission.getActivity().getClassroom().getTeacher().getId().equals(currentUser.getId());
        boolean isStudentOwner = submission.getStudent().getId().equals(currentUser.getId());
        
        if (!isTeacher && !isStudentOwner) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        SubmissionComment comment = SubmissionComment.builder()
                .submission(submission)
                .author(currentUser)
                .content(request.getContent())
                .commentScope(request.getScope())
                .build();
        
        SubmissionComment saved = commentRepository.save(comment);
        log.info("Comment {} added to submission {}", saved.getId(), submissionId);
        
        return toCommentResponse(saved);
    }
    
    /**
     * Get all comments for a submission
     * @param submissionId the submission
     * @return list of comments visible to current user
     */
    @Transactional(readOnly = true)
    public List<SubmissionCommentResponse> getSubmissionComments(Long submissionId) {
        log.info("Fetching comments for submission {}", submissionId);
        
        ActivitySubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new AppException(ErrorCode.SUBMISSION_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        
        boolean isTeacher = submission.getActivity().getClassroom().getTeacher().getId().equals(currentUser.getId());
        boolean isStudentOwner = submission.getStudent().getId().equals(currentUser.getId());
        
        if (!isTeacher && !isStudentOwner) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        
        List<SubmissionComment> comments = commentRepository.findBySubmissionIdOrderByCreatedAt(submissionId);
        
        // Filter based on visibility (teachers see all, students see only PUBLIC)
        return comments.stream()
                .filter(c -> isTeacher || c.getCommentScope() == CommentScope.PUBLIC)
                .map(this::toCommentResponse)
                .collect(Collectors.toList());
    }
    
    // DTO Conversion Methods
    
    private SubmissionDetailResponse toDetailResponse(ActivitySubmission submission) {
        List<SubmissionAttachment> attachments = attachmentRepository.findBySubmissionId(submission.getId());
        
        return SubmissionDetailResponse.builder()
                .id(submission.getId())
                .activityId(submission.getActivity().getId())
                .studentId(submission.getStudent().getId())
                .studentName(submission.getStudent().getFullName())
                .submittedAt(submission.getSubmittedAt())
                .status(submission.getStatus().name())
                .score(submission.getScore())
                .teacherFeedback(submission.getTeacherFeedback())
                .attachmentCount((long) attachments.size())
                .commentCount(commentRepository.countBySubmissionId(submission.getId()))
                .createdAt(submission.getCreatedAt())
                .updatedAt(submission.getUpdatedAt())
                .build();
    }
    
    private SubmissionListResponse toListResponse(ActivitySubmission submission) {
        return SubmissionListResponse.builder()
                .id(submission.getId())
                .studentId(submission.getStudent().getId())
                .studentName(submission.getStudent().getFullName())
                .status(submission.getStatus().name())
                .submittedAt(submission.getSubmittedAt())
                .score(submission.getScore())
                .build();
    }
    
    private SubmissionCommentResponse toCommentResponse(SubmissionComment comment) {
        return SubmissionCommentResponse.builder()
                .id(comment.getId())
                .authorId(comment.getAuthor().getId())
                .authorName(comment.getAuthor().getFullName())
                .content(comment.getContent())
                .scope(comment.getCommentScope().name())
                .createdAt(comment.getCreatedAt())
                .build();
    }
}
