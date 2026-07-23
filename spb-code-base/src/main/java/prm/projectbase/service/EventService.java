package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.EventAssignmentRequest;
import prm.projectbase.dto.request.EventCreateRequest;
import prm.projectbase.dto.request.EventQuestionRequest;
import prm.projectbase.dto.request.EventUpdateRequest;
import prm.projectbase.dto.response.*;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.*;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class EventService {

    private final EventRepository eventRepository;
    private final EventAssignmentRepository assignmentRepository;
    private final EventAssetRepository assetRepository;
    private final EventQuestionRepository questionRepository;
    private final ClassroomRepository classroomRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final ProjectGroupRepository groupRepository;
    private final ProjectMemberRepository memberRepository;
    private final UserRepository userRepository;
    private final UserService userService;
    private final FileService fileService;

    @Transactional(readOnly = true)
    public List<EventListResponse> getTeacherEvents() {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);

        List<Event> events = eventRepository.findByClassroomTeacherIdOrderByStartAtDesc(teacher.getId());
        List<Long> eventIds = events.stream().map(Event::getId).toList();
        Map<Long, List<EventAssignment>> assignmentsByEventId = eventIds.isEmpty()
                ? Collections.emptyMap()
                : assignmentRepository.findByEventIdIn(eventIds).stream()
                .collect(Collectors.groupingBy(a -> a.getEvent().getId()));
        Map<Long, Long> recordingCountByEventId = eventIds.isEmpty()
                ? Collections.emptyMap()
                : assetRepository.findByEventIdIn(eventIds).stream()
                .filter(asset -> asset.getAssetType() == EventAssetType.RECORDING)
                .collect(Collectors.groupingBy(asset -> asset.getEvent().getId(), Collectors.counting()));

        return events.stream()
                .map(event -> {
                    List<EventAssignment> assignments = assignmentsByEventId.getOrDefault(event.getId(), Collections.emptyList());
                    return EventListResponse.builder()
                            .id(event.getId())
                            .classroomId(event.getClassroom().getId())
                            .classroomCode(event.getClassroom().getCode())
                            .classroomName(event.getClassroom().getName())
                            .title(event.getTitle())
                            .description(event.getDescription())
                            .startAt(event.getStartAt())
                            .endAt(event.getEndAt())
                            .sessionDurationMinutes(event.getSessionDurationMinutes())
                            .status(event.getStatus().name())
                            .canJoinRoom(event.getStatus() == EventWorkflowStatus.LIVE)
                            .canWatchRecording(recordingCountByEventId.getOrDefault(event.getId(), 0L) > 0)
                            .assignmentCount(assignments.size())
                            .build();
                })
                .toList();
    }

    public EventDetailResponse createEvent(EventCreateRequest request) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);

        Classroom classroom = classroomRepository.findById(request.getClassroomId())
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        if (!classroom.getTeacher().getId().equals(teacher.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        validateEventDates(request.getStartAt(), request.getEndAt());

        Event event = eventRepository.save(Event.builder()
                .classroom(classroom)
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .startAt(request.getStartAt())
                .endAt(request.getEndAt())
                .sessionDurationMinutes(request.getSessionDurationMinutes())
                .status(EventWorkflowStatus.SCHEDULED)
                .build());

        return getTeacherEventDetail(event.getId());
    }

    @Transactional(readOnly = true)
    public EventDetailResponse getTeacherEventDetail(Long eventId) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());
        return buildEventDetail(event, teacher, true);
    }

    public EventDetailResponse updateEvent(Long eventId, EventUpdateRequest request) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());

        LocalDateTime nextStart = request.getStartAt() != null ? request.getStartAt() : event.getStartAt();
        LocalDateTime nextEnd = request.getEndAt() != null ? request.getEndAt() : event.getEndAt();
        validateEventDates(nextStart, nextEnd);

        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            event.setTitle(request.getTitle().trim());
        }
        if (request.getDescription() != null) {
            event.setDescription(request.getDescription());
        }
        if (request.getStartAt() != null) {
            event.setStartAt(request.getStartAt());
        }
        if (request.getEndAt() != null) {
            event.setEndAt(request.getEndAt());
        }
        if (request.getSessionDurationMinutes() != null) {
            event.setSessionDurationMinutes(request.getSessionDurationMinutes());
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            EventWorkflowStatus nextStatus = EventWorkflowStatus.valueOf(request.getStatus().trim().toUpperCase());
            event.setStatus(nextStatus);
            if (nextStatus == EventWorkflowStatus.LIVE || nextStatus == EventWorkflowStatus.COMPLETED) {
                publishEventEvidences(event.getId());
            }
        }

        eventRepository.save(event);
        return buildEventDetail(event, teacher, true);
    }

    public EventAssignmentResponse createAssignment(Long eventId, EventAssignmentRequest request) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());

        EventAssignmentType assignmentType = EventAssignmentType.valueOf(request.getAssignmentType().trim().toUpperCase());
        if (assignmentRepository.findByEventIdOrderByOrderIndexAsc(eventId).stream()
                .anyMatch(item -> Objects.equals(item.getOrderIndex(), request.getOrderIndex()))) {
            throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
        }

        User reviewer = userRepository.findById(request.getReviewerStudentId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        ensureStudentInClassroom(event.getClassroom(), reviewer.getId());

        User presenterStudent = null;
        ProjectGroup presenterGroup = null;
        if (assignmentType == EventAssignmentType.INDIVIDUAL) {
            if (request.getPresenterStudentId() == null) {
                throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
            }
            presenterStudent = userRepository.findById(request.getPresenterStudentId())
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
            ensureStudentInClassroom(event.getClassroom(), presenterStudent.getId());
            if (presenterStudent.getId().equals(reviewer.getId())) {
                throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
            }
        } else {
            if (request.getPresenterGroupId() == null) {
                throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
            }
            presenterGroup = groupRepository.findById(request.getPresenterGroupId())
                    .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));
            if (!presenterGroup.getClassroom().getId().equals(event.getClassroom().getId())) {
                throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
            }
            List<ProjectMember> members = memberRepository.findByProjectGroupId(presenterGroup.getId()).stream()
                    .filter(ProjectMember::isActive)
                    .toList();
            if (members.stream().anyMatch(member -> member.getStudent().getId().equals(reviewer.getId()))) {
                throw new AppException(ErrorCode.INVALID_EVENT_ASSIGNMENT);
            }
        }

        EventAssignment saved = assignmentRepository.save(EventAssignment.builder()
                .event(event)
                .assignmentType(assignmentType)
                .presenterStudent(presenterStudent)
                .presenterGroup(presenterGroup)
                .reviewerStudent(reviewer)
                .orderIndex(request.getOrderIndex())
                .status(EventAssignmentStatus.PENDING)
                .build());

        return mapAssignmentResponse(
                saved,
                teacher,
                Collections.emptyList(),
                Collections.emptyList()
        );
    }

    public EventQuestionResponse addQuestionBankItem(Long eventId, EventQuestionRequest request) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());

        EventQuestion saved = questionRepository.save(EventQuestion.builder()
                .event(event)
                .author(teacher)
                .assignment(null)
                .questionType(EventQuestionType.BANK)
                .content(request.getContent().trim())
                .askedAt(LocalDateTime.now())
                .build());

        return mapQuestion(saved);
    }

    public EventQuestionResponse addTeacherLiveQuestion(Long eventId, EventQuestionRequest request) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());
        if (event.getStatus() != EventWorkflowStatus.LIVE) {
            throw new AppException(ErrorCode.EVENT_ROOM_NOT_AVAILABLE);
        }

        EventAssignment assignment = resolveAssignment(eventId, request.getAssignmentId());
        EventQuestion saved = questionRepository.save(EventQuestion.builder()
                .event(event)
                .assignment(assignment)
                .author(teacher)
                .questionType(EventQuestionType.LIVE)
                .content(request.getContent().trim())
                .askedAt(LocalDateTime.now())
                .build());
        return mapQuestion(saved);
    }

    public EventAssignmentResponse completeAssignment(Long eventId, Long assignmentId) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());
        EventAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND));
        if (!assignment.getEvent().getId().equals(event.getId())) {
            throw new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND);
        }
        assignment.setStatus(EventAssignmentStatus.REVIEWED);
        assignmentRepository.save(assignment);
        return mapAssignmentResponse(
                assignment,
                teacher,
                questionRepository.findByEventIdOrderByAskedAtAsc(eventId),
                assetRepository.findByEventId(eventId)
        );
    }

    public EventAssetResponse uploadRecording(Long eventId, Long assignmentId, MultipartFile file) {
        User teacher = userService.getCurrentUser();
        ensureTeacher(teacher);
        Event event = getManagedEvent(eventId, teacher.getId());
        EventAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND));
        if (!assignment.getEvent().getId().equals(event.getId())) {
            throw new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND);
        }

        FileService.StorageResult stored = fileService.storeFile(file, "events/" + eventId + "/recordings");
        EventAsset asset = assetRepository.save(EventAsset.builder()
                .event(event)
                .assignment(assignment)
                .uploadedBy(teacher)
                .ownerStudent(null)
                .assetType(EventAssetType.RECORDING)
                .visibility(EventAssetVisibility.PUBLIC)
                .storageKey(stored.getStorageKey())
                .originalFileName(stored.getOriginalFileName())
                .contentType(stored.getContentType())
                .sizeBytes(stored.getSizeBytes())
                .build());

        return mapAsset(asset);
    }

    @Transactional(readOnly = true)
    public List<EventListResponse> getStudentEvents() {
        User student = userService.getCurrentUser();
        ensureStudent(student);

        List<ClassroomEnrollment> enrollments = enrollmentRepository.findByStudentAndStatus(
                student,
                ClassroomEnrollmentStatus.ACTIVE
        );
        List<Long> classroomIds = enrollments.stream()
                .map(enrollment -> enrollment.getClassroom().getId())
                .toList();
        if (classroomIds.isEmpty()) {
            return Collections.emptyList();
        }

        List<Event> events = eventRepository.findByClassroomIdInOrderByStartAtDesc(classroomIds);
        List<EventAssignment> assignments = events.isEmpty()
                ? Collections.emptyList()
                : assignmentRepository.findByEventIdIn(events.stream().map(Event::getId).toList());
        Map<Long, List<EventAssignment>> assignmentsByEventId = assignments.stream()
                .collect(Collectors.groupingBy(item -> item.getEvent().getId()));
        Set<Long> eventIdsWithRecording = assetRepository.findByEventIdIn(events.stream().map(Event::getId).toList())
                .stream()
                .filter(asset -> asset.getAssetType() == EventAssetType.RECORDING)
                .map(asset -> asset.getEvent().getId())
                .collect(Collectors.toSet());
        Map<Long, Set<Long>> groupMemberIds = buildGroupMemberIds(assignments);

        return events.stream()
                .map(event -> {
                    List<EventAssignment> eventAssignments = assignmentsByEventId.getOrDefault(event.getId(), Collections.emptyList());
                    String myRole = resolveRoleForEvent(student.getId(), eventAssignments, groupMemberIds);
                    return EventListResponse.builder()
                            .id(event.getId())
                            .classroomId(event.getClassroom().getId())
                            .classroomCode(event.getClassroom().getCode())
                            .classroomName(event.getClassroom().getName())
                            .title(event.getTitle())
                            .description(event.getDescription())
                            .startAt(event.getStartAt())
                            .endAt(event.getEndAt())
                            .sessionDurationMinutes(event.getSessionDurationMinutes())
                            .status(event.getStatus().name())
                            .myRole(myRole)
                            .canJoinRoom(event.getStatus() == EventWorkflowStatus.LIVE && !"AUDIENCE".equals(myRole))
                            .canWatchRecording(event.getStatus() == EventWorkflowStatus.COMPLETED && eventIdsWithRecording.contains(event.getId()))
                            .assignmentCount(eventAssignments.size())
                            .build();
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public EventDetailResponse getStudentEventDetail(Long eventId) {
        User student = userService.getCurrentUser();
        ensureStudent(student);
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_NOT_FOUND));
        ensureStudentInClassroom(event.getClassroom(), student.getId());
        return buildEventDetail(event, student, false);
    }

    public EventAssetResponse uploadStudentEvidence(Long eventId, MultipartFile file, Long assignmentId) {
        User student = userService.getCurrentUser();
        ensureStudent(student);
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_NOT_FOUND));
        ensureStudentInClassroom(event.getClassroom(), student.getId());

        EventAssignment assignment = null;
        if (assignmentId != null) {
            assignment = assignmentRepository.findById(assignmentId)
                    .orElseThrow(() -> new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND));
            if (!assignment.getEvent().getId().equals(eventId)) {
                throw new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND);
            }
            String role = resolveAssignmentRole(student.getId(), assignment);
            if (!"PRESENTER".equals(role)) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        } else {
            EventDetailResponse detail = buildEventDetail(event, student, false);
            if (!Boolean.TRUE.equals(detail.getCanUploadEvidence()) || detail.getMyAssignment() == null) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
            assignment = detail.getMyAssignment().getId() != null
                    ? assignmentRepository.findById(detail.getMyAssignment().getId()).orElse(null)
                    : null;
        }

        FileService.StorageResult stored = fileService.storeFile(file, "events/" + eventId + "/evidences");
        EventAsset asset = assetRepository.save(EventAsset.builder()
                .event(event)
                .assignment(assignment)
                .uploadedBy(student)
                .ownerStudent(student)
                .assetType(EventAssetType.EVIDENCE)
                .visibility(EventAssetVisibility.PUBLIC)
                .storageKey(stored.getStorageKey())
                .originalFileName(stored.getOriginalFileName())
                .contentType(stored.getContentType())
                .sizeBytes(stored.getSizeBytes())
                .build());

        return mapAsset(asset);
    }

    public void deleteEventAsset(Long assetId) {
        User currentUser = userService.getCurrentUser();
        EventAsset asset = assetRepository.findById(assetId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_ASSET_NOT_FOUND));
        boolean isTeacher = "ROLE_TEACHER".equals(currentUser.getRole().getName())
                && asset.getEvent().getClassroom().getTeacher().getId().equals(currentUser.getId());
        boolean isOwner = asset.getOwnerStudent() != null
                && asset.getOwnerStudent().getId().equals(currentUser.getId())
                && asset.getEvent().getStatus() == EventWorkflowStatus.SCHEDULED;
        if (!isTeacher && !isOwner) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        fileService.deleteFile(asset.getStorageKey());
        assetRepository.delete(asset);
    }

    public EventQuestionResponse addStudentLiveQuestion(Long eventId, EventQuestionRequest request) {
        User student = userService.getCurrentUser();
        ensureStudent(student);
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_NOT_FOUND));
        ensureStudentInClassroom(event.getClassroom(), student.getId());
        if (event.getStatus() != EventWorkflowStatus.LIVE) {
            throw new AppException(ErrorCode.EVENT_ROOM_NOT_AVAILABLE);
        }

        EventDetailResponse detail = buildEventDetail(event, student, false);
        if (!Boolean.TRUE.equals(detail.getCanAskQuestions())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        EventAssignment assignment = resolveAssignment(
                eventId,
                request.getAssignmentId() != null ? request.getAssignmentId() : detail.getMyAssignment() != null ? detail.getMyAssignment().getId() : null
        );

        EventQuestion saved = questionRepository.save(EventQuestion.builder()
                .event(event)
                .assignment(assignment)
                .author(student)
                .questionType(EventQuestionType.LIVE)
                .content(request.getContent().trim())
                .askedAt(LocalDateTime.now())
                .build());
        return mapQuestion(saved);
    }

    public EventQuestionResponse answerStudentLiveQuestion(Long eventId, Long questionId, String answerContent) {
        User student = userService.getCurrentUser();
        ensureStudent(student);
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_NOT_FOUND));
        ensureStudentInClassroom(event.getClassroom(), student.getId());

        EventQuestion question = questionRepository.findById(questionId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_QUESTION_NOT_FOUND));
        if (!question.getEvent().getId().equals(eventId)) {
            throw new AppException(ErrorCode.EVENT_QUESTION_NOT_FOUND);
        }

        EventAssignment assignment = question.getAssignment();
        if (assignment == null) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        String role = resolveAssignmentRole(student.getId(), assignment);
        if (!"PRESENTER".equals(role)) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (question.getAnswer() != null && !question.getAnswer().isBlank()) {
            throw new AppException(ErrorCode.QUESTION_ALREADY_ANSWERED);
        }

        question.setAnswer(answerContent != null ? answerContent.trim() : null);
        question.setAnsweredAt(LocalDateTime.now());
        EventQuestion saved = questionRepository.save(question);
        return mapQuestion(saved);
    }

    private EventDetailResponse buildEventDetail(Event event, User currentUser, boolean includeManagementData) {
        List<EventAssignment> assignments = assignmentRepository.findByEventIdOrderByOrderIndexAsc(event.getId());
        List<EventQuestion> questions = questionRepository.findByEventIdOrderByAskedAtAsc(event.getId());
        List<EventAsset> assets = assetRepository.findByEventId(event.getId());
        Map<Long, Set<Long>> groupMemberIds = buildGroupMemberIds(assignments);
        String myRole = resolveRoleForEvent(currentUser.getId(), assignments, groupMemberIds);

        List<EventQuestionResponse> bankQuestions = questions.stream()
                .filter(question -> question.getQuestionType() == EventQuestionType.BANK)
                .map(this::mapQuestion)
                .toList();

        List<EventAssignmentResponse> assignmentResponses = assignments.stream()
                .map(assignment -> mapAssignmentResponse(assignment, currentUser, questions, filterVisibleAssets(assets, currentUser, includeManagementData)))
                .toList();

        EventAssignmentResponse myAssignment = assignmentResponses.stream()
                .filter(item -> item.getMyRole() != null && !"AUDIENCE".equals(item.getMyRole()))
                .findFirst()
                .orElse(null);

        boolean isTeacher = includeManagementData;
        boolean canJoinRoom = event.getStatus() == EventWorkflowStatus.LIVE && !"AUDIENCE".equals(myRole);
        boolean canWatchRecording = event.getStatus() == EventWorkflowStatus.COMPLETED
                && assignmentResponses.stream().anyMatch(item -> item.getRecording() != null);
        boolean canUploadEvidence = event.getStatus() == EventWorkflowStatus.SCHEDULED && "PRESENTER".equals(myRole);
        boolean canAskQuestions = event.getStatus() == EventWorkflowStatus.LIVE
                && (isTeacher || "REVIEWER".equals(myRole) || "PRESENTER".equals(myRole));

        return EventDetailResponse.builder()
                .id(event.getId())
                .classroomId(event.getClassroom().getId())
                .classroomCode(event.getClassroom().getCode())
                .classroomName(event.getClassroom().getName())
                .title(event.getTitle())
                .description(event.getDescription())
                .startAt(event.getStartAt())
                .endAt(event.getEndAt())
                .sessionDurationMinutes(event.getSessionDurationMinutes())
                .status(event.getStatus().name())
                .teacher(toUserResponse(event.getClassroom().getTeacher()))
                .myRole(myRole)
                .canManage(isTeacher)
                .canJoinRoom(canJoinRoom)
                .canWatchRecording(canWatchRecording)
                .canUploadEvidence(canUploadEvidence)
                .canAskQuestions(canAskQuestions)
                .myAssignment(myAssignment)
                .assignments(assignmentResponses)
                .questionBank(bankQuestions)
                .availableStudents(includeManagementData ? loadClassroomStudents(event.getClassroom()) : Collections.emptyList())
                .availableGroups(includeManagementData ? loadClassroomGroups(event.getClassroom().getId()) : Collections.emptyList())
                .build();
    }

    private List<EventAsset> filterVisibleAssets(List<EventAsset> assets, User currentUser, boolean includeManagementData) {
        if (includeManagementData) {
            return assets;
        }
        return assets.stream()
                .filter(asset -> asset.getVisibility() == EventAssetVisibility.PUBLIC
                        || asset.getAssetType() == EventAssetType.EVIDENCE
                        || asset.getUploadedBy().getId().equals(currentUser.getId()))
                .toList();
    }

    private EventAssignmentResponse mapAssignmentResponse(
            EventAssignment assignment,
            User currentUser,
            List<EventQuestion> allQuestions,
            List<EventAsset> visibleAssets
    ) {
        List<EventQuestionResponse> questions = allQuestions.stream()
                .filter(question -> question.getQuestionType() == EventQuestionType.LIVE)
                .filter(question -> question.getAssignment() != null && question.getAssignment().getId().equals(assignment.getId()))
                .map(this::mapQuestion)
                .toList();
        List<EventAssetResponse> evidences = visibleAssets.stream()
                .filter(asset -> asset.getAssignment() != null && asset.getAssignment().getId().equals(assignment.getId()))
                .filter(asset -> asset.getAssetType() == EventAssetType.EVIDENCE)
                .map(this::mapAsset)
                .toList();
        EventAssetResponse recording = visibleAssets.stream()
                .filter(asset -> asset.getAssignment() != null && asset.getAssignment().getId().equals(assignment.getId()))
                .filter(asset -> asset.getAssetType() == EventAssetType.RECORDING)
                .findFirst()
                .map(this::mapAsset)
                .orElse(null);

        String myRole = resolveAssignmentRole(currentUser.getId(), assignment);
        boolean currentUserInPresenterTeam = "PRESENTER".equals(myRole);

        return EventAssignmentResponse.builder()
                .id(assignment.getId())
                .assignmentType(assignment.getAssignmentType().name())
                .orderIndex(assignment.getOrderIndex())
                .status(assignment.getStatus().name())
                .presenterStudentId(assignment.getPresenterStudent() != null ? assignment.getPresenterStudent().getId() : null)
                .presenterStudentName(assignment.getPresenterStudent() != null ? assignment.getPresenterStudent().getFullName() : null)
                .presenterGroupId(assignment.getPresenterGroup() != null ? assignment.getPresenterGroup().getId() : null)
                .presenterGroupName(assignment.getPresenterGroup() != null ? assignment.getPresenterGroup().getGroupName() : null)
                .reviewerStudentId(assignment.getReviewerStudent().getId())
                .reviewerStudentName(assignment.getReviewerStudent().getFullName())
                .myRole(myRole)
                .currentUserInPresenterTeam(currentUserInPresenterTeam)
                .questions(questions)
                .evidences(evidences)
                .recording(recording)
                .build();
    }

    private EventQuestionResponse mapQuestion(EventQuestion question) {
        return EventQuestionResponse.builder()
                .id(question.getId())
                .assignmentId(question.getAssignment() != null ? question.getAssignment().getId() : null)
                .questionType(question.getQuestionType().name())
                .content(question.getContent())
                .authorId(question.getAuthor().getId())
                .authorName(question.getAuthor().getFullName())
                .authorRole(question.getAuthor().getRole() != null ? question.getAuthor().getRole().getName() : null)
                .askedAt(question.getAskedAt())
                .answer(question.getAnswer())
                .answeredAt(question.getAnsweredAt())
                .build();
    }

    private EventAssetResponse mapAsset(EventAsset asset) {
        return EventAssetResponse.builder()
                .id(asset.getId())
                .assignmentId(asset.getAssignment() != null ? asset.getAssignment().getId() : null)
                .assetType(asset.getAssetType().name())
                .visibility(asset.getVisibility().name())
                .fileUrl(fileService.getFileUrl(asset.getStorageKey()))
                .originalFileName(asset.getOriginalFileName())
                .contentType(asset.getContentType())
                .sizeBytes(asset.getSizeBytes())
                .uploadedById(asset.getUploadedBy().getId())
                .uploadedByName(asset.getUploadedBy().getFullName())
                .ownerStudentId(asset.getOwnerStudent() != null ? asset.getOwnerStudent().getId() : null)
                .createdAt(asset.getCreatedAt())
                .build();
    }

    private List<UserResponse> loadClassroomStudents(Classroom classroom) {
        return enrollmentRepository.findByClassroomId(classroom.getId()).stream()
                .filter(enrollment -> enrollment.getStatus() == ClassroomEnrollmentStatus.ACTIVE)
                .map(ClassroomEnrollment::getStudent)
                .map(this::toUserResponse)
                .toList();
    }

    private List<ProjectGroupListResponse> loadClassroomGroups(Long classroomId) {
        return groupRepository.findByClassroomId(classroomId).stream()
                .map(group -> ProjectGroupListResponse.builder()
                        .id(group.getId())
                        .groupName(group.getGroupName())
                        .projectName(group.getProjectName())
                        .leader(group.getLeader() != null ? toUserResponse(group.getLeader()) : null)
                        .status(group.getStatus().name())
                        .memberCount((int) memberRepository.findByProjectGroupId(group.getId()).stream().filter(ProjectMember::isActive).count())
                        .classroomId(group.getClassroom().getId())
                        .classroomCode(group.getClassroom().getCode())
                        .classroomName(group.getClassroom().getName())
                        .build())
                .toList();
    }

    private UserResponse toUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .userName(user.getUserName())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .institutionalId(user.getInstitutionalId())
                .active(user.isActive())
                .role(user.getRole() != null
                        ? RoleResponse.builder()
                        .id(user.getRole().getId())
                        .name(user.getRole().getName())
                        .description(user.getRole().getDescription())
                        .build()
                        : null)
                .build();
    }

    private void validateEventDates(LocalDateTime startAt, LocalDateTime endAt) {
        if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
            throw new AppException(ErrorCode.INVALID_EVENT_DATES);
        }
    }

    private void publishEventEvidences(Long eventId) {
        List<EventAsset> assets = assetRepository.findByEventId(eventId);
        for (EventAsset asset : assets) {
            if (asset.getAssetType() == EventAssetType.EVIDENCE
                    && asset.getVisibility() == EventAssetVisibility.PRIVATE) {
                asset.setVisibility(EventAssetVisibility.PUBLIC);
            }
        }
    }

    private EventAssignment resolveAssignment(Long eventId, Long assignmentId) {
        if (assignmentId == null) {
            return null;
        }
        EventAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND));
        if (!assignment.getEvent().getId().equals(eventId)) {
            throw new AppException(ErrorCode.EVENT_ASSIGNMENT_NOT_FOUND);
        }
        return assignment;
    }

    private Event getManagedEvent(Long eventId, Long teacherId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new AppException(ErrorCode.EVENT_NOT_FOUND));
        if (!event.getClassroom().getTeacher().getId().equals(teacherId)) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        return event;
    }

    private void ensureTeacher(User user) {
        if (!"ROLE_TEACHER".equals(user.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
    }

    private void ensureStudent(User user) {
        if (!"ROLE_STUDENT".equals(user.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
    }

    private void ensureStudentInClassroom(Classroom classroom, Long studentId) {
        ClassroomEnrollment enrollment = enrollmentRepository.findByClassroomIdAndStudentId(classroom.getId(), studentId)
                .orElseThrow(() -> new AppException(ErrorCode.FORBIDDEN));
        if (enrollment.getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
    }

    private Map<Long, Set<Long>> buildGroupMemberIds(List<EventAssignment> assignments) {
        List<Long> groupIds = assignments.stream()
                .map(EventAssignment::getPresenterGroup)
                .filter(Objects::nonNull)
                .map(ProjectGroup::getId)
                .distinct()
                .toList();
        if (groupIds.isEmpty()) {
            return Collections.emptyMap();
        }

        return memberRepository.findByProjectGroupIdIn(groupIds).stream()
                .filter(ProjectMember::isActive)
                .collect(Collectors.groupingBy(
                        member -> member.getProjectGroup().getId(),
                        Collectors.mapping(member -> member.getStudent().getId(), Collectors.toSet())
                ));
    }

    private String resolveRoleForEvent(Long userId, List<EventAssignment> assignments, Map<Long, Set<Long>> groupMemberIds) {
        for (EventAssignment assignment : assignments) {
            String role = resolveAssignmentRole(userId, assignment, groupMemberIds);
            if (!"AUDIENCE".equals(role)) {
                return role;
            }
        }
        return "AUDIENCE";
    }

    private String resolveAssignmentRole(Long userId, EventAssignment assignment) {
        return resolveAssignmentRole(userId, assignment, new HashMap<>());
    }

    private String resolveAssignmentRole(Long userId, EventAssignment assignment, Map<Long, Set<Long>> groupMemberIds) {
        if (assignment.getReviewerStudent() != null && assignment.getReviewerStudent().getId().equals(userId)) {
            return "REVIEWER";
        }
        if (assignment.getPresenterStudent() != null && assignment.getPresenterStudent().getId().equals(userId)) {
            return "PRESENTER";
        }
        if (assignment.getPresenterGroup() != null) {
            Set<Long> memberIds = groupMemberIds.computeIfAbsent(
                    assignment.getPresenterGroup().getId(),
                    groupId -> memberRepository.findByProjectGroupId(groupId).stream()
                            .filter(ProjectMember::isActive)
                            .map(member -> member.getStudent().getId())
                            .collect(Collectors.toSet())
            );
            if (memberIds.contains(userId)) {
                return "PRESENTER";
            }
        }
        return "AUDIENCE";
    }
}
