## Students & their marks

### I. Introduction

Dataset included much information about students such as name, batch name, marks, sessions, and their instructors.

### II. Dataset:

The dataset includes multiple tables.

1. **users**: name(user name), active(boolean to check if user is active)
2. **batches**: name(batch name), active(boolean to check if batch is active)
3. **student_batch_maps**: this table is a mapping of the student and his batch. deactivated_at is the time when a student is made inactive in a batch.
4. **instructor_batch_maps**: this table is a mapping of the instructor and the batch he has been assigned to take class/session.
5. **sessions**: Every day session happens where the teacher takes a session or class of students.
6. **attendances**: After session or class happens between teacher and student, attendance is given by student. students provide ratings to the teacher.
7. **tests**: Test is created by instructor. total_mark is the maximum marks for the test.
8. **test_scores**: Marks scored by students are added in the test_scores table.

### Language: PostgresSQL

### List of queries

1. Calculate the average rating given by students to each teacher for each session created. Also, provide the batch name for which session was conducted.
2. Find the attendance percentage for each session for each batch. Also mention the batch name and users name who has conduct that session.
3. What is the average marks scored by each student in all the tests the student had appeared?
4. A student is passed when he scores 40 percent of total marks in a test. Find out how many students passed in each test. Also mention the batch name for that test.
5. A student can be transferred from one batch to another batch.
   If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
   At a time, one student can be active in one batch only.
   One Student can not be transferred more than four times.
   Calculate each students attendance percentage for all the sessions created for his past batch.
   Consider only those sessions for which he was active in that past batch.
6. What is the average percentage of marks scored by each student in all the tests the student had appeared?
7. A student is passed when he scores 40 percent of total marks in a test. Find out how many percentage of students have passed in each test. Also mention the batch name for that test.
8. A student can be transferred from one batch to another batch.
   If he is transferred from batch a to batch b. batch b’s active=true and batch a’s active=false in student_batch_maps.
   At a time, one student can be active in one batch only.
   One Student can not be transferred more than four times.
   Calculate each students attendance percentage for all the sessions.
9. Find students who transferred from one batch to another batch. Also mention the batch name and users name of the students.
10. A student is passed when he scores 40 percent of total marks in a test. Find students who failed in a test. Also mention the batch name and user name for that test.
