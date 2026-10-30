
use bootcamp.northern_star;

1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи
удео?

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

-- 1 Harbourside Park, 2	Kingsbridge Stadium, 3 Northport Arena

3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи
гол дао најраније?

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
sum(goals_for) over(partition by team_id order by kickoff_ts, match_id asc rows between unbounded preceding and current row) as current_goals
from team_matches
where season='2024/25' and team_id=2
)
select *,
row_number() over (partition by team_id order by current_goals asc) as rank
from current_table
where current_goals>=50
qualify rank=1 
--Utakmica match_id=2248, od 8.2.2025. je presao 50 bodova
