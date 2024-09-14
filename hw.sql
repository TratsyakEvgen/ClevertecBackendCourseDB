-- Вывести к каждому самолету класс обслуживания
-- и количество мест этого класса

select seats.aircraft_code, model, fare_conditions, count(seat_no)
from aircrafts_data
         join seats on aircrafts_data.aircraft_code = seats.aircraft_code
group by seats.aircraft_code, model, fare_conditions;

-- Найти 3 самых вместительных самолета (модель + кол-во мест)

select *
from aircrafts_data
         join (select aircraft_code, count(seat_no) from seats group by aircraft_code) as acc
              on aircrafts_data.aircraft_code = acc.aircraft_code
order by acc.count DESC
limit 3;

-- Вывести код, модель самолета и места не эконом класса
-- для самолета 'Аэробус A321-200' с сортировкой по местам

select aircrafts_data.aircraft_code, model, seat_no, fare_conditions
from aircrafts_data
         join (select * from seats where fare_conditions != 'Economy') as s
              on aircrafts_data.aircraft_code = s.aircraft_code
where model::json ->> 'ru' = 'Аэробус A321-200'
order by seat_no;

-- Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

select airport_code, airport_name, city
from airports_data
where city::json ->> 'en' in (select city
                              from (select city::json ->> 'en' as city, count(city::json ->> 'en')
                                    from airports_data
                                    group by city::json ->> 'en') as cc
                              where cc.count > 1);


-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву,
-- на который еще не завершилась регистрация

select *
from flights
where departure_airport in (select airport_code
                            from airports_data
                            where city::json ->> 'ru' = 'Екатеринбург')
  and arrival_airport in (select airport_code
                          from airports_data
                          where city::json ->> 'ru' = 'Москва')
  and (lower(status) = 'on time' or lower(status) = 'delayed')
  and scheduled_departure = (select min(scheduled_departure)
                             from flights
                             where departure_airport in (select airport_code
                                                         from airports_data
                                                         where city::json ->> 'ru' = 'Екатеринбург')
                               and arrival_airport in (select airport_code
                                                       from airports_data
                                                       where city::json ->> 'ru' = 'Москва')
                               and (lower(status) = 'on time' or lower(status) = 'delayed'));
;

-- Вывести самый дешевый и дорогой билет и стоимость
-- (в одном результирующем ответе)

select ticket_no, tickets.book_ref, passenger_id, passenger_name, contact_data, total_amount
from tickets
         join bookings on tickets.book_ref = bookings.book_ref
where bookings.total_amount = (select min(bookings.total_amount) from bookings)
   or bookings.total_amount = (select max(bookings.total_amount) from bookings)
;

-- Вывести информацию о вылете с наибольшей суммарной стоимостью билетов

select flights.*, tickets_sum_amount.sum
from flights
         join (select flight_id, sum(amount)
               from ticket_flights
               group by flight_id) as tickets_sum_amount
              on flights.flight_id = tickets_sum_amount.flight_id
where tickets_sum_amount.sum =
      (select max(sum_amont.sum) from (select sum(amount) from ticket_flights group by flight_id) as sum_amont);


-- Найти модель самолета, принесшую наибольшую прибыль
-- (наибольшая суммарная стоимость билетов).
-- Вывести код модели, информацию о модели и общую стоимость

select aircrafts_data.aircraft_code, model, aircrafts_sum_amount.sum
from (select aircraft_code, sum(tickets_sum_amount.sum)
      from flights
               join (select flight_id, sum(amount)
                     from ticket_flights
                     group by flight_id) as tickets_sum_amount
                    on flights.flight_id = tickets_sum_amount.flight_id
      group by aircraft_code) as aircrafts_sum_amount
         join aircrafts_data on aircrafts_sum_amount.aircraft_code = aircrafts_data.aircraft_code
where aircrafts_sum_amount.sum = (select max(aircrafts_sum_amount.sum)
                 from (select sum(tickets_sum_amount.sum)
                       from flights
                                join (select flight_id, sum(amount)
                                      from ticket_flights
                                      group by flight_id) as tickets_sum_amount
                                     on flights.flight_id = tickets_sum_amount.flight_id
                       group by aircraft_code) as aircrafts_sum_amount);


-- Найти самый частый аэропорт назначения для каждой модели самолета.
-- Вывести количество вылетов, информацию о модели самолета,
-- аэропорт назначения, город

select arrival_airport, city, cf.count, cf.aircraft_code, model
from (select arrival_airport, aircraft_code, count(arrival_airport)
      from flights
      group by arrival_airport, aircraft_code) as cf
         join (select aircraft_code, max(c.count)
               from (select aircraft_code, count(arrival_airport)
                     from flights
                     group by arrival_airport, aircraft_code) as c
               group by aircraft_code) as acm
              on cf.aircraft_code = acm.aircraft_code and cf.count = acm.max
         join aircrafts_data on cf.aircraft_code = aircrafts_data.aircraft_code
         join airports_data on cf.arrival_airport = airports_data.airport_code




