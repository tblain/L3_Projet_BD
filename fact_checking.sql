-- 1

CREATE OR REPLACE FUNCTION WE_ARE_THE_OPPOSITION_PARTY(IN party TEXT) RETURNS REAL AS
$$
DECLARE 
	cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) where national_party = party order by ballotid asc;
	against integer;
	-- ceux qui ont le tag
	total_ballot integer;
	
BEGIN
	against := 0;
	select count(distinct ballotid) from outcomes join meps using(mepid) where national_party = party into total_ballot;
  
	
	for line in cursor_ballot LOOP
    IF (select majority_vote_party(line.ballotid, party) = 2) THEN
      against := against + 1;
    END IF;
	END LOOP;
	
	return (against::decimal / total_ballot) * 100;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION WE_ARE_THE_OPPOSITION_GROUP(IN groupe TEXT) RETURNS REAL AS
$$
DECLARE 
	cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) where group_id = groupe order by ballotid asc;
	against integer;
	-- ceux qui ont le tag
	total_ballot integer;
	
BEGIN
	against := 0;
	select count(distinct ballotid) from outcomes join meps using(mepid) where group_id = groupe into total_ballot;
  
	
	for line in cursor_ballot LOOP
    IF (select majority_vote_group(line.ballotid, groupe) = 2) THEN
      against := against + 1;
    END IF;
	END LOOP;
	
	return (against::decimal / total_ballot) * 100;
END;
$$
LANGUAGE PLPGSQL;

-- 2

-- 3

-- 4