-- 1

CREATE OR REPLACE FUNCTION verify_has_parent_func() RETURNS TRIGGER AS $Tags$
  DECLARE
    pos_last_dot integer;
    count integer;
  BEGIN
    select length(new.tag_id) - position('.' in reverse(new.tag_id)) into pos_last_dot;
    select count(*) from Tags where tag_id = left(new.tag_id, pos_last_dot) into count;
    IF (count > 0 ) THEN
      return NEW;
    ELSIF (count = 0) THEN
      RAISE EXCEPTION 'this tag has no parent';
    END IF;
    RETURN NEW;
  END;
$Tags$ LANGUAGE plpgsql;

CREATE TRIGGER TRIGGER_ADD_TAG AFTER INSERT ON Tags
FOR EACH ROW EXECUTE PROCEDURE verify_has_parent_func();

-- 2
