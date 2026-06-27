package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ProjectGroupStatus;

@Entity
@Table(
        name = "project_groups",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_project_group_name_per_class", columnNames = {"classroom_id", "group_name"})
        },
        indexes = {
                @Index(name = "idx_project_groups_classroom_id", columnList = "classroom_id"),
                @Index(name = "idx_project_groups_leader_id", columnList = "leader_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectGroup extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @Column(name = "group_name", nullable = false, length = 120)
    String groupName;

    @Column(name = "project_name", nullable = false, length = 255)
    String projectName;

    @Column(length = 3000)
    String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "leader_id")
    User leader;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    ProjectGroupStatus status = ProjectGroupStatus.ACTIVE;
}
