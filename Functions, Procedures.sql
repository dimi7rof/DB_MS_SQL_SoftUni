--01

CREATE PROC usp_GetEmployeesSalaryAbove35000
AS
BEGIN
SELECT FirstName, LastName
FROM Employees
WHERE Salary > 35000
END

--02

CREATE PROC usp_GetEmployeesSalaryAboveNumber (@num DECIMAL(18,4))
AS
SELECT FirstName, LastName
FROM Employees
WHERE Salary >= @num

--03

CREATE PROC usp_GetTownsStartingWith  (@INPUT VARCHAR(20))
AS
SELECT [Name]
FROM Towns
WHERE @INPUT = LEFT(Name, LEN(@INPUT))

--04

CREATE PROC usp_GetEmployeesFromTown  (@INPUT VARCHAR(20))
AS
SELECT FirstName, LastName
FROM Employees AS e
 JOIN Addresses AS a
 ON a.AddressID = e.AddressID
 JOIN Towns AS t
 ON t.TownID = a.TownID
 WHERE @INPUT = LEFT(t.Name, LEN(@INPUT))

--05

CREATE OR ALTER FUNCTION ufn_GetSalaryLevel(@salary DECIMAL(18,4)) 
RETURNS VARCHAR(10)
AS
BEGIN
DECLARE @SalaryLEVEL VARCHAR(10)
	IF (@salary < 30000) SET @SalaryLEVEL = 'Low'
	ELSE IF (@salary > 50000) SET @SalaryLEVEL = 'High'
	ELSE SET @SalaryLEVEL = 'Average'
RETURN @SalaryLEVEL
END
	--SELECT 	Salary,
	--dbo.ufn_GetSalaryLevel(SALARY) AS [Salary Level]
	--FROM Employees

--06

CREATE OR ALTER PROC usp_EmployeesBySalaryLevel (@salary VARCHAR(10)) 
AS
BEGIN
 SELECT 
 FirstName, LastName
 FROM Employees
WHERE dbo.ufn_GetSalaryLevel(Salary) = @salary
END

--07

CREATE OR ALTER FUNCTION ufn_IsWordComprised(@setOfLetters VARCHAR(20), @word VARCHAR(20)) 
RETURNS BIT
AS
BEGIN
   DECLARE @i INT = 1
   WHILE @i <= LEN(@word)
   BEGIN DECLARE @isWOrdCompromised BIT = 0
		 DECLARE @curWordLetter CHAR(1) = SUBSTRING(@word, @i, 1)
		 DECLARE @j INT = 1
		 WHILE @j <= LEN(@setOfLetters)
		 BEGIN DECLARE @curSetLetter CHAR(1) = SUBSTRING(@setOfLetters, @j, 1)
			   IF @curWordLetter = @curSetLetter
				   BEGIN
				   SET @isWOrdCompromised = 1
			       BREAK
			       END
			   SET @j += 1
			   END
	     IF @isWOrdCompromised = 0
	         BEGIN
	         RETURN 0
		     END
         SET @i += 1
         END
   RETURN 1
 END

--08

CREATE PROC usp_DeleteEmployeesFromDepartment (@departmentId INT)
AS
BEGIN
-- DELETE RELATIONS
   DELETE FROM EmployeesProjects
	     WHERE EmployeeID IN (
			SELECT EmployeeID
			  FROM Employees
			 WHERE DepartmentID = @departmentId )
  UPDATE Employees
	 SET ManagerID = NULL
   WHERE ManagerID IN (
			SELECT EmployeeID
			  FROM Employees
			 WHERE DepartmentID = @departmentId )
-- MAKE COLUMN NULLABLE
   ALTER TABLE Departments
  ALTER COLUMN ManagerID INT
  UPDATE Departments
	 SET ManagerID = NULL
   WHERE ManagerID IN (
			SELECT EmployeeID
			  FROM Employees
			 WHERE DepartmentID = @departmentId )
-- NO MORE RELATIONS
 DELETE FROM Employees
	   WHERE DepartmentID = @departmentId
 DELETE FROM Departments
	   WHERE DepartmentID = @departmentId
SELECT COUNT(EmployeeID)
  FROM Employees
 WHERE DepartmentID = @departmentId
END

--09

CREATE PROC usp_GetHoldersFullName 
AS
BEGIN
	SELECT 
		CONCAT(FirstName, ' ', LastName)
	FROM AccountHolders
END

--10

CREATE OR ALTER PROC usp_GetHoldersWithBalanceHigherThan @num DECIMAL(18,4)
AS
BEGIN
	SELECT FirstName, LastName
	  FROM AccountHolders AS ah
	  JOIN Accounts AS a
	    ON ah.Id = a.AccountHolderId
  GROUP BY FirstName, LastName, ah.Id
	HAVING SUM(Balance) > @num
  ORDER BY FirstName, LastName
END

--11

CREATE FUNCTION ufn_CalculateFutureValue (
				@sum DECIMAL(18,4)
			   ,@yearlyInterestRate FLOAT
			   ,@numberOfYears INT)
RETURNS DECIMAL(18,4)
AS
BEGIN
	RETURN (@sum * (POWER(1 + @yearlyInterestRate, @numberOfYears )))
END

--12

CREATE OR ALTER PROC usp_CalculateFutureValueForAccount 
			(@accID INT, @rate FLOAT)
AS
BEGIN
  SELECT a.Id AS [Account Id]
		,ah.FirstName AS [First Name]
		,ah.LastName AS [Last Name]
		,a.Balance AS [Current Balance]
		,dbo.ufn_CalculateFutureValue(a.Balance, @rate, 5)
			AS [Balance in 5 years]
	FROM AccountHolders AS ah
	JOIN Accounts AS a
	  ON a.AccountHolderId = ah.Id
   WHERE a.Id = @accID
END

--13

CREATE FUNCTION ufn_CashInUsersGames(@gameName NVARCHAR(50))
RETURNS TABLE
	AS RETURN(
		SELECT SUM(Cash) AS SumCash
		  FROM ( SELECT ug.Cash
					  , ROW_NUMBER() OVER(ORDER BY ug.Cash DESC) AS RowNumber
				   FROM UsersGames AS ug
			  LEFT JOIN Games AS g
					 ON g.Id = ug.GameId
				  WHERE g.Name = @gameName ) AS RowNumberSub
		 WHERE RowNumber % 2 <> 0)



