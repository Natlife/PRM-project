package prm.projectbase.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.StudentDashboardResponse;
import prm.projectbase.dto.response.TeacherDashboardResponse;
import prm.projectbase.service.DashboardService;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    /**
     * Get dashboard summary for the current student
     * GET /api/v1/student/dashboard/summary
     */
    @GetMapping("/student/dashboard/summary")
    public ResponseEntity<BaseResponse<StudentDashboardResponse>> getStudentDashboard() {
        log.info("GET /student/dashboard/summary - Fetching student dashboard summary");
        StudentDashboardResponse response = dashboardService.getStudentDashboard();
        return ResponseEntity.ok(BaseResponse.success(response, "Get student dashboard summary successfully"));
    }

    /**
     * Get dashboard summary for the current teacher
     * GET /api/v1/teacher/dashboard/summary
     */
    @GetMapping("/teacher/dashboard/summary")
    public ResponseEntity<BaseResponse<TeacherDashboardResponse>> getTeacherDashboard() {
        log.info("GET /teacher/dashboard/summary - Fetching teacher dashboard summary");
        TeacherDashboardResponse response = dashboardService.getTeacherDashboard();
        return ResponseEntity.ok(BaseResponse.success(response, "Get teacher dashboard summary successfully"));
    }
}
