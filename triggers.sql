-- 1


CREATE OR REPLACE FUNCTION verify_has_parent_func() RETURNS TRIGGER AS $Tags$
  DECLARE
    pos_last_dot integer;
    count integer;
  BEGIN
    -- on recupere le tag_id que devrait avoir le parent du tag insere s'il existe
    select length(new.tag_id) - position('.' in reverse(new.tag_id)) into pos_last_dot;
    -- on recupere le nombre de tags ayant le bon tag_id
    select count(*) from Tags where tag_id = left(new.tag_id, pos_last_dot) into count;
    -- si le compte de tags et supérieur à 0 c'est donc que le tag insere a un parent
    IF (count > 0 ) THEN
      -- o peut dnc l'insere
      return NEW;
    ELSIF (count = 0) THEN
      -- sinon on leve une exception
      RAISE EXCEPTION 'this tag has no parent';
    END IF;
  END;
$Tags$ LANGUAGE plpgsql;

-- avant chaque insertion dans Tags on effectue la fonction/trigger du desssus
CREATE TRIGGER TRIGGER_ADD_TAG BEFORE INSERT ON Tags
FOR EACH ROW EXECUTE PROCEDURE verify_has_parent_func();