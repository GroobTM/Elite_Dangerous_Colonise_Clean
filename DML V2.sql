-- Creates the InsertNewSystemToSystemsDatabase trigger
CREATE TRIGGER InsertNewSystemToSystemsDatabase
ON StarSystems
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO SystemsDatabase.dbo.StarSystemSummaryStaging
	(systemID, isColonised, coordinateX, coordinateY, coordinateZ, queryType)
	SELECT i.systemID, i.isColonised, sc.coordinateX, sc.coordinateY, sc.coordinateZ, 'INSERT'
	FROM inserted i
	INNER JOIN SystemCoords sc ON i.systemID = sc.systemID
	WHERE NOT EXISTS (
		SELECT 1 FROM SystemsDatabase.dbo.StarSystemSummaryStaging sss WHERE i.systemID = sss.systemID
	);
END;

-- Creates the UpdateSystemInSystemsDatabase trigger
CREATE TRIGGER UpdateSystemInSystemsDatabase
ON StarSystems
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	MERGE INTO SystemsDatabase.dbo.StarSystemSummaryStaging AS target
    USING (
        SELECT 
            i.systemID, 
            i.isColonised, 
            sc.coordinateX, 
            sc.coordinateY, 
            sc.coordinateZ, 
            'UPDATE' AS queryType
        FROM inserted i
        INNER JOIN SystemCoords sc ON i.systemID = sc.systemID
        INNER JOIN deleted d ON i.systemID = d.systemID
        WHERE i.isColonised <> d.isColonised
    ) AS source
    ON target.systemID = source.systemID

    WHEN MATCHED THEN
        UPDATE SET 
            target.isColonised = source.isColonised,
            target.coordinateX = source.coordinateX,
            target.coordinateY = source.coordinateY,
            target.coordinateZ = source.coordinateZ,
            target.queryType = source.queryType

    WHEN NOT MATCHED THEN
        INSERT (systemID, isColonised, coordinateX, coordinateY, coordinateZ, queryType)
        VALUES (source.systemID, source.isColonised, source.coordinateX, source.coordinateY, source.coordinateZ, source.queryType);
END;