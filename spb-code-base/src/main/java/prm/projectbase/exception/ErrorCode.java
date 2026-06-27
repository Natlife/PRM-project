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
