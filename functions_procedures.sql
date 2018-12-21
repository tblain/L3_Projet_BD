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
  on split le tag2 à la position 4 et on prend la partie gauche que l'on compare au tag1
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
  tag1 est l'ancêtre de tag2
  avec 
  tag1 = 4
  tag2 = 4.10.3
  on prend la sous-chaine de tag2 de position 1 à celle équivalent
  à la taille de tag1 ce qui donne
  et on retourne tag1 =  (substring(tag2, 1 ,length(tag1)) = '4' ) or parentof()
  parentof car parent => donc ancêtre aussi
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
  -- Pour tous les ballots sélectionnés, si ils ont pour parent ou ancêtre le tag on retourne TRUE
  -- si pas de résultat, on retourne FALSE
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
    -- on sélectionne les différents votes d'un ballot pour un parti
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
    --  on sélectionne les résultats majoritaire à propos d'un ballot pour les deux partis donnés
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
    -- On prend tous les ballots pour lesquelles ont votés les deux partis (party1 et party2)
    -- utiliser LIMIT 100 pour tester les résultat
    cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) 
    where national_party = party1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where national_party = party2) 
    order by ballotid asc;
    total_ballot integer;
    similarity integer;
    
BEGIN
    similarity := 0;
    
    -- mettre total_ballot au nombre utiliser pour LIMIT (si utilisé)
    select count(distinct ballotid) from outcomes join meps using(mepid) 
    where national_party = party1 and ballotid in 
    (select distinct ballotid from outcomes join meps using(mepid) where national_party = party2) into total_ballot;
    
    -- pour chaque ballot on regarde si les résultats sont pareil pour les deux partis, si oui on incrémente similarity
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
    -- comme précédent mais pour group
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
    -- comme précédent mais avec country
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
	
	-- Pour chaque ligne, si le ballot est tagué avec celui spécifié, alors on regarde si les votes des deux partis
  -- sur ce ballot sont semblables, si oui on incrémente similarity
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

/*
	creation de tables pour reduire les temps d'executions
	la première est utilisé pour la creation de la seconde table
		et contient :

 ballotid |  national_party                  |  vote   | count 
----------+-----------------------------------------------------------------------+---------+-------
    48361 | -                                | Against |     2
    48361 | -                                | For     |     8
    48361 | Agir - La Droite constructive    | For     |     1
    48361 | ALDE Romania                     | For     |     2
	
	la table suivante contient la vote majoritaire de chaque parti pour chaque ballot


 ballotid |      national_party  |  vote   
----------+--------------------------+---------
    72230 | Les Patriotes            | Against
    59282 | Les Patriotes            | Abstain
    50901 | Les Patriotes            | For

*/

CREATE table nb_vote_par_party_par_ballot
as
  select ballotid, national_party, vote, count(*)
  from Outcomes o2
  join Meps m2 on (o2.mepid = m2.mepid)
  group by ballotid, national_party, vote;

CREATE table vote_majo_par_party_par_ballot
as
  select ballotid, national_party, vote
  from Outcomes o
  join Meps m on (o.mepid = m.mepid)
  where national_party = 'Green Party' or
  		national_party = 'Europe Écologie'
  group by ballotid, national_party, vote
  having count(*) >= all(
    select count
    from nb_vote_par_party_par_ballot n
    where m.national_party = n.national_party
      and o.ballotid = n.ballotid
  )
  ;

/*
	on a des tables similaires pour les partis nationaux et les pays
*/

create table nb_vote_par_country_par_ballot
as
  select ballotid, country, vote, count(*)
  from Outcomes o2
  join Meps m2 on (o2.mepid = m2.mepid)
  group by ballotid, country, vote;


create table vote_majo_par_country_par_ballot
as
  select ballotid, country, vote
  from Outcomes o
  join Meps m on (o.mepid = m.mepid)
  group by ballotid, country, vote
  having count(*) >= all(
    select count
    from nb_vote_par_country_par_ballot n
    where m.country = n.country
      and o.ballotid = n.ballotid
  )
  ;

-- ces tables ont déja étés créées dans le fichier requetes.sql

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

-- insert into vote_majo_par_party_par_ballot
-- select ballotid, national_party, vote
--   from Outcomes o
--   join Meps m on (o.mepid = m.mepid)
--   where national_party = 'Partido Social Democrata' or
--   		national_party = 'StarostovÃ© a nezÃ¡visli'
  		
--   group by ballotid, national_party, vote
--   having count(*) >= all(
--     select count
--     from nb_vote_par_party_par_ballot n
--     where m.national_party = n.national_party
--       and o.ballotid = n.ballotid
--   )
--   ;


-- drop table statistics_meps;

CREATE TABLE STATISTICS_MEPS (
  mepid integer,
  name_full TEXT,
  nb_participation integer,
  pourcent_simil_party integer,
  pourcent_simil_groupe integer,
  pourcent_simil_country integer
);

CREATE or replace function STATISTICS_MEPS_func()
returns void as
$$
	DECLARE
		-- curseur contenant tous les députés
		cursor_mep CURSOR FOR select * from meps;
		-- curseur à variable qui renvoie les votes d'un député
		cursor_vote CURSOR(mep_id integer) for
			select * from meps r
				join outcomes on (r.mepid=outcomes.mepid)
				where r.mepid = mep_id
				and groupe_id = 'Verts/ALE';
		count integer;
		nb_vote_similaire_party integer;
		nb_vote_similaire_groupe integer;
		nb_vote_similaire_country integer;
		nb_vote integer;
		vote_party TEXT;
		vote_groupe TEXT;
		vote_country TEXT;

	begin
		-- on parcourt les députés
		for mep in cursor_mep LOOP
			-- initialisation des compteurs
			nb_vote := 0;
			nb_vote_similaire_party := 0;
			nb_vote_similaire_groupe := 0;
			nb_vote_similaire_country := 0;

			-- on parcourt les votes du député en cours
			for vote in cursor_vote(mep.mepid) LOOP

				-- on recupere le vote majoritaire du parti national du député
				select vm.vote into vote_party from vote_majo_par_party_par_ballot vm
				where ballotid = vm.ballotid
				  and national_party = mep.national_party;

				-- on recupere le vote majoritaire du pays du deputé
				select vm.vote into vote_country from vote_majo_par_country_par_ballot vm
				where ballotid = vm.ballotid
				  and country = mep.country;

				-- on recupere le vote majoritaire du groupe du député
				select vm.vote into vote_groupe from vote_majo_par_groupe_par_ballot vm
				where ballotid = vm.ballotid
				  and groupe_id = mep.groupe_id;

				-- si son vote est en accord avec celui du parti
				IF (vote.vote = vote_party) THEN
					-- on incremente le compteur de votes similaires
					nb_vote_similaire_party := nb_vote_similaire_party + 1;
				end IF;

				-- si son vote est en accord avec celui du pays
				IF (vote.vote = vote_country) THEN
					-- on incremente le compteur de votes similaires
					nb_vote_similaire_country := nb_vote_similaire_country + 1;
				end IF;

				-- si son vote est en accord avec celui du groupe
				IF (vote.vote = vote_groupe) THEN
					-- on incremente le compteur de votes similaires
					nb_vote_similaire_groupe := nb_vote_similaire_groupe + 1;
				end IF;

				-- on incremente le compteur de votes
				nb_vote := nb_vote + 1;

			end LOOP;

			-- si il y a au moins un vote
			if (nb_vote > 0) then
				insert into statistics_meps(mepid, name_full, nb_participation, pourcent_simil_party, pourcent_simil_groupe, pourcent_simil_country)
					values (
						mep.mepid,
						mep.name_full,
						nb_vote,
						ceil( (nb_vote_similaire_party::decimal/nb_vote::decimal) * 100 ),
						ceil( (nb_vote_similaire_groupe::decimal/nb_vote::decimal) * 100 ),
						ceil( (nb_vote_similaire_country::decimal/nb_vote::decimal) * 100)
					);
			end if;

		end loop;
	end;
$$ LANGUAGE plpgsql;

select STATISTICS_MEPS_func();
select * from statistics_meps;
