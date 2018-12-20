-- 1

CREATE OR REPLACE FUNCTION parentof(IN tag1 TEXT, IN tag2 TEXT) RETURNS BOOLEAN AS
$$
DECLARE 
	pos_last_dot integer;
BEGIN
  /*
  tag1 est le parent de tag2
  Exemple :
  tag1 = 4.10
  tag2 = 4.10.3
  on fait length(tag2) = 6 - (position('.' in reverse(tag2)=3.01.4)= 2) = 4
  on split le tag2 � la position 4 et on prend la partie gauche que l'on compare au tag1
  et on obtient 4.10 = 4.10 = true
  */
	select length(tag2) - position('.' in reverse(tag2)) into pos_last_dot;
	return left(tag2, pos_last_dot) = tag1;
END;
$$
LANGUAGE PLPGSQL;
				
-- 2

CREATE OR REPLACE FUNCTION ancestor(IN tag1 TEXT, IN tag2 TEXT) RETURNS BOOLEAN AS
$$
BEGIN
  /*
  tag1 est l'anc�tre de tag2
  avec 
  tag1 = 4
  tag2 = 4.10.3
  on prend la sous-chaine de tag2 de position 1 � celle �quivalent
  � la taille de tag1 ce qui donne
  et on retourne tag1 =  (substring(tag2, 1 ,length(tag1)) = '4' ) or parentof()
  parentof car parent => donc anc�tre aussi
  */
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
  -- Pour tous les ballots s�lectionn�s, si ils ont pour parent ou anc�tre le tag on retourne TRUE
  -- si pas de r�sultat, on retourne FALSE
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
    -- on s�lectionne les diff�rents votes d'un ballot pour un parti
    cursor_vote CURSOR FOR select * from meps join outcomes using(mepid) 
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

-- 5

CREATE OR REPLACE FUNCTION MAJORITY_VOTE_GROUP(IN ballot integer, IN groupe TEXT) RETURNS integer AS
$$
DECLARE 
  -- comme la 4
	cursor_vote CURSOR FOR select * from meps join outcomes using(mepid) 
  	where group_id = groupe and ballotid = ballot;
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

-- 6

CREATE OR REPLACE FUNCTION MAJORITY_VOTE_COUNTRY(IN ballot integer, IN country TEXT) RETURNS integer AS
$$
DECLARE 
  -- comme la 4
	cursor_vote CURSOR FOR select * from meps join outcomes using(mepid) 
  	where 'country' = country and ballotid = ballot;
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

-- 7

CREATE OR REPLACE FUNCTION SIMILARITY_NATIONAL_PARTY(IN ballot integer, IN party1 TEXT, IN party2 TEXT) RETURNS boolean AS
$$
DECLARE 
    res_party1 integer;
    res_party2 integer;
BEGIN
    --  on s�lectionne les r�sultats majoritaire � propos d'un ballot pour les deux partis donn�s
  	select majority_vote_party(ballot, party1) into res_party1;
    select majority_vote_party(ballot, party2) into res_party2;
    -- et on les compare
    return res_party1 = res_party2;
END;
$$
LANGUAGE PLPGSQL;

-- 8

CREATE OR REPLACE FUNCTION SIMILARITY_GROUP(IN ballot integer, IN group1 TEXT, IN group2 TEXT) RETURNS boolean AS
$$
DECLARE 
    res_group1 integer;
    res_group2 integer;
BEGIN
    -- comme la 7 mais pour un group
  	select majority_vote_group(ballot, group1) into res_group1;
    select majority_vote_group(ballot, group2) into res_group2;
    return res_group1 = res_group2;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION SIMILARITY_COUNTRIES(IN ballot integer, IN country1 TEXT, IN country2 TEXT) RETURNS boolean AS
$$
DECLARE 
    res_country1 integer;
    res_country2 integer;
BEGIN
    -- comme la 7 mais pour deux pays
  	select majority_vote_country(ballot, country1) into res_country1;
    select majority_vote_country(ballot, country2) into res_country2;
    return res_country1 = res_country2;
END;
$$
LANGUAGE PLPGSQL;

-- 9

CREATE OR REPLACE FUNCTION USUAL_SIMILARITY_PARTY(IN party1 TEXT, IN party2 TEXT) RETURNS REAL AS
$$
DECLARE 
    -- On prend tous les ballots pour lesquelles ont vot�s les deux partis (party1 et party2)
    -- utiliser LIMIT 100 pour tester les r�sultat
    cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) 
    where national_party = party1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where national_party = party2) 
    order by ballotid asc;
    total_ballot integer;
    similarity integer;
    
BEGIN
    similarity := 0;
    
    -- mettre total_ballot au nombre utiliser pour LIMIT (si utilis�)
    select count(distinct ballotid) from outcomes join meps using(mepid) 
    where national_party = party1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where national_party = party2) into total_ballot;
    
    -- pour chaque ballot on regarde si les r�sultats sont pareil pour les deux partis, si oui on incr�mente similarity
    FOR ballot in cursor_ballot LOOP
      IF (select SIMILARITY_NATIONAL_PARTY(ballot.ballotid, party1, party2) = true) THEN
        similarity := similarity + 1;
      END IF;
    END LOOP;
    -- enfin on retourne une pourcentage
  	return (similarity::decimal / total_ballot) *100 ;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION USUAL_SIMILARITY_GROUP(IN group1 TEXT, IN group2 TEXT) RETURNS REAL AS
$$
DECLARE
    -- comme pr�c�dent mais pour group
    cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) 
    where group_id = group1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where group_id = group2) 
    order by ballotid asc;
    total_ballot integer;
    similarity integer;
BEGIN
    similarity := 0;
    select count(distinct ballotid) from outcomes join meps using(mepid) 
    where group_id = group1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where group_id = group2) into total_ballot;
    
    FOR ballot in cursor_ballot LOOP
      IF (select SIMILARITY_GROUP(ballot.ballotid, group1, group2) = true) THEN
        similarity := similarity + 1;
      END IF;
    END LOOP;
  	return (similarity::decimal / total_ballot) *100 ;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION USUAL_SIMILARITY_COUNTRY(IN country1 TEXT, IN country2 TEXT) RETURNS REAL AS
$$
DECLARE 
    -- comme pr�c�dent mais avec country
    cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) 
    where country = country1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where country = country2) 
    order by ballotid asc;
    total_ballot integer;
    similarity integer;
BEGIN
    similarity := 0;
    
    select count(distinct ballotid) from outcomes join meps using(mepid) 
    where country = country1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where country = country2) into total_ballot;
	
    
    FOR ballot in cursor_ballot LOOP
      IF (select SIMILARITY_COUNTRIES(ballot.ballotid, country1, country2) = true) THEN
        similarity := similarity + 1;
      END IF;
    END LOOP;
  	return (similarity::decimal / total_ballot) *100 ;
END;
$$
LANGUAGE PLPGSQL;

-- 10

CREATE OR REPLACE FUNCTION CONTEXTUAL_SIMILARITY_PARTY(IN tag TEXT, IN party1 TEXT, IN party2 TEXT) RETURNS REAL AS
$$
DECLARE 
	cursor_ballot_with_tag CURSOR FOR select distinct ballotid from outcomes 
	join meps using(mepid) 
  where national_party = party1 
	and ballotid in 
    	(
			select distinct ballotid from outcomes join meps using(mepid) where national_party = party2
		) 
  order by ballotid asc;
	similarity integer;
	-- ceux qui ont le tag
	total_ballot_with_tag integer;
	
BEGIN
	similarity := 0;
	total_ballot_with_tag := 0;
	
	-- Pour chaque ligne, si le ballot est tagu� avec celui sp�cifi�, alors on regarde si les votes des deux partis
  -- sur ce ballot sont semblables, si oui on incr�mente similarity
	for line in cursor_ballot_with_tag LOOP
		IF (select Tagged(line.ballotid, tag) = true) THEN
			total_ballot_with_tag := total_ballot_with_tag + 1;
			IF (select SIMILARITY_NATIONAL_PARTY(line.ballotid, party1, party2) = true) THEN
				similarity := similarity + 1;
			END IF;
		END IF;
	END LOOP;
	
  -- et on retourne un %
	return (similarity::decimal / total_ballot_with_tag) * 100;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION CONTEXTUAL_SIMILARITY_GROUP(IN tag TEXT, IN group1 TEXT, IN group2 TEXT) RETURNS REAL AS
$$
DECLARE 
	cursor_ballot_with_tag CURSOR FOR select distinct ballotid from outcomes 
	join meps using(mepid) 
    where group_id = group1 
	and ballotid in 
    	(
			select distinct ballotid from outcomes join meps using(mepid) where group_id = group2
		) 
    order by ballotid asc;
	similarity integer;
	-- ceux qui ont le tag
	total_ballot_with_tag integer;
	
BEGIN
	similarity := 0;
	total_ballot_with_tag := 0;
	
	
	for line in cursor_ballot_with_tag LOOP
		IF (select Tagged(line.ballotid, tag) = true) THEN
			total_ballot_with_tag := total_ballot_with_tag + 1;
			IF (select SIMILARITY_GROUP(line.ballotid, group1, group2) = true) THEN
				similarity := similarity + 1;
			END IF;
		END IF;
	END LOOP;
	
	return (similarity::decimal / total_ballot_with_tag) * 100;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION CONTEXTUAL_SIMILARITY_COUNTRY(IN tag TEXT, IN country1 TEXT, IN country2 TEXT) RETURNS REAL AS
$$
DECLARE 
	cursor_ballot_with_tag CURSOR FOR select distinct ballotid from outcomes 
	join meps using(mepid) 
    where country = country1 
	and ballotid in 
    	(
			select distinct ballotid from outcomes join meps using(mepid) where country = country2
		) 
    order by ballotid asc;
	similarity integer;
	-- ceux qui ont le tag
	total_ballot_with_tag integer;
	
BEGIN
	similarity := 0;
	total_ballot_with_tag := 0;
	
	
	for line in cursor_ballot_with_tag LOOP
		IF (select Tagged(line.ballotid, tag) = true) THEN
			total_ballot_with_tag := total_ballot_with_tag + 1;
			IF (select SIMILARITY_COUNTRIES(line.ballotid, country1, country2) = true) THEN
				similarity := similarity + 1;
			END IF;
		END IF;
	END LOOP;
	
	return (similarity::decimal / total_ballot_with_tag) * 100;
END;
$$
LANGUAGE PLPGSQL;

-- 11


