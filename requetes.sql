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

select * from outcomes o1 where o1.mepid = 124851 && o1.ballotid=any(select * from outcomes o2 where mepid = 124851 && o1.vote=o2.vote);
