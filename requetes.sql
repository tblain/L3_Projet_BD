-- Questions
  -- 1)

select * from meps where national_party='[nom du party]';

  -- 2)
select distinct name_full, count(*) from meps join outcomes on (meps.mepid=outcomes.mepid) group by name_full order by count(*) desc;

  -- 3)
select count(*)/(select count(*) from meps) from meps join outcomes on (meps.mepid=outcomes.mepid);

  -- 4)
select groupe_id, count(*) from meps group by groupe_id;

  -- 5)
select groupe_id, count(*)/(select count(*) from meps where groupe_id = m.groupe_id) from meps as m join outcomes on (m.mepid=outcomes.mepid) group by groupe_id;

  -- 6)

CREATE MATERIALIZED VIEW nb_vote_par_groupe_par_ballot
as
  select ballotid, groupe_id, vote, count(*)
  from Outcomes o2
  join Meps m2 on (o2.mepid = m2.mepid)
  group by ballotid, groupe_id, vote;

CREATE MATERIALIZED VIEW vote_majo_par_groupe_par_ballot
as
  select ballotid, groupe_id, vote
  from Outcomes o
  join Meps m on (o.mepid = m.mepid)
  group by ballotid, groupe_id, vote
  having count(*) >= all(
    select count
    from nb_vote_par_groupe_par_ballot n
    where m.groupe_id = n.groupe_id
      and o.ballotid = n.ballotid
  )
  ;

select 
from (
  select groupe_id, name_full, count(*),
    ceil(cast(count(*) as decimal)/(select count(*) from meps join outcomes on (meps.mepid=outcomes.mepid) group by name_full having name_full = m2.name_full) * 100)
  from Outcomes o2
  join (select * from meps where name_full = 'Jussi HALLA-AHO') m2 on (o2.mepid = m2.mepid)
  where vote = any(
    select vote
    from vote_majo_par_groupe_par_ballot v
    where v.ballotid = o2.ballotid
    and v.groupe_id = m2.groupe_id
  )
  group by groupe_id, name_full
  order by groupe_id, count(groupe_id) desc;
)
;

Perussuomalaiset

-- 17h23
select groupe_id, name_full, count,
ceil(cast(count as decimal)/(select count(*) from meps join outcomes on (meps.mepid=outcomes.mepid) group by name_full having name_full = r.name_full) * 100)
from (
  select distinct on(groupe_id) groupe_id, name_full, count(*) as count
  from Outcomes o2
  join meps m2 on (o2.mepid = m2.mepid)
  where groupe_id = 'NI' and vote = any(
    select vote
    from vote_majo_par_groupe_par_ballot v
    where v.ballotid = o2.ballotid
      and v.groupe_id = m2.groupe_id
  )
  group by groupe_id, name_full
  order by groupe_id, count(groupe_id) desc
) r
;