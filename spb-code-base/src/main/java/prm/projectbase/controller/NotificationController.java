package prm.projectbase.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.NotificationResponse;
import prm.projectbase.service.NotificationService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Get all notifications for the current user
     * GET /api/v1/notifications
     */
    @GetMapping
    public ResponseEntity<BaseResponse<List<NotificationResponse>>> getUserNotifications() {
        log.info("GET /api/v1/notifications - Fetching user notifications");
        List<NotificationResponse> response = notificationService.getUserNotifications();
        return ResponseEntity.ok(BaseResponse.success(response, "Get notifications successfully"));
    }

    /**
     * Get only unread notifications for the current user
     * GET /api/v1/notifications/unread
     */
    @GetMapping("/unread")
    public ResponseEntity<BaseResponse<List<NotificationResponse>>> getUnreadNotifications() {
        log.info("GET /api/v1/notifications/unread - Fetching unread notifications");
        List<NotificationResponse> response = notificationService.getUnreadNotifications();
        return ResponseEntity.ok(BaseResponse.success(response, "Get unread notifications successfully"));
    }

    /**
     * Get unread notification count
     * GET /api/v1/notifications/unread-count
     */
    @GetMapping("/unread-count")
    public ResponseEntity<BaseResponse<Long>> getUnreadCount() {
        log.info("GET /api/v1/notifications/unread-count - Fetching unread count");
        long count = notificationService.getUnreadCount();
        return ResponseEntity.ok(BaseResponse.success(count, "Get unread count successfully"));
    }

    /**
     * Mark a notification as read
     * PUT /api/v1/notifications/{notificationId}/read
     */
    @PutMapping("/{notificationId}/read")
    public ResponseEntity<BaseResponse<NotificationResponse>> markAsRead(
            @PathVariable Long notificationId) {
        log.info("PUT /api/v1/notifications/{}/read - Marking notification as read", notificationId);
        NotificationResponse response = notificationService.markAsRead(notificationId);
        return ResponseEntity.ok(BaseResponse.success(response, "Marked notification as read successfully"));
    }

    /**
     * Mark all notifications of the current user as read
     * PUT /api/v1/notifications/read-all
     */
    @PutMapping("/read-all")
    public ResponseEntity<BaseResponse<Void>> markAllAsRead() {
        log.info("PUT /api/v1/notifications/read-all - Marking all notifications as read");
        notificationService.markAllAsRead();
        return ResponseEntity.ok(BaseResponse.success(null, "Marked all notifications as read successfully"));
    }
}
