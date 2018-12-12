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


-- Suppression de toutes les tables
DROP TABLE Ballots;
DROP TABLE Tags;
DROP TABLE Ballots_To_Tags;
DROP TABLE Meps;
DROP TABLE Outcomes;

-- Injecter les tuples

\copy ballots(ballotid, vote_date, commitee) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS.csv' with (format csv, delimiter E'\t', header);
\copy Tags from '/home/tblain/Documents/bd/projet/EP_DATA/TAGS.csv' with (format csv, delimiter E'\t', header);
\copy Ballots_To_Tags(ballotid, tag_id) from '/home/tblain/Documents/bd/projet/EP_DATA/BALLOTS_TO_TAGS.csv' with (format csv, delimiter E'\t', header);
\copy MEPS from '/home/tblain/Documents/bd/projet/EP_DATA/MEPS.csv' with (format csv, delimiter E'\t', header);
\copy Outcomes from '/home/tblain/Documents/bd/projet/EP_DATA/Outcomes.csv' with (format csv, delimiter E'\t', header);
