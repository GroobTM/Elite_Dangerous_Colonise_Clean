-- Creates the AddInsertedSystemToStagingFunc function
CREATE OR REPLACE FUNCTION AddInsertedSystemToStagingFunc()
RETURNS TRIGGER AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM StarSystemStaging sss WHERE sss.systemID = NEW.systemID
	)
	THEN
		INSERT INTO StarSystemStaging
		(systemID, isColonised, coordinateX, coordinateY, coordinateZ, queryType)
		SELECT NEW.systemID, NEW.isColonised, sc.coordinateX, sc.coordinateY, sc.coordinateZ, 'INSERT'
		FROM SystemCoords sc
		WHERE sc.systemID = NEW.systemID;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creates the AddInsertedSystemToStagingTrig trigger
CREATE OR REPLACE TRIGGER AddInsertedSystemToStagingTrig
AFTER INSERT ON StarSystems
FOR EACH ROW
EXECUTE FUNCTION AddInsertedSystemToStagingFunc();


-- Creates the AddUpdatedSystemToStagingFunc function
CREATE OR REPLACE FUNCTION AddUpdatedSystemToStagingFunc()
RETURNS TRIGGER AS $$
DECLARE
	rowsUpdated INT;
BEGIN
	IF NEW.isColonised <> OLD.isColonised THEN
		UPDATE StarSystemStaging
		SET
			isColonised = NEW.isColonised,
			queryType = 'UPDATE'
		WHERE StarSystemStaging.systemID = NEW.systemID;
		
		GET DIAGNOSTICS rowsUpdated = ROW_COUNT;
		
		IF rowsUpdated = 0 THEN
			INSERT INTO StarSystemStaging
			(systemID, isColonised, coordinateX, coordinateY, coordinateZ, queryType)
			SELECT NEW.systemID, NEW.isColonised, sc.coordinateX, sc.coordinateY, sc.coordinateZ, 'UPDATE'
			FROM SystemCoords sc
			WHERE sc.systemID = NEW.systemID;
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creates the AddUpdatedSystemToStagingTrig trigger
CREATE OR REPLACE TRIGGER AddUpdatedSystemToStagingTrig
AFTER UPDATE ON StarSystems
FOR EACH ROW
EXECUTE FUNCTION AddUpdatedSystemToStagingFunc();