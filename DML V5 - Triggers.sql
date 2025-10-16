CREATE OR REPLACE FUNCTION "TriggerAddNewSystemsToAvailabilityOnInsert"()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO "UncolonisedStarSystemsAvailability" ("systemID")
	SELECT "systemID"
	FROM "NewlyInserted"
	WHERE "isColonised" = FALSE
	ON CONFLICT("systemID") DO NOTHING;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerAddNewSystemsToAvailabilityOnInsert"
AFTER INSERT ON "StarSystems"
REFERENCING NEW TABLE AS "NewlyInserted"
FOR EACH STATEMENT
EXECUTE FUNCTION "TriggerAddNewSystemsToAvailabilityOnInsert"();

CREATE OR REPLACE FUNCTION "TriggerRemoveUncolonisedSystemOnUpdate"()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD."isColonised" = FALSE AND NEW."isColonised" = TRUE THEN
		DELETE FROM "UncolonisedStarSystems" uss WHERE uss."systemID" = NEW."systemID";
		DELETE FROM "UncolonisedStarSystemsAvailability" ussa WHERE ussa."systemID" = NEW."systemID";
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerRemoveUncolonisedSystemOnUpdate"
AFTER UPDATE ON "StarSystems"
FOR EACH ROW
EXECUTE FUNCTION "TriggerRemoveUncolonisedSystemOnUpdate"();

CREATE OR REPLACE FUNCTION "TriggerAddNewSystemToStaging"()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO "StagedStarSystems" ("systemID")
	VALUES (NEW."systemID")
	ON CONFLICT("systemID") DO NOTHING;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerAddNewSystemToStaging"
AFTER INSERT ON "StarSystems"
FOR EACH ROW
EXECUTE FUNCTION "TriggerAddNewSystemToStaging"();

CREATE OR REPLACE FUNCTION "TriggerAddUpdatedSystemToStaging"()
RETURNS TRIGGER AS $$
BEGIN
	IF OLD."isColonised" = FALSE AND NEW."isColonised" = TRUE THEN
		INSERT INTO "StagedStarSystems" ("systemID")
		VALUES (NEW."systemID")
		ON CONFLICT("systemID") DO NOTHING;
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerAddUpdatedSystemToStaging"
AFTER UPDATE ON "StarSystems"
FOR EACH ROW
EXECUTE FUNCTION "TriggerAddUpdatedSystemToStaging"();

CREATE OR REPLACE FUNCTION "TriggerUpdateAvailabilityLock"()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW."isLocked" = FALSE AND NEW."lockReportCount" >= 10 THEN
		UPDATE "UncolonisedStarSystemsAvailability"
		SET
			"isLocked" = TRUE,
			"lockReportDate" = NOW()
		WHERE "systemID" = NEW."systemID";
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerUpdateAvailabilityLock"
AFTER UPDATE ON "UncolonisedStarSystemsAvailability"
FOR EACH ROW
WHEN (OLD."lockReportCount" IS DISTINCT FROM NEW."lockReportCount")
EXECUTE FUNCTION "TriggerUpdateAvailabilityLock"();

CREATE OR REPLACE FUNCTION "TriggerUpdateAvailabilityClaim"()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW."isClaimed" = FALSE AND NEW."claimReportCount" >= 10 THEN
		UPDATE "UncolonisedStarSystemsAvailability"
		SET
			"isClaimed" = TRUE,
			"claimReportDate" = NOW()
		WHERE "systemID" = NEW."systemID";
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerUpdateAvailabilityClaim"
AFTER UPDATE ON "UncolonisedStarSystemsAvailability"
FOR EACH ROW
WHEN (OLD."claimReportCount" IS DISTINCT FROM NEW."claimReportCount")
EXECUTE FUNCTION "TriggerUpdateAvailabilityClaim"();

CREATE OR REPLACE FUNCTION "TriggerUpdateTrailblazerMegaships"()
RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM "TrailblazerDistances"
	WHERE "trailblazerID" = NEW."trailblazerID";
	
	SELECT "RefreshConcurrentlyClosestTrailblazerByStarSystem"();
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "TriggerUpdateTrailblazerMegaships"
AFTER UPDATE ON "TrailblazerMegaships"
FOR EACH ROW
WHEN (OLD."lastUpdate" < NEW."lastUpdate" AND NOT ST_Equals(OLD."trailblazerCoords", NEW."trailblazerCoords"))
EXECUTE FUNCTION "TriggerUpdateTrailblazerMegaships"();