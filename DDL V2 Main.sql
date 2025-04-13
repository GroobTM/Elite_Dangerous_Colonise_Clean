BEGIN TRANSACTION;

-- Creates the BodyType table
CREATE TABLE BodyType (
	typeID TINYINT PRIMARY KEY,
	typeName VARCHAR(50) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the ReserveType table
CREATE TABLE ReserveType (
	typeID TINYINT PRIMARY KEY,
	typeName VARCHAR(10) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the RingType table
CREATE TABLE RingType (
	typeID TINYINT PRIMARY KEY,
	typeName VARCHAR(10) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the HotspotType table
CREATE TABLE HotspotType (
	typeID TINYINT PRIMARY KEY,
	typeName VARCHAR(50) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Factions table
CREATE TABLE Factions (
	factionID INT PRIMARY KEY,
	factionName VARCHAR(75) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the SyncErrors table
CREATE TABLE SyncErrors (
    tableName VARCHAR(100),
    errorMessage VARCHAR(1000),
    errorTime DATETIME
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the NearbyStarSystems table
CREATE TABLE NearbyStarSystems (
	colonisedSystemID BIGINT,
	nearbySystemID BIGINT
	PRIMARY KEY (colonisedSystemID, nearbySystemID)
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the NearbyStarSystemsValue table
CREATE TABLE NearbyStarSystemsValue (
	nearbySystemID BIGINT PRIMARY KEY,
	bodyTypesValue SMALLINT,
	landableBodiesCount SMALLINT,
	hotspotCount SMALLINT,
	totalValue SMALLINT
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the StarSystemSummary table
CREATE TABLE StarSystemSummary (
	systemID BIGINT PRIMARY KEY,
	isColonised BIT NOT NULL,
	coordinateX DECIMAL(10, 5) NOT NULL,
	coordinateY DECIMAL(10, 5) NOT NULL,
	coordinateZ DECIMAL(10, 5) NOT NULL,
	distanceToSol DECIMAL(10, 5) NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the StarSystemSummaryStaging table
CREATE TABLE StarSystemSummaryStaging (
	systemID BIGINT PRIMARY KEY,
	isColonised BIT NOT NULL,
	coordinateX DECIMAL(10, 5) NOT NULL,
	coordinateY DECIMAL(10, 5) NOT NULL,
	coordinateZ DECIMAL(10, 5) NOT NULL,
	queryType CHAR(6) NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the HotspotsTable type
CREATE TYPE HotspotsTable AS TABLE (
	ringID INT,
	hotspotType VARCHAR(50),
	hotspotCount SMALLINT,
	PRIMARY KEY (ringID, hotspotType)
);

-- Creates the RingsTable type
CREATE TYPE RingsTable AS TABLE (
    ringID INT PRIMARY KEY,
    bodyID BIGINT,
    ringName VARCHAR(75),
    ringType VARCHAR(10)
)

-- Creates the BodiesTable type
CREATE TYPE BodiesTable AS TABLE (
    bodyID BIGINT PRIMARY KEY,
    systemID BIGINT,
    bodyName VARCHAR(75),
    bodyType VARCHAR(50),
    isLandable BIT,
    reserveType VARCHAR(10)
);

-- Creates the StationsTable type
CREATE TYPE StationsTable AS TABLE (
    stationID BIGINT PRIMARY KEY,
    systemID BIGINT,
    stationName VARCHAR(75),
    controllingFaction VARCHAR(75)
);

-- Creates the StarSystemsTable type
CREATE TYPE StarSystemsTable AS TABLE (
    systemID BIGINT PRIMARY KEY,
    systemName VARCHAR(75),
	lastColonisingUpdate DATE,
    isColonised BIT,
    coordinateX DECIMAL(10, 5),
    coordinateY DECIMAL(10, 5),
    coordinateZ DECIMAL(10, 5)
);

-- Creates the SearchParametersTable type
CREATE TYPE SearchParametersTable AS TABLE (
	colonisedSystem VARCHAR(75),
	faction VARCHAR(75),
	sortOrder VARCHAR(75),
	includeColonising BIT
);

CREATE INDEX idx_nearbySystemID ON NearbyStarSystems (nearbySystemID);
CREATE INDEX idx_colonisedSystemID ON NearbyStarSystems (colonisedSystemID);
CREATE INDEX idx_isColonised ON StarSystemSummary (isColonised);
CREATE INDEX idx_coordinateX ON StarSystemSummary (coordinateX);
CREATE INDEX idx_coordinateY ON StarSystemSummary (coordinateY);
CREATE INDEX idx_coordinateZ ON StarSystemSummary (coordinateZ);
CREATE INDEX idx_distanceToSol ON StarSystemSummary (distanceToSol);
CREATE INDEX idx_factionName ON Factions(factionName);
CREATE INDEX idx_bodyTypesValue ON NearbyStarSystemsValue(bodyTypesValue);
CREATE INDEX idx_landableBodiesCount ON NearbyStarSystemsValue(landableBodiesCount);
CREATE INDEX idx_hotspotCount ON NearbyStarSystemsValue(hotspotCount);
CREATE INDEX idx_totalValue ON NearbyStarSystemsValue(totalValue);

COMMIT TRANSACTION;