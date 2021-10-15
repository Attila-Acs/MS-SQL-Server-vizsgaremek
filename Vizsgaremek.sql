--A .bak kell + a teljes db script, valamint a doksi
/* Ezzel a vizsgaremekkel nem az a c�lom, hogy egy aut�szerv�z folyamatait min�l �letszer�bben tudjam bemutatni, mivel a megadott metrik�k ezt nem teszik lehet�v�, hanem hogy a tanultak
k�z�l min�l t�bb SQL megold�st tudjak bemutatni.
Az al�bbi felt�telez�sekkel �ltem:
	- Ez egy m�rkaszerv�z, vagyis csak egyf�le aut�m�rk�t szervizelnek. A k�l�nb�z� t�pusokkal sem akartam r�szletesen foglalkozni, ez�rt egy aut�hoz csak a rendsz�m, motorsz�m,
	  alv�zsz�m adatait �s az �zembe helyez�s d�tum�t t�rolom, hogy a vizsgaremek metrik�k k�zel�ben maradhassak.
	- Elektromos aut�kkal nem foglalkozunk. Csak a hagyom�nyos benzines �s d�zeles jav�t�sokat v�gz�nk.
	- Az egyes t�pusokhoz ugyanazok az alkatr�szek kellenek, teh�t nincs t�bbf�le olajsz�r� vagy f�kbet�t, hanem egyfajta j� mindegyikhez.
	- Az alkatr�sz rakt�rban mindig mindenb�l van elegend�.
	- S�t, id�pontfoglal�sra sincs sz�ks�g, mert b�rmikor is �rkezik az �gyf�l, mindig van szabad kapacit�s.
	- Egy aut�nak sincs egyedi, n�vre szabott rendsz�ma �s a v�letlensz�m gener�tor miatt mindegyik rendsz�m a magyar szab�lyok szerinti 3 bet� - 3 sz�m.
	- Minden �gyf�lnek csak 1 aut�ja van
	- Az aut�szerv�z minden munkat�rsa rendelkezik magyar TAJ sz�mmal �s ad�azonos�t� jellel.*/

/*
USE master
GO
DROP LOGIN HRManager
DROP LOGIN FinancialController
DROP LOGIN FinancialAssistant
DROP LOGIN DatabaseAdministrator
DROP SCHEMA IF EXISTS pbi
DROP DATABASE IF EXISTS Autoszerviz
GO
*/

CREATE DATABASE Autoszerviz
  ON  PRIMARY 
( NAME = N'Autoszerviz', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Autoszerviz.mdf' , SIZE = 81920KB , FILEGROWTH = 10% )
 LOG ON 
( NAME = N'Autoszerviz_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Autoszerviz_log.ldf' , SIZE = 8192KB , FILEGROWTH = 10% )
 COLLATE Hungarian_CI_AS
GO
USE master
CREATE LOGIN HRManager WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF										--  2.munkak�r

CREATE LOGIN FinancialController WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF							--  3.munkak�r

CREATE LOGIN FinancialAssistant WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF								--  4.munkak�r
ALTER SERVER ROLE bulkadmin ADD MEMBER FinancialAssistant													-- Az�rt, hogy a P�nz�gyi �gyint�z� tudjon .csv-ket import�lni.

CREATE LOGIN DatabaseAdministrator WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF							-- 15.munkak�r

CREATE LOGIN ChiefExecutiveOfficer WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF							-- 1.munkak�r

CREATE LOGIN ServiceMan WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=Autoszerviz, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF									-- fizikai munk�sok vezet�je

GO
Use Autoszerviz
-- Az al�bbi Global nev� t�bl�ban gy�jt�m az input f�jlok adatait, hogy ne a scriptekbe legyenek elsz�rtan be�getve:
DROP TABLE IF EXISTS dbo.Global
GO
CREATE TABLE dbo.Global (
	GlobalName			varchar(50)		NOT NULL,
	GlobalValue			varchar(100)	NOT NULL
	CONSTRAINT PK_Global_GlobalName PRIMARY KEY (GlobalName))
GO
	INSERT dbo.Global (GlobalName, GlobalValue)
	VALUES('PostInfo2', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\PostInfo2.xml'),
		  ('Keresztnevek', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\Keresztnevek.txt'),
		  ('Csaladnevek', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\Csaladnevek.txt'),
		  ('CsaladnevekFormatFile', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\Csaladnevek.xml'),
		  ('ServiceCategory', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\ServiceCategory.txt'),
		  ('ServiceSubCategory', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\ServiceSubCategory.txt'),
		  ('Employee', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\Employee.txt'),
		  ('RuleTable', 'C:\Users\Reket\Downloads\SQL\Vizsgaremek\RuleTable.txt')
/*	VALUES('PostInfo2', 'D:\Vizsgaremek\PostInfo2.xml'),
		  ('Keresztnevek', 'D:\Vizsgaremek\Keresztnevek.txt'),
		  ('Csaladnevek', 'D:\Vizsgaremek\Csaladnevek.txt'),
		  ('CsaladnevekFormatFile', 'D:\Vizsgaremek\Csaladnevek.xml'),
		  ('ServiceCategory', 'D:\Vizsgaremek\ServiceCategory.txt'),
		  ('ServiceSubCategory', 'D:\Vizsgaremek\ServiceSubCategory.txt'),
		  ('Employee', 'D:\Vizsgaremek\Employee.txt'),
		  ('RuleTable', 'D:\Vizsgaremek\RuleTable.txt') */
	ALTER TABLE dbo.Global ADD CONSTRAINT AK_Global_GlobalValue UNIQUE (GlobalValue)
--SELECT * FROM Global

DROP TABLE IF EXISTS TempAddress
GO
CREATE TABLE TempAddress(
	AddressID	int			NOT NULL IDENTITY,
	PostalCode	char(4)		NOT NULL,
	City		varchar(25) NOT NULL,
	StreetName	varchar(30) NULL,
	StreetType	varchar(15) NULL,
	HouseNumber varchar(25) NULL,
	CONSTRAINT PK_TempAddress_AddressID PRIMARY KEY (AddressID))
GO

-- A Partner t�bla c�moszlopaihoz egy xml t�pus� input f�jlb�l t�lt�m fel az adatokat t�rolt elj�r�s seg�ts�g�vel el�sz�r m�g csak egy �tmeneti t�bl�ba:
GO
CREATE OR ALTER PROC PartnerAddress
AS
BEGIN
	DECLARE @PostinfoFile varchar(200), @xml xml, @TAD varchar(max)
	SELECT @PostinfoFile = GlobalValue FROM Global WHERE GlobalName='PostInfo2'
	DROP TABLE IF EXISTS dbo.XD
	CREATE TABLE dbo.XD (XD xml)
	CREATE TABLE #NewAddressItem (NAI int)
	
	SET @TAD = 'INSERT dbo.XD SELECT I 
		FROM OPENROWSET (BULK ''' + @PostinfoFile + ''', SINGLE_BLOB) X(I)'
	EXECUTE (@TAD)
	SELECT @xml = XD FROM XD
	DROP TABLE dbo.XD

	TRUNCATE TABLE TempAddress
	INSERT TempAddress
	SELECT
		N.value('@zipCode[1]', 'char(4)') PostalCode,
		N.value('city[1]', 'varchar(25)') City,
		N.value('(street/name)[1]', 'varchar(30)') StreetName,
		N.value('(street/type)[1]', 'varchar(15)') StreetType,
		N.value('(street/houseNumber)[1]', 'varchar(25)') HouseNumber
	FROM @xml.nodes('/postInfo/post') M(N)											--2926 db c�mem lesz.
END
GO
EXEC PartnerAddress
--SELECT * FROM TempAddress

--A Partner t�bla csal�dn�v oszlop�hoz az OPENROWSET paranccsal t�lt�m fel az adatokat el�sz�r m�g egy �tmeneti t�bl�ba:
DROP TABLE IF EXISTS TempLastName
	DECLARE @FormatFileLN varchar(200), @ImportFileLN varchar(200), @LN varchar(max)
	SELECT @ImportFileLN = GlobalValue FROM Global WHERE GlobalName = 'Csaladnevek'
	SELECT @FormatFileLN = GlobalValue FROM Global WHERE GlobalName = 'CsaladnevekFormatFile'
CREATE TABLE TempLastName (LastName varchar(30) CONSTRAINT PK_TempLastName_LastName PRIMARY KEY (LastName))
	SET @LN = '
		INSERT TempLastName 
			SELECT * FROM OPENROWSET (BULK ''' + @ImportFileLN + ''', FORMATFILE = ''' + @FormatFileLN + ''', FIRSTROW = 1) X'
	EXEC (@LN)
--SELECT * FROM TempLastName

-- Miel�tt �talak�tom a vezet�kneveket csinos form�ra, el�tte meggy�z�d�k arr�l, hogy ki vannak-e t�ltve, illetve hogy csak bet�ket tartalmaznak-e:
GO
	CREATE OR ALTER PROC UpdateLastName
	AS
		DECLARE	@LN varchar(max)
		SET @LN = 'SELECT * FROM TempLastName'
		EXEC (@LN)
	IF @LN IS NULL
		RETURN 1
	ELSE IF @LN LIKE '%[0-9]%'
		RETURN 2
	ELSE
		UPDATE TempLastName SET LastName = LEFT(LastName,1) + LOWER(SUBSTRING(LastName, 2, 29))
GO
EXEC UpdateLastName

-- A Partner t�bla keresztn�v oszlop�hoz a BULK INSERT dinamikus SQL m�dszer�vel t�lt�m fel az adatokat el�sz�r m�g egy �tmeneti t�bl�ba:
DROP TABLE IF EXISTS TempFirstName
	DECLARE @ImportFileFN varchar(200), @FN varchar(max)
	SELECT @ImportFileFN = GlobalValue FROM Global WHERE GlobalName = 'Keresztnevek'
CREATE TABLE TempFirstName (FirstName varchar(30), Gender char(1)  CONSTRAINT PK_TempFirstName_FirstName PRIMARY KEY (FirstName))
SET @FN = '
	BULK INSERT TempFirstName 
		FROM ''' + @ImportFileFN + '''
		WITH(CODEPAGE = ''65001'', FIELDTERMINATOR = '';'', FIRSTROW = 2)'
EXEC (@FN)
--SELECT * FROM TempFirstName

-- A 2926 darab k�l�nb�z� v�letlen Partner n�v el��ll�t�sa a NEWID() f�ggv�nnyel:
DROP TABLE IF EXISTS TempFullName
CREATE TABLE TempFullName (
		PartnerID	smallint	NOT NULL IDENTITY,
		LastName	varchar(10)	NOT NULL,
		FirstName	varchar(15)	NOT NULL,
		Gender		char(1)		NOT NULL
		CONSTRAINT PK_TempFullName_PartnerID PRIMARY KEY (PartnerID))

	INSERT TempFullName (LastName, FirstName, Gender)
	SELECT TOP 2926 TLN.LastName, TFN.FirstName, TFN.Gender
	FROM TempFirstName TFN
	CROSS JOIN TempLastName TLN
	ORDER BY NEWID()
--SELECT * FROM TempFullName

--V�letlen telefonsz�mok el��ll�t�sa t�bla v�ltoz� �s RAND() f�ggv�ny haszn�lat�val:
DECLARE @counter SMALLINT, @rnd int
DECLARE @Result table	(PartnerID			smallint	NOT NULL IDENTITY,
						 PhoneNumberPrefix	char(2)		NOT NULL,
						 PhoneNumber		char(8)		NOT NULL);  
SET @counter = 1;  
WHILE @counter <= 2926 
   BEGIN  
      SET @rnd = CAST (RAND()*6+1 as int)
	  INSERT @Result VALUES (CHOOSE (@rnd,1,20,30,31,50,70), FORMAT(CAST(LEFT(CAST(RAND()*100000000000000 AS bigint),7) as int), '###-####'))
      SET @counter = @counter + 1  
   END;
SELECT * FROM @Result

-- ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS FK_Employee_Partner_PartnerID 
-- ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS FK_Employee_Partner_PartnerID
DROP TABLE IF EXISTS Partner															-- Miel�tt t�rl�m a t�bl�t, el�bb t�r�lni kell a t�bl�b�l indul� idegen kulcsokat.
CREATE TABLE Partner (
	PartnerID			smallint		NOT NULL IDENTITY,	-- csal�di v�llalkoz�s keretein bel�l k�v�nunk maradni, ez�rt a 32.000-n�l nagyobb Partnerk�r nem �letszer� �s
	IsEmployee			bit				NOT NULL,														-- a smallint adatt�pus csak 2 byte-ot foglal el az SQL express-b�l.
	IsCustomer			bit				NOT NULL,
	PartnerLastName		varchar(30)		NOT NULL,
	PartnerFirstName	varchar(30)		NOT NULL,
	Gender				char(1)			NOT NULL,
	PostalCode			char(4)			NOT NULL,
	City				varchar(25)		NOT NULL,
	StreetName			varchar(30)		NULL,
	StreetType			varchar(15)		NULL,
	HouseNumber			varchar(25)		NULL,
	eMailAddress		varchar(45)		NULL,
	PhoneNumberPrefix	varchar(2)		NOT NULL,
	PhoneNumber			char(8)			NOT NULL,
	CreationDate		smalldatetime	NOT NULL,			-- M�sodpercre nincs sz�ks�g �s a 2079.�vi fels� korl�t sem jelent val�s probl�m�t �s csak 4 byte-ot fogyaszt.
	CessationDate		smalldatetime	NOT NULL,
	IsActive			bit				NOT NULL,
	CONSTRAINT PK_Partner_PartnerID PRIMARY KEY (PartnerID))
	ALTER TABLE dbo.Partner ADD CONSTRAINT CK_Partner_Gender CHECK (Gender = 1 OR Gender = 2)
	ALTER TABLE dbo.Partner ALTER COLUMN eMailAddress varchar(45) COLLATE SQL_Latin1_General_Cp1251_CS_AS
	ALTER TABLE dbo.Partner ADD CONSTRAINT DF_Partner_CreationDate DEFAULT SYSDATETIME() FOR CreationDate
	ALTER TABLE dbo.Partner ADD CONSTRAINT DF_Partner_CessationDate DEFAULT '20790606 23:59' FOR CessationDate
	ALTER TABLE dbo.Partner ADD CONSTRAINT CK_Partner_CessationDate CHECK (CreationDate <= CessationDate)
	ALTER TABLE dbo.Partner ADD CONSTRAINT DF_Partner_IsEmployee DEFAULT 0 FOR IsEmployee
	ALTER TABLE dbo.Partner ADD CONSTRAINT DF_Partner_IsCustomer DEFAULT 1 FOR IsCustomer
	ALTER TABLE dbo.Partner ADD CONSTRAINT DF_Partner_IsActive DEFAULT 1 FOR IsActive
	ALTER TABLE dbo.Partner ADD PartnerName AS CONCAT(PartnerLastName, ' ', PartnerFirstName)
	ALTER TABLE dbo.Partner ADD PartnerAddress AS CONCAT(PostalCode, ', ', City, ' ', StreetName, ' ', StreetType, ' ', HouseNumber)
	CREATE NONCLUSTERED INDEX IX_Partner_PartnerName ON Partner (PartnerName)
	CREATE NONCLUSTERED INDEX IX_Partner_PartnerAddress ON Partner (PartnerAddress)


/* Collation ellen�rz�s az e-mail c�mek miatt:
	SELECT t.name TableName, c.name ColumnName, collation_name  
	FROM sys.columns c  
	inner join sys.tables t on c.object_id = t.object_id;  
*/


-- A Partner t�bla felt�lt�se az el��ll�tott adatokkal:
	INSERT Partner (PartnerLastName, PartnerFirstName, Gender, PostalCode, City, StreetName, StreetType, HouseNumber, PhoneNumberPrefix, PhoneNumber)
	SELECT N.LastName, N.FirstName, N.Gender, TA.PostalCode, TA.City, TA.StreetName, TA.StreetType, TA.HouseNumber, R.PhoneNumberPrefix, R.PhoneNumber
	FROM TempFullName N
	INNER JOIN TempAddress TA ON N.PartnerID = TA.AddressID
	INNER JOIN @Result R ON N.PartnerID = R.PartnerID


--SELECT * FROM Partner

-- A v�letlenszer�en el��ll�tott Partner nevek alapj�n legy�rtom hozz�juk a szint�n v�letlenszer� e-mail c�m�ket ez�ttal ABS(CHECKSUM(NEWID())) f�ggv�nyekkel:
GO
	CREATE OR ALTER PROC UpdateEMailAddress
	AS
		DECLARE	@EM varchar(max)
		SET @EM = 'SELECT PartnerLastName, PartnerFirstName FROM Partner'
		EXEC (@EM)
	IF @EM IS NULL
		RETURN 1
	ELSE IF @EM LIKE '%[0-9]%'
		RETURN 2
	ELSE
UPDATE dbo.Partner SET eMailAddress = CONCAT(LOWER(PartnerLastName), '.', LOWER(PartnerFirstName), '@',
	CASE
		WHEN  ABS(CHECKSUM(NEWID()))%5 + 1 = 1 THEN 'gmail.com'
		WHEN  ABS(CHECKSUM(NEWID()))%5 + 1 = 2 THEN 'freemail.hu'
		WHEN  ABS(CHECKSUM(NEWID()))%5 + 1 = 3 THEN 'outlook.com'
		WHEN  ABS(CHECKSUM(NEWID()))%5 + 1 = 4 THEN 'yahoo.com'
		ELSE 'citromail.hu'
	END  ) WHERE eMailAddress IS NULL
GO
EXEC UpdateEMailAddress
--SELECT * FROM Partner

-- A telefonsz�mok megfelel� hossz�s�g�t ellen�rz� skal�r f�ggv�ny:
GO
CREATE OR ALTER FUNCTION dbo.PhoneNumberCheck 
	(@Prefix varchar(2), @Phone char(8))
RETURNS bit
AS
	BEGIN
		IF @Prefix IS NULL OR @Phone IS NULL
			RETURN NULL
		ELSE IF (LEN(@Prefix) >= 1 OR LEN(@Prefix) < 3) AND LEN(@Phone) = 8
			RETURN 1
	RETURN 0	-- A skal�r f�ggv�ny ragaszkodik ahhoz, hogy az utols� END el�tt legyen egy RETURN 0
	END
GO

	ALTER TABLE dbo.Partner ADD CONSTRAINT CK_Partner_PhoneNumberPrefix_PhoneNumber CHECK (dbo.PhoneNumberCheck(PhoneNumberPrefix, PhoneNumber) = 1)
--	ALTER TABLE dbo.Partner DROP CONSTRAINT IF EXISTS CK_Partner_PhoneNumberPrefix_PhoneNumber


	DROP TABLE IF EXISTS dbo.PartnerLog
	CREATE TABLE PartnerLog (
		PartnerLogID		int				IDENTITY
		,PartnerID			smallint		
		,IsEmployee			bit				
		,IsCustomer			bit				
		,IsActive			bit				
		,DMLAction			varchar(10)
		,InsertUser			varchar(100)	DEFAULT SUSER_SNAME()
		,InsertDate			datetime2		DEFAULT SYSDATETIME()
		CONSTRAINT PK_PartnerLog_PartnerLogID PRIMARY KEY (PartnerLogID))

GO
	CREATE OR ALTER TRIGGER trgPartner_IsEmployee ON dbo.Partner FOR UPDATE
	AS
		IF @@NESTLEVEL = 1
			BEGIN
				INSERT dbo.PartnerLog (PartnerID, IsEmployee, IsCustomer, DMLAction)
				SELECT I.PartnerID, I.IsEmployee, I.IsCustomer, 'UPDATE'
				FROM inserted I
				INNER JOIN deleted D ON I.PartnerID = D.PartnerID 
				UPDATE dbo.Partner SET IsEmployee = '1'
				FROM inserted I
				INNER JOIN dbo.Partner P ON I.PartnerID = P.PartnerID
				WHERE P.City LIKE 'EGER'
			END
GO

UPDATE dbo.Partner SET IsEmployee = '0' WHERE City LIKE 'EGER'

SELECT * FROM dbo.Partner WHERE City LIKE 'EGER'
SELECT * FROM dbo.PartnerLog


DROP TABLE IF EXISTS InvoiceHeader
CREATE TABLE InvoiceHeader (
	InvoiceID			int				NOT NULL IDENTITY
	,PartnerID			smallint		NOT NULL 
	,DueDate			date			NOT NULL
	,SubTotal			money			NOT NULL
	,TaxAmount			money			NOT NULL
	,TotalDue			money			NOT NULL
	CONSTRAINT PK_InvoiceHeader_InvoiceID PRIMARY KEY (InvoiceID))
	ALTER TABLE dbo.InvoiceHeader ADD CONSTRAINT DF_InvoiceHeader_DueDate DEFAULT SYSDATETIME() FOR DueDate
	ALTER TABLE dbo.InvoiceHeader ADD CONSTRAINT FK_InvoiceHeader_Partner_PartnerID FOREIGN KEY (PartnerID) REFERENCES dbo.Partner (PartnerID)

DROP TABLE IF EXISTS InvoiceDetail
CREATE TABLE InvoiceDetail (
	InvoiceDetailID		int				NOT NULL IDENTITY
	,InvoiceID			int				NOT NULL
	,ServiceEventID		int				NOT NULL
	,MaterialFee		money			NULL
	,LabourFee			money			NULL
	,FeeDiscount		money			NULL
	CONSTRAINT PK_InvoiceDetail_InvoiceDetailID_InvoiceID PRIMARY KEY (InvoiceDetailID, InvoiceID))
	ALTER TABLE dbo.InvoiceDetail ADD CONSTRAINT FK_InvoiceDetail_InvoiceHeader_InvoiceID FOREIGN KEY (InvoiceID) REFERENCES dbo.InvoiceHeader (InvoiceID)


-- A JobTitle (munkak�r) t�bla felt�lt�se adatokkal az INSERT ... VALUES m�dszerrel, mert a BULK INSERT-hez t�bbet kellett volna g�pelni �s nem tudtam volna kommentet f�zni p�r sorhoz:
--	ALTER TABLE dbo.JobTitle DROP CONSTRAINT IF EXISTS AK_JobTitle_JobTitle
DROP TABLE IF EXISTS dbo.JobTitle

CREATE TABLE dbo.JobTitle (
	JobTitleID			tinyint			NOT NULL IDENTITY,
	JobTitle			varchar(50)		NOT NULL,
	CONSTRAINT PK_JobTitle_JobTitleID PRIMARY KEY (JobTitleID))

	INSERT dbo.JobTitle (JobTitle)
	VALUES	('Chief Executive Officer'),
			('Human Recource Manager'),						--  2.munkak�r
			('Financial Controller'),						--  3.munkak�r
			('Financial Assistant/Cashier'),				--  4.munkak�r
			('Technical Leader'),							--							Munkafelvev�
			('Electrician'),								--							Aut� villamoss�gi szerel�
			('Car Mechanic'),
			('Body Locksmith'),								--							Karossz�ria lakatos
			('Car Polisher'),								--							Aut� f�nyez�
			('Car Washer'),									--							Aut� mos� alkalmazott
			('Stocker'),									--							Rakt�ros
			('Assistant to the Chief Executive Officer'),
			('Insurance Agent'),
			('Cleaning Staff'),								--							Takar�t� szem�lyzet
			('Database Administrator')						--  15.munkak�r

	ALTER TABLE dbo.JobTitle ADD CONSTRAINT AK_JobTitle_JobTitle UNIQUE (JobTitle)
--SELECT * FROM JobTitle

/*	ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS FK_Employee_JobTitle_JobTitleID
	ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS AK_Employee_NationalIDNumber
	ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS AK_Employee_TaxID */

DROP TABLE IF EXISTS dbo.Employee
CREATE TABLE dbo.Employee (
	PartnerID			smallint		NOT NULL
	,JobTitleID			tinyint			NOT NULL																	-- A poz�ci� v�lt�s miatt indokolt az id�soros t�bla.
	,HireDate			date			NOT NULL
	,IsActive			bit				NOT NULL
	,LeaveDate			date			NULL
	,BirthDate			date			NOT NULL
	,NationalIDNumber	char(9)			NOT NULL								-- Azt felt�telezem, hogy az aut�szerv�z minden munkat�rsa rendelkezik magyar TAJ sz�mmal.
	,TaxID				char(10)		NOT NULL						-- Azt felt�telezem, hogy az aut�szerv�z minden munkat�rsa rendelkezik magyar ad�azonos�t� jellel.
	,PositionStartDate	date			NOT NULL
	,Salary				char(7)			NOT NULL																	-- A fizet�s v�ltoz�s miatt indokolt az id�soros t�bla.
	,SalaryStartDate	date			NOT NULL
	CONSTRAINT PK_Employee_NationalIDNumber PRIMARY KEY (NationalIDNumber))

	ALTER TABLE dbo.Employee ADD CONSTRAINT DF_Employee_HireDate DEFAULT SYSUTCDATETIME() FOR HireDate		-- Az id�soros t�blas�g miatt nem el�g a SYSDATETIME(), mert j�v� idej�s�get
	ALTER TABLE dbo.Employee ADD CONSTRAINT DF_Employee_LeaveDate DEFAULT '20790606 23:59' FOR LeaveDate																	-- csin�l.
	ALTER TABLE dbo.Employee ADD CONSTRAINT CK_Employee_HireDate_LeaveDate CHECK (HireDate <= LeaveDate)
	ALTER TABLE dbo.Employee ADD CONSTRAINT DF_Employee_IsActive DEFAULT 1 FOR IsActive
	ALTER TABLE dbo.Employee ADD CONSTRAINT AK_Employee_NationalIDNumber UNIQUE (NationalIDNumber)
	ALTER TABLE dbo.Employee ADD CONSTRAINT AK_Employee_TaxID UNIQUE (TaxID)
	ALTER TABLE dbo.Employee ADD CONSTRAINT DF_Employee_PositionStartDate DEFAULT SYSUTCDATETIME() FOR PositionStartDate
	ALTER TABLE dbo.Employee ADD CONSTRAINT CK_Employee_Salary CHECK (Salary >= 200000 AND Salary <= 1000000)
	ALTER TABLE dbo.Employee ADD CONSTRAINT DF_Employee_SalaryStartDate DEFAULT SYSUTCDATETIME() FOR SalaryStartDate
	ALTER TABLE dbo.Employee ADD CONSTRAINT FK_Employee_Partner_PartnerID FOREIGN KEY (PartnerID) REFERENCES dbo.Partner (PartnerID) -- ON UPDATE CASCADE
	ALTER TABLE dbo.Employee ADD CONSTRAINT FK_Employee_JobTitle_JobTitleID FOREIGN KEY (JobTitleID) REFERENCES dbo.JobTitle (JobTitleID)

-- Ez a skal�r f�ggv�ny a munkav�llal�k TAJ sz�mainak val�dis�g�t ellen�rzi:
GO
CREATE OR ALTER FUNCTION dbo.NationalIDNumberCheck 
	(@TAJNo char(9))
RETURNS bit
AS
BEGIN
	DECLARE @I smallint
    IF @TAJNo IS NULL 
		RETURN NULL
    ELSE IF LEN(@TAJNo) != 9
		OR @TAJNo LIKE '%[^0-9]%'	-- OR SUBSTRING(@TAJNo, 1, 1) NOT IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
		RETURN 0
    ELSE
		BEGIN
	        SET @I = (LEFT(@TAJNo, 1) * 3 + SUBSTRING(@TAJNo, 2, 1) * 7 + SUBSTRING(@TAJNo, 3, 1) * 3 + SUBSTRING(@TAJNo, 4, 1) * 7 + 
		        SUBSTRING(@TAJNo, 5, 1) * 3 + SUBSTRING(@TAJNo, 6, 1) * 7 + SUBSTRING(@TAJNo, 7, 1) * 3 + SUBSTRING(@TAJNo, 8, 1) * 7) % 10 
			IF @I = RIGHT(@TAJNo, 1)
		RETURN 1
		END
	RETURN 0	-- A skal�r f�ggv�ny ragaszkodik ahhoz, hogy az utols� END el�tt legyen egy RETURN 0
END	
GO
--SELECT dbo.NationalIDNumberCheck ('003738711')
	ALTER TABLE dbo.Employee ADD CONSTRAINT CK_Employee_NationalIDNumber CHECK (dbo.NationalIDNumberCheck(NationalIDNumber) = 1)
--	ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS CK_Employee_NationalIDNumber

-- Ez a skal�r f�ggv�ny a munkav�llal�k ad�azonos�t� jeleinek �s sz�let�si d�tumainak val�dis�g�t ellen�rzi:
GO
CREATE OR ALTER FUNCTION dbo.TaxIDCheck 
	(@TaxID char(10), @Birthday date)
RETURNS bit
AS
BEGIN
	DECLARE @I smallint,
	@J int = CAST(CONCAT(SUBSTRING(@TaxID, 2, 1), SUBSTRING(@TaxID, 3, 1), SUBSTRING(@TaxID, 4, 1), SUBSTRING(@TaxID, 5, 1), SUBSTRING(@TaxID, 6, 1)) AS int)
    IF @TaxID IS NULL 
		RETURN NULL
    ELSE IF LEN(@TaxID) != 10
		OR @TaxID LIKE '%[^0-9]%'		--OR SUBSTRING(@TaxID, 1, 1) NOT IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
		RETURN 0
    ELSE
		BEGIN
	        SET @I = (LEFT(@TaxID, 1) + SUBSTRING(@TaxID, 2, 1) * 2 + SUBSTRING(@TaxID, 3, 1) * 3 + SUBSTRING(@TaxID, 4, 1) * 4 + 
		        SUBSTRING(@TaxID, 5, 1) * 5 + SUBSTRING(@TaxID, 6, 1) * 6 + SUBSTRING(@TaxID, 7, 1) * 7 + SUBSTRING(@TaxID, 8, 1) * 8 +
				SUBSTRING(@TaxID, 9, 1) * 9) % 11 
			IF @I = RIGHT(@TaxID, 1) AND @J = DATEDIFF(d, '18670101', @Birthday)
			
		RETURN 1
		END
	RETURN 0	-- A skal�r f�ggv�ny ragaszkodik ahhoz, hogy az utols� END el�tt legyen egy RETURN 0
END	
GO
--SELECT dbo.TaxIDCheck ('8218810951', '19261129')

	ALTER TABLE dbo.Employee ADD CONSTRAINT CK_Employee_TaxID CHECK (dbo.TaxIDCheck(TaxID, BirthDate) = 1)
--	ALTER TABLE dbo.Employee DROP CONSTRAINT IF EXISTS CK_Employee_TaxID



/* Az Employee (munkav�llal�) t�bl�n�l nem haszn�lhattam v�letlensz�m gener�tort, hogy tudjam ellen�rizni a TAJ sz�mok �s az ad�azonos�t� sz�mok helyess�g�t.
El�sz�r a Global t�bl�n kereszt�li BULK INSERT-tel pr�b�lkoztam, de nem j�ttem r� mi�rt nem m�k�dik, ez�rt v�g�lis az INSERT ... VALUES m�dszert haszn�ltam az adatok felt�lt�s�re: */
-- TRUNCATE TABLE Employee

	DECLARE @ImportFileEmployee varchar(200), @E varchar(max)
	SELECT @ImportFileEmployee = GlobalValue FROM Global WHERE GlobalName = 'Employee'
SET @E = '
	BULK INSERT dbo.Employee 
		FROM ''' + @ImportFileEmployee + '''
		WITH(CODEPAGE = ''65001'', FIELDTERMINATOR = ''\t'', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'
--SELECT @E
EXEC (@E)

--SELECT dbo.TaxIDCheck ('8476633777', '19970701')		
--SELECT * FROM Employee



/************************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************************
ITT KELL EGY KIS SZ�NETET HAGYNI A BET�LT�SKOR, HOGY LEGYEN K�L�NBS�G A SYSUTCDATETIME() F�GGV�NYEK FENTI �S LENTI �RT�KEI K�Z�TT
*************************************************************************************************************************************************************************************
************************************************************************************************************************************************************************************/




GO
	ALTER TABLE dbo.Employee ADD HistoryStartDate datetime2(0) GENERATED ALWAYS AS ROW START
								 CONSTRAINT DF_Employee_HistoryStartDate DEFAULT SYSUTCDATETIME(),
								 HistoryEndDate datetime2(0) GENERATED ALWAYS AS ROW END
								 CONSTRAINT DF_Employee_HistoryEndDate DEFAULT CONVERT(datetime2(0),'99991231 23:59:59'), PERIOD FOR SYSTEM_TIME (HistoryStartDate, HistoryEndDate)
	ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory))					-- A CAST() f�ggv�nnyel nem akart m�k�dni datetime2(0)-�s konvert�l�s!
--	ALTER TABLE dbo.Employee SET (SYSTEM_VERSIONING = OFF)

GO


GO
	CREATE OR ALTER PROC UpdateSalary
		@PartnerID	int,
		@NewSalary	char(7)
	AS
	IF @NewSalary IS NULL
		RETURN 1
	ELSE IF @NewSalary < 200000 OR @NewSalary > 1000000
		RETURN 2
	ELSE IF @NewSalary = (SELECT Salary FROM Employee WHERE PartnerID = @PartnerID)									      -- Ha megegyezik a jelenlegivel, akkor ne v�ltoztassuk meg.
		RETURN 3
	ELSE IF NOT EXISTS (SELECT * FROM Employee WHERE PartnerID = @PartnerID)										-- Csak meglev� munkav�llal�nak lehessen v�ltoztatni a fizet�s�n.
		RETURN 4
	ELSE
UPDATE Employee SET Salary = @NewSalary/*, SalaryEndDate = SYSUTCDATETIME()*/ WHERE PartnerID = @PartnerID
GO
EXEC UpdateSalary 16, '590000'
EXEC UpdateSalary 7, '580000'
EXEC UpdateSalary 17, '570000'
SELECT * FROM Employee FOR SYSTEM_TIME ALL WHERE JobTitleID = 7

/*
-- Kiknek volt fizet�s emel�se az elm�lt f�l �vben?
DECLARE @TODAY date = GETDATE(), @HalfYearAgo date = DATEADD(month, -6, GETDATE())
SELECT P.PartnerName, JobTitle
FROM Employee --FOR SYSTEM_TIME BETWEEN @TODAY AND @HalfYearAgo
INNER JOIN Partner P ON Employee.PartnerID = P.PartnerID
INNER JOIN JobTitle J ON Employee.JobTitleID = J.JobTitleID
WHERE Salary 

*/


/* 333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333 */

--	ALTER TABLE dbo.Car DROP CONSTRAINT IF EXISTS AK_Car_PlateNumber
--V�letlen rendsz�mok, motor- �s alv�zsz�mok, valamint �zembehelyez�si d�tumok el��ll�t�sa t�bla v�ltoz� �s RAND() f�ggv�ny haszn�lat�val:
DECLARE @counter SMALLINT, @rnd int, /* Magyar rendsz�m gener�tor: */@PL1 TINYINT, @PL2 TINYINT, @PL3 TINYINT, @PN1 TINYINT, @PN2 TINYINT, @PN3 TINYINT,
				/* Motorsz�m gener�tor: */ @EL1 TINYINT, @EL2 TINYINT, @EN1 TINYINT, @EN2 TINYINT, @EN3 TINYINT, @EN4 TINYINT, @EN5 TINYINT, @EN6 TINYINT, @EN7 TINYINT, @EN8 TINYINT,
				/* Alv�zsz�m gener�tor: */ @CL1 TINYINT, @CL2 TINYINT, @CL3 TINYINT, @CN1 TINYINT, @CN2 TINYINT, @CN3 TINYINT, @CN4 TINYINT, @CN5 TINYINT, @CN6 TINYINT
DECLARE @Result table	(PartnerID			smallint		NOT NULL IDENTITY
						 ,PlateNumber		varchar(10)		NOT NULL
						 ,EngineNumber		varchar(20)		NOT NULL
						 ,ChassisNumber		varchar(20)		NOT NULL
						 );  
SET @counter = 1;  
WHILE @counter <= 2926 
   BEGIN
-- Magyar rendsz�m gener�tor:   
		SET @PL1 = ABS(CHECKSUM(NEWID())) % 19 + 1			-- Mivel 2021-ben az S bet�s rendsz�mokat osztj�k, ez�rt az els� karaktert csak A-S k�z�tti tartom�nyban enged�lyeztem.
		SET @PL2 = ABS(CHECKSUM(NEWID())) % 25 + 1	-- K�z�pen nem lehet Q, mert k�nnyen O-nak n�zhet�. Forr�s: https://hu.wikipedia.org/wiki/Magyar_forgalmi_rendsz%C3%A1mok#Jelen
		SET @PL3 = ABS(CHECKSUM(NEWID())) % 23 + 1										-- Utols� bet� nem lehet I, O �s Q, mert k�nnyen �sszekeverhet�k, illetve sz�mnak n�zhet�k.
		SET @PN1 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @PN2 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @PN3 = ABS(CHECKSUM(NEWID())) % 10 + 1
-- Motorsz�m gener�tor:
		SET @rnd = CAST (RAND()*5+1 as int )
		SET @EL1 = ABS(CHECKSUM(NEWID())) % 26 + 1
		SET @EL2 = ABS(CHECKSUM(NEWID())) % 26 + 1
		SET @EN1 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN2 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN3 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN4 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN5 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN6 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN7 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @EN8 = ABS(CHECKSUM(NEWID())) % 10 + 1
-- Alv�zsz�m gener�tor:
		SET @CL1 = ABS(CHECKSUM(NEWID())) % 26 + 1
		SET @CL2 = ABS(CHECKSUM(NEWID())) % 26 + 1
		SET @CL3 = ABS(CHECKSUM(NEWID())) % 26 + 1
		SET @CN1 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @CN2 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @CN3 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @CN4 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @CN5 = ABS(CHECKSUM(NEWID())) % 10 + 1
		SET @CN6 = ABS(CHECKSUM(NEWID())) % 10 + 1
		
	  INSERT @Result VALUES (
		CONCAT(SUBSTRING('ABCDEFGHIJKLMNOPQRS', @PL1, 1), SUBSTRING('ABCDEFGHIJKLMNOPRSTUVWXYZ', @PL2, 1), SUBSTRING('ABCDEFGHJKLMNPRSTUVWXYZ', @PL3, 1), '-',
			SUBSTRING('0123456789', @PN1, 1), SUBSTRING('0123456789', @PN2, 1), SUBSTRING('0123456789', @PN3, 1)),	-- Rendsz�m
--	Sajnos a string adat eset�n nem haszn�lhat� a FORMAT(), '### #### ######') formula, ez�rt k�nytelen voltam be�getni a 2db elv�laszt� sz�k�zt az adatmez�be:
		CONCAT(CHOOSE(@rnd,'H5F', 'H5H', 'K7M', 'H4M', 'K9K'), ' ', SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @EL1, 1), SUBSTRING('0123456789', @EN1, 1),
			SUBSTRING('0123456789', @EN2, 1), SUBSTRING('0123456789', @EN3, 1), ' ', SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @EL2, 1), SUBSTRING('0123456789', @EN4, 1),
			SUBSTRING('0123456789', @EN5, 1), SUBSTRING('0123456789', @EN6, 1), SUBSTRING('0123456789', @EN7, 1), SUBSTRING('0123456789', @EN8, 1)),	-- Motorsz�m
		CONCAT(SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @CL1, 1), SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @CL2, 1), SUBSTRING('0123456789', @CN1, 1),
			SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', @CL3, 1), SUBSTRING('0123456789', @CN2, 1), SUBSTRING('0123456789', @CN3, 1), SUBSTRING('0123456789', @CN4, 1),
			SUBSTRING('0123456789', @CN5, 1), SUBSTRING('0123456789', @CN6, 1)))	--Alv�zsz�m
      SET @counter = @counter + 1  
   END;
SELECT * FROM @Result

DROP TABLE IF EXISTS dbo.Car
CREATE TABLE dbo.Car (
	CarID				smallint		NOT NULL IDENTITY						-- az egyszer�s�t�s kedv��rt azt felt�telezem, hogy minden �gyf�lnek csak 1 aut�ja van
	,PartnerID			smallint		NOT NULL
	,PlateNumber		varchar(10)		NOT NULL		-- Rendsz�m
	,EngineNumber		varchar(20)		NOT NULL		-- Motorsz�m

/* Nem akartam nagy m�rt�kben meghaladni a metrik�ban meghat�rozott 9db t�bla sz�mot, ez�rt nem hoztam l�tre egy olyan seg�d t�bl�t, ami alapj�n meghat�rozhat� lenne, hogy melyik motorsz�m
a benzines �s melyik a d�zel, pedig ez fontos, mert d�zeln�l nem lehet gy�jt�gyerty�t cser�lni, mivel nincs benne ilyen, ugyan�gy a benzin motorokban pedig nincs un. AdBlue folyad�k.
Ezt az inform�ci�t a ServiceSubCategory t�bla Fuel (�zemanyag) oszlop�val jelzem. Azok lesznek a d�zel motorok, amelyekn�l a motorsz�m els� 3 karaktere K9K lesz. */

	,ChassisNumber		varchar(20)		NOT NULL		-- Alv�zsz�m
	,ActivationDate		date			NULL			-- �zembehelyez�s d�tuma. Csak az�rt NULL, mert k�s�bb ker�l felt�lt�sre egy UPDATE paranccsal.
	,Kilometer			int				NULL			-- Kilom�ter �ra �ll�s. Csak az�rt NULL, mert k�s�bb ker�l felt�lt�sre egy UPDATE paranccsal.
	CONSTRAINT PK_Car_CarID PRIMARY KEY (CarID))
	ALTER TABLE dbo.Car ADD CONSTRAINT AK_Car_PlateNumber UNIQUE (PlateNumber)
	ALTER TABLE dbo.Car ADD CONSTRAINT AK_Car_EngineNumber UNIQUE (EngineNumber)
	ALTER TABLE dbo.Car ADD CONSTRAINT AK_Car_ChassisNumber UNIQUE (ChassisNumber)
	ALTER TABLE dbo.Car ADD CONSTRAINT CK_Car_ActivationDate CHECK (ActivationDate <= SYSDATETIME())
	ALTER TABLE dbo.Car ADD CONSTRAINT FK_Car_Partner_PartnerID FOREIGN KEY (PartnerID) REFERENCES dbo.Partner (PartnerID)
	CREATE NONCLUSTERED INDEX IX_Car_PartnerID ON Car (PartnerID)

-- Az aut� (Car) t�bla felt�lt�se az el��ll�tott adatokkal:
	INSERT Car(PartnerID, PlateNumber, EngineNumber, ChassisNumber)
	SELECT R.PartnerID, R.PlateNumber, R.EngineNumber, R.ChassisNumber FROM @Result R

-- SELECT * FROM Car


/* Az els� forgalomba helyez�s id�pontj�nak meghat�roz�sa DATEFROMPARTS() f�ggv�nnyel r�szben a rendsz�m els� karakter�nek alapj�n az �vet,
r�szben v�letlensz�m gener�l�ssal a h�napot �s napot illet�en: */
UPDATE dbo.Car SET ActivationDate = DATEFROMPARTS(CASE
	WHEN LEFT(PlateNumber, 1) = 'A' THEN '1990'
	WHEN LEFT(PlateNumber, 1) = 'B' THEN '1991'
	WHEN LEFT(PlateNumber, 1) = 'C' THEN '1992'	--1993 ut�n lassult a rendsz�m kioszt�s, ez�rt musz�j tov�bbi megbont�st is bevetni a SUBSTRING() f�ggv�ny haszn�lat�val,
	WHEN LEFT(PlateNumber, 1) = 'D' THEN '1993'					--hogy minden �vben legyen �zembehelyezett aut� �s �gy minden �vben legyen k�telez� m�szaki vizsg�ztat�s is.
	WHEN LEFT(PlateNumber, 1) = 'E' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-H]' THEN '1994'
	WHEN LEFT(PlateNumber, 1) = 'E' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[I-P]' THEN '1995'
	WHEN LEFT(PlateNumber, 1) = 'E' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[R-Z]' THEN '1996'
	WHEN LEFT(PlateNumber, 1) = 'F' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-H]' THEN '1997'
	WHEN LEFT(PlateNumber, 1) = 'F' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[I-P]' THEN '1998'
	WHEN LEFT(PlateNumber, 1) = 'F' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[R-Z]' THEN '1999'
	WHEN LEFT(PlateNumber, 1) = 'G' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2000'
	WHEN LEFT(PlateNumber, 1) = 'G' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2001'
	WHEN LEFT(PlateNumber, 1) = 'H' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2002'
	WHEN LEFT(PlateNumber, 1) = 'H' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2003'
	WHEN LEFT(PlateNumber, 1) = 'I' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2004'
	WHEN LEFT(PlateNumber, 1) = 'I' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2005'
	WHEN LEFT(PlateNumber, 1) = 'J' THEN '2006'
	WHEN LEFT(PlateNumber, 1) = 'K' THEN '2007'
	WHEN LEFT(PlateNumber, 1) = 'L' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2008'
	WHEN LEFT(PlateNumber, 1) = 'L' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2009'
	WHEN LEFT(PlateNumber, 1) = 'M' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2010'
	WHEN LEFT(PlateNumber, 1) = 'M' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2011'
	WHEN LEFT(PlateNumber, 1) = 'N' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2012'
	WHEN LEFT(PlateNumber, 1) = 'N' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2013'
	WHEN LEFT(PlateNumber, 1) = 'O' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2014'
	WHEN LEFT(PlateNumber, 1) = 'O' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2015'
	WHEN LEFT(PlateNumber, 1) = 'P' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2016'
	WHEN LEFT(PlateNumber, 1) = 'P' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2017'
	WHEN LEFT(PlateNumber, 1) = 'Q' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[A-M]' THEN '2018'
	WHEN LEFT(PlateNumber, 1) = 'Q' AND SUBSTRING(PlateNumber, 2, 1) LIKE '[N-Z]' THEN '2019'
	ELSE '2020' END, ABS(CHECKSUM(NEWID()))%12 + 1, ABS(CHECKSUM(NEWID()))%28 + 1)		--Az�rt csak 28 naposak a h�napok, hogy ne legyen febru�r 30-a vagy j�nius 31-e.
	/* 2021-es forgalomba helyez�s az�rt nincs, mert a h�nap �s nap v�letlensz�m gener�tor sok d�tumot helyezne el a mai nap (2021 augusztus 11) ut�nra is, amelyek j�v�beli
	id�pontok lenn�nek �s ilyeneket nem engedhetek meg �s emiatt is van a Car t�bl�n a CK_Car_ActivationDate nev� ellen�rz� megszor�t�s. */









/*************************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************************
ITT MEG AZ�RT KELL MEG�LLNI, HOGY HIBA N�LK�L J�JJ�N L�TRE A CAR T�BLA �S CSAK AZUT�N KEZDJ�K EL KI�P�TENI AZ IDEGEN KULCS MEGSZOR�T�SOKAT.
HIB�T PEDIG AZ OKOZHAT, HOGY SAJNOS A V�LETLENSZ�M GENER�TOR SIM�N LEGY�RTJA UGYANAZT A RENDSZ�MOT K�TSZER!!!
***************************************************************************************************************************************************************************************
**************************************************************************************************************************************************************************************/





-- A k�vetkez� m�szaki vizsga d�tum�nak meghat�roz�sa skal�r f�ggv�nnyel:
GO
CREATE OR ALTER FUNCTION dbo.NextTechnicalExam(@ActivationDate date) RETURNS date AS
BEGIN
	DECLARE @NextTechnicalExam date, @counter tinyint = 1
	IF DATEADD(YEAR, 4, @ActivationDate) > SYSDATETIME()
		RETURN DATEADD(YEAR, 4, @ActivationDate)
	ELSE
		BEGIN
		WHILE @ActivationDate < SYSDATETIME()
		   BEGIN
				SET @ActivationDate = DATEADD(YEAR, 2, @ActivationDate)
				SET @counter = @counter + 1
		   END;
		
		END
		RETURN @ActivationDate
END
GO


-- A motorsz�mok megfelel� hossz�s�g�t ellen�rz� skal�r f�ggv�ny:
GO
CREATE OR ALTER FUNCTION dbo.EngineNumberCheck 
	(@Engine char(15))
RETURNS bit
AS
	BEGIN
		IF @Engine IS NULL
			RETURN NULL
		ELSE IF LEN(@Engine) = 15 AND SUBSTRING(@Engine, 4, 1) = ' ' AND SUBSTRING(@Engine, 9, 1) = ' '
			RETURN 1
	RETURN 0	-- A skal�r f�ggv�ny ragaszkodik ahhoz, hogy az utols� END el�tt legyen egy RETURN 0
	END
GO

	ALTER TABLE dbo.Car ADD CONSTRAINT CK_Car_EngineNumber CHECK (dbo.EngineNumberCheck(EngineNumber) = 1)
--	ALTER TABLE dbo.Car DROP CONSTRAINT IF EXISTS CK_Car_EngineNumber

-- Az alv�zsz�mok megfelel� hossz�s�g�t ellen�rz� skal�r f�ggv�ny:
GO
CREATE OR ALTER FUNCTION dbo.ChassisNumberCheck 
	(@Chassis char(9))
RETURNS bit
AS
	BEGIN
		IF @Chassis IS NULL
			RETURN NULL
		ELSE IF LEN(@Chassis) = 9
			RETURN 1
	RETURN 0	-- A skal�r f�ggv�ny ragaszkodik ahhoz, hogy az utols� END el�tt legyen egy RETURN 0
	END
GO

	ALTER TABLE dbo.Car ADD CONSTRAINT CK_Car_ChassisNumber CHECK (dbo.ChassisNumberCheck(ChassisNumber) = 1)
--	ALTER TABLE dbo.Car DROP CONSTRAINT IF EXISTS CK_Car_ChassisNumber


DROP TABLE IF EXISTS dbo.ServiceEvent
CREATE TABLE dbo.ServiceEvent (
	ServiceEventID			int				NOT NULL IDENTITY	
	,PlateNumber			varchar(10)		NOT NULL
	,ServiceDate			smalldatetime	NOT NULL
	,Milage					int				NOT NULL			-- Kilom�ter �ra �ll�s.
	,ServiceSubCategoryID	smallint		NOT NULL
	CONSTRAINT PK_ServiceEvent_ServiceEventID PRIMARY KEY (ServiceEventID))
	ALTER TABLE dbo.ServiceEvent ADD CONSTRAINT CK_ServiceEvent_Milage CHECK (Milage > 0)
	ALTER TABLE dbo.ServiceEvent ADD CONSTRAINT FK_ServiceEvent_Car_PlateNumber FOREIGN KEY (PlateNumber) REFERENCES dbo.Car (PlateNumber)
	ALTER TABLE dbo.ServiceEvent ADD CONSTRAINT DF_ServiceEvent_ServiceDate DEFAULT SYSDATETIME() FOR ServiceDate
	-- Ez direkt van itt:
	ALTER TABLE dbo.InvoiceDetail ADD CONSTRAINT FK_InvoiceDetail_ServiceEvent_ServiceEventID FOREIGN KEY (ServiceEventID) REFERENCES dbo.ServiceEvent (ServiceEventID)

DROP TABLE IF EXISTS dbo.ServiceCategory
CREATE TABLE dbo.ServiceCategory (
	ServiceCategoryID				smallint		NOT NULL
	,ServiceCategoryDescription		varchar(40)		NOT NULL
	CONSTRAINT PK_ServiceCategory_ServiceCategoryID PRIMARY KEY (ServiceCategoryID))
	ALTER TABLE dbo.ServiceCategory ADD CONSTRAINT AK_ServiceCategory_ServiceCategoryDescription UNIQUE (ServiceCategoryDescription)

	DECLARE @ImportFileServiceCategory varchar(200), @SC varchar(max)
	SELECT @ImportFileServiceCategory = GlobalValue FROM Global WHERE GlobalName = 'ServiceCategory'
SET @SC = '
	BULK INSERT dbo.ServiceCategory 
		FROM ''' + @ImportFileServiceCategory + '''
		WITH(CODEPAGE = ''65001'', FIELDTERMINATOR = ''\t'', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'													-- Codepage 65001 = UTF-8
EXEC (@SC)
-- SELECT @SC

/* Alapvet�en a GLOBAL t�bla alapj�n t�lt�m fel adatokkal a t�bl�kat, de ezt az INSERT ... VALUES m�dszert is beletettem, mert ide tudtam kommenteket elhelyezni az egyes angol
megnevez�sek mell�:
	INSERT ServiceCategory (ServiceCategoryDescription)
	VALUES  ('Bodywork repair') /*Karossz�ria szerel�s*/, ('Break repair') /*F�kszerel�s*/, ('Electrical repair') /*Elektromoss�gi szerel�s*/, ('Engine repair') /*Motorszerel�s*/,
			('Exhaust repair') /*Kipufog� szerel�s*/, ('Interior repair') /*Bels� t�r szerel�s*/, ('Landing gear and steering repair') /*Fut�m� �s korm�nyszerkezet szerel�s*/,
			('Painting') /*F�nyez�s*/, ('Transmission and gearbox repair') /*Er��tvitel �s v�lt� szerel�s*/ */

-- SELECT * FROM ServiceCategory

DROP TABLE IF EXISTS dbo.ServiceSubCategory
CREATE TABLE dbo.ServiceSubCategory (
	ServiceSubCategoryID				smallint		NOT NULL IDENTITY
	,ServiceCategoryID					smallint		NOT NULL
	,ServiceSubCategoryDescription		varchar(100)	NOT NULL
	,ServiceType						char(1)			NULL
	,TechnicalExam						char(1)			NULL
	,Fuel								varchar(10)		NOT NULL

/* Nem akartam nagy m�rt�kben meghaladni a metrik�ban meghat�rozott 9db t�bla sz�mot, ez�rt nem hoztam l�tre egy olyan seg�d t�bl�t, ami alapj�n meghat�rozhat� lenne, hogy melyik motorsz�m
a benzines �s melyik a d�zel, pedig ez fontos, mert d�zeln�l nem lehet gy�jt�gyerty�t cser�lni, mivel nincs benne ilyen, ugyan�gy a benzin motorokban pedig nincs un. AdBlue folyad�k.
Ezt az inform�ci�t a ServiceSubCategory t�bla Fuel (�zemanyag) oszlop�val jelzem. Azok lesznek a d�zel motorok, amelyekn�l a motorsz�m els� 3 karaktere K9K lesz. */

	,TimeRequirement					time(0)			NOT NULL
	,JobTitleID							tinyint			NOT NULL
	,MaterialPrice						int				NULL
	CONSTRAINT PK_ServiceSubCategory_ServiceSubCategoryID PRIMARY KEY (ServiceSubCategoryID))
	ALTER TABLE dbo.ServiceSubCategory ADD CONSTRAINT AK_ServiceSubCategory_ServiceSubCategoryDescription UNIQUE (ServiceSubCategoryDescription)
	ALTER TABLE dbo.ServiceSubCategory ADD CONSTRAINT FK_ServiceSubCategory_ServiceCategory_ServiceCategoryID FOREIGN KEY
	(ServiceCategoryID) REFERENCES dbo.ServiceCategory (ServiceCategoryID)
	ALTER TABLE dbo.ServiceSubCategory ADD CONSTRAINT FK_ServiceSubCategory_JobTitleID_JobTitleID FOREIGN KEY (JobTitleID) REFERENCES dbo.JobTitle (JobTitleID)
-- Ez direkt van itt:
	ALTER TABLE dbo.ServiceEvent ADD CONSTRAINT FK_ServiceEvent_ServiceSubCategory_ServiceSubCategoryID FOREIGN KEY (ServiceSubCategoryID)
		REFERENCES dbo.ServiceSubCategory (ServiceSubCategoryID)


	DECLARE @ImportFileServiceSubCategory varchar(200), @SSC varchar(max)
	SELECT @ImportFileServiceSubCategory = GlobalValue FROM Global WHERE GlobalName = 'ServiceSubCategory'
SET @SSC = '
	BULK INSERT dbo.ServiceSubCategory 
		FROM ''' + @ImportFileServiceSubCategory + '''
		WITH(CODEPAGE = ''1250'', FIELDTERMINATOR = ''\t'', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'															-- Codepage 1250 = ANSI
EXEC (@SSC)

	ALTER TABLE dbo.ServiceSubCategory ADD LabourPrice AS DATEDIFF(MINUTE, '0:00:00', TimeRequirement) * 20000 / 60

-- SELECT @SSC
-- SELECT * FROM ServiceSubCategory


DROP TABLE IF EXISTS dbo.RuleTable
CREATE TABLE dbo.RuleTable (
	RuleID						tinyint		NOT NULL IDENTITY
	,ServiceSubCategoryID		smallint	NOT NULL
	,KM30k						bit			NULL
	,KM60k						bit			NULL
	,KM90k						bit			NULL
	,KM120k						bit			NULL
	,KM150k						bit			NULL
	,KM180k						bit			NULL
	,KM210k						bit			NULL
	,KM240k						bit			NULL
	,KM270k						bit			NULL
	,KM300k						bit			NULL
	CONSTRAINT PK_RuleTable_RuleID PRIMARY KEY (RuleID))
	ALTER TABLE dbo.RuleTable ADD CONSTRAINT FK_RuleTable_ServiceSubCategory_ServiceSubCategoryID FOREIGN KEY (ServiceSubCategoryID) REFERENCES dbo.ServiceSubCategory (ServiceSubCategoryID)


	DECLARE @ImportFileRuleTable varchar(200), @RT varchar(max)
	SELECT @ImportFileRuleTable = GlobalValue FROM Global WHERE GlobalName = 'RuleTable'
SET @RT = '
	BULK INSERT dbo.RuleTable 
		FROM ''' + @ImportFileRuleTable + '''
		WITH(CODEPAGE = ''1250'', FIELDTERMINATOR = ''\t'', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'
EXEC (@RT)
-- SELECT * FROM RuleTable


DROP FUNCTION IF EXISTS MilageBasedServiceItems
GO
CREATE OR ALTER FUNCTION dbo.MilageBasedServiceItems (@Milage varchar(6)) RETURNS varchar(6)		--�letkort�l f�ggetlen�l a fut�steljes�tm�nyen alapul� szerv�z sz�ks�glet meghat�roz�sa
	BEGIN
		DECLARE @KM varchar(6)
		IF @Milage < 30000 SET @KM = 'A' ELSE
		SET @KM =
		CASE WHEN @Milage % 300000 >= 30000 AND @Milage % 300000 < 60000 THEN 'KM30k'
			 WHEN @Milage % 300000 >= 60000 AND @Milage % 300000 < 90000 THEN 'KM60k'
			 WHEN @Milage % 300000 >= 90000 AND @Milage % 300000 < 120000 THEN 'KM90k'
			 WHEN @Milage % 300000 >= 120000 AND @Milage % 300000 < 150000 THEN 'KM120k'
 			 WHEN @Milage % 300000 >= 150000 AND @Milage % 300000 < 180000 THEN 'KM150k'
 			 WHEN @Milage % 300000 >= 180000 AND @Milage % 300000 < 210000 THEN 'KM180k'
 			 WHEN @Milage % 300000 >= 210000 AND @Milage % 300000 < 240000 THEN 'KM210k'
 			 WHEN @Milage % 300000 >= 240000 AND @Milage % 300000 < 270000 THEN 'KM240k'
 			 WHEN @Milage % 300000 >= 270000 AND @Milage % 300000 < 300000 THEN 'KM270k'
 			 WHEN @Milage % 300000 < 30000 THEN 'KM300k'
		END
		RETURN @KM
	END
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation300k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM300k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation300kDiesel
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM300k = 1 AND SSC.ServiceSubCategoryID != '10'
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation300k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM300k = 1
GO


GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation270k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM270k = 1
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation270k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM270k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation240k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM240k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation240kDiesel
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM240k = 1 AND SSC.ServiceSubCategoryID != '10'
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation240k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM240k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation210k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM210k = 1
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation210k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM210k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation180k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM180k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation180kDiesel
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM180k = 1 AND SSC.ServiceSubCategoryID != '10'
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation180k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM180k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation150k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM150k = 1
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation150k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM150k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation120k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM120k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation120kDiesel
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM120k = 1 AND SSC.ServiceSubCategoryID != '10'
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation120k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM120k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation90k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM90k = 1
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation90k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM90k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation60k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM60k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation60kDiesel
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM60k = 1 AND SSC.ServiceSubCategoryID != '10'
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation60k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM60k = 1
GO

GO
CREATE OR ALTER VIEW DetailsOfTimeAndCostEstimation30k
AS
SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM30k = 1
GO

GO
CREATE OR ALTER VIEW TimeAndCostEstimation30k
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM RuleTable R
LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
WHERE KM30k = 1
GO



DROP PROC IF EXISTS SelectService
GO
	CREATE OR ALTER PROC SelectService (@PlateNumber varchar(7))
	AS
		DECLARE @CarAge tinyint, @ServiceType char(1), @Fuel varchar(10)
		SET @CarAge = (DATEDIFF(YEAR, (SELECT ActivationDate FROM Car WHERE PlateNumber = @PlateNumber), SYSDATETIME()))
		SET @Fuel = (SELECT LEFT(EngineNumber,3) FROM Car WHERE PlateNumber = @PlateNumber)
	IF @Fuel = 'K9K' SET @Fuel = 'Diesel' ELSE SET @Fuel = 'Petrol'

	IF @CarAge % 6 = 0																											--A csak 6 �vente esed�kes jav�t�sok miatt kell
		BEGIN
					SET @ServiceType ='B'
					SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
					FROM ServiceSubCategory SSC
					LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
					WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '6'
				INTERSECT
					SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
					FROM ServiceSubCategory SSC
					LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
					WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
	
	ELSE IF @CarAge % 5 = 0																											--A csak 5 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='A'
				SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '5'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
	ELSE IF @CarAge % 4 = 0																											--A csak 4 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='B'
				SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '4'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
	ELSE IF @CarAge % 3 = 0																											--A csak 3 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='A'
				SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '3'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
	ELSE IF @CarAge % 2 = 0																											--A csak 2 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='B'
				SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
	ELSE IF @CarAge % 2 != 0
		BEGIN
				SET @ServiceType ='A'
				SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both'
		END
--SELECT @PlateNumber "Plate number", @CarAge "Car age", @Fuel "Fuel type", @ServiceType "Service type (year)"
GO


/* Tesztel�shez:
EXEC SelectService 'SAK-017' 1 �ves
EXEC SelectService 'SCU-028' 1 �ves d�zel
EXEC SelectService 'QXV-626' 2 �ves
EXEC SelectService 'QYB-583' 2 �ves d�zel
EXEC SelectService 'QEM-040' 3 �ves
EXEC SelectService 'QFU-074' 3 �ves d�zel
EXEC SelectService 'PZL-261' 4 �ves
EXEC SelectService 'PUS-930' 4 �ves d�zel
EXEC SelectService 'PMP-024' 5 �ves
EXEC SelectService 'PKX-780' 5 �ves d�zel
EXEC SelectService 'OVB-688' 6 �ves
EXEC SelectService 'OTJ-373' 6 �ves d�zel
EXEC SelectService 'OAR-853' 7 �ves
EXEC SelectService 'OEP-291' 7 �ves d�zel*/

--Az �gyf�l �s az aut� beazonos�t�sa TVF f�ggv�nnyel a rendsz�m alapj�n. Egy�ttal elk�rem a kilom�ter �ra �ll�s�t is, mert a tov�bbiakhoz az is kelleni fog:
		GO
			CREATE OR ALTER FUNCTION dbo.SelectPartnerAndCar (@Plate varchar(10))
				RETURNS TABLE AS RETURN
			SELECT P.PartnerName, P.PartnerAddress, C.PlateNumber				-- Ha itt bel�l lehetne v�ltoz�kat deklar�lni, akkor ki tudn�m �ratni az aut� �letkor�t �s az
			FROM Car C																																--  �zemanyag t�pus�t is.
			INNER JOIN Partner P ON C.PartnerID = P.PartnerID
			WHERE C.PlateNumber = @Plate
		GO

		DROP TABLE IF EXISTS #SelectedService
CREATE TABLE #SelectedService (
	ServiceSubCategoryID			smallint		NOT NULL
	,ServiceSubCategoryDescription	varchar(100)	NOT NULL
	,TimeRequirement				time(0)			NOT NULL
	,MaterialPrice					int				NULL
	,LabourPrice					int				NOT NULL)


CREATE TABLE #SelectedService3 (
	ServiceSubCategoryID			smallint		NOT NULL
	,ServiceSubCategoryDescription	varchar(100)	NOT NULL
	,TimeRequirement				time(0)			NOT NULL
	,MaterialPrice					int				NULL
	,LabourPrice					int				NOT NULL)


/* �s akkor itt van az els� attrakci�: �gyf�l hozza az aut�j�t, megadja a rendsz�m�t �s a kil�m�ter�ra �ll�s�t �s ezek alapj�n az SQL server megadja, hogy milyen szerv�z m�veletek
esed�kesek, v�rhat�an mennyi ideig fog tartani a szervizel�s �s mennyibe fog f�jni. */
SELECT * FROM SelectPartnerAndCar('OEP-291')		--TVF
SELECT dbo.MilageBasedServiceItems('621378')

INSERT #SelectedService
EXEC SelectService 'OEP-291'	-- Ebben van az A vagy B szerv�z

SELECT * FROM #SelectedService


-- SELECT SSC.ServiceSubCategoryDescription, R.* FROM RuleTable R INNER JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
SELECT * FROM DetailsOfTimeAndCostEstimation30k
SELECT * FROM TimeAndCostEstimation30k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation30k
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation60k
SELECT * FROM DetailsOfTimeAndCostEstimation60kDiesel
SELECT * FROM TimeAndCostEstimation60k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation60k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation60kDiesel
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation90k
SELECT * FROM TimeAndCostEstimation90k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation90k
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation120k
SELECT * FROM DetailsOfTimeAndCostEstimation120kDiesel
SELECT * FROM TimeAndCostEstimation120k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation120k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation120kDiesel
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation150k
SELECT * FROM TimeAndCostEstimation150k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation150k
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation180k
SELECT * FROM TimeAndCostEstimation180k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation180k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation180kDiesel
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation210k
SELECT * FROM TimeAndCostEstimation210k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation210k
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation240k
SELECT * FROM TimeAndCostEstimation240k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation240k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation240kDiesel
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation270k
SELECT * FROM TimeAndCostEstimation270k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation270k
SELECT * FROM #SelectedService2

SELECT * FROM DetailsOfTimeAndCostEstimation300k
SELECT * FROM TimeAndCostEstimation300k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation300k
SELECT * INTO #SelectedService2 FROM DetailsOfTimeAndCostEstimation300kDiesel
SELECT * FROM #SelectedService2

INSERT #SelectedService3			-- SELECT * FROM #SelectedService3
SELECT * FROM #SelectedService
UNION
SELECT * FROM #SelectedService2

		SELECT * FROM #SelectedService3
ALTER TABLE #SelectedService3 ADD PlateNumber varchar(10) NULL, Milage int NULL
		GO
			CREATE OR ALTER PROC UpdatePlateNumberAndMilage
				@PlateNumber	varchar(10),
				@Milage			int
			AS
			IF @PlateNumber IS NULL OR @Milage IS NULL
				RETURN 1
			ELSE IF @Milage < 0 OR @Milage > 1000000
				RETURN 2
			ELSE
		UPDATE #SelectedService3 SET PlateNumber = @PlateNumber, Milage = @Milage
		GO
EXEC UpdatePlateNumberAndMilage 'OEP-291', '621378'
 
 INSERT ServiceEvent (PlateNumber, Milage, ServiceSubCategoryID)
 SELECT PlateNumber, Milage, ServiceSubCategoryID
 FROM #SelectedService3

 SELECT * FROM ServiceEvent

DROP TABLE #SelectedService
DROP TABLE #SelectedService2
DROP TABLE #SelectedService3


-- M�sodik attrakci�: kilist�zza azokat az �gyfeleket, akiknek az �ltalam megadott id�szakban fog lej�rni a forgalmi enged�ly�k.

GO
CREATE OR ALTER FUNCTION TechnicalExamNeeded (@FromDate date, @ToDate date)
RETURNS TABLE AS RETURN	
SELECT P.PartnerName, CONCAT('+36-',P.PhoneNumberPrefix, '/', P.PhoneNumber) "Phone number", P.PartnerAddress, PlateNumber, dbo.NextTechnicalExam(C.ActivationDate) NextTechnicalExam
FROM Car C
INNER JOIN Partner P ON C.PartnerID = P.PartnerID
WHERE dbo.NextTechnicalExam(C.ActivationDate) BETWEEN @FromDate AND @ToDate
GO
SELECT * FROM TechnicalExamNeeded('20211004', '20211018')

GO
CREATE OR ALTER VIEW TechnicalExamDetailes
AS
SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
FROM ServiceSubCategory SSC
LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
WHERE SSC.TechnicalExam = 'D'
GO

CREATE OR ALTER VIEW TimeAndCostEstimationTechnicalExam
AS
SELECT RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) / 60) AS VARCHAR(2)),2) + ':' + 
            RIGHT('00' + CAST((SUM(DATEDIFF(MINUTE, '0:00:00', TimeRequirement)) % 60) AS VARCHAR(2)), 2) "TimeRequirement ( hours : minutes )",
			sum(MaterialPrice) MaterialPrice, sum(LabourPrice) LabourPrice
FROM ServiceSubCategory SSC
LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
WHERE SSC.TechnicalExam = 'D'
GO
SELECT * FROM TechnicalExamDetailes
SELECT * FROM TimeAndCostEstimationTechnicalExam



/*         ADMIN SZEKCI� J�N        */




GO					  -- Ebbe a s�m�ba fognak ker�lni a p�nz�gyi vezet�nek sz�nt n�zetek �s t�rolt elj�r�sok, �gy nem kell k�l�n-k�l�n hozz�f�r�st adni az objektumokhoz,
CREATE SCHEMA pbi AUTHORIZATION dbo														--hanem el�g csak a s�m�ra egy jogot adni. M�s objektumhoz nem lesz hozz�f�r�se.
GO
CREATE USER HRManager FOR LOGIN HRManager																													--  2.munkak�r
GRANT CONTROL ON dbo.Employee TO HRManager								-- A Database Administrator-on k�v�l csak a szem�lyzeti vezet� f�rhet hozz� az Employee t�bl�hoz

CREATE USER FinancialController FOR LOGIN FinancialController																								--  3.munkak�r
ALTER USER FinancialController WITH DEFAULT_SCHEMA=pbi

CREATE USER FinancialAssistant FOR LOGIN FinancialAssistant																									--  4.munkak�r
CREATE USER ChiefExecutiveOfficer FOR LOGIN ChiefExecutiveOfficer																							--  1.munkak�r
ALTER ROLE CEO ADD MEMBER ChiefExecutiveOfficer
ALTER ROLE db_datareader ADD MEMBER ChiefExecutiveOfficer
CREATE USER ServiceMan FOR LOGIN ServiceMan																											-- fizikai dolgoz�k vezet�je


CREATE ROLE Financial
CREATE ROLE HR
CREATE ROLE CEO
CREATE ROLE SERVICEMAN
GRANT DELETE ON SCHEMA::pbi TO Financial
GRANT EXECUTE ON SCHEMA::pbi TO Financial
GRANT INSERT ON SCHEMA::pbi TO Financial
GRANT SELECT ON SCHEMA::pbi TO Financial
GRANT UPDATE ON SCHEMA::pbi TO Financial
DENY CONTROL ON dbo.Employee TO Financial
ALTER ROLE Financial ADD MEMBER FinancialAssistant
ALTER ROLE db_datawriter ADD MEMBER FinancialAssistant
ALTER ROLE Financial ADD MEMBER FinancialController
ALTER ROLE db_datareader ADD MEMBER FinancialController
CREATE USER DatabaseAdministrator FOR LOGIN DatabaseAdministrator																							-- 15.munkak�r
ALTER ROLE db_owner ADD MEMBER DatabaseAdministrator
ALTER ROLE HR ADD MEMBER HRManager

-- Ellen�rz�shez:
--EXECUTE AS USER = 'FinancialAssistant'
--SELECT * FROM Employee
--DELETE Employee

GO
BACKUP DATABASE [Autoszerviz] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Autoszerviz.bak' WITH NOFORMAT, NOINIT, 
NAME = N'Autoszerviz-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'AutoszervizDailyFullBackup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DELL-3010\Reket', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'AutoszervizDailyFullBackup', @server_name = N'DELL-3010'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'AutoszervizDailyFullBackup', @step_name=N'AutoszervizDailyFullBackup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [Autoszerviz] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Autoszerviz.bak'' WITH NOFORMAT, NOINIT, 
NAME = N''Autoszerviz-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'AutoszervizDailyFullBackup', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DELL-3010\Reket', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'AutoszervizDailyFullBackup', @name=N'AutoszervizDailyFullBackupAt3AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210818, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO



/* Ez a t�rolt elj�r�s lett volna a vizsgaremek lelke. Param�terk�nt az aut� rendsz�m�t �s a kilom�ter �ra �ll�s�t kellett volna megadni. Ezek alapj�n meghat�rozta volna az aut� �letkor�t,
�zemm�dj�t teh�t, hogy benzines vagy d�zel �s testre szabja, hogy az adott aut�hoz milyen szerv�z m�veletek esed�kesek, majd meghat�rozza a szerel�s v�rhat� id�tartam�t �s k�lts�geit.
Viszont a fut�steljes�tm�nyt�l f�gg� szerv�z sz�ks�glet m�r nem m�k�d�tt, amikor egybegy�rtam a t�bbivel (k�l�n m�k�d�tt, csak egyben nem! Nem kapta fel a v�ltoz� �rt�k�t. �t kellett
volna alak�tani dinamikus SQL-l�, ami viszont meghaladta a jelenlegi ismereteimet, illetve t�bb id�t rabolt volna el, mint amivel rendelkeztem. Emiatt sz�t kellett bontanom a 
r�szegys�gekre: */

/*
DROP PROC IF EXISTS SelectService
GO
	CREATE OR ALTER PROC SelectService (
		@PlateNumber varchar(7),
		@Milage int )
	AS
		DECLARE @CarAge tinyint, @ServiceType char(1), @KM varchar(6), @Fuel varchar(10), @R6 varchar(max)
		SET @CarAge = (DATEDIFF(YEAR, (SELECT ActivationDate FROM Car WHERE PlateNumber = @PlateNumber), SYSDATETIME()))
		SET @Fuel = (SELECT LEFT(EngineNumber,3) FROM Car WHERE PlateNumber = @PlateNumber)
	IF @Fuel = 'K9K' SET @Fuel = 'Diesel' ELSE SET @Fuel = 'Petrol'
	IF @Milage < 30000 SET @ServiceType = 'A' ELSE										--�letkort�l f�ggetlen�l a fut�steljes�tm�nyen alapul� szerv�z sz�ks�glet meghat�roz�sa
		SET @KM =
		CASE WHEN @Milage % 300000 >= 30000 AND @Milage % 300000 < 60000 THEN 'KM30k'
			 WHEN @Milage % 300000 >= 60000 AND @Milage % 300000 < 90000 THEN 'KM60k'
			 WHEN @Milage % 300000 >= 90000 AND @Milage % 300000 < 120000 THEN 'KM90k'
			 WHEN @Milage % 300000 >= 120000 AND @Milage % 300000 < 150000 THEN 'KM120k'
 			 WHEN @Milage % 300000 >= 150000 AND @Milage % 300000 < 180000 THEN 'KM150k'
 			 WHEN @Milage % 300000 >= 180000 AND @Milage % 300000 < 210000 THEN 'KM180k'
 			 WHEN @Milage % 300000 >= 210000 AND @Milage % 300000 < 240000 THEN 'KM210k'
 			 WHEN @Milage % 300000 >= 240000 AND @Milage % 300000 < 270000 THEN 'KM240k'
 			 WHEN @Milage % 300000 >= 270000 AND @Milage % 300000 < 300000 THEN 'KM270k'
 			 WHEN @Milage % 300000 < 30000 THEN 'KM300k'
		END
	IF @CarAge % 6 = 0																											--A csak 6 �vente esed�kes jav�t�sok miatt kell
		BEGIN
					SET @ServiceType ='B'
					(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
					FROM ServiceSubCategory SSC
					LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
					WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '6'
				INTERSECT
					SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
					FROM ServiceSubCategory SSC
					LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
					WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
			UNION ALL
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM RuleTable R
				LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
				WHERE @KM = '1'
		END
	
	ELSE IF @CarAge % 5 = 0																											--A csak 5 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='A'
				(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '5'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
		UNION
			SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
			FROM RuleTable R
			LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
			WHERE @KM = '1'
		END
	ELSE IF @CarAge % 4 = 0																											--A csak 4 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='B'
				(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '4'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
		UNION
			SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
			FROM RuleTable R
			LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
			WHERE @KM = '1'
		END
	ELSE IF @CarAge % 3 = 0																											--A csak 3 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='A'
				(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C' OR SSC.ServiceType LIKE '3'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
		UNION
			SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
			FROM RuleTable R
			LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
			WHERE @KM = '1'
		END
	ELSE IF @CarAge % 2 = 0																											--A csak 2 �vente esed�kes jav�t�sok miatt kell
		BEGIN
				SET @ServiceType ='B'
				(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
		UNION
			SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
			FROM RuleTable R
			LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
			WHERE @KM = '1'
		END
	ELSE IF @CarAge % 2 != 0
		BEGIN
				SET @ServiceType ='A'
				(SELECT SSC.ServiceSubCategoryID, ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.ServiceType = @ServiceType OR SSC.ServiceType LIKE 'C'
			INTERSECT
				SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
				FROM ServiceSubCategory SSC
				LEFT JOIN RuleTable R ON SSC.ServiceSubCategoryID = R.ServiceSubCategoryID
				WHERE SSC.Fuel = @Fuel OR SSC.Fuel LIKE 'Both')
		UNION
			SELECT SSC.ServiceSubCategoryID, SSC.ServiceSubCategoryDescription, SSC.TimeRequirement, SSC.MaterialPrice, SSC.LabourPrice
			FROM RuleTable R
			LEFT JOIN ServiceSubCategory SSC ON R.ServiceSubCategoryID = SSC.ServiceSubCategoryID
			WHERE @KM = '1'
		END
SELECT @PlateNumber "Plate number", @Milage Milage, @CarAge "Car age", @Fuel "Fuel type", @ServiceType "Service type (year)", @KM "Service type (km)"
GO
*/