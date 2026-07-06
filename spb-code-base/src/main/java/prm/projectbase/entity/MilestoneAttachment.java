package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "milestone_attachments", indexes = {
        @Index(name = "idx_milestone_attachments_milestone_id", columnList = "milestone_id"),
        @Index(name = "idx_milestone_attachments_uploaded_by", columnList = "uploaded_by")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MilestoneAttachment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "milestone_id", nullable = false)
    ProjectMilestone milestone;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "uploaded_by", nullable = false)
    User uploadedBy;

    @Column(name = "storage_key", nullable = false, length = 512)
    String storageKey;

    @Column(name = "original_file_name", nullable = false, length = 255)
    String originalFileName;

    @Column(name = "content_type", length = 120)
    String contentType;

    @Column(name = "size_bytes")
    Long sizeBytes;
}
