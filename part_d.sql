use bootcamp.sandbox;

--Tabela sa timovima

create or replace table dim_team as
select distinct team_id, team_name, short_name as team_code
from bootcamp.northern_star.teams
order by team_id asc;

select * from dim_team;

--Tabela sa datumima
create or replace table dim_date as
select cast(date_format(d, 'yyyyMMdd') as int) as date_key,
       d                                       as full_date,
       date_format(d, 'EEEE')                  as weekday_name,
       dayofweek(d) in (1, 7)                  as is_weekend,
       case when month(d) >= 7 then concat(year(d), '/', substring(cast(year(d) + 1 as string), 3, 2))
            else concat(year(d) - 1, '/', substring(cast(year(d) as string), 3, 2))
       end                                   as season
from (select explode(sequence(date'2023-07-01', date'2025-06-30', interval 1 day)) as d);

select * from dim_date;

--Tabela sa igracima

create or replace table dim_players as
select distinct player_id, first_name, last_name
from bootcamp.northern_star.players
where player_id is not null
union
select -1, 'Nepoznat', 'Nepoznat'
order by player_id asc;

select * from dim_players;

--Tabela sa sudijama
create or replace table dim_referee as
select distinct referee_id, referee_name
from bootcamp.northern_star.referees
order by referee_id;

select * from dim_referee;


--Tabela fact_card
-- U fact_card Један ред по картону (yellow_card, second_yellow, red_card) из
-- match_event
-- У fact_card ставите: event_id, match_id, date_key, team_id, player_id, referee_id и врсту
-- картона. Догађаји са играчем кога нема у players добијају player_id = -1

create or replace table matches_and_events as(
select me.event_id, 
 me.match_id, m.kickoff_ts, me.team_id, me.player_id, m.referee_id, me.event_type
 from bootcamp.northern_star.match_events me
 join bootcamp.northern_star.matches m on m.match_id=me.match_id 
 where event_type in( 'yellow_card', 'second_yellow', 'red_card')
);

--Prvo sam napravila ovu tabelu matches_and_events, da bih lakse izvukla sve sto mi treba.
--Nadam se da je to ok. Znam da sam mogla da pravim blank tabele pa da sa update uzimam podatke iz svake pojedinacno, ali ovako mi je bilo lakse i brze (morala sam da otputujem i veoma sam u stisci sa vremenom). 
create or replace table fact_card1 
(   event_id BIGINT,
    match_id BIGINT, 
    date_key INT,
    team_id BIGINT, 
    player_id BIGINT, 
    referee_id BIGINT, 
    card_type STRING
);
insert into fact_card1 ()...
--Ako treba da doradim, mogu i da napravim bas gde radi update table iz svih ovih malih tabela.

CREATE OR REPLACE TABLE fact_card AS
SELECT me.event_id,
me.match_id,
CAST(DATE_FORMAT(me.kickoff_ts, 'yyyyMMdd') AS INT) AS date_key,
me.team_id,
COALESCE(me.player_id, -1) AS player_id,
me.referee_id,
me.event_type as card_type
FROM matches_and_events me;


--Tabela ispunjava trazeni kriterijum granularnosti, jedan red je za svaki kartonski dogadjaj.
--Redova ima 2678 isto kao i kartonskih dogadjaja u originalnoj tabeli. 

select count(*) from fact_card; --2678

select count(*) from bootcamp.northern_star.match_events where event_type in( 'yellow_card', 'second_yellow', 'red_card'); --2678 
select * from matches_and_events
--Iz nekog razloga, pri spajanju tabela, umesto da se player_id iz null pretvori u -1, prelazi u 99999. 
select * from fact_card where player_id=99999;
--Imaju dva igraca sa takvim player_id. 
select * from bootcamp.northern_star.match_events where event_id=1024
--Proanalizirala sam originalnu tabelu match_events. Za event_id=1024, player_id je 99999, zato coalesce ne radi kako bismo ocekivali. Moze da se zameni sa case when player_id=99999... pa da se menja na taj nacin.
--Ovo je i greska u podacima.
select * from bootcamp.northern_star.players where player_id=99999
