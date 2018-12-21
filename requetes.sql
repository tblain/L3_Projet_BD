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

CREATE table nb_vote_par_groupe_par_ballot
as
  select ballotid, groupe_id, vote, count(*)
  from Outcomes o2
  join Meps m2 on (o2.mepid = m2.mepid)
  group by ballotid, groupe_id, vote;

CREATE table vote_majo_par_groupe_par_ballot
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


select groupe_id, name_full, count,
ceil(cast(count as decimal)/(select count(*) from meps join outcomes on (meps.mepid=outcomes.mepid) group by name_full having name_full = r.name_full) * 100)
from (
  select distinct on(groupe_id) groupe_id, name_full, count(*) as count
  from Outcomes o2
  join meps m2 on (o2.mepid = m2.mepid)
  where vote = any(                          
    select vote
    from vote_majo_par_groupe_par_ballot v
    where v.ballotid = o2.ballotid
      and v.groupe_id = m2.groupe_id
  )
  group by groupe_id, name_full
  order by groupe_id, count(groupe_id) desc
) r
;

--  groupe_id |        name_full        | count | ceil 
-- -----------+-------------------------+-------+------
--  ALDE      | Matthijs van MILTENBURG |  4478 |   97
--  ECR       | Jussi HALLA-AHO         |  4268 |   95
--  EFDD      | Jonathan ARNOTT         |  3317 |   75
--  ENF       | Dominique BILDE         |  4519 |   99
--  GUE/NGL   | Barbara SPINELLI        |  4378 |   94
--  NI        | Mara BIZZOTTO           |  3370 |   72
--  PPE       | Jens GIESEKE            |  4565 |   98
--  S&D       | Nicola DANTI            |  4562 |   98
--  Verts/ALE | Bronis ROPĖ             |  4500 |   99
-- (9 rows)

-- select groupe_id, name_full, count(*) as count
--   from Outcomes o2
--   join meps m2 on (o2.mepid = m2.mepid)
--   where groupe_id = 'ALDE' and name_full = 'Matthijs van MILTENBURG'
--   group by groupe_id, name_full;

-- select 
-- from (
--   select groupe_id, name_full, count(*),
--     ceil(cast(count(*) as decimal)/(select count(*) from meps join outcomes on (meps.mepid=outcomes.mepid) group by name_full having name_full = m2.name_full) * 100)
--   from Outcomes o2
--   join (select * from meps where name_full = 'Jussi HALLA-AHO') m2 on (o2.mepid = m2.mepid)
--   where vote = any(
--     select vote
--     from vote_majo_par_groupe_par_ballot v
--     where v.ballotid = o2.ballotid
--     and v.groupe_id = m2.groupe_id
--   )
--   group by groupe_id, name_full
--   order by groupe_id, count(groupe_id) desc;
-- )
-- ;