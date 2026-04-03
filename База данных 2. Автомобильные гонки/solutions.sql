-- Задача 1
-- Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках, 
-- и вывести информацию о каждом таком автомобиле для данного класса, включая его класс, среднюю позицию
-- и количество гонок, в которых он участвовал. 
-- Также отсортировать результаты по средней позиции.
select 
    car_name,
    car_class,
    average_position,
    race_count
from (
    select 
        c.name car_name,
        c.class car_class,
        avg(r.position) average_position,
        count(r.race) race_count,
        min(avg(r.position)) over (partition by c.class) min_avg_pos
    from cars c
    join results r on c.name = r.car
    group by c.name, c.class
) stats
where average_position = min_avg_pos
order by average_position;

-- Задача 2
-- Определить автомобиль, который имеет наименьшую среднюю позицию в гонках среди всех автомобилей,
-- и вывести информацию об этом автомобиле, включая его класс, среднюю позицию,
-- количество гонок, в которых он участвовал, и страну производства класса автомобиля.
-- Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию,
-- выбрать один из них по алфавиту (по имени автомобиля).
select
    c.name car_name,
    c.class car_class,
    avg(r.position) average_position,
    count(r.race) race_count,
    cls.country car_country
from cars c
join results r on c.name = r.car
join classes cls on c."class" = cls."class"
group by c.name, c.class, cls.country
order by average_position, name
limit 1

-- Задача 3
-- Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках,
-- и вывести информацию о каждом автомобиле из этих классов, включая его имя, среднюю позицию,
-- количество гонок, в которых он участвовал, страну производства класса автомобиля,
-- а также общее количество гонок, в которых участвовали автомобили этих классов.
-- Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
with car_stats as (
    select 
        c.name car_name,
        c.class car_class,
        avg(r.position) average_position,
        count(r.race) race_count,
        cls.country car_country
    from cars c
    join results r on c.name = r.car
    join classes cls on c.class = cls.class
    group by c.name, c.class, cls.country
),
class_avg as (
    select 
        car_class,
        avg(average_position) class_avg_position
    from car_stats
    group by car_class
)
select 
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cs.car_country,
    sum(cs.race_count) over (partition by cs.car_class) total_races
from car_stats cs
where cs.car_class in (
	select car_class from class_avg 
	where class_avg_position = (select min(class_avg_position) from class_avg)
)
order by cs.average_position;

-- Задача 4
-- Определить, какие автомобили имеют среднюю позицию лучше (меньше) средней позиции всех автомобилей в своем классе 
-- (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них). 
-- Вывести информацию об этих автомобилях, включая их имя, класс, среднюю позицию, количество гонок, в которых они участвовали, 
-- и страну производства класса автомобиля. Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
with car_results as (
	select
		c.name,
		cls.class,
		avg(r.position) car_avg_pos,
		count(r) car_race_count,
		cls.country
	from results r
	join cars c on r.car = c."name"
	join classes cls on c."class" = cls."class"
	group by c.name, cls.class, cls.country 
),
car_class_results as (
	select
		name,
		class,
		avg(car_avg_pos) over (partition by class) class_avg_pos,
		car_avg_pos,
		car_race_count,
		country
	from car_results
)
select
	name car_name,
	class car_class,
	car_avg_pos average_position,
	car_race_count race_count,
	country car_country
from car_class_results
where car_avg_pos < class_avg_pos


-- Задача 5
--Определить, какие классы автомобилей имеют наибольшее количество автомобилей с низкой средней позицией (больше 3.0) 
--и вывести информацию о каждом автомобиле из этих классов, включая его имя, класс, среднюю позицию, количество гонок, в которых он участвовал, 
--страну производства класса автомобиля, а также общее количество гонок для каждого класса. 
--Отсортировать результаты по количеству автомобилей с низкой средней позицией.
with car_stats as (
    select
        c.name as car_name,
        c.class as car_class,
        avg(r.position * 1.0) as average_position,
        count(r.race) as race_count
    from cars c
    join results r on r.car = c.name
    group by c.name, c.class
),
class_race_stats as (
    select
        c.class,
        count(r.race) as total_races
    from cars c
    left join results r on r.car = c.name
    group by c.class
),
class_car_counts as (
    select
        class,
        count(*) as low_position_count
    from cars
    group by class
)
select
    cs.car_name,
    cs.car_class,
    round(cs.average_position, 4) as average_position,
    cs.race_count,
    cl.country as car_country,
    crs.total_races,
    ccc.low_position_count
from car_stats cs
join classes cl on cl.class = cs.car_class
join class_race_stats crs on crs.class = cs.car_class
join class_car_counts ccc on ccc.class = cs.car_class
where cs.average_position > 3.0
order by ccc.low_position_count desc, cs.car_name;
