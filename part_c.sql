
use bootcamp.northern_star;
CREATE OR REPLACE VIEW bootcamp.northern_star.team_matches AS
WITH sides AS (
SELECT match_id, season, matchday, kickoff_ts,
home_team_id AS team_id, away_team_id AS opponent_id, 'home' AS
venue,
home_goals AS goals_for, away_goals AS goals_against
FROM bootcamp.northern_star.matches WHERE status = 'played'
UNION ALL
SELECT match_id, season, matchday, kickoff_ts,
away_team_id, home_team_id, 'away',
away_goals, home_goals
FROM bootcamp.northern_star.matches WHERE status = 'played'
)
SELECT *,
CASE WHEN goals_for > goals_against THEN 'W'
WHEN goals_for = goals_against THEN 'D' ELSE 'L' END AS result,
CASE WHEN goals_for > goals_against THEN 3
WHEN goals_for = goals_against THEN 1 ELSE 0 END AS points
FROM sides;

1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи
удео?

with team_goals as(
select 
team_id,
sum(goals_for) as tot_goals_per_team
from team_matches
where season='2024/25'
group by team_id
order by tot_goals_per_team desc
)
select 
*, 
round(tot_goals_per_team*100.0/(select sum(goals_for) from team_matches where season='2024/25'),2) as avg_per_team 
from team_goals;

select team_name from teams where team_id=4
--Najveci udeo ima tim Kingsbridge City, sa 7.60%

2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?

with list as(
select 
m.stadium_id,
 s.stadium_name,
round(avg(m.attendance),2) as avg_att
from matches m
join stadiums s on s.stadium_id=m.stadium_id and season='2024/25'
group by m.stadium_id,  s.stadium_name
)
select
*,
row_number() over (order by avg_att desc) as rank
from list
qualify rank<=3;

-- 1 Harbourside Park, 2 Kingsbridge Stadium, 3 Northport Arena

3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи
гол дао најраније?
--event_type in ('goal', 'penalty_goal')
with list as( 
select 
me.match_id,
m.kickoff_ts,
me.minute,
me.team_id,
me.player_id
from match_events me
join matches m on m.match_id=me.match_id and me.event_type in ('goal', 'penalty_goal') and m.season='2024/25'
)
select
*, 
row_number() over (partition by team_id order by kickoff_ts desc, match_id desc, minute desc) as rank
from list
qualify rank=1;
--Tabela prikazuje datum i vreme poslednjeg gola za svaki tim.

--Tim team_id=8, Elmsworth Wanderers je svoj poslednji gol dao najranije, 3. maja 2025. u match_id=2354

select team_name from teams where team_id=8;

4. За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену у
односу на претходну домаћу утакмицу. Где је највећи пад?
select team_id from teams where team_name='Northport United' --team_id=1

with att as(
select
match_id, 
home_team_id, 
kickoff_ts, 
attendance,
lag(attendance) over (partition by home_team_id order by kickoff_ts asc, match_id asc) as previous_att 
from matches
where season='2024/25' and home_team_id=1
)

select *,
attendance-previous_att as att_diff,
row_number() over (order by attendance-previous_att asc) as rank
from att
where attendance-previous_att is not null
qualify rank=1;

--Najveci pad je u utakmici match_id 2110 odigranoj 2024-11-10 

5. Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој
утакмици по реду и ког датума је прешао 50 бодова?
select team_id from teams where team_name='Northport City' --team_id=2

with current_table as (select 
match_id, 
kickoff_ts, 
team_id, 
sum(points) over(partition by team_id order by kickoff_ts, match_id asc rows between unbounded preceding and current row) as current_points
from team_matches
where season='2024/25' and team_id=2
)
select *,
row_number() over (partition by team_id order by current_points asc) as rank
from current_table
where current_points>=50
qualify rank=1 
--Utakmica match_id 2210 od 12. januara 2025., 51 poen, to je bila 21. utakmica po redu
