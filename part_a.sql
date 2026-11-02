use bootcamp.northern_star;

--1. Колико утакмица је одиграно у фебруару 2025?
select 
count (match_id) as num_of_matches
from matches
where month(kickoff_ts)=2 and year(kickoff_ts)=2025 and status='played';
--40 utakmica

--2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?
select 
stadium_id, 
capacity
from stadiums 
order by capacity desc;

select stadium_name from stadiums where stadium_id=22;
--Najveci kapacitet ima National stadium, stadium_id=22;
select 
t.team_id, 
t.team_name,
t.stadium_id, 
s.stadium_name, 
s.capacity
from teams t 
join stadiums s on s.stadium_id=t.stadium_id
order by s.capacity desc;
--Najveci stadion nekog tima je 1	Harbourside Park	52000, za tim Northport United

3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?
select 
count (distinct player_id) as num_of_players
from players 
where nationality = 'Serbia';
--42 igraca

4. Колико утакмица је завршено резултатом 1:1?

select 
sum(case when home_goals=1 and away_goals=1 then 1
        else 0 
        end) as num_of_ones
from matches;
--94 utakmice

5. Колика је просечна посета по сезони?

select
season,
round(avg(attendance),2) as average
from matches
where attendance is not null
group by season;
--2023/24	24252.95
--2024/25	24199.49

6. Колико голова је дато из пенала по сезони?
select 
season,
sum(case when event_type='penalty_goal' then 1
         else 0
         end) as penalty_goals
from match_events me
join matches m on m.match_id=me.match_id
group by season;
--2023/24	104
--2024/25	109

7. Колико различитих играча је дало бар један гол у сезони 2024/25?

select 
count(distinct player_id) as num_of_players_that_scored
from match_events me
join matches m on m.match_id=me.match_id and m.season='2024/25'
where event_type in ('penalty_goal', 'goal');
--308 igraca

8. Који судија је највише пута судио утакмице клуба Northport United?

select * from teams where team_name='Northport United' --team_id=1

select
referee_id,
count(referee_id) as times_reffed
from matches 
where home_team_id=1 or away_team_id=1 and status='played'
group by referee_id
order by times_reffed desc;

select referee_name
from referees where referee_id=4;
--Peter Lindgren

9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један
пенал, дат или промашен?

select distinct event_type from match_events; --'penalty_goal','penalty_miss' 

select
m.referee_id,
count(distinct me.match_id) as num_of_matches
from match_events me 
join matches m on m.match_id=me.match_id  
where event_type in ('penalty_goal','penalty_miss') and season='2024/25'
group by referee_id
order by num_of_matches desc;

select referee_name from referees where referee_id=4;
--Peter Lindgren

10. Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на
полувремену? Рачунајте и домаће и гостујуће утакмице

select 
t.team_id,
sum(case when home_goals_ht<away_goals_ht and home_goals>away_goals then 3
            when home_goals_ht<away_goals_ht and home_goals=away_goals then 1
            else 0 
            end) 
sum(case when away_goals_ht<home_goals_ht and away_goals>home_goals then 3
            when away_goals_ht<home_goals_ht and away_goals=home_goals then 1
            else 0 
            end) as total_points
from matches m
join teams t on t.team_id=m.home_team_id or t.team_id=m.away_team_id
group by t.team_id
order by total_points desc;

select manager_name from manager_spells where team_id=9;
select team_name from teams where team_id=9;
--Zoran Tošić, 32 poena, Harrowgate Albion

-- select * from matches where (home_goals_ht<away_goals_ht and home_goals>away_goals) or(away_goals_ht<home_goals_ht and away_goals>home_goals)git