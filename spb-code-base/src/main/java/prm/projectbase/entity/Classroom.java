package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@Table(
        name = "classrooms",
        indexes = {
                @Index(name = "idx_classrooms_teacher_id", columnList = "teacher_id"),
                @Index(name = "idx_classrooms_join_code", columnList = "join_code", unique = true)
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Classroom extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    String code;

    @Column(nullable = false, length = 255)
    String name;

    @Column(length = 2000)
    String description;

    @Column(name = "semester_code", nullable = false, length = 30)
    String semesterCode;

    @Column(name = "join_code", nullable = false, unique = true, length = 80)
    String joinCode;

    @Builder.Default
    @Column(nullable = false)
    boolean active = true;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "teacher_id", nullable = false)
    User teacher;

    @OneToMany(mappedBy = "classroom", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    List<ClassroomSchedule> schedules = List.of();

    @OneToMany(mappedBy = "classroom", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    List<ClassroomEnrollment> enrollments = List.of();
}
