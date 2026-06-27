package prm.projectbase.exception;

import org.springframework.http.HttpStatus;
import lombok.Getter;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(500, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_KEY(400, "Invalid configuration key", HttpStatus.BAD_REQUEST),
    USER_EXISTED(400, "User already exists", HttpStatus.BAD_REQUEST),
    USERNAME_INVALID(400, "Username must be at least 3 characters", HttpStatus.BAD_REQUEST),
    INVALID_PASSWORD(400, "Password must be at least 6 characters", HttpStatus.BAD_REQUEST),
    USER_NOT_FOUND(404, "User not found", HttpStatus.NOT_FOUND),
    ROLE_NOT_FOUND(404, "Role not found", HttpStatus.NOT_FOUND),
    UNAUTHENTICATED(401, "Unauthenticated", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED(403, "You do not have permission", HttpStatus.FORBIDDEN),
    FORBIDDEN(403, "You do not have permission to perform this action", HttpStatus.FORBIDDEN),
    EMAIL_EXISTED(400, "Email already exists", HttpStatus.BAD_REQUEST),
    INVALID_CREDENTIALS(402, "Invalid parameters", HttpStatus.UNPROCESSABLE_ENTITY),
    FILE_STORAGE_ERROR(500, "Could not store file", HttpStatus.INTERNAL_SERVER_ERROR),
    FILE_NOT_FOUND(404, "File not found", HttpStatus.NOT_FOUND),
    
    // Classroom errors
    CLASSROOM_NOT_FOUND(404, "Classroom not found", HttpStatus.NOT_FOUND),
    CLASSROOM_CODE_ALREADY_EXISTS(400, "Classroom code already exists", HttpStatus.BAD_REQUEST),
    CLASSROOM_INACTIVE(400, "This classroom is inactive", HttpStatus.BAD_REQUEST),
    ALREADY_ENROLLED(400, "You are already enrolled in this classroom", HttpStatus.BAD_REQUEST),
    
    // Material errors
    MATERIAL_NOT_FOUND(404, "Material not found", HttpStatus.NOT_FOUND),
    
    // Activity errors
    ACTIVITY_NOT_FOUND(404, "Activity not found", HttpStatus.NOT_FOUND),
    ACTIVITY_ALREADY_CLOSED(400, "This activity is already closed", HttpStatus.BAD_REQUEST),
    ACTIVITY_NOT_YET_OPEN(400, "This activity is not yet open for submission", HttpStatus.BAD_REQUEST),
    INVALID_ACTIVITY_DATES(400, "Activity open date must be before due date", HttpStatus.BAD_REQUEST),
    
    // Submission errors
    SUBMISSION_NOT_FOUND(404, "Submission not found", HttpStatus.NOT_FOUND),
    SUBMISSION_LOCKED(400, "This submission is locked and cannot be edited", HttpStatus.BAD_REQUEST),
    INVALID_SCORE(400, "Score is outside the valid range for this activity", HttpStatus.BAD_REQUEST),

    // Phase 3 errors
    GROUP_NOT_FOUND(404, "Project group not found", HttpStatus.NOT_FOUND),
    GROUP_ALREADY_EXISTS(400, "Project group name already exists in this classroom", HttpStatus.BAD_REQUEST),
    STUDENT_NOT_ENROLLED(400, "Student is not enrolled in this classroom", HttpStatus.BAD_REQUEST),
    STUDENT_ALREADY_IN_GROUP(400, "Student is already in another active group in this classroom", HttpStatus.BAD_REQUEST),
    LEADER_MUST_BE_MEMBER(400, "Leader must be a member of the group", HttpStatus.BAD_REQUEST),
    MILESTONE_NOT_FOUND(404, "Milestone not found", HttpStatus.NOT_FOUND),
    PEER_REVIEW_NOT_FOUND(404, "Peer review not found", HttpStatus.NOT_FOUND),
    CANNOT_REVIEW_OWN_GROUP(400, "Reviewer cannot review their own group", HttpStatus.BAD_REQUEST),
    PEER_REVIEW_ALREADY_SUBMITTED(400, "Peer review is already submitted and cannot be updated", HttpStatus.BAD_REQUEST),
    REVIEWER_NOT_IN_CLASSROOM(400, "Reviewer is not in this classroom", HttpStatus.BAD_REQUEST),
    ;


    ErrorCode(int code, String message, HttpStatus statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private final int code;
    private final String message;
    private final HttpStatus statusCode;
}
