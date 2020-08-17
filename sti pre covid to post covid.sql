declare @Start_Date date = (select dateadd(day, -146, '20200315'))
declare @End_Date date = '20200808'

select @Start_date 

drop table #a1, #lab1

SELECT	distinct 		
		lm.location_name, 
		pe.enc_id, 
		pe.person_id, 
		p.sex, 
		pp.service_item_id, 
		cast(pe.create_timestamp as date) DOS,
		p.date_of_birth
INTO #a1 --drop table #enc
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe
	on pp.enc_id = pe.enc_id
join ngprod.dbo.location_mstr lm on pe.location_id = lm.location_id
JOIN ngprod.dbo.person p 
	on pp.person_id= p.person_id
WHERE  (cast(pe.create_timestamp as date) between  @Start_Date and @End_Date) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (lm.location_name <> 'PPPSW Lab' and lm.location_name <> 'Clinical Services Planned Parenthood')

alter table #a1 
add age int, 
	age_group varchar(100), 
	dateRange varchar(20), 
	event_type varchar(1000), 
	broadDateRange varchar(100),
	tabOrder int


update #a1
set event_type = ev.event
from #a1 l 
join ngprod.dbo.appointments a on l.enc_id = a.enc_id 
join ngprod.dbo.events ev on ev.event_id = a.event_id 


update #a1 
set age =  CAST((CONVERT(INT,CONVERT(CHAR(8),DOS,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)

UPDATE #a1
SET age_group =
	(
		CASE
			WHEN age BETWEEN 1  AND 17 THEN '<18'
			WHEN age BETWEEN 18 AND 24 THEN '18-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			WHEN age BETWEEN 30 AND 34 THEN '30-34'
			WHEN age BETWEEN 35 AND 49 THEN '35-49'
			WHEN age >= 50 THEN '>50'
		END
	)

update #a1 
set dateRange= 'pre-Covid19'
where DOS between (select dateadd(day, -146, '20200315')) and '20200314'

update #a1 
set dateRange= 'post-Covid19'
where DOS between '20200315' and '20200808'
and location_name != 'Telehealth' and (event_type not in (
	'Telehealth GAHT Follow Up',
	'Telehealth MAB F/U',
	'Telehealth FP F/U',
	'Telehealth Procedure F/U',
	'Telehealth Pick-Up F/U',
	'Telehealth MA F/U'
) or event_type is null)

update #a1 
set dateRange= 'Telehealth'
where DOS between '20200315' and '20200808'
and location_name = 'Telehealth'


update #a1 
set dateRange= 'Telehealth Follow-Up'
where DOS between '20200315' and '20200808'
and event_type in (
	'Telehealth GAHT Follow Up',
	'Telehealth MAB F/U',
	'Telehealth FP F/U',
	'Telehealth Procedure F/U',
	'Telehealth Pick-Up F/U',
	'Telehealth MA F/U'

)


update #a1 
set broadDateRange = 'Pre-Covid19' 
where DOS between (select dateadd(day, -146, '20200315')) and '20200314'

update #a1 
set broadDateRange= 'post-Covid19'
where DOS between '20200315' and '20200808'


update #a1 
set tabOrder = 1 
where dateRange = 'pre-Covid19'

update #a1 
set tabOrder = 2 
where dateRange = 'post-Covid19'

update #a1 
set tabOrder = 3 
where dateRange = 'Telehealth'

update #a1 
set tabOrder = 4 
where dateRange = 'Telehealth Follow-Up'



drop table #lab1
select distinct pe.person_id, 				
				nor.enc_id,
				obr.test_desc, -- test description
				obx.obs_id,
				obx.observ_value, -- result
				obx.result_desc -- Quest result							
into #lab1			
from #a1 a
join ngprod.dbo.lab_nor nor on a.enc_id = nor.enc_id
join ngprod.dbo.patient_encounter pe on nor.enc_id=pe.enc_id
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_Num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
join ngprod.dbo.person p on p.person_id=pe.person_id
where nor.delete_ind <> 'Y' and 					
		nor.ngn_status != 'Cancelled'	and 
		nor.test_status != 'Cancelled'	and 
		p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult') and
		((obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) or 
		  (obx.obs_id like '%rpr%') or 
		  (obx.result_desc like '%hiv%') or 
		  	(obx.obs_id like '%trich%') 
		  ) 

alter table #a1
add RFV1 varchar(1000), 	
	New_or_Est_Pt varchar(500),	
	GC_CT varchar(20), 
	RPR varchar(20), 
	hiv varchar(20), 
	trich varchar(20),
	enc_concern varchar(1000)
	
update #a1 
set RFV1 = m.chiefcomplaint1
from #a1 a
join ngprod.dbo.master_im_ m on m.enc_id=a.enc_id 
where dateRange !='Telehealth'

update #a1 
set RFV1 = m.chiefcomplaint2
from #a1 a
join ngprod.dbo.master_im_ m on m.enc_id=a.enc_id 
where dateRange ='Telehealth'

update #a1 
set New_or_Est_Pt = 'Est' 
from #a1 a 
join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
where m.newEstablished = 2

update #a1 
set New_or_Est_Pt = 'New' 
from #a1 a 
join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
where m.newEstablished = 1

update #a1 
set GC_CT = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.result_desc LIKE '%GC%' OR l.result_desc = 'CT' or l.result_desc like '%TRACHOMATIS%' OR l.obs_id like '%Gonor%' OR l.obs_id like '%Chlam%' )
and dateRange !='Telehealth'

update #a1 
set GC_CT = 'N'
from #a1 a 
where GC_CT is null

update #a1 
set rpr = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.obs_id like '%rpr%' )

update #a1 
set rpr = 'N'
from #a1 a 
where rpr is null

update #a1 
set hiv = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.result_desc like '%hiv%' )

update #a1 
set hiv = 'N'
from #a1 a 
where hiv is null

update #a1 
set trich = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.obs_id like '%trich%' )

update #a1 
set trich = 'N'
from #a1 a 
where trich is null

update #a1 
set enc_concern = h.txt_cc
from #a1 a 
join ngprod.dbo.hpi_female_urogenital_ h on a.enc_id = h.enc_id
and sex = 'f'

update #a1 
set enc_concern = h.txt_concern
from #a1 a 
join ngprod.dbo.hpi_male_urogenital_ h on a.enc_id = h.enc_id
and sex = 'm'



select a.broadDateRange, count(distinct a.enc_id) countGCCT, r.totalVisits, count(distinct a.enc_id) * 1.0/r.totalVisits
from #a1 a
join (select broadDateRange, count(distinct enc_id) totalVisits
		from #a1
		group by broadDateRange) r on r.broadDateRange=a.broadDateRange
where trich ='Y'
group by a.broadDateRange, r.totalVisits

select a.tabOrder, a.dateRange, t.countVisits countGCCT,count(distinct a.enc_id) countVisits, t.countVisits * 1.0 / count(distinct a.enc_id) 
from #a1 a
left join (select tabOrder, dateRange, count(distinct enc_id) countVisits
			from #a1
			where trich = 'y'
			group by tabOrder, dateRange) t on t.tabOrder = a.tabOrder and a.dateRange = t.dateRange
group by a.tabOrder, a.dateRange, t.countVisits
order by a.tabOrder


alter table #a1
add msm varchar(20), --risk
	new_partner varchar(20),  --risk
	multi_partners varchar(20), --risk
	partner_not_monog varchar(20), --risk
	sexual_favors varchar(20), --risk
	risk varchar(20), --risk
	current_sexual_activity varchar(500), --sexualActivity
	Anal_insertive VARCHAR (1), --sexualActivity
	Anal_receptive VARCHAR (1), --sexualActivity
	oral_insertive VARCHAR (1), --sexualActivity
	oral_receptive VARCHAR (1), --sexualActivity
	vaginal_insertive VARCHAR (1), --sexualActivity
	vaginal_receptive VARCHAR (1),  --sexualActivity
	mrgcct date, --Most Recent GCCT
	gcct_within_12mo varchar(20),  --GCCT within 12 mo
	appropriate varchar(50) --Apppropriate testing based on risk and sexual activity

alter table #a1
add Rectal_swab VARCHAR (20),
	Pharyngeal_swab VARCHAR (20),
	Urine_sample VARCHAR (20),
	Vaginal_swab VARCHAR (20)

/* Risk Factors */

update #a1
set msm = 'y'
from #a1 a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where a.sex='m' 
and opt_sexual_partners = '1'
and a.DOS <='20181031'

update #a1
set msm = 'y'
from #a1 a 
join ngprod.dbo.psw_hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1'
and a.DOS >'20181031'

update #a1
set msm = 'n'
where msm is null

update #a1
set new_partner = 'y'
from #a1 a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_new_partner = '2'

update #a1
set new_partner = 'n'
where new_partner is null

update #a1
set multi_partners = 'y'
from #a1 a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_multiple_partners = '2'

update #a1
set multi_partners = 'n'
where multi_partners is null

update #a1
set partner_not_monog = 'y'
from #a1 a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_partner_monogomous = '1'

update #a1
set partner_not_monog = 'n'
where partner_not_monog is null

update #a1
set sexual_favors = 'y'
from #a1 a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_sexual_favors = '2'

update #a1
set sexual_favors = 'n'
from #a1 a 
where sexual_favors is null


/* Current Sexual Activity */

update #a1
set current_sexual_activity = txt_current_sexual_activity
from #a1 a
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id

UPDATE #a1 
SET anal_insertive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%anal insertive%'

--anal receptive
UPDATE #a1
SET anal_receptive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%anal receptive%'

--Female anal receptive
UPDATE #a1 
SET anal_receptive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%anal%' and
a.sex = 'f'

--Oral insertive
UPDATE #a1 
SET oral_insertive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%oral insertive%'

--Oral receptive
UPDATE #a1 
SET oral_receptive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%oral Receptive%'

--vaginal receptive
UPDATE #a1 
SET Vaginal_receptive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%vaginal%' AND sex = 'f'

--vaginal insertive
UPDATE #a1 
SET vaginal_insertive = 'Y' 
FROM #a1 a
WHERE current_sexual_activity LIKE '%vaginal%' AND sex = 'm'

/* Test Source */

--Rectal Swab
UPDATE #a1 
SET rectal_swab = 'Y' 
FROM #a1 a
JOIN ngprod.dbo.lab_nor nor ON nor.enc_id = a.enc_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE (aoe.test_data_value LIKE '%Rectal%'  and aoe.test_data_value not like '%pregnant%')
/*AND CONVERT(date,a.DOS) = CONVERT(date,lot.collectiON_time) */
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 

--Pharyngeal Swab
UPDATE #a1 
SET pharyngeal_swab = 'Y' 
FROM #a1 a
JOIN ngprod.dbo.lab_nor nor ON nor.enc_id = a.enc_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE (aoe.test_data_value LIKE '%Pharyngeal%' and aoe.test_data_value not like '%pregnant%')
--AND CONVERT(date,a.DOS) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 


--Urine
UPDATE #a1 
SET urine_sample = 'Y' 
FROM #a1 a
JOIN ngprod.dbo.lab_nor nor ON nor.enc_id = a.enc_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE (aoe.test_data_value LIKE '%Urine%' and aoe.test_data_value not like '%pregnant%')
--AND CONVERT(date,a.DOS) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status LIKE 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 

--Vaginal Swab
UPDATE #a1 
SET vaginal_swab = 'Y' 
FROM #a1 a
JOIN ngprod.dbo.lab_nor nor ON nor.enc_id = a.enc_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE (aoe.test_data_value LIKE '%Vaginal%'and aoe.test_data_value not like '%pregnant%')
--AND CONVERT(date,a.DOS) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 


/* Most Recent GC/CT Test */

drop table #mr_gcct_test

SELECT a.persoN_id, MAX(CONVERT(date,lot.collection_time)) AS 'lastgccttest'
into #mr_gcct_test
						FROM #a1 a
						JOIN ngprod.dbo.lab_nor nor ON nor.person_id = a.person_id
						JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
						JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
						join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
						join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
						WHERE CONVERT(date,a.DOS) > CONVERT(date,lot.collection_time)
						AND nor.ngn_status = 'Signed-Off'
						and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 
						GROUP BY a.person_id 
		



update #a1
set mrgcct = lastgccttest
from #a1 a
join #mr_gcct_test r on a.person_id=r.person_id 

update #a1
set gcct_within_12mo  = 'y'
where datediff(d, mrgcct, DOS) <=366

update #a1
set gcct_within_12mo = 'n'
where gcct_within_12mo is null

/* Risk Level */

update #a1
set risk = 'y'
where  
	new_partner ='y' or 
	multi_partners ='y' or  
	partner_not_monog ='y' or  
	sexual_favors ='y' or 
	gcct_within_12mo = 'n'

update #a1
set risk = 'n'
where risk is null



--***Begin appropriate Testing section***

--Male Insertive ONly
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or [oral_insertive] = 'y') --***Add oral insert??***
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

--Male Insertive AND anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Male Insertive AND anal AND oral receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] = 'y'
AND [Pharyngeal_swab] = 'y' AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Male Insertive AND oral receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] ='y' AND [Vaginal_swab]  IS NULL AND Urine_sample ='y' AND Rectal_swab IS NULL

--Female Vaginal receptive or oral insertive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f' 
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL AND ([vaginal_receptive] = 'Y' or oral_insertive = 'y')
AND [Rectal_swab] IS NULL AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y')

--Male Anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL

--Male Oral receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL

--Female Oral AND Vaginal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab IS NULL

--Female Oral AND Vaginal AND anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab = 'Y'

--Male Oral AND anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'M' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral AND anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'

--Vaginal AND anal receptive
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f'
AND [oral_receptive] IS NULL AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab = 'Y'


--Female No sexual activity but tested
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'f' 
AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab IS NULL

--Male No sexual activity but tested
UPDATE #a1
SET appropriate = 'Y'
FROM #a1
WHERE sex = 'm' 
AND [oral_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [oral_insertive] IS NULL AND [Anal_insertive] IS NULL AND [vaginal_insertive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab] IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

drop table #mrEnc
select a.*
into #mrEnc
from #a1 a 
join (select dateRange, persoN_id, max(DOS) maxDOS
		from #a1
		group by dateRange, persoN_id) g on a.person_id = g.persoN_id and a.DOS = g.maxDOS and a.dateRange = g.dateRange


/************************** Age Group *****************************************/

drop table #ageGroup
select a.tabOrder, 
		a.dateRange, 
		a.age_group, 
		count(distinct a.person_id) countAgeGroup, 
		p.countTotalPatients, 
		count(distinct a.persoN_id) * 1.0 / p.countTotalPatients percAgeGroup
into #ageGroup
from #mrEnc a 
join (select dateRange, count(distinct person_id) countTotalPatients
		from #mrEnc
		group by dateRange) p on a.dateRange = p.dateRange
group by a.tabOrder, a.dateRange, a.age_group,p.countTotalPatients


alter table #ageGroup
add [<18] int, 
	[18-24] int, 
	[25-29] int, 
	[30-34] int, 
	[35-49] int, 
	[> 50] int, 
	[TotalPatients] int

update #ageGroup
set [<18] = countAgeGroup
where age_group = '<18'


update #ageGroup
set [18-24] = countAgeGroup
where age_group = '18-24'

update #ageGroup
set [25-29] = countAgeGroup
where age_group = '25-29'


update #ageGroup
set [30-34] = countAgeGroup
where age_group = '30-34'

update #ageGroup
set [35-49] = countAgeGroup
where age_group = '35-49'

update #ageGroup
set [> 50] = countAgeGroup
where age_group = '>50'


update #ageGroup
set [TotalPatients] = countTotalPatients

alter table #ageGroup
add broadDateRange varchar(100)

update #ageGroup
set broadDateRange = 'Pre-Covid19' 
where dateRange = 'Pre-Covid19'


update #ageGroup
set broadDateRange = 'Post-Covid19' 
where tabOrder in (2,3,4)

select tabOrder, 
		dateRange, 
		max([<18]) [<18], 
		max([18-24]) [18-24],
		max([25-29]) [25-29],
		max([30-34]) [30-34],
		max([35-49]) [35-49],
		max([> 50]) [> 50],
		max([TotalPatients]) [TotalPatients],
		max([<18]) * 1.0 / max([TotalPatients]) percLT18,
		max([18-24]) * 1.0 / max([TotalPatients]) [perc18-24],
		max([25-29]) * 1.0 / max([TotalPatients]) [perc25-29],
		max([30-34]) * 1.0 / max([TotalPatients]) [perc30-34],
		max([35-49]) * 1.0 / max([TotalPatients]) [perc35-49],
		max([> 50]) * 1.0 / max([TotalPatients]) [perc > 50]
from #ageGroup
group by tabOrder, dateRange
order by tabOrder

/************************** Age Group w testing  *****************************************/

drop table #mrEncGCCT
select a.*
into #mrEncGCCT
from #a1 a 
join (select dateRange, persoN_id, max(DOS) maxDOS
		from #a1
		where gc_ct = 'y'
		group by dateRange, persoN_id) g on a.person_id = g.persoN_id and a.DOS = g.maxDOS and a.dateRange = g.dateRange

drop table #ageGroupGCCT
select p.tabOrder, 
		p.dateRange, 
		p.age_group, 
		count(distinct a.person_id) countAgeGroup, 
		p.countTotalPatients, 
		count(distinct a.persoN_id) * 1.0 / p.countTotalPatients percAgeGroup
into #ageGroupGCCT
from #mrEncGCCT a 
right join (select tabOrder,dateRange,age_group, count(distinct person_id) countTotalPatients
		from #mrEnc
		group by tabOrder, age_group,dateRange) p on a.tabOrder = p.tabOrder and a.dateRange = p.dateRange and a.age_group = p.age_group
group by p.tabOrder, p.dateRange, p.age_group,p.countTotalPatients



alter table #ageGroupGCCT
add [<18] int, 
	[18-24] int, 
	[25-29] int, 
	[30-34] int, 
	[35-49] int, 
	[> 50] int, 
	[TotalPatients <18] int,
	[TotalPatients 18-24] int, 
	[TotalPatients 25-29] int, 
	[TotalPatients 30-34] int, 
	[TotalPatients 35-49] int, 
	[TotalPatients > 50] int

update #ageGroupGCCT
set [<18] = countAgeGroup
where age_group = '<18'

update #ageGroupGCCT
set [18-24] = countAgeGroup
where age_group = '18-24'

update #ageGroupGCCT
set [25-29] = countAgeGroup
where age_group = '25-29'

update #ageGroupGCCT
set [30-34] = countAgeGroup
where age_group = '30-34'

update #ageGroupGCCT
set [35-49] = countAgeGroup
where age_group = '35-49'

update #ageGroupGCCT
set [> 50] = countAgeGroup
where age_group = '>50'


update #ageGroupGCCT
set [TotalPatients <18] = countTotalPatients
where age_group = '<18'

update #ageGroupGCCT
set [TotalPatients 18-24] = countTotalPatients
where age_group = '18-24'

update #ageGroupGCCT
set [TotalPatients 25-29] = countTotalPatients
where age_group = '25-29'

update #ageGroupGCCT
set [TotalPatients 30-34] = countTotalPatients
where age_group = '30-34'

update #ageGroupGCCT
set [TotalPatients 35-49] = countTotalPatients
where age_group = '35-49'

update #ageGroupGCCT
set [TotalPatients > 50] = countTotalPatients
where age_group = '>50'


select tabOrder, 
		dateRange, 
		max([<18]) [<18], 
		max([TotalPatients <18]) [TotalPatients <18],
		max([18-24]) [18-24],
		max([TotalPatients 18-24]) [TotalPatients 18-24],
		max([25-29]) [25-29],
		max([TotalPatients 25-29]) [TotalPatients 25-29],
		max([30-34]) [30-34],
		max([TotalPatients 30-34]) [TotalPatients 30-34],
		max([35-49]) [35-49],
		max([TotalPatients 35-49]) [TotalPatients 35-49],
		max([> 50]) [> 50],
		max([TotalPatients > 50]) [TotalPatients > 50],
		isnull(max([<18]) * 1.0,0) / max([TotalPatients <18]) percLT18,
		isnull(max([18-24]) * 1.0,0) / max([TotalPatients 18-24]) [perc18-24],
		isnull(max([25-29]) * 1.0,0) / max([TotalPatients 25-29]) [perc25-29],
		isnull(max([30-34]) * 1.0,0) / max([TotalPatients 30-34]) [perc30-34],
		isnull(max([35-49]) * 1.0,0) / max([TotalPatients 35-49]) [perc35-49],
		isnull(max([> 50]) * 1.0,0) / max([TotalPatients > 50]) [perc > 50]
from #ageGroupGCCT
group by tabOrder, dateRange
order by tabOrder



select broadDateRange, 		
		max([<18]) [<18], 
		max([TotalPatients <18]) [TotalPatients <18],
		max([18-24]) [18-24],
		max([TotalPatients 18-24]) [TotalPatients 18-24],
		max([25-29]) [25-29],
		max([TotalPatients 25-29]) [TotalPatients 25-29],
		max([30-34]) [30-34],
		max([TotalPatients 30-34]) [TotalPatients 30-34],
		max([35-49]) [35-49],
		max([TotalPatients 35-49]) [TotalPatients 35-49],
		max([> 50]) [> 50],
		max([TotalPatients > 50]) [TotalPatients > 50],
		isnull(max([<18]) * 1.0,0) / max([TotalPatients <18]) percLT18,
		isnull(max([18-24]) * 1.0,0) / max([TotalPatients 18-24]) [perc18-24],
		isnull(max([25-29]) * 1.0,0) / max([TotalPatients 25-29]) [perc25-29],
		isnull(max([30-34]) * 1.0,0) / max([TotalPatients 30-34]) [perc30-34],
		isnull(max([35-49]) * 1.0,0) / max([TotalPatients 35-49]) [perc35-49],
		isnull(max([> 50]) * 1.0,0) / max([TotalPatients > 50]) [perc > 50]
from #ageGroupGCCT
group by broadDateRange




/************************** Risk Patients *****************************************/


select a.tabOrder, a.dateRange, a.risk, count(distinct a.enc_id) countVisitsByRisk, p.countTotalVisits, count(distinct a.enc_id) * 1.0/ p.countTotalVisits
from #a1 a
join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange
where risk = 'y'
group by a.tabOrder, a.dateRange, a.risk,p.countTotalVisits
order by tabOrder


select p.tabOrder, p.dateRange, a.risk, count(distinct a.enc_id) countVisitsByRisk, p.countTotalVisits, count(distinct a.enc_id) * 1.0/ p.countTotalVisits
from #a1 a
right join (select tabOrder, dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		where risk = 'y'
		group by tabOrder, dateRange) p on a.dateRange = p.dateRange and a.tabOrder = p.tabOrder and a.risk = 'y' and a.gc_ct = 'y'
group by p.tabOrder, p.dateRange, a.risk,p.countTotalVisits
order by p.tabOrder

/************************** Sexual Activity *****************************************/

drop table #sex_activity
select  sexual_activity = 'anal insertive', 
		p.dateRange, 
		a.anal_insertive,
		count(distinct a.enc_id) anal_insertive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
into #sex_activity
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and anal_insertive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.anal_insertive
union 
select sexual_activity = 'anal receptive', 
		p.dateRange, 
		a.anal_receptive,
		count(distinct a.enc_id) anal_receptive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and anal_receptive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.anal_receptive
union 
select sexual_activity = 'oral insertive', 
		p.dateRange, 
		a.oral_insertive,
		count(distinct a.enc_id) oral_insertive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and oral_insertive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.oral_insertive
union 
select sexual_activity = 'oral receptive', 
		p.dateRange, 
		a.oral_receptive,
		count(distinct a.enc_id) oral_receptive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and oral_receptive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.oral_receptive
union 
select sexual_activity = 'vaginal_insertive', 
		p.dateRange, 
		a.vaginal_insertive,
		count(distinct a.enc_id) vaginal_insertive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and vaginal_insertive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.vaginal_insertive
union 
select sexual_activity = 'vaginal_receptive', 
		p.dateRange, 
		a.vaginal_receptive,
		count(distinct a.enc_id) vaginal_receptive_visits, 
		p.countTotalVisits, 
		count(distinct a.enc_id) * 1.0/ p.countTotalVisits percVisits
from #a1 a
right join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange and vaginal_receptive = 'y'
group by p.dateRange, 
		p.countTotalVisits,
		a.vaginal_receptive

alter table #sex_activity 
add tabOrder int

update #sex_activity
set tabOrder = 1 
where dateRange like '%pre%'

update #sex_activity
set tabOrder = 2
where dateRange like '%post%'

update #sex_activity
set tabOrder = 3
where dateRange ='Telehealth'

update #sex_activity
set tabOrder = 4
where dateRange like '%follow%'


drop table #sex_activity_gcct
select sexual_activity = 'anal receptive', dateRange,anal_receptive,  count(distinct enc_id) count_anal_receptive_gcct
into #sex_activity_gcct
from #a1 
where gc_Ct = 'y' and anal_receptive = 'y'
group by dateRange,anal_receptive
union 
select sexual_activity = 'anal insertive', dateRange,anal_insertive,  count(distinct enc_id) count_anal_insertive_gcct
from #a1 
where gc_Ct = 'y' and anal_insertive = 'y'
group by dateRange,anal_insertive
union 
select sexual_activity = 'oral insertive', dateRange,oral_insertive,  count(distinct enc_id) count_oral_insertive_gcct
from #a1 
where gc_Ct = 'y' and oral_insertive = 'y'
group by dateRange,oral_insertive
union 
select sexual_activity = 'oral receptive', dateRange,oral_receptive,  count(distinct enc_id) count_oral_receptive_gcct
from #a1 
where gc_Ct = 'y' and oral_receptive = 'y'
group by dateRange,oral_receptive
union 
select sexual_activity = 'vaginal_insertive', dateRange,vaginal_insertive,  count(distinct enc_id) count_vaginal_insertive_gcct
from #a1 
where gc_Ct = 'y' and vaginal_insertive = 'y'
group by dateRange,vaginal_insertive
union 
select sexual_activity = 'vaginal_receptive', dateRange,vaginal_receptive,  count(distinct enc_id) count_vaginal_receptive_gcct
from #a1 
where gc_Ct = 'y' and vaginal_receptive = 'y'
group by dateRange,vaginal_receptive



select s.*, ar.count_anal_receptive_gcct, ar.count_anal_receptive_gcct * 1.0/ s.anal_insertive_visits percTestedSexualActivity
from #sex_activity s
left join #sex_activity_gcct ar on s.sexual_activity = ar.sexual_activity and s.dateRange = ar.dateRange
order by sexual_activity, tabOrder

/************************** Appropriate Testing*****************************************/

select a.dateRange, a.appropriate, count(distinct a.enc_id), p.countTotalVisits, count(distinct a.enc_id) * 1.0/p.countTotalVisits
from #a1 a
join (select dateRange, count(distinct enc_id) countTotalVisits
		from #a1
		group by dateRange) p on a.dateRange = p.dateRange
where a.appropriate = 'y'
group by a.dateRange, a.appropriate, p.countTotalVisits


select t.tabOrder, t.dateRange, t.rfv1, t.enc_concern, count(distinct a.enc_id), t.countVisits, count(distinct enc_id) * 1.0 /t.countVisits
from #a1 a
right join (select tabOrder, dateRange, rfv1, enc_concern, count(distinct enc_id) countVisits
		from #a1
		where rfv1 like '%gyn complaint%' and enc_concern like '%vaginal discharge%' 
		group by tabOrder, dateRange,rfv1, enc_concern) t on t.tabOrder = a.tabOrder and t.dateRange = a.dateRange and  a.rfv1 like '%gyn complaint%' and a.enc_concern like '%vaginal discharge%' 
and gc_ct ='n' 
group by t.tabOrder, t.dateRange, t.rfv1, t.countVisits, t.enc_concern
order by tabOrder

select distinct enc_concern, count(distinct enc_id)
from #a1
group by enc_concern
order by count(distinct enc_id) desc 

----drop table #app_gcct
--select a.qtr,a.qtr_begin_date, a.qtr_end_date,  tier = null,count(distinct a.persoN_id) numeratorAppGCCT, c.countRisk, count(distinct a.person_id) * 1.0/c.countRisk percAppGCCT
--into #app_gcct
--from #a1 a
--join (select qtr, count(distinct person_id) countRisk
--		from #a1
--		where risk='y'
--		group by qtr		
--	) c on a.qtr=c.qtr 
--join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = a.qtr_begin_date
--where risk='y' and appropriate='y'
--group by a.qtr, c.countRisk,a.qtr_begin_date, a.qtr_end_date
