
CREATE TABLE public.employees (
    employee_id TEXT, department TEXT, job_title TEXT, hire_date TEXT,
    termination_date TEXT, employment_status TEXT, employment_type TEXT,
    gender TEXT, age INTEGER, location TEXT, manager_id TEXT
);

CREATE TABLE public.compensation (
    employee_id TEXT, effective_date TEXT, base_salary_eur TEXT, bonus_target_pct TEXT
);

CREATE TABLE public.performance_reviews (
    employee_id TEXT, review_date TEXT, rating TEXT, promotion_flag INTEGER
);

CREATE TABLE public.attrition_events (
    employee_id TEXT, termination_date TEXT, termination_type TEXT,
    termination_reason TEXT, exit_survey_score TEXT
);

CREATE TABLE public.engagement_surveys (
    employee_id TEXT, survey_date TEXT, engagement_score INTEGER, satisfaction_score TEXT
);

CREATE TABLE public.recruiting_funnel (
    candidate_id TEXT, department TEXT, source TEXT, application_date TEXT,
    final_stage TEXT, days_to_fill TEXT
);

CREATE TABLE public.recruiting_spend (
    month TEXT, source TEXT, spend_eur TEXT
);

CREATE TABLE public.attrition_events_copy AS
SELECT * FROM public.attrition_events;

CREATE TABLE public.compensation_copy AS
SELECT * FROM public.compensation;

CREATE TABLE public.employees_copy AS
SELECT * FROM public.employees;

CREATE TABLE public.engagement_surveys_copy AS
SELECT * FROM public.engagement_surveys;


CREATE TABLE public.performance_reviews_copy AS
SELECT * FROM public.performance_reviews;

CREATE TABLE public.recruiting_funnel_copy AS
SELECT * FROM public.recruiting_funnel;

CREATE TABLE public.recruiting_spend_copy AS
SELECT * FROM public.recruiting_spend;
--See if they loaded perfectly
SELECT * FROM public.attrition_events_copy
SELECT * FROM public.compensation_copy
SELECT * FROM public.employees_copy
SELECT * FROM public.engagement_surveys_copy
SELECT * FROM public.performance_reviews_copy
SELECT * FROM public.recruiting_funnel_copy
SELECT * FROM public.recruiting_spend_copy

-- 1. Row-Count Validation
SELECT COUNT(*) FROM attrition_events
union all 
SELECT COUNT(*) FROM compensation
union all
SELECT COUNT(*) FROM employees
union all
SELECT COUNT(*) FROM engagement_surveys
union all
SELECT COUNT(*) FROM performance_reviews
union all
SELECT COUNT(*) FROM recruiting_funnel
union all
SELECT COUNT(*) FROM recruiting_spend


SELECT COUNT(*) FROM attrition_events_copy
union all 
SELECT COUNT(*) FROM compensation_copy
union all
SELECT COUNT(*) FROM employees_copy
union all
SELECT COUNT(*) FROM engagement_surveys_copy
union all
SELECT COUNT(*) FROM performance_reviews_copy
union all
SELECT COUNT(*) FROM recruiting_funnel_copy
union all
SELECT COUNT(*) FROM recruiting_spend_copy

-- Validation: Working copies were created successfully and row counts
-- Match the corresponding raw source tables.

-- ============================================================
-- DATA CLEANING: ATTRITION_EVENTS
-- ============================================================
SELECT * FROM public.attrition_events_copy

--Completeness
select 
	count(*) as total_rows,
	count(*)-count(employee_id) as missing_employee_id,
	count(*)-count(termination_date) as missing_termination_date,
	count(*)-count(termination_type) as missing_termination_type,
	count(*)-count(termination_reason) as missing_termination_reason,
	count(*)-count(exit_survey_score) as missing_exit_survey_score
from public.attrition_events_copy


SELECT exit_survey_score, COUNT(*) 
FROM public.attrition_events_copy
WHERE exit_survey_score IN ('N/A','NULL','None','n/a','Unknown','--','null')
GROUP BY exit_survey_score;

--Consistency
--IS the same thing writen in the same way

--Check for the employee id
select 
	employee_id,
	count(*)
from attrition_events_copy
group by employee_id

----Check for the termination_date
select 
	termination_date,
	count(*)
from attrition_events_copy
group by termination_date

ALTER TABLE public.attrition_events_copy
ALTER COLUMN termination_date TYPE DATE
USING CASE
    WHEN termination_date ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(termination_date, 'YYYY-MM-DD')
    WHEN termination_date ~ '^\d{2}/\d{2}/\d{4}$'
        THEN TO_DATE(termination_date, 'MM/DD/YYYY')
    WHEN termination_date ~ '^\d{2}-\d{2}-\d{4}$'
        THEN TO_DATE(termination_date, 'DD-MM-YYYY')
    WHEN termination_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
        THEN TO_DATE(termination_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;

select 
	termination_date,
	count(*)
from attrition_events_copy
group by termination_date;


--Check for termination type
select 
	termination_type,
	count(*)
from attrition_events_copy
group by termination_type;

update attrition_events_copy
set termination_type=initcap(trim(termination_type))

select 
	termination_type,
	count(*)
from attrition_events_copy
group by termination_type;

--Check for termination_reason
select 
	termination_reason,
	count(*)
from attrition_events_copy
group by termination_reason;

update attrition_events_copy
set termination_reason=initcap(trim(termination_reason))

--Check for exit_survey_score
select 
	exit_survey_score,
	count(*)
from attrition_events_copy
group by exit_survey_score;

ALTER TABLE public.attrition_events_copy
ALTER COLUMN exit_survey_score TYPE NUMERIC
USING NULLIF(TRIM(exit_survey_score), '')::numeric;

-- Check for duplicates
SELECT
    employee_id,
    COUNT(*)
FROM attrition_events_copy
GROUP BY employee_id
HAVING COUNT(*) > 1;

SELECT * FROM public.attrition_events_copy
WHERE employee_id IN ('EMP00532','EMP00615')
ORDER BY employee_id;

DELETE FROM public.attrition_events_copy a
USING public.attrition_events_copy b
WHERE a.ctid < b.ctid
  AND a.employee_id = b.employee_id;

SELECT employee_id, COUNT(*) 
FROM public.attrition_events_copy 
GROUP BY employee_id 
HAVING COUNT(*) > 1;


CREATE OR REPLACE VIEW attrition_events_clean AS
SELECT *
FROM attrition_events_copy

select * from public.attrition_events_clean

-- ============================================================
-- DATA CLEANING: COMPENSATION
-- ============================================================
SELECT
*
FROM public.compensation_copy

--Completeness
select 
	count(*) as total_rows,
	count(*)-count(employee_id) as missing_employee_id,
	count(*)-count(effective_date) as missing_effective_date,
	count(*)-count(base_salary_eur) as missing_base_salary_eur,
	count(*)-count(bonus_target_pct) as missing_bonus_target_pct
from public.compensation_copy

DELETE FROM public.compensation_copy
WHERE base_salary_eur IS NULL;

--Consistency
--Is the same column be written in the same way

--Check for employee_id
select
	employee_id,
	count(*)
from compensation_copy
group by 
	employee_id

--Check for effective_date
select
	effective_date,
	count(*)
from compensation_copy
group by 
	effective_date


ALTER TABLE public.compensation_copy
ALTER COLUMN effective_date TYPE DATE
USING CASE
    WHEN effective_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(effective_date, 'YYYY-MM-DD')
    WHEN effective_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(effective_date, 'MM/DD/YYYY')
    WHEN effective_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(effective_date, 'DD-MM-YYYY')
    WHEN effective_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(effective_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;

--Check for base_salary_eur
select
	base_salary_eur,
	count(*)
from compensation_copy
group by 
	base_salary_eur


UPDATE public.compensation_copy
SET base_salary_eur = NULL
WHERE TRIM(base_salary_eur) IN ('N/A','NULL','None','n/a','Unknown','--');
	
UPDATE public.compensation_copy
SET base_salary_eur = TRIM(
    REPLACE(REPLACE(REPLACE(base_salary_eur, '€', ''), 'EUR', ''), ',', '')
)
WHERE base_salary_eur IS NOT NULL;


UPDATE public.compensation_copy
SET base_salary_eur = NULL
WHERE base_salary_eur ~ '^-';

ALTER TABLE public.compensation_copy
ALTER COLUMN base_salary_eur TYPE NUMERIC
USING NULLIF(TRIM(base_salary_eur), '')::numeric;

select
	base_salary_eur,
	count(*)
from compensation_copy
group by 
	base_salary_eur

--Check for bonus target pct
select
	bonus_target_pct,
	count(*)
from compensation_copy
group by 
	bonus_target_pct


ALTER TABLE public.compensation_copy
ALTER COLUMN bonus_target_pct TYPE NUMERIC
USING NULLIF(TRIM(bonus_target_pct), '')::numeric;

UPDATE public.compensation_copy
SET bonus_target_pct = ROUND(bonus_target_pct / 100, 2);

ALTER TABLE public.compensation_copy
ALTER COLUMN bonus_target_pct TYPE NUMERIC(4,2);


SELECT
	base_salary_eur
FROM public.compensation_copy
where base_salary_eur<=1000


--Check for duplicate
select 
	employee_id,
	count(*)
from compensation_copy
group by employee_id
having count(*)>1

SELECT *
FROM public.compensation_copy
WHERE employee_id IN (
    SELECT employee_id
    FROM public.compensation_copy
    GROUP BY employee_id
    HAVING COUNT(*) > 1
)
ORDER BY employee_id, effective_date;

DELETE FROM public.compensation_copy a
USING public.compensation_copy b
WHERE a.ctid < b.ctid
  AND a.employee_id = b.employee_id
  AND a.effective_date = b.effective_date;

  CREATE OR REPLACE VIEW public.compensation_clean AS
SELECT employee_id, effective_date, base_salary_eur, bonus_target_pct
FROM public.compensation_copy;

select *
from compensation_clean


-- ============================================================
-- DATA CLEANING: EMPLOYEES
-- ============================================================

select *
from public.employees_copy

--Completeness
select 
	count(*) as total_rows,
	count(*)-count(employee_id) as missing_employee_id,
	count(*)-count(department) as missing_department,
	count(*)-count(job_title) as missing_job_title,
	count(*)-count(hire_date) as missing_hire_date,
	count(*)-count(termination_date) as missing_termination_date,
	count(*)-count(employment_status) as missing_employment_status,
	count(*)-count(employment_type) as missing_employment_type,
	count(*)-count(gender) as missing_gender,
	count(*)-count(age) as missing_age,
	count(*)-count(location) as missing_location,
	count(*)-count(manager_id) as missing_manager_id
from public.employees_copy

SELECT 'job_title' AS col, job_title AS val, COUNT(*) 
FROM public.employees_copy
WHERE job_title IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY job_title
UNION ALL
SELECT 'employment_status', employment_status, COUNT(*) 
FROM public.employees_copy
WHERE employment_status IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY employment_status
UNION ALL
SELECT 'employment_type', employment_type, COUNT(*) 
FROM public.employees_copy
WHERE employment_type IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY employment_type
UNION ALL
SELECT 'gender', gender, COUNT(*) 
FROM public.employees_copy
WHERE gender IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY gender
UNION ALL
SELECT 'location', location, COUNT(*) 
FROM public.employees_copy
WHERE location IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY location
UNION ALL
SELECT 'manager_id', manager_id, COUNT(*) 
FROM public.employees_copy
WHERE manager_id IN ('N/A','NULL','None','n/a','Unknown','--') GROUP BY manager_id;

UPDATE public.employees_copy
SET gender = NULL
WHERE gender IN ('N/A','NULL','None','n/a','Unknown','--');

UPDATE public.employees_copy
SET location = NULL
WHERE location IN ('N/A','NULL','None','n/a','Unknown','--');


--Consistency
--Is the same column written in the same way
select *
from public.employees_copy

--Check for employee id
select
	employee_id,
	count(*)
from employees_copy
group by 
	employee_id

--Check for Department
select
	department,
	count(*)
from employees_copy
group by 
	department

UPDATE public.employees_copy
SET department = INITCAP(TRIM(department));

UPDATE public.employees_copy
SET department = 'HR'
WHERE UPPER(TRIM(department)) = 'HR';

UPDATE public.employees_copy
SET department = NULL
WHERE department IN ('N/A','NULL','None','n/a','Unknown','--','Null');

SELECT department, COUNT(*) FROM public.employees_copy
GROUP BY department ORDER BY department;

--Check for job title

select
	job_title,
	count(*)
from employees_copy
group by 
	job_title

update employees_copy
set job_title=initcap(trim(job_title))
select *
from public.employees_copy

--Check for hire date
select
	hire_date,
	count(*)
from employees_copy
group by 
	hire_date

ALTER TABLE public.employees_copy
ALTER COLUMN hire_date TYPE DATE
USING CASE
    WHEN hire_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(hire_date, 'YYYY-MM-DD')
    WHEN hire_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(hire_date, 'MM/DD/YYYY')
    WHEN hire_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(hire_date, 'DD-MM-YYYY')
    WHEN hire_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(hire_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;

--Check for termination date
select
	termination_date,
	count(*)
from employees_copy
group by 
	termination_date

ALTER TABLE public.employees_copy
ALTER COLUMN termination_date TYPE DATE
USING CASE
    WHEN termination_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(termination_date, 'YYYY-MM-DD')
    WHEN termination_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(termination_date, 'MM/DD/YYYY')
    WHEN termination_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(termination_date, 'DD-MM-YYYY')
    WHEN termination_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(termination_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;

--Check for employment status 

select
	employment_status,
	count(*)
from employees_copy
group by 
	employment_status

update employees_copy
set employment_status=initcap(trim(employment_status))

--Check for employment type

select
	employment_type,
	count(*)
from employees_copy
group by 
	employment_type

update employees_copy
set employment_type=Initcap(trim(employment_type))

UPDATE public.employees_copy
SET employment_type = INITCAP(REPLACE(TRIM(employment_type), ' ', '-'));
select *
from public.employees_copy


UPDATE public.employees_copy
SET employment_type = 'Contract'
WHERE employment_type = 'Contractor';

--Check for Gender

select
	gender,
	count(*)
from employees_copy
group by 
	gender


UPDATE public.employees_copy
SET gender = CASE
    WHEN TRIM(gender) = 'M' THEN 'Male'
    WHEN TRIM(gender) = 'F' THEN 'Female'
    WHEN TRIM(gender) = 'Nb' THEN 'Non-Binary'
    WHEN TRIM(gender) IN ('N/A','NULL','None','n/a','Unknown','--') THEN NULL
    ELSE INITCAP(TRIM(gender))
END;


--Check for age 
select
	age,
	count(*)
from employees_copy
group by 
	age

UPDATE public.employees_copy
SET age = NULL
WHERE age < 0 OR age = 999;

SELECT age, COUNT(*) FROM public.employees_copy
WHERE age IS NOT NULL AND (age < 16 OR age > 75)
GROUP BY age ORDER BY age;



--Check for location
select
	location,
	count(*)
from employees_copy
group by 
	location

update employees_copy
set location=initcap(trim(location))



--Check for manager_id
select
	manager_id,
	count(*)
from employees_copy
group by 
	manager_id

update employees_copy
set manager_id=(trim(manager_id))



--Check for duplicates
select 
	employee_id,
	count(*)
from public.employees_copy
group by employee_id
having count(*)>1

SELECT *
FROM public.employees_copy
WHERE employee_id IN (
    'EMP00810','EMP00083','EMP00174','EMP00470','EMP00471','EMP00554'
)
ORDER BY employee_id;


DELETE FROM public.employees_copy a
USING public.employees_copy b
WHERE a.ctid < b.ctid
  AND a.employee_id = b.employee_id;


 CREATE OR REPLACE VIEW public.employees_clean AS
SELECT employee_id, department, job_title, hire_date, termination_date,
       employment_status, employment_type, gender, age, location, manager_id
FROM public.employees_copy;


select *
from public.employees_clean


-- ============================================================
-- DATA CLEANING: ENGAGEMENT SURVEYS
-- ============================================================
select *
from public.engagement_surveys_copy

--Completeness
select 
	count(*) as total_rows,
	count(*)-count(employee_id) as missing_employee_id,
	count(*)-count(survey_date) as missing_survey_date,
	count(*)-count(engagement_score) as missing_engagement_score,
	count(*)-count(satisfaction_score) as missing_satisfaction_score
from public.engagement_surveys_copy

--Consistency
--Is the same column Writen in the same way

--check for employee id
select
	employee_id,
	count(*)
from engagement_surveys_copy
group by employee_id


UPDATE public.engagement_surveys_copy
SET employee_id = CASE
    WHEN TRIM(employee_id) IN ('N/A','NULL','None','n/a','Unknown','--') THEN NULL
    ELSE TRIM(employee_id)
END;


--Check for survey date
select 
	survey_date,
	count(*)
from engagement_surveys_copy
group by survey_date



ALTER TABLE public.engagement_surveys_copy
ALTER COLUMN survey_date TYPE DATE
USING CASE
    WHEN survey_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(survey_date, 'YYYY-MM-DD')
    WHEN survey_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(survey_date, 'MM/DD/YYYY')
    WHEN survey_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(survey_date, 'DD-MM-YYYY')
    WHEN survey_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(survey_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;


--Check for  engagement score
select
	engagement_score,
	count(*)
from engagement_surveys_copy
group by engagement_score

UPDATE public.engagement_surveys_copy
SET engagement_score = NULL
WHERE engagement_score = 15;

--Check for satisfaction score
select
	satisfaction_score,
	count(*)
from engagement_surveys_copy
group by satisfaction_score
order by satisfaction_score

ALTER TABLE public.engagement_surveys_copy
ALTER COLUMN satisfaction_score TYPE INTEGER
USING NULLIF(TRIM(satisfaction_score), '')::integer;


--Check for duplicates
SELECT employee_id, survey_date, COUNT(*)
FROM public.engagement_surveys_copy
GROUP BY employee_id, survey_date
HAVING COUNT(*) > 1;


CREATE OR REPLACE VIEW public.engagement_surveys_clean AS
SELECT employee_id, survey_date, engagement_score, satisfaction_score
FROM public.engagement_surveys_copy;

select *
from engagement_surveys_clean


-- ============================================================
-- DATA CLEANING: PERFORMANCE REVIEW
-- ============================================================
Select *
from public.performance_reviews_copy

--Completeness
select 
	count(*) as total_rows,
	count(*)-count(employee_id) as missing_employee_id,
	count(*)-count(review_date) as missing_review_date,
	count(*)-count(rating) as missing_rating,
	count(*)-count(promotion_flag) as missing_promotion_flag
from public.performance_reviews_copy

--Consistency
--Is the same column writen in the same way

--Check for employee_id

select 
	employee_id,
	count(*)
from performance_reviews_copy
group by employee_id
order by employee_id

UPDATE public.performance_reviews_copy
SET employee_id = CASE
    WHEN TRIM(employee_id) IN ('N/A','NULL','None','n/a','Unknown','--') THEN NULL
    ELSE TRIM(employee_id)
END;

--Check for review_date
Select 
	review_date,
	count(*)
from performance_reviews_copy
group by review_date

ALTER TABLE public.performance_reviews_copy
ALTER COLUMN review_date TYPE DATE
USING CASE
    WHEN review_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(review_date, 'YYYY-MM-DD')
    WHEN review_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(review_date, 'MM/DD/YYYY')
    WHEN review_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(review_date, 'DD-MM-YYYY')
    WHEN review_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(review_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;

--Check for rating
select 
	rating,
	Count(*)
from performance_reviews_copy
group by rating
order by rating

UPDATE public.performance_reviews_copy
SET rating = CASE
    WHEN TRIM(rating) IN ('N/A','NULL','None','n/a','Unknown','--') THEN NULL
    ELSE TRIM(rating)
END;

ALTER TABLE public.performance_reviews_copy
ALTER COLUMN rating TYPE INTEGER
USING NULLIF(TRIM(rating), '')::integer;

--Check for promotion flag
select 
	promotion_flag,
	count(*)
from performance_reviews_copy
group by promotion_flag
order by promotion_flag

--Check for duplicates
Select 
	employee_id,
	review_date,
	count(*)
from performance_reviews_copy
group by employee_id,review_date
having count(*)>1

SELECT *
FROM public.performance_reviews_copy
WHERE (employee_id, review_date) IN (
    ('EMP00256','2023-12-16'),
    ('EMP00742','2025-08-13'),
    ('EMP00524','2026-03-30'),
    ('EMP00276','2025-12-30'),
    ('EMP00576','2024-01-17'),
    ('EMP00805','2025-06-11'),
    ('EMP00812','2026-02-18')
)
ORDER BY employee_id, review_date;

DELETE FROM public.performance_reviews_copy a
USING public.performance_reviews_copy b
WHERE a.ctid < b.ctid
  AND a.employee_id = b.employee_id
  AND a.review_date = b.review_date;

 CREATE OR REPLACE VIEW public.performance_reviews_clean AS
SELECT employee_id, review_date, rating, promotion_flag
FROM public.performance_reviews_copy;


-- ============================================================
-- DATA CLEANING: RECRUITING FUNNEL
-- ============================================================
select *
from recruiting_funnel_copy

--Completeness
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(candidate_id)      AS missing_candidate_id,
    COUNT(*) - COUNT(department)        AS missing_department,
    COUNT(*) - COUNT(source)            AS missing_source,
    COUNT(*) - COUNT(application_date)  AS missing_application_date,
    COUNT(*) - COUNT(final_stage)       AS missing_final_stage,
    COUNT(*) - COUNT(days_to_fill)      AS missing_days_to_fill
FROM public.recruiting_funnel_copy;

SELECT final_stage, COUNT(*) AS total,
       COUNT(days_to_fill) AS has_days_to_fill,
       COUNT(*) - COUNT(days_to_fill) AS missing_days_to_fill
FROM public.recruiting_funnel_copy
GROUP BY final_stage
ORDER BY total DESC;

--Consistency
--Is the same column writen in the same way

--Check for candidate_id
select 
	candidate_id,
	count(*)
from recruiting_funnel_copy
group by candidate_id

SELECT candidate_id, COUNT(*) FROM public.recruiting_funnel_copy
WHERE candidate_id IN ('N/A','NULL','None','n/a','Unknown','--')
GROUP BY candidate_id;
--Check for department
SELECT 
	department, 
	COUNT(*) 
	FROM public.recruiting_funnel_copy
GROUP BY department ORDER BY department;

update recruiting_funnel_copy
set department=initcap(trim(department))

UPDATE public.recruiting_funnel_copy
SET department = 'HR'
WHERE UPPER(TRIM(department)) = 'HR';

--Check for source
SELECT 
	source, 
	COUNT(*) 
FROM public.recruiting_funnel_copy
GROUP BY source ORDER BY source;

update recruiting_funnel_copy
set source=initcap(trim(source))

UPDATE public.recruiting_funnel_copy
SET source = CASE
    WHEN source IN ('Jobboard') THEN 'Job Board'
    WHEN source IN ('Linkedin') THEN 'Linked In'
    ELSE source
END;

--Chekc for application_date
select
	application_date,
	count(*)
from recruiting_funnel_copy
group by application_date

ALTER TABLE public.recruiting_funnel_copy
ALTER COLUMN application_date TYPE DATE
USING CASE
    WHEN application_date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(application_date, 'YYYY-MM-DD')
    WHEN application_date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(application_date, 'MM/DD/YYYY')
    WHEN application_date ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE(application_date, 'DD-MM-YYYY')
    WHEN application_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$' THEN TO_DATE(application_date, 'FMMonth DD, YYYY')
    ELSE NULL
END;


--Check for final_stage
SELECT 
	final_stage, 
	COUNT(*) 
FROM public.recruiting_funnel_copy
GROUP BY final_stage ORDER BY final_stage;

--Check for days_to_fill
SELECT 
	days_to_fill, 
	COUNT(*)
 FROM public.recruiting_funnel_copy
WHERE days_to_fill IS NOT NULL
GROUP BY days_to_fill
ORDER BY days_to_fill;

ALTER TABLE public.recruiting_funnel_copy
ALTER COLUMN days_to_fill TYPE INTEGER
USING NULLIF(TRIM(days_to_fill), '')::integer;

UPDATE public.recruiting_funnel_copy
SET days_to_fill = NULL
WHERE days_to_fill < 0;

--Check for duplicates
SELECT 
	candidate_id, 
	COUNT(*)
FROM public.recruiting_funnel_copy
GROUP BY candidate_id
HAVING COUNT(*) > 1;

SELECT *
FROM public.recruiting_funnel_copy
WHERE candidate_id IN (
    'CAND01090','CAND00991','CAND00182','CAND00120','CAND00671',
    'CAND01191','CAND01013','CAND00467','CAND00741','CAND00960'
)
ORDER BY candidate_id;

DELETE FROM public.recruiting_funnel_copy a
USING public.recruiting_funnel_copy b
WHERE a.ctid < b.ctid AND a.candidate_id = b.candidate_id;


CREATE OR REPLACE VIEW public.recruiting_funnel_clean AS
SELECT candidate_id, department, source, application_date, final_stage, days_to_fill
FROM public.recruiting_funnel_copy;

select *
from recruiting_funnel_clean


-- ============================================================
-- DATA CLEANING: RECRUITING SPEND
-- ============================================================
select *
from recruiting_spend_copy

--Completeness
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(month)      AS missing_month,
    COUNT(*) - COUNT(source)        AS missing_department,
    COUNT(*) - COUNT(spend_eur)            AS missing_spend_eur
FROM public.recruiting_spend_copy;

--Consistency
--Is the same column writen in the same way

--Check for month
select 
	month,
	count(*)
from recruiting_spend_copy
group by month


ALTER TABLE public.recruiting_spend_copy
ALTER COLUMN month TYPE DATE
USING CASE
    WHEN month ~ '^\d{4}-\d{2}$' THEN TO_DATE(month || '-01', 'YYYY-MM-DD')
    WHEN month ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(month, 'YYYY-MM-DD')
    ELSE NULL
END;

--Check for source
select 
	source,
	count(*)
from recruiting_spend_copy
group by source

update recruiting_spend_copy
set source=initcap(trim(source))

UPDATE public.recruiting_spend_copy
SET source = CASE
    WHEN source IN ('Jobboard') THEN 'Job Board'
    WHEN source IN ('Linkedin') THEN 'Linked In'
    ELSE source
END;

--Check for spend_eur
select 
	spend_eur,
	count(*)
from recruiting_spend_copy
group by spend_eur

SELECT spend_eur, COUNT(*) FROM public.recruiting_spend_copy
WHERE spend_eur IN ('N/A','NULL','None','n/a','Unknown','--') OR spend_eur ~ '^-'
GROUP BY spend_eur;

UPDATE public.recruiting_spend_copy
SET spend_eur = TRIM(REPLACE(REPLACE(REPLACE(spend_eur, '€', ''), 'EUR', ''), ',', ''))
WHERE spend_eur IS NOT NULL;

UPDATE public.recruiting_spend_copy
SET spend_eur = NULL
WHERE spend_eur ~ '^-';

ALTER TABLE public.recruiting_spend_copy
ALTER COLUMN spend_eur TYPE NUMERIC
USING NULLIF(TRIM(spend_eur), '')::numeric;


--Check for duplicates
SELECT month, source, COUNT(*)
FROM public.recruiting_spend_copy
GROUP BY month, source
HAVING COUNT(*) > 1;

CREATE OR REPLACE VIEW public.recruiting_spend_clean AS
SELECT month, source, spend_eur
FROM public.recruiting_spend_copy;

select *
from recruiting_spend_clean


Hr business questions · SQL
-- ================================================================
-- HR WORKFORCE ANALYTICS — BUSINESS QUESTIONS (BQ01–BQ30)
-- Built on top of the 7 _clean views:
--   employees_clean, compensation_clean, performance_reviews_clean,
--   attrition_events_clean, engagement_surveys_clean,
--   recruiting_funnel_clean, recruiting_spend_clean
-- ================================================================
 
 
-- ============================================================
-- SECTION 1: WORKFORCE OVERVIEW / HEADCOUNT
-- ============================================================
 
-- BQ01: Current headcount (active employees)
SELECT 
	COUNT(*) AS active_headcount
FROM employees_clean
WHERE employment_status = 'Active';

-- BQ02: Headcount by department
SELECT 
	department, 
	COUNT(*) AS headcount
FROM employees_clean
WHERE employment_status = 'Active'
GROUP BY department
ORDER BY headcount DESC;

-- BQ03: Headcount by employment type
SELECT employment_type, COUNT(*) AS headcount
FROM employees_clean
WHERE employment_status = 'Active'
GROUP BY employment_type
ORDER BY headcount DESC;

-- BQ04: Gender distribution (overall and by department)
SELECT 
	department, 
	gender, 
	COUNT(*) AS headcount
FROM employees_clean
WHERE employment_status = 'Active'
GROUP BY department, gender
ORDER BY department, gender;

-- BQ05: Average age by department
SELECT department, ROUND(AVG(age), 1) AS avg_age
FROM employees_clean
WHERE employment_status = 'Active' AND age IS NOT NULL AND department IS NOT NULL
GROUP BY department
ORDER BY avg_age DESC;

-- BQ06: Headcount by location
SELECT location, COUNT(*) AS headcount
FROM employees_clean
WHERE employment_status = 'Active' AND location IS NOT NULL
GROUP BY location
ORDER BY headcount DESC;

-- BQ07: Tenure distribution — average years of service (active employees)
SELECT department,
       ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))), 1) AS avg_tenure_years
FROM employees_clean
WHERE employment_status = 'Active' AND hire_date IS NOT NULL AND department IS NOT NULL
GROUP BY department
ORDER BY avg_tenure_years DESC;

-- BQ08: Headcount growth by hire year
SELECT 
	EXTRACT(YEAR FROM hire_date) AS hire_year, 
	COUNT(*) AS hires
FROM employees_clean
WHERE hire_date IS NOT NULL
GROUP BY hire_year
ORDER BY hire_year;

-- BQ09: Span of control — average direct reports per manager
SELECT 
	manager_id, 
	COUNT(*) AS direct_reports
FROM employees_clean
WHERE employment_status = 'Active' AND manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY direct_reports DESC;

-- ============================================================
-- SECTION 2: ATTRITION ANALYSIS
-- ============================================================

-- BQ10: Overall attrition rate (terminations / average headcount)
SELECT
    (SELECT COUNT(*) FROM attrition_events_clean) AS total_terminations,
    (SELECT COUNT(*) FROM employees_clean) AS total_ever_employed,
    ROUND(
        (SELECT COUNT(*) FROM attrition_events_clean)::numeric
        / NULLIF((SELECT COUNT(*) FROM employees_clean), 0) * 100, 2
    ) AS attrition_rate_pct;

		-- BQ11: Attrition by department
SELECT e.department, COUNT(a.employee_id) AS terminations
FROM attrition_events_clean a
JOIN employees_clean e ON a.employee_id = e.employee_id
GROUP BY e.department
ORDER BY terminations DESC;

-- BQ12: Voluntary vs involuntary termination split
SELECT termination_type, COUNT(*) AS total,
       ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM attrition_events_clean
GROUP BY termination_type;

-- BQ13: Top termination reasons
SELECT termination_reason, COUNT(*) AS total
FROM attrition_events_clean
GROUP BY termination_reason
ORDER BY total DESC;

-- BQ14: Average exit survey score by termination type
SELECT termination_type, ROUND(AVG(exit_survey_score), 2) AS avg_exit_score,
       COUNT(exit_survey_score) AS responses
FROM attrition_events_clean
GROUP BY termination_type;

-- BQ15: Attrition rate by tenure band (early attrition flag)
SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(a.termination_date, e.hire_date)) < 1 THEN '< 1 year'
        WHEN EXTRACT(YEAR FROM AGE(a.termination_date, e.hire_date)) < 3 THEN '1-3 years'
        WHEN EXTRACT(YEAR FROM AGE(a.termination_date, e.hire_date)) < 5 THEN '3-5 years'
        ELSE '5+ years'
    END AS tenure_band,
    COUNT(*) AS terminations
FROM attrition_events_clean a
JOIN employees_clean e ON a.employee_id = e.employee_id
WHERE e.hire_date IS NOT NULL AND a.termination_date IS NOT NULL
GROUP BY tenure_band
ORDER BY terminations DESC;


-- BQ16: Attrition trend over time (terminations per quarter)
SELECT DATE_TRUNC('quarter', termination_date) AS quarter, COUNT(*) AS terminations
FROM attrition_events_clean
WHERE termination_date IS NOT NULL
GROUP BY quarter
ORDER BY quarter;

-- ============================================================
-- SECTION 3: COMPENSATION ANALYSIS
-- ============================================================

-- BQ17: Average salary by department (current/most recent comp record per employee)
WITH latest_comp AS (
    SELECT DISTINCT ON (employee_id) employee_id, base_salary_eur, bonus_target_pct
    FROM compensation_clean
    ORDER BY employee_id, effective_date DESC
)
SELECT e.department, ROUND(AVG(c.base_salary_eur), 0) AS avg_salary,
       ROUND(AVG(c.bonus_target_pct), 3) AS avg_bonus_target
FROM latest_comp c
JOIN employees_clean e ON c.employee_id = e.employee_id
GROUP BY e.department
ORDER BY avg_salary DESC;

-- BQ18: Gender pay gap by department (using latest comp record)
WITH latest_comp AS (
    SELECT DISTINCT ON (employee_id) employee_id, base_salary_eur
    FROM compensation_clean
    ORDER BY employee_id, effective_date DESC
)
SELECT e.department, e.gender, ROUND(AVG(c.base_salary_eur), 0) AS avg_salary, COUNT(*) AS headcount
FROM latest_comp c
JOIN employees_clean e ON c.employee_id = e.employee_id
WHERE e.gender IN ('Male', 'Female')
GROUP BY e.department, e.gender
ORDER BY e.department, e.gender;

-- BQ19: Compensation distribution — salary bands
WITH latest_comp AS (
    SELECT DISTINCT ON (employee_id) employee_id, base_salary_eur
    FROM compensation_clean
    ORDER BY employee_id, effective_date DESC
)
SELECT
    CASE
        WHEN base_salary_eur < 50000 THEN '< 50K'
        WHEN base_salary_eur < 70000 THEN '50K-70K'
        WHEN base_salary_eur < 90000 THEN '70K-90K'
        ELSE '90K+'
    END AS salary_band,
    COUNT(*) AS employees
FROM latest_comp
GROUP BY salary_band
ORDER BY salary_band;

-- ============================================================
-- SECTION 4: PERFORMANCE & PROMOTION
-- ============================================================

-- BQ20: Average performance rating by department
with avg_performance_rating as
(
Select 
	e.employee_id,
	e.department,
	rating
from employees_clean as e
Join performance_reviews_clean as p
	on e.employee_id=p.employee_id
)
Select
	department,
	Round(avg(rating),2) as avg_rating_per_department
from avg_performance_rating
Group by department
order by avg_rating_per_department desc

-- BQ21: Promotion rate by department
SELECT e.department,
       COUNT(*) AS total_reviews,
       SUM(p.promotion_flag) AS promotions,
       ROUND(SUM(p.promotion_flag)::numeric / COUNT(*) * 100, 1) AS promotion_rate_pct
FROM performance_reviews_clean p
JOIN employees_clean e ON p.employee_id = e.employee_id
GROUP BY e.department
ORDER BY promotion_rate_pct DESC;

-- BQ22: Does low performance rating predict attrition?
SELECT
    CASE WHEN a.employee_id IS NOT NULL THEN 'Terminated' ELSE 'Active/Retained' END AS status,
    ROUND(AVG(p.rating), 2) AS avg_rating
FROM performance_reviews_clean p
LEFT JOIN attrition_events_clean a ON p.employee_id = a.employee_id
GROUP BY status;

-- BQ23: Rating trend over time (company-wide average rating per review period)
SELECT 
	DATE_TRUNC('quarter', review_date) AS quarter, 
	ROUND(AVG(rating), 2) AS avg_rating
FROM performance_reviews_clean
WHERE review_date IS NOT NULL
GROUP BY quarter
ORDER BY quarter;

-- ============================================================
-- SECTION 5: ENGAGEMENT & SATISFACTION
-- ============================================================

-- BQ24: Average engagement/satisfaction score by department
SELECT e.department,
       ROUND(AVG(s.engagement_score), 2) AS avg_engagement,
       ROUND(AVG(s.satisfaction_score), 2) AS avg_satisfaction
FROM engagement_surveys_clean s
JOIN employees_clean e ON s.employee_id = e.employee_id
GROUP BY e.department
ORDER BY avg_engagement ASC;

-- BQ25: Engagement trend leading up to termination (last survey before leaving)
WITH last_survey AS (
    SELECT DISTINCT ON (employee_id) employee_id, survey_date, engagement_score, satisfaction_score
    FROM engagement_surveys_clean
    ORDER BY employee_id, survey_date DESC
)
SELECT
    CASE WHEN a.employee_id IS NOT NULL THEN 'Terminated' ELSE 'Active/Retained' END AS status,
    ROUND(AVG(ls.engagement_score), 2) AS avg_last_engagement_score,
    ROUND(AVG(ls.satisfaction_score), 2) AS avg_last_satisfaction_score
FROM last_survey ls
LEFT JOIN attrition_events_clean a ON ls.employee_id = a.employee_id
GROUP BY status;

-- BQ26: Engagement score distribution (histogram-style buckets)
SELECT
    CASE
        WHEN engagement_score <= 3 THEN '1-3 (Low)'
        WHEN engagement_score <= 6 THEN '4-6 (Medium)'
        ELSE '7-10 (High)'
    END AS engagement_band,
    COUNT(*) AS responses
FROM engagement_surveys_clean
WHERE engagement_score IS NOT NULL
GROUP BY engagement_band;

-- ============================================================
-- SECTION 6: RECRUITING FUNNEL & EFFICIENCY
-- ============================================================

-- BQ27: Funnel conversion rates by stage
SELECT final_stage, COUNT(*) AS candidates,
       ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_total
FROM recruiting_funnel_clean
GROUP BY final_stage
ORDER BY candidates DESC;

-- BQ28: Average days-to-fill by department (hired candidates only)
SELECT department, ROUND(AVG(days_to_fill), 1) AS avg_days_to_fill, COUNT(*) AS hires
FROM recruiting_funnel_clean
WHERE final_stage = 'Hired'
GROUP BY department
ORDER BY avg_days_to_fill DESC;

-- BQ29: Best-performing sourcing channel (hire rate by source)
SELECT source,
       COUNT(*) AS total_candidates,
       SUM(CASE WHEN final_stage = 'Hired' THEN 1 ELSE 0 END) AS hires,
       ROUND(SUM(CASE WHEN final_stage = 'Hired' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 1) AS hire_rate_pct
FROM recruiting_funnel_clean
GROUP BY source
ORDER BY hire_rate_pct DESC;


-- ============================================================
-- SECTION 7: RECRUITING SPEND / ROI
-- ============================================================
 
-- BQ30: Total recruiting spend by source
SELECT source, SUM(spend_eur) AS total_spend
FROM recruiting_spend_clean
GROUP BY source
ORDER BY total_spend DESC;
 
-- BQ31: Cost-per-hire by source (spend / hires from that source)
WITH hires_by_source AS (
    SELECT source, COUNT(*) AS hires
    FROM recruiting_funnel_clean
    WHERE final_stage = 'Hired'
    GROUP BY source
),
spend_by_source AS (
    SELECT source, SUM(spend_eur) AS total_spend
    FROM recruiting_spend_clean
    GROUP BY source
)
SELECT s.source, s.total_spend, h.hires,
       ROUND(s.total_spend / NULLIF(h.hires, 0), 0) AS cost_per_hire
FROM spend_by_source s
JOIN hires_by_source h ON s.source = h.source
ORDER BY cost_per_hire ASC;
 
-- BQ32: Monthly recruiting spend trend
SELECT DATE_TRUNC('month', month) AS month, SUM(spend_eur) AS total_spend
FROM recruiting_spend_clean
GROUP BY month
ORDER BY month;

--kpi_attrition_by_department
CREATE OR REPLACE VIEW public.kpi_attrition_by_department AS
SELECT
    e.department,
    COUNT(*) AS total_employees,
    COUNT(a.employee_id) AS terminations,
    ROUND(COUNT(a.employee_id)::numeric / COUNT(*) * 100, 2) AS attrition_rate_pct,
    COUNT(*) FILTER (WHERE a.termination_type = 'Voluntary') AS voluntary,
    COUNT(*) FILTER (WHERE a.termination_type = 'Involuntary') AS involuntary
FROM employees_clean e
LEFT JOIN attrition_events_clean a ON e.employee_id = a.employee_id
GROUP BY e.department;

select *
from kpi_attrition_by_department

--kpi_compensation_by_dept_gender
CREATE OR REPLACE VIEW public.kpi_compensation_by_dept_gender AS
SELECT
    e.department,
    CASE WHEN e.gender = 'Nb' THEN 'Non-Binary' ELSE e.gender END AS gender,
    COUNT(*) AS headcount,
    ROUND(AVG(c.base_salary_eur), 0) AS avg_salary,
    ROUND(AVG(c.bonus_target_pct), 3) AS avg_bonus_target
FROM employees_clean e
JOIN compensation_clean c ON e.employee_id = c.employee_id
WHERE e.gender IS NOT NULL
  AND e.department IS NOT NULL
GROUP BY
    e.department,
    CASE WHEN e.gender = 'Nb' THEN 'Non-Binary' ELSE e.gender END;

select *
from kpi_compensation_by_dept_gender


SELECT gender, COUNT(*) FROM employees_clean GROUP BY gender ORDER BY 2 DESC;

--kpi_performance_by_department
CREATE OR REPLACE VIEW public.kpi_performance_by_department AS
SELECT
    e.department,
    COUNT(*) AS total_reviews,
    ROUND(AVG(p.rating), 2) AS avg_rating,
    SUM(p.promotion_flag) AS promotions,
    ROUND(SUM(p.promotion_flag)::numeric / COUNT(*) * 100, 1) AS promotion_rate_pct
FROM performance_reviews_clean p
JOIN employees_clean e ON p.employee_id = e.employee_id
GROUP BY e.department;

select *
from kpi_performance_by_department

--kpi_engagement_vs_attrition
CREATE OR REPLACE VIEW public.kpi_engagement_vs_attrition AS
SELECT
    e.department,
    ROUND(AVG(s.engagement_score), 2) AS avg_engagement,
    ROUND(AVG(s.satisfaction_score), 2) AS avg_satisfaction,
    MAX(k.attrition_rate_pct) AS attrition_rate_pct
FROM engagement_surveys_clean s
JOIN employees_clean e ON s.employee_id = e.employee_id
JOIN kpi_attrition_by_department k ON k.department = e.department
GROUP BY e.department;

select *
from kpi_engagement_vs_attrition

--kpi_recruiting_by_source
CREATE OR REPLACE VIEW public.kpi_recruiting_by_source AS
SELECT
    source,
    COUNT(*) AS total_candidates,
    COUNT(*) FILTER (WHERE final_stage = 'Hired') AS hires,
    ROUND(COUNT(*) FILTER (WHERE final_stage = 'Hired')::numeric / COUNT(*) * 100, 1) AS hire_rate_pct,
    ROUND(AVG(days_to_fill), 1) AS avg_days_to_fill
FROM recruiting_funnel_clean
GROUP BY source;

select *
from kpi_recruiting_by_source



--kpi_cost_per_hire_by_source
CREATE OR REPLACE VIEW public.kpi_cost_per_hire_by_source AS
WITH hires AS (
    SELECT source, COUNT(*) AS hires
    FROM recruiting_funnel_clean
    WHERE final_stage = 'Hired'
    GROUP BY source
),
spend AS (
    SELECT source, SUM(spend_eur) AS total_spend
    FROM recruiting_spend_clean
    GROUP BY source
)
SELECT
    s.source,
    s.total_spend,
    h.hires,
    ROUND(s.total_spend / NULLIF(h.hires, 0), 0) AS cost_per_hire_eur
FROM spend s
LEFT JOIN hires h ON s.source = h.source;

select *
from kpi_cost_per_hire_by_source


SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public' AND table_name LIKE 'kpi_%'
ORDER BY table_name;