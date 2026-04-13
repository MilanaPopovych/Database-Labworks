# Лабораторна робота 5: Нормалізація бази даних
# ІО-46 Шеремета Артем, Попович Мілана

## 1. Початковий дизайн таблиць

Для демонстрації процесу нормалізації, припустимо, що до створення поточної ER-діаграми всі дані про успішність студентів та їхні групи зберігалися в одній ненормалізованій зведеній відомості `student_records_draft`.

**Таблиця:** `student_records_draft`
**Стовпці:**
* `student_id` (PK)
* `first_name`
* `second_name`
* `group_name`
* `curator_name` (ПІБ куратора текстом)
* `faculty_name`
* `building`
* `courses_grades` (наприклад: "Організація баз даних: 95, ІПЗ: 94")

**Аналіз проблеми**
Поточна схема не відповідає 1NF, оскільки стовпець `courses_grades` містить множинні значення (повторювані групи) та не є атомарним. Крім того, присутні численні часткові та транзитивні залежності.

---

## 2. Функціональні залежності (ФЗ)

Якщо припустити, що ми розбили `courses_grades` на окремі атрибути `course_id`, `course_name` та `grade` для визначення залежностей, мінімальний набір функціональних залежностей для початкової предметної області буде наступним:

1. **ФЗ 1 (Повна залежність):** `{student_id, course_id} -> {grade}`
   Оцінка залежить виключно від конкретного студента та конкретного курсу.
2. **ФЗ 2 (Часткова залежність):** `student_id -> {first_name, second_name, group_name}`
   Особисті дані студента та його група залежать лише від ідентифікатора студента.
3. **ФЗ 3 (Часткова залежність):** `course_id -> {course_name}`
   *Назва дисципліни залежить лише від ID курсу.*
4. **ФЗ 4 (Транзитивна залежність):** `group_name -> {curator_name, faculty_name, building}`
   Інформація про куратора та факультет залежить від групи, а не безпосередньо від студента.
5. **ФЗ 5 (Транзитивна залежність):** `faculty_name -> {building}`
   Номер корпусу залежить від факультету.

---

## 3. Нормалізація

### 1. Перехід до 1NF. Усунення повторюваних груп
* **Проблема:** Поле `courses_grades` порушує вимогу атомарності атрибутів.
* **Рішення:** Розбиваємо множинне поле на окремі рядки. Тепер кожен запис містить лише один курс та одну оцінку. Первинний ключ стає складеним: `(student_id, course_id)`.
* **Результат (Таблиця в 1NF):** `student_1nf(student_id, course_id, first_name, second_name, group_name, curator_name, faculty_name, building, course_name, grade)`

### 2. Перехід до 2NF. Усунення часткових залежностей
* **Проблема:** Неключові атрибути (наприклад, `first_name` або `course_name`) залежать лише від частини складеного ключа (ФЗ 2 та ФЗ 3).
* **Рішення:** Декомпозуємо таблицю на три нові. Дані про студентів, дані про курси та таблицю зв'язку для оцінок.
* **Результат (Таблиці в 2NF):**
  * `students_2nf` (Ключ: `student_id`): `first_name, second_name, group_name, curator_name, faculty_name, building`
  * `courses_2nf` (Ключ: `course_id`): `course_name`
  * `enrollment` (Складений ключ: `student_id, course_id`): `grade`

### 3. Перехід до 3NF. Усунення транзитивних залежностей
* **Проблема:** У таблиці `students_2nf` атрибути `faculty_name` та `building` залежать від `group_name` (ФЗ 4, ФЗ 5). Також наявна аномалія оновлення: `curator_name` зберігається як звичайний текст, що дублює сутність викладача і може призвести до невідповідностей при зміні куратора.
* **Рішення:** Виокремлюємо факультети та групи у власні таблиці. Заміняємо текстове поле `curator_name` на зовнішній ключ `curator_id`, який посилається на таблицю викладачів (`teacher`).
* **Результат (Фінальні таблиці в 3NF):**
  * `faculty` (Ключ: `faculty_id`): `faculty_name, building`
  * `teacher` (Ключ: `teacher_id`): `first_name, second_name...`
  * `student_group` (Ключ: `group_id`): `group_name, start_year, faculty_id, curator_id`
  * `student` (Ключ: `student_id`): `first_name, second_name, group_id...`

---

## 4. Трансформація структури (ALTER TABLE)

Після декомпозиції початкової ненормалізованої сутності на окремі таблиці (`faculty`, `teacher`, `student_group`, `student`), ми використовуємо команди `alter table` для встановлення зв'язків та обмежень цілісності.

### Таблиця student_group
```sql
-- видаляємо старе текстове поле
alter table student_group drop column if exists curator_name;

-- додаємо зовнішній ключ на таблицю викладачів
alter table student_group 
add column curator_id int,
add constraint fk_group_curator 
foreign key (curator_id) references teacher(teacher_id) 
on delete set null;
```

### Таблиця student
```sql
-- переконуємося, що тип даних збігається з первинним ключем у student_group
alter table student 
add constraint fk_student_group 
foreign key (group_id) references student_group(group_id);
```

### Таблиця teacher
```sql
alter table teacher 
add constraint fk_teacher_faculty 
foreign key (faculty_id) references faculty(faculty_id);
```
Прив'язуємо викладача до факультету (усунення аномалій приналежності)

### Таблиця course

```sql
alter table course 
add constraint chk_credits check (credits > 0 and credits < 60),
add constraint fk_course_faculty foreign key (faculty_id) references faculty(faculty_id);
```
Додаємо обов'язкову перевірку для кредитів та прив'язку до факультету

---

## 5. Перероблений дизайн таблиць (SQL)

Нижче наведено команди створення (`CREATE TABLE`) для переглянутої схеми у 3NF. В таблиці `student_group` видалено текстове поле куратора і додано зовнішній ключ `curator_id`.

```sql
create table faculty (
    faculty_id serial primary key,
    faculty_name varchar(100) not null,
    building smallint
);

create table teacher (
    teacher_id serial primary key,
    first_name varchar(25) not null,
    second_name varchar(35) not null,
    phone_number char(13) not null,
    email varchar(64) unique not null,
    job teacher_role,
    status teacher_status not null,
    faculty_id int not null references faculty(faculty_id)
);

-- нормалізована 3NF таблиця: додано curator_id замість curator_name
create table student_group (
    group_id serial primary key,
    group_name char(7) not null check (group_name like '__-%'),
    start_year smallint not null check (start_year >= 1898),
    curator_id int references teacher(teacher_id) on delete set null,
    faculty_id int not null references faculty(faculty_id)
);

create table student (
    student_id serial primary key,
    first_name varchar(25) not null,
    second_name varchar(35) not null,
    birth_date date not null,
    start_date date,
    end_date date,
    phone_number char(13) not null,
    email varchar(64) unique not null,
    course int check(course >= 1 and course <= 6),
    status student_status not null,
    form_of_study student_form_of_study,
    finance_source student_finance_source,
    group_id int not null references student_group(group_id)
);
```

### ER-діаграма оновленої бази даних

---

## Висновки
У ході виконання лабораторної роботи було проведено повний цикл нормалізації бази даних навчального закладу до нормальної форми 3NF. Було виявлено та формалізовано повні, часткові та транзитивні залежності, що дозволило чітко зрозуміти логічну структуру даних та ідентифікувати слабкі місця початкового дизайну. В результаті було розроблено DDL-скрипт та забезпечено цілісність даних через систему зовнішніх ключів.
