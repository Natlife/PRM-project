package prm.projectbase.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.MaterialUploadRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.MaterialDetailResponse;
import prm.projectbase.dto.response.MaterialListResponse;
import prm.projectbase.entity.enums.ClassroomMaterialType;
import prm.projectbase.service.MaterialService;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MaterialController {
    
    private final MaterialService materialService;

    @PostMapping("/teacher/classrooms/{classroomId}/materials")
    public ResponseEntity<BaseResponse<MaterialDetailResponse>> uploadMaterial(
            @PathVariable Long classroomId,
            @RequestParam String title,
            @RequestParam(required = false) String description,
            @RequestParam ClassroomMaterialType materialType,
            @RequestParam MultipartFile file,
            @RequestParam(defaultValue = "true") Boolean publishImmediately,
            @RequestParam(required = false) LocalDateTime schedulePublishAt) {
        
        log.info("POST /teacher/classrooms/{}/materials - Uploading material", classroomId);
        
        MaterialUploadRequest request = MaterialUploadRequest.builder()
                .title(title)
                .description(description)
                .materialType(materialType)
                .file(file)
                .publishImmediately(publishImmediately)
                .schedulePublishAt(schedulePublishAt)
                .build();
        
        MaterialDetailResponse response = materialService.uploadMaterial(classroomId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Material uploaded successfully", HttpStatus.CREATED));
    }

    @GetMapping("/classrooms/{classroomId}/materials")
    public ResponseEntity<BaseResponse<List<MaterialListResponse>>> getClassroomMaterials(
            @PathVariable Long classroomId) {
        
        log.info("GET /classrooms/{}/materials - Fetching materials", classroomId);
        
        List<MaterialListResponse> response = materialService.getClassroomMaterials(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @GetMapping("/materials/{materialId}")
    public ResponseEntity<BaseResponse<MaterialDetailResponse>> getMaterial(
            @PathVariable Long materialId) {
        
        log.info("GET /materials/{} - Fetching material detail", materialId);
        
        MaterialDetailResponse response = materialService.getMaterial(materialId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @DeleteMapping("/teacher/materials/{materialId}")
    public ResponseEntity<BaseResponse<Void>> deleteMaterial(
            @PathVariable Long materialId) {
        
        log.info("DELETE /teacher/materials/{} - Deleting material", materialId);
        
        materialService.deleteMaterial(materialId);
        return ResponseEntity.ok(BaseResponse.success(null));
    }
}
