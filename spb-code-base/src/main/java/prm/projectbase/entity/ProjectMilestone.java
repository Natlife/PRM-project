package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.MilestoneWorkflowStatus;

import java.time.LocalDateTime;

@Entity
@Table(name = "project_milestones", indexes = {
        @Index(name = "idx_project_milestones_group_id", columnList = "project_group_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectMilestone extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "project_group_id", nullable = false)
    ProjectGroup projectGroup;

    @Column(nullable = false, length = 255)
    String title;

    @Column(length = 3000)
    String description;

    @Column(name = "due_at", nullable = false)
    LocalDateTime dueAt;

    @Column(name = "progress_percent", nullable = false)
    @Builder.Default
    Integer progressPercent = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    MilestoneWorkflowStatus status = MilestoneWorkflowStatus.NOT_STARTED;
}
