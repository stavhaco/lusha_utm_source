
-- Create calendar table with recursive CTE
DROP TABLE IF EXISTS [calendar];
DECLARE @startDate  date = '20211001';
DECLARE @endDate date = '20211203'; 
DECLARE @diff int = DATEDIFF(DAY, @startDate, @endDate);
WITH get_calendar(n, date) 
AS (
    SELECT 
        0, 
        DATEADD(DAY, 0, @StartDate)
    UNION ALL
    SELECT    
        n + 1, 
        DATEADD(DAY, n+1, @StartDate)
    FROM    
        get_calendar
    WHERE n < @diff
)
SELECT 
    date
INTO calendar
FROM 
    get_calendar
ORDER BY date
OPTION (MAXRECURSION 0);

-- CREATE INPUT TABLES
DROP TABLE IF EXISTS [user_utm];
CREATE TABLE user_utm (
    utm_date datetime,
    userId int,
    utmSource varchar(100)
);

DROP TABLE IF EXISTS [users];
CREATE TABLE users (
    userId int,
    registrationDate datetime,
);

DROP TABLE IF EXISTS [purchases];
CREATE TABLE purchases (
    purchaseDate datetime,
    userId int,
    billing decimal(12,6)
);

-- Generate dummy data 
INSERT INTO user_utm VALUES ('2021-10-01', 1, 'google')
						    ,('2021-10-02', 1, 'facebook')
						    ,('2021-10-03', 1, 'google')
						    ,('2021-10-04', 1, 'youtube')
						    ,('2021-10-01', 2, 'youtube')
						    ,('2021-10-06', 3, 'facebook')
						    ,('2021-10-05', 3, 'facebook')
						    ,('2021-10-05', 4, 'google')
						    ,('2021-10-06', 4, 'youtube')
						    ,('2021-10-07', 4, 'youtube')
						    ,('2021-10-08', 4, 'youtube')
						    ,('2021-10-09', 4, 'facebook')
						    ,('2021-10-10', 4, 'google')
						    ,('2021-10-11', 4, 'google')
						    ,('2021-10-11', 4, 'youtube')
						    ,('2021-10-05', 5, 'google')
						    ,('2021-10-06', 5, 'google')
						    ,('2021-10-07', 5, 'google');
						    
INSERT INTO users VALUES (1, '2021-10-02')
						 ,(2, '2021-10-01')
						 ,(3, '2021-10-05')
						 ,(4, '2021-10-05')
						 ,(5, '2021-10-05');

INSERT INTO purchases VALUES ('2021-10-02',1,100)
						     ,('2021-10-04',1,100)
						     ,('2021-10-10',2,100)
						     ,('2021-10-07',3,100)
						     ,('2021-10-07',4,200)
						     ,('2021-10-10',4,300)
						     ,('2021-10-11',4,120)
						     ,('2021-10-07',5,300)
						     ,('2021-10-11',5,410);

-- CREATE OUTPUT TABLE
DROP TABLE IF EXISTS [utm_source_performance];
CREATE TABLE utm_source_performance (
    CalendarDate datetime,
    utmSource varchar(100),
	number_of_registrations int,
	number_of_purchases int,
	total_billing decimal(12,6)
);