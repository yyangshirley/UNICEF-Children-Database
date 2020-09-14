CREATE DATABASE ChildEducationDW;
GO
USE ChildEducationDW;
GO

/* Dimension Model Tables */
-- Fact Table
DROP TABLE IF EXISTS dbo.FactEducation;
GO
CREATE TABLE dbo.FactEducation(
    CountryKey INT NOT NULL,
	LabourKey INT NOT NULL,
	ViolenceKey INT NOT NULL,
	ModernizationKey INT NOT NULL,
	UrbanNum DECIMAL(18,2) NULL,
    RuralNum DECIMAL(18,2) NULL,
    TotalViolenceNum DECIMAL(18,2) NULL,
    TotalLabourNum DECIMAL(18,2) NULL,
	SchoolCompletionRate FLOAT NULL,
	TotalSchoolCompletion FLOAT NULL, --POPULATION
	OutofSchoolRate FLOAT NULL,
	TotalOutofSchool FLOAT NULL, --POPULATION
	NetAttendanceRate FLOAT NULL,
	TotalNetAttendance FLOAT NULL, --POPULATION
	LDC NVARCHAR(50) NULL
);
GO

-- create foreign key indexes for seeking records
CREATE INDEX IX_FactEducation_CountryKey ON FactEducation(CountryKey);
CREATE INDEX IX_FactEducation_ModerizationKey ON FactEducation(ModernizationKey);
CREATE INDEX IX_FactEducation_LablourKey ON FactEducation(LabourKey);
CREATE INDEX IX_FactEducation_ViolenceKey ON FactEducation(ViolenceKey);

-- Dimension tables
DROP TABLE IF EXISTS dbo.DimCountry
GO
CREATE TABLE dbo.DimCountry(
	CountryKey INT NOT NULL,
	CountryName NVARCHAR(60) NULL,
	RegionName NVARCHAR(50) NULL,
	Population INT NULL,
	CONSTRAINT PK_DimCountry PRIMARY KEY CLUSTERED ( CountryKey )
);
GO

DROP TABLE IF EXISTS dbo.DimViolence
GO
CREATE TABLE dbo.DimViolence(
	ViolenceKey INT NOT NULL,
	MaleRate FLOAT NULL,
	FemaleRate FLOAT NULL,
	CountryName NVARCHAR(50) NULL
	CONSTRAINT PK_DimViolence PRIMARY KEY CLUSTERED ( ViolenceKey )
);
GO

DROP TABLE IF EXISTS dbo.DimModernization
GO
CREATE TABLE dbo.DimModernization(
	ModernizationKey INT NOT NULL,
    CountryName NVARCHAR(50) NULL,
	Urban FLOAT NULL,
	Rural FLOAT NULL,
	UrbanPopulationWeighted INT NULL,
	RuralPopulationWeighted INT NULL,
	CONSTRAINT PK_DimCountryWealth PRIMARY KEY CLUSTERED( ModernizationKey )
);
GO

DROP TABLE IF EXISTS dbo.DimChildLabour
GO
CREATE TABLE dbo.DimChildLabour(
	LabourKey INT NOT NULL,
    TotalRate INT NULL,
	Male FLOAT NULL,
	Female FLOAT NULL,
	CountryName NVARCHAR(50) NULL,
	CONSTRAINT PK_DimChildLabour PRIMARY KEY CLUSTERED( LabourKey )
);
GO

/* Extracts and Stage tables */
DROP TABLE IF EXISTS dbo.Country_Stage
GO
CREATE TABLE dbo.Country_Stage(
   CountryName NVARCHAR(60) NULL,
	RegionName NVARCHAR(50) NULL,
	Population INT NULL
)
GO

DROP PROCEDURE IF EXISTS dbo.Country_Extract
GO
CREATE PROCEDURE dbo.Country_Extract
AS
BEGIN;
SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Country_Stage;

    INSERT INTO dbo.Country_Stage
    SELECT ct.CountryName,
        rg.RegionName,
        ct.CountryPopulation
    FROM ChildrenDatabase.dbo.Country ct
        LEFT JOIN ChildrenDatabase.dbo.Region rg
        ON ct.RegionID =rg.RegionID
    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;
GO

EXECUTE dbo.Country_Extract
GO
SELECT * FROM dbo.Country_Stage
GO

DROP TABLE IF EXISTS dbo.Violence_Stage
GO
CREATE TABLE dbo.Violence_Stage(
    Totalrate FLOAT NULL,
    MaleRate FLOAT NULL,
	FemaleRate FLOAT NULL,
    TotalViolenceNum DECIMAL(18,2) NULL,
	CountryName NVARCHAR(50) NULL
);
GO

DROP PROCEDURE IF EXISTS dbo.Violence_Extract
GO
CREATE PROCEDURE dbo.Violence_Extract
AS
BEGIN;
SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Violence_Stage;

    INSERT INTO dbo.Violence_Stage
    SELECT vl.Total,
        vl.Male,
        vl.Female,
        vl.Total*ct.CountryPopulation,
        ct.CountryName
    FROM ChildrenDatabase.dbo.Violence vl
        LEFT JOIN ChildrenDatabase.dbo.Country ct
        ON vl.CountryID = ct.CountryID

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;
GO

EXECUTE dbo.Violence_Extract
GO
SELECT * FROM dbo.Violence_Stage
GO

DROP TABLE IF EXISTS dbo.Modernization_Stage
GO
CREATE TABLE dbo.Modernization_Stage(
    CountryName NVARCHAR(50) NULL,
    Urban FLOAT NULL,
	Rural FLOAT NULL,
	UrbanPopulationWeighted INT NULL,
	RuralPopulationWeighted INT NULL,
);
GO

DROP PROCEDURE IF EXISTS dbo.Modernization_Extract
GO
CREATE PROCEDURE dbo.Modernization_Extract
AS
BEGIN;
SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Modernization_Stage;

    INSERT INTO dbo.Modernization_Stage
    SELECT ct.CountryName,
        cw.Urban,
        cw.Rural,
        cw.UrbanPopulation,
        cw.RuralPopulation
    FROM ChildrenDatabase.dbo.CountryWealth cw
        LEFT JOIN ChildrenDatabase.dbo.Country ct
        ON cw.CountryID = ct.CountryID

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;
GO

EXECUTE dbo.Modernization_Extract
GO
SELECT * FROM dbo.Modernization_Stage
GO

DROP TABLE IF EXISTS dbo.Labour_Stage
GO
CREATE TABLE dbo.Labour_Stage(
    TotalRate INT NULL,
	Male FLOAT NULL,
	Female FLOAT NULL,
    TotalLabourNum DECIMAL(18,2) NULL,
	CountryName NVARCHAR(50) NULL
)
GO

DROP PROCEDURE IF EXISTS dbo.Labour_Extract
GO
CREATE PROCEDURE dbo.Labour_Extract
AS
BEGIN;
SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Labour_Stage;

    INSERT INTO dbo.Labour_Stage
    SELECT lb.Total,
        lb.Male,
        lb.Female,
        lb.Total*ct.CountryPopulation,
        ct.CountryName
    FROM ChildrenDatabase.dbo.ChildLabour lb
        LEFT JOIN ChildrenDatabase.dbo.Country ct
        ON lb.CountryID = ct.CountryID

    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;
GO

EXECUTE dbo.Labour_Extract
GO
SELECT * FROM dbo.Labour_Stage
GO

DROP TABLE IF EXISTS dbo.Education_Stage
GO
CREATE TABLE dbo.Education_Stage(
    CountryName NVARCHAR(50) NULL,
    UrbanNum DECIMAL(18,2) NULL,
    RuralNum DECIMAL(18,2) NULL,
    TotalViolenceNum DECIMAL(18,2) NULL,
    TotalLabourNum DECIMAL(18,2) NULL,
    SchoolCompletionRate FLOAT NULL,
	TotalSchoolCompletion FLOAT NULL, --POPULATION
	OutofSchoolRate FLOAT NULL,
	TotalOutofSchool FLOAT NULL, --POPULATION
	NetAttendanceRate FLOAT NULL,
	TotalNetAttendance FLOAT NULL, --POPULATION
	LDC NVARCHAR(50) NULL,
);
GO

DROP PROCEDURE IF EXISTS dbo.Education_Extract
GO
CREATE PROCEDURE dbo.Education_Extract
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @RowCt INT;

    TRUNCATE TABLE dbo.Education_Stage;

    INSERT INTO dbo.Education_Stage
    SELECT ct.CountryName,
        wl.Urban * wl.UrbanPopulation,
        wl.Rural * wl.RuralPopulation,
        vl.Total * ct.CountryPopulation,
        lb.Total * ct.CountryPopulation,
        edu.SchoolCompletionRatePrimary,
		edu.SchoolCompletionRatePrimary*ct.CountryPopulation,
        edu.OutofSchoolRatePrimary,
		edu.OutofSchoolRatePrimary*ct.CountryPopulation,
        edu.NetAttendanceRatePrimary,
		edu.NetAttendanceRatePrimary*ct.CountryPopulation,
        ct.LDC
    FROM ChildrenDatabase.dbo.Education edu
        LEFT JOIN ChildrenDatabase.dbo.Country ct
        ON edu.CountryName = ct.CountryName
        LEFT JOIN ChildrenDatabase.dbo.Violence vl
        ON ct.CountryID = vl.CountryID
        LEFT JOIN ChildrenDatabase.dbo.CountryWealth wl
        ON wl.CountryID = ct.CountryID
        LEFT JOIN ChildrenDatabase.dbo.ChildLabour lb
        ON lb.CountryID = ct.CountryID
    SET @RowCt = @@ROWCOUNT;
    IF @RowCt = 0
    BEGIN;
        THROW 50001, 'No records found. Check with source system.', 1;
    END;
END;
GO

EXECUTE dbo.Education_Extract
GO
SELECT * FROM dbo.Education_Stage
GO

/* Transforms and Preload tables */
DROP TABLE IF EXISTS dbo.Country_Preload
GO
CREATE TABLE dbo.Country_Preload(
    -- type 1 SCD
    CountryKey INT NOT NULL,
	CountryName NVARCHAR(60) NULL,
	RegionName NVARCHAR(50) NULL,
	Population INT NULL,
	CONSTRAINT PK_Country_Preload PRIMARY KEY CLUSTERED ( CountryKey )
);
GO
-- create and use sequence to set dimension business key
DROP SEQUENCE if EXISTS dbo.CountryKey
GO
CREATE SEQUENCE dbo.CountryKey START WITH 1;
GO

DROP PROCEDURE IF EXISTS dbo.Country_Transform
GO
CREATE PROCEDURE dbo.Country_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Country_Preload;

    BEGIN TRANSACTION;
    -- Use Sequence to create new surrogate keys (Create new records)
    INSERT INTO dbo.Country_Preload 
    SELECT NEXT VALUE FOR dbo.CountryKey as CountryKey,
        stg.CountryName,
        stg.RegionName,
        stg.Population
    FROM dbo.Country_Stage stg  
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimCountry dc where dc.CountryName = stg.CountryName)
    -- use existing surrogate key if one exists (add updated records)
    INSERT INTO dbo.Country_Preload 
    SELECT dc.CountryKey,
        stg.CountryName,
        stg.RegionName,
        stg.Population
    FROM dbo.Country_Stage stg
        JOIN dbo.DimCountry dc
        ON stg.CountryName = dc.CountryName
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Country_Transform
GO
SELECT * FROM dbo.Country_Preload
GO

DROP TABLE IF EXISTS dbo.Violence_Preload
GO
CREATE TABLE dbo.Violence_Preload(
    --type 1 SCD
	ViolenceKey INT NOT NULL,
	MaleRate FLOAT NULL,
	FemaleRate FLOAT NULL,
	CountryName NVARCHAR(50) NULL
	CONSTRAINT PK_Violence_Preload PRIMARY KEY CLUSTERED ( ViolenceKey )
);
GO

DROP SEQUENCE IF EXISTS dbo.ViolenceKey ;
GO
CREATE SEQUENCE dbo.ViolenceKey START WITH 1;
GO

DROP PROCEDURE IF EXISTS dbo.Violence_Transform
GO
CREATE PROCEDURE dbo.Violence_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Violence_Preload;

    BEGIN TRANSACTION;
    -- Use Sequence to create new surrogate keys (Create new records)
    INSERT INTO dbo.Violence_Preload
    SELECT NEXT VALUE FOR dbo.ViolenceKey as ViolenceKey,
        stg.MaleRate,
        stg.FemaleRate,
        stg.CountryName
    FROM dbo.Violence_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimViolence dv where  dv.CountryName = stg.CountryName)
    -- use existing surrogate key if one exists (add updated records)
    INSERT INTO dbo.Violence_Preload
    SELECT dv.ViolenceKey,
        stg.MaleRate,
        stg.FemaleRate,
        stg.CountryName
    FROM dbo.Violence_Stage stg
        JOIN dbo.DimViolence dv
        ON dv.CountryName = stg.CountryName
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Violence_Transform
GO
SELECT * FROM dbo.Violence_Preload
GO

DROP TABLE IF EXISTS dbo.Modernization_Preload
GO
CREATE TABLE dbo.Modernization_Preload(
	ModernizationKey INT NOT NULL,
    CountryName NVARCHAR(50) NULL,
	Urban FLOAT NULL,
	Rural FLOAT NULL,
	UrbanPopulationWeighted INT NULL,
	RuralPopulationWeighted INT NULL,
	CONSTRAINT PK_CountryWealth_Preload PRIMARY KEY CLUSTERED( ModernizationKey )
);
GO

DROP SEQUENCE IF EXISTS dbo.ModernizationKey;
GO
CREATE SEQUENCE dbo.ModernizationKey START WITH 1;
GO

DROP PROCEDURE IF EXISTS dbo.Modernization_Transform
GO
CREATE PROCEDURE dbo.Modernization_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Modernization_Preload;

    BEGIN TRANSACTION;
    -- Use Sequence to create new surrogate keys (Create new records)
    INSERT INTO dbo.Modernization_Preload
    SELECT NEXT VALUE FOR dbo.ModernizationKey as ModernizationKey,
        stg.CountryName,
        stg.Urban,
        stg.Rural,
        stg.UrbanPopulationWeighted,
        stg.RuralPopulationWeighted
    FROM dbo.Modernization_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimModernization dm where dm.CountryName =stg.CountryName)
    -- use existing surrogate key if one exists (add updated records)
    INSERT INTO dbo.Modernization_Preload
    SELECT dm.ModernizationKey,
        stg.CountryName,
        stg.Urban,
        stg.Rural,
        stg.UrbanPopulationWeighted,
        stg.RuralPopulationWeighted
    FROM dbo.Modernization_Stage stg
        JOIN dbo.DimModernization dm
        ON dm.CountryName = stg.CountryName
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Modernization_Transform
GO
SELECT * FROM dbo.Modernization_Preload
GO

DROP TABLE IF EXISTS dbo.Labour_Preload
GO
CREATE TABLE dbo.Labour_Preload(
	LabourKey INT NOT NULL,
    TotalRate INT NULL,
	Male FLOAT NULL,
	Female FLOAT NULL,
	CountryName NVARCHAR(50) NULL,
	CONSTRAINT PK_Labour_Preload PRIMARY KEY CLUSTERED( LabourKey )
);
GO

DROP SEQUENCE IF EXISTS dbo.LabourKey;
GO
CREATE SEQUENCE dbo.LabourKey START WITH 1;
GO

DROP PROCEDURE IF EXISTS dbo.Labour_Transform
GO
CREATE PROCEDURE dbo.Labour_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Labour_Preload;

    BEGIN TRANSACTION;
    -- Use Sequence to create new surrogate keys (Create new records)
    INSERT INTO dbo.Labour_Preload
    SELECT NEXT VALUE FOR dbo.LabourKey as LabourKey,
        stg.TotalRate,
        stg.Male,
        stg.Female,
        stg.CountryName
    FROM dbo.Labour_Stage stg
    WHERE NOT EXISTS (SELECT 1 FROM dbo.DimChildLabour dl where dl.CountryName =stg.CountryName)
    -- use existing surrogate key if one exists (add updated records)
    INSERT INTO dbo.Labour_Preload
    SELECT dl.LabourKey,
        stg.TotalRate,
        stg.Male,
        stg.Female,
        stg.CountryName
    FROM dbo.Labour_Stage stg
        JOIN dbo.DimChildLabour dl
        ON dl.CountryName = stg.CountryName
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Labour_Transform
GO
SELECT * FROM dbo.Labour_Preload
GO

DROP TABLE IF EXISTS dbo.Education_Preload;
GO
CREATE TABLE dbo.Education_Preload(
    CountryKey INT NOT NULL,
	LabourKey INT NOT NULL,
	ViolenceKey INT NOT NULL,
	ModernizationKey INT NOT NULL,
	UrbanNum DECIMAL(18,2) NULL,
    RuralNum DECIMAL(18,2) NULL,
    TotalViolenceNum DECIMAL(18,2) NULL,
    TotalLabourNum DECIMAL(18,2) NULL,
	SchoolCompletionRate FLOAT NULL,
	TotalSchoolCompletion FLOAT NULL, --POPULATION
	OutofSchoolRate FLOAT NULL,
	TotalOutofSchool FLOAT NULL, --POPULATION
	NetAttendanceRate FLOAT NULL,
	TotalNetAttendance FLOAT NULL, --POPULATION
	LDC NVARCHAR(50) NULL
);
GO

DROP PROCEDURE if EXISTS dbo.Education_Transform
GO
CREATE PROCEDURE dbo.Education_Transform
AS
BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    TRUNCATE TABLE dbo.Education_Preload;

    INSERT INTO dbo.Education_Preload /* Columns excluded for brevity */
    SELECT ctp.CountryKey,
        lrp.LabourKey,
        vlp.ViolenceKey,
        mp.ModernizationKey,
		stg.UrbanNum,
		stg.RuralNum,
        stg.TotalViolenceNum,
        stg.TotalLabourNum,
        stg.SchoolCompletionRate,
		stg.TotalSchoolCompletion,
        stg.OutofSchoolRate,
		stg.TotalOutofSchool,
        stg.NetAttendanceRate,
		stg.TotalNetAttendance,
        stg.LDC
    FROM dbo.Education_Stage stg
        JOIN dbo.Country_Preload ctp
        ON stg.CountryName = ctp .CountryName
        JOIN dbo.Violence_Preload vlp
        ON stg.CountryName = vlp.CountryName
        JOIN dbo.Modernization_Preload mp
        ON mp.CountryName = stg.CountryName
        JOIN dbo.Labour_Preload lrp
        ON lrp.CountryName = stg.CountryName
END;
GO

EXECUTE dbo.Education_Transform
GO
SELECT * FROM dbo.Education_Preload
GO

/* ETL Loads */
DROP PROCEDURE IF EXISTS dbo.Country_Load
GO
CREATE PROCEDURE dbo.Country_Load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DELETE  ct FROM dbo.DimCountry ct
        JOIN dbo.Country_Preload pl
        ON ct.CountryKey= pl.CountryKey
    INSERT into dbo.DimCountry
    SELECT * FROM dbo.Country_Preload
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Country_Load
GO
SELECT * FROM dbo.DimCountry
GO

DROP PROCEDURE IF EXISTS dbo.Voilence_Load
GO
CREATE PROCEDURE dbo.Voilence_Load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DELETE  vl FROM dbo.DimViolence vl
        JOIN dbo.Violence_Preload pl
        ON vl.ViolenceKey= pl.ViolenceKey
    INSERT into dbo.DimViolence
    SELECT * FROM dbo.Violence_Preload
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Voilence_Load
GO
SELECT * FROM dbo.DimViolence
GO

DROP PROCEDURE IF EXISTS dbo.Modernization_Load
GO
CREATE PROCEDURE dbo.Modernization_Load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DELETE  dm FROM dbo.DimModernization dm
        JOIN dbo.Modernization_Preload pl
        ON dm.ModernizationKey= pl.ModernizationKey
    INSERT into dbo.DimModernization
    SELECT * FROM dbo.Modernization_Preload
    COMMIT TRANSACTION;
END
GO


EXECUTE dbo.Modernization_Load
GO
SELECT * FROM dbo.DimModernization
GO

DROP PROCEDURE IF EXISTS dbo.Labour_Load
GO
CREATE PROCEDURE dbo.Labour_Load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DELETE  lr FROM dbo.DimChildLabour lr
        JOIN dbo.Labour_Preload pl
        ON lr.LabourKey= pl.LabourKey
    INSERT into dbo.DimChildLabour
    SELECT * FROM dbo.Labour_Preload
    COMMIT TRANSACTION;
END
GO

EXECUTE dbo.Labour_Load
GO
SELECT * FROM dbo.DimChildLabour
GO

DROP PROCEDURE IF EXISTS dbo.Education_Load
GO
CREATE PROCEDURE dbo.Education_Load
AS
    BEGIN;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    INSERT INTO dbo.FactEducation 
    SELECT * 
    FROM dbo.Education_Preload;
END;
GO

EXECUTE dbo.Education_Load
SELECT * FROM dbo.FactEducation
GO