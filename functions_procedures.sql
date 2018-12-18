-- 1

CREATE OR REPLACE FUNCTION parentof(IN tag1 TEXT, IN tag2 TEXT) RETURNS BOOLEAN AS
$$
DECLARE 
	pos_last_dot integer;
BEGIN
	select length(tag2) - position('.' in reverse(tag2)) into pos_last_dot;
	return left(tag2, pos_last_dot) = tag1;
END;
$$
LANGUAGE PLPGSQL;
				
-- 2

CREATE OR REPLACE FUNCTION ancestor(IN tag1 TEXT, IN tag2 TEXT) RETURNS BOOLEAN AS
$$
BEGIN
	return tag1 = substring(tag2 ,1 ,length(tag1)) or parentof(tag1, tag2);
END;
$$
LANGUAGE PLPGSQL;

-- 3

CREATE OR REPLACE FUNCTION Tagged(IN ballot integer, IN tag TEXT) RETURNS BOOLEAN AS
$$
DECLARE 
	cursor_tags_for_ballot CURSOR FOR select * from ballots_to_tags where ballotid = ballot;
BEGIN
	for line in cursor_tags_for_ballot
	LOOP
		IF ancestor(tag, line.tag_id) THEN
			return true;
		END IF;
	END LOOP;
	return false;
END;
$$
LANGUAGE PLPGSQL;


-- 4 

CREATE OR REPLACE FUNCTION MAJORITY_VOTE_PARTY(IN ballot integer, IN party TEXT) RETURNS integer AS
$$
DECLARE 
	cursor_vote CURSOR FOR select * from meps join outcomes using(ballotid) 
  	where national_party = party and ballotid = ballot;
  	pro integer;
  	against integer;
  	abstain integer;
BEGIN
  	pro := 0;
  	against := 0;
  	abstain := 0;
	
	FOR line IN cursor_vote LOOP

		IF line.vote = 'For' THEN
		  pro := pro + 1;
		ELSIF line.vote = 'Against' THEN
		  against := against + 1;
		ELSIF line.vote = 'Abstain' THEN
		  abstain := abstain + 1;
		END IF;

	END LOOP;
  
  IF pro = 0 and against = 0 and abstain = 0 THEN
    return 0;
  ELSIF pro = against and against = abstain and abstain != 0 THEN
    return 7;
  ELSE
    IF pro > against and pro > abstain THEN
        return 1;
    ELSIF against > pro and against > abstain THEN
        return 2;
    ELSIF abstain > against and abstain > pro THEN
        return 3;
    ELSE
        IF pro > abstain and against > abstain THEN 
          return 4;
        ELSIF pro > against and abstain > against THEN
          return 5;
        ELSIF abstain > pro and against > pro THEN
          return 6;
        END IF;
    END IF;
  END IF;
END;
$$
LANGUAGE PLPGSQL;