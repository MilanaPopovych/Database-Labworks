# Лабораторна робота № 4
# ІО-46 Попович Мілана, Шеремета Артем
## Тема: Аналітичні SQL-запити (OLAP)
---
## Цілі
- Використати агрегатні функції, такі як `COUNT`, `SUM`, `AVG`, `MIN` та `MAX`, для обчислення зведеної статистики з наших даних.
- Написати запити `GROUP BY` для групування рядків за одним або кількома стовпцями та обчислення агрегатів для кожної групи.
- Використати `HAVING` для фільтрації результатів згрупованих запитів на основі агрегованих умов.
- Виконати операції `JOIN` (принаймні `INNER JOIN` та `LEFT JOIN`), щоб об'єднати дані з кількох таблиць.
- Створити об'єднані запити на агрегацію для кількох таблиць, які об'єднують таблиці та створюють згрупований, агрегований вивід.
- Інтерпретувати результати запитів та пояснити, що робить кожен з них.
---
## Результати
1. Запити з агрегаційними функціями (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`, `GROUP BY`) 
```sql
-- SUM: вивести загальну к-сть кредитів дисциплін 4 семестру
select sum(credits) as total_credits_4th_semester
from course
where student_year = 2 and is_active = true;
```
Результат: 

```sql
-- AVG: в групі ІО-46 вивести середній бал з предмету Вища математика-3
select g.group_name, c.course_name, 
	round(avg(e.grade), 2) as avg_maths_grade
from enrollment e
join student s on e.student_id = s.student_id
join student_group g on s.group_id = g.group_id
join course c on e.course_id = c.course_id
where g.group_name = 'IO-46' and c.course_name = 'Вища математика-3'
group by g.group_name, c.course_name;
```
Результат:

```sql
-- MIN: Вивести найнижчий бал з потоку ІО-4х та назву дисципліни
select 
	c.course_name, 
	e.grade as abs_min_grade
from enrollment e 
join course c on e.course_id = c.course_id
join student s on e.student_id = s.student_id
join student_group g on s.group_id = g.group_id 
where g.group_name like 'ІО-4%' and e.grade = (
	select min(e.grade)
	from enrollment e
	join student s on e.student_id = s.student_id
	join student_group g on s.group_id = g.group_id
	where g.group_name like 'ІО-4%'
);
```
Результат:

```sql
-- MAX: вивести інформацію про найстаршого студента 
select
	g.group_name,
	s.first_name || ' ' || s.second_name as name_surname,
	s.birth_date
from student s
join student_group g on s.group_id = g.group_id
where (current_date - s.birth_date) = (
	select max(current_date - birth_date)
	from student
);
```
Результат:

2. Запити з операціями об'єднання таблиць (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, `CROSS JOIN`)

```sql
-- LEFT JOIN: вивести імена, прізвища та групи студентів, у яких немає жодних оцінок
select s.first_name, s.second_name, g.group_name
from student s 
join student_group g on s.group_id = g.group_id
left join enrollment e on s.student_id = e.student_id
where e.student_id is null;
```

Результат:

```sql

```

3. Запити з використанням підзапитів (вибірка з підзапитом в `SELECT`, `WHERE`, `HAVING`)
---
## Висновки
