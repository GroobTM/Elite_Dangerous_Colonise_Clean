BEGIN TRANSACTION;

-- Creates the BodyType table
CREATE TABLE BodyType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the ReserveType table
CREATE TABLE ReserveType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the RingType table
CREATE TABLE RingType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the HotspotType table
CREATE TABLE HotspotType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the Factions table
CREATE TABLE Factions (
	factionID INT PRIMARY KEY IDENTITY(1, 1),
	factionName VARCHAR(75) UNIQUE NOT NULL
);

-- Creates the SystemCoords table
CREATE TABLE SystemCoords (
	systemID BIGINT PRIMARY KEY,
	coordinateX DECIMAL(10, 5) NOT NULL,
	coordinateY DECIMAL(10, 5) NOT NULL,
	coordinateZ DECIMAL(10, 5) NOT NULL
);

-- Creates the StarSystems table
CREATE TABLE StarSystems (
	systemID BIGINT PRIMARY KEY,
	systemName VARCHAR(75) NOT NULL,
	isColonised BIT NOT NULL,
	lastColonisingUpdate DATE,
	FOREIGN KEY (systemID) REFERENCES SystemCoords (systemID) ON DELETE CASCADE
);

-- Creates the Stations table
CREATE TABLE Stations (
	stationID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	stationName VARCHAR(75) NOT NULL,
	controllingFaction INT NOT NULL,
	FOREIGN KEY (systemID) REFERENCES StarSystems (systemID) ON DELETE CASCADE,
	FOREIGN KEY (controllingFaction) REFERENCES Factions (factionID)
);

-- Creates the Bodies table
CREATE TABLE Bodies (
	bodyID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	bodyName VARCHAR(75) NOT NULL,
	bodyType TINYINT NOT NULL,
	isLandable BIT NOT NULL,
	reserveType TINYINT NOT NULL,
	FOREIGN KEY (systemID) REFERENCES StarSystems (systemID) ON DELETE CASCADE,
	FOREIGN KEY (bodyType) REFERENCES BodyType (typeID),
	FOREIGN KEY (reserveType) REFERENCES ReserveType (typeID)
);

-- Creates the Rings table
CREATE TABLE Rings (
	ringID INT PRIMARY KEY,
	bodyID BIGINT NOT NULL,
	ringName VARCHAR(75) NOT NULL,
	ringType TINYINT NOT NULL,
	FOREIGN KEY (bodyID) REFERENCES Bodies (bodyID) ON DELETE CASCADE,
	FOREIGN KEY (ringType) REFERENCES RingType (typeID)
);

-- Creates the Hotspots table
CREATE TABLE Hotspots (
	ringID INT,
	hotspotID TINYINT,
	hotspotCount TINYINT NOT NULL,
	PRIMARY KEY (ringID, hotspotID),
	FOREIGN KEY (ringID) REFERENCES Rings (ringID) ON DELETE CASCADE,
	FOREIGN KEY (hotspotID) REFERENCES HotspotType (typeID)
);

-- Creates the NearbyStarSystems table
CREATE TABLE NearbyStarSystems (
	colonisedSystemID BIGINT NOT NULL,
	nearbySystemID BIGINT NOT NULL,
	PRIMARY KEY (colonisedSystemID, nearbySystemID)
);

-- Creates the NearbyStarSystemsValues table
CREATE TABLE NearbyStarSystemsValues (
	nearbySystemID BIGINT PRIMARY KEY,
	bodyTypesValue SMALLINT NOT NULL,
	landableBodiesCount SMALLINT NOT NULL,
	hotspotCount SMALLINT NOT NULL,
	totalValue SMALLINT NOT NULL,
	distanceToSol SMALLINT NOT NULL
);

-- Creates the StarSystemStaging table
CREATE TABLE StarSystemStaging (
	systemID BIGINT PRIMARY KEY,
	isColonised BIT NOT NULL,
	coordinateX DECIMAL(10, 5) NOT NULL,
	coordinateY DECIMAL(10, 5) NOT NULL,
	coordinateZ DECIMAL(10, 5) NOT NULL,
	queryType CHAR(6) NOT NULL
);

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

-- Creates indexes
CREATE INDEX idx_systemName ON StarSystems(systemName);
CREATE INDEX idx_controllingFaction ON Stations(controllingFaction);
CREATE INDEX idx_systemID ON Stations(systemID);
CREATE INDEX idx_systemID ON Bodies(systemID)
CREATE INDEX idx_bodyID ON Rings(bodyID);
CREATE INDEX idx_ringID ON Hotspots(ringID);
CREATE INDEX idx_coordinateX ON SystemCoords(coordinateX);
CREATE INDEX idx_coordinateY ON SystemCoords(coordinateY);
CREATE INDEX idx_coordinateZ ON SystemCoords(coordinateZ);
CREATE INDEX idx_nearbySystemID ON NearbyStarSystems (nearbySystemID);
CREATE INDEX idx_colonisedSystemID ON NearbyStarSystems (colonisedSystemID);
CREATE INDEX idx_factionName ON Factions(factionName);
CREATE INDEX idx_bodyTypesValue ON NearbyStarSystemsValue(bodyTypesValue);
CREATE INDEX idx_landableBodiesCount ON NearbyStarSystemsValue(landableBodiesCount);
CREATE INDEX idx_hotspotCount ON NearbyStarSystemsValue(hotspotCount);
CREATE INDEX idx_totalValue ON NearbyStarSystemsValue(totalValue);

COMMIT TRANSACTION;