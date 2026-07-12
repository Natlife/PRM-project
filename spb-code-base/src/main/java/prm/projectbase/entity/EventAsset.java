package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.EventAssetType;
import prm.projectbase.entity.enums.EventAssetVisibility;

@Entity
@Table(name = "event_assets", indexes = {
        @Index(name = "idx_event_assets_event_id", columnList = "event_id"),
        @Index(name = "idx_event_assets_assignment_id", columnList = "assignment_id"),
        @Index(name = "idx_event_assets_uploader_id", columnList = "uploaded_by")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventAsset extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    Event event;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignment_id")
    EventAssignment assignment;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "uploaded_by", nullable = false)
    User uploadedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_student_id")
    User ownerStudent;

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_type", nullable = false, length = 20)
    EventAssetType assetType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    EventAssetVisibility visibility;

    @Column(name = "storage_key", nullable = false, length = 512)
    String storageKey;

    @Column(name = "original_file_name", nullable = false, length = 255)
    String originalFileName;

    @Column(name = "content_type", length = 120)
    String contentType;

    @Column(name = "size_bytes")
    Long sizeBytes;
}
