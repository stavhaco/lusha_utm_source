DECLARE @first_touch_billing_attribution_share  decimal = 0.5;
DECLARE @non_first_touch_billing_attribution_share  decimal = 1-@first_touch_billing_attribution_share;

--#### Registrations
WITH touch_rank AS (
	SELECT utm_date 
		   ,userId
		   ,utmSource
		   ,ROW_NUMBER() OVER (PARTITION BY userId ORDER BY utm_date ASC) AS rank
	FROM user_utm 
),
first_touch AS (
	SELECT t.userId
		   ,u.registrationDate
		   ,t.utmSource 
	FROM touch_rank t
	LEFT JOIN users u
	ON t.userId=u.userId
	WHERE rank=1
), 
registrations_per_date_source as (
	SELECT registrationDate
		   ,utmSource 
		   ,count(userId) AS number_of_registrations 
	FROM first_touch 
	GROUP BY registrationDate, utmSource
--#### Billing
), purchases_utm AS (
	SELECT p.userId
		   ,p.purchaseDate
		   ,t.utm_date
		   ,t.utmSource
		   ,p.billing
	FROM purchases p
	LEFT JOIN user_utm t
		ON p.userId=t.userId
	WHERE p.purchaseDate>=t.utm_date --ignore touches after purchase (in case of more than 1 purchase, or more visits after purchase with no purchase)
-- remove multiple touches from the same source
), purchases_utm_max_date_per_source AS (
	SELECT 
		utmSource
		,purchaseDate
		,userId
		,max(billing) as billing 
		,max(utm_date) as utm_date 
	FROM purchases_utm
	GROUP BY utmSource, purchaseDate, userId
)
, purchases_utm_rank AS (
	SELECT 
		*
		,ROW_NUMBER() OVER (PARTITION BY userId, purchaseDate ORDER BY utm_date DESC) AS rank
	FROM purchases_utm_max_date_per_source
), purchase_utm_count AS (
	SELECT 
		*
		,MAX(rank) over (partition by purchaseDate, userId) as cnt 
	FROM purchases_utm_rank
), purchase_utm_attribution AS (
	SELECT *
	,CASE 
		WHEN rank=1 and cnt>1 then @first_touch_billing_attribution_share * billing
		WHEN rank=1 and cnt=1 then billing
		ELSE (1.000/(cnt-1)) * @non_first_touch_billing_attribution_share * billing
	END AS attribution
	,CASE 
		WHEN rank=1 then 1
		ELSE 0
	END AS purchase_count
	FROM purchase_utm_count
), purchases_utm_per_date_source AS (
	SELECT 
		purchaseDate
		,utmSource 
		,sum(attribution) attribution
		,sum(purchase_count) purchase_count
	FROM purchase_utm_attribution
	GROUP BY purchaseDate, utmSource
), temp_utm_source_performance AS (
SELECT 
	c.date as CalendarDate
	,u.utmSource
	,r.number_of_registrations as number_of_registrations
	,p.purchase_count as number_of_purchases
	,p.attribution as total_billing
FROM calendar c -- build on top of full calendar table to prevent date holes in the final table
CROSS JOIN (SELECT distinct utmSource FROM user_utm) u
LEFT JOIN registrations_per_date_source r
	ON c.date=r.registrationDate and u.utmSource=r.utmSource
LEFT JOIN purchases_utm_per_date_source p
	ON c.date=p.purchaseDate and u.utmSource=p.utmSource
)
MERGE utm_source_performance AS TARGET
USING temp_utm_source_performance AS SOURCE 
ON (TARGET.CalendarDate = SOURCE.CalendarDate AND TARGET.utmSource = SOURCE.utmSource) 
WHEN MATCHED  
THEN UPDATE SET TARGET.CalendarDate = SOURCE.CalendarDate, 
				TARGET.utmSource = SOURCE.utmSource, 
				TARGET.number_of_registrations = SOURCE.number_of_registrations, 
				TARGET.number_of_purchases = SOURCE.number_of_purchases, 
				TARGET.total_billing = SOURCE.total_billing
WHEN NOT MATCHED BY TARGET 
	THEN INSERT (CalendarDate, utmSource, number_of_registrations, number_of_purchases, total_billing) 
	VALUES (SOURCE.CalendarDate, SOURCE.utmSource, SOURCE.number_of_registrations, SOURCE.number_of_purchases, SOURCE.total_billing) 
WHEN NOT MATCHED BY SOURCE 
	THEN DELETE;