-- Phase 3: Project Groups, Milestones, and Peer Reviews

CREATE TABLE project_groups (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    classroom_id BIGINT NOT NULL,
    group_name VARCHAR(100) NOT NULL,
    project_name VARCHAR(255),
    description TEXT,
    leader_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_groups_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    CONSTRAINT fk_project_groups_leader FOREIGN KEY (leader_id) REFERENCES users(id),
    CONSTRAINT uk_classroom_group_name UNIQUE (classroom_id, group_name)
);

CREATE TABLE project_members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_group_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    member_role VARCHAR(50),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_members_group FOREIGN KEY (project_group_id) REFERENCES project_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_members_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT uk_group_student UNIQUE (project_group_id, student_id)
);

CREATE TABLE project_milestones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_group_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_at DATETIME,
    progress_percent INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_milestones_group FOREIGN KEY (project_group_id) REFERENCES project_groups(id) ON DELETE CASCADE,
    CONSTRAINT chk_milestone_progress CHECK (progress_percent BETWEEN 0 AND 100)
);

CREATE TABLE milestone_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    milestone_id BIGINT NOT NULL,
    uploaded_by BIGINT NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    size_bytes BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_milestone_attachments_milestone FOREIGN KEY (milestone_id) REFERENCES project_milestones(id) ON DELETE CASCADE,
    CONSTRAINT fk_milestone_attachments_user FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

CREATE TABLE peer_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    classroom_id BIGINT NOT NULL,
    reviewer_student_id BIGINT NOT NULL,
    reviewed_group_id BIGINT NOT NULL,
    code_quality_score INT NOT NULL,
    ui_ux_score INT NOT NULL,
    feature_score INT NOT NULL,
    presentation_score INT NOT NULL,
    comment TEXT,
    submitted_at DATETIME,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_peer_reviews_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    CONSTRAINT fk_peer_reviews_reviewer FOREIGN KEY (reviewer_student_id) REFERENCES users(id),
    CONSTRAINT fk_peer_reviews_group FOREIGN KEY (reviewed_group_id) REFERENCES project_groups(id),
    CONSTRAINT uk_reviewer_group UNIQUE (reviewer_student_id, reviewed_group_id),
    CONSTRAINT chk_code_quality CHECK (code_quality_score BETWEEN 1 AND 5),
    CONSTRAINT chk_ui_ux CHECK (ui_ux_score BETWEEN 1 AND 5),
    CONSTRAINT chk_feature CHECK (feature_score BETWEEN 1 AND 5),
    CONSTRAINT chk_presentation CHECK (presentation_score BETWEEN 1 AND 5)
);

CREATE INDEX idx_project_groups_classroom ON project_groups(classroom_id);
CREATE INDEX idx_project_members_group ON project_members(project_group_id);
CREATE INDEX idx_project_members_student ON project_members(student_id);
CREATE INDEX idx_project_milestones_group ON project_milestones(project_group_id);
CREATE INDEX idx_peer_reviews_classroom ON peer_reviews(classroom_id);
CREATE INDEX idx_peer_reviews_reviewer ON peer_reviews(reviewer_student_id);
CREATE INDEX idx_peer_reviews_group ON peer_reviews(reviewed_group_id);
