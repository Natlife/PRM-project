package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.request.PeerReviewRequest;
import prm.projectbase.dto.response.PeerReviewResponse;
import prm.projectbase.dto.response.ProjectGroupListResponse;
import prm.projectbase.dto.response.UserResponse;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.entity.enums.ReviewWorkflowStatus;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class PeerReviewService {

    private final PeerReviewRepository peerReviewRepository;
    private final ProjectGroupRepository groupRepository;
    private final ProjectMemberRepository memberRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final ClassroomRepository classroomRepository;
    private final UserService userService;
    private final NotificationService notificationService;

    @Transactional(readOnly = true)
    public List<ProjectGroupListResponse> getPeerReviewTargets(Long classroomId) {
        log.info("Fetching peer review targets for classroom {}", classroomId);

        User currentStudent = userService.getCurrentUser();

        Optional<ClassroomEnrollment> enrollment = enrollmentRepository
                .findByClassroomIdAndStudentId(classroomId, currentStudent.getId());
        if (enrollment.isEmpty() || enrollment.get().getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        Optional<ProjectMember> ownMember = memberRepository
                .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(currentStudent.getId(), classroomId);
        Long ownGroupId = ownMember.map(m -> m.getProjectGroup().getId()).orElse(null);

        List<ProjectGroup> allGroups = groupRepository.findByClassroomId(classroomId);

        return allGroups.stream()
                .filter(g -> ownGroupId == null || !g.getId().equals(ownGroupId))
                .map(g -> {
                    List<ProjectMember> members = memberRepository.findByProjectGroupId(g.getId());
                    return toListResponse(g, members.size());
                })
                .collect(Collectors.toList());
    }

    public PeerReviewResponse createOrUpdatePeerReview(PeerReviewRequest request) {
        log.info("Creating or updating peer review for group {}", request.getReviewedGroupId());

        User currentStudent = userService.getCurrentUser();

        ProjectGroup reviewedGroup = groupRepository.findById(request.getReviewedGroupId())
                .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));

        Long classroomId = reviewedGroup.getClassroom().getId();

        Optional<ClassroomEnrollment> enrollment = enrollmentRepository
                .findByClassroomIdAndStudentId(classroomId, currentStudent.getId());
        if (enrollment.isEmpty() || enrollment.get().getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
            throw new AppException(ErrorCode.REVIEWER_NOT_IN_CLASSROOM);
        }

        Optional<ProjectMember> ownMember = memberRepository
                .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(currentStudent.getId(), classroomId);
        if (ownMember.isPresent() && ownMember.get().getProjectGroup().getId().equals(request.getReviewedGroupId())) {
            throw new AppException(ErrorCode.CANNOT_REVIEW_OWN_GROUP);
        }

        Optional<PeerReview> existingReview = peerReviewRepository
                .findByReviewerStudentIdAndReviewedGroupId(currentStudent.getId(), request.getReviewedGroupId());

        PeerReview review;
        if (existingReview.isPresent()) {
            review = existingReview.get();
            if (review.getStatus() == ReviewWorkflowStatus.SUBMITTED) {
                throw new AppException(ErrorCode.PEER_REVIEW_ALREADY_SUBMITTED);
            }
        } else {
            review = PeerReview.builder()
                    .classroom(reviewedGroup.getClassroom())
                    .reviewerStudent(currentStudent)
                    .reviewedGroup(reviewedGroup)
                    .build();
        }

        review.setCodeQualityScore(request.getCodeQualityScore());
        review.setUiUxScore(request.getUiUxScore());
        review.setFeatureScore(request.getFeatureScore());
        review.setPresentationScore(request.getPresentationScore());
        review.setComment(request.getComment());
        review.setSubmittedAt(LocalDateTime.now());
        review.setStatus(ReviewWorkflowStatus.SUBMITTED);

        PeerReview saved = peerReviewRepository.save(review);

        if (saved.getReviewedGroup().getLeader() != null) {
            notificationService.createNotification(
                    saved.getReviewedGroup().getLeader(),
                    "Peer Review Submitted",
                    "Your project group '" + saved.getReviewedGroup().getGroupName() + "' received a new peer review from " + currentStudent.getFullName(),
                    prm.projectbase.entity.enums.NotificationType.PEER_REVIEW_SUBMITTED,
                    "PeerReview",
                    saved.getId()
            );
        }

        notificationService.createNotification(
                saved.getClassroom().getTeacher(),
                "Peer Review Submitted",
                "Group '" + saved.getReviewedGroup().getGroupName() + "' was reviewed by student " + currentStudent.getFullName(),
                prm.projectbase.entity.enums.NotificationType.PEER_REVIEW_SUBMITTED,
                "PeerReview",
                saved.getId()
        );

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<PeerReviewResponse> getStudentPeerReviewsMe(Long classroomId) {
        log.info("Fetching peer reviews made by current student in classroom {}", classroomId);

        User currentStudent = userService.getCurrentUser();

        List<PeerReview> reviews = peerReviewRepository
                .findByClassroomIdAndReviewerStudentId(classroomId, currentStudent.getId());

        return reviews.stream().map(this::toResponse).collect(Collectors.toList());
    }

    private PeerReviewResponse toResponse(PeerReview review) {
        return PeerReviewResponse.builder()
                .id(review.getId())
                .classroomId(review.getClassroom().getId())
                .reviewerStudentId(review.getReviewerStudent().getId())
                .reviewerStudentName(review.getReviewerStudent().getFullName())
                .reviewedGroupId(review.getReviewedGroup().getId())
                .reviewedGroupName(review.getReviewedGroup().getGroupName())
                .codeQualityScore(review.getCodeQualityScore())
                .uiUxScore(review.getUiUxScore())
                .featureScore(review.getFeatureScore())
                .presentationScore(review.getPresentationScore())
                .comment(review.getComment())
                .submittedAt(review.getSubmittedAt())
                .status(review.getStatus().name())
                .build();
    }

    private ProjectGroupListResponse toListResponse(ProjectGroup group, int memberCount) {
        UserResponse leaderResponse = null;
        if (group.getLeader() != null) {
            leaderResponse = UserResponse.builder()
                    .id(group.getLeader().getId())
                    .userName(group.getLeader().getUserName())
                    .email(group.getLeader().getEmail())
                    .fullName(group.getLeader().getFullName())
                    .phone(group.getLeader().getPhone())
                    .avatarUrl(group.getLeader().getAvatarUrl())
                    .institutionalId(group.getLeader().getInstitutionalId())
                    .active(group.getLeader().isActive())
                    .build();
        }

        return ProjectGroupListResponse.builder()
                .id(group.getId())
                .groupName(group.getGroupName())
                .projectName(group.getProjectName())
                .leader(leaderResponse)
                .status(group.getStatus().name())
                .memberCount(memberCount)
                .build();
    }
}
