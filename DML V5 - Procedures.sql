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
		"UncolonisedStarSystems"."lastUpdated",
		"UncolonisedStarSystems"."reserveLevel",
		"UncolonisedStarSystems"."landableCount",
		"UncolonisedStarSystems"."walkableCount",
		"UncolonisedStarSystems"."totalHotspots",
		"UncolonisedStarSystems"."systemValue"
	)
	IS DISTINCT FROM (
		EXCLUDED."lastUpdated",
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
		"trailblazerCoords" = EXCLUDED."trailblazerCoords",
		"lastUpdate" = EXCLUDED."lastUpdate"
	WHERE NOT ST_Equals("TrailblazerMegaships"."trailblazerCoords", EXCLUDED."trailblazerCoords")
	AND "TrailblazerMegaships"."lastUpdate" > EXCLUDED."lastUpdate";
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
		duss."uncolonisedSystemID",
		tm."trailblazerID",
		ST_3DDistance(ss."systemCoords", tm."trailblazerCoords")
	FROM "DistinctUncolonisedStarSystems" duss	
	CROSS JOIN "TrailblazerMegaships" tm
	INNER JOIN "StarSystems" ss ON duss."uncolonisedSystemID" = ss."systemID"
	LEFT JOIN "TrailblazerDistances" td ON duss."uncolonisedSystemID" = td."uncolonisedSystemID"
		AND tm."trailblazerID" = td."trailblazerID"
	WHERE td."uncolonisedSystemID" IS NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "InsertColonisableStarSystemsFromStaged"("insertColonised" BOOLEAN)
RETURNS VOID AS $$
BEGIN
	INSERT INTO "ColonisableStarSystems" (
		"colonisedSystemID",
		"uncolonisedSystemID"
	)
	SELECT
		CASE
			WHEN "insertColonised"
				THEN source."systemID"
				ELSE target."systemID"
		END AS "colonisedSystemID",
		
		CASE
			WHEN "insertColonised"
				THEN target."systemID"
				ELSE source."systemID"
		END AS "colonisedSystemID"
	FROM "StagedStarSystems" sss
	INNER JOIN "StarSystems" source ON sss."systemID" = source."systemID"
	INNER JOIN "StarSystems" target ON ST_3DDWithin(source."systemCoords", target."systemCoords", 15)
	WHERE source."isColonised" = "insertColonised"
	AND target."isColonised" = NOT "insertColonised"
	AND source."systemID" != target."systemID"
	ON CONFLICT("colonisedSystemID", "uncolonisedSystemID") DO NOTHING;
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
	AND ("inputClaimDate" > "claimReportDate" OR "claimReportDate" IS NULL);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "UnclaimStarSystem"("inputSystemID" BIGINT, "inputUnclaimDate" TIMESTAMPTZ)
RETURNS VOID AS $$
BEGIN
	UPDATE "UncolonisedStarSystemsAvailability"
	SET
		"isClaimed" = FALSE,
		"claimReportCount" = 0,
		"claimReportDate" = "inputUnclaimDate"
	WHERE "systemID" = "inputSystemID"
	AND "isClaimed" = TRUE
	AND "inputUnclaimDate" > "claimReportDate";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "SelectSearchedColonisedSystems" (
	"inputSystemName" VARCHAR(75),
	"inputFactionName" VARCHAR(75)
)
RETURNS TABLE("colonisedSystemID" BIGINT) AS $$
DECLARE
	"queryString" TEXT;
BEGIN
	"queryString" := '
		SELECT dcss."colonisedSystemID"
		FROM "DistinctColonisedStarSystems" dcss';
	
	IF "inputSystemName" IS NOT NULL AND "inputFactionName" IS NOT NULL THEN
		"queryString" := "queryString" || '
			INNER JOIN "Stations" s ON dcss."colonisedSystemID" = s."systemID"
			INNER JOIN "Factions" f ON s."controllingFaction" = f."factionID"
			WHERE dcss."systemName" = $1
			AND f."factionName" = $2';
			
			RETURN QUERY EXECUTE "queryString"
			USING "inputSystemName", "inputFactionName";
	
	ELSIF "inputSystemName" IS NOT NULL THEN
		"queryString" := "queryString" || '
			WHERE dcss."systemName" = $1';
			
			RETURN QUERY EXECUTE "queryString"
			USING "inputSystemName";
	
	ELSIF "inputFactionName" IS NOT NULL THEN
		"queryString" := "queryString" || '
			INNER JOIN "Stations" s ON dcss."colonisedSystemID" = s."systemID"
			INNER JOIN "Factions" f ON s."controllingFaction" = f."factionID"
			WHERE f."factionName" = $1';
			
			RETURN QUERY EXECUTE "queryString"
			USING "inputFactionName";
	
	ELSE
		RETURN QUERY EXECUTE "queryString";
	
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "SelectSearchResults" (
	"sortOrder" "ResultOrderType",
	"pageNo" INT,
	"resultsPerPage" SMALLINT,
	"inputSystemName" VARCHAR(75),
	"inputFactionName" VARCHAR(75),
	"inputMinBlackHoles" SMALLINT,
	"inputMaxBlackHoles" SMALLINT,
	"inputMinNeutronStars" SMALLINT,
	"inputMaxNeutronStars" SMALLINT,
	"inputMinWhiteDwarves" SMALLINT,
	"inputMaxWhiteDwarves" SMALLINT,
	"inputMinOtherStars" SMALLINT,
	"inputMaxOtherStars" SMALLINT,
	"inputMinEarthLikes" SMALLINT,
	"inputMaxEarthLikes" SMALLINT,
	"inputMinWaterWorlds" SMALLINT,
	"inputMaxWaterWorlds" SMALLINT,
	"inputMinAmmoniaWorlds" SMALLINT,
	"inputMaxAmmoniaWorlds" SMALLINT,
	"inputMinGasGiants" SMALLINT,
	"inputMaxGasGiants" SMALLINT,
	"inputMinHighMetalContents" SMALLINT,
	"inputMaxHighMetalContents" SMALLINT,
	"inputMinMetalRiches" SMALLINT,
	"inputMaxMetalRiches" SMALLINT,
	"inputMinRockyIces" SMALLINT,
	"inputMaxRockyIces" SMALLINT,
	"inputMinRocks" SMALLINT,
	"inputMaxRocks" SMALLINT,
	"inputMinIcys" SMALLINT,
	"inputMaxIcys" SMALLINT,
	"inputMinOrganics" SMALLINT,
	"inputMaxOrganics" SMALLINT,
	"inputMinGeologicals" SMALLINT,
	"inputMaxGeologicals" SMALLINT,
	"inputMinRings" SMALLINT,
	"inputMaxRings" SMALLINT,
	"inputMinLandables" SMALLINT,
	"inputMaxLandables" SMALLINT,
	"inputMinWalkable" SMALLINT,
	"inputMaxWalkable" SMALLINT,
	"inputMaxDistanceToSol" INT,
	"inputHotspotTypes" "HotspotType"[],
	"inputRemovedSystemIDs" BIGINT[]
)
RETURNS jsonb AS $$
DECLARE
	"queryString" TEXT;
	"result" jsonb;
BEGIN
	"queryString" := 'WITH';


	IF "inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL THEN
		"queryString" := "queryString" || '
			"ColonisedSearchResults" AS (
				SELECT DISTINCT "uncolonisedSystemID"
				FROM "ColonisableStarSystems"
				WHERE "colonisedSystemID" IN (
					SELECT "colonisedSystemID"
					FROM "DistinctColonisedStarSystems" dcss
					INNER JOIN "Stations" s ON dcss."colonisedSystemID" = s."systemID"
					INNER JOIN "Factions" f ON s."controllingFaction" = f."factionID"
					WHERE ($42 IS NULL OR dcss."systemName" = $42)
					AND ($43 IS NULL OR f."factionName" = $43)
				)
			),';
	END IF;
	
	IF "inputHotspotTypes" IS NOT NULL AND NOT ("inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL) THEN
		"queryString" := "queryString" || '
			"HotspotSearchResults" AS (
				SELECT "uncolonisedSystemID"
				FROM "DistinctUncolonisedStarSystems" duss
				INNER JOIN "Rings" r ON duss."uncolonisedSystemID" = r."systemID"
				INNER JOIN "Hotspots" h ON r."ringID" = h."ringID"
				WHERE h."hotspotType" = ANY($42)
			),';
	END IF;
	
	IF "inputHotspotTypes" IS NOT NULL AND ("inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL) THEN
		"queryString" := "queryString" || '
			"HotspotSearchResults" AS (
				SELECT "uncolonisedSystemID"
				FROM "DistinctUncolonisedStarSystems" duss
				INNER JOIN "Rings" r ON duss."uncolonisedSystemID" = r."systemID"
				INNER JOIN "Hotspots" h ON r."ringID" = h."ringID"
				WHERE h."hotspotType" = ANY($44)
			),';
	END IF;
	
	"queryString" := "queryString" || '
		"TopResults" AS (
			SELECT 
				duss."uncolonisedSystemID",
				ss."systemName",
				ss."systemCoords",
				uss."lastUpdated",
				uss."reserveLevel",
				uss."landableCount",
				uss."walkableCount",
				uss."distanceToSol",
				uss."totalHotspots",
				uss."systemValue",
				coc."blackHoleCount",
				coc."neutronStarCount",
				coc."whiteDwarves",
				coc."otherStarCount",
				coc."earthLikeCount",
				coc."waterWorldCount",
				coc."ammoniaWorldCount",
				coc."gasGiantCount",
				coc."highMetalContentCount",
				coc."metalRichCount",
				coc."rockyIceBodyCount",
				coc."rockBodyCount",
				coc."icyBodyCount",
				coc."organicCount",
				coc."geologicalsCount",
				coc."ringCount"';
				
	IF "sortOrder" = 'DistanceToTrailblazer' THEN
		"queryString" := "queryString" || '
				, ctbss."distanceToTrailblazer"';
	END IF;
	
	"queryString" := "queryString" || '
			FROM "DistinctUncolonisedStarSystems" duss
			INNER JOIN "StarSystems" ss ON duss."uncolonisedSystemID" = ss."systemID"
			INNER JOIN "UncolonisedStarSystems" uss ON duss."uncolonisedSystemID" = uss."systemID"
			INNER JOIN "ColonyOverrideCounts" coc ON duss."uncolonisedSystemID" = coc."systemID"
			INNER JOIN "UncolonisedStarSystemsAvailability" ussa ON duss."uncolonisedSystemID" = ussa."systemID"';
			
	IF "sortOrder" = 'DistanceToTrailblazer' THEN
		"queryString" := "queryString" || '
			INNER JOIN "ClosestTrailblazerByStarSystem" ctbss ON duss."uncolonisedSystemID" = ctbss."uncolonisedSystemID"';
	END IF;
			
	"queryString" := "queryString" || '
			WHERE';
	
	IF "inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL THEN
		"queryString" := "queryString" || '
			duss."uncolonisedSystemID" IN (
				SELECT "uncolonisedSystemID"
				FROM "ColonisedSearchResults"
			)
			AND';
	END IF;
	
	IF "inputHotspotTypes" IS NOT NULL THEN
		"queryString" := "queryString" || '
			duss."uncolonisedSystemID" IN (
				SELECT "uncolonisedSystemID"
				FROM "HotspotSearchResults"
			)
			AND';
	END IF;
	
	"queryString" := "queryString" || '
			ussa."isLocked" = FALSE
			AND ussa."isClaimed" = FALSE
			AND coc."blackHoleCount" >= $1 AND coc."blackHoleCount" <= $2
			AND coc."neutronStarCount" >= $3 AND coc."neutronStarCount" <= $4
			AND coc."whiteDwarves" >= $5 AND coc."whiteDwarves" <= $6
			AND coc."otherStarCount" >= $7 AND coc."otherStarCount" <= $8
			AND coc."earthLikeCount" >= $9 AND coc."earthLikeCount" <= $10
			AND coc."waterWorldCount" >= $11 AND coc."waterWorldCount" <= $12
			AND coc."ammoniaWorldCount" >= $13 AND coc."ammoniaWorldCount" <= $14
			AND coc."gasGiantCount" >= $15 AND coc."gasGiantCount" <= $16
			AND coc."highMetalContentCount" >= $17 AND coc."highMetalContentCount" <= $18
			AND coc."metalRichCount" >= $19 AND coc."metalRichCount" <= $20
			AND coc."rockyIceBodyCount" >= $21 AND coc."rockyIceBodyCount" <= $22
			AND coc."rockBodyCount" >= $23 AND coc."rockBodyCount" <= $24
			AND coc."icyBodyCount" >= $25 AND coc."icyBodyCount" <= $26
			AND coc."organicCount" >= $27 AND coc."organicCount" <= $28
			AND coc."geologicalsCount" >= $29 AND coc."geologicalsCount" <= $30
			AND coc."ringCount" >= $31 AND coc."ringCount" <= $32
			AND uss."landableCount" >= $33 AND uss."landableCount" <= $34
			AND uss."walkableCount" >= $35 AND uss."walkableCount" <= $36
			AND uss."distanceToSol" <= $37
			AND duss."uncolonisedSystemID" NOT IN (SELECT unnest($41))
			ORDER BY
				CASE WHEN $38 = ''SystemValue'' THEN uss."systemValue" END DESC,
				CASE WHEN $38 = ''MostWalkables'' THEN uss."walkableCount" END DESC,
				CASE WHEN $38 = ''DistanceToSol'' THEN uss."distanceToSol" END ASC,
				CASE WHEN $38 = ''MostHotspots'' THEN uss."totalHotspots" END DESC';
			
	IF "sortOrder" = 'DistanceToTrailblazer' THEN
		"queryString" := "queryString" || '
				, CASE WHEN $38 = ''DistanceToTrailblazer'' THEN ctbss."distanceToTrailblazer" END ASC';
	END IF;
	
	"queryString" := "queryString" || '
			OFFSET (($39 - 1) * $40) ROWS
			LIMIT $40 * 11
		)
		SELECT jsonb_build_object(
			''minFollwingPages'', MIN(tr."minFollwingPages"),
			''results'', jsonb_agg(
				jsonb_build_object(
					''systemID'', tr."uncolonisedSystemID",
					''systemName'', tr."systemName",
					''lastUpdate'', tr."lastUpdated",
					''distanceToSol'', tr."distanceToSol",
					''coordinates'', jsonb_build_object(
							''coordinateX'', ST_X(tr."systemCoords"),
							''coordinateY'', ST_Y(tr."systemCoords"),
							''coordinateZ'', ST_Z(tr."systemCoords")
						),
					''reserveLevel'', tr."reserveLevel",
					''landableCount'', tr."landableCount",
					''walkableCount'', tr."walkableCount",
					''systemCounts'', jsonb_build_object(
						''blackHoleCount'', tr."blackHoleCount",
						''neutronStarCount'', tr."neutronStarCount",
						''whiteDwarves'', tr."whiteDwarves",
						''otherStarCount'', tr."otherStarCount",
						''earthLikeCount'', tr."earthLikeCount",
						''waterWorldCount'', tr."waterWorldCount",
						''ammoniaWorldCount'', tr."ammoniaWorldCount",
						''gasGiantCount'', tr."gasGiantCount",
						''highMetalContentCount'', tr."highMetalContentCount",
						''metalRichCount'', tr."metalRichCount",
						''rockyIceBodyCount'',tr."rockyIceBodyCount",
						''rockBodyCount'', tr."rockBodyCount",
						''icyBodyCount'', tr."icyBodyCount",
						''organicCount'', tr."organicCount",
						''geologicalsCount'', tr."geologicalsCount",
						''ringCount'', tr."ringCount",
						''totalHotspots'', tr."totalHotspots"
					),
					''rings'', (
						SELECT jsonb_agg(
							jsonb_build_object(
								''ringName'', r."ringName",
								''ringType'', r."ringType",
								''hotspots'', (
									SELECT jsonb_agg(
										jsonb_build_object(
											''hotspotType'', h."hotspotType",
											''hotspotCount'', h."hotspotCount"
										)
									)
									FROM "Hotspots" h
									WHERE h."ringID" = r."ringID"
								)
							)
						)
						FROM "Rings" r
						WHERE r."systemID" = tr."uncolonisedSystemID"
					),
					''trailblazers'', (
						SELECT jsonb_agg(
							jsonb_build_object(
								''trailblazerID'', tm."trailblazerID",
								''trailblazerName'', tm."trailblazerName",
								''distanceBetween'', td."distanceBetween"
							)
						)
						FROM "TrailblazerDistances" td
						INNER JOIN "TrailblazerMegaships" tm ON td."trailblazerID" = tm."trailblazerID"
						WHERE td."uncolonisedSystemID" = tr."uncolonisedSystemID"
					),
					''colonisedSystems'', (
						SELECT jsonb_agg(
							jsonb_build_object(
								''colonisedSystemID'', css."colonisedSystemID",
								''systemName'', ss."systemName",
								''stations'', (
									SELECT jsonb_agg(
										jsonb_build_object(
											''stationID'', s."stationID",
											''stationName'', s."stationName",
											''controllingFaction'', f."factionName"
										)
									)
									FROM "Stations" s
									INNER JOIN "Factions" f ON s."controllingFaction" = f."factionID"
									WHERE s."systemID" = css."colonisedSystemID"
								)
							)
						)
						FROM "ColonisableStarSystems" css
						INNER JOIN "StarSystems" ss ON css."colonisedSystemID" = ss."systemID"
						WHERE css."uncolonisedSystemID" = tr."uncolonisedSystemID"
					)
				)
			)
		)
		FROM (
			SELECT 
				*,
				GREATEST((COUNT(*) OVER()) / $40, 1) - 1 "minFollwingPages"
				FROM "TopResults"
				LIMIT $40
		) tr';
		
	IF ("inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL) AND "inputHotspotTypes" IS NULL THEN
		EXECUTE "queryString" INTO "result"
		USING 
		"inputMinBlackHoles", 
		"inputMaxBlackHoles", 
		"inputMinNeutronStars",
		"inputMaxNeutronStars",
		"inputMinWhiteDwarves",
		"inputMaxWhiteDwarves",
		"inputMinOtherStars",
		"inputMaxOtherStars",
		"inputMinEarthLikes",
		"inputMaxEarthLikes",
		"inputMinWaterWorlds",
		"inputMaxWaterWorlds",
		"inputMinAmmoniaWorlds",
		"inputMaxAmmoniaWorlds",
		"inputMinGasGiants",
		"inputMaxGasGiants",
		"inputMinHighMetalContents",
		"inputMaxHighMetalContents",
		"inputMinMetalRiches",
		"inputMaxMetalRiches",
		"inputMinRockyIces",
		"inputMaxRockyIces",
		"inputMinRocks",
		"inputMaxRocks",
		"inputMinIcys",
		"inputMaxIcys",
		"inputMinOrganics",
		"inputMaxOrganics",
		"inputMinGeologicals",
		"inputMaxGeologicals",
		"inputMinRings",
		"inputMaxRings",
		"inputMinLandables",
		"inputMaxLandables",
		"inputMinWalkable",
		"inputMaxWalkable",
		"inputMaxDistanceToSol",
		"sortOrder",
		"pageNo",
		"resultsPerPage",
		"inputRemovedSystemIDs",
		"inputSystemName",
		"inputFactionName";
		
	ELSIF "inputHotspotTypes" IS NOT NULL AND NOT ("inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL) THEN
		EXECUTE "queryString" INTO "result"
		USING 
		"inputMinBlackHoles", 
		"inputMaxBlackHoles", 
		"inputMinNeutronStars",
		"inputMaxNeutronStars",
		"inputMinWhiteDwarves",
		"inputMaxWhiteDwarves",
		"inputMinOtherStars",
		"inputMaxOtherStars",
		"inputMinEarthLikes",
		"inputMaxEarthLikes",
		"inputMinWaterWorlds",
		"inputMaxWaterWorlds",
		"inputMinAmmoniaWorlds",
		"inputMaxAmmoniaWorlds",
		"inputMinGasGiants",
		"inputMaxGasGiants",
		"inputMinHighMetalContents",
		"inputMaxHighMetalContents",
		"inputMinMetalRiches",
		"inputMaxMetalRiches",
		"inputMinRockyIces",
		"inputMaxRockyIces",
		"inputMinRocks",
		"inputMaxRocks",
		"inputMinIcys",
		"inputMaxIcys",
		"inputMinOrganics",
		"inputMaxOrganics",
		"inputMinGeologicals",
		"inputMaxGeologicals",
		"inputMinRings",
		"inputMaxRings",
		"inputMinLandables",
		"inputMaxLandables",
		"inputMinWalkable",
		"inputMaxWalkable",
		"inputMaxDistanceToSol",
		"sortOrder",
		"pageNo",
		"resultsPerPage",
		"inputRemovedSystemIDs",
		"inputHotspotTypes";
		
	ELSIF "inputHotspotTypes" IS NOT NULL AND ("inputSystemName" IS NOT NULL OR "inputFactionName" IS NOT NULL) THEN
		EXECUTE "queryString" INTO "result"
		USING 
		"inputMinBlackHoles", 
		"inputMaxBlackHoles", 
		"inputMinNeutronStars",
		"inputMaxNeutronStars",
		"inputMinWhiteDwarves",
		"inputMaxWhiteDwarves",
		"inputMinOtherStars",
		"inputMaxOtherStars",
		"inputMinEarthLikes",
		"inputMaxEarthLikes",
		"inputMinWaterWorlds",
		"inputMaxWaterWorlds",
		"inputMinAmmoniaWorlds",
		"inputMaxAmmoniaWorlds",
		"inputMinGasGiants",
		"inputMaxGasGiants",
		"inputMinHighMetalContents",
		"inputMaxHighMetalContents",
		"inputMinMetalRiches",
		"inputMaxMetalRiches",
		"inputMinRockyIces",
		"inputMaxRockyIces",
		"inputMinRocks",
		"inputMaxRocks",
		"inputMinIcys",
		"inputMaxIcys",
		"inputMinOrganics",
		"inputMaxOrganics",
		"inputMinGeologicals",
		"inputMaxGeologicals",
		"inputMinRings",
		"inputMaxRings",
		"inputMinLandables",
		"inputMaxLandables",
		"inputMinWalkable",
		"inputMaxWalkable",
		"inputMaxDistanceToSol",
		"sortOrder",
		"pageNo",
		"resultsPerPage",
		"inputRemovedSystemIDs",
		"inputSystemName",
		"inputFactionName",
		"inputHotspotTypes";
		
	ELSE
		EXECUTE "queryString" INTO "result"
		USING 
		"inputMinBlackHoles", 
		"inputMaxBlackHoles", 
		"inputMinNeutronStars",
		"inputMaxNeutronStars",
		"inputMinWhiteDwarves",
		"inputMaxWhiteDwarves",
		"inputMinOtherStars",
		"inputMaxOtherStars",
		"inputMinEarthLikes",
		"inputMaxEarthLikes",
		"inputMinWaterWorlds",
		"inputMaxWaterWorlds",
		"inputMinAmmoniaWorlds",
		"inputMaxAmmoniaWorlds",
		"inputMinGasGiants",
		"inputMaxGasGiants",
		"inputMinHighMetalContents",
		"inputMaxHighMetalContents",
		"inputMinMetalRiches",
		"inputMaxMetalRiches",
		"inputMinRockyIces",
		"inputMaxRockyIces",
		"inputMinRocks",
		"inputMaxRocks",
		"inputMinIcys",
		"inputMaxIcys",
		"inputMinOrganics",
		"inputMaxOrganics",
		"inputMinGeologicals",
		"inputMaxGeologicals",
		"inputMinRings",
		"inputMaxRings",
		"inputMinLandables",
		"inputMaxLandables",
		"inputMinWalkable",
		"inputMaxWalkable",
		"inputMaxDistanceToSol",
		"sortOrder",
		"pageNo",
		"resultsPerPage",
		"inputRemovedSystemIDs";
	
	END IF;
	
	RETURN "result";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "SelectFactionNamesJson"()
RETURNS jsonb AS $$
	SELECT json_agg(to_json("factionName"))
	FROM (
		SELECT "factionName"
		FROM "Factions"
		ORDER BY "factionName" ASC
	) as "factionNames";
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION "SelectColonisedSystemNamesJson"("name" VARCHAR(75))
RETURNS jsonb AS $$
	SELECT json_agg(
		jsonb_build_object(
			'name', "systemName"
		)
	)
	FROM (
		SELECT "systemName"
		FROM "StarSystems"
		WHERE "isColonised" = TRUE
		AND "systemName" ILIKE '%' || "name" || '%'
		LIMIT 100
	) as "systemNames";
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION "RefreshDistinctColonisedStarSystems"()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW "DistinctColonisedStarSystems";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "RefreshDistinctUncolonisedStarSystems"()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW "DistinctUncolonisedStarSystems";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "RefreshClosestTrailblazerByStarSystem"()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW "ClosestTrailblazerByStarSystem";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "RefreshConcurrentlyClosestTrailblazerByStarSystem"()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY "ClosestTrailblazerByStarSystem";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "RefreshMaxSearchValues"()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW "MaxSearchValues";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION "ReportStarSystem"("inputSystemID" BIGINT, "isLockReport" BOOLEAN)
RETURNS VOID AS $$
BEGIN
	IF "isLockReport" THEN
		UPDATE "UncolonisedStarSystemsAvailability"
		SET "lockReportCount" = "lockReportCount" + 1
		WHERE "systemID" = "inputSystemID"
		AND NOT "isLocked";
	
	ELSE
		UPDATE "UncolonisedStarSystemsAvailability"
		SET "claimReportCount" = "claimReportCount" + 1
		WHERE "systemID" = "inputSystemID"
		AND NOT "isClaimed";
	END IF;
END;
$$ LANGUAGE plpgsql;