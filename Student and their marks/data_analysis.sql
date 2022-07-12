SELECT * FROM users;

SELECT * FROM batches; 

SELECT * FROM student_batch_maps; -- this table is a mapping of the student and his batch. 
-- deactivated_at is the time when a student is made inactive in a batch.

SELECT * FROM instructor_batch_maps;
-- this table is a mapping of the instructor and the batch he has been assigned to take class/session.

SELECT * FROM sessions;
-- Every day session happens where the teacher takes a session or class of students.

SELECT * FROM attendances;
-- After session or class happens between teacher and student, 
-- attendance is given by student. students provide ratings to the teacher.

SELECT * FROM tests;
-- Test is created by instructor. total_mark is the maximum marks for the test.

SELECT * FROM test_scores;
-- Marks scored by students are added in the test_scores table.

-- LIST OF QUERIES

/*
1. Calculate the average rating given by students to each teacher for each session created. 
Also, provide the batch name for which session was conducted.
*/
SELECT
    a.session_id,
    b.name AS batch_name,
--     u.name AS teacher,
    ROUND(AVG(a.rating)::decimal, 2) AS avg_rating
FROM attendances a
    JOIN sessions s ON a.session_id = s.id
    JOIN batches b ON s.batch_id = b.id
--     JOIN users u ON s.conducted_by = u.id
GROUP BY
    a.session_id,
    b.name
ORDER BY 1
;


/*
2. Find the attendance percentage for each session for each batch. 
Also mention the batch name and users name who has conduct that session.
*/
-- pct = (value/total_value) * 100
-- s1. Find total_students who attended each session -- value
-- s2. Find total_students who were supposed to be present for each session -- total_value
-- s3. calculate pct
WITH
    batch_students AS
    (
        SELECT
            batch_id,
            name,
            COUNT(user_id) AS students_per_batch
        FROM student_batch_maps sbm
            JOIN batches b ON sbm.batch_id = b.id
        WHERE sbm.active = true
        GROUP BY sbm.batch_id, name
        ORDER BY sbm.batch_id
    ),
    session_students AS
    (
        SELECT
            session_id,
            COUNT(student_id) AS students_attended
        FROM attendances a
            JOIN sessions s ON a.session_id = s.id
        WHERE (a.student_id, s.batch_id) NOT IN (SELECT user_id, batch_id
                                                 FROM student_batch_maps
                                                 WHERE active = false)
        GROUP BY session_id
        ORDER BY session_id
    )
SELECT
    st.session_id,
    b.name,
    students_per_batch,
    students_attended,
    ROUND(students_attended::decimal / students_per_batch * 100, 2) AS pct
FROM sessions s
    JOIN batch_students b USING (batch_id)
    JOIN session_students st ON s.id = st.session_id
ORDER BY st.session_id
;


-- 3. What is the average marks scored by each student in all the tests the student had appeared?
SELECT
    user_id,
    name,
    ROUND(AVG(score), 2) AS avg_score
FROM test_scores ts
    JOIN users u ON ts.user_id = u.id
GROUP BY user_id, name
ORDER BY user_id
;


/*
4. A student is passed when he scores 40 percent of total marks in a test.
Find out how many students passed in each test. Also mention the batch name for that test.
*/ 
SELECT
    ts.test_id,
    b.name AS batch_name,
    COUNT(user_id) AS students_passed
FROM tests t
    LEFT JOIN test_scores ts ON t.id = ts.test_id
    JOIN batches b ON t.batch_id = b.id
WHERE (score::decimal / total_mark * 100) >= 40
GROUP BY
    ts.test_id,
    b.name
ORDER BY ts.test_id
;


/*
5. A student can be transferred from one batch to another batch. 
If he is transferred from batch a to batch b. 
batch b’s active=true and batch a’s active=false in student_batch_maps.
At a time, one student can be active in one batch only. 
One Student can not be transferred more than four times. 
Calculate each students attendance percentage for all the sessions created for his past batch. 
Consider only those sessions for which he was active in that past batch.
*/
-- pct = (value/total_value) * 100
-- s1. For each student, find total_sessions -- total_value
-- s1. For each student, find total_sessions_attended -- value
-- Calculate pct
WITH
    total_sessions_per_student_id AS
    (
        SELECT
            user_id AS student_id,
            COUNT(s.id) AS total_sessions
        FROM student_batch_maps sbm
            JOIN sessions s USING (batch_id)
        WHERE sbm.active = false
        GROUP BY user_id
        ORDER BY user_id
    ),
    sessions_attended AS
    (
        SELECT
            a.student_id,
            s.batch_id,
            COUNT(a.session_id) AS total_sessions_attended
        FROM attendances a
            JOIN sessions s ON a.session_id = s.id
        WHERE (a.student_id, s.batch_id) IN (SELECT
                                                user_id,
                                                batch_id
                                             FROM student_batch_maps
                                             WHERE active = false
                                            )
        GROUP BY 1, 2
        ORDER BY 1
    )
SELECT
    student_id,
    u.name,
    total_sessions,
    total_sessions_attended,
    ROUND(total_sessions_attended::decimal / total_sessions * 100, 2) AS pct
FROM total_sessions_per_student_id t
    LEFT JOIN sessions_attended USING (student_id)
    JOIN users u ON t.student_id = u.id
;


/*
6. What is the average percentage of marks scored by each student 
in all the tests the student had appeared?
*/
-- s1. For each student, each test, find marks_pct = score / total_mark * 100
-- s2. For each student, find avg_marks_pct
WITH
    marks_pct_per_student AS
    (
        SELECT
            user_id AS student_id,
            ts.test_id,
            score,
            total_mark,
            ROUND(score::decimal / total_mark * 100, 2) AS marks_pct
        FROM test_scores ts
            JOIN tests t ON ts.test_id = t.id
        ORDER BY 1
    )
SELECT
    student_id,
    u.name,
    ROUND(AVG(marks_pct) ,2) AS avg_marks_pct
FROM marks_pct_per_student m
    JOIN users u ON m.student_id = u.id
GROUP BY student_id, u.name
ORDER BY student_id
;


/*
7. A student is passed when he scores 40 percent of total marks in a test. 
Find out how many percentage of students have passed in each test. 
Also mention the batch name for that test.
*/
-- pct = (students_passed / students_attended) * 100
-- s1. Find total_students attended in each test -- students_attended
-- s2. Find total_students passed in each test -- students_passed
-- s3. Calculate pct
WITH
    students_attended_per_test AS
    (
        SELECT
            test_id,
            COUNT(user_id) AS students_attended
        FROM test_scores
        GROUP BY test_id
        ORDER BY test_id
    ),
    students_passed_per_test AS
    (
        SELECT
            test_id,
            b.name,
            COUNT(user_id) AS students_passed
        FROM test_scores ts
            JOIN tests t ON ts.test_id = t.id
            JOIN batches b ON t.batch_id = b.id
        WHERE ROUND(score::decimal / total_mark * 100) >= 40
        GROUP BY test_id, b.name
    )
SELECT
    test_id,
    name AS batch_name,
    students_attended,
    students_passed,
    ROUND(students_passed::decimal / students_attended * 100, 2) AS students_passed_pct
FROM students_attended_per_test sa
    JOIN students_passed_per_test sp USING (test_id)
ORDER BY test_id
;


/* 
8. A student can be transferred from one batch to another batch. 
If he is transferred from batch a to batch b. 
batch b’s active=true and batch a’s active=false in student_batch_maps.
At a time, one student can be active in one batch only. 
One Student can not be transferred more than four times.
Calculate each students attendance percentage for all the sessions.
*/
-- pct = total_sessions_attended / total_sessions_present * 100
-- s1. For each student, find total_sessions_present which they were supposed to be present
-- s2. For each student, find total_sessions_attended which they really attended
-- s3. Calculate pct
WITH
    total_sessions_present_per_student AS
    (
        SELECT
            user_id AS student_id,
            u.name,
            COUNT(s.id) AS total_sessions_present
        FROM student_batch_maps sbm
            JOIN sessions s USING (batch_id)
            LEFT JOIN users u ON user_id = u.id
        WHERE sbm.active = true
        GROUP BY user_id, u.name
        ORDER BY user_id
    ),
    total_sessions_attended_per_student AS
    (
        SELECT
            student_id,
            COUNT(session_id) AS total_sessions_attended
        FROM attendances a
            JOIN sessions s ON a.session_id = s.id
        WHERE (student_id, batch_id) NOT IN (
                                            SELECT user_id, batch_id
                                            FROM student_batch_maps
                                            WHERE active = false)
        GROUP BY student_id
    )
SELECT
    student_id,
    ts.name,
    total_sessions_present,
    total_sessions_attended,
    ROUND(COALESCE(total_sessions_attended::decimal / total_sessions_present, 0) * 100, 2) AS attend_pct
FROM total_sessions_present_per_student ts
    LEFT JOIN total_sessions_attended_per_student ta USING (student_id)
ORDER BY student_id
;


/*
9. Find students who transferred from one batch to another batch.
Also mention the batch name and users name of the students.
*/
SELECT
    active.user_id,
    u.name AS name,
    b.name AS batch_name,
    inactive.batch_id AS inactive_batch,
    active.batch_id AS active_batch
FROM student_batch_maps active
    JOIN student_batch_maps inactive USING (user_id)
    JOIN users u ON active.user_id = u.id
    JOIN batches b ON active.batch_id = b.id
WHERE active.active = true AND inactive.active = false
;

/*
10. A student is passed when he scores 40 percent of total marks in a test.
Find students who failed in a test.  Also mention the batch name and user name for that test.
*/
SELECT
    ts.user_id,
    u.name,
    b.name AS batch_name,
    score,
    total_mark,
    ROUND(score::decimal / total_mark * 100, 2) AS pct_of_total_marks
FROM test_scores ts
    JOIN tests t ON ts.test_id = t.id
    JOIN users u ON ts.user_id = u.id
    JOIN batches b ON t.batch_id = b.id
WHERE (score::decimal / total_mark * 100) < 40
;