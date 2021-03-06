USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[Holistic_Report_New]    Script Date: 4/8/2020 1:29:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER proc [dbo].[Holistic_Report_New]
--(
--	@Start_date date, 
--	@End_Date date-- End of date range 
--)

AS

/*
Tier 1 = IUC, Implant
- Implant
- IUC (Levonorgestrel)
- IUC (Copper)
Tier 2 = Oral, Injection, Patch, Ring
- Oral (CHC)
- Injection
- Ring
- Patch
- Oral (POP)
*/

declare @Start_Date datetime = DATEADD(d, -730, GETDATE())
declare @End_Date datetime = DATEADD(d, 365, GETDATE())

--declare @start_Date date = '20190901'
--declare @end_Date date = '20190930'



/*
#bci_meas,#bci_prev_meas,#lr_3mo,#lr_12mo,#bci_mab_ab,#bci_tab_ab_meas,#abRate1Yr,#app_gcct, #tmt_gcct,#ab_lr_3mo,#ab_lr_12mo,#r_abRate1Yr,#co_fup,#pap_fup
*/

--drop table #a1, #bc_prev, #bc_prev_num, #bc_prev_denom, #ab, #dq1
--drop table #bc_incidence
--drop table #bci_ab, #bci_tab,#bci_mab, #d1, #d2, #d3, #d4, #d5, #d6, #d7, #d8, #d8_1, #d8_2, #d8_3, #bci_mab2, #d9, 
--	#f1, #f2, #f3, #bci_mab3
--drop table #larc_removals, #larc_removals1, #larc3m_removal, #larc12m_removal, #larc3m_removal_rate, #larc12m_removal_rate, #larc_inserts, #lr1, #lr2, #lr3, #lr4, #lr_3mo,#lr_12mo
--drop table #bci_prev_meas, #bci_prev_meas1, #bci_meas, #bci_mab_ab, #bci_tab_ab_meas,#larc_3m_removal_rate
--drop table #combine_measures
--drop table #most_recent_qtr, #prior_qtr, #q4,  #fulltab
--drop table #abVisit,#nonAB_toAB,#abRate1Yr,#abr,#pme
--drop table #a_gcct, #mr_gcct_test, #app_gcct
--drop table #c1_1, #c1,#c2,#c3,#c4,#pregQ1, #abVis,#ab_max,#abRate1Yr
--drop table #gt, #gt1, #tmt_gcct
--drop table #ab_larc_removals, #ab_larc_removals1, #ab_larc3m_removal, #ab_larc12m_removal, #ab_larc3m_removal_rate, #ab_larc12m_removal_rate, #ab_larc_inserts, #ab_lr1, #ab_lr2, #ab_lr3, #ab_lr4, #ab_lr_3mo,#ab_lr_12mo
--drop table #r1, #r2, #r3, #r4, #r_abRate1Yr, #r_ab_max
--drop table #colpo1, #colpo2, #co_fup
--drop table #PapFollowUp, #pap2, #pap_fup
--drop table #appt, #appt_mab, #appt_5tab, #appt_7tab
--drop table #combine_tables


SELECT	distinct 
		pp.enc_id, 
		pp.person_id, 
		p.sex, 
		pp.service_item_id, 
		pp.service_date, 
		p.date_of_birth, 
		im.txt_birth_control_visitend AS 'BCM'
INTO #a1 --drop table #enc
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe
	on pp.enc_id = pe.enc_id
join ngprod.dbo.location_mstr lm on pe.location_id = lm.location_id
JOIN ngprod.dbo.person p 
	on pp.person_id= p.person_id
LEFT JOIN ngprod.dbo.master_im_ im 
	on im.enc_id = pe.enc_id
WHERE  (pp.service_date >= @Start_Date AND pp.service_date <= @End_Date) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
--AND p.sex = 'F'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND lm.location_name IN (
							
						)


alter table #a1
add qtr varchar(20), 
	qtr_begin_date date, 
	qtr_end_date date, 
	age int, 
	qYr varchar(10),
	qNum int



--declare @Start_Date datetime = DATEADD(d, -730, GETDATE())
--declare @End_Date datetime = DATEADD(d, 365, GETDATE())


update #a1
set qtr = concat('Y', datepart(yy, service_date), 'Q1')
where datepart(m,service_date) between 1 and 3
--and service_date >= @Start_Date


update #a1
set qtr = concat('Y', datepart(yy, service_date), 'Q2')
where datepart(m,service_date) between 4 and 6
--and service_date >= @Start_Date

update #a1
set qtr = concat('Y', datepart(yy, service_date), 'Q3')
where datepart(m,service_date) between 7 and 9
--and service_date >= @Start_Date

update #a1
set qtr = concat('Y', datepart(yy, service_date), 'Q4')
where datepart(m,service_date) between 10 and 12
--and service_date >= @Start_Date

update #a1
set qtr_begin_date = datefromparts(datepart(year, service_date), 1,1) 
where datepart(month, service_date) between 1 and 3

update #a1
set qtr_end_date = datefromparts(datepart(year, service_date), 3,31) 
where datepart(month, service_date) between 1 and 3

update #a1
set qtr_begin_date = datefromparts(datepart(year, service_date), 4,1) 
where datepart(month, service_date) between 4 and 6

update #a1
set qtr_end_date = datefromparts(datepart(year, service_date), 6,30) 
where datepart(month, service_date) between 4 and 6

update #a1
set qtr_begin_date = datefromparts(datepart(year, service_date), 7,1) 
where datepart(month, service_date) between 7 and 9

update #a1
set qtr_end_date = datefromparts(datepart(year, service_date), 9,30) 
where datepart(month, service_date) between 7 and 9

update #a1
set qtr_begin_date = datefromparts(datepart(year, service_date), 10,1) 
where datepart(month, service_date) between 10 and 12

update #a1
set qtr_end_date = datefromparts(datepart(year, service_date), 12,31) 
where datepart(month, service_date) between 10 and 12

update #a1
set age =  CAST((CONVERT(INT,CONVERT(CHAR(8),service_date,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)



update #a1
set qNum = 1
where datepart(month, service_date) between 1 and 3

update #a1
set qNum = 2
where datepart(month, service_date) between 4 and 6

update #a1
set qNum = 3
where datepart(month, service_date) between 7 and 9

update #a1
set qNum = 4
where datepart(month, service_date) between 10 and 12

update #a1
set qYr = datepart(year, service_date)

--drop table #ab
--***Find all AB related visits during report period***
SELECT DISTINCT person_id, service_date, enc_id-- drop table #ab
INTO #ab
FROM #a1
WHERE 
   (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
OR	 Service_Item_id = '99214PME'
	)
and sex='f'
GROUP BY  person_id, service_date, enc_id


select distinct  qNum, qYr, concat('Q',qNum, ' ',qYr) period
into #dq1
from #a1

alter table #dq1
add begin_date date, 
	end_date date, 
	qtr_begin varchar(50), 
	qtr_end varchar(50)

update #dq1
set begin_date = datefromparts(qYr, 1,1)
where qNum =1

update #dq1
set end_date = datefromparts(qYr, 3,31)
where qNum =1

update #dq1
set begin_date = datefromparts(qYr, 4,1)
where qNum =2

update #dq1
set end_date = datefromparts(qYr, 6,30)
where qNum =2

update #dq1
set begin_date = datefromparts(qYr, 7,1)
where qNum =3

update #dq1
set end_date = datefromparts(qYr, 9,30)
where qNum =3

update #dq1
set begin_date = datefromparts(qYr, 10,1)
where qNum =4

update #dq1
set end_date = datefromparts(qYr, 12,31)
where qNum =4

update #dq1
set qtr_begin = 'Q0_begin'
where begin_date = (
 select distinct cast(dateadd(month, -12, (select max(begin_date) from #dq1)) as date)
							from #dq1 )

update #dq1
set qtr_end = 'Q0_end'
where end_date = (select distinct cast(dateadd(month, -12, (select max(end_date) from #dq1)) as date)
							from #dq1 ) 

update #dq1
set qtr_begin = 'Q1_begin'
where begin_date = (
 select distinct cast(dateadd(month, -9, (select max(begin_date) from #dq1)) as date)
							from #dq1 )

update #dq1
set qtr_end = 'Q1_end'
where end_date = (select distinct cast(dateadd(month, -9, (select max(end_date) from #dq1)) as date)
							from #dq1 ) 

update #dq1
set qtr_begin = 'Q2_begin'
where begin_date = (select distinct cast(dateadd(month, -6, (select max(begin_date) from #dq1)) as date)
							from #dq1 ) 

update #dq1
set qtr_end = 'Q2_end'
where end_date = (select distinct cast(dateadd(month, -6, (select max(end_date) from #dq1)) as date)
							from #dq1 ) 


update #dq1
set qtr_begin = 'Q3_begin'
where begin_date = (select distinct cast(dateadd(month, -3, (select max(begin_date) from #dq1)) as date)
							from #dq1 ) 

update #dq1
set qtr_end = 'Q3_end'
where end_date = (select distinct cast(dateadd(month, -3, (select max(end_date) from #dq1)) as date)
							from #dq1 ) 

update #dq1
set qtr_begin = 'Q4_begin'
where begin_date =  (select max(begin_date) from #dq1)

update #dq1
set qtr_end = 'Q4_end'
where end_date = (select max(end_date) from #dq1)



/*#######################################BC INCIDENCE#####################################################################*/

--drop table #bc_incidence

select *
into #bc_incidence
from #a1
where age between 15 and 44 and sex='f'

delete from #bc_incidence 
where bcm in 
(
 'Pregnant/Partner Pregnant'
,'Seeking pregnancy'
,'Female Sterilization'
,'Vasectomy'
,'Infertile'
,'Same sex partner'
)

alter table #bc_incidence
add ab_visit varchar(20), 
 refill varchar(50), 
 tier int

update #bc_incidence
set ab_visit = 'yes'
from #bc_incidence b
join (select person_id, service_date 
		from #ab		
	) ab on ab.person_id=b.person_id and ab.service_date=b.service_date

delete from #bc_incidence
where ab_visit='yes'

alter table #bc_incidence
drop column ab_visit


update #bc_incidence
set refill = 'yes'
from #bc_incidence b
join (select person_id, service_date 
		from #bc_incidence 
		where Service_Item_id in (
			'99499', -- refill
			'96372' -- depo 
		)
	) r on r.person_id=b.person_id and r.service_date=b.service_date

delete from #bc_incidence
where refill='yes'

alter table #bc_incidence
drop column refill

update #bc_incidence
set tier = 2
where service_item_id in (
		'AUBRA',
		'AUBRAEQ',
		'Brevicon',
		'CHATEAL',
		'CHATEALEQ',
		'Cyclessa',
		'CyclessaNC',
		'CYRED',
		'CYREDEQ',
		'Desogen',
		'DesogenNC',
		'Gildess',
		'Levora',
		'LEVORANC',
		'LYZA',
		'Mgestin',
		'MGESTINNC',
		'Micronor',
		'Micronornc',
		'Modicon',
		'ModiconNC',
		'NO777',
		'NORTREL',
		'OCELL',
		'OCEPT',
		'ON135',
		'ON135NC',
		'ON777',
		'ON777NC',
		'ORCYCLEN',
		'ORCYCLENNC',
		'OTRICYCLEN',
		'OTRINC',
		'RECLIPSEN',
		'Tarina',
		'Trilo',
		'TRILONC',
		'TriVylibra',
		'Tulana',
		'Vylibra'--Pills
		,'J7304','X7728','X7728-ins','X7728-pt' --Patch
		,'J7303' --Ring
		,'J1050' --Depo
)

update #bc_incidence
set tier = 1
where service_item_id in (
	'J7296','J7297','J7298','J7300','J7301','J7302' --IUC
	,'J7307' --Implant
)


select b.qtr, b.qtr_begin_date, b.qtr_end_date, b.tier, count(distinct b.enc_id) countDistinctEnc, d.bci_denom, count(distinct b.enc_id) * 1.0 / d.bci_denom bci_meas
into #bci_meas
from #bc_incidence b
join (select qtr, count(distinct enc_id) bci_denom
	  from #bc_incidence
	  where tier is not null
	  group by qtr
	  ) d on b.qtr=d.qtr
join (select enc_id, min(tier) minTier
		from #bc_incidence
		where tier is not null
		group by enc_id
		) m on m.enc_id=b.enc_id and m.minTier=b.tier
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = b.qtr_begin_date
where b.tier is not null
group by b.qtr, b.tier, d.bci_denom, b.qtr_begin_date, b.qtr_end_date
order by qtr, tier



/*#######################################BC PREV#####################################################################*/

select *
into #bc_prev 
from #a1
where age between 15 and 44 and sex='f'

delete from #bc_prev 
where bcm in 
(
 'Pregnant/Partner Pregnant'
,'Seeking pregnancy'
,'Female Sterilization'
,'Vasectomy'
,'Infertile'
,'Same sex partner'
)

--select distinct bcm, count(distinct persoN_id)
--from #bc_prev
--group by bcm
--order by count(distinct person_id) desc

select distinct b.qtr, b.qtr_begin_date, b.qtr_end_date, b.person_id, b.service_date, b.bcm
into #bc_prev_num
from #bc_prev b
join (select qtr, person_id, max(service_date) maxQtrDOS
		from #bc_prev
		where bcm is not null
		group by qtr, persoN_id) m on m.person_id=b.person_id and m.maxQtrDOS=b.service_date
order by qtr, person_id

select distinct b.qtr,b.qtr_begin_date, b.qtr_end_date, b.person_id, b.service_date, b.bcm
into #bc_prev_denom
from #bc_prev b
join (select qtr, person_id, max(service_date) maxQtrDOS
		from #bc_prev	
		group by qtr, persoN_id) m on m.person_id=b.person_id and m.maxQtrDOS=b.service_date
order by qtr, person_id

alter table #bc_prev_num
add tier int

update #bc_prev_num
set tier = 1 
where bcm like '%implant%' or 
	  bcm like 'iuc%'

update #bc_prev_num
set tier = 2
where bcm like 'oral%' or 
	  bcm like 'injection%' or 
	  bcm like 'patch%' or
	  bcm like 'ring%' 
	  
select n.qtr, n.qtr_begin_date, n.qtr_end_date, n.tier, count(distinct n.person_id) countUniquePersonTier, d.bcPrevDenom, count(distinct n.person_id) * 1.0/d.bcPrevDenom bci_prev_meas
into #bci_prev_meas
from #bc_prev_num n
join (select qtr, count(distinct person_id) bcPrevDenom 
			from #bc_prev_denom bcpd
			group by qtr
		  ) d on d.qtr=n.qtr
join (select * from #dq1 where qtr_begin is not null) n1 on n1.begin_date = n.qtr_begin_date
where tier is not null
group by n.qtr, n.tier, d.bcPrevDenom, n.qtr_begin_date, n.qtr_end_date
order by n.qtr, n.tier



/*#######################################3-Month and 12-Month LARC Removal Rates  #####################################################################*/

--Insertion date is within three months of the quarter (before)
--Removal date is within the quarter

--declare @Start_date date = '20190701'
--declare @End_date date = '20190930'


--get larc inserts and ABs for those 15-44



select *
into #larc_inserts 
from #a1
where	(service_item_id = '11981' or 
		service_item_id = '58300' or 
		Service_Item_id = '59840A' or
		Service_Item_id LIKE '59841[C-N]' or 
		Service_Item_id = 'S0199' or 
		Service_Item_id = 'S0199A' or 
		Service_Item_id = '99214PME' 
)
and age between 15 and 44
and sex='f'


alter table #larc_inserts
add ab_visit varchar(20)

update #larc_inserts
set ab_visit = 'yes'
where concat(person_id, service_date) in (
	select concat(person_id, service_date)  
	from #ab
		)


--remove those with inserts on same day as AB visit
delete from #larc_inserts where ab_visit = 'yes'

alter table #larc_inserts 
drop column bcm, ab_visit, enc_id, service_item_id


--get larc removals for females 15-44

select distinct *
into #larc_removals
from #a1
where age between 15 and 44
and sex='f'


alter table #larc_removals
drop column bcm


--get just larc removals
select distinct person_id, enc_id, sex, service_date, date_of_birth, qtr, age
into #larc_removals1
from #larc_removals
where service_item_id in (
	--'11981', -- Implant Insert
	'11976', -- Implant Removal
	--'58300', -- IUC Insert
	'58301' -- IUC Removal
	)



--get day diff between insert and removal date, where removal date is after insertion date
select distinct li.*, lr.service_date remDOS, lr.qtr remQtr, datediff(day, li.service_date, lr.service_date) dayDiff
into #lr1
from #larc_inserts li
join #larc_removals1 lr on li.person_id=lr.person_id and lr.service_date > li.service_date
order by datediff(day, li.service_date, lr.service_date)


--Get most recent removal date from insertion date
select distinct l.*
into #lr2
from #lr1 l
join (select person_id, service_Date, min(remDOS) minRemDOS
		from #lr1
		group by person_id, service_Date		
	 ) m on l.person_id=m.person_id and l.service_date = m.service_date and l.remDOS = m.minRemDOS


--get most recent insertion date from removal date
select distinct l.*
into #lr3
from #lr2 l
join ( 
	select person_id, remDOS, max(service_date) maxDOS
	from #lr2
	group by person_id, remDOS
) m on l.person_id=m.person_id and l.remDOS=m.remDOS and l.service_date= m.maxDOS

--get all inserts and removals if they were
select distinct li.*, lr.remDOS, lr.remQtr, lr.dayDiff
into #lr4
from #larc_inserts li
left join #lr3 lr on li.person_id=lr.person_id and li.service_date = lr.service_date 
--where li.person_id='CB0163FC-7AE9-4086-AC74-05141E9490D0'

alter table #lr4 
add qtr_for_insert varchar(100)

update #lr4
set qtr_for_insert =  null

update #lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q2')
where datepart(mm,service_date) between 1 and 3

update #lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q3')
where datepart(mm,service_date) between 4 and 6

update #lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q4')
where datepart(mm,service_date) between 7 and 9

update #lr4
set qtr_for_insert =  concat('Y',datepart(yy,dateadd(yy, 1,service_date)), 'Q1')
where datepart(mm,service_date) between 10 and 12

alter table #lr4
drop column  qtr

alter table #lr4
add insert_qtr_begin_date date, 
	insert_qtr_end_date date


update #lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),4,1)
where datepart(mm,service_date) between 1 and 3

update #lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),7,1)
where datepart(mm,service_date) between 4 and 6

update #lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),10,1)
where datepart(mm,service_date) between 7 and 9

update #lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, dateadd(year, 1,service_date)),1,1)
where datepart(mm,service_date) between 10 and 12

update #lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),6,30)
where datepart(mm,service_date) between 1 and 3

update #lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),9,30)
where datepart(mm,service_date) between 4 and 6

update #lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),12,31)
where datepart(mm,service_date) between 7 and 9

update #lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, dateadd(year, 1,service_date)),3,31)
where datepart(mm,service_date) between 10 and 12


alter table #lr4
add yr_qtr_for_insert varchar(50)

update #lr4
set yr_qtr_for_insert =  null

update #lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q1')
where datepart(mm,service_date) between 1 and 3

update #lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q2')
where datepart(mm,service_date) between 4 and 6

update #lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q3')
where datepart(mm,service_date) between 7 and 9

update #lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q4')
where datepart(mm,service_date) between 10 and 12

alter table #lr4
add insert_qtr_begin_date_year date, 
	insert_qtr_end_date_year date


update #lr4
set insert_qtr_begin_date_year = dateadd(year,1,qtr_begin_date)


update #lr4
set insert_qtr_end_date_year = dateadd(year,1,qtr_end_date)


select lr.qtr_for_insert, lr.insert_qtr_begin_date,lr.insert_qtr_end_date, tier= null, count(distinct lr.person_id) l3mo_num, lr1.l3mo_dm, 
	count(distinct lr.person_id) * 1.0 / lr1.l3mo_dm l3mo_perc
into #lr_3mo
from #lr4 lr
join (select qtr_for_insert, count(distinct person_id) l3mo_dm
	  from #lr4 l
	  group by qtr_for_insert) lr1 on lr.qtr_for_insert = lr1.qtr_for_insert
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = lr.insert_qtr_begin_date
where dayDiff  <= 90
group by lr.qtr_for_insert, lr1.l3mo_dm, lr.insert_qtr_begin_date,lr.insert_qtr_end_date


select lr.yr_qtr_for_insert, lr.insert_qtr_begin_date_year,lr.insert_qtr_end_date_year, tier= null, count(distinct lr.person_id) l12mo_num, lr1.l12mo_dm, 
	count(distinct lr.person_id) * 1.0 / lr1.l12mo_dm l12mo_perc
into #lr_12mo
from #lr4 lr
join (select yr_qtr_for_insert, count(distinct person_id) l12mo_dm
	  from #lr4 l
	  group by yr_qtr_for_insert) lr1 on lr.yr_qtr_for_insert= lr1.yr_qtr_for_insert
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = lr.insert_qtr_begin_date_year
where dayDiff  <= 365
group by lr.yr_qtr_for_insert, lr1.l12mo_dm, lr.insert_qtr_begin_date_year, insert_qtr_end_date_year






/*#######################################BC INCIDENCE AFTER ABORTION #####################################################################*/

--Separate MABs and TABs (will be 6 measures)
--Make sure to include PMEs
--If BC is dispensed at any AB/PME visit



select *
into #bci_ab 
from #a1
where age between 15 and 44 and sex='f'

alter table #bci_ab
add ab_visit varchar(20)

update #bci_ab
set ab_visit = 'yes'
where concat(person_id, service_date) in (
	select concat(person_id, service_date)  
	from #ab
		)

delete from #bci_ab 
where ab_visit is null

alter table #bci_ab
add tier int

update #bci_ab
set tier = 3
where service_item_id in (
	'C005' --Diaphragm
		,'B008' --Female Condom
		,'C003' --Female Condom
		,'C001' --Cervical Cap
		,'C006' --Foam
		,'FILM','SPONGE','DENTAL'
		,'10CON'
		,'10CON-NC'
		,'C002NC'
		,'C002'
		,'12CON-NC'
		,'C003'
		,'24CON-NC'
		,'C033'
		,'48CON'
		,'24CON'
		,'30CON'
		,'30CON-NC'
)


update #bci_ab
set tier = 2
where service_item_id in (
		'AUBRA',
		'AUBRAEQ',
		'Brevicon',
		'CHATEAL',
		'CHATEALEQ',
		'Cyclessa',
		'CyclessaNC',
		'CYRED',
		'CYREDEQ',
		'Desogen',
		'DesogenNC',
		'Gildess',
		'Levora',
		'LEVORANC',
		'LYZA',
		'Mgestin',
		'MGESTINNC',
		'Micronor',
		'Micronornc',
		'Modicon',
		'ModiconNC',
		'NO777',
		'NORTREL',
		'OCELL',
		'OCEPT',
		'ON135',
		'ON135NC',
		'ON777',
		'ON777NC',
		'ORCYCLEN',
		'ORCYCLENNC',
		'OTRICYCLEN',
		'OTRINC',
		'RECLIPSEN',
		'Tarina',
		'Trilo',
		'TRILONC',
		'TriVylibra',
		'Tulana',
		'Vylibra'--Pills
		,'J7304','X7728','X7728-ins','X7728-pt' --Patch
		,'J7303' --Ring
		,'J1050' --Depo
)


update #bci_ab
set tier = 1
where service_item_id in (
	'J7296','J7297','J7298','J7300','J7301','J7302' --IUC
	,'J7307' --Implant
)


select b.*
into #bci_mab
from #bci_ab b
join (select person_id, service_date
		from #bci_ab 
		where (Service_Item_id = 'S0199'
				OR	 Service_Item_id = 'S0199A'
				OR	 Service_Item_id = '99214PME'
		)
	) m on m.persoN_id=b.persoN_id and m.service_date=b.service_date



select b.*
into #bci_tab
from #bci_ab b
join (select person_id, service_date
		from #bci_ab 
		where (Service_Item_id = '59840A'
			OR	 Service_Item_id LIKE '59841[C-N]'
	)
	) m on m.persoN_id=b.persoN_id and m.service_date=b.service_date

--drop table #d1
select distinct person_id, service_item_id, service_date, qtr
into #d1
from #bci_mab
where (Service_Item_id = 'S0199'
				OR	 Service_Item_id = 'S0199A'
				OR	 Service_Item_id = '99214PME'
	   )

--if countSvcItems > 1 then both MAB and PME

select person_id, count(service_item_id) countSvcItems
into #d2
from (select person_id, service_item_id
		from #d1		
	) c 
group by c.person_id



select d.*, d2.countSvcItems
into #d3
from #d1 d
join #d2 d2 on d.person_id=d2.person_id
order by person_id, service_date


--if service items run into different quarters (count > 1)
select person_id, count(distinct qtr) countQtrs
into #d4
from #d1
group by person_id

select distinct d3.*, d4.countQtrs
into #d5
from #d3 d3
join #d4 d4 on d3.person_id=d4.person_id



select * 
into #d6
from #d5
where countSvcItems > 1



--two mabs
select * 
into #d7
from #d6
where person_id not in (
		select person_id
		from #d6
		where service_item_id in (
		 '99214PME'
		)
	)



--most recent is mab
select d.person_id, d.service_item_id, d.service_date
into #d8
from #d6 d
join (select person_id, max(service_date) maxDOS
		from #d6
		group by person_id) m on m.person_id=d.person_id and m.maxDOS=d.service_date
where d.person_id not in (
	select person_id 
	from #d7
)
and d.service_item_id !='99214PME'
and countSvcItems =2

--most recent is mab
select d.person_id, d.service_item_id, d.service_date
into #d8_1
from #d6 d
join (select person_id, max(service_date) maxDOS
		from #d6
		group by person_id) m on m.person_id=d.person_id and m.maxDOS=d.service_date
where d.person_id not in (
	select person_id 
	from #d7
)
and d.service_item_id !='99214PME'
and countSvcItems > 2

select d6.*
into #d8_2
from #d6 d6
join #d8_1 d81 on d6.person_id=d81.person_id
order by person_id, service_date


select d.*, m.maxDOS
into #d8_3
from #d8_2 d
left join (select person_id, max(service_date) maxDOS
		from #d8_2
		group by person_id
	) m on d.person_id = m.person_id and d.service_date=m.maxDOS
order by d.person_id, d.service_date


select * 
into #bci_mab2
from #bci_mab



select * 
into #d9
from #d6


/*
	#d9 is the list of mabs that need to e deleted
*/

delete from #d9
where concat(person_id, service_date) in (select concat(person_id, service_date) from #d7  )

delete from #d9
where concat(person_id, service_date) in (select concat(person_id, service_date) from #d8_3 where maxDOS is not null and service_item_id ='s0199')

--select * 
--from #d9
--order by person_id, service_date

select * 
into #f1
from #d9 
where countQtrs=2

select person_id, min(service_date) minDOS
into #f2
from #f1
group by person_id

select d.*, f.minDOS
into #f3
from #d9 d
left join #f2 f on d.person_id=f.person_id


alter table #bci_mab2
add deleteRow varchar(20)

update #bci_mab2
set deleteRow = 'yes'
where concat(person_id, service_date) in (select concat(person_id, service_date) from #d9 where service_item_id='S0199')

alter table #bci_mab2
add countQtrs varchar(10)


update #bci_mab2 
set countQtrs = d.countQtrs
from #bci_mab2 b
join #d9 d on b.person_id=d.person_id and d.service_date=b.service_date



select distinct b.*, f.minDOS
into #bci_mab3
from #bci_mab2 b
left join #f3 f on b.person_id=f.persoN_id 
order by person_id, service_date


update #bci_mab3
set service_date = minDOS 
where countQtrs = 2 and minDOS is not null

delete from #bci_mab3
where deleteRow = 'yes'


update #bci_mab3
set qtr = concat('Y', datepart(yy, service_date), 'Q1')
where datepart(m,service_date) between 1 and 3

update #bci_mab3
set qtr = concat('Y', datepart(yy, service_date), 'Q2')
where datepart(m,service_date) between 4 and 6

update #bci_mab3
set qtr = concat('Y', datepart(yy, service_date), 'Q3')
where datepart(m,service_date) between 7 and 9

update #bci_mab3
set qtr = concat('Y', datepart(yy, service_date), 'Q4')
where datepart(m,service_date) between 10 and 12


update #bci_mab3
set qtr_begin_date = datefromparts(datepart(year, service_Date),1,1)
where datepart(m,service_date) between 1 and 3

update #bci_mab3
set qtr_begin_date = datefromparts(datepart(year, service_Date),4,1)
where datepart(m,service_date) between 4 and 6

update #bci_mab3
set qtr_begin_date = datefromparts(datepart(year, service_Date),7,1)
where datepart(m,service_date) between 7 and 9

update #bci_mab3
set qtr_begin_date = datefromparts(datepart(year, service_Date),10,1)
where datepart(m,service_date) between 10 and 12


update #bci_mab3
set qtr_end_date = datefromparts(datepart(year, service_Date),3,31)
where datepart(m,service_date) between 1 and 3

update #bci_mab3
set qtr_end_date= datefromparts(datepart(year, service_Date),6,30)
where datepart(m,service_date) between 4 and 6

update #bci_mab3
set qtr_end_date= datefromparts(datepart(year, service_Date),9,30)
where datepart(m,service_date) between 7 and 9

update #bci_mab3
set qtr_end_date = datefromparts(datepart(year, service_Date),12,31)
where datepart(m,service_date) between 10 and 12

select c.qtr, c.qtr_begin_date,c.qtr_end_date, c.minTier, count(distinct c.person_id) countTierPerson, a.countABPerson, count(distinct c.persoN_id) * 1.0/a.countABPerson bci_mab_ab_meas
into #bci_mab_ab
from (
	select b.qtr, b.qtr_begin_date,b.qtr_end_date,b.person_id, b.service_date, min(b.tier) minTier
	from #bci_mab3 b
	join (select qtr, person_id, max(service_date) maxDOS
			from #bci_mab3
			where tier is not null
			group by qtr, person_id
		  ) m on m.maxDOS=b.service_date
	where tier is not null
	group by b.qtr, b.persoN_id, b.service_date, b.qtr_begin_date, b.qtr_end_date
	) c
join (select qtr, count(distinct person_id) countABPerson
      from #bci_mab3
	  group by qtr) a on a.qtr=c.qtr
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
group by c.qtr, c.minTier, a.countABPerson,  c.qtr_begin_date,c.qtr_end_date


select c.qtr,c.qtr_begin_date, c.qtr_end_date, c.minTier, count(distinct c.person_id) countTierPerson, a.countABPerson, count(distinct c.persoN_id) * 1.0/a.countABPerson bci_tab_ab_meas
into #bci_tab_ab_meas
from (
	select distinct b.qtr, b.qtr_begin_date, b.qtr_end_date,b.person_id, b.service_date, min(b.tier) minTier
	from #bci_tab b
	join (select qtr, person_id, max(service_date) maxDOS
			from #bci_tab 
			where tier is not null
			group by qtr, person_id
		  ) m on m.maxDOS=b.service_date
	where tier is not null
	group by b.qtr, b.persoN_id, b.service_date,b.qtr_begin_date, b.qtr_end_date
	) c
join (select qtr, count(distinct person_id) countABPerson
      from #bci_tab 
	  group by qtr) a on a.qtr=c.qtr
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
group by c.qtr, c.minTier, a.countABPerson,c.qtr_begin_date, c.qtr_end_date


/*###################################1-Year AB Rate#################################################################################*/

select distinct * 
into #c1
from #a1
where sex='f'

SELECT DISTINCT t.person_id, t.service_date
INTO #pregQ1
FROM #c1 t
JOIN ngprod.dbo.order_ o ON o.encounterID = t.enc_id
WHERE service_item_id = '81025K' AND actText LIKE '%preg%' AND obsValue = 'positive'

--drop table #c2
select distinct qtr_begin_date, qtr_end_date,person_id, age=CAST((CONVERT(INT,CONVERT(CHAR(8),service_date,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar), 
service_Date visit_date
into #c2
from #c1

alter table #c2 
add ab_date date,
    days_btw int

delete from #c2
where exists (
	select * 
	from #pregQ1 p
	where p.persoN_id= #c2.person_id and p.service_Date=#c2.visit_date
)

delete from #c2
where exists
(
	select * 
	from #ab a
	where a.person_id=#c2.person_id and a.service_date=#c2.visit_date
)

delete from #c2
where age < 15 or age > 44

--***Find all AB related visits within 1 year after the reporting period***
--drop table #ab_max
SELECT DISTINCT person_id, service_date
INTO #ab_max
FROM #c1
WHERE 
   (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
OR	 Service_Item_id = '99214PME'
	)
GROUP BY  person_id, service_date

update #c2
set ab_date = a.service_date
from #ab_max a
join #c2 c on c.person_id=a.person_id
where  a.service_date between qtr_end_date and dateadd(year, 1, c.visit_date)

UPDATE #c2
SET days_btw = CASE WHEN ISNULL(AB_Date,'') <> '' THEN DATEDIFF(DAY,Visit_Date, AB_Date)
			 ELSE 0 END
FROM #c2

--drop table #c3,#c4
select c.* 
into #c3
from #c2 c 
join (select person_id, ab_date, min(days_btw) min_dbtw
	  from #c2
	  where ab_date is not null
	  group by person_id, ab_date) m on c.person_id=m.person_id and c.days_btw = m.min_dbtw


select distinct c2.qtr_begin_date, c2.qtr_end_date, c2.person_id, c2.age, c2.visit_date, c3.ab_date, c3.days_btw
into #c4
from #c2 c2
left join #c3 c3 on c3.person_id=c2.person_id and c3.visit_date=c2.visit_date and c3.ab_date=c2.ab_date and c3.days_btw = c2.days_btw

update #c4
set qtr_begin_date = dateadd(year,1,qtr_begin_date)

update #c4
set qtr_end_date = dateadd(year,1,qtr_end_date )

alter table #c4
add qtr varchar(50)


update #c4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q1')
where datepart(m,qtr_begin_date) between 1 and 3

update #c4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q2')
where datepart(m,qtr_begin_date) between 4 and 6

update #c4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q3')
where datepart(m,qtr_begin_date) between 7 and 9

update #c4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q4')
where datepart(m,qtr_begin_date) between 10 and 12


SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null, COUNT(distinct c.person_id) numeratorABRate , a.countDenominator countVisits, count(distinct c.person_id) * 1.0/ a.countDenominator percABVisit
into #abRate1Yr
FROM #c4 c
joIN (select qtr,count(distinct person_id) countDenominator
		from #c4
		--where dateadd(yy,1,qe) <= @end_date
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE (days_btw >0 AND days_btw <= 365) /*and dateadd(yy,1,qe) <= @end_date */
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr

/*###################################APPROPRIATE GC/CT TESTING #################################################################################*/

/*
** Risk Factors: 
	No testing in previous 12 months, 
	MSM, 
		- Before Nov 18
			- Sex ='m'
			- hpi -> opt_sexual_partners = 1
		- After Nov 18
			- Sex ='m'
			- psw -> chk_sp_penis = 1
	New partner,  = New Partner since Last Test = yes
		- hpi -> opt_new_partner = 2
	Multiple partners, >1 partner in 12 months = 'yes', # of Partners > 1, 
		- hpi -> opt_multiple_partners = 2
	Partner not monogamous, Partner Info => Monogomous = 'yes'
		- hpi -> opt_partner_monogomous = 2
	STI exposure, Exposure to STIs ='yes'
		- hpi -> opt_known_exposure = 2
	Has sex for money/drugs, Has sex for money or drugs = 'yes'
		- hpi -> opt_sexual_favors = 2
	Incarceration, Incarceration = 'yes'
		- opt_patient_incarceration =2
*/


select distinct * 
into #a_gcct
from #a1

alter table #a_gcct
add msm varchar(20), 
	new_partner varchar(20), 
	multi_partners varchar(20), 
	partner_not_monog varchar(20), 
	sexual_favors varchar(20), 
	risk varchar(20), 
	current_sexual_activity varchar(500),
	Anal_insertive VARCHAR (1),
	Anal_receptive VARCHAR (1),
	oral_insertive VARCHAR (1),
	oral_receptive VARCHAR (1),
	vaginal_insertive VARCHAR (1),
	vaginal_receptive VARCHAR (1), 
	mrgcct date, 
	gcct_within_12mo varchar(20), 
	appropriate varchar(50)

alter table #a_gcct
add Rectal_swab VARCHAR (20),Pharyngeal_swab VARCHAR (20),Urine_sample VARCHAR (20),Vaginal_swab VARCHAR (20)

/* Risk Factors */

update #a_gcct
set msm = 'y'
from #a_gcct a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where a.sex='m' 
and opt_sexual_partners = '1'
and a.service_date <='20181031'

update #a_gcct
set msm = 'y'
from #a_gcct a 
join ngprod.dbo.psw_hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1'
and a.service_date >'20181031'

update #a_gcct
set msm = 'n'
where msm is null

update #a_gcct
set new_partner = 'y'
from #a_gcct a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_new_partner = '2'

update #a_gcct
set new_partner = 'n'
where new_partner is null

update #a_gcct
set multi_partners = 'y'
from #a_gcct a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_multiple_partners = '2'

update #a_gcct
set multi_partners = 'n'
where multi_partners is null

update #a_gcct
set partner_not_monog = 'y'
from #a_gcct a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_partner_monogomous = '1'

update #a_gcct
set partner_not_monog = 'n'
where partner_not_monog is null

update #a_gcct
set sexual_favors = 'y'
from #a_gcct a 
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id
where opt_sexual_favors = '2'

update #a_gcct
set sexual_favors = 'n'
from #a_gcct a 
where sexual_favors is null


/* Current Sexual Activity */

update #a_gcct
set current_sexual_activity = txt_current_sexual_activity
from #a_gcct a
join ngprod.dbo.hpi_sti_screening_ hpi1 ON hpi1.enc_id = a.enc_id

UPDATE #a_gcct 
SET anal_insertive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%anal insertive%'

--anal receptive
UPDATE #a_gcct
SET anal_receptive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%anal receptive%'

--Female anal receptive
UPDATE #a_gcct 
SET anal_receptive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%anal%' and
a.sex = 'f'

--Oral insertive
UPDATE #a_gcct 
SET oral_insertive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%oral insertive%'

--Oral receptive
UPDATE #a_gcct 
SET oral_receptive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%oral Receptive%'

--vaginal receptive
UPDATE #a_gcct 
SET Vaginal_receptive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%vaginal%' AND sex = 'f'

--vaginal insertive
UPDATE #a_gcct 
SET vaginal_insertive = 'Y' 
FROM #a_gcct a
WHERE current_sexual_activity LIKE '%vaginal%' AND sex = 'm'

/* Test Source */

--Rectal Swab
UPDATE #a_gcct 
SET rectal_swab = 'Y' 
FROM #a_gcct a
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = a.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE aoe.test_data_value LIKE '%Rectal%' 
AND CONVERT(date,a.service_date) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 

--Pharyngeal Swab
UPDATE #a_gcct 
SET pharyngeal_swab = 'Y' 
FROM #a_gcct a
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = a.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE aoe.test_data_value LIKE '%Pharyngeal%'
AND CONVERT(date,a.service_date) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 

--Urine
UPDATE #a_gcct 
SET urine_sample = 'Y' 
FROM #a_gcct a
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = a.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE aoe.test_data_value LIKE '%Urine%'
AND CONVERT(date,a.service_date) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status LIKE 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 

--Vaginal Swab
UPDATE #a_gcct 
SET vaginal_swab = 'Y' 
FROM #a_gcct a
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = a.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
WHERE aoe.test_data_value LIKE '%Vaginal%'
AND CONVERT(date,a.service_date) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'
and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 


/* Most Recent GC/CT Test */

SELECT a.persoN_id, MAX(CONVERT(date,lot.collection_time)) AS 'lastgccttest'
into #mr_gcct_test
						FROM #a_gcct a
						JOIN ngprod.dbo.lab_nor nor ON nor.person_id = a.person_id
						JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
						JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
						join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
						join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
						WHERE CONVERT(date,a.service_date) > CONVERT(date,lot.collection_time)
						AND nor.ngn_status = 'Signed-Off'
						and (obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) 
						GROUP BY a.person_id 
		



update #a_gcct
set mrgcct = lastgccttest
from #a_gcct a
join #mr_gcct_test r on a.person_id=r.person_id 

update #a_gcct
set gcct_within_12mo  = 'y'
where datediff(d, mrgcct, service_date) <=366

update #a_gcct
set gcct_within_12mo = 'n'
where gcct_within_12mo is null

/* Risk Level */

update #a_gcct
set risk = 'y'
where  
	new_partner ='y' or 
	multi_partners ='y' or  
	partner_not_monog ='y' or  
	sexual_favors ='y' or 
	gcct_within_12mo = 'n'

update #a_gcct
set risk = 'n'
where risk is null



--***Begin appropriate Testing section***

--Male Insertive ONly
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or [oral_insertive] = 'y') --***Add oral insert??***
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

--Male Insertive AND anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Male Insertive AND anal AND oral receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] = 'y'
AND [Pharyngeal_swab] = 'y' AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Male Insertive AND oral receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y' or oral_insertive = 'y') --***Add oral insert??***
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] ='y' AND [Vaginal_swab]  IS NULL AND Urine_sample ='y' AND Rectal_swab IS NULL

--Female Vaginal receptive or oral insertive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f' 
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL AND ([vaginal_receptive] = 'Y' or oral_insertive = 'y')
AND [Rectal_swab] IS NULL AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y')

--Male Anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL

--Male Oral receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL

--Female Oral AND Vaginal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab IS NULL

--Female Oral AND Vaginal AND anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab = 'Y'

--Male Oral AND anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'M' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral AND anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'

--Vaginal AND anal receptive
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f'
AND [oral_receptive] IS NULL AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab = 'Y'


--Female No sexual activity but tested
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'f' 
AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab IS NULL

--Male No sexual activity but tested
UPDATE #a_gcct
SET appropriate = 'Y'
FROM #a_gcct
WHERE sex = 'm' 
AND [oral_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [oral_insertive] IS NULL AND [Anal_insertive] IS NULL AND [vaginal_insertive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab] IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

--drop table #app_gcct
select a.qtr,a.qtr_begin_date, a.qtr_end_date,  tier = null,count(distinct a.persoN_id) numeratorAppGCCT, c.countRisk, count(distinct a.person_id) * 1.0/c.countRisk percAppGCCT
into #app_gcct
from #a_gcct a
join (select qtr, count(distinct person_id) countRisk
		from #a_gcct
		where risk='y'
		group by qtr		
	) c on a.qtr=c.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = a.qtr_begin_date
where risk='y' and appropriate='y'
group by a.qtr, c.countRisk,a.qtr_begin_date, a.qtr_end_date


--select pt.med_rec_nbr, a.* 
--from #a_gcct a
--join ngprod.dbo.patient pt on pt.person_id=a.person_id
--where sex='f'
--and oral_insertive = 'y'


/*###################################GC/CT Treatment #################################################################################*/


select distinct * 
into #gt
from #a1


select distinct g.*, obx.result_desc, obx.observ_value, obx.obs_id
into #gt1
from #gt g
join ngprod.dbo.lab_nor nor ON nor.enc_id = g.enc_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
where  
--CONVERT(date,g.service_date) = CONVERT(date,lot.collectiON_time) and 
		(obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) and 
		 (obx.observ_value='DETECTED' or obx.observ_value='POSITIVE')

alter table #gt1
drop column service_item_id, bcm

alter table #gt1
add azith varchar(50), 
	ceft varchar(50),
	genta varchar(50), 
	gc varchar(50), 
	ct varchar(50), 
	treated varchar(50)


--Azithromycin ERX within 30 days
UPDATE #gt1
SET Azith = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM ON H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #gt1 p							  ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'azi%'
)

--Azithromycin dispensed within 30 days
UPDATE #gt1
SET Azith = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #gt1 p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'azi%'
)

--Ceftriaxlon ERX within 30 days
UPDATE #gt1
SET ceft = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM on H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #gt1 p ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'ceft%'
)

--Ceftriaxlon dispensed within 30 days
UPDATE #gt1
SET ceft = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #gt1 p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'ceft%'
)

--Gentamycin ERX within 30 days
UPDATE #gt1
SET genta = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM ON H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #gt1 p							  ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'genta%'
)

--Gentamycin dispensed within 30 days
UPDATE #gt1
SET genta = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #gt1 p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.service_date AND DATEADD(DD, 31,p.service_date)
AND medication_name LIKE 'genta%'
)


update #gt1
set gc = 'y'
where enc_id in (
	select enc_id 
	from #gt1
	where result_desc = 'gc'   OR obs_id like '%Gonor%' 
) 

update #gt1
set ct = 'y'
where enc_id in (
	select enc_id 
	from #gt1
	where  result_desc = 'ct' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Chlam%' 
) 


--***Set treated depending on STI and meds dispensed***
UPDATE #gt1
SET Treated = 'Y'
WHERE gc='y' AND Azith = 'y' AND (Ceft = 'y' OR genta = 'y')

UPDATE #gt1
SET Treated = 'Y'
WHERE ct='y' AND Azith = 'y'

UPDATE #gt1
SET Treated = 'n'
WHERE GC = 'y' AND CT = 'y' AND Ceft IS NULL AND genta IS NULL


alter table #gt1
drop column result_desc, observ_value, obs_id

select a.qtr,a.qtr_begin_date, a.qtr_end_date, tier = null, count(distinct a.persoN_id) numeratorTreated, c.countPos, count(distinct a.person_id) * 1.0/c.countPos percTreated
into #tmt_gcct
from #gt1 a
join (select qtr, count(distinct person_id) countPos
		from #gt1		
		group by qtr		
	) c on a.qtr=c.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = a.qtr_begin_date
where treated ='y'
group by a.qtr, c.countPos, a.qtr_begin_date, a.qtr_end_date



/*#######################################3-Month and 12-Month LARC Removal Rates Abortion Rate #####################################################################*/

--Insertion date is within three months of the quarter (before)
--Removal date is within the quarter

--declare @Start_date date = '20190701'
--declare @End_date date = '20190930'


--get larc inserts and ABs for those 15-44

--drop table #ab_larc_inserts
select *
into #ab_larc_inserts 
from #a1
where	(service_item_id = '11981' or 
		service_item_id = '58300' or 
		Service_Item_id = '59840A' or
		Service_Item_id LIKE '59841[C-N]' or 
		Service_Item_id = 'S0199' or 
		Service_Item_id = 'S0199A' or 
		Service_Item_id = '99214PME' 
)
and age between 15 and 44
and sex='f'

alter table #ab_larc_inserts
add ab_visit varchar(20)

update #ab_larc_inserts
set ab_visit = 'yes'
where concat(person_id, service_date) in (
	select concat(person_id, service_date)  
	from #ab
		)


--remove those with inserts on same day as AB visit
delete from #ab_larc_inserts where ab_visit is null

delete from #ab_larc_inserts where service_item_id in ('59840A', 
		'S0199', 
		'S0199A', 
		'99214PME'
		) or Service_Item_id LIKE '59841[C-N]' 



alter table #ab_larc_inserts 
drop column bcm, ab_visit, enc_id, service_item_id


--get larc removals for females 15-44

--drop table #ab_larc_removals
select distinct *
into #ab_larc_removals
from #a1
where age between 15 and 44
and sex='f'

alter table #ab_larc_removals
drop column bcm

--get just larc removals
select distinct person_id, enc_id, sex, service_date, date_of_birth, qtr, age
into #ab_larc_removals1
from #ab_larc_removals
where service_item_id in (
	--'11981', -- Implant Insert
	'11976', -- Implant Removal
	--'58300', -- IUC Insert
	'58301' -- IUC Removal
	)

--drop table #ab_lr2,#ab_lr3,#ab_lr4
--get day diff between insert and removal date, where removal date is after insertion date
select distinct li.*, lr.service_date remDOS, lr.qtr remQtr, datediff(day, li.service_date, lr.service_date) dayDiff
into #ab_lr1
from #ab_larc_inserts li
join #ab_larc_removals1 lr on li.person_id=lr.person_id and lr.service_date > li.service_date
order by datediff(day, li.service_date, lr.service_date)


--Get most recent removal date from insertion date
select distinct l.*
into #ab_lr2
from #ab_lr1 l
join (select person_id, service_Date, min(remDOS) minRemDOS
		from #ab_lr1
		group by person_id, service_Date		
	 ) m on l.person_id=m.person_id and l.service_date = m.service_date and l.remDOS = m.minRemDOS

--get most recent insertion date from removal date
select distinct l.*
into #ab_lr3
from #ab_lr2 l
join ( 
	select person_id, remDOS, max(service_date) maxDOS
	from #ab_lr2
	group by person_id, remDOS
) m on l.person_id=m.person_id and l.remDOS=m.remDOS and l.service_date= m.maxDOS

--get all inserts and removals if they were
select distinct li.*, lr.remDOS, lr.remQtr, lr.dayDiff
into #ab_lr4
from #ab_larc_inserts li
left join #ab_lr3 lr on li.person_id=lr.person_id and li.service_date = lr.service_date 
--where li.person_id='CB0163FC-7AE9-4086-AC74-05141E9490D0'



alter table #ab_lr4 
add qtr_for_insert varchar(100)

update #ab_lr4
set qtr_for_insert =  null

update #ab_lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q2')
where datepart(mm,service_date) between 1 and 3

update #ab_lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q3')
where datepart(mm,service_date) between 4 and 6

update #ab_lr4
set qtr_for_insert =  concat('Y', datepart(yy,service_date), 'Q4')
where datepart(mm,service_date) between 7 and 9

update #ab_lr4
set qtr_for_insert =  concat('Y',datepart(yy,dateadd(yy, 1,service_date)), 'Q1')
where datepart(mm,service_date) between 10 and 12

alter table #ab_lr4
drop column  qtr

alter table #ab_lr4
add insert_qtr_begin_date date, 
	insert_qtr_end_date date

update #ab_lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),4,1)
where datepart(mm,service_date) between 1 and 3

update #ab_lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),7,1)
where datepart(mm,service_date) between 4 and 6

update #ab_lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, service_date),10,1)
where datepart(mm,service_date) between 7 and 9

update #ab_lr4
set insert_qtr_begin_date  = datefromparts(datepart(yy, dateadd(year, 1,service_date)),1,1)
where datepart(mm,service_date) between 10 and 12

update #ab_lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),6,30)
where datepart(mm,service_date) between 1 and 3

update #ab_lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),9,30)
where datepart(mm,service_date) between 4 and 6

update #ab_lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, service_date),12,31)
where datepart(mm,service_date) between 7 and 9

update #ab_lr4
set insert_qtr_end_date  = datefromparts(datepart(yy, dateadd(year, 1,service_date)),3,31)
where datepart(mm,service_date) between 10 and 12


alter table #ab_lr4
add yr_qtr_for_insert varchar(50)

update #ab_lr4
set yr_qtr_for_insert =  null

update #ab_lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q1')
where datepart(mm,service_date) between 1 and 3

update #ab_lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q2')
where datepart(mm,service_date) between 4 and 6

update #ab_lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q3')
where datepart(mm,service_date) between 7 and 9

update #ab_lr4
set yr_qtr_for_insert =  concat('Y', datepart(yy,dateadd(year,1,service_date)), 'Q4')
where datepart(mm,service_date) between 10 and 12

alter table #ab_lr4
add insert_qtr_begin_date_year date, 
	insert_qtr_end_date_year date

update #ab_lr4
set insert_qtr_begin_date_year = dateadd(year,1,qtr_begin_date)

update #ab_lr4
set insert_qtr_end_date_year = dateadd(year,1,qtr_end_date)

--drop table #ab_lr_3mo, #ab_lr_12mo
select lr.qtr_for_insert, lr.insert_qtr_begin_date, lr.insert_qtr_end_date, tier= null, count(distinct lr.person_id) l3mo_num, lr1.l3mo_dm, 
	count(distinct lr.person_id) * 1.0 / lr1.l3mo_dm l3mo_perc
into #ab_lr_3mo
from #ab_lr4 lr
join (select qtr_for_insert, count(distinct person_id) l3mo_dm
	  from #ab_lr4 l
	  group by qtr_for_insert) lr1 on lr.qtr_for_insert = lr1.qtr_for_insert
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = lr.insert_qtr_begin_date
where dayDiff  <= 90 
group by lr.qtr_for_insert, lr1.l3mo_dm, lr.insert_qtr_begin_date, lr.insert_qtr_end_date

select lr.yr_qtr_for_insert,lr.insert_qtr_begin_date_year,lr.insert_qtr_end_date_year, tier= null, count(distinct lr.person_id) l12mo_num, lr1.l12mo_dm, 
	count(distinct lr.person_id) * 1.0 / lr1.l12mo_dm l12mo_perc
into #ab_lr_12mo
from #ab_lr4 lr
join (select yr_qtr_for_insert, count(distinct person_id) l12mo_dm
	  from #ab_lr4 l
	  group by yr_qtr_for_insert) lr1 on lr.yr_qtr_for_insert= lr1.yr_qtr_for_insert
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = lr.insert_qtr_begin_date_year
where dayDiff  <= 365
group by lr.yr_qtr_for_insert, lr1.l12mo_dm,lr.insert_qtr_begin_date_year, insert_qtr_end_date_year


/*###################################1-Year Repeat Abortion Rate#################################################################################*/

--drop table #r1,#r2,#r3,#r4
select distinct * 
into #r1 
from #a1
where sex = 'f'
and age between 15 and 44 


select distinct qtr_begin_date, qtr_end_date, person_id, age, service_date visit_date
into #r2
from #r1

alter table #r2
add ab_date date, 
	days_btw int

alter table #r2
add ab_visit varchar(20)
 
 
update #r2
set ab_visit = 'yes'
from #r2 b
join (SELECT DISTINCT person_id, service_date, enc_id-- drop table #ab
		FROM #a1
		WHERE 
		   (
			 Service_Item_id = '59840A'
		OR	 Service_Item_id LIKE '59841[C-N]'
		OR	 Service_Item_id = 'S0199'
		OR	 Service_Item_id = 'S0199A'		
			)
		and sex='f'	
	) ab on ab.person_id=b.person_id and ab.service_date=b.visit_date

delete from #r2 
where ab_visit is null


select distinct person_id, service_date
into #r_ab_max
from #r1
where 
 (
	 Service_Item_id = '59840A'
		OR	 Service_Item_id LIKE '59841[C-N]'
		OR	 Service_Item_id = 'S0199'
		OR	 Service_Item_id = 'S0199A'		
	)
group by person_id, service_date

update #r2
set ab_date = a.service_date
from #r_ab_max a
join #r2 r on r.person_id=a.person_id
where a.service_date between qtr_end_date and dateadd(year, 1,r.visit_date)

update #r2 
set days_btw = case when isnull(ab_date, '') <>'' then datediff(day, visit_date, ab_date) 
				else 0 end
from #r2

select r.*
into #r3 
from #r2 r 
join (select person_id, ab_date, min(days_btw) min_dbtw
		from #r2
		where ab_date is not null		
		group by person_id, ab_date) m on r.person_id=m.person_id and r.days_btw = m.min_dbtw



select distinct r2.qtr_begin_date, r2.qtr_end_date, r2.person_id, r2.age, r2.visit_date, r3.ab_date, r3.days_btw
into #r4
from #r2 r2
left join #r3 r3 on r3.person_id=r2.person_id and r3.visit_date=r2.visit_date and r3.ab_date=r2.ab_date and r3.days_btw = r2.days_btw

update #r4
set qtr_begin_date = dateadd(year,1,qtr_begin_date)

update #r4
set qtr_end_date = dateadd(year,1,qtr_end_date )

alter table #r4
add qtr varchar(50)

update #r4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q1')
where datepart(m,qtr_begin_date) between 1 and 3

update #r4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q2')
where datepart(m,qtr_begin_date) between 4 and 6

update #r4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q3')
where datepart(m,qtr_begin_date) between 7 and 9

update #r4
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q4')
where datepart(m,qtr_begin_date) between 10 and 12


SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null,COUNT(distinct c.person_id) numeratorABRate , a.countDenominator countVisits, count(distinct c.person_id) * 1.0/ a.countDenominator percABVisit
into #r_abRate1Yr 
FROM #r4 c
joIN (select qtr,count(distinct person_id) countDenominator
		from #r4		
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE (days_btw >0 AND days_btw <= 365) /*and dateadd(yy,1,qe) <= @end_date */
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr


/************************************************** Timely Colpo Follow up ***************************************************/
--Creates list of all encounters, dx and SIM codes during time period

SELECT obr.test_desc, obx.result_comment, e.person_id, e.service_date, e.enc_id, e.qtr, e.qtr_begin_date, e.qtr_end_date
INTO #colpo1
FROM #a1 e
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = e.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr ON obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx   ON obx.unique_obr_num = obr.unique_obr_num
WHERE service_item_id = '57454'
AND nor.delete_ind != 'Y'			-- no deleted labs
AND nor.ngn_status = 'Signed-off'	-- Signed off results only
AND nor.ngn_status != 'Cancelled'	-- no cancelled labs
AND nor.test_status != 'Cancelled'	-- no cancelled tests
AND obr.test_desc = 'PATHOLOGY REPORT'


CREATE TABLE #colpo2 (
 qtr varchar(20), 
 qtr_begin_date date, 
 qtr_end_date date, 
 person_id UNIQUEIDENTIFIER
,Colpo_date DATE
,cryo_leep DATE
)

INSERT INTO #colpo2
SELECT DISTINCT qtr, qtr_begin_date, qtr_end_date, person_id, service_date, NULL--, NULL
FROM #Colpo1
WHERE result_comment LIKE '%diagnosis%'
AND (result_comment LIKE '%CIN 2%' OR result_comment LIKE '%CIN II%' OR result_comment LIKE '%CIN 3%' OR result_comment LIKE '%CIN III%')


UPDATE #Colpo2
SET cryo_leep = pp.service_date
FROM ngprod.dbo.patient_procedure pp
JOIN #colpo2 t2 ON t2.person_id = pp.person_id
WHERE pp.service_date BETWEEN t2.colpo_date AND DATEADD(DD, 91,t2.colpo_date)
AND pp.service_item_id IN ('57460','57511','57455','58110')

--57460 LEEP
--57511 Cryo

update #colpo2
set qtr_begin_date = dateadd(month,3,qtr_begin_date)

update #colpo2
set qtr_end_date = dateadd(month,3,qtr_end_date )

update #colpo2 
set qtr_end_date ='20191231' 
where qtr_end_date = '20191230'

update #colpo2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q1')
where datepart(m,qtr_begin_date) between 1 and 3

update #colpo2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q2')
where datepart(m,qtr_begin_date) between 4 and 6

update #colpo2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q3')
where datepart(m,qtr_begin_date) between 7 and 9

update #colpo2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q4')
where datepart(m,qtr_begin_date) between 10 and 12

--drop table #co_fup
SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date,tier = null, COUNT(distinct c.person_id) numeratorCryo, a.countDenominator countColpo, count(distinct c.person_id) * 1.0/ a.countDenominator percCryo
into #co_fup
FROM #colpo2 c
joIN (select qtr,count(distinct person_id) countDenominator
		from #colpo2	
		where colpo_date is not null	
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE cryo_leep is not null and colpo_date is not null
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr


/************************************************** Timely Pap Follow up ***************************************************/

--declare @Start_Date datetime = DATEADD(d, -730, GETDATE())
--declare @End_Date datetime = DATEADD(d, 365, GETDATE())

--drop table #PapFollowUp
SELECT DISTINCT pe.person_id, pp.service_date, pe.enc_id, lm.location_name
INTO #PapFollowUp
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe  ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.location_mstr lm on pp.location_id = lm.location_id
JOIN ngprod.dbo.person	p			  ON pp.person_id = p.person_id
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = pe.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr ON obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx   ON obx.unique_obr_num = obr.unique_obr_num
WHERE (pp.service_date >= @Start_Date AND pp.service_date <= @End_Date) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND obr.test_desc like 'PAP%'
AND nor.delete_ind != 'Y'			-- no deleted labs
AND nor.ngn_status = 'Signed-off'	-- Signed off results only
AND nor.ngn_status != 'Cancelled'	-- no cancelled labs
AND nor.test_status != 'Cancelled'	-- no cancelled tests
AND pp.delete_ind = 'N' --***EB 24/7/2018 Was pulling multiple locations when someone created a charge under the wrong center the deleted it***
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD', --Clinical services and Lab locations are excluded
						   '966B30EA-F24F-48D6-8346-948669FDCE6E')-- Online services excluded included in totals

--DELETE ALL PATIENTS WHO HAD COLPO AND PAP ON SAME DAY
DELETE FROM #PapFollowUp
FROM #PapFollowUp 
JOIN ngprod.dbo.patient_procedure pp ON pp.enc_id = #PapFollowUp.enc_id
WHERE service_item_id IN ('57454','57455','58110') AND pp.service_date = #PapFollowUp.service_date


CREATE TABLE #Pap2 (
 person_id UNIQUEIDENTIFIER
,location varchar(50) --new
,pap_date DATE
,hpv VARCHAR(1)
,result VARCHAR(50)
,colpo_location VARCHAR(50) --new
,colpo_date DATE
)

--Insert all atypical glandular patiets into table
INSERT INTO #Pap2
SELECT DISTINCT t.person_id, t.location_name, t.service_date, NULL, 'atypical glandular', NULL, NULL
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%atypical glandular cells of undeter%'

--Insert all ASC cannot exclude high-grade patiets into table
INSERT INTO #Pap2
SELECT DISTINCT t.person_id,  t.location_name,t.service_date, NULL, 'cannot exclude', NULL, NULL
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%cannot exclude%'

--Insert High grade squamous intraepithelial lesions into table
INSERT INTO #Pap2
SELECT DISTINCT t.person_id, t.location_name, t.service_date, NULL, 'high-grade squamous intraepithelial lesion', NULL, NULL
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%high-grade squamous intraepithelial lesion%'
OR    obx.result_comment like '%high grade squamous intraepithelial lesion%'

--Insert all HPV positive patiets into table
INSERT INTO #Pap2
SELECT DISTINCT t.person_id,t.location_name, t.service_date, 'Y', NULL, NULL, NULL
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE result_desc LIKE '%HPV%' AND observ_value = 'positive'
AND t.person_id NOT IN (SELECT t2.person_id from #Pap2 t2)

--Update all patients who had previous result and have HPV
UPDATE #Pap2
SET hpv = 'Y'
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #pap2 t2 ON t2.person_id = t.person_id
WHERE result_desc LIKE '%HPV%' AND observ_value = 'positive'

--Update ASCUS
UPDATE #Pap2
SET result = 'ASCUS'
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #Pap2 t2 ON t2.person_id = t.person_id
WHERE result_comment LIKE '%atypical squamous cells%'
AND hpv = 'y'

--Update all LNIL
UPDATE #Pap2
SET result = 'LSIL'
FROM #PapFollowUp t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #Pap2 t2 ON t2.person_id = t.person_id
WHERE result_comment LIKE '%low-grade squamous intraepithelial lesion%'
AND hpv = 'y' 

--Update table when colpo found within 90 days of PAP
UPDATE #Pap2
SET colpo_date = pp.service_date
FROM ngprod.dbo.patient_procedure pp
JOIN #Pap2 t2 ON t2.person_id = pp.person_id
WHERE pp.service_date BETWEEN t2.pap_date AND DATEADD(DD, 91,t2.pap_date)
AND pp.service_item_id IN ('57454','57455','58110')

--Update HPV to 'N' instead of null
UPDATE #Pap2
SET hpv = 'N'
WHERE hpv IS NULL


alter table #pap2
add qtr varchar(20), 
	qtr_begin_date date, 
	qtr_end_date date

update #pap2
set qtr_begin_date = datefromparts(datepart(year, pap_date), 1,1) 
where datepart(month, pap_date) between 1 and 3

update #pap2
set qtr_end_date = datefromparts(datepart(year, pap_date), 3,31) 
where datepart(month, pap_date) between 1 and 3

update #pap2
set qtr_begin_date = datefromparts(datepart(year, pap_date), 4,1) 
where datepart(month, pap_date) between 4 and 6

update #pap2
set qtr_end_date = datefromparts(datepart(year, pap_date), 6,30) 
where datepart(month, pap_date) between 4 and 6

update #pap2
set qtr_begin_date = datefromparts(datepart(year, pap_date), 7,1) 
where datepart(month, pap_date) between 7 and 9

update #pap2
set qtr_end_date = datefromparts(datepart(year, pap_date), 9,30) 
where datepart(month, pap_date) between 7 and 9

update #pap2
set qtr_begin_date = datefromparts(datepart(year, pap_date), 10,1) 
where datepart(month, pap_date) between 10 and 12

update #pap2
set qtr_end_date = datefromparts(datepart(year, pap_date), 12,31) 
where datepart(month, pap_date) between 10 and 12


update #pap2
set qtr_begin_date = dateadd(month,3,qtr_begin_date)

update #pap2
set qtr_end_date = dateadd(month,3,qtr_end_date )

update #pap2 
set qtr_end_date ='20191231' 
where qtr_end_date = '20191230'

update #pap2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q1')
where datepart(m,qtr_begin_date) between 1 and 3

update #pap2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q2')
where datepart(m,qtr_begin_date) between 4 and 6

update #pap2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q3')
where datepart(m,qtr_begin_date) between 7 and 9

update #pap2
set qtr = concat('Y', datepart(yy, qtr_begin_date), 'Q4')
where datepart(m,qtr_begin_date) between 10 and 12

SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null, COUNT(distinct c.person_id) numeratorPap, a.countDenominator countPap, count(distinct c.person_id) * 1.0/ a.countDenominator percCryo
into #pap_fup
FROM #pap2 c
joIN (select qtr,count(distinct person_id) countDenominator
		from #pap2	
		where pap_date is not null	
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE colpo_date is not null and pap_date is not null
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr


/* **********************************************---------------------------------------********************************/
--Gather appointment date, appointment create date and the difference between the two based on AB event types


--declare @Start_Date datetime = DATEADD(d, -730, GETDATE())
--declare @End_Date datetime = DATEADD(d, 365, GETDATE())

--drop table #appt

SELECT a.create_timestamp, appt_date, DATEDIFF(DAY,a.create_timestamp, appt_date) AS 'Diff', [event]
INTO #appt
FROM ngprod.dbo.appointments a
JOIN ngprod.dbo.events e on e.event_id = a.event_id
WHERE a.create_timestamp >= @Start_Date AND a.create_timestamp <= @End_Date
AND [event] IN 
(
 'Specialty-MAB'
,'Specialty-APC'
,'Specialty-EPEM'
,'Specialty-TAB'
,'Specialty-CYTO'
,'Specialty-LAM1'
,'Specialty-LAM2'
)

alter table #appt
add qtr varchar(20),
	qtr_begin_date date, 
	qtr_end_date date


update #appt
set qtr = concat('Y', datepart(yy, cast(create_timestamp as date)), 'Q1')
where datepart(m,cast(create_timestamp as date)) between 1 and 3

update #appt
set qtr = concat('Y', datepart(yy, cast(create_timestamp as date)), 'Q2')
where datepart(m,cast(create_timestamp as date)) between 4 and 6

update #appt
set qtr = concat('Y', datepart(yy, cast(create_timestamp as date)), 'Q3')
where datepart(m,cast(create_timestamp as date)) between 7 and 9

update #appt
set qtr = concat('Y', datepart(yy, cast(create_timestamp as date)), 'Q4')
where datepart(m,cast(create_timestamp as date)) between 10 and 12

update #appt
set qtr_begin_date = datefromparts(datepart(year, cast(create_timestamp as date)), 1,1) 
where datepart(month, cast(create_timestamp as date)) between 1 and 3

update #appt
set qtr_end_date = datefromparts(datepart(year, cast(create_timestamp as date)), 3,31) 
where datepart(month, cast(create_timestamp as date)) between 1 and 3

update #appt
set qtr_begin_date = datefromparts(datepart(year, cast(create_timestamp as date)), 4,1) 
where datepart(month, cast(create_timestamp as date)) between 4 and 6

update #appt
set qtr_end_date = datefromparts(datepart(year, cast(create_timestamp as date)), 6,30) 
where datepart(month, cast(create_timestamp as date)) between 4 and 6

update #appt
set qtr_begin_date = datefromparts(datepart(year, cast(create_timestamp as date)), 7,1) 
where datepart(month, cast(create_timestamp as date)) between 7 and 9

update #appt
set qtr_end_date = datefromparts(datepart(year, cast(create_timestamp as date)), 9,30) 
where datepart(month, cast(create_timestamp as date)) between 7 and 9

update #appt
set qtr_begin_date = datefromparts(datepart(year, cast(create_timestamp as date)), 10,1) 
where datepart(month, cast(create_timestamp as date)) between 10 and 12

update #appt
set qtr_end_date = datefromparts(datepart(year, cast(create_timestamp as date)), 12,31) 
where datepart(month, cast(create_timestamp as date)) between 10 and 12


SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null, COUNT(*) numMABAppt, a.countDenominator countMABAppt, 
		count(*) * 1.0/ a.countDenominator percMABAppt
into #appt_mab
FROM #appt c
joIN (select qtr,count(*) countDenominator
		from #appt	
		where [event] = 'Specialty-MAB'  
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE [event] = 'Specialty-MAB' and diff <=5
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr

SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null, COUNT(*) numTAB5Appt, a.countDenominator countTAB5Appt, 
		count(*) * 1.0/ a.countDenominator percTAB5Appt
into #appt_5tab
FROM #appt c
joIN (select qtr,count(*) countDenominator
		from #appt	
		where [event] in ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO')
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE [event] in ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO') and diff <=5
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr


SELECT c.qtr,c.qtr_begin_date, c.qtr_end_date, tier = null, COUNT(*) numTAB7Appt, a.countDenominator countTAB7Appt, 
		count(*) * 1.0/ a.countDenominator percTAB5Appt
into #appt_7tab
FROM #appt c
joIN (select qtr,count(*) countDenominator
		from #appt	
		where [event] in ('Specialty-LAM1','Specialty-LAM2')
		group by qtr
	) a on c.qtr=a.qtr 
join (select * from #dq1 where qtr_begin is not null) n on n.begin_date = c.qtr_begin_date
WHERE [event] in ('Specialty-LAM1','Specialty-LAM2') and diff <=7
group by c.qtr, a.countDenominator,c.qtr_begin_date, c.qtr_end_date
order by qtr

/* **********************************************---------------------------------------********************************/

--#bci_meas,#bci_prev_meas,#lr_3mo,#lr_12mo,#bci_mab_ab,#bci_tab_ab_meas,#abRate1Yr,#app_gcct, #tmt_gcct,#ab_lr_3mo,#ab_lr_12mo,#r_abRate1Yr,#co_fup,#pap_fup
--alter table #bci_meas drop column descp 
--alter table #bci_prev_meas drop column descp 
--alter table #bci_mab_ab drop column descp 
--alter table #bci_tab_ab_meas drop column descp 


alter table #bci_meas
add descp varchar(max), 
	num varchar(max), 
	den varchar(max), 
	excl varchar(max)

alter table #bci_prev_meas
add descp varchar(max), 
	num varchar(max), 
	den varchar(max), 
	excl varchar(max)

alter table #bci_mab_ab
add descp varchar(max), 
	num varchar(max), 
	den varchar(max), 
	excl varchar(max)

alter table #bci_tab_ab_meas
add descp varchar(max), 
	num varchar(max), 
	den varchar(max), 
	excl varchar(max)

update #bci_meas
set descp = '% of females at risk of unintended pregnancy, who received hormonal birth control in a non-abortion visit', 
	num = 'Number of females 15-44 at risk of unintended pregnancy (UP)* who were dispensed Tier II (hormonal) birth control', 
	den = 'Total females 15-44 at risk of UP who had a visit where Tier I and Tier II birth control was dispensed.', 
	excl = 'Females with an abortion visit on the same day.'
where tier = '2'

update #bci_meas
set descp = '% of females at risk of unintended pregnancy, who received a LARC in a non-abortion visit', 
	num = 'Number of females 15-44 at risk of UP who were dispensed Tier I (Long-Acting Reverible Contraception / LARC) birth control ', 
	den = 'Total females 15-44 at risk of UP who had a visit where Tier I and Tier II birth control was dispensed.', 
	excl = 'Females with an abortion visit on the same day.'
where tier = '1'

update #bci_prev_meas
set descp = '% of females at risk of unintended pregnancy, who were using Tier II BC at their last visit', 
	num = 'Number of females 15-44 at risk of UP who were using Tier II (hormonal) birth control at their last visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where tier = '2'

update #bci_prev_meas
set descp = '% of females at risk of unintended pregnancy, who were using Tier I BC at their last visit', 
	num = 'Number of females 15-44 at risk of UP who were using Tier I  (LARC) birth control at their last visit ', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where tier = '1'

update #bci_mab_ab
set descp = '% of females who received a barrier contraception method at a MAB visit', 
	num = 'Number of females 15-44 who were dispensed Tier III (barrier) birth control at their last MAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where mintier = '3'

update #bci_mab_ab
set descp = '% of females who received hormonal contraception at a MAB visit',
	num = 'Number of females 15-44 who were dispensed Tier II (hormonal) birth control at their last MAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where mintier = '2'

update #bci_mab_ab
set descp = '% of females who received a LARC at a MAB visit', 
	num = 'Number of females 15-44 who were dispensed Tier I (LARC) birth control at their last MAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where mintier = '1'

update #bci_tab_ab_meas
set descp = '% of females who received a barrier contraception method at a TAB visit', 
	num = 'Number of females 15-44 who were dispensed Tier III (barrier) birth control at their last TAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where minTier = '3'

update #bci_tab_ab_meas
set descp = '% of females who received hormonal contraception at a TAB visit', 
	num = 'Number of females 15-44 who were dispensed Tier II (hormonal) birth control at their last TAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where minTier= '2'

update #bci_tab_ab_meas
set descp = '% of females who received a LARC at a TAB visit', 
	num = 'Number of females 15-44 who were dispensed Tier I (LARC) birth control at their last TAB visit', 
	den = 'Total females 15-44 at risk of UP who had a visit in the reporting period', 
	excl = ''
where minTier= '1'

/* **********************************************---------------------------------------********************************/


select header = 'CONTRACEPTION - INCIDENCE, BIRTH CONTROL METHOD DISPENSED', aim = 'Patient-Centered, Effective', metric='Birth Control Incidence',b1.*,  concat(countDistinctEnc, ' / ', bci_denom) txtPerc
into #combine_tables
from  #bci_meas b1

union all 

select header = 'CONTRACEPTION - INCIDENCE, BIRTH CONTROL METHOD DISPENSED', aim='Patient-Centered, Equitable', metric = '3-month Removal Rate for LARC', l1.*, descp = '% of females who had a LARC inserted and had it removed within 3 months', 
		num='Number of females 15-44 who had a LARC removed within 3 months of insertion', den = 'Total females 15-44 who had a LARC inserted', excl ='',
		concat(l3mo_num, ' / ', l3mo_dm) txtPerc
from #lr_3mo l1

union all 

select header = 'CONTRACEPTION - INCIDENCE, BIRTH CONTROL METHOD DISPENSED', aim='Effective', metric = '12-month Removal Rate for LARC',l2.*, descp = '% of females who had a LARC inserted and had it removed within 12 months', 
		 num='Number of females 15-44 who had a LARC removed within 12 months of insertion', den = 'Total females 15-44 who had a LARC inserted', excl ='', 
		 concat(l12mo_num, ' / ', l12mo_dm) txtPerc
from #lr_12mo l2

union all 

select header = 'CONTRACEPTION - PREVALENCE, BIRTH CONTROL METHOD AT END OF VISIT', aim = 'Patient-Centered, Effective', metric='Birth Control Prevalence',b2.*, concat(countUniquePersonTier, ' / ', bcPrevDenom) txtPerc
from #bci_prev_meas b2

union all 

select  header = 'CONTRACEPTION - PREVALENCE, BIRTH CONTROL METHOD AT END OF VISIT', aim='Effective', metric = '1-Year Abortion Rate',a1.*,  descp = '% of females who had an abortion within 1 year of their last non-abortion visit', 
		num='Number of females 15-44 who had an abortion within 1 year of their last non-abortion visit', den = 'Total females 15-44 at risk of UP who had a visit in the analysis period', 
		excl ='Females with an abortion visit on the same day; visits with a positive pregancy test', concat(numeratorABRate, ' / ', countVisits) txtPerc
from #abRate1Yr a1


union all 

select header = 'STI PREVENTION AND TREATMENT', aim='Effective, Patient-Centered', metric = ' % of patients who had risk factors and were appropriately tested for GC/CT', a2.*, 
		descp = 'Number of patients who had risk factors** and were tested in all sites (vaginal, urine, rectal, pharyngeal) per their reported exposure site(s)', 
		num='Number of patients who had risk factors** and were tested in all sites (vaginal, urine, rectal, pharyngeal) per their reported exposure site(s)', 
			den = 'Total patients who had risk factors', 
		excl ='' , concat(numeratorAppGCCT, ' / ', countRisk) txtPerc
from #app_gcct a2

union all 

select header = 'STI PREVENTION AND TREATMENT', aim='Timely, Efficient', metric = '% of patients who had a positive result and received treatment within 30 days', t1.*, 
		descp = 'Number of patients who had risk factors** and were tested in all sites (vaginal, urine, rectal, pharyngeal) per their reported exposure site(s)', 
		num='Number of patients who had a positive GC/CT result and received treatment within 30 days', 
			den = 'Total patients who had a positive GC/CT result', 
		excl ='' , concat(numeratorTreated, ' / ', countPos) txtPerc
from #tmt_gcct t1

union all 

select header = 'ABORTION CARE', aim = 'Timely, Patient-Centered, Equitable', metric='Abortion Access', 
		amab.*,  descp='% of MAB appointments scheduled within 5 days of contact', num='Number of MAB appointments scheduled within 5 days', 
		den = ' Total MAB appointments scheduled',excl='', concat(numMABAppt, ' / ', countMABAppt) txtPerc
from #appt_mab amab

union all 

select header = 'ABORTION CARE', aim = 'Timely, Patient-Centered, Equitable', metric='Abortion Access', 
		a5tab.*,  descp ='% of TAB 1-Day appointments scheduled within 5 days of contact', num='Number of TAB 1-day appointments scheduled within 5 days', 
		den = 'Total TAB 1-day appointments scheduled', excl='',concat(numTAB5Appt, ' / ', countTAB5Appt) txtPerc
from #appt_5tab a5tab

union all 

select header = 'ABORTION CARE', aim = 'Timely, Patient-Centered, Equitable', metric='Abortion Access', 
		a7tab.*,  descp ='% of TAB 2-Day appointments scheduled within 7 days of contact', num='Number of TAB 2-day appointments scheduled within 7 days', 
		den = ' Total TAB 2-day appointments scheduled',excl='',concat(numTAB7Appt, ' / ', countTAB7Appt) txtPerc
from #appt_7tab a7tab

union all 

select header = 'ABORTION CARE', aim = 'Patient-Centered, Effective', metric='Birth Control Incidence after Abortion',b3.*,  concat(countTierPerson, ' / ', countABPerson) txtPerc
from #bci_mab_ab b3

union all 


select header = 'ABORTION CARE',  aim = 'Patient-Centered, Effective', metric='Birth Control Incidence after Abortion', b4.*, concat(countTierPerson, ' / ', countABPerson) txtPerc
from #bci_tab_ab_meas b4

union all 

select header = 'ABORTION CARE', aim='Patient-Centered, Equitable', metric = '3-month Removal Rate for LARC after Abortion', a3.*,
		descp = '% of females who had a LARC inserted at an abortion visit and had it removed within 3 months', 
		 num='Number of females 15-44  who had a LARC removed within 3 months of insertion at an abortion visit', 
			den = 'Total females 15-44 who had a LARC inserted at an abortion visit', 
		excl ='' , concat(l3mo_num,' / ', l3mo_dm) txtPerc
from #ab_lr_3mo a3

union all 

select  header = 'ABORTION CARE', aim='Effective', metric = '12-month Removal Rate for LARC after Abortion', a4.*, 
		descp = '% of females who had a LARC inserted at an abortion visit and had it removed within 12 months', 
		num='Number of females 15-44  who had a LARC removed within 12 months of insertion at an abortion visit', 
			den = 'Total females 15-44 who had a LARC inserted at an abortion visit', 
		excl ='' , concat(l12mo_num,' / ', l12mo_dm) txtPerc
from #ab_lr_12mo a4

union all 

select  header = 'ABORTION CARE', aim='Effective', metric = '1-year Repeat Abortion Rate', a5.*, 
		descp = '% of females who had a repeat abortion within 1 year', 
		num='Number of females 15-44 who had an abortion within 1 year of their last abortion visit', 
			den = 'Total females 15-44 who had an abortion visit', 
		excl ='' , concat(numeratorABRate,' / ', countVisits) txtPerc
from #r_abRate1Yr a5

union all 

select header ='CERVICAL CANCER PREVENTION AND TREATMENT', aim='Effective, Timely, Equitable', metric = 'Timely Colpo Follow-up', c1.*, 
		descp = '% of female patients who had an abnormal colpo (CIN 2+) and received LEEP/Cryo at 3 months (<50 patients)', 
		num='Number of patients who had an abnormal colpo (CIN 2+) and received a LEEP/Cryo within 3 months', 
			den = 'Total patients who had an abnormal colpo (CIN 2+)', 
		excl ='' , concat(numeratorCryo,' / ', countColpo) txtPerc
from #co_fup c1

union all 

select header = 'CERVICAL CANCER PREVENTION AND TREATMENT', aim='Effective, Timely, Equitable', metric = 'Timely Pap Follow-up', p1.*, 
		descp = '% of female patients who had an abnormal pap and received colpo at 3 months', 
		num='Number of patients who needed a colpo and received it within 3 months', 
			den = 'Total patients who needed a colpo', 
		excl ='' , concat(numeratorPap,' / ', countPap) txtPerc
from #pap_fup p1



update #combine_tables
set qtr_end_Date = datefromparts(datepart(year, qtr_end_date), 12,31) 
where datepart(month,qtr_end_date) = 12


delete from ppreporting.dbo.Holistic_Report_Updated

insert into ppreporting.dbo.Holistic_Report_Updated
select header, aim, metric, descp, qtr, qtr_begin_date, qtr_end_date,concat(qtr_begin_date, ' - ',qtr_end_date), tier, countDistinctEnc, bci_denom, bci_meas, txtPerc, num, den, excl
from #combine_tables 

