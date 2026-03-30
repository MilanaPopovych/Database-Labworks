-- SELECT: вивести імена, прізвища та пошту всіх викладачів ФІОТу, які зараз викладають
select first_name, second_name, email
from teacher
where faculty_id = 1 and status = 'викладає'; 

-- INSERT: додати новий факультет в корпус № 7 та вивести у порядку зростання номерів корпусу
insert into faculty (faculty_name, building)
values ('Факультет маркетингу та менеджменту', 7);

select * from faculty order by building;

-- DELETE: видалити оцінки студента, який відрахований
delete from enrollment
where student_id = (
	select student_id
	from student
	where status = 'відрахований'
); 

-- UPDATE: перевести учня в академвідпустку
update student
set status = 'академ', course = null, end_date = null
where student_id = 4;