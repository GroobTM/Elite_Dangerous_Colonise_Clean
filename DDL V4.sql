BEGIN TRANSACTION;

-- Creates the BodyType table
CREATE TABLE BodyType (
	typeID SMALLSERIAL PRIMARY KEY,
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the ReserveType table
CREATE TABLE ReserveType (
	typeID SMALLSERIAL PRIMARY KEY,
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the RingType table
CREATE TABLE RingType (
	typeID SMALLSERIAL PRIMARY KEY,
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the HotspotType table
CREATE TABLE HotspotType (
	typeID SMALLSERIAL PRIMARY KEY,
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the Factions table
CREATE TABLE Factions (
	factionID SERIAL PRIMARY KEY,
	factionName VARCHAR(75) UNIQUE NOT NULL
);

-- Creates the SystemCoords table
CREATE TABLE SystemCoords (
	systemID BIGINT PRIMARY KEY,
	coordinateX NUMERIC(10, 5) NOT NULL,
	coordinateY NUMERIC(10, 5) NOT NULL,
	coordinateZ NUMERIC(10, 5) NOT NULL
);

-- Creates the StarSystems table
CREATE TABLE StarSystems (
	systemID BIGINT PRIMARY KEY,
	systemName VARCHAR(75) NOT NULL,
	isColonised BOOLEAN NOT NULL,
	lastColonisingUpdate TIMESTAMP,
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
	bodyType SMALLINT NOT NULL,
	isLandable BOOLEAN NOT NULL,
	reserveType SMALLINT NOT NULL,
	distanceFromStar INT,
	FOREIGN KEY (systemID) REFERENCES StarSystems (systemID) ON DELETE CASCADE,
	FOREIGN KEY (bodyType) REFERENCES BodyType (typeID),
	FOREIGN KEY (reserveType) REFERENCES ReserveType (typeID)
);

-- Creates the Rings table
CREATE TABLE Rings (
	ringID INT PRIMARY KEY,
	bodyID BIGINT NOT NULL,
	ringName VARCHAR(75) NOT NULL,
	ringType SMALLINT NOT NULL,
	FOREIGN KEY (bodyID) REFERENCES Bodies (bodyID) ON DELETE CASCADE,
	FOREIGN KEY (ringType) REFERENCES RingType (typeID)
);

-- Creates the Hotspots table
CREATE TABLE Hotspots (
	ringID INT,
	hotspotID SMALLINT,
	hotspotCount SMALLINT NOT NULL,
	PRIMARY KEY (ringID, hotspotID),
	FOREIGN KEY (ringID) REFERENCES Rings (ringID) ON DELETE CASCADE,
	FOREIGN KEY (hotspotID) REFERENCES HotspotType (typeID)
);

-- Creates the NearbyStarSystems table
CREATE TABLE NearbyStarSystems (
	colonisedSystemID BIGINT NOT NULL,
	nearbySystemID BIGINT NOT NULL,
	PRIMARY KEY (colonisedSystemID, nearbySystemID),
	FOREIGN KEY (colonisedSystemID) REFERENCES StarSystems(systemID) ON DELETE CASCADE,
	FOREIGN KEY (nearbySystemID) REFERENCES StarSystems(systemID) ON DELETE CASCADE
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
	isColonised BOOLEAN NOT NULL,
	coordinateX NUMERIC(10, 5) NOT NULL,
	coordinateY NUMERIC(10, 5) NOT NULL,
	coordinateZ NUMERIC(10, 5) NOT NULL,
	queryType CHAR(6) NOT NULL,
	FOREIGN KEY (systemID) REFERENCES StarSystems(systemID) ON DELETE CASCADE
);

-- Creates the TrailblazerMegaships table
CREATE TABLE TrailblazerMegaships (
	trailblazerID BIGINT PRIMARY KEY,
	trailblazerName VARCHAR(25) UNIQUE NOT NULL,
	coordinateX NUMERIC(10, 5) NOT NULL,
	coordinateY NUMERIC(10, 5) NOT NULL,
	coordinateZ NUMERIC(10, 5) NOT NULL
	lastUpdate TIMESTAMP NOT NULL,
);

-- Creates the TrailblazerDistances table
CREATE TABLE TrailblazerDistances (
	systemID BIGINT PRIMARY KEY,
	trailblazerID BIGINT NOT NULL,
	distanceToTrailblazer SMALLINT NOT NULL,
	FOREIGN KEY (systemID) REFERENCES NearbyStarSystemsValues(nearbySystemID) ON DELETE CASCADE,
	FOREIGN KEY (trailblazerID) REFERENCES TrailblazerMegaships(trailblazerID) ON DELETE CASCADE
);

-- Creates the StarSystemsType type
CREATE TYPE StarSystemsType AS (
    systemID BIGINT,
    systemName VARCHAR(75),
	lastColonisingUpdate TIMESTAMP,
    isColonised BOOLEAN,
    coordinateX NUMERIC(10, 5),
    coordinateY NUMERIC(10, 5),
    coordinateZ NUMERIC(10, 5)
);

-- Creates the StationsType type
CREATE TYPE StationsType AS (
    stationID BIGINT,
    systemID BIGINT,
    stationName VARCHAR(75),
    controllingFaction VARCHAR(75)
);

-- Creates the BodiesType type
CREATE TYPE BodiesType AS (
    bodyID BIGINT,
    systemID BIGINT,
    bodyName VARCHAR(75),
    bodyType VARCHAR(50),
    isLandable BOOLEAN,
    reserveType VARCHAR(10),
	distanceFromStar INT
);

-- Creates the RingsType type
CREATE TYPE RingsType AS (
    ringID INT,
    bodyID BIGINT,
    ringName VARCHAR(75),
    ringType VARCHAR(10)
);

-- Creates the HotspotsTable type
CREATE TYPE HotspotsType AS (
	ringID INT,
	hotspotType VARCHAR(50),
	hotspotCount SMALLINT
);

-- Creates indexes
CREATE INDEX idx_SS_systemName ON StarSystems(systemName);
CREATE INDEX idx_S_controllingFaction ON Stations(controllingFaction);
CREATE INDEX idx_S_systemID ON Stations(systemID);
CREATE INDEX idx_B_systemID ON Bodies(systemID);
CREATE INDEX idx_R_bodyID ON Rings(bodyID);
CREATE INDEX idx_H_ringID ON Hotspots(ringID);
CREATE INDEX idx_SC_coordinateX ON SystemCoords(coordinateX);
CREATE INDEX idx_SC_coordinateY ON SystemCoords(coordinateY);
CREATE INDEX idx_SC_coordinateZ ON SystemCoords(coordinateZ);
CREATE INDEX idx_NSS_nearbySystemID ON NearbyStarSystems (nearbySystemID);
CREATE INDEX idx_NSS_colonisedSystemID ON NearbyStarSystems (colonisedSystemID);
CREATE INDEX idx_F_factionName ON Factions(factionName);
CREATE INDEX idx_NSSV_bodyTypesValue ON NearbyStarSystemsValues(bodyTypesValue);
CREATE INDEX idx_NSSV_landableBodiesCount ON NearbyStarSystemsValues(landableBodiesCount);
CREATE INDEX idx_NSSV_hotspotCount ON NearbyStarSystemsValues(hotspotCount);
CREATE INDEX idx_NSSV_totalValue ON NearbyStarSystemsValues(totalValue);
CREATE INDEX idx_NSSV_distanceToSol ON NearbyStarSystemsValues(distanceToSol);
CREATE INDEX idx_TD_trailblazerID ON TrailblazerDistances(trailblazerID);
CREATE INDEX idx_TD_systemID ON TrailblazerDistances(systemID);
CREATE INDEX idx_TD_distanceToTrailblazer ON TrailblazerDistances(distanceToTrailblazer);

COMMIT TRANSACTION;