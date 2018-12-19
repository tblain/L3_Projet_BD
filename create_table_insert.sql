-- Suppression de toutes les tables
/*
DROP TABLE Ballots CASCADE;
DROP TABLE Tags CASCADE;
DROP TABLE Ballots_To_Tags CASCADE;
DROP TABLE Meps CASCADE;
DROP TABLE Outcomes CASCADE;
*/

-- Creation des tables

CREATE TABLE Ballots (
  ballotid INT PRIMARY KEY NOT NULL,
  vote_date DATE,
  commitee TEXT
);

CREATE TABLE Tags(
    tag_id TEXT PRIMARY KEY NOT NULL,
    tag_label TEXT
T);

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
-- la table est tout d'abord cr��e sans contraintes pour �viter les erreurs de doublons lors de l'import
-- on rajoutera les contraintes apr�s
CREATE TABLE Outcomes(
  ballotid integer,
  mepid integer,
  vote TEXT
);


-- Injecter les tuples

\copy ballots(ballotid, vote_date, commitee) from 'C:\Users\Public\easy_access\EP_DATA\BALLOTS.csv' with (format csv, delimiter E'\t', header);
\copy Tags from 'C:\Users\Public\easy_access\EP_DATA\TAGS.csv' with (format csv, delimiter E'\t', header);
\copy Ballots_To_Tags(ballotid, tag_id) from 'C:\Users\Public\easy_access\EP_DATA\BALLOTS_TO_TAGS.csv' with (format csv, delimiter E'\t', header);
\copy MEPS from 'C:\Users\Public\easy_access\EP_DATA\MEPS.csv' with (format csv, delimiter E'\t', header, encoding 'utf8');
\copy Outcomes from 'C:\Users\Public\easy_access\EP_DATA\Outcomes.csv' with (format csv, delimiter E'\t', header);

/*
\copy ballots(ballotid, vote_date, commitee) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS.csv' with (format csv, delimiter E'\t', header);
\copy Tags from '/home/tblain/Documents/bd/projet/EP_DATA/TAGS.csv' with (format csv, delimiter E'\t', header);
\copy Ballots_To_Tags(ballotid, tag_id) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS_TO_TAGS.csv' with (format csv, delimiter E'\t', header);
\copy MEPS from '/home/tblain/Documents/bd/projet/EP_DATA/MEPS.csv' with (format csv, delimiter E'\t', header);
\copy Outcomes from '/home/tblain/Documents/bd/projet/EP_DATA/Outcomes.csv' with (format csv, delimiter E'\t', header);
*/

-- delete les doublons
alter table outcomes add column id serial primary key; -- on rajoute une cl� primaire pour distinguer les outcomes
Delete from outcomes a using outcomes b where a.id < b.id and a.mepid = b.mepid and a.ballotid = b.ballotid;

-- delete les outcomes qui n'ont pas de ballot car supprimer pendant la phase de clean
delete from outcomes where ballotid=any((select ballotid from outcomes where mepid = 124851) except (select ballotid from ballots));

-- corriger les fautes de frappes pour le champ vote de Outcomes
update Outcomes set vote = 'For' where vote = 'oFr';
update Outcomes set vote = 'Abstain' where vote = 'bAstain';
update Outcomes set vote = 'Against' where vote = 'gAainst';

alter table Outcomes
  add constraint fk_ballotid foreign key(ballotid) references ballots(ballotid);
alter table Outcomes
  add constraint fk_mepid foreign key(mepid) references meps(mepid);
  
  
-- indexs

create unique index on tags(tag_id);
create unique index on ballots(ballotid);
create unique index on meps(mepid);