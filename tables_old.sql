-- Creation des tables

CREATE TABLE Ballots (
  ballotid INT PRIMARY KEY NOT NULL,
  vote_date DATE,
  commitee TEXT
);

CREATE TABLE Tags(
    tag_id TEXT PRIMARY KEY NOT NULL,
    tag_label TEXT
);

CREATE TABLE Ballots_To_Tags(
  ballotid INT references Ballots(ballotid),
  tag_id TEXT references Tags(tag_id)
);

CREATE TABLE Meps(
  mepid INT PRIMARY KEY NOT NULL,
  name_full TEXT,
  country TEXT,
  national_party TEXT,
  groupe_id TEXT,
  gender varchar(1)
);

CREATE TABLE Outcomes(
  ballotid INT references Ballots(ballotid),
  mepid INT references Meps(mepid),
  vote TEXT
);


/*
-- Suppression de toutes les tables
DROP TABLE Ballots;
DROP TABLE Tags;
DROP TABLE Ballots_To_Tags;
DROP TABLE Meps;
DROP TABLE Outcomes;
*/

-- Injecter les tuples

\copy ballots(ballotid, vote_date, commitee) from 'C:\Users\Mathéo Dumont\Documents\Licence L3\bd\L3_Projet_BD\EP_DATA\BALLOTS.csv' with (format csv, delimiter E'\t', header);
\copy Tags from 'C:\Users\Mathéo Dumont\Documents\Licence L3\bd\L3_Projet_BD\EP_DATA\TAGS.csv' with (format csv, delimiter E'\t', header);
\copy Ballots_To_Tags(ballotid, tag_id) from 'C:\Users\Mathéo Dumont\Documents\Licence L3\bd\L3_Projet_BD\EP_DATA\BALLOTS_TO_TAGS.csv' with (format csv, delimiter E'\t', header);
\copy MEPS from 'C:\Users\Mathéo Dumont\Documents\Licence L3\bd\L3_Projet_BD\EP_DATA\MEPS.csv' with (format csv, delimiter E'\t', header);
\copy Outcomes from 'C:\Users\Mathéo Dumont\Documents\Licence L3\bd\L3_Projet_BD\EP_DATA\Outcomes.csv' with (format csv, delimiter E'\t', header);

/*
\copy ballots(ballotid, vote_date, commitee) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS.csv' with (format csv, delimiter E'\t', header);
\copy Tags from '/home/tblain/Documents/bd/projet/EP_DATA/TAGS.csv' with (format csv, delimiter E'\t', header);
\copy Ballots_To_Tags(ballotid, tag_id) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS_TO_TAGS.csv' with (format csv, delimiter E'\t', header);
\copy MEPS from '/home/tblain/Documents/bd/projet/EP_DATA/MEPS.csv' with (format csv, delimiter E'\t', header);
\copy Outcomes from '/home/tblain/Documents/bd/projet/EP_DATA/Outcomes.csv' with (format csv, delimiter E'\t', header);
*/

-- requetes SQL

-- delete les doublons
alter table outcomes add column id serial primary key; -- on rajoute une clÃ© primaire pour distinguer les outcomes
Delete from outcomes a using outcomes b where a.id < b.id and a.mepid = b.mepid and a.ballotid = b.ballotid;

-- delete les outcomes qui n'ont pas de ballot car supprimer pendant la phase de clean
delete from outcomes where ballotid=any((select ballotid from outcomes where mepid = 124851) except (select ballotid from ballots));

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
