-- Creates the InsertIntoBodies Procedure
CREATE PROCEDURE InsertIntoBodies
	@bodyID BIGINT,
	@systemID BIGINT,
	@bodyName VARCHAR(150),
	@bodyType SMALLINT,
	@isLandable BIT,
	@reserveType SMALLINT
AS
BEGIN
	MERGE INTO Bodies AS target
	USING (SELECT @bodyID AS bodyID, @systemID AS systemID, @bodyName AS bodyName,
	@bodyType AS bodyType, @isLandable AS isLandable, @reserveType AS reserveType)
	AS source
	ON target.bodyID = source.bodyID
	WHEN MATCHED AND (target.isLandable <> source.isLandable
	OR target.reserveType <> source.reserveType) THEN
		UPDATE SET target.isLandable = source.isLandable,
		target.reserveType = source.reserveType
	WHEN NOT MATCHED THEN
		INSERT (bodyID, systemID, bodyName, bodyType, isLandable, reserveType)
		VALUES (source.bodyID, source.systemID, source.bodyName, source.bodyType,
		source.isLandable, source.reserveType);
END;

-- Creates the InsertIntoBodiesCascade Procedure
CREATE PROCEDURE InsertIntoBodiesCascade
	@bodyID BIGINT,
	@systemID BIGINT,
	@bodyName VARCHAR(150),
	@bodyType VARCHAR(50),
	@isLandable BIT,
	@reserveType VARCHAR(50)
AS
BEGIN
	DECLARE @bodyTypeID SMALLINT;
	DECLARE @reserveTypeID SMALLINT;

	EXEC InsertIntoBodyType @bodyType, @bodyTypeID OUTPUT;
	EXEC InsertIntoReserveType @reserveType, @reserveType OUTPUT;

	EXEC InsertIntoBodies @bodyID, @systemID, @bodyName, @bodyTypeID, @isLandable, @reserveTypeID;
END;

-- Creates the InsertIntoBodiesCascadeBulk Procedure
CREATE PROCEDURE InsertIntoBodiesCascadeBulk
	@bodies BodiesTable READONLY
AS
BEGIN
	DECLARE @resolvedBodyTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID SMALLINT
	);
	DECLARE @resolvedReserveTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID SMALLINT
	);
	
	-- Inserts new types into BodyType.
	INSERT INTO BodyType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedBodyTypes
	SELECT DISTINCT b.bodyType
	FROM @bodies b
	WHERE NOT EXISTS (
		SELECT 1 FROM BodyType bt WHERE bt.typeName = b.bodyType
	);
	
	-- Inserts existing types into resolvedBodyTypes.
	INSERT INTO @resolvedBodyTypes (typeName, typeID)
	SELECT DISTINCT bt.typeName, bt.typeID
	FROM BodyType bt
	INNER JOIN @bodies b ON b.bodyType = bt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedBodyTypes rbt WHERE rbt.typeName = bt.typeName
	);
	
	-- Inserts new types into ReserveType.
	INSERT INTO ReserveType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedReserveTypes
	SELECT DISTINCT b.reserveType
	FROM @bodies b
	WHERE NOT EXISTS (
		SELECT 1 FROM ReserveType rt WHERE rt.typeName = b.reserveType
	);
	
	-- Inserts existing types into resolvedReserveTypes.
	INSERT INTO @resolvedReserveTypes (typeName, typeID)
	SELECT DISTINCT rt.typeName, rt.typeID
	FROM ReserveType rt
	INNER JOIN @bodies b ON b.reserveType = rt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedReserveTypes rrt WHERE rrt.typeName = rt.typeName
	);
	
	-- Updates existing bodies in Bodies
	UPDATE Bodies
	SET
		Bodies.isLandable = b.isLandable,
		Bodies.reserveType = rrt.typeID
	FROM Bodies
	INNER JOIN @bodies b ON Bodies.bodyID = b.bodyID
	INNER JOIN @resolvedReserveTypes rrt ON b.reserveType = rrt.typeName;
	
	-- Inserts new bodies into Bodies.
	INSERT INTO Bodies (bodyID, systemID, bodyName, bodyType, isLandable, reserveType)
	SELECT b.bodyID, b.systemID, b.bodyName, rbt.typeID, b.isLandable, rrt.typeID
	FROM @bodies b
	INNER JOIN @resolvedBodyTypes rbt ON b.bodyType = rbt.typeName
	INNER JOIN @resolvedReserveTypes rrt ON b.reserveType = rrt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM Bodies WHERE Bodies.bodyID = b.bodyID
	);
END;

-- Creates the InsertIntoBodyType Procedure
CREATE PROCEDURE InsertIntoBodyType
	@typeName VARCHAR(50)
AS
BEGIN
	DECLARE @typeID SMALLINT;

	SELECT @typeID = typeID FROM BodyType WHERE typeName = @typeName;

	IF @typeID IS NULL
	BEGIN
		INSERT INTO BodyType (typeName) VALUES (@typeName);
		SET @typeID = SCOPE_IDENTITY();
	END

	SELECT @typeID AS typeID;
END;

-- Creates the InsertIntoFactions Procedure
CREATE PROCEDURE InsertIntoFactions
	@factionName VARCHAR(150)
AS
BEGIN
	DECLARE @insertedKey TABLE (factionID INT);

	MERGE INTO Factions AS target
	USING (SELECT @factionName AS factionName) AS source
	ON target.factionName = source.factionName
	WHEN MATCHED THEN
		UPDATE SET factionName = source.factionName
	WHEN NOT MATCHED THEN
		INSERT (factionName) VALUES (source.factionName)
	OUTPUT inserted.factionID INTO @insertedKey;

SELECT factionID FROM @insertedKey;
END;

-- Creates the InsertIntoHotspots Procedure
CREATE PROCEDURE InsertIntoHotspots
	@ringID BIGINT,
	@hotspotID SMALLINT,
	@hotspotCount SMALLINT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Hotspots WHERE ringID = @ringID
	AND hotspotID = @hotspotID)
	BEGIN
		INSERT INTO Hotspots (ringID, hotspotID, hotspotCount)
		VALUES (@ringID, @hotspotID, @hotspotCount);
	END
END;

-- Creates the InsertIntoHotspotsCascade Procedure
CREATE PROCEDURE InsertIntoHotspotsCascade
	@ringID BIGINT,
	@hotspotType VARCHAR(50),
	@hotspotCount SMALLINT
AS
BEGIN
	DECLARE @hotspotID SMALLINT;

	EXEC InsertIntoHotspotType @hotspotType, @hotspotID OUTPUT;

	EXEC InsertIntoHotspots @ringID, @hotspotID, @hotspotCount;
END;

-- Creates the InsertIntoHotspotsCascadeBulk Procedure
CREATE PROCEDURE InsertIntoHotspotsCascadeBulk
	@hotspots HotspotsTable READONLY
AS
BEGIN
	DECLARE @resolvedHotspotTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID SMALLINT
	);
	
	-- Inserts new types into HotspotType.
	INSERT INTO HotspotType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedHotspotTypes
	SELECT DISTINCT h.hotspotType
	FROM @hotspots h
	WHERE NOT EXISTS (
		SELECT 1 FROM HotspotType ht WHERE h.hotspotType = ht.typeName
	);
	
	-- Inserts existing types into resolvedHotspotTypes.
	INSERT INTO @resolvedHotspotTypes (typeName, typeID)
	SELECT DISTINCT ht.typeName, ht.typeID
	FROM HotspotType ht
	INNER JOIN @hotspots h ON h.hotspotType = ht.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedHotspotTypes rht WHERE rht.typeName = ht.typeName
	);
	
	-- Inserts new hotspots into Hotspots
	INSERT INTO Hotspots (ringID, bodyID, hotspotID, hotspotCount)
	SELECT h.ringID, h.bodyID, rht.typeID, h.hotspotCount
	FROM @hotspots h
	INNER JOIN @resolvedHotspotTypes rht ON h.hotspotType = rht.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM Hotspots
		WHERE Hotspots.ringID = h.ringID
		AND Hotspots.bodyID = h.bodyID
		AND Hotspots.hotspotID = rht.typeID
	);
END;

-- Creates the InsertIntoHotspotType Procedure
CREATE PROCEDURE InsertIntoHotspotType
	@typeName VARCHAR(50)
AS
BEGIN
	DECLARE @typeID SMALLINT;

	SELECT @typeID = typeID FROM HotspotType WHERE typeName = @typeName;

	IF @typeID IS NULL
	BEGIN
		INSERT INTO HotspotType (typeName) VALUES (@typeName);
		SET @typeID = SCOPE_IDENTITY();
	END

	SELECT @typeID AS typeID;
END;

-- Creates the InsertIntoReserveType Procedure
CREATE PROCEDURE InsertIntoReserveType
	@typeName VARCHAR(50)
AS
BEGIN
	DECLARE @typeID SMALLINT;

	SELECT @typeID = typeID FROM ReserveType WHERE typeName = @typeName;

	IF @typeID IS NULL
	BEGIN
		INSERT INTO ReserveType (typeName) VALUES (@typeName);
		SET @typeID = SCOPE_IDENTITY();
	END

	SELECT @typeID AS typeID;
END;

-- Creates the InsertIntoRings Procedure
CREATE PROCEDURE InsertIntoRings
	@ringID BIGINT,
	@bodyID BIGINT,
	@ringName VARCHAR(150),
	@ringType SMALLINT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Rings WHERE ringID = @ringID)
	BEGIN
		INSERT INTO Rings (ringID, bodyID, ringName, ringType)
		VALUES (@ringID, @bodyID, @ringName, @ringType);
	END
END;

-- Creates the InsertIntoRingsCascade Procedure
CREATE PROCEDURE InsertIntoRingsCascade
	@ringID BIGINT,
	@bodyID BIGINT,
	@ringName VARCHAR(150),
	@ringType VARCHAR(50)
AS
BEGIN
	DECLARE @ringTypeID SMALLINT;

	EXEC InsertIntoRingType @ringType, @ringTypeID OUTPUT;

	EXEC InsertIntoRings @ringID, @bodyID, @ringName, @ringTypeID;
END;

-- Creates the InsertIntoRingsCascadeBulk Procedure
CREATE PROCEDURE InsertIntoRingsCascadeBulk
	@rings RingsTable READONLY
AS
BEGIN
	DECLARE @resolvedRingTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID SMALLINT
	);
	
	-- Inserts new types into RingType.
	INSERT INTO RingType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedRingTypes
	SELECT DISTINCT r.ringType
	FROM @rings r
	WHERE NOT EXISTS (
		SELECT 1 FROM RingType rt WHERE r.ringType = rt.typeName
	);
	
	-- Inserts existing types into resolvedRingTypes.
	INSERT INTO @resolvedRingTypes (typeName, typeID)
	SELECT DISTINCT rt.typeName, rt.typeID
	FROM RingType rt
	INNER JOIN @rings r ON r.ringType = rt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedRingTypes rrt WHERE rrt.typeName = rt.typeName
	);

	-- Inserts new rings into Rings
	INSERT INTO Rings (ringID, bodyID, ringName, ringType)
	SELECT r.ringID, r.bodyID, r.ringName, rrt.typeID
	FROM @rings r
	INNER JOIN @resolvedRingTypes rrt ON r.ringType = rrt.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM Rings
		WHERE Rings.ringID = r.ringID
		AND Rings.bodyID = r.bodyID
	);
END;

-- Creates the InsertIntoRingType Procedure
CREATE PROCEDURE InsertIntoRingType
	@typeName VARCHAR(50)
AS
BEGIN
	DECLARE @typeID SMALLINT;

	SELECT @typeID = typeID FROM RingType WHERE typeName = @typeName;

	IF @typeID IS NULL
	BEGIN
		INSERT INTO RingType (typeName) VALUES (@typeName);
		SET @typeID = SCOPE_IDENTITY();
	END

	SELECT @typeID AS typeID;
END;

-- Creates the InsertIntoStations Procedure
CREATE PROCEDURE InsertIntoStations
	@stationID BIGINT,
	@systemID BIGINT,
	@stationName VARCHAR(150),
	@stationType SMALLINT,
	@controllingFaction INT
AS
BEGIN
	MERGE INTO Stations AS target
	USING (SELECT @stationID AS stationID, @systemID AS systemID,
	@stationName AS stationName, @stationType AS stationType,
	@controllingFaction AS controllingFaction)
	AS source
	ON target.stationID = source.stationID
	WHEN MATCHED AND (target.controllingFaction <> source.controllingFaction
	OR target.stationName <> source.stationName) THEN
		UPDATE SET target.controllingFaction = source.controllingFaction,
		target.stationName = source.stationName
	WHEN NOT MATCHED THEN
		INSERT (stationID, systemID, stationName, stationType, controllingFaction)
		VALUES (source.stationID, source.systemID, source.stationName,
		source.stationType, source.controllingFaction);
END;

-- Creates the InsertIntoStationsCascade Procedure
CREATE PROCEDURE InsertIntoStationsCascade
	@stationID BIGINT,
	@systemID BIGINT,
	@stationName VARCHAR(150),
	@stationType VARCHAR(50),
	@controllingFaction VARCHAR(150)
AS
BEGIN
	DECLARE @stationTypeID SMALLINT;
	DECLARE @controllingFactionID INT;

	EXEC InsertIntoStationType @stationType, @stationTypeID OUTPUT;
	EXEC InsertIntoFactions @controllingFaction, @controllingFactionID OUTPUT;

	EXEC InsertIntoStations @stationID, @systemID, @stationName, @stationTypeID, @controllingFactionID;
END;

-- Creates the InsertIntoStationsCascadeBulk Procedure
CREATE PROCEDURE InsertIntoStationsCascadeBulk
	@stations StationsTable READONLY
AS
BEGIN
	DECLARE @resolvedStationTypes TABLE (
		typeName VARCHAR(50) PRIMARY KEY,
		typeID SMALLINT
	);
	DECLARE @resolvedFactions TABLE (
		factionName VARCHAR(150) PRIMARY KEY,
		factionID INT
	);
	
	-- Inserts new types into StationType.
	INSERT INTO StationType (typeName)
	OUTPUT inserted.typeName, inserted.typeID INTO @resolvedStationTypes
	SELECT DISTINCT s.stationType
	FROM @stations s
	WHERE NOT EXISTS (
		SELECT 1 FROM StationType st WHERE st.typeName = s.stationType
	);
	
	-- Inserts existing types into resolvedStationTypes.
	INSERT INTO @resolvedStationTypes (typeName, typeID)
	SELECT DISTINCT st.typeName, st.typeID
	FROM StationType st
	INNER JOIN @stations s ON s.stationType = st.typeName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedStationTypes rst WHERE rst.typeName = st.typeName
	);
	
	-- Inserts new factions into Factions.
	INSERT INTO Factions (factionName)
	OUTPUT inserted.factionName, inserted.factionID INTO @resolvedFactions
	SELECT DISTINCT s.controllingFaction
	FROM @stations s
	WHERE NOT EXISTS (
		SELECT 1 FROM Factions f WHERE f.factionName = s.controllingFaction
	);
	
	-- Inserts existing factions into resolvedFactions.
	INSERT INTO @resolvedFactions (factionName, factionID)
	SELECT DISTINCT f.factionName, f.factionID
	FROM Factions f
	INNER JOIN @stations s ON s.controllingFaction = f.factionName
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedFactions rf WHERE rf.factionName = f.factionName
	);
	
	-- Updates existing stations in Stations
	UPDATE Stations
	SET
		Stations.stationName = s.stationName,
		Stations.controllingFaction = rf.factionID
	FROM Stations
	INNER JOIN @stations s ON Stations.stationID = s.stationID
	INNER JOIN @resolvedFactions rf ON s.controllingFaction = rf.factionName;
	
	-- Inserts new stations into Stations.
	INSERT INTO Stations (stationID, systemID, stationName, stationType, controllingFaction)
	SELECT s.stationID, s.systemID, s.stationName, rst.typeID, rf.factionID
	FROM @stations s
	INNER JOIN @resolvedStationTypes rst ON s.stationType = rst.typeName
	INNER JOIN @resolvedFactions rf ON s.controllingFaction = rf.factionName
	WHERE NOT EXISTS (
		SELECT 1 FROM Stations WHERE Stations.stationID = s.stationID
	);
END;

-- Creates the InsertIntoStationType Procedure
CREATE PROCEDURE InsertIntoStationType
	@typeName VARCHAR(50)
AS
BEGIN
	DECLARE @typeID SMALLINT;

	SELECT @typeID = typeID FROM StationType WHERE typeName = @typeName;

	IF @typeID IS NULL
	BEGIN
		INSERT INTO StationType (typeName) VALUES (@typeName);
		SET @typeID = SCOPE_IDENTITY();
	END

	SELECT @typeID AS typeID;
END;

-- Creates the InsertIntoSystemCoords Procedure
CREATE PROCEDURE InsertIntoSystemCoords
	@coordinateX DECIMAL(12, 6),
	@coordinateY DECIMAL(12, 6),
	@coordinateZ DECIMAL(12, 6)
AS
BEGIN
	DECLARE @coordinateID INT;

	SELECT @coordinateID = coordinateID FROM SystemCoords
	WHERE coordinateX = @coordinateX AND coordinateY = @coordinateY
	AND coordinateZ = @coordinateZ;

	IF @coordinateID IS NULL
	BEGIN
		INSERT INTO SystemCoords (coordinateX, coordinateY, coordinateZ)
		VALUES (@coordinateX, @coordinateY, @coordinateZ);

		SET @coordinateID = SCOPE_IDENTITY();
	END

	SELECT @coordinateID AS coordinateID;
END;

-- Creates the InsertIntoSystems Procedure
CREATE PROCEDURE InsertIntoSystems
	@systemID BIGINT,
	@systemName VARCHAR(150),
	@isColonised BIT,
	@coordinates INT
AS
BEGIN
	MERGE INTO Systems AS target
	USING (SELECT @systemID AS systemID, @systemName AS systemName,
	@isColonised AS isColonised, @coordinates AS coordinates)
	AS source
	ON target.systemID = source.systemID
	WHEN MATCHED AND target.isColonised <> source.isColonised THEN
		UPDATE SET target.isColonised = source.isColonised
	WHEN NOT MATCHED THEN
		INSERT (systemID, systemName, isColonised, coordinates)
		VALUES (source.systemID, source.systemName, source.isColonised,
		source.coordinates);
END;

-- Creates the InsertIntoSystemsCascade Procedure
CREATE PROCEDURE InsertIntoSystemsCascade
	@systemID BIGINT,
	@systemName VARCHAR(150),
	@isColonised BIT,
	@coordinateX DECIMAL(12, 6),
	@coordinateY DECIMAL(12, 6),
	@coordinateZ DECIMAL(12, 6)
AS
BEGIN
	DECLARE @coordinateID SMALLINT;

	EXEC InsertIntoSystemCoords @coordinateX, @coordinateY, @coordinateZ, @coordinateID OUTPUT;

	EXEC InsertIntoSystems @systemID, @systemName, @isColonised, @coordinateID;
END;

-- Creates the InsertIntoSystemsCascadeBulk Procedure
CREATE PROCEDURE InsertIntoSystemsCascadeBulk
	@systems SystemsTable READONLY
AS
BEGIN
	DECLARE @resolvedCoords TABLE (
		coordinateX DECIMAL(12, 6),
		coordinateY DECIMAL(12, 6),
		coordinateZ DECIMAL(12, 6),
		coordinateID INT
	);
	
	-- Inserts new coordinates into SystemCoords.
	INSERT INTO SystemCoords (coordinateX, coordinateY, coordinateZ)
	OUTPUT inserted.coordinateX, inserted.coordinateY, inserted.coordinateZ, inserted.coordinateID
	INTO @resolvedCoords
	SELECT DISTINCT s.coordinateX, s.coordinateY, s.coordinateZ
	FROM @systems s
	WHERE NOT EXISTS (
		SELECT 1 FROM SystemCoords sc
		WHERE sc.coordinateX = s.coordinateX
		AND sc.coordinateY = s.coordinateY
		AND sc.coordinateZ = s.coordinateZ
	);
	
	-- Inserts existing coordinates into resolvedCoords.
	INSERT INTO @resolvedCoords (coordinateX, coordinateY, coordinateZ, coordinateID)
	SELECT sc.coordinateX, sc.coordinateY, sc.coordinateZ, sc.coordinateID
	FROM SystemCoords sc
	INNER JOIN @systems s ON s.coordinateX = sc.coordinateX
	AND s.coordinateY = sc.coordinateY
	AND s.coordinateZ = sc.coordinateZ
	WHERE NOT EXISTS (
		SELECT 1 FROM @resolvedCoords rc
		WHERE rc.coordinateX = sc.coordinateX
		AND rc.coordinateY = sc.coordinateY
		AND rc.coordinateZ = sc.coordinateZ
	);
	
	-- Updates existing systems in Systems
	UPDATE Systems
	SET
		Systems.isColonised = s.isColonised
	FROM Systems
	INNER JOIN @systems s ON Systems.systemID = s.systemID;
	
	-- Inserts new systems into Systems.
	INSERT INTO Systems (systemID, systemName, isColonised, coordinates)
	SELECT s.systemID, s.systemName, s.isColonised, rc.coordinateID
	FROM @systems s
	INNER JOIN @resolvedCoords rc ON s.coordinateX = rc.coordinateX
	AND s.coordinateY = rc.coordinateY
	AND s.coordinateZ = rc.coordinateZ
	WHERE NOT EXISTS (
		SELECT 1 FROM Systems WHERE Systems.systemID = s.systemID
	);
END;