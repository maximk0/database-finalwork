-- Задача 1
--Определить, какие клиенты сделали более двух бронирований в разных отелях, 
--и вывести информацию о каждом таком клиенте, включая его имя, электронную почту, телефон, общее количество бронирований, 
--а также список отелей, в которых они бронировали номера (объединенные в одно поле через запятую). 
--Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям. 
--Отсортировать результаты по количеству бронирований в порядке убывания.
select
    c.name,
    c.email,
    c.phone,
    count(*) as total_bookings,
    string_agg(distinct h.name, ', ' order by h.name) as hotels,
    avg(b.check_out_date - b.check_in_date) as avg_stay_days
from customer c
join booking b on b.id_customer = c.id_customer
join room r on r.id_room = b.id_room
join hotel h on h.id_hotel = r.id_hotel
group by c.id_customer, c.name, c.email, c.phone
having count(*) > 2 and count(distinct h.id_hotel) > 1
order by total_bookings desc, c.name;

--Задача 2
--Необходимо провести анализ клиентов, которые сделали более двух бронирований в разных отелях и потратили более 500 долларов на свои бронирования. 
--Для этого:
-- * Определить клиентов, которые сделали более двух бронирований и забронировали номера в более чем одном отеле. 
--   Вывести для каждого такого клиента следующие данные: ID_customer, имя, общее количество бронирований, 
--   общее количество уникальных отелей, в которых они бронировали номера, и общую сумму, потраченную на бронирования.
-- * Также определить клиентов, которые потратили более 500 долларов на бронирования, 
--   и вывести для них ID_customer, имя, общую сумму, потраченную на бронирования, и общее количество бронирований.
-- * В результате объединить данные из первых двух пунктов, чтобы получить список клиентов, которые соответствуют условиям обоих запросов. 
--   Отобразить поля: ID_customer, имя, общее количество бронирований, общую сумму, потраченную на бронирования, и общее количество уникальных отелей.
-- * Результаты отсортировать по общей сумме, потраченной клиентами, в порядке возрастания.
with booking_stats as (
    select
        c.id_customer,
        c.name,
        count(*) as total_bookings,
        count(distinct h.id_hotel) as unique_hotels,
        sum((b.check_out_date - b.check_in_date) * r.price) as total_spent
    from customer c
    join booking b on b.id_customer = c.id_customer
    join room r on r.id_room = b.id_room
    join hotel h on h.id_hotel = r.id_hotel
    group by c.id_customer, c.name
),
multi_hotel_clients as (
    select
        id_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    from booking_stats
    where total_bookings > 2
      and unique_hotels > 1
),
high_spenders as (
    select
        id_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    from booking_stats
    where total_spent > 500
)
select
    m.id_customer,
    m.name,
    m.total_bookings,
    m.total_spent,
    m.unique_hotels
from multi_hotel_clients m
join high_spenders h on h.id_customer = m.id_customer
order by m.total_spent asc;

--Задача 3
--Вам необходимо провести анализ данных о бронированиях в отелях и определить предпочтения клиентов по типу отелей. 
--Для этого выполните следующие шаги:
-- 1. Категоризация отелей.
--    Определите категорию каждого отеля на основе средней стоимости номера:
--      * «Дешевый»: средняя стоимость менее 175 долларов.
--      * «Средний»: средняя стоимость от 175 до 300 долларов.
--      * «Дорогой»: средняя стоимость более 300 долларов.
-- 2. Анализ предпочтений клиентов.
--    Для каждого клиента определите предпочитаемый тип отеля на основании условия ниже:
--      * Если у клиента есть хотя бы один «дорогой» отель, присвойте ему категорию «дорогой».
--      * Если у клиента нет «дорогих» отелей, но есть хотя бы один «средний», присвойте ему категорию «средний».
--      * Если у клиента нет «дорогих» и «средних» отелей, но есть «дешевые», присвойте ему категорию предпочитаемых отелей «дешевый».
-- 3. Вывод информации.
--    Выведите для каждого клиента следующую информацию:
--      * ID_customer: уникальный идентификатор клиента.
--      * name: имя клиента.
--      * preferred_hotel_type: предпочитаемый тип отеля.
--      * visited_hotels: список уникальных отелей, которые посетил клиент.
-- 4. Сортировка результатов.
--    Отсортируйте клиентов так, чтобы сначала шли клиенты с «дешевыми» отелями, затем со «средними» и в конце — с «дорогими».
with hotel_categories as (
    select
        h.id_hotel,
        h.name as hotel_name,
        case
            when avg(r.price) < 175 then 1
            when avg(r.price) <= 300 then 2
            else 3
        end as hotel_type
    from hotel h
    join room r on r.id_hotel = h.id_hotel
    group by h.id_hotel, h.name
),
customer_hotel_types as (
    select distinct
        c.id_customer,
        c.name,
        hc.hotel_name,
        hc.hotel_type
    from customer c
    join booking b on b.id_customer = c.id_customer
    join room r on r.id_room = b.id_room
    join hotel_categories hc on hc.id_hotel = r.id_hotel
),
customer_preferences as (
    select
        id_customer,
        name,
        max(hotel_type) as preferred_hotel_type,
        string_agg(distinct hotel_name, ',' order by hotel_name) as visited_hotels
    from customer_hotel_types
    group by id_customer, name
)
select
    id_customer,
    name,
    case preferred_hotel_type
        when 1 then 'дешевый'
        when 2 then 'средний'
        when 3 then 'дорогой'
    end,
    visited_hotels
from customer_preferences
order by preferred_hotel_type;
