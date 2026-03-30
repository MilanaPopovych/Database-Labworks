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
1. Запити з агрегатними функціями (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`, `GROUP BY`) 
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
В цьому запиті використовується агрегатна функція `AVG` для знаходження середнього балу всіх студентів
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
	select min(e2.grade)
	from enrollment e2
	join student s2 on e2.student_id = s2.student_id
	join student_group g2 on s2.group_id = g2.group_id
	where g2.group_name like 'ІО-4%'
);
```

У цьому запиті використана агрегатна функція `MIN` для знаходження абсолютного мінімуму та вкладений запит для пошуку мінімальної оцінки серед потоку IO-4X. Також, необхідно знайти інформацію про дисципліну, з якої було виведено найнижчий бал (`c.course_name`), що виводиться в окремому стовпчику таблиці. 
В підзапиті використовуються змінені псевдоніми для таблиць для відокремлення контексту підзапита від зовнішьного запиту.

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
що визначає старшого студента за різницею сьогоднішньої дати та дати народження. Для цієї задачі також підходить використання функції `MIN` – в цьому випадку, за результатом вибірки було би обрано "найранішу" дату народження з усього університету. 

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

student <--- student_id ---> enrollment <--- course_id ---> course

`ORDER BY` використовується для впорядкування оцінок за спаданням (за замовчуванням, функція впорядкування `ORDER BY` сортує дані за зростанням).

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

На відміну від інших видів join, `FULL JOIN` об'єднує всі рядки з вибраних таблиць, незалежно від того, чи є в них відповідники. Наприклад, запит
```sql
from student s
full join enrollment e on s.student_id = e.student_id
```
виводить таблицю всіх студентів (і тих, що без оцінок) та всіх оцінок (навіть якщо вони належать видаленим студентам). Так само з наступними рядками:
- `full join student_group g on s.group_id = g.group_id` додає до списку всі групи (і ті, що без студентів);
- `full join course c on e.course_id = c.course_id` додає до списку всі курси (і ті, на які ще не записався жоден студент).

Кінцева фільтрація `WHERE` задає умову для виводу наступних рядків: 
- `s.status = 'навчається'` – групи, в яких є активні студенти, що записані на курси 
- `s.student_id is null` – групи, в яких немає студентів (наприклад, 'ІМ-41')
- `c.course_id is null` – групи, в яких є активні студенти, але ще не обрали жодного предмета.

В результаті, таблиця містить групи: 1) в яких є активні студенти, що мають оцінки з предметів; 2) в яких немає студентів; 3) в яких є активні студенти, які
не мають оцінок з предметів. Список груп та студентів впорядкований згідно з інформацією про внесені оцінки (таблиця `enrollment`).

Результат:

![full_join_all_students.png](img/2/full_join_all_students.png)

---

```sql
-- RIGHT JOIN: вивести усі групи, в тому числі ті, що без студентів
select g.group_name, s.first_name || ' ' || s.second_name as name_surname
from student s
right join student_group g ON s.group_id = g.group_id;
```

Цей запит схожий на попередній, проте він не об'єднує рядки таблиці `course` та `enrollment` з іншими. Тут лише треба вивести таблицю з групами, які як мають активних студентів (тих, що 'навчаються'), так і не мають (жодного студента чи всі 'відраховані' тощо). В випадку з `RIGHT JOIN`, таблиця `student_group g` є пріоритетною, тобто незалежно від того, чи містить вона студентів, групи з неї все одно будуть записані в таблицю в результаті. Якщо в якійсь групі немає студентів, то в колонці `name_surname` буде `[null]`, а назва самої групи збережеться.

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

Для задачі знаходження групи/груп з найвищим середнім балом за загальноуніверситетський було написано вибірку з підзапитом в `HAVING`.
В підзапиті `select avg(grade) from enrollment` здійснюється підрахунок середнього балу всіх студентів з усіх предметів, які є в таблиці оцінок, а потім виконується підрахунок середнього балу студентів із кожної групи, що порівнюється з загальним середнім балом. Наприклад, середній бал – 86.25, тож в кінцевому результаті буде інформація лише про ті групи, в яких загальний середній бал вище за 86.25

Результат:

![having_highest_avg_grade.png](img/3/having_highest_avg_grade.png)

---

```sql
-- Знайти факультети, де середня к-сть кредитів на один курс вища за середню
select f.faculty_name, round(avg(c.credits), 2) as avg_course_credits
from course c 
join faculty f on c.faculty_id = f.faculty_id
group by f.faculty_id, f.faculty_name
having avg(c.credits) > (select avg(credits) from course);
```

Аналогічно до попередньої задачі, тут шукаються факультети з більшою кількістю кредитів для їхніх дисциплін. В підзапиті `select avg(credits) from course` знаходиться середнє значення кредитів дисциплін усіх факультетів (з таблиці `course`) – наприклад, 4.4 . В зовнішьному запиті обраховуються кредити дисциплін кожного факультету та зіставляються з загальним середнім значенням 4.4 .

Таблиця дисциплін `course`:

| course_id | course_name | credits | student_year | is_active | faculty_id | 
|-----------|-------------|---------|--------------|-----------|------------|
| 1 | Організація баз даних | 4 | 2 | true | 1 |
| 2 | Вища математика-2 | 4 | 1 | false | 2 |
| 3 | Вища математика-3 | 4 | 2 | false | 2 |
| 4 | Інженерія програмного забезпечення | 5 | 2 | true | 1 |
| 5 | Теорія електричних кіл та сигналів | 5 | 2 | false | 3 |

З цього можна порахувати середнє значення кредитів для кожного факультету:

| faculty_id | Курси | Середнє значення кредитів | 
|-----------|-------|---------------------------|
| 1 | Організація баз даних, Інженерія програмного забезпечення | (4+5)/2 = 4.5 | 
| 2 | Вища математика-2, Вища математика-3  | (4+4)/2 = 4 | 
| 3 | Теорія електричних кіл та сигналів | 5/1 = 5 | 

Отже, в результаті будуть записані лише факультети Інформатики та обчислювальної техніки (`faculty_id = 1`) та Електроенерготехніки та автоматики (`faculty_id = 3`)

Результат:

![having_avg_course_credits.png](img/3/having_avg_course_credits.png)

---

```sql
-- Знайти та вивести інформацію про групу, в якій навчається студент Шеремета Артем
select
    g.group_name,
    g.curator_name,
    s.first_name || ' ' || s.second_name as name_surname,
    s.status
from student s
join student_group g on s.group_id = g.group_id
where s.group_id = (select s2.group_id from student s2
	where s2.first_name = 'Артем' and s2.second_name = 'Шеремета'
);
```

Для задачі пошуку інформації про групу, в якій навчається конкретний студент, використовується вибірка з підзапитом. В підзапиті використовуються інші псевдоніми (`s2` для таблиці `student`) задля уникнення конфліктів.

Результат:

![select_where_sheremeta.png](img/3/select_where_sheremeta.png)

---
## Висновки
В ході цієї лабораторної роботи було набуто навички написання аналітичних SQL-запитів та використання агрегатних функцій, фільтрації, групування та об'єднання рядків для вирішення різних задач вибірки даних. Було перевірено запити на коректність виконання та дотримання синтаксису SQL, та підтверджено при тестуванні в pgAdmin 4. 
