package prm.projectbase.entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import prm.projectbase.entity.enums.EventAssignmentStatus;
import prm.projectbase.entity.enums.EventAssignmentType;

@Entity
@Table(name = "event_assignments", indexes = {
        @Index(name = "idx_event_assignments_event_id", columnList = "event_id"),
        @Index(name = "idx_event_assignments_reviewer_id", columnList = "reviewer_student_id"),
        @Index(name = "idx_event_assignments_presenter_id", columnList = "presenter_student_id"),
        @Index(name = "idx_event_assignments_group_id", columnList = "presenter_group_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EventAssignment extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    Event event;

    @Enumerated(EnumType.STRING)
    @Column(name = "assignment_type", nullable = false, length = 20)
    EventAssignmentType assignmentType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "presenter_student_id")
    User presenterStudent;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "presenter_group_id")
    ProjectGroup presenterGroup;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reviewer_student_id", nullable = false)
    User reviewerStudent;

    @Column(name = "order_index", nullable = false)
    Integer orderIndex;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    EventAssignmentStatus status = EventAssignmentStatus.PENDING;
}
