-- Creates the InsertIntoStarSystemsBulk Procedure
CREATE PROCEDURE InsertIntoStarSystemsBulk
	@inputStarSystems StarSystemsTable READONLY
AS
BEGIN
	-- Inserts new coordinates into SystemCoords.
	INSERT INTO SystemCoords
	(systemID, coordinateX, coordinateY, coordinateZ)
	SELECT inss.systemID, inss.coordinateX, inss.coordinateY, inss.coordinateZ
	FROM @inputStarSystems inss
	WHERE NOT EXISTS (
		SELECT 1 FROM SystemCoords WHERE SystemCoords.systemID = inss.systemID
	);
	
	-- Updates existing systems in StarSystems
	UPDATE StarSystems
	SET
		StarSystems.isColonised = inss.isColonised,
		StarSystems.lastColonisingUpdate = inss.lastColonisingUpdate
	FROM StarSystems
	INNER JOIN @inputStarSystems inss ON StarSystems.systemID = inss.systemID;
	
	-- Inserts new systems into StarSystems.
	INSERT INTO StarSystems
	(systemID, systemName, isColonised, lastColonisingUpdate)
	SELECT inss.systemID, inss.systemName, inss.isColonised, inss.lastColonisingUpdate
	FROM @inputStarSystems inss
	WHERE NOT EXISTS (
		SELECT 1 FROM StarSystems WHERE StarSystems.systemID = inss.systemID
	);
END;

-- Creates the InsertIntoStationsBulk Procedure
CREATE PROCEDURE InsertIntoStationsBulk
	@inputStations StationsTable READONLY
AS
BEGIN
	DECLARE @resolvedFactions TABLE (
		factionName VARCHAR(75) PRIMARY KEY,
		factionID INT
	);
	
	-- Inserts new factions into Factions.
	INSERT INTO dbo.Factions (factionName)
	OUTPUT inserted.factionName, inserted.factionID INTO @resolvedFactions
	SELECT DISTINCT ins.controllingFaction
	FROM @inputStations ins
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.Factions f
		WHERE f.factionName = ins.controllingFaction
	);
	
	-- Inserts existing factions into resolvedFactions.
	INSERT INTO @resolvedFactions (factionName, factionID)
	SELECT DISTINCT f.factionName, f.factionID
	FROM dbo.Factions f
	INNER JOIN @inputStations ins ON ins.controllingFaction = f.factionName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedFactions rf WHERE rf.factionName = f.factionName
	);
	
	-- Updates existing stations in Stations
	UPDATE Stations
	SET
		Stations.stationName = ins.stationName,
		Stations.controllingFaction = rf.factionID
	FROM Stations
	INNER JOIN @inputStations ins ON Stations.stationID = ins.stationID
	INNER JOIN @resolvedFactions rf ON ins.controllingFaction = rf.factionName;
	
	-- Inserts new stations into Stations.
	INSERT INTO Stations
	(stationID, systemID, stationName, controllingFaction)
	SELECT ins.stationID, ins.systemID, ins.stationName, rf.factionID
	FROM @inputStations ins
	INNER JOIN @resolvedFactions rf ON ins.controllingFaction = rf.factionName
	WHERE NOT EXISTS (
		SELECT 1 FROM Stations
		WHERE Stations.stationID = ins.stationID
	);
END;

-- Creates the InsertIntoBodiesBulk Procedure
CREATE PROCEDURE InsertIntoBodiesBulk
	@inputBodies BodiesTable READONLY
AS
BEGIN
	DECLARE @resolvedBodyTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID TINYINT
	);
	DECLARE @resolvedReserveTypes TABLE (
		typeName VARCHAR(10) PRIMARY KEY,
		typeID TINYINT
	);
	
	-- Inserts new types into BodyType.
	INSERT INTO dbo.BodyType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedBodyTypes
	SELECT DISTINCT inb.bodyType
	FROM @inputBodies inb
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.BodyType bt
		WHERE bt.typeName = inb.bodyType
	);
	
	-- Inserts existing types into resolvedBodyTypes.
	INSERT INTO @resolvedBodyTypes (typeName, typeID)
	SELECT DISTINCT bt.typeName, bt.typeID
	FROM dbo.BodyType bt
	INNER JOIN @inputBodies inb ON inb.bodyType = bt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedBodyTypes rbt WHERE rbt.typeName = bt.typeName
	);
	
	-- Inserts new types into ReserveType.
	INSERT INTO dbo.ReserveType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedReserveTypes
	SELECT DISTINCT inb.reserveType
	FROM @inputBodies inb
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.ReserveType rt
		WHERE rt.typeName = inb.reserveType
	);
	
	-- Inserts existing types into resolvedReserveTypes.
	INSERT INTO @resolvedReserveTypes (typeName, typeID)
	SELECT DISTINCT rt.typeName, rt.typeID
	FROM dbo.ReserveType rt
	INNER JOIN @inputBodies inb ON inb.reserveType = rt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedReserveTypes rrt WHERE rrt.typeName = rt.typeName
	);
	
	-- Updates existing bodies in Bodies
	UPDATE Bodies
	SET
		Bodies.isLandable = inb.isLandable,
		Bodies.reserveType = rrt.typeID
	FROM Bodies
	INNER JOIN @inputBodies inb ON Bodies.bodyID = inb.bodyID
	INNER JOIN @resolvedReserveTypes rrt ON inb.reserveType = rrt.typeName;
	
	-- Inserts new bodies into Bodies.
	INSERT INTO Bodies
	(bodyID, systemID, bodyName, bodyType, isLandable, reserveType)
	SELECT inb.bodyID, inb.systemID, inb.bodyName, rbt.typeID, inb.isLandable, rrt.typeID
	FROM @inputBodies inb
	INNER JOIN @resolvedBodyTypes rbt ON inb.bodyType = rbt.typeName
	INNER JOIN @resolvedReserveTypes rrt ON inb.reserveType = rrt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM Bodies
		WHERE Bodies.bodyID = inb.bodyID
	);
END;

-- Creates the InsertIntoRingsBulk Procedure
CREATE PROCEDURE InsertIntoRingsBulk
	@inputRings RingsTable READONLY
AS
BEGIN
	DECLARE @resolvedRingTypes TABLE (
		typeName VARCHAR(10) PRIMARY KEY,
		typeID TINYINT
	);
	
	-- Inserts new types into RingType.
	INSERT INTO dbo.RingType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedRingTypes
	SELECT DISTINCT inr.ringType
	FROM @inputRings inr
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.RingType rt
		WHERE inr.ringType = rt.typeName
	);
	
	-- Inserts existing types into resolvedRingTypes.
	INSERT INTO @resolvedRingTypes (typeName, typeID)
	SELECT DISTINCT rt.typeName, rt.typeID
	FROM dbo.RingType rt
	INNER JOIN @inputRings inr ON inr.ringType = rt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedRingTypes rrt WHERE rrt.typeName = rt.typeName
	);

	-- Inserts new rings into Rings
	INSERT INTO Rings
	(ringID, bodyID, ringName, ringType)
	SELECT inr.ringID, inr.bodyID, inr.ringName, rrt.typeID
	FROM @inputRings inr
	INNER JOIN @resolvedRingTypes rrt ON inr.ringType = rrt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM Rings
		WHERE Rings.ringID = inr.ringID
	);
END;

-- Creates the InsertIntoHotspotsBulk Procedure
CREATE PROCEDURE InsertIntoHotspotsBulk
	@inputHotspots HotspotsTable READONLY
AS
BEGIN
		DECLARE @resolvedHotspotTypes TABLE (
			typeName VARCHAR(50) PRIMARY KEY,
			typeID TINYINT
		);
		
		-- Inserts new types into HotspotType.
		INSERT INTO dbo.HotspotType (typeName)
		OUTPUT inserted.typeName, inserted.typeID INTO @resolvedHotspotTypes
		SELECT DISTINCT inh.hotspotType
		FROM @inputHotspots inh
		WHERE NOT EXISTS (
			SELECT 1 FROM dbo.HotspotType ht
			WHERE inh.hotspotType = ht.typeName
		);
		
		-- Inserts existing types into resolvedHotspotTypes.
		INSERT INTO @resolvedHotspotTypes (typeName, typeID)
		SELECT DISTINCT ht.typeName, ht.typeID
		FROM dbo.HotspotType ht
		INNER JOIN @inputHotspots inh ON inh.hotspotType = ht.typeName
		WHERE NOT EXISTS (
			SELECT 1 FROM @resolvedHotspotTypes rht WHERE rht.typeName = ht.typeName
		);
		
		-- Inserts new hotspots into Hotspots
		INSERT INTO Hotspots
		(ringID, hotspotID, hotspotCount)
		SELECT inh.ringID, rht.typeID, inh.hotspotCount
		FROM @inputHotspots inh
		INNER JOIN @resolvedHotspotTypes rht ON inh.hotspotType = rht.typeName
		WHERE NOT EXISTS (
			SELECT 1 FROM Hotspots
			WHERE Hotspots.ringID = inh.ringID
			AND Hotspots.hotspotID = rht.typeID
		);
END;

-- Creates the UpdateSystemColonisationState procedure
CREATE PROCEDURE UpdateSystemColonisationState
	@systemID BIGINT
AS
BEGIN
	DECLARE @now DATE;
	
	SET @now = CAST(GETUTCDATE() AS DATE);

	UPDATE StarSystems
	SET lastColonisingUpdate = @now
	WHERE systemID = @systemID
	AND isColonised <> 1;
END;

-- Creates the GetSearchResults Procedure.
CREATE PROCEDURE GetSearchResults
	@searchParameters SearchParametersTable READONLY,
	@pageNo SMALLINT,
	@resultsPerPage SMALLINT
AS
BEGIN
	DECLARE @colonisedSystem VARCHAR(75);
	DECLARE @faction VARCHAR(75);
	DECLARE @sortOrder VARCHAR(75);
	DECLARE @includeColonising BIT;

	SET NOCOUNT ON;

	SELECT TOP 1 @colonisedSystem = colonisedSystem, @faction = faction, @sortOrder = sortOrder, @includeColonising = includeColonising
	FROM @searchParameters;

	WITH SearchResults AS (
		SELECT DISTINCT nss.colonisedSystemID, ss.systemName, s.stationID, s.stationName, f.factionName
		FROM NearbyStarSystems nss
		INNER JOIN StarSystems AS ss ON ss.systemID = nss.colonisedSystemID
		INNER JOIN Stations AS s ON s.systemID = nss.colonisedSystemID
		INNER JOIN Factions f ON f.factionID = s.controllingFaction
		WHERE ss.systemName LIKE @colonisedSystem + '%' AND f.factionName LIKE @faction + '%'
	),
	DistinctNearbyValue AS (
		SELECT DISTINCT nssv.nearbySystemID,
		nssv.bodyTypesValue,
		nssv.landableBodiesCount,
		nssv.hotspotCount,
		nssv.totalValue,
		nssv.distanceToSol
		FROM NearbyStarSystemsValues AS nssv
		INNER JOIN NearbyStarSystems nss ON nss.nearbySystemID = nssv.nearbySystemID
		INNER JOIN StarSystems AS ss ON ss.systemID = nss.nearbySystemID
		WHERE nss.colonisedSystemID IN (SELECT DISTINCT colonisedSystemID FROM SearchResults)
		AND (@includeColonising = 1 OR ss.lastColonisingUpdate IS NULL)
	),
	TotalResults AS (
		SELECT COUNT(nearbySystemID) totalCount
		FROM DistinctNearbyValue
	),
	PaginatedResults AS (
		SELECT dnv.nearbySystemID,
		dnv.bodyTypesValue,
		dnv.landableBodiesCount,
		dnv.hotspotCount,
		dnv.totalValue,
		dnv.distanceToSol
		FROM DistinctNearbyValue dnv
		ORDER BY
			CASE WHEN @sortOrder = 'bodyValue' THEN dnv.bodyTypesValue END DESC,
			CASE WHEN @sortOrder = 'landableBodies' THEN dnv.landableBodiesCount END DESC,
			CASE WHEN @sortOrder = 'hotspots' THEN dnv.hotspotCount END DESC,
			CASE WHEN @sortOrder = 'totalValue' THEN dnv.totalValue END DESC,
			CASE WHEN @sortOrder = 'solDistance' THEN dnv.distanceToSol END DESC
		OFFSET @pageNo * @resultsPerPage ROWS
		FETCH NEXT @resultsPerPage ROWS ONLY
	)
	SELECT (
		SELECT
			(
				SELECT totalCount FROM TotalResults
			) AS totalCount,
			pr.nearbySystemID,
			ss.systemName,
			ss.lastColonisingUpdate,
			pr.distanceToSol,
			pr.landableBodiesCount,
			(
				SELECT
					c.coordinateX,
					c.coordinateY,
					c.coordinateZ
				FROM SystemCoords c
				WHERE c.systemID = pr.nearbySystemID
				FOR JSON PATH
			) AS coordinates,
			(
				SELECT 
					b.bodyID, 
					b.bodyName, 
					bt.typeName AS bodyType, 
					b.isLandable, 
					ret.typeName AS reserveType,
					(
						SELECT 
							r.ringName, 
							rit.typeName AS ringType, 
							(
								SELECT 
									ht.typeName AS hotspotType, 
									h.hotspotCount 
								FROM Hotspots h
								LEFT JOIN HotspotType ht ON ht.typeID = h.hotspotID
								WHERE h.ringID = r.ringID
								FOR JSON PATH
							) AS hotspots
						FROM Rings r
						LEFT JOIN RingType rit ON rit.typeID = r.ringType
						WHERE r.bodyID = b.bodyID
						FOR JSON PATH
					) AS rings
				FROM Bodies b
				LEFT JOIN BodyType bt ON bt.typeID = b.bodyType
				LEFT JOIN ReserveType ret ON ret.typeID = b.reserveType
				WHERE b.systemID = ss.systemID
				ORDER BY b.bodyName ASC
				FOR JSON PATH
			) AS bodies,
			(
				SELECT DISTINCT
				sr1.colonisedSystemID,
				sr1.systemName,
				(
					SELECT DISTINCT
					sr2.stationID,
					sr2.stationName,
					sr2.factionName
					FROM SearchResults sr2
					WHERE sr1.colonisedSystemID = sr2.colonisedSystemID
					ORDER BY sr2.stationName
					FOR JSON PATH
				) AS stations
				FROM SearchResults sr1
				INNER JOIN NearbyStarSystems nss ON  nss.colonisedSystemID = sr1.colonisedSystemID
				WHERE ss.systemID = nss.nearbySystemID
				ORDER BY sr1.systemName
				FOR JSON PATH
			) AS colonisedSystems
		FROM PaginatedResults pr
		INNER JOIN StarSystems AS ss ON ss.systemID = pr.nearbySystemID
		ORDER BY
			CASE WHEN @sortOrder = 'bodyValue' THEN pr.bodyTypesValue END DESC,
			CASE WHEN @sortOrder = 'landableBodies' THEN pr.landableBodiesCount END DESC,
			CASE WHEN @sortOrder = 'hotspots' THEN pr.hotspotCount END DESC,
			CASE WHEN @sortOrder = 'totalValue' THEN pr.totalValue END DESC,
			CASE WHEN @sortOrder = 'solDistance' THEN pr.distanceToSol END DESC
		FOR JSON PATH
	) AS jsonFile;
END;

-- Creates the CalculateNearbyStarSystemsValues procedure.
CREATE PROCEDURE CalculateNearbyStarSystemsValues
AS
BEGIN
	SET NOCOUNT ON;
	
	TRUNCATE TABLE NearbyStarSystemsValues;

	WITH SystemValues AS (
		SELECT DISTINCT nss.nearbySystemID,
		COUNT(DISTINCT CASE WHEN bt.typeName IN ('Black Hole', 'Neutron Star', 'Ammonia world') THEN b.bodyID ELSE 0 END) * 1 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Water world' THEN b.bodyID ELSE 0 END) * 2 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Earth-like world' THEN b.bodyID ELSE 0 END) * 3
		AS bodyTypesValue,
		COUNT(DISTINCT CASE WHEN b.isLandable = 1 THEN b.bodyID ELSE 0 END) AS landableBodiesCount,
		SUM(COALESCE(h.hotspotCount, 0)) AS hotspotCount
		FROM NearbyStarSystems nss
		INNER JOIN Bodies AS b ON b.systemID = nss.nearbySystemID
		LEFT JOIN Rings AS r ON r.bodyID = b.bodyID
		LEFT JOIN Hotspots AS h ON h.ringID = r.ringID
		LEFT JOIN BodyType AS bt ON bt.typeID = b.bodyType
		WHERE NOT EXISTS (
			SELECT 1 FROM NearbyStarSystemsValues nssv WHERE nssv.nearbySystemID = nss.nearbySystemID
		)
		GROUP BY nss.nearbySystemID
	)
	INSERT INTO NearbyStarSystemsValues(nearbySystemID, bodyTypesValue, landableBodiesCount, hotspotCount, totalValue, distanceToSol)
	SELECT sv.nearbySystemID, sv.bodyTypesValue, sv.landableBodiesCount, sv.hotspotCount,
	(sv.bodyTypesValue * 1.2 + sv.landableBodiesCount * 1 + sv.hotspotCount * 0.6) AS totalValue,
	SQRT(POWER(sc.coordinateX, 2) + POWER(sc.coordinateY, 2) + POWER(sc.coordinateZ, 2)) AS distanceToSol
	FROM SystemValues sv
	INNER JOIN SystemCoords AS sc ON sc.systemID = sv.nearbySystemID;
END;

-- Creates the GetSystemSummary procedure.
CREATE PROCEDURE GetSystemSummary
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT ss.systemID, ss.isColonised, sc.coordinateX, sc.coordinateY, sc.coordinateZ
	FROM StarSystems ss
	INNER JOIN SystemCoords sc ON sc.systemID = ss.systemID;
END;

-- Creates the GetAASystems procedure.
CREATE PROCEDURE GetAASystems
AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT ss.systemName 'name', sc.coordinateX 'x', sc.coordinateY 'y', sc.coordinateZ 'z'
	FROM StarSystems ss
	INNER JOIN SystemCoords sc ON sc.systemID = ss.systemID
	INNER JOIN Stations s ON s.systemID = ss.systemID
	INNER JOIN Factions f ON f.factionID = s.controllingFaction
	WHERE factionName = 'Aisling''s Angels';
END;