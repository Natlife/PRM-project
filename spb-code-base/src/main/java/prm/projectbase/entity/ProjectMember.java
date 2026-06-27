package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ProjectMemberRole;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "project_members",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_project_member_student", columnNames = {"project_group_id", "student_id"})
        },
        indexes = {
                @Index(name = "idx_project_members_group_id", columnList = "project_group_id"),
                @Index(name = "idx_project_members_student_id", columnList = "student_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProjectMember extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "project_group_id", nullable = false)
    ProjectGroup projectGroup;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    User student;

    @Enumerated(EnumType.STRING)
    @Column(name = "member_role", nullable = false, length = 20)
    @Builder.Default
    ProjectMemberRole memberRole = ProjectMemberRole.MEMBER;

    @Column(name = "joined_at", nullable = false)
    @Builder.Default
    LocalDateTime joinedAt = LocalDateTime.now();

    @Builder.Default
    @Column(nullable = false)
    boolean active = true;
}
