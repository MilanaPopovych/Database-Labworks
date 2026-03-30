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

Даний запит створений для того, щоби підрахувати загалньу кількість кредитів дисциплін 2 курсу 2 семестру, 
тому в ньому міститься перевірка на `is_active = true`, оскільки дисципліни 2 курсу 1 семестру є неактивними
`(is_active = false)`.

Результат:

![sum_credits_4th_semester.png](img/1/sum_credits_4th_semester.png)

---

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
В цьому запиті використовується агрегаційна функція `AVG` для знаходження середнього балу всіх студентів
групи ІО-46 з дисципліни "Вища математика-3". Наприклад, оцінки студентів наступні:
| Прізвище, Ім'я | Оцінка |
|----------------|---------|
| Попович Мілана | 99 |
| Шеремета Артем | 90 |
| Меджитова Севіль | 88 |

За цими даними, середня оцінка студентів: (99+90+88)/3 ≈ 92,33 – це число збігається з результатом у таблиці

Результат:

![avg_IO-46_maths_grade.png](img/1/avg_IO-46_maths_grade.png)

---

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

У цьому запиті використана агрегаційна функція `MIN` для знаходження абсолютного мінімуму
та вкладений запит для пошуку мінімальної оцінки серед потоку IO-4X. Також, необхідно знайти інформацію 
про дисципліну, з якої було виведено найнижчий бал (`c.course_name`), що виводиться 
в окремому стовпчику таблиці. 

Результат:

![min_abs_minimum_grade.png](img/1/min_abs_minimum_grade.png)

---

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

Функція `MAX` використана в цьому запиті для знаходження найстаршого студента в університеті, 
та містить підзапит:
```sql
where (current_date - s.birth_date) = (
	select max(current_date - birth_date)
	from student
)
```
що визначає старшого студента за різницею сьогоднішньої дати та дати народження. Для цієї задачі
також підходить використання функції `MIN` – в цьому випадку, за результатом вибірки було би 
обрано "найранішу" дату народження з усього університету. 

Результат:

![max_oldest_student.png](img/1/max_oldest_student.png)

---

2. Запити з операціями об'єднання таблиць (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, `CROSS JOIN`)

```sql
-- INNER JOIN: вивести імена, прізвища та оцінки студентів з курсів, де бал більше 80, в порядку спадання
select 
    s.first_name, 
    s.second_name, 
    c.course_name, 
    e.grade
from enrollment e
join student s on e.student_id = s.student_id
join course c on e.course_id = c.course_id
where e.grade > 80
order by e.grade desc;
```

У цьому запиті для знаходження студентів з усього університету, бал яких вище за 80
з будь-яких курсів, використовується об'єднання таблиць (`INNER JOIN`) student, course та
enrollment, оскільки на реляційній схемі вони мають ланцюговий зв'язок:

student <--- FK: student_id ---> enrollment <--- FK: course_id ---> course

`ORDER BY` використовується для впорядкування оцінок за спаданням (за замовчуванням,
функція впорядкування `ORDER BY` сортує дані за зростанням).

Результат:

![inner_join_morethan80.png](img/2/inner_join_morethan80.png)

---

```sql
-- LEFT JOIN: вивести імена, прізвища та групи студентів, у яких немає жодних оцінок
select s.first_name, s.second_name, g.group_name
from student s 
join student_group g on s.group_id = g.group_id
left join enrollment e on s.student_id = e.student_id
where e.student_id is null;
```

Задача полягає в тому, щоби з загального списку студентів вивести інформацію лише про тих, 
що не мають оцінок взагалі. В попередній лабораторній роботі, було використано запит `DELETE` для видалення оцінок відрахованого студента
"Василь Іванов", і нам, наприклад, необхідно вивести інформацію про цього ж студента. Логічне з'єднання таблиць `student s` та `student_group g`
відбувається за виконання умови збігу (значенню `group_id` з таблиці `student` відповідає те ж значення з таблиці `student_group`). З'єднання таблиць
`student` та `enrollment` має такий результат:
- В списку буде кожен студент.
- Якщо немає інформації про оцінки студента в таблиці `enrollment`, то він все одно залишиться в кінцевому списку:

| Ім'я | Прізвище | Група |
|---------- |------|---------|
| Артем | Шеремета | ІО-46 |
| Севіль | Меджитова | ІО-46 |
| Максим | Гаврилюк | ЕК-зп31 |
| Мілана | Попович | ІО-46 |
| Артем | Шеремета | ІО-46 |
| Севіль | Меджитова | ІО-46 |
| Василь | Іванов | ІО-45 |

(*порядок студентів та їхніх груп у цій таблиці збігається з порядком запису їхніх оцінок в таблиці `enrollment`)

В останньому кроці виконується фільтрація: `where e.student_id is null`, тобто всі студенти, які записані на певні курси та мають з них оцінки відсіюються.

Результат:

![left_join_students_without_grades.png](img/2/left_join_students_without_grades.png)

---

```sql
-- FULL JOIN: вивести список усіх активних студентів та курсів, на які вони записані
select 
	g.group_name,
	s.first_name || ' ' || s.second_name as name_surname,
	c.course_name
from student s
full join enrollment e on s.student_id = e.student_id
full join student_group g on s.group_id = g.group_id
full join course c on e.course_id = c.course_id
where s.status = 'навчається' or s.student_id is null or c.course_id is null;
```

Результат:

---

```sql
-- RIGHT JOIN: вивести усі групи, в тому числі ті, що без студентів
select g.group_name, s.first_name || ' ' || s.second_name as name_surname
from student s
right join student_group g ON s.group_id = g.group_id;
```
Результат:

![right_join_all_students.png](img/2/right_join_all_students.png)

---

3. Запити з використанням підзапитів (вибірка з підзапитом в `SELECT`, `WHERE`, `HAVING`)

```sql
-- Знайти групу з найвищим середнім балом з усіх предметів
select g.group_name, round(avg(e.grade), 2) as avg_group_grade
from enrollment e 
join student s on e.student_id = s.student_id
join student_group g on s.group_id = g.group_id
group by g.group_id, g.group_name
having avg(e.grade) > (select avg(grade) from enrollment);
```

Результат:

![having_avg_course_credits.png](img/3/having_avg_course_credits.png)

```sql
-- Знайти факультети, де середня к-сть кредитів на один курс вища за середню
select f.faculty_name, round(avg(c.credits), 2) as avg_course_credits
from course c 
join faculty f on c.faculty_id = f.faculty_id
group by f.faculty_id, f.faculty_name
having avg(c.credits) > (select avg(credits) from course);
```

Результат:

![having_higest_avg_grade.png](img/3/having_higest_avg_grade.png)

```sql
-- Знайти та вивести інформацію про групу, в якій навчається студент Шеремета Артем
select
    g.group_name,
    g.curator_name,
    s.first_name || ' ' || s.second_name as name_surname,
    s.status
from student s
join student_group g on s.group_id = g.group_id
where s.group_id = (select s.group_id from student s
	where s.first_name = 'Артем' and s.second_name = 'Шеремета'
);
```
Результат:

![select_where_sheremeta.png](img/3/select_where_sheremeta.png)

---
## Висновки
