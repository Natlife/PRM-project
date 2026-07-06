package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "submission_attachments", indexes = {
        @Index(name = "idx_submission_attachments_submission_id", columnList = "submission_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class SubmissionAttachment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "submission_id", nullable = false)
    ActivitySubmission submission;

    @Column(name = "storage_key", nullable = false, length = 512)
    String storageKey;

    @Column(name = "original_file_name", nullable = false, length = 255)
    String originalFileName;

    @Column(name = "content_type", length = 120)
    String contentType;

    @Column(name = "size_bytes")
    Long sizeBytes;
}
