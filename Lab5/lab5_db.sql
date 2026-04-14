drop table if exists course_prerequisite cascade;
drop table if exists enrollment cascade;
drop table if exists course cascade;
drop table if exists student cascade;
drop table if exists student_group cascade;
drop table if exists teacher cascade;
drop table if exists faculty cascade;

drop type if exists student_status cascade;
drop type if exists student_form_of_study cascade;
drop type if exists student_finance_source cascade;
drop type if exists teacher_status cascade;
drop type if exists teacher_role cascade;

create type student_status as enum ('навчається', 'випускник', 'академ', 'відрахований', 'абітурієнт');
create type student_form_of_study as enum ('денна', 'заочна', 'вечірня', 'дистанційна');
create type student_finance_source as enum ('контракт', 'бюджет', 'відпрацювання');
create type teacher_status as enum ('викладає', 'звільнений', 'у відпустці');
create type teacher_role as enum ('асистент', 'старший викладач', 'доцент', 'професор');

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
    start_year smallint not null check (start_year >= 1898)
    /*curator_id int references teacher(teacher_id) on delete set null,
    faculty_id int not null references faculty(faculty_id)*/
);

alter table student_group 
    add column curator_id int references teacher(teacher_id),
    add column faculty_id int not null references faculty(faculty_id),
    add constraint chk_group_name check (group_name like '__-%');

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

create table course (
    course_id serial primary key,
    course_name varchar(60) not null,
    credits smallint not null check (credits > 0 and credits < 100),
    student_year smallint not null check (student_year >= 1 and student_year <= 4),
    is_active boolean not null,
    faculty_id int not null references faculty(faculty_id)
);

alter table course 
    add constraint chk_credits check (credits > 0 and credits < 60);

create table enrollment (
    course_id int not null references course(course_id),
    student_id int not null references student(student_id),
    grade smallint,
    primary key (course_id, student_id)
);

create table course_prerequisite (
    course_id int not null references course(course_id),
    prerequisite_course_id int not null references course(course_id) check (course_id <> prerequisite_course_id),
    primary key (course_id, prerequisite_course_id)
);

insert into faculty (faculty_name, building)
values ('Інформатики та Обчислювальної техніки', 18),
       ('Фізико-математичний', 7),
       ('Електроенерготехніки та автоматики', 20);

insert into teacher (first_name, second_name, phone_number, email, status, job, faculty_id)
values ('Дмитро', 'Дрозд', '+380966787369', 'random.teacher@lll.kpi.ua', 'викладає', 'старший викладач', 1),
       ('Михайло', 'Білоус', '+380668887744', 'workmail@edu.kpi.ua', 'у відпустці', 'доцент', 3),
       ('Костянтин', 'Федоренко', '+380668887733', 'example@lll.kpi.ua', 'звільнений', 'асистент', 2),
       ('Ірина', 'Ковальчук', '+380985554499', 'teacher@edu.kpi.ua', 'викладає', 'старший викладач', 2),
       ('Світлана', 'Меджитова', '+380501112233', 's.medzhytova@edu.kpi.ua', 'викладає', 'доцент', 1),
       ('Ігор', 'Романенко', '+380631112244', 'i.romanenko@edu.kpi.ua', 'викладає', 'старший викладач', 1),
       ('Анна', 'Куц', '+380671112255', 'a.kuts@edu.kpi.ua', 'викладає', 'асистент', 1),
       ('Катерина', 'Коваленко', '+380991112266', 'k.kovalenko@edu.kpi.ua', 'викладає', 'доцент', 3);

insert into student_group (group_name, start_year, curator_id, faculty_id)
values ('ІО-46', 2024, 5, 1),
       ('ІО-45', 2024, 6, 1),
       ('ІМ-41', 2024, 7, 1),
       ('ЕК-зп31', 2023, 8, 3);

insert into student (first_name, second_name, birth_date, start_date, end_date, phone_number, email, course, status, form_of_study, finance_source, group_id)
values ('Артем', 'Шеремета', '2006-08-09', '2024-09-01', null, '+380999867369', 'random.navch@lll.kpi.ua', 2, 'навчається', 'денна', null, 1),
       ('Мілана', 'Попович', '2007-05-18', '2024-09-01', null, '+380983615133', 'example@lll.kpi.ua', 2, 'навчається', 'денна', 'бюджет', 1),
       ('Севіль', 'Меджитова', '2007-11-07', '2024-09-01', null, '+380992007298', 'email@lll.kpi.ua', 2, 'навчається', 'денна', 'бюджет', 1),
       ('Василь', 'Іванов', '2006-11-20', '2024-09-01', '2026-02-02', '+380675552233', 'v.ivanov@lll.kpi.ua', 2, 'відрахований', null, null, 2),
       ('Максим', 'Гаврилюк', '2003-05-03', '2023-09-01', null, '+380657773388', 'student@lll.kpi.ua', 3, 'навчається', 'заочна', 'відпрацювання', 4);

insert into course (course_name, credits, student_year, is_active, faculty_id)
values ('Організація баз даних', 4, 2, true, 1),
       ('Вища математика-2', 4, 1, false, 2),
       ('Вища математика-3', 4, 2, false, 2),
       ('Інженерія програмного забезпечення', 5, 2, true, 1),
       ('Теорія електричних кіл та сигналів', 5, 2, false, 3);

insert into enrollment (course_id, student_id, grade)
values (1, 1, 95), (5, 4, 78), (4, 3, 94), (2, 5, 62), (3, 2, 99), (1, 4, 84), (3, 1, 90), (3, 3, 88);

insert into course_prerequisite (course_id, prerequisite_course_id)
values (3, 2);