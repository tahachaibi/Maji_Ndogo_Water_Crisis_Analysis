-- Get to know our data
	-- list of all the tables in the database
	show tables;
    -- Retrieving the first few records from each table
    select *
    from employee
    limit 100;
    
    select *
    from global_water_access
    limit 100;
    
    select *
    from location
    limit 100;
    
    select *
    from visits
    limit 100;
    
    select *
    from water_quality
    limit 100;
    
    select *
    from water_source
    limit 100;
    
    select *
    from well_pollution
    limit 100;
    
    -- Dive into the water sources
		-- find all the unique types of water sources.
        select distinct(type_of_water_source)
        from water_source;
	
    -- Unpack the visits to water sources
		-- retrieves all records where the time_in_queue is more than 8 hours (crazy right)
        select * 
        from visits
        where time_in_queue >= 500;
       
       -- retrieves all records where there is no time_in_queue 
       select * 
        from visits
        where time_in_queue = 0;
        
        -- checking some of the water sources to know why some queues take more than 8 hours and why the is no queueing time in others
        select *
        from water_source
        where source_id in ("kiru28935224", "aklu01628224", "soru35083224", "soko33124224") ;
	
  -- Assess the quality of water sources
		-- checking if there was multiple visits to good water sources
        select *
        from water_quality 
		where subjective_quality_score = 10 
			and visit_count = 2;
	
    -- Investigate pollution issues
		-- Checking if the results is Clean but the biological is > 0.01
        select *
        from well_pollution
        where results = "clean"
			and biological > 0.01;
		
        -- description with the word "clean" in it with additional characters
        select * 
        from well_pollution
        where description like "clean %";
        
        -- Fixing the error of the description column with the word "clean" in it but it's actually contaminated
        update well_pollution 
        set description = ( case when description like "Clean Bacteria: E. coli" then "Bacteria: E. coli"
								when description like "Clean Bacteria: Giardia Lamblia" then "Bacteria: Giardia Lamblia"
                                end)
		where description like "Clean Bacteria: E. coli" or description like "Clean Bacteria: Giardia Lamblia";
        
		update well_pollution 
		set results = "Contaminated: Biological"
        where results = "clean"
			and biological > 0.01;
		
        -- checking if our errors are fixed
		SELECT *
		FROM well_pollution
		WHERE description LIKE "Clean_%"
			OR (results = "Clean" AND biological > 0.01);
            
		-- adding email address column
        update employee
        set email =
			Concat(lower(replace(employee_name, " ", ".")),"@ndogowater.gov");
            
		-- removing the extra space from the phone number
        update employee
        set phone_number = trim(phone_number);    
	
    -- Employees performance 
		-- Number of records per each employee
        select assigned_employee_id, count(visit_count) total_visits
		from visits
		group by assigned_employee_id
		order by total_visits desc;
        
        -- top three employees 
        select vis.assigned_employee_id, emp.employee_name, count(vis.visit_count) total_visits
		from visits vis join employee emp
			on vis.assigned_employee_id = emp.assigned_employee_id
		group by assigned_employee_id, emp.employee_name
		order by total_visits desc
		limit 3;
        
	-- Analysing locations
		-- Number of records per province and town
		select province_name, town_name, count(*) records_per_town
		from location
		group by province_name, town_name
        order by province_name, records_per_town desc;
        
        -- Number of records per location type
        select location_type, count(*) records_per_location_type
        from location
        group by location_type;
        
	-- Diving into the sources 
		-- total number of people served
        select sum(number_of_people_served) total_number_of_people_served
        from water_source;
        
        -- total number of different source types
		select type_of_water_source, count(*) total_number_of_each_water_source
		from water_source
        group by type_of_water_source
        order by total_number_of_each_water_source desc;
        
        -- average number of people served by each water source
        select type_of_water_source, round(avg(number_of_people_served), 0) avg_people_per_source
		from water_source
        group by type_of_water_source
        order by avg_people_per_source desc;
        
        -- percentage  of people served by each water source
		select type_of_water_source, round((sum(number_of_people_served)/(select sum(number_of_people_served) 
        from water_source)) * 100, 0) pct_of_people_per_source
		from water_source
        group by type_of_water_source
        order by pct_of_people_per_source desc;
        
        -- Rank each type of source based on how many people in total use it.
		select type_of_water_source, sum(number_of_people_served)  total_number_of_people_per_source,
				rank() over(order by sum(number_of_people_served) desc) ranking
		from water_source
		group by type_of_water_source;
        
        -- Ranking the water sources to know which one to fix first
		select source_id, type_of_water_source, number_of_people_served,
					rank() over(partition by type_of_water_source order by number_of_people_served desc) priority_rank
		from water_source
        group by source_id, type_of_water_source, number_of_people_served;
        
	-- Analysing queues
		-- Survey duration
        select min(time_of_record) first_date,
				max(time_of_record) last_date,
                timestampdiff(day, min(time_of_record), max(time_of_record)) survey_duration
		from visits;
        
        -- queueing average time in Maji Ndogo
        select round(avg(nullif((time_in_queue), 0)), 0) avg_time_in_queue
		from visits;
        
        -- queueing average by day
        select dayname(time_of_record) day_name,
			round(avg(nullif((time_in_queue), 0)), 0) avg_time_in_queue
		from visits
        group by day_name;
        
		-- queueing average by hour
        select time_format(time(time_of_record), "%H:00") hour_of_day,
			round(avg(nullif((time_in_queue), 0)), 0) avg_time_in_queue
		from visits
        group by hour_of_day
        order by hour_of_day;
        
        -- creating a pivot table of the average queueing time by hour day
        select
			concat(time_format((time_of_record), "%H"), "h") time_of_day,
			round(avg(case 
				when dayname(time_of_record) = "Monday" then time_in_queue else null end),0) Monday,
			round(avg(case 
				when dayname(time_of_record) = "Tuesday" then time_in_queue else null end),0) Tuesday,
			round(avg(case 
				when dayname(time_of_record) = "Wednesday" then time_in_queue else null end),0) Wednesday,
			round(avg(case 
				when dayname(time_of_record) = "Thursday" then time_in_queue else null end),0) Thursday,
			round(avg(case 
				when dayname(time_of_record) = "Friday" then time_in_queue else null end),0) Friday,
			round(avg(case 
				when dayname(time_of_record) = "Saturday" then time_in_queue else null end),0) Saturday,
			round(avg(case 
				when dayname(time_of_record) = "Sunday" then time_in_queue else null end),0) sunday	
		from visits
		where time_in_queue != 0
		group by time_of_day
        order by time_of_day;
	
    -- loading the auditor results files
	DROP TABLE IF EXISTS `auditor_report`; 
    CREATE TABLE `auditor_report`(
		`location_id`VARCHAR(32), 
        `type_of_water_source` VARCHAR(64), 
        `true_water_source_score` int DEFAULT NULL, 
        `statements` VARCHAR(255));
        
        -- Check if the auditor's and exployees' scores agree
        select count(*)
        from (select ar.location_id, 
			wq.record_id, 
			ar.true_water_source_score auditor_score, 
			wq.subjective_quality_score surveyor_score
		from auditor_report ar join visits vis
			on ar.location_id = vis.location_id
			join water_quality wq on wq.record_id = vis.record_id
			where ar.true_water_source_score = wq.subjective_quality_score and vis.visit_count = 1) good_results;
		
        -- retrieving the incorrect records
       select ar.location_id, 
			wq.record_id,
            emp.employee_name,
			ar.true_water_source_score auditor_score, 
			wq.subjective_quality_score surveyor_score,
            ar.type_of_water_source
		from auditor_report ar join visits vis
			on ar.location_id = vis.location_id
			join water_quality wq on wq.record_id = vis.record_id
            join employee emp on emp.assigned_employee_id = vis.assigned_employee_id
			where ar.true_water_source_score <> wq.subjective_quality_score and vis.visit_count = 1; 
            
		-- creating incorrect records table
        create table incorrect_records as 
        (select ar.location_id, 
			wq.record_id,
            emp.employee_name,
			ar.true_water_source_score auditor_score, 
			wq.subjective_quality_score surveyor_score,
            ar.type_of_water_source
		from auditor_report ar join visits vis
			on ar.location_id = vis.location_id
			join water_quality wq on wq.record_id = vis.record_id
            join employee emp on emp.assigned_employee_id = vis.assigned_employee_id
			where ar.true_water_source_score <> wq.subjective_quality_score and vis.visit_count = 1);
         
         -- Number of mistakes made by each employee
         select employee_name, count(*) number_of_mistakes
         from incorrect_records
         group by employee_name
         order by number_of_mistakes desc;
         
         -- Average number of misakes
         select avg(number_of_mistakes)
         from (select employee_name, count(*) number_of_mistakes
         from incorrect_records
         group by employee_name
         order by number_of_mistakes desc) error_count;
         
         -- employees with a number of mistakes more than the average
         create view suspect_list as
         (select employee_name, number_of_mistakes
         from (select employee_name, count(*) number_of_mistakes
				 from incorrect_records
				 group by employee_name) error_count
		group by employee_name
        having number_of_mistakes > (select avg(number_of_mistakes)
         from (select employee_name, count(*) number_of_mistakes
         from incorrect_records
         group by employee_name
         order by number_of_mistakes desc) error_count));
         
         -- adding statement column to the incorrect records
		select ir.employee_name, ir.location_id, ar.statements
		from incorrect_records ir join auditor_report ar
			on ir.location_id = ar.location_id
		where ir.employee_name in (select employee_name from suspect_list);
        
        -- records mentioning cthe word "cash"
        select ir.employee_name, ir.location_id, ar.statements
		from incorrect_records ir join auditor_report ar
			on ir.location_id = ar.location_id
		where ar.statements like "%cash%";
		
	-- starting the final journey
		-- finding the data we need across tables
        create view combined_data_table as (
        select loc.province_name, loc.town_name, loc.location_type, 
		ws.type_of_water_source, ws.number_of_people_served, vis.time_in_queue, wp.results
		from location loc join visits vis
			on loc.location_id = vis.location_id
			join water_source ws on ws.source_id = vis.source_id
			left join well_pollution wp on wp.source_id = vis.source_id
		WHERE vis.visit_count = 1);
        
        -- creating a pivot table of the perecentage of people served by each water source in each province
		WITH province_totals AS (
		Select province_name, SUM(number_of_people_served) total_ppl_serv 
		FROM combined_data_table
		GROUP BY province_name)
		SELECT ct.province_name,
		ROUND((SUM(CASE WHEN type_of_water_source = 'river' THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap' THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home' THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken' THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'well' THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
		FROM combined_data_table ct
		JOIN province_totals pt ON ct.province_name = pt.province_name
		GROUP BY ct.province_name
		ORDER BY ct.province_name;
        
        -- creating a pivot table of the perecentage of people served by each water source in each town
		create view town_aggregated_water_access as(
        WITH town_totals AS (
		Select province_name, town_name, SUM(number_of_people_served) total_ppl_serv 
		FROM combined_data_table
		GROUP BY province_name, town_name)
		SELECT ct.province_name, ct.town_name,
		ROUND((SUM(CASE WHEN type_of_water_source = 'river' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken, 
		ROUND((SUM(CASE WHEN type_of_water_source = 'well' THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
		FROM combined_data_table ct
		JOIN town_totals tt ON ct.province_name = tt.province_name and ct.town_name = tt.town_name
		GROUP BY ct.province_name, ct.town_name
		ORDER BY ct.province_name);
        
        -- Ratio of people who have taps but have no running water
        SELECT province_name, town_name, 
			ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
		FROM town_aggregated_water_access;
        
	-- practical plan
		-- sources to improve
       Create view sources_to_improve as 
       (SELECT
			location.address, location.town_name, location.province_name, water_source.source_id,
			water_source.type_of_water_source, well_pollution.results, visits.time_in_queue
		FROM water_source
			LEFT JOIN well_pollution ON water_source.source_id = well_pollution.source_id
			INNER JOIN visits ON water_source.source_id = visits.source_id
			INNER JOIN location ON location.location_id = visits.location_id
		WHERE visits.visit_count = 1 
			AND (well_pollution.results != 'Clean'
			OR type_of_water_source IN ('tap_in_home_broken','river') 
			OR (type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)));
            
		-- create project progress table
        CREATE TABLE Project_progress (
		Project_id SERIAL PRIMARY KEY,
		source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE, Address VARCHAR(50),
		Town VARCHAR(30),
		Province VARCHAR(30),
		Source_type VARCHAR(50),
		Improvement VARCHAR(50),
		Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')), Date_of_completion DATE,
		Comments TEXT);
        
        -- types of improvement for each source type
        select *,
			(case
				when type_of_water_source = "river" then "Drill wells" 
				when type_of_water_source = "well" and results = "contaminated: chemical" then "Install RO filter" 
				when type_of_water_source = "well" and results = "contaminated: biological" then "Install UV and RO filter"
				when type_of_water_source = "tap_in_home_broken"  then "Diagnose local infrastructure"
				WHEN type_of_water_source = "shared_tap" THEN CONCAT("Install ", FLOOR(time_in_queue / 30), " taps nearby")
				else null end) improvement
		from sources_to_improve;
        
        -- inserting values in project progress table
        insert into Project_progress (address, town, province, source_id, source_type, improvement)
		select address, town_name, province_name, source_id, type_of_water_source,
			(case
				when type_of_water_source = "river" then "Drill wells" 
				when type_of_water_source = "well" and results = "contaminated: chemical" then "Install RO filter" 
				when type_of_water_source = "well" and results = "contaminated: biological" then "Install UV and RO filter"
				when type_of_water_source = "tap_in_home_broken"  then "Diagnose local infrastructure"
				WHEN type_of_water_source = "shared_tap" THEN CONCAT("Install ", FLOOR(time_in_queue / 30), " taps nearby")
				else null end) improvement
		from sources_to_improve;
        
        
        
        
        
        
        
        
        
            
		