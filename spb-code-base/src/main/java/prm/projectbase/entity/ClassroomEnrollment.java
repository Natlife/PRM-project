package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "classroom_enrollments",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_classroom_student", columnNames = {"classroom_id", "student_id"})
        },
        indexes = {
                @Index(name = "idx_enrollment_classroom_id", columnList = "classroom_id"),
                @Index(name = "idx_enrollment_student_id", columnList = "student_id")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ClassroomEnrollment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classroom_id", nullable = false)
    Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    User student;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    ClassroomEnrollmentStatus status = ClassroomEnrollmentStatus.ACTIVE;

    @Column(name = "joined_at", nullable = false)
    @Builder.Default
    LocalDateTime joinedAt = LocalDateTime.now();
}
