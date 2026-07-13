package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.EventAssignmentRequest;
import prm.projectbase.dto.request.EventCreateRequest;
import prm.projectbase.dto.request.EventQuestionRequest;
import prm.projectbase.dto.request.EventUpdateRequest;
import prm.projectbase.dto.response.*;
import prm.projectbase.service.EventService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @GetMapping("/teacher/events")
    public ResponseEntity<BaseResponse<List<EventListResponse>>> getTeacherEvents() {
        List<EventListResponse> response = eventService.getTeacherEvents();
        return ResponseEntity.ok(BaseResponse.success(response, "Get teacher events successfully"));
    }

    @PostMapping("/teacher/events")
    public ResponseEntity<BaseResponse<EventDetailResponse>> createEvent(
            @Valid @RequestBody EventCreateRequest request
    ) {
        EventDetailResponse response = eventService.createEvent(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Create event successfully", HttpStatus.CREATED));
    }

    @GetMapping("/teacher/events/{eventId}")
    public ResponseEntity<BaseResponse<EventDetailResponse>> getTeacherEventDetail(@PathVariable Long eventId) {
        EventDetailResponse response = eventService.getTeacherEventDetail(eventId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get teacher event detail successfully"));
    }

    @PutMapping("/teacher/events/{eventId}")
    public ResponseEntity<BaseResponse<EventDetailResponse>> updateEvent(
            @PathVariable Long eventId,
            @Valid @RequestBody EventUpdateRequest request
    ) {
        EventDetailResponse response = eventService.updateEvent(eventId, request);
        return ResponseEntity.ok(BaseResponse.success(response, "Update event successfully"));
    }

    @PostMapping("/teacher/events/{eventId}/assignments")
    public ResponseEntity<BaseResponse<EventAssignmentResponse>> createAssignment(
            @PathVariable Long eventId,
            @Valid @RequestBody EventAssignmentRequest request
    ) {
        EventAssignmentResponse response = eventService.createAssignment(eventId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Create event assignment successfully", HttpStatus.CREATED));
    }

    @PostMapping("/teacher/events/{eventId}/question-bank")
    public ResponseEntity<BaseResponse<EventQuestionResponse>> createQuestionBankItem(
            @PathVariable Long eventId,
            @Valid @RequestBody EventQuestionRequest request
    ) {
        EventQuestionResponse response = eventService.addQuestionBankItem(eventId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Create question bank item successfully", HttpStatus.CREATED));
    }

    @PostMapping("/teacher/events/{eventId}/questions")
    public ResponseEntity<BaseResponse<EventQuestionResponse>> addTeacherLiveQuestion(
            @PathVariable Long eventId,
            @Valid @RequestBody EventQuestionRequest request
    ) {
        EventQuestionResponse response = eventService.addTeacherLiveQuestion(eventId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Add live question successfully", HttpStatus.CREATED));
    }

    @PostMapping("/teacher/events/{eventId}/assignments/{assignmentId}/complete")
    public ResponseEntity<BaseResponse<EventAssignmentResponse>> completeAssignment(
            @PathVariable Long eventId,
            @PathVariable Long assignmentId
    ) {
        EventAssignmentResponse response = eventService.completeAssignment(eventId, assignmentId);
        return ResponseEntity.ok(BaseResponse.success(response, "Complete event assignment successfully"));
    }

    @PostMapping("/teacher/events/{eventId}/assignments/{assignmentId}/recording")
    public ResponseEntity<BaseResponse<EventAssetResponse>> uploadRecording(
            @PathVariable Long eventId,
            @PathVariable Long assignmentId,
            @RequestParam("file") MultipartFile file
    ) {
        EventAssetResponse response = eventService.uploadRecording(eventId, assignmentId, file);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Upload recording successfully", HttpStatus.CREATED));
    }

    @GetMapping("/student/events")
    public ResponseEntity<BaseResponse<List<EventListResponse>>> getStudentEvents() {
        List<EventListResponse> response = eventService.getStudentEvents();
        return ResponseEntity.ok(BaseResponse.success(response, "Get student events successfully"));
    }

    @GetMapping("/student/events/{eventId}")
    public ResponseEntity<BaseResponse<EventDetailResponse>> getStudentEventDetail(@PathVariable Long eventId) {
        EventDetailResponse response = eventService.getStudentEventDetail(eventId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get student event detail successfully"));
    }

    @PostMapping("/student/events/{eventId}/evidences")
    public ResponseEntity<BaseResponse<EventAssetResponse>> uploadEvidence(
            @PathVariable Long eventId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "assignmentId", required = false) Long assignmentId
    ) {
        EventAssetResponse response = eventService.uploadStudentEvidence(eventId, file, assignmentId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Upload event evidence successfully", HttpStatus.CREATED));
    }

    @DeleteMapping("/student/event-assets/{assetId}")
    public ResponseEntity<BaseResponse<Void>> deleteEventAsset(@PathVariable Long assetId) {
        eventService.deleteEventAsset(assetId);
        return ResponseEntity.ok(BaseResponse.success(null, "Delete event asset successfully"));
    }

    @PostMapping("/student/events/{eventId}/questions")
    public ResponseEntity<BaseResponse<EventQuestionResponse>> addStudentLiveQuestion(
            @PathVariable Long eventId,
            @Valid @RequestBody EventQuestionRequest request
    ) {
        EventQuestionResponse response = eventService.addStudentLiveQuestion(eventId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Add student live question successfully", HttpStatus.CREATED));
    }

    @PostMapping("/student/events/{eventId}/questions/{questionId}/answer")
    public ResponseEntity<BaseResponse<EventQuestionResponse>> answerQuestion(
            @PathVariable Long eventId,
            @PathVariable Long questionId,
            @RequestBody java.util.Map<String, String> body
    ) {
        String answer = body.get("answer");
        EventQuestionResponse response = eventService.answerStudentLiveQuestion(eventId, questionId, answer);
        return ResponseEntity.ok(BaseResponse.success(response, "Answer question successfully"));
    }
}
