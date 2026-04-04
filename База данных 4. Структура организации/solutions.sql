--Задача 1
--Найти всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1), 
--включая их подчиненных и подчиненных подчиненных, а также самого Ивана Иванова. 
--Для каждого сотрудника вывести следующую информацию:
-- 1. EmployeeID: идентификатор сотрудника.
-- 2. Имя сотрудника.
-- 3. ManagerID: Идентификатор менеджера.
-- 4. Название отдела, к которому он принадлежит.
-- 5. Название роли, которую он занимает.
-- 6. Название проектов, к которым он относится (если есть, конкатенированные в одном столбце через запятую).
-- 7. Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце через запятую).
-- 8. Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
--Требования:
-- * Рекурсивно извлечь всех подчиненных сотрудников Ивана Иванова и их подчиненных.
-- * Для каждого сотрудника отобразить информацию из всех таблиц.
-- * Результаты должны быть отсортированы по имени сотрудника.
-- * Решение задачи должно представлять из себя один sql-запрос и задействовать ключевое слово RECURSIVE.
with recursive subordinates as (
    select
        e.employeeid,
        e.name,
        e.managerid,
        e.departmentid,
        e.roleid
    from employees e
    where e.employeeid = 1

    union all

    select
        e.employeeid,
        e.name,
        e.managerid,
        e.departmentid,
        e.roleid
    from employees e
    join subordinates s on e.managerid = s.employeeid
),
project_names as (
    select
        e.employeeid,
        string_agg(distinct p.projectname, ', ') as projectnames
    from employees e
    left join projects p on p.departmentid = e.departmentid
    group by e.employeeid
),
task_names as (
    select
        t.assignedto,
        string_agg(t.taskname, ', ') as tasknames
    from tasks t
    group by t.assignedto
)
select
    s.employeeid,
    s.name as employeename,
    s.managerid,
    d.departmentname,
    r.rolename,
    pn.projectnames,
    tn.tasknames
from subordinates s
left join departments d on d.departmentid = s.departmentid
left join roles r on r.roleid = s.roleid
left join project_names pn on pn.employeeid = s.employeeid
left join task_names tn on tn.assignedto = s.employeeid
order by s.name;

--Задача 2
--Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, 
--включая их подчиненных и подчиненных подчиненных, а также самого Ивана Иванова. 
--Для каждого сотрудника вывести следующую информацию:
-- 1. EmployeeID: идентификатор сотрудника.
-- 2. Имя сотрудника.
-- 3. Идентификатор менеджера.
-- 4. Название отдела, к которому он принадлежит.
-- 5. Название роли, которую он занимает.
-- 6. Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
-- 7. Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
-- 8. Общее количество задач, назначенных этому сотруднику.
-- 9. Общее количество подчиненных у каждого сотрудника (не включая подчиненных их подчиненных).
-- 10. Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
with recursive subordinates as (
    select
        e.employeeid,
        e.name,
        e.managerid,
        e.departmentid,
        e.roleid
    from employees e
    where e.employeeid = 1

    union all

    select
        e.employeeid,
        e.name,
        e.managerid,
        e.departmentid,
        e.roleid
    from employees e
    join subordinates s on e.managerid = s.employeeid
),
project_names as (
    select
        e.employeeid,
        string_agg(distinct p.projectname, ', ') as projectnames
    from employees e
    left join projects p on p.departmentid = e.departmentid
    group by e.employeeid
),
task_stats as (
    select
        t.assignedto as employeeid,
        string_agg(t.taskname, ', ') as tasknames,
        count(*) as totaltasks
    from tasks t
    group by t.assignedto
),
subordinate_counts as (
    select
        e.managerid,
        count(*)
    from employees e
    where e.managerid is not null
    group by e.managerid
)
select
    s.employeeid,
    s.name as employeename,
    s.managerid,
    d.departmentname,
    r.rolename,
    pn.projectnames,
    ts.tasknames,
    coalesce(ts.totaltasks, 0) as totaltasks,
    coalesce(sc.count, 0) as totalsubordinates
from subordinates s
left join departments d on d.departmentid = s.departmentid
left join roles r on r.roleid = s.roleid
left join project_names pn on pn.employeeid = s.employeeid
left join task_stats ts on ts.employeeid = s.employeeid
left join subordinate_counts sc on sc.managerid = s.employeeid
order by s.name;

--Задача 3
--Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных (то есть число подчиненных больше 0). 
--Для каждого такого сотрудника вывести следующую информацию:
-- 1. EmployeeID: идентификатор сотрудника.
-- 2. Имя сотрудника.
-- 3. Идентификатор менеджера.
-- 4. Название отдела, к которому он принадлежит.
-- 5. Название роли, которую он занимает.
-- 6. Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
-- 7. Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
-- 8. Общее количество подчиненных у каждого сотрудника (включая их подчиненных).
-- 9. Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
with recursive manager_tree as (
    select
        e.employeeid as rootmanagerid,
        e.employeeid as employeeid
    from employees e
    where e.roleid = 1

    union all

    select
        mt.rootmanagerid,
        e.employeeid
    from employees e
    join manager_tree mt on e.managerid = mt.employeeid
),
total_subordinates as (
    select
        rootmanagerid as employeeid,
        count(*) - 1 as totalsubordinates
    from manager_tree
    group by rootmanagerid
),
project_names as (
    select
        e.employeeid,
        string_agg(distinct p.projectname, ', ') as projectnames
    from employees e
    left join projects p on p.departmentid = e.departmentid
    group by e.employeeid
),
task_names as (
    select
        t.assignedto as employeeid,
        string_agg(t.taskname, ', ') as tasknames
    from tasks t
    group by t.assignedto
)
select
    e.employeeid,
    e.name as employeename,
    e.managerid,
    d.departmentname,
    r.rolename,
    pn.projectnames,
    tn.tasknames,
    ts.totalsubordinates
from employees e
join roles r on r.roleid = e.roleid
left join departments d on d.departmentid = e.departmentid
left join project_names pn on pn.employeeid = e.employeeid
left join task_names tn on tn.employeeid = e.employeeid
join total_subordinates ts on ts.employeeid = e.employeeid
where e.roleid = 1
  and ts.totalsubordinates > 0
order by e.name;
