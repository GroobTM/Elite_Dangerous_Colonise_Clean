-- Creates the InsertIntoStarSystemsBulkFunc Function
CREATE OR REPLACE FUNCTION InsertIntoStarSystemsBulkFunc(inputStarSystems StarSystemsType[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inss (
		systemID BIGINT,
		systemName VARCHAR(75),
		lastColonisingUpdate TIMESTAMP,
		isColonised BOOLEAN,
		coordinateX NUMERIC(10, 5),
		coordinateY NUMERIC(10, 5),
		coordinateZ NUMERIC(10, 5)
	);
	
	INSERT INTO inss(
		systemID,
		systemName,
		lastColonisingUpdate,
		isColonised,
		coordinateX,
		coordinateY,
		coordinateZ
	)
	SELECT
		systemID,
		systemName,
		lastColonisingUpdate,
		isColonised,
		coordinateX,
		coordinateY,
		coordinateZ
	FROM unnest(inputStarSystems) AS inss(
		systemID,
		systemName,
		lastColonisingUpdate,
		isColonised,
		coordinateX,
		coordinateY,
		coordinateZ
	);

	INSERT INTO SystemCoords
	(systemID, coordinateX, coordinateY, coordinateZ)
	SELECT systemID, coordinateX, coordinateY, coordinateZ
	FROM inss
	ON CONFLICT (systemID) DO NOTHING;
				
	INSERT INTO StarSystems
	(systemID, systemName, isColonised, lastColonisingUpdate)
	SELECT systemID, systemName, isColonised, lastColonisingUpdate
	FROM inss
	ON CONFLICT (systemID) DO UPDATE
	SET
		isColonised = EXCLUDED.isColonised,
		lastColonisingUpdate = EXCLUDED.lastColonisingUpdate
	WHERE StarSystems.lastColonisingUpdate < EXCLUDED.lastColonisingUpdate
	OR (StarSystems.isColonised = FALSE AND EXCLUDED.isColonised = TRUE);
		
	DROP TABLE inss;
END;
$$ LANGUAGE plpgsql;

-- Creates the InsertIntoStationsBulkFunc Function
CREATE OR REPLACE FUNCTION InsertIntoStationsBulkFunc(inputStations StationsType[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE ins (
		stationID BIGINT,
		systemID BIGINT,
		stationName VARCHAR(75),
		controllingFaction VARCHAR(75)
	);

	INSERT INTO ins(
		stationID,
		systemID,
		stationName,
		controllingFaction
	)
	SELECT
		stationID,
		systemID,
		stationName,
		controllingFaction
	FROM unnest(inputStations) AS ins(
		stationID,
		systemID,
		stationName,
		controllingFaction
	);

	
	INSERT INTO Factions (factionName)
	SELECT DISTINCT controllingFaction
	FROM ins
	ON CONFLICT (factionName) DO NOTHING;
	
	INSERT INTO Stations
	(stationID, systemID, stationName, controllingFaction)
	SELECT ins.stationID, ins.systemID, ins.stationName, f.factionID
	FROM ins
	INNER JOIN Factions f ON ins.controllingFaction = f.factionName
	ON CONFLICT (stationID) DO UPDATE
	SET
		stationName = EXCLUDED.stationName,
        controllingFaction = EXCLUDED.controllingFaction;
	
	DROP TABLE ins;
END;
$$ LANGUAGE plpgsql;

-- Creates the InsertIntoBodiesBulkFunc Function
CREATE OR REPLACE FUNCTION InsertIntoBodiesBulkFunc(inputBodies BodiesType[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inb (
		bodyID BIGINT,
		systemID BIGINT,
		bodyName VARCHAR(75),
		bodyType VARCHAR(50),
		isLandable BOOLEAN,
		reserveType VARCHAR(10),
		distanceFromStar INT
	);

	INSERT INTO inb(
		bodyID,
		systemID,
		bodyName,
		bodyType,
		isLandable,
		reserveType,
		distanceFromStar
	)
	SELECT
		bodyID,
		systemID,
		bodyName,
		bodyType,
		isLandable,
		reserveType,
		distanceFromStar
	FROM unnest(inputBodies) AS inb(
		bodyID,
		systemID,
		bodyName,
		bodyType,
		isLandable,
		reserveType,
		distanceFromStar
	);

	INSERT INTO BodyType (typeName)
	SELECT DISTINCT bodyType
	FROM inb
	ON CONFLICT (typeName) DO NOTHING;

	INSERT INTO ReserveType (typeName)
	SELECT DISTINCT reserveType
	FROM inb
	ON CONFLICT (typeName) DO NOTHING;
	
	INSERT INTO Bodies
	(bodyID, systemID, bodyName, bodyType, isLandable, reserveType, distanceFromStar)
	SELECT inb.bodyID, inb.systemID, inb.bodyName, bt.typeID, inb.isLandable, rt.typeID, inb.distanceFromStar
	FROM inb
	INNER JOIN BodyType bt ON inb.bodyType = bt.typeName
	INNER JOIN ReserveType rt ON inb.reserveType = rt.typeName
	ON CONFLICT (bodyID) DO UPDATE
	SET
		isLandable = EXCLUDED.isLandable,
		reserveType = EXCLUDED.reserveType,
		distanceFromStar = EXCLUDED.distanceFromStar;
		
	DROP TABLE inb;
END;
$$ LANGUAGE plpgsql;

-- Creates the InsertIntoRingsBulkFunc Function
CREATE OR REPLACE FUNCTION InsertIntoRingsBulkFunc(inputRings RingsType[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inr (
		ringID INT,
		bodyID BIGINT,
		ringName VARCHAR(75),
		ringType VARCHAR(10)
	);

	INSERT INTO inr(
		ringID,
		bodyID,
		ringName,
		ringType
	)
	SELECT
		ringID,
		bodyID,
		ringName,
		ringType
	FROM unnest(inputRings) AS inr(
		ringID,
		bodyID,
		ringName,
		ringType
	);

	INSERT INTO RingType (typeName)
	SELECT DISTINCT ringType
	FROM inr
	ON CONFLICT (typeName) DO NOTHING;

	
	INSERT INTO Rings
	(ringID, bodyID, ringName, ringType)
	SELECT inr.ringID, inr.bodyID, inr.ringName, rt.typeID
	FROM inr
	INNER JOIN RingType rt ON inr.ringType = rt.typeName
	ON CONFLICT (ringID) DO NOTHING;
	
	DROP TABLE inr;
END;
$$ LANGUAGE plpgsql;

-- Creates the InsertIntoHotspotsBulkFunc Function
CREATE OR REPLACE FUNCTION InsertIntoHotspotsBulkFunc(inputHotspots HotspotsType[])
RETURNS VOID AS $$
BEGIN
	CREATE TEMP TABLE inh (
		ringID INT,
		hotspotType VARCHAR(50),
		hotspotCount SMALLINT
	);
	
	INSERT INTO inh(
		ringID,
		hotspotType,
		hotspotCount
	)
	SELECT
		ringID,
		hotspotType,
		hotspotCount
	FROM unnest(inputHotspots) AS inh(
		ringID,
		hotspotType,
		hotspotCount
	);


	INSERT INTO HotspotType (typeName)
	SELECT DISTINCT hotspotType
	FROM inh
	ON CONFLICT (typeName) DO NOTHING;

	INSERT INTO Hotspots
	(ringID, hotspotID, hotspotCount)
	SELECT inh.ringID, ht.typeID, inh.hotspotCount
	FROM inh
	INNER JOIN hotspotType ht ON inh.hotspotType = ht.typeName
	ON CONFLICT (ringID, hotspotID) DO NOTHING;
	
	DROP TABLE inh;
END;
$$ LANGUAGE plpgsql;

-- Creates the UpdateSystemColonisationStateFunc Function
CREATE OR REPLACE FUNCTION UpdateSystemColonisationStateFunc(inputSystemID BIGINT, updateDate TIMESTAMP)
RETURNS VOID AS $$
BEGIN
	UPDATE StarSystems
	SET lastColonisingUpdate = updateDate
	WHERE systemID = inputSystemID
	AND lastColonisingUpdate < updateDate
	AND isColonised <> TRUE;
END;
$$ LANGUAGE plpgsql;


-- Creates the GetSearchResultsFunc Function
CREATE OR REPLACE FUNCTION GetSearchResultsFunc(
	colonisedSystem VARCHAR(75),
	faction VARCHAR(75),
	sortOrder VARCHAR(75),
	includeColonising BOOLEAN,
	pageNo INT,
	resultsPerPage SMALLINT
)
RETURNS JSONB AS $$
DECLARE
	result JSONB;
BEGIN	
	WITH SearchResults AS (
		SELECT DISTINCT
			nss.colonisedSystemID,
			ss.systemName,
			s.stationID,
			s.stationName,
			f.factionName
		FROM NearbyStarSystems nss
		INNER JOIN StarSystems AS ss ON ss.systemID = nss.colonisedSystemID
		INNER JOIN Stations AS s ON s.systemID = nss.colonisedSystemID
		INNER JOIN Factions f ON f.factionID = s.controllingFaction
		WHERE ss.systemName ILIKE colonisedSystem || '%'
		AND f.factionName ILIKE faction || '%'
	),
	DistinctNearbyValue AS (
		SELECT DISTINCT
			nssv.nearbySystemID,
			nssv.bodyTypesValue,
			nssv.landableBodiesCount,
			nssv.hotspotCount,
			nssv.totalValue,
			nssv.distanceToSol,
			td.trailblazerID,
			td.distanceToTrailblazer
		FROM NearbyStarSystemsValues AS nssv
		INNER JOIN TrailblazerDistances td ON td.systemID = nssv.nearbySystemID
		INNER JOIN NearbyStarSystems nss ON nss.nearbySystemID = nssv.nearbySystemID
		INNER JOIN StarSystems AS ss ON ss.systemID = nss.nearbySystemID
		WHERE nss.colonisedSystemID IN (SELECT DISTINCT colonisedSystemID FROM SearchResults)
		AND (includeColonising = TRUE OR ss.lastColonisingUpdate IS NULL)
	),
	TotalResults AS (
		SELECT COUNT(nearbySystemID) totalCount
		FROM DistinctNearbyValue
	),
	PaginatedResults AS (
		SELECT
			dnv.nearbySystemID,
			dnv.bodyTypesValue,
			dnv.landableBodiesCount,
			dnv.hotspotCount,
			dnv.totalValue,
			dnv.distanceToSol,
			dnv.trailblazerID,
			dnv.distanceToTrailblazer
		FROM DistinctNearbyValue dnv
		ORDER BY
			CASE WHEN sortOrder = 'bodyValue' THEN dnv.bodyTypesValue END DESC,
			CASE WHEN sortOrder = 'landableBodies' THEN dnv.landableBodiesCount END DESC,
			CASE WHEN sortOrder = 'hotspots' THEN dnv.hotspotCount END DESC,
			CASE WHEN sortOrder = 'totalValue' THEN dnv.totalValue END DESC,
			CASE WHEN sortOrder = 'solDistance' THEN dnv.distanceToSol END ASC,
			CASE WHEN sortOrder = 'trailblazerDistance' THEN dnv.distanceToTrailblazer END ASC
		OFFSET ((pageNo - 1) * resultsPerPage) ROWS
		LIMIT resultsPerPage
	)
	SELECT jsonb_build_object(
		'totalCount', (SELECT totalCount FROM TotalResults),
		'results', jsonb_agg(
			jsonb_build_object(
				'nearbySystemID', pr.nearbySystemID,
				'systemName', ss.systemName,
				'lastColonisingUpdate', ss.lastColonisingUpdate,
				'distanceToSol', pr.distanceToSol,
				'landableBodiesCount', pr.landableBodiesCount,
				'coordinates', (
					SELECT jsonb_build_object(
						'coordinateX', c.coordinateX,
						'coordinateY', c.coordinateY,
						'coordinateZ', c.coordinateZ
					)
					FROM SystemCoords c
					WHERE c.systemID = pr.nearbySystemID
					LIMIT 1
				),
				'trailblazer', (
					SELECT jsonb_build_object(
						'trailblazerID', tbm.trailblazerID,
						'trailblazerName', tbm.trailblazerName,
						'distanceToTrailblazer', pr2.distanceToTrailblazer
					)
					FROM PaginatedResults pr2
					INNER JOIN TrailblazerMegaships tbm ON tbm.trailblazerID = pr2.trailblazerID
					WHERE pr2.trailblazerID = pr.trailblazerID
					LIMIT 1
				),
				'bodies', (
					SELECT jsonb_agg(
						jsonb_build_object(
							'bodyID', b.bodyID, 
							'bodyName', b.bodyName, 
							'bodyType', bt.typeName, 
							'isLandable', b.isLandable, 
							'reserveType', ret.typeName,
							'distanceFromStar', b.distanceFromStar,
							'rings', (
								SELECT jsonb_agg(
									jsonb_build_object(
										'ringName', r.ringName, 
										'ringType', rit.typeName, 
										'hotspots', (
											SELECT jsonb_agg(
												jsonb_build_object(
													'hotspotType', ht.typeName, 
													'hotspotCount', h.hotspotCount
												)
											)
											FROM Hotspots h
											LEFT JOIN HotspotType ht ON ht.typeID = h.hotspotID
											WHERE h.ringID = r.ringID
										)
									)
								)
								FROM Rings r
								LEFT JOIN RingType rit ON rit.typeID = r.ringType
								WHERE r.bodyID = b.bodyID
							)
						)
					)
					FROM Bodies b
					LEFT JOIN BodyType bt ON bt.typeID = b.bodyType
					LEFT JOIN ReserveType ret ON ret.typeID = b.reserveType
					WHERE b.systemID = ss.systemID
				),
				'colonisedSystems', (
					SELECT jsonb_agg(
						jsonb_build_object(
							'colonisedSystemID', cs.colonisedSystemID,
							'systemName', cs.systemName,
							'stations', cs.Stations
						)
					)
					FROM (
						SELECT
							sr1.colonisedSystemID,
							sr1.systemName,
							(
								SELECT jsonb_agg(
									jsonb_build_object(
										'stationID', sr2.stationID,
										'stationName', sr2.stationName,
										'factionName', sr2.factionName
									)
								)
								FROM SearchResults sr2
								WHERE sr1.colonisedSystemID = sr2.colonisedSystemID
							) AS stations
						FROM SearchResults sr1
						INNER JOIN NearbyStarSystems nss ON  nss.colonisedSystemID = sr1.colonisedSystemID
						WHERE ss.systemID = nss.nearbySystemID
						AND sr1.factionName ILIKE '%' || faction || '%'
						GROUP BY sr1.colonisedSystemID, sr1.systemName, stations
					) AS cs
				)
			)
		)
	)
	INTO result
	FROM PaginatedResults pr
	INNER JOIN StarSystems AS ss ON ss.systemID = pr.nearbySystemID;
	
	RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Creates the CalculateNearbyStarSystemsValuesFunc Function
CREATE OR REPLACE FUNCTION CalculateNearbyStarSystemsValuesFunc()
RETURNS VOID AS $$
BEGIN
	TRUNCATE TABLE NearbyStarSystemsValues CASCADE;
	
	WITH SystemValues AS (
		SELECT DISTINCT nss.nearbySystemID,
		COUNT(DISTINCT CASE WHEN bt.typeName IN ('Black Hole', 'Neutron Star', 'Ammonia world') THEN b.bodyID END) * 1 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Water world' THEN b.bodyID END) * 2 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Earth-like world' THEN b.bodyID END) * 3
		AS bodyTypesValue,
		COUNT(DISTINCT CASE WHEN b.isLandable = TRUE THEN b.bodyID END) AS landableBodiesCount,
		SUM(COALESCE(h.hotspotCount, 0)) AS hotspotCount
		FROM NearbyStarSystems nss
		INNER JOIN Bodies AS b ON b.systemID = nss.nearbySystemID
		LEFT JOIN Rings AS r ON r.bodyID = b.bodyID
		LEFT JOIN Hotspots AS h ON h.ringID = r.ringID
		LEFT JOIN BodyType AS bt ON bt.typeID = b.bodyType
		GROUP BY nss.nearbySystemID
	)
	INSERT INTO NearbyStarSystemsValues
	(nearbySystemID, bodyTypesValue, landableBodiesCount, hotspotCount, totalValue, distanceToSol)
	SELECT sv.nearbySystemID, sv.bodyTypesValue, sv.landableBodiesCount, sv.hotspotCount,
	(sv.bodyTypesValue * 1.2 + sv.landableBodiesCount * 1 + sv.hotspotCount * 0.6) AS totalValue,
	SQRT(POWER(sc.coordinateX, 2) + POWER(sc.coordinateY, 2) + POWER(sc.coordinateZ, 2)) AS distanceToSol
	FROM SystemValues sv
	INNER JOIN SystemCoords AS sc ON sc.systemID = sv.nearbySystemID;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Creates the GetSystemSummaryFunc function
CREATE OR REPLACE FUNCTION GetSystemSummaryFunc(getColonised BOOLEAN)
RETURNS TABLE (
	systemID BIGINT,
	coordinateX NUMERIC(10, 5),
	coordinateY NUMERIC(10, 5),
	coordinateZ NUMERIC(10, 5)
) AS $$
BEGIN
	RETURN QUERY
	SELECT ss.systemID, sc.coordinateX, sc.coordinateY, sc.coordinateZ
	FROM StarSystems ss
	INNER JOIN SystemCoords sc ON sc.systemID = ss.systemID
	WHERE ss.isColonised = getColonised;
END;
$$ LANGUAGE plpgsql;

-- Creates the GetAASystemsFunc function
CREATE OR REPLACE FUNCTION GetAASystemsFunc()
RETURNS TABLE (
	name VARCHAR(75),
	x NUMERIC(10, 5),
	y NUMERIC(10, 5),
	z NUMERIC(10, 5)
) AS $$
BEGIN
	RETURN QUERY
	SELECT DISTINCT ss.systemName AS name, sc.coordinateX AS x, sc.coordinateY AS y, sc.coordinateZ AS z
	FROM StarSystems ss
	INNER JOIN SystemCoords sc ON sc.systemID = ss.systemID
	INNER JOIN Stations s ON s.systemID = ss.systemID
	INNER JOIN Factions f ON f.factionID = s.controllingFaction
	WHERE factionName = 'Aisling''s Angels';
END;
$$ LANGUAGE plpgsql;

-- Creates the InsertTrailblazerMegashipFunc function
CREATE OR REPLACE FUNCTION InsertTrailblazerMegashipFunc(
	inputID BIGINT,
	inputName VARCHAR(25),
	inputCoordinateX NUMERIC(10, 5),
	inputCoordinateY NUMERIC(10, 5),
	inputCoordinateZ NUMERIC(10, 5),
	inputUpdateDate TIMESTAMP
)
RETURNS VOID AS $$
BEGIN
	INSERT INTO TrailblazerMegaships
	(trailblazerID, trailblazerName, coordinateX, coordinateY, coordinateZ, lastUpdate)
	VALUES 
	(inputID, inputName, inputCoordinateX, inputCoordinateY, inputCoordinateZ, inputUpdateDate)
	ON CONFLICT (trailblazerID) DO UPDATE
	SET
		coordinateX = EXCLUDED.coordinateX,
		coordinateY = EXCLUDED.coordinateY,
		coordinateZ = EXCLUDED.coordinateZ
	WHERE (TrailblazerMegaships.coordinateX <> EXCLUDED.coordinateX
	OR TrailblazerMegaships.coordinateY <> EXCLUDED.coordinateY
	OR TrailblazerMegaships.coordinateZ <> EXCLUDED.coordinateZ)
	AND TrailblazerMegaships.lastUpdate < EXCLUDED.lastUpdate;
END;
$$ LANGUAGE plpgsql;

-- Create CalculateTrailblazerDistancesFunc function
CREATE OR REPLACE FUNCTION CalculateTrailblazerDistancesFunc()
RETURNS VOID AS $$
BEGIN
	TRUNCATE TABLE TrailblazerDistances;
	
	WITH AbsoluteDistances AS (
		SELECT
			tbm.trailblazerID,
			nss.nearbySystemID AS systemID,
			ABS(tbm.coordinateX - sc.coordinateX) AS diffX,
			ABS(tbm.coordinateY - sc.coordinateY) AS diffY,
			ABS(tbm.coordinateZ - sc.coordinateZ) AS diffZ
		FROM TrailblazerMegaships tbm
		CROSS JOIN (SELECT DISTINCT nearbySystemID FROM NearbyStarSystems) nss
		INNER JOIN SystemCoords sc ON sc.systemID = nss.nearbySystemID
	),
	RankedAbsoluteDistances AS (
		SELECT
			trailblazerID,
			systemID,
			diffX,
			diffY,
			diffZ,
			ROW_NUMBER() OVER (PARTITION BY systemID ORDER BY (diffX + diffY + diffZ) ASC) AS distanceRank
		FROM AbsoluteDistances
	)
	INSERT INTO TrailblazerDistances
	(trailblazerID, systemID, distanceToTrailblazer)
	SELECT
		trailblazerID,
		systemID,
		SQRT(
			POWER(diffX, 2) +
			POWER(diffY, 2) +
			POWER(diffZ, 2)
		) AS distanceToTrailblazer
	FROM RankedAbsoluteDistances
	WHERE distanceRank = 1;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION UnclaimSystemFunc(inputSystemID BIGINT, updateDate TIMESTAMP)
RETURNS VOID AS $$
BEGIN
	UPDATE StarSystems
	SET lastColonisingUpdate = NULL
	WHERE systemID = inputSystemID
	AND lastColonisingUpdate < updateDate;
END;
$$ LANGUAGE plpgsql VOLATILE;