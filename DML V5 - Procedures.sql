CREATE OR REPLACE FUNCTION "InsertStarSystemsBulk"("inputStarSystems" "StarSystemInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE "inss" (
		"systemID" BIGINT,
		"systemName" VARCHAR(75),
		"isColonised" BOOLEAN,
		"coordinateX" NUMERIC(11, 5),
		"coordinateY" NUMERIC(11, 5),
		"coordinateZ" NUMERIC(11, 5)
	);
	
	INSERT INTO "inss" (
		"systemID",
		"systemName",
		"isColonised",
		"coordinateX",
		"coordinateY",
		"coordinateZ"
	)
	SELECT
		"systemID",
		"systemName",
		"isColonised",
		"coordinateX",
		"coordinateY",
		"coordinateZ"
	FROM unnest("inputStarSystems") AS inss (
		"systemID",
		"systemName",
		"isColonised",
		"coordinateX",
		"coordinateY",
		"coordinateZ"
	);

	INSERT INTO "StarSystems" (
		"systemID",
		"systemName",
		"systemCoords",
		"isColonised"
	)
	SELECT
		"systemID",
		"systemName",
		ST_MakePoint("coordinateX", "coordinateY", "coordinateZ"),
		"isColonised"
	FROM inss
	ON CONFLICT ("systemID") DO UPDATE
	SET
		"isColonised" = EXCLUDED."isColonised"
	WHERE "StarSystems"."isColonised" = FALSE
	AND EXCLUDED."isColonised" = TRUE;
	
	DROP TABLE inss;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertStationsBulk"("inputStations" "StationInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE ins (
		"stationID" BIGINT,
		"systemID" BIGINT,
		"stationName" VARCHAR(75),
		"controllingFaction" VARCHAR(75)
	);
	
	INSERT INTO ins (
		"stationID",
		"systemID",
		"stationName",
		"controllingFaction"
	)
	SELECT
		"stationID",
		"systemID",
		"stationName",
		"controllingFaction"
	FROM unnest("inputStations") AS ins (
		"stationID",
		"systemID",
		"stationName",
		"controllingFaction"
	);
	
	-- Insert Factions
	INSERT INTO "Factions" ("factionName")
	SELECT DISTINCT "controllingFaction"
	FROM ins
	ON CONFLICT ("factionName") DO NOTHING;
	
	-- Insert Stations
	INSERT INTO "Stations" (
		"stationID",
		"systemID",
		"stationName",
		"controllingFaction"
	)
	SELECT
		ins."stationID",
		ins."systemID",
		ins."stationName",
		f."factionID"
	FROM ins
	INNER JOIN "Factions" f ON ins."controllingFaction" = f."factionName"
	ON CONFLICT ("stationID") DO UPDATE
	SET
		"stationName" = EXCLUDED."stationName",
		"controllingFaction" = EXCLUDED."controllingFaction"
	WHERE (
		"Stations"."stationName",
		"Stations"."controllingFaction"
	)
	IS DISTINCT FROM (
		EXCLUDED."stationName",
		EXCLUDED."controllingFaction"
	);
	
	DROP TABLE ins;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertUncolonisedStarSystemDetailsBulk"("inputDetails" "UncolonisedDetailsInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE ind (
		"systemID" BIGINT,
		"lastUpdated" TIMESTAMPTZ,
		"reserveLevel" "ReserveType",
		"landableCount" SMALLINT,
		"walkableCount" SMALLINT,
		"distanceToSol" INT,
		"totalHotspots" SMALLINT,
		"systemValue" NUMERIC(5,2),
		"blackHoleCount" SMALLINT,
		"neutronStarCount" SMALLINT,
		"whiteDwarves" SMALLINT,
		"otherStarCount" SMALLINT,
		"earthLikeCount" SMALLINT,
		"waterWorldCount" SMALLINT,
		"ammoniaWorldCount" SMALLINT,
		"gasGiantCount" SMALLINT,
		"highMetalContentCount" SMALLINT,
		"metalRichCount" SMALLINT,
		"rockyIceBodyCount" SMALLINT,
		"rockBodyCount" SMALLINT,
		"icyBodyCount" SMALLINT,
		"organicCount" SMALLINT,
		"geologicalsCount" SMALLINT,
		"ringCount" SMALLINT
	);
	
	INSERT INTO ind (
		"systemID",
		"lastUpdated",
		"reserveLevel",
		"landableCount",
		"walkableCount",
		"distanceToSol",
		"totalHotspots",
		"systemValue",
		"blackHoleCount",
		"neutronStarCount",
		"whiteDwarves",
		"otherStarCount",
		"earthLikeCount",
		"waterWorldCount",
		"ammoniaWorldCount",
		"gasGiantCount",
		"highMetalContentCount",
		"metalRichCount",
		"rockyIceBodyCount",
		"rockBodyCount",
		"icyBodyCount",
		"organicCount",
		"geologicalsCount",
		"ringCount"
	)
	SELECT
		"systemID",
		"lastUpdated",
		"reserveLevel",
		"landableCount",
		"walkableCount",
		"distanceToSol",
		"totalHotspots",
		"systemValue",
		"blackHoleCount",
		"neutronStarCount",
		"whiteDwarves",
		"otherStarCount",
		"earthLikeCount",
		"waterWorldCount",
		"ammoniaWorldCount",
		"gasGiantCount",
		"highMetalContentCount",
		"metalRichCount",
		"rockyIceBodyCount",
		"rockBodyCount",
		"icyBodyCount",
		"organicCount",
		"geologicalsCount",
		"ringCount"
	FROM unnest("inputDetails") AS ind (
		"systemID",
		"lastUpdated",
		"reserveLevel",
		"landableCount",
		"walkableCount",
		"distanceToSol",
		"totalHotspots",
		"systemValue",
		"blackHoleCount",
		"neutronStarCount",
		"whiteDwarves",
		"otherStarCount",
		"earthLikeCount",
		"waterWorldCount",
		"ammoniaWorldCount",
		"gasGiantCount",
		"highMetalContentCount",
		"metalRichCount",
		"rockyIceBodyCount",
		"rockBodyCount",
		"icyBodyCount",
		"organicCount",
		"geologicalsCount",
		"ringCount"
	);
	
	-- Insert UncolonisedStarSystems
	INSERT INTO "UncolonisedStarSystems" (
		"systemID",
		"lastUpdated",
		"reserveLevel",
		"landableCount",
		"walkableCount",
		"distanceToSol",
		"totalHotspots",
		"systemValue"
	)
	SELECT
		"systemID",
		"lastUpdated",
		"reserveLevel",
		"landableCount",
		"walkableCount",
		"distanceToSol",
		"totalHotspots",
		"systemValue"
	FROM ind
	ON CONFLICT ("systemID") DO UPDATE
	SET
		"lastUpdated" = EXCLUDED."lastUpdated",
		"reserveLevel" = EXCLUDED."reserveLevel",
		"landableCount" = EXCLUDED."landableCount",
		"walkableCount" = EXCLUDED."walkableCount",
		"totalHotspots" = EXCLUDED."totalHotspots",
		"systemValue" = EXCLUDED."systemValue"
	WHERE (
		"UncolonisedStarSystems"."reserveLevel",
		"UncolonisedStarSystems"."landableCount",
		"UncolonisedStarSystems"."walkableCount",
		"UncolonisedStarSystems"."totalHotspots",
		"UncolonisedStarSystems"."systemValue"
	)
	IS DISTINCT FROM (
		EXCLUDED."reserveLevel",
		EXCLUDED."landableCount",
		EXCLUDED."walkableCount",
		EXCLUDED."totalHotspots",
		EXCLUDED."systemValue"
	);
	
	
	-- Insert ColonyOverrideCounts
	INSERT INTO "ColonyOverrideCounts" (
		"systemID",
		"blackHoleCount",
		"neutronStarCount",
		"whiteDwarves",
		"otherStarCount",
		"earthLikeCount",
		"waterWorldCount",
		"ammoniaWorldCount",
		"gasGiantCount",
		"highMetalContentCount",
		"metalRichCount",
		"rockyIceBodyCount",
		"rockBodyCount",
		"icyBodyCount",
		"organicCount",
		"geologicalsCount",
		"ringCount"
	)
	SELECT
		"systemID",
		"blackHoleCount",
		"neutronStarCount",
		"whiteDwarves",
		"otherStarCount",
		"earthLikeCount",
		"waterWorldCount",
		"ammoniaWorldCount",
		"gasGiantCount",
		"highMetalContentCount",
		"metalRichCount",
		"rockyIceBodyCount",
		"rockBodyCount",
		"icyBodyCount",
		"organicCount",
		"geologicalsCount",
		"ringCount"
	FROM ind
	ON CONFLICT ("systemID") DO UPDATE
	SET
		"blackHoleCount" = EXCLUDED."blackHoleCount",
		"neutronStarCount" = EXCLUDED."neutronStarCount",
		"whiteDwarves" = EXCLUDED."whiteDwarves",
		"otherStarCount" = EXCLUDED."otherStarCount",
		"earthLikeCount" = EXCLUDED."earthLikeCount",
		"waterWorldCount" = EXCLUDED."waterWorldCount",
		"ammoniaWorldCount" = EXCLUDED."ammoniaWorldCount",
		"gasGiantCount" = EXCLUDED."gasGiantCount",
		"highMetalContentCount" = EXCLUDED."highMetalContentCount",
		"metalRichCount" = EXCLUDED."metalRichCount",
		"rockyIceBodyCount" = EXCLUDED."rockyIceBodyCount",
		"rockBodyCount" = EXCLUDED."rockBodyCount",
		"icyBodyCount" = EXCLUDED."icyBodyCount",
		"organicCount" = EXCLUDED."organicCount",
		"geologicalsCount" = EXCLUDED."geologicalsCount",
		"ringCount" = EXCLUDED."ringCount"
	WHERE (
		"ColonyOverrideCounts"."blackHoleCount",
		"ColonyOverrideCounts"."neutronStarCount",
		"ColonyOverrideCounts"."whiteDwarves",
		"ColonyOverrideCounts"."otherStarCount",
		"ColonyOverrideCounts"."earthLikeCount",
		"ColonyOverrideCounts"."waterWorldCount",
		"ColonyOverrideCounts"."ammoniaWorldCount",
		"ColonyOverrideCounts"."gasGiantCount",
		"ColonyOverrideCounts"."highMetalContentCount",
		"ColonyOverrideCounts"."metalRichCount",
		"ColonyOverrideCounts"."rockyIceBodyCount",
		"ColonyOverrideCounts"."rockBodyCount",
		"ColonyOverrideCounts"."icyBodyCount",
		"ColonyOverrideCounts"."organicCount",
		"ColonyOverrideCounts"."geologicalsCount",
		"ColonyOverrideCounts"."ringCount"
	)
	IS DISTINCT FROM (
		EXCLUDED."blackHoleCount",
		EXCLUDED."neutronStarCount",
		EXCLUDED."whiteDwarves",
		EXCLUDED."otherStarCount",
		EXCLUDED."earthLikeCount",
		EXCLUDED."waterWorldCount",
		EXCLUDED."ammoniaWorldCount",
		EXCLUDED."gasGiantCount",
		EXCLUDED."highMetalContentCount",
		EXCLUDED."metalRichCount",
		EXCLUDED."rockyIceBodyCount",
		EXCLUDED."rockBodyCount",
		EXCLUDED."icyBodyCount",
		EXCLUDED."organicCount",
		EXCLUDED."geologicalsCount",
		EXCLUDED."ringCount"
	);
	
	DROP TABLE ind;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertRingsBulk"("inputRings" "RingInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inr (
		"systemID" BIGINT,
		"ringName" VARCHAR(75),
		"ringType" "RingType"
	);
	
	INSERT INTO inr (
		"systemID",
		"ringName",
		"ringType"
	)
	SELECT
		"systemID",
		"ringName",
		"ringType"
	FROM unnest("inputRings") AS inr (
		"systemID",
		"ringName",
		"ringType"
	);
	
	INSERT INTO "Rings" (
		"systemID",
		"ringName",
		"ringType"
	)
	SELECT 
		"systemID",
		"ringName",
		"ringType"
	FROM inr
	ON CONFLICT ("systemID", "ringName") DO NOTHING;

	DROP TABLE inr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertHotspotsBulk"("inputHotspots" "HotspotInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inh (
		"systemID" BIGINT,
		"ringName" VARCHAR(75),
		"hotspotType" "HotspotType",
		"hotspotCount" SMALLINT
	);
	
	INSERT INTO inh (
		"systemID",
		"ringName",
		"hotspotType",
		"hotspotCount"
	)
	SELECT
		"systemID",
		"ringName",
		"hotspotType",
		"hotspotCount"
	FROM unnest("inputHotspots") AS inh (
		"systemID",
		"ringName",
		"hotspotType",
		"hotspotCount"
	);
	
	INSERT INTO "Hotspots" (
		"ringID",
		"hotspotType",
		"hotspotCount"
	)
	SELECT 
		r."ringID",
		inh."hotspotType",
		inh."hotspotCount"
	FROM inh
	INNER JOIN "Rings" r ON inh."systemID" = r."systemID" AND inh."ringName" = r."ringName"
	ON CONFLICT ("ringID", "hotspotType") DO UPDATE
	SET
		"hotspotCount" = EXCLUDED."hotspotCount"
	WHERE "Hotspots"."hotspotCount" != EXCLUDED."hotspotCount";

	DROP TABLE inh;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertColonisableStarSystemsBulk"("inputColonisables" "ColonisableInsertType"[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inc (
		"colonisedSystemID" BIGINT,
		"uncolonisedSystemID" BIGINT
	);
	
	INSERT INTO inc (
		"colonisedSystemID",
		"uncolonisedSystemID"
	)
	SELECT
		"colonisedSystemID",
		"uncolonisedSystemID"
	FROM unnest ("inputColonisables") AS inc (
		"colonisedSystemID",
		"uncolonisedSystemID"
	);
	
	INSERT INTO "ColonisableStarSystems" (
		"colonisedSystemID",
		"uncolonisedSystemID"
	)
	SELECT
		"colonisedSystemID",
		"uncolonisedSystemID"
	FROM inc
	ON CONFLICT ("colonisedSystemID", "uncolonisedSystemID") DO NOTHING;
	
	DROP TABLE inc;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION "InsertTrailblazerMegaship"(
	"inputID" BIGINT,
	"inputName" VARCHAR(25),
	"inputCoordX" NUMERIC(11, 5),
	"inputCoordY" NUMERIC(11, 5),
	"inputCoordZ" NUMERIC(11, 5),
	"inputUpdateDate" TIMESTAMPTZ
)
RETURNS VOID AS $$
BEGIN
	INSERT INTO "TrailblazerMegaships" (
		"trailblazerID",
		"trailblazerName",
		"trailblazerCoords",
		"lastUpdate"
	)
	VALUES (
		"inputID",
		"inputName",
		ST_MakePoint("inputCoordX", "inputCoordY", "inputCoordZ"),
		"inputUpdateDate"
	)
	ON CONFLICT ("trailblazerID") DO UPDATE
	SET
		"trailblazerCoordX" = EXCLUDED."trailblazerCoordX",
		"trailblazerCoordY" = EXCLUDED."trailblazerCoordY",
		"trailblazerCoordZ" = EXCLUDED."trailblazerCoordZ",
		"lastUpdate" = EXCLUDED."lastUpdate"
	WHERE (
		"TrailblazerMegaships"."trailblazerCoordX",
		"TrailblazerMegaships"."trailblazerCoordY",
		"TrailblazerMegaships"."trailblazerCoordZ"
	)
	IS DISTINCT FROM (
		EXCLUDED."trailblazerCoordX",
		EXCLUDED."trailblazerCoordY",
		EXCLUDED."trailblazerCoordZ"
	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertTrailblazerDistances"()
RETURNS VOID AS $$
BEGIN
	INSERT INTO "TrailblazerDistances" (
		"uncolonisedSystemID",
		"trailblazerID",
		"distanceBetween"
	)
	SELECT
		css."uncolonisedSystemID",
		tm."trailblazerID",
		ST_3DDistance(ss."systemCoords", tm."trailblazerCoords")
	FROM "TrailblazerMegaships" tm
	CROSS JOIN (
		SELECT DISTINCT "uncolonisedSystemID"
		FROM "ColonisableStarSystems"
		WHERE "uncolonisedSystemID" NOT IN (
			SELECT "uncolonisedSystemID"
			FROM "TrailblazerDistances"
		)
	) AS css
	INNER JOIN "StarSystems" ss ON css."uncolonisedSystemID" = ss."systemID";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "SelectStarSystems"("getColonised" BOOLEAN)
RETURNS TABLE (
	"systemID" BIGINT,
	"coordinateX" DOUBLE PRECISION,
	"coordinateY" DOUBLE PRECISION,
	"coordinateZ" DOUBLE PRECISION
) AS $$
BEGIN
	RETURN QUERY
	SELECT 
		ss."systemID",
		ST_X(ss."systemCoords") AS "coordinateX",
		ST_Y(ss."systemCoords") AS "coordinateY",
		ST_Z(ss."systemCoords") AS "coordinateZ"
	FROM "StarSystems" ss
	WHERE ss."isColonised" = "getColonised";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "SelectStagedStarSystems"()
RETURNS TABLE (
	"systemID" BIGINT,
	"isColonised" BOOLEAN,
	"coordinateX" DOUBLE PRECISION,
	"coordinateY" DOUBLE PRECISION,
	"coordinateZ" DOUBLE PRECISION
) AS $$
BEGIN
	RETURN QUERY
	SELECT 
		sss."systemID",
		ss."isColonised",
		ST_X(ss."systemCoords") AS "coordinateX",
		ST_Y(ss."systemCoords") AS "coordinateY",
		ST_Z(ss."systemCoords") AS "coordinateZ"
	FROM "StagedStarSystems" sss
	INNER JOIN "StarSystems" ss ON sss."systemID" = ss."systemID";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ClaimStarSystem"("inputSystemID" BIGINT, "inputClaimDate" TIMESTAMPTZ)
RETURNS VOID AS $$
BEGIN
	UPDATE "UncolonisedStarSystemsAvailability"
	SET
		"isClaimed" = TRUE,
		"claimReportDate" = "inputClaimDate"
	WHERE "systemID" = "inputSystemID"
	AND "isClaimed" = FALSE
	AND "inputClaimDate" > "claimReportDate";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "UnclaimStarSystem"("inputSystemID" BIGINT, "inputUnclaimDate" TIMESTAMPTZ)
RETURNS VOID AS $$
BEGIN
	UPDATE "UncolonisedStarSystemsAvailability"
	SET
		"isClaimed" = FALSE,
		"claimReportCount" = 0,
		"claimReportDate" = NULL
	WHERE "systemID" = "inputSystemID"
	AND "isClaimed" = TRUE
	AND "inputUnclaimDate" > "claimReportDate";
END;
$$ LANGUAGE plpgsql;