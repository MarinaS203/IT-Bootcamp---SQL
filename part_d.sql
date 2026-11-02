use bootcamp.sandbox;

--Tabela sa timovima

CREATE OR REPLACE TABLE dim_team AS
select distinct team_id, team_name, short_name as team_code
from bootcamp.northern_star.teams
order by team_id asc;

select * from dim_team;

--Tabela sa datumima
CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);

select * from dim_date;

--Tabela sa igracima

CREATE OR REPLACE TABLE dim_players AS
select distinct player_id, first_name, last_name
from bootcamp.northern_star.players
where player_id is not null
UNION
SELECT -1, 'Nepoznat', 'Nepoznat'
ORDER BY player_id ASC;

select * from dim_players;

--Tabela sa sudijama
CREATE OR REPLACE TABLE dim_referee AS
SELECT DISTINCT referee_id, referee_name
FROM bootcamp.northern_star.referees
ORDER BY referee_id;

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