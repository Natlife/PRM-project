-- SQL Script to Insert 10 Students into Flipped Classroom App (prm_project)
USE prm_project;

-- 1. Insert 10 student users into the 'users' table
-- Passwords are set to the BCrypt hash of 'student123': $2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje
-- Role ID for student is 3 (ROLE_STUDENT)
INSERT INTO users (id, user_name, email, password, full_name, phone, institutional_id, active, role_id) VALUES
  (4, 'student1', 'student1@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Nguyen Van A', '0912345601', 'HE160001', TRUE, 3),
  (5, 'student2', 'student2@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Tran Thi B', '0912345602', 'HE160002', TRUE, 3),
  (6, 'student3', 'student3@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Le Van C', '0912345603', 'HE160003', TRUE, 3),
  (7, 'student4', 'student4@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Pham Thi D', '0912345604', 'HE160004', TRUE, 3),
  (8, 'student5', 'student5@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Hoang Van E', '0912345605', 'HE160005', TRUE, 3),
  (9, 'student6', 'student6@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Vu Thi F', '0912345606', 'HE160006', TRUE, 3),
  (10, 'student7', 'student7@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Ngo Van G', '0912345607', 'HE160007', TRUE, 3),
  (11, 'student8', 'student8@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Do Thi H', '0912345608', 'HE160008', TRUE, 3),
  (12, 'student9', 'student9@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Bui Van I', '0912345609', 'HE160009', TRUE, 3),
  (13, 'student10', 'student10@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Dang Thi K', '0912345610', 'HE160010', TRUE, 3);

-- 2. Enroll all 10 students into the default classroom PRM393 (classroom_id = 1)
INSERT INTO classroom_enrollments (classroom_id, student_id, status) VALUES
  (1, 4, 'ACTIVE'),
  (1, 5, 'ACTIVE'),
  (1, 6, 'ACTIVE'),
  (1, 7, 'ACTIVE'),
  (1, 8, 'ACTIVE'),
  (1, 9, 'ACTIVE'),
  (1, 10, 'ACTIVE'),
  (1, 11, 'ACTIVE'),
  (1, 12, 'ACTIVE'),
  (1, 13, 'ACTIVE');
