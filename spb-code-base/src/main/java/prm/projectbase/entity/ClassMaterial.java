package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ClassroomMaterialType;

import java.time.LocalDateTime;

@Entity
@Table(name = "class_materials", indexes = {
        @Index(name = "idx_class_materials_classroom_id", columnList = "classroom_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassMaterial extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @Column(nullable = false, length = 255)
    String title;

    @Column(length = 2000)
    String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "material_type", nullable = false, length = 20)
    ClassroomMaterialType materialType;

    @Column(name = "storage_key", nullable = false, length = 512)
    String storageKey;

    @Column(name = "original_file_name", nullable = false, length = 255)
    String originalFileName;

    @Column(name = "content_type", length = 120)
    String contentType;

    @Column(name = "size_bytes")
    Long sizeBytes;

    @Column(name = "published_at")
    @Builder.Default
    LocalDateTime publishedAt = LocalDateTime.now();
}
