package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.request.MaterialUploadRequest;
import prm.projectbase.dto.response.MaterialDetailResponse;
import prm.projectbase.dto.response.MaterialListResponse;
import prm.projectbase.entity.ClassMaterial;
import prm.projectbase.entity.Classroom;
import prm.projectbase.entity.User;
import prm.projectbase.entity.enums.ClassroomMaterialType;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.ClassMaterialRepository;
import prm.projectbase.repository.ClassroomRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class MaterialService {
    
    private final ClassMaterialRepository materialRepository;
    private final ClassroomRepository classroomRepository;
    private final UserService userService;
    private final FileService fileService;
    private final NotificationService notificationService;

    public MaterialDetailResponse uploadMaterial(Long classroomId, MaterialUploadRequest request) {
        log.info("Teacher uploading material to classroom {}", classroomId);

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        FileService.StorageResult storageResult = fileService.storeFile(
                request.getFile(),
                "materials/" + classroomId
        );

        ClassMaterial material = ClassMaterial.builder()
                .classroom(classroom)
                .title(request.getTitle())
                .description(request.getDescription())
                .materialType(request.getMaterialType())
                .storageKey(storageResult.getStorageKey())
                .originalFileName(storageResult.getOriginalFileName())
                .contentType(storageResult.getContentType())
                .sizeBytes(storageResult.getSizeBytes())
                .publishedAt(request.getPublishImmediately() ? LocalDateTime.now() : request.getSchedulePublishAt())
                .build();
        
        ClassMaterial saved = materialRepository.save(material);
        log.info("Material saved with id {}", saved.getId());
        
        if (request.getPublishImmediately()) {
            notificationService.sendNotificationToAllEnrolled(
                    classroom,
                    "New Material Published",
                    "A new class material '" + saved.getTitle() + "' has been uploaded to class " + classroom.getName(),
                    prm.projectbase.entity.enums.NotificationType.MATERIAL_PUBLISHED,
                    "Material",
                    saved.getId()
            );
        }
        
        return toDetailResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<MaterialListResponse> getClassroomMaterials(Long classroomId) {
        log.info("Fetching materials for classroom {}", classroomId);

        classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();

        boolean isTeacher = "ROLE_TEACHER".equals(currentUser.getRole().getName());
        
        List<ClassMaterial> materials = isTeacher
                ? materialRepository.findByClassroomIdOrderByPublishedAtDesc(classroomId)
                : materialRepository.findPublishedInClassroom(classroomId, LocalDateTime.now());
        
        return materials.stream()
                .map(this::toListResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public MaterialDetailResponse getMaterial(Long materialId) {
        log.info("Fetching material {}", materialId);
        
        ClassMaterial material = materialRepository.findById(materialId)
                .orElseThrow(() -> new AppException(ErrorCode.MATERIAL_NOT_FOUND));

        if (material.getPublishedAt().isAfter(LocalDateTime.now())) {
            User currentUser = userService.getCurrentUser();
            if (!material.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }
        
        return toDetailResponse(material);
    }

    public void deleteMaterial(Long materialId) {
        log.info("Deleting material {}", materialId);
        
        ClassMaterial material = materialRepository.findById(materialId)
                .orElseThrow(() -> new AppException(ErrorCode.MATERIAL_NOT_FOUND));
        
        User currentUser = userService.getCurrentUser();
        if (!material.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        fileService.deleteFile(material.getStorageKey());

        materialRepository.delete(material);
        log.info("Material {} deleted", materialId);
    }

    private MaterialDetailResponse toDetailResponse(ClassMaterial material) {
        return MaterialDetailResponse.builder()
                .id(material.getId())
                .classroomId(material.getClassroom().getId())
                .title(material.getTitle())
                .description(material.getDescription())
                .materialType(material.getMaterialType().name())
                .originalFileName(material.getOriginalFileName())
                .contentType(material.getContentType())
                .sizeBytes(material.getSizeBytes())
                .fileUrl(fileService.getFileUrl(material.getStorageKey()))
                .publishedAt(material.getPublishedAt())
                .createdAt(material.getCreatedAt())
                .build();
    }
    
    private MaterialListResponse toListResponse(ClassMaterial material) {
        return MaterialListResponse.builder()
                .id(material.getId())
                .title(material.getTitle())
                .description(material.getDescription())
                .materialType(material.getMaterialType().name())
                .originalFileName(material.getOriginalFileName())
                .sizeBytes(material.getSizeBytes())
                .fileUrl(fileService.getFileUrl(material.getStorageKey()))
                .publishedAt(material.getPublishedAt())
                .build();
    }
}
