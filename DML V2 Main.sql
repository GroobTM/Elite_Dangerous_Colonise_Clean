-- Creates the InsertIntoStarSystemsBulk Procedure
CREATE PROCEDURE InsertIntoStarSystemsBulk
	@inputStarSystems StarSystemsTable READONLY,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
		-- Inserts new coordinates into SystemCoords.
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.SystemCoords
		(systemID, coordinateX, coordinateY, coordinateZ)
		SELECT inss.systemID, inss.coordinateX, inss.coordinateY, inss.coordinateZ
		FROM @inputStarSystems inss
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.SystemCoords WHERE SystemCoords.systemID = inss.systemID
		);
		
		-- Updates existing systems in StarSystems
		UPDATE SystemsDatabase' + @databaseID + '.dbo.StarSystems
		SET
			StarSystems.isColonised = inss.isColonised,
			StarSystems.lastColonisingUpdate = inss.lastColonisingUpdate
		FROM SystemsDatabase' + @databaseID + '.dbo.StarSystems
		INNER JOIN @inputStarSystems inss ON StarSystems.systemID = inss.systemID;
		
		-- Inserts new systems into StarSystems.
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.StarSystems
		(systemID, systemName, isColonised, lastColonisingUpdate)
		SELECT inss.systemID, inss.systemName, inss.isColonised, inss.lastColonisingUpdate
		FROM @inputStarSystems inss
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.StarSystems WHERE StarSystems.systemID = inss.systemID
		);
	';
	
	EXEC sp_executesql @sql, N'@inputStarSystems StarSystemsTable READONLY', @inputStarSystems;
END;

-- Creates the InsertIntoStationsBulk Procedure
CREATE PROCEDURE InsertIntoStationsBulk
	@inputStations StationsTable READONLY,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
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
		UPDATE SystemsDatabase' + @databaseID + '.dbo.Stations
		SET
			Stations.stationName = ins.stationName,
			Stations.controllingFaction = rf.factionID
		FROM SystemsDatabase' + @databaseID + '.dbo.Stations
		INNER JOIN @inputStations ins ON Stations.stationID = ins.stationID
		INNER JOIN @resolvedFactions rf ON ins.controllingFaction = rf.factionName;
		
		-- Inserts new stations into Stations.
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.Stations
		(stationID, systemID, stationName, controllingFaction)
		SELECT ins.stationID, ins.systemID, ins.stationName, rf.factionID
		FROM @inputStations ins
		INNER JOIN @resolvedFactions rf ON ins.controllingFaction = rf.factionName
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.Stations
			WHERE Stations.stationID = ins.stationID
		);
	';
	
	EXEC sp_executesql @sql, N'@inputStations StationsTable READONLY', @inputStations;
END;

-- Creates the InsertIntoBodiesBulk Procedure
CREATE PROCEDURE InsertIntoBodiesBulk
	@inputBodies BodiesTable READONLY,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
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
		UPDATE SystemsDatabase' + @databaseID + '.dbo.Bodies
		SET
			Bodies.isLandable = inb.isLandable,
			Bodies.reserveType = rrt.typeID
		FROM SystemsDatabase' + @databaseID + '.dbo.Bodies
		INNER JOIN @inputBodies inb ON Bodies.bodyID = inb.bodyID
		INNER JOIN @resolvedReserveTypes rrt ON inb.reserveType = rrt.typeName;
		
		-- Inserts new bodies into Bodies.
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.Bodies
		(bodyID, systemID, bodyName, bodyType, isLandable, reserveType)
		SELECT inb.bodyID, inb.systemID, inb.bodyName, rbt.typeID, inb.isLandable, rrt.typeID
		FROM @inputBodies inb
		INNER JOIN @resolvedBodyTypes rbt ON inb.bodyType = rbt.typeName
		INNER JOIN @resolvedReserveTypes rrt ON inb.reserveType = rrt.typeName
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.Bodies
			WHERE Bodies.bodyID = inb.bodyID
		);
	';
	
	EXEC sp_executesql @sql, N'@inputBodies BodiesTable READONLY', @inputBodies;
END;

-- Creates the InsertIntoRingsBulk Procedure
CREATE PROCEDURE InsertIntoRingsBulk
	@inputRings RingsTable READONLY,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
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
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.Rings
		(ringID, bodyID, ringName, ringType)
		SELECT inr.ringID, inr.bodyID, inr.ringName, rrt.typeID
		FROM @inputRings inr
		INNER JOIN @resolvedRingTypes rrt ON inr.ringType = rrt.typeName
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.Rings
			WHERE Rings.ringID = inr.ringID
		);
	';
	
	EXEC sp_executesql @sql, N'@inputRings RingsTable READONLY', @inputRings;
END;

-- Creates the InsertIntoHotspotsBulk Procedure
CREATE PROCEDURE InsertIntoHotspotsBulk
	@inputHotspots HotspotsTable READONLY,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);

	SET @sql = '
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
		INSERT INTO SystemsDatabase' + @databaseID + '.dbo.Hotspots
		(ringID, hotspotID, hotspotCount)
		SELECT inh.ringID, rht.typeID, inh.hotspotCount
		FROM @inputHotspots inh
		INNER JOIN @resolvedHotspotTypes rht ON inh.hotspotType = rht.typeName
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase' + @databaseID + '.dbo.Hotspots
			WHERE Hotspots.ringID = inh.ringID
			AND Hotspots.hotspotID = rht.typeID
		);
	';
	
	EXEC sp_executesql @sql, N'@inputHotspots HotspotsTable READONLY', @inputHotspots;
END;

-- Creates the UpdateSystemColonisationState procedure
CREATE PROCEDURE UpdateSystemColonisationState
	@systemID BIGINT,
	@databaseID NVARCHAR(16)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);
	DECLARE @now DATE;
	
	SET @now = CAST(GETUTCDATE() AS DATE);
	
	SET @sql = '
		UPDATE SystemsDatabase' + @databaseID + '.dbo.StarSystems
		SET lastColonisingUpdate = @now
		WHERE systemID = @systemID
		AND isColonised <> 1;
	';
	
	EXEC sp_executesql @sql, N'@systemID BIGINT, @now DATE', @systemID, @now;
END;

-- Creates the InsertIntoStarSystemsBulkDirect procedure
CREATE PROCEDURE InsertIntoStarSystemsBulkDirect
	@inputStarSystems StarSystemsTable READONLY,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.InsertIntoStarSystemsBulk @inputStarSystems, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.InsertIntoStarSystemsBulk @inputStarSystems, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.InsertIntoStarSystemsBulk @inputStarSystems, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.InsertIntoStarSystemsBulk @inputStarSystems, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
END;

-- Creates the InsertIntoStationsBulkDirect procedure
CREATE PROCEDURE InsertIntoStationsBulkDirect
	@inputStations StationsTable READONLY,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.InsertIntoStationsBulk @inputStations, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.InsertIntoStationsBulk @inputStations, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.InsertIntoStationsBulk @inputStations, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.InsertIntoStationsBulk @inputStations, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
END;

-- Creates the InsertIntoBodiesBulkDirect procedure
CREATE PROCEDURE InsertIntoBodiesBulkDirect
	@inputBodies BodiesTable READONLY,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.InsertIntoBodiesBulk @inputBodies, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.InsertIntoBodiesBulk @inputBodies, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.InsertIntoBodiesBulk @inputBodies, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.InsertIntoBodiesBulk @inputBodies, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
END;

-- Creates the InsertIntoRingsBulkDirect procedure
CREATE PROCEDURE InsertIntoRingsBulkDirect
	@inputRings RingsTable READONLY,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.InsertIntoRingsBulk @inputRings, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.InsertIntoRingsBulk @inputRings, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.InsertIntoRingsBulk @inputRings, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.InsertIntoRingsBulk @inputRings, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
END;

-- Creates the InsertIntoHotspotsBulkDirect procedure
CREATE PROCEDURE InsertIntoHotspotsBulkDirect
	@inputHotspots HotspotsTable READONLY,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.InsertIntoHotspotsBulk @inputHotspots, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.InsertIntoHotspotsBulk @inputHotspots, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.InsertIntoHotspotsBulk @inputHotspots, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.InsertIntoHotspotsBulk @inputHotspots, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
END;

-- Creates the UpdateSystemColonisationStateDirect procedure
CREATE PROCEDURE UpdateSystemColonisationStateDirect
	@systemID BIGINT,
	@databaseID VARCHAR(16)
AS
BEGIN
	IF @databaseID = '1000X1000Y'
		EXEC dbo.UpdateSystemColonisationState @systemID, '1000X1000Y';
	ELSE IF @databaseID = '1000XN1000Y'
		EXEC dbo.UpdateSystemColonisationState @systemID, '1000XN1000Y';
	ELSE IF @databaseID = 'N1000X1000Y'
		EXEC dbo.UpdateSystemColonisationState @systemID, 'N1000X1000Y';
	ELSE IF @databaseID = 'N1000XN1000Y'
		EXEC dbo.UpdateSystemColonisationState @systemID, 'N1000XN1000Y';
	ELSE
		THROW 50000, 'Invalid databaseID provided.', 1;
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
		INNER JOIN (
			SELECT systemID, systemName FROM SystemsDatabase1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName FROM SystemsDatabase1000XN1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName FROM SystemsDatabaseN1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName FROM SystemsDatabaseN1000XN1000Y.dbo.StarSystems
		) AS ss ON ss.systemID = nss.colonisedSystemID
		INNER JOIN (
			SELECT systemID, stationID, stationName, controllingFaction FROM SystemsDatabase1000X1000Y.dbo.Stations
			UNION ALL
			SELECT systemID, stationID, stationName, controllingFaction FROM SystemsDatabase1000XN1000Y.dbo.Stations
			UNION ALL
			SELECT systemID, stationID, stationName, controllingFaction FROM SystemsDatabaseN1000X1000Y.dbo.Stations
			UNION ALL
			SELECT systemID, stationID, stationName, controllingFaction FROM SystemsDatabaseN1000XN1000Y.dbo.Stations
		) AS s ON s.systemID = nss.colonisedSystemID
		INNER JOIN Factions f ON f.factionID = s.controllingFaction
		WHERE ss.systemName LIKE @colonisedSystem + '%' AND f.factionName LIKE @faction + '%'
	),
	DistinctNearbyValue AS (
		SELECT DISTINCT nssv.nearbySystemID,
		nssv.bodyTypesValue,
		nssv.landableBodiesCount,
		nssv.hotspotCount,
		nssv.totalValue,
		sss.distanceToSol
		FROM SystemsDatabase.dbo.NearbyStarSystemsValue AS nssv
		INNER JOIN SystemsDatabase.dbo.NearbyStarSystems nss ON nss.nearbySystemID = nssv.nearbySystemID
		INNER JOIN SystemsDatabase.dbo.StarSystemSummary sss ON sss.systemID = nss.nearbySystemID
		INNER JOIN (
			SELECT systemID, lastColonisingUpdate FROM SystemsDatabase1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, lastColonisingUpdate FROM SystemsDatabase1000XN1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, lastColonisingUpdate FROM SystemsDatabaseN1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, lastColonisingUpdate FROM SystemsDatabaseN1000XN1000Y.dbo.StarSystems
		) AS ss ON ss.systemID = nss.nearbySystemID
		WHERE nss.colonisedSystemID IN (SELECT DISTINCT colonisedSystemID FROM SearchResults)
		AND (@includeColonising = 1 OR ss.lastColonisingUpdate IS NULL)
	), TotalResults AS (
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
				FROM (
					SELECT systemID, coordinateX, coordinateY, coordinateZ FROM SystemsDatabase1000X1000Y.dbo.SystemCoords
					UNION ALL
					SELECT systemID, coordinateX, coordinateY, coordinateZ FROM SystemsDatabase1000XN1000Y.dbo.SystemCoords
					UNION ALL
					SELECT systemID, coordinateX, coordinateY, coordinateZ FROM SystemsDatabaseN1000X1000Y.dbo.SystemCoords
					UNION ALL
					SELECT systemID, coordinateX, coordinateY, coordinateZ FROM SystemsDatabaseN1000XN1000Y.dbo.SystemCoords
				) c
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
								FROM (
									SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabase1000X1000Y.dbo.Hotspots
									UNION ALL
									SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabase1000XN1000Y.dbo.Hotspots
									UNION ALL
									SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabaseN1000X1000Y.dbo.Hotspots
									UNION ALL
									SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabaseN1000XN1000Y.dbo.Hotspots
								) h
								LEFT JOIN SystemsDatabase.dbo.HotspotType ht ON ht.typeID = h.hotspotID
								WHERE h.ringID = r.ringID
								FOR JSON PATH
							) AS hotspots
						FROM (
							SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabase1000X1000Y.dbo.Rings
							UNION ALL
							SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabase1000XN1000Y.dbo.Rings
							UNION ALL
							SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabaseN1000X1000Y.dbo.Rings
							UNION ALL
							SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabaseN1000XN1000Y.dbo.Rings
						) r
						LEFT JOIN SystemsDatabase.dbo.RingType rit ON rit.typeID = r.ringType
						WHERE r.bodyID = b.bodyID
						FOR JSON PATH
					) AS rings
				FROM (
					SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabase1000X1000Y.dbo.Bodies
					UNION ALL
					SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabase1000XN1000Y.dbo.Bodies
					UNION ALL
					SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabaseN1000X1000Y.dbo.Bodies
					UNION ALL
					SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabaseN1000XN1000Y.dbo.Bodies
				) b
				LEFT JOIN SystemsDatabase.dbo.BodyType bt ON bt.typeID = b.bodyType
				LEFT JOIN SystemsDatabase.dbo.ReserveType ret ON ret.typeID = b.reserveType
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
				INNER JOIN SystemsDatabase.dbo.NearbyStarSystems nss ON  nss.colonisedSystemID = sr1.colonisedSystemID
				WHERE ss.systemID = nss.nearbySystemID
				ORDER BY sr1.systemName
				FOR JSON PATH
			) AS colonisedSystems
		FROM PaginatedResults pr
		INNER JOIN (
			SELECT systemID, systemName, lastColonisingUpdate FROM SystemsDatabase1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName, lastColonisingUpdate FROM SystemsDatabase1000XN1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName, lastColonisingUpdate FROM SystemsDatabaseN1000X1000Y.dbo.StarSystems
			UNION ALL
			SELECT systemID, systemName, lastColonisingUpdate FROM SystemsDatabaseN1000XN1000Y.dbo.StarSystems
		) AS ss ON ss.systemID = pr.nearbySystemID
		ORDER BY
			CASE WHEN @sortOrder = 'bodyValue' THEN pr.bodyTypesValue END DESC,
			CASE WHEN @sortOrder = 'landableBodies' THEN pr.landableBodiesCount END DESC,
			CASE WHEN @sortOrder = 'hotspots' THEN pr.hotspotCount END DESC,
			CASE WHEN @sortOrder = 'totalValue' THEN pr.totalValue END DESC,
			CASE WHEN @sortOrder = 'solDistance' THEN pr.distanceToSol END DESC
		FOR JSON PATH
	) AS jsonFile;
END;

-- Creates the CalculateNearbyStarSystemsValue procedure.
CREATE PROCEDURE CalculateNearbyStarSystemsValue
AS
BEGIN
	SET NOCOUNT ON;
	
	TRUNCATE TABLE SystemsDatabase.dbo.NearbyStarSystemsValue;

	WITH AllBodies AS (
		SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabase1000X1000Y.dbo.Bodies
		UNION
		SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabase1000XN1000Y.dbo.Bodies
		UNION
		SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabaseN1000X1000Y.dbo.Bodies
		UNION
		SELECT systemID, bodyID, bodyName, bodyType, isLandable, reserveType FROM SystemsDatabaseN1000XN1000Y.dbo.Bodies
	),
	AllRings AS (
		SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabase1000X1000Y.dbo.Rings
		UNION
		SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabase1000XN1000Y.dbo.Rings
		UNION
		SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabaseN1000X1000Y.dbo.Rings
		UNION
		SELECT bodyID, ringID, ringName, ringType FROM SystemsDatabaseN1000XN1000Y.dbo.Rings
	),
	AllHotspots AS (
		SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabase1000X1000Y.dbo.Hotspots
		UNION
		SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabase1000XN1000Y.dbo.Hotspots
		UNION
		SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabaseN1000X1000Y.dbo.Hotspots
		UNION
		SELECT ringID, hotspotID, hotspotCount FROM SystemsDatabaseN1000XN1000Y.dbo.Hotspots
	),
	SystemValues AS (
		SELECT DISTINCT nss.nearbySystemID,
		COUNT(DISTINCT CASE WHEN bt.typeName IN ('Black Hole', 'Neutron Star', 'Ammonia world') THEN ab.bodyID ELSE 0 END) * 1 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Water world' THEN ab.bodyID ELSE 0 END) * 2 +
		COUNT(DISTINCT CASE WHEN bt.typeName = 'Earth-like world' THEN ab.bodyID ELSE 0 END) * 3
		AS bodyTypesValue,
		COUNT(DISTINCT CASE WHEN ab.isLandable = 1 THEN ab.bodyID ELSE 0 END) AS landableBodiesCount,
		SUM(COALESCE(ah.hotspotCount, 0)) AS hotspotCount
		FROM NearbyStarSystems nss
		INNER JOIN AllBodies AS ab ON ab.systemID = nss.nearbySystemID
		LEFT JOIN AllRings AS ar ON ar.bodyID = ab.bodyID
		LEFT JOIN AllHotspots AS ah ON ah.ringID = ar.ringID
		LEFT JOIN SystemsDatabase.dbo.BodyType AS bt ON bt.typeID = ab.bodyType
		WHERE NOT EXISTS (
			SELECT 1 FROM SystemsDatabase.dbo.NearbyStarSystemsValue nssv WHERE nssv.nearbySystemID = nss.nearbySystemID
		)
		GROUP BY nss.nearbySystemID
	)
	INSERT INTO SystemsDatabase.dbo.NearbyStarSystemsValue (nearbySystemID, bodyTypesValue, landableBodiesCount, hotspotCount, totalValue)
	SELECT sv.nearbySystemID, sv.bodyTypesValue, sv.landableBodiesCount, sv.hotspotCount,
	(sv.bodyTypesValue * 1.2 + sv.landableBodiesCount * 1 + sv.hotspotCount * 0.6) AS totalValue
	FROM SystemValues sv;
END;

-- Creates the RemoveOldBodies procedure.
CREATE PROCEDURE RemoveOldBodies
	@systemID BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	
	DELETE FROM SystemsDatabase1000X1000Y.dbo.Bodies WHERE systemID = @systemID;
	DELETE FROM SystemsDatabase1000XN1000Y.dbo.Bodies WHERE systemID = @systemID;
	DELETE FROM SystemsDatabaseN1000X1000Y.dbo.Bodies WHERE systemID = @systemID;
	DELETE FROM SystemsDatabaseN1000XN1000Y.dbo.Bodies WHERE systemID = @systemID;
END;

-- Creates the SyncBodyTypeInsertDistribute trigger.
CREATE TRIGGER SyncBodyTypeInsertDistribute
ON BodyType
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO SystemsDatabase1000X1000Y.dbo.BodyType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000X1000Y.dbo.BodyType 
            WHERE SystemsDatabase1000X1000Y.dbo.BodyType.typeID = inserted.typeID
        );

        INSERT INTO SystemsDatabase1000XN1000Y.dbo.BodyType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000XN1000Y.dbo.BodyType 
            WHERE SystemsDatabase1000XN1000Y.dbo.BodyType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000X1000Y.dbo.BodyType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000X1000Y.dbo.BodyType 
            WHERE SystemsDatabaseN1000X1000Y.dbo.BodyType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000XN1000Y.dbo.BodyType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000XN1000Y.dbo.BodyType 
            WHERE SystemsDatabaseN1000XN1000Y.dbo.BodyType.typeID = inserted.typeID
        );
		
    END TRY
    BEGIN CATCH
        INSERT INTO SystemsDatabase.dbo.SyncErrors (tableName, errorMessage, errorTime)
        VALUES ('BodyTypeMain', ERROR_MESSAGE(), GETDATE());
    END CATCH
END;

-- Creates the SyncReserveTypeInsertDistribute trigger.
CREATE TRIGGER SyncReserveTypeInsertDistribute
ON ReserveType
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO SystemsDatabase1000X1000Y.dbo.ReserveType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000X1000Y.dbo.ReserveType 
            WHERE SystemsDatabase1000X1000Y.dbo.ReserveType.typeID = inserted.typeID
        );

        INSERT INTO SystemsDatabase1000XN1000Y.dbo.ReserveType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000XN1000Y.dbo.ReserveType 
            WHERE SystemsDatabase1000XN1000Y.dbo.ReserveType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000X1000Y.dbo.ReserveType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000X1000Y.dbo.ReserveType 
            WHERE SystemsDatabaseN1000X1000Y.dbo.ReserveType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000XN1000Y.dbo.ReserveType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000XN1000Y.dbo.ReserveType 
            WHERE SystemsDatabaseN1000XN1000Y.dbo.ReserveType.typeID = inserted.typeID
        );
		
    END TRY
    BEGIN CATCH
        INSERT INTO SystemsDatabase.dbo.SyncErrors (tableName, errorMessage, errorTime)
        VALUES ('ReserveTypeMain', ERROR_MESSAGE(), GETDATE());
    END CATCH
END;

-- Creates the SyncRingTypeInsertDistribute trigger.
CREATE TRIGGER SyncRingTypeInsertDistribute
ON RingType
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO SystemsDatabase1000X1000Y.dbo.RingType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000X1000Y.dbo.RingType 
            WHERE SystemsDatabase1000X1000Y.dbo.RingType.typeID = inserted.typeID
        );

        INSERT INTO SystemsDatabase1000XN1000Y.dbo.RingType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000XN1000Y.dbo.RingType 
            WHERE SystemsDatabase1000XN1000Y.dbo.RingType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000X1000Y.dbo.RingType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000X1000Y.dbo.RingType 
            WHERE SystemsDatabaseN1000X1000Y.dbo.RingType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000XN1000Y.dbo.RingType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000XN1000Y.dbo.RingType 
            WHERE SystemsDatabaseN1000XN1000Y.dbo.RingType.typeID = inserted.typeID
        );
		
    END TRY
    BEGIN CATCH
        INSERT INTO SystemsDatabase.dbo.SyncErrors (tableName, errorMessage, errorTime)
        VALUES ('RingTypeMain', ERROR_MESSAGE(), GETDATE());
    END CATCH
END;

-- Creates the SyncHotspotTypeInsertDistribute trigger.
CREATE TRIGGER SyncHotspotTypeInsertDistribute
ON HotspotType
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO SystemsDatabase1000X1000Y.dbo.HotspotType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000X1000Y.dbo.HotspotType 
            WHERE SystemsDatabase1000X1000Y.dbo.HotspotType.typeID = inserted.typeID
        );

        INSERT INTO SystemsDatabase1000XN1000Y.dbo.HotspotType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000XN1000Y.dbo.HotspotType 
            WHERE SystemsDatabase1000XN1000Y.dbo.HotspotType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000X1000Y.dbo.HotspotType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000X1000Y.dbo.HotspotType 
            WHERE SystemsDatabaseN1000X1000Y.dbo.HotspotType.typeID = inserted.typeID
        );
		
        INSERT INTO SystemsDatabaseN1000XN1000Y.dbo.HotspotType (typeID, typeName)
        SELECT typeID, typeName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000XN1000Y.dbo.HotspotType 
            WHERE SystemsDatabaseN1000XN1000Y.dbo.HotspotType.typeID = inserted.typeID
        );
		
    END TRY
    BEGIN CATCH
        INSERT INTO SystemsDatabase.dbo.SyncErrors (tableName, errorMessage, errorTime)
        VALUES ('HotspotTypeMain', ERROR_MESSAGE(), GETDATE());
    END CATCH
END;

-- Creates the SyncFactionsInsertDistribute trigger.
CREATE TRIGGER SyncFactionsInsertDistribute
ON Factions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO SystemsDatabase1000X1000Y.dbo.Factions (factionID, factionName)
        SELECT factionID, factionName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000X1000Y.dbo.Factions 
            WHERE SystemsDatabase1000X1000Y.dbo.Factions.factionID = inserted.factionID
        );

        INSERT INTO SystemsDatabase1000XN1000Y.dbo.Factions (factionID, factionName)
        SELECT factionID, factionName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabase1000XN1000Y.dbo.Factions 
            WHERE SystemsDatabase1000XN1000Y.dbo.Factions.factionID = inserted.factionID
        );
		
        INSERT INTO SystemsDatabaseN1000X1000Y.dbo.Factions (factionID, factionName)
        SELECT factionID, factionName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000X1000Y.dbo.Factions 
            WHERE SystemsDatabaseN1000X1000Y.dbo.Factions.factionID = inserted.factionID
        );
		
        INSERT INTO SystemsDatabaseN1000XN1000Y.dbo.Factions (factionID, factionName)
        SELECT factionID, factionName FROM inserted
        WHERE NOT EXISTS (
            SELECT 1
            FROM SystemsDatabaseN1000XN1000Y.dbo.Factions 
            WHERE SystemsDatabaseN1000XN1000Y.dbo.Factions.factionID = inserted.factionID
        );
		
    END TRY
    BEGIN CATCH
        INSERT INTO SystemsDatabase.dbo.SyncErrors (tableName, errorMessage, errorTime)
        VALUES ('FactionsMain', ERROR_MESSAGE(), GETDATE());
    END CATCH
END;