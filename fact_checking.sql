-- 1

CREATE OR REPLACE FUNCTION WE_ARE_THE_OPPOSITION_PARTY(IN party TEXT) RETURNS REAL AS
$$
DECLARE 
  -- on veut les ids des ballots pour lesquelles ont vot? les membres du parti 'party' 
	cursor_ballot CURSOR FOR select distinct ballotid from outcomes join meps using(mepid) where national_party = party order by ballotid asc;
  -- Le nombre de vote contre pour chaque ballot
	against integer;
	-- nombre total de vote auxquelles ?particip?le parti
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
	-- nombre total de vote auxquelles à participé le groupe
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

/*
	Pour un groupe on peut utiliser la fonction nous_sommes_uni_groupe
	avec comme argument l'id du groupe en question qui renvoie la moyenne
	de l'accord de ses députés avec le vote majoritaire.

	la fonction est facilement derivable pour un pays ou un parti national
*/

-- table qui stoque le nombre de vote par député pour accelerer la fonction d'après
create table nb_vote_par_depute as
	select meps.mepid, count(*)
	from meps join outcomes on (meps.mepid=outcomes.mepid)
	group by meps.mepid;

CREATE OR REPLACE FUNCTION nous_sommes_uni_groupe(groupe_id_arg TEXT) RETURNS REAL AS $$
	DECLARE
		pourcent_unis real;
	BEGIN
		select avg(ceil(cast(count as decimal)/
				(select count from nb_vote_par_depute n where n.mepid = r.mepid) * 100)) into pourcent_unis
			from (
			  select groupe_id, m2.mepid, count(*) as count
			  from Outcomes o2
			  join meps m2 on (o2.mepid = m2.mepid)
			  where groupe_id = groupe_id_arg and
			  	vote = any(
			  		select vote
						  from vote_majo_par_groupe_par_ballot v
						  where v.ballotid = o2.ballotid
						  and v.groupe_id = m2.groupe_id
			  	)
			  group by groupe_id, m2.mepid
			  order by groupe_id, count(groupe_id) desc
			) r
			group by groupe_id;

			return pourcent_unis;
	END;
$$ LANGUAGE plpgsql;