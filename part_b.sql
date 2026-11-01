use bootcamp.northern_star;

1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа
домаћина, нерешених и победа гостију.

select 
season,
count(match_id) as num_of_matches,
round(avg(home_goals+away_goals),2) as avg_goals,
round(sum(case when home_goals>away_goals then 1
        else 0
        end)*100.0/count(match_id),2) as percentage_of_home_wins,
round(sum(case when away_goals>home_goals then 1
        else 0
        end)*100.0/count(match_id),2) percentage_of_away_wins,
round(sum(case when home_goals=away_goals then 1
        else 0
        end)*100.0/count(match_id),2) as percentage_of_draws
from matches where status='played' and season='2024/25'
group by season;


2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у
сваком месецу. Који месец се издваја?
--radim za mesece po sezonama
with pomoc as(
select 
season,
month(kickoff_ts) as mesec, 
count(match_id) as num_of_matches,
sum(home_goals+away_goals) as goals,
round(avg(home_goals+away_goals),2) as avg_goals
from matches
where status='played'
group by mesec, season
)
-- select *,
-- row_number() over ( order by num_of_matches desc) as rank
-- from pomoc;
-- select *,
-- row_number() over ( order by goals desc) as rank
-- from pomoc;
select *,
row_number() over (order by avg_goals desc) as rank
from pomoc;
--Najvise meceva se igra u decembru

3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и
утакмица без публике.

with pomoc as( select 
m.season,
s.stadium_id,
round(avg(m.attendance),2) as avg_att,
round(avg(m.attendance*100.0/s.capacity),2) as avg_popunjenost
from matches m 
join stadiums s on s.stadium_id=m.stadium_id and m.season='2024/25'
group by s.stadium_id, m.season
order by season asc, avg_att desc)
select *,
row_number() over (partition by season order by avg_popunjenost desc) as rank
from pomoc;

select stadium_name from stadiums where stadium_id=8;

select 
count(match_id) as num_of_matches
from matches
where attendance is null and status='played' and season='2024/25';


select 
count(match_id) as num_of_matches
from matches
where attendance=0 and status='played' and season='2024/25'


4. Судије: за сваког судију број утакмица и картони по утакмици.
--Prvi upit je broj utakmica
select 
m.referee_id,
count(distinct m.match_id) as num_of_matches
-- sum(case when me.event_type in ('red_card', 'yellow_card', 'second_yellow') then 1 
--             else 0 
--             end) as num_of_cards
from matches m
-- join match_events me on m.match_id=me.match_id and me.event_type in ('red_card', 'yellow_card', 'second_yellow')
where status='played' and season='2024/25'
group by  m.referee_id
order by num_of_matches desc;

--Ovo je prosecan broj kartona po utakmici
select 
m.referee_id,
count(distinct m.match_id) as num_of_matches,
sum(case when me.event_type in ('red_card', 'yellow_card', 'second_yellow') then 1 
        else 0 
        end) as num_of_cards,
round(sum(case when me.event_type in ('red_card', 'yellow_card', 'second_yellow') then 1 
            else 0 
            end) * 1.0/count(distinct m.match_id), 2) as avg_cards
from matches m
left join match_events me on m.match_id = me.match_id and me.event_type in ('red_card', 'yellow_card', 'second_yellow')
where m.status = 'played' and m.season = '2024/25'
group by m.referee_id
order by avg_cards desc;
--Brinula sam se zbog umnozavanja redova, ali Google kaze da prosecan broj kartona po utakmici jeste od 4-5 tako da izgleda da ipak jeste dobro.  

select referee_name from referees where referee_id=4

5. Играчи: пет најбољих стрелаца и пет најбољих асистената.

with goals_pp as(
select 
me.player_id, 
sum(case when event_type in ('goal', 'penalty_goal') then 1
         else 0
         end) as goals_per_player
from match_events me
join matches m on m.match_id=me.match_id and m.season='2024/25'
group by me.player_id
order by goals_per_player desc --612 redova
)
select goals_pp.player_id, goals_per_player, 
p.first_name, p.last_name,
row_number() over (order by goals_per_player desc) as rank
from goals_pp
join players p on p.player_id=goals_pp.player_id
qualify rank<=5;

with goals_pp as(
select 
me.related_player_id, 
sum(case when event_type in ('goal', 'penalty_goal') then 1
         else 0
         end) as goals_per_player
from match_events me
join matches m on m.match_id=me.match_id and season='2024/25'
group by  me.related_player_id
order by goals_per_player desc --612 redova
)
select 
goals_pp.related_player_id, 
goals_per_player, 
p.first_name, p.last_name,
row_number() over (order by goals_per_player desc) as rank
from goals_pp
join players p on p.player_id=goals_pp.related_player_id
qualify rank<=5;

6. Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица
чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без
тренера), са упитима који их проналазе.

select * from match_events where player_id is null and event_type in ('goal', 'penalty_goal', 'own_goal');

select * from referees;
Kolona debut season ima nelogicne vrednosti, oblika 2014/21, 2013/22, 2015/20...

U tabeli players, prvi deo tabele su sudije, a ne igraci.
select * from players;

Tabela sa menadzerima (trenerima), preklapaju se datumi pocetka i kraja mandata nekih menadzera. (setila sam se sa vezbi)
