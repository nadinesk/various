declare @Start_Date date = '20190701'
declare @End_Date date = '20200630'

drop table #s1, #s2, #epem, #g1, #g2, #g3, #cmp, #st, #th1, #gahtpt, #epemComb, #gahtComb, #cmpComb, #stComb, #th1Comb, #cf1, #core4, #core4Comb, #combine

SELECT distinct 
		lm.location_name, 
		pp.enc_id, 
		pp.person_id,
		pp.service_item_id, 
		cast(pe.create_timestamp as date) DOS, 
		p.date_of_birth, 
		CAST((CONVERT(INT,CONVERT(CHAR(8),cast(pe.create_timestamp as date),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) age, 
		p.sex,
		p.race, 
		p.ethnicity
INTO #s1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
join ngprod.dbo.location_mstr lm	 ON lm.location_id = pe.location_id
WHERE (cast(pe.create_timestamp as date) between @Start_Date AND @End_Date)
AND (lm.location_name <> 'PPPSW Lab' and lm.location_name <> 'Clinical Services Planned Parenthood' and lm.location_name <> 'Planned Parenthood Pacific Southwest' )
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.delete_ind = 'N'
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

alter table #s1
add race_eth varchar(500), 
	sexual_practices varchar(500)

update #s1
set race_eth =case 
					when race like '%white%' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'White' 
					when  (race = '2- African American' or race = '2- African American/Black') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'African American'
					when (race = '3- Asian' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Asian'					
					when  ( race = '4- Pacific Islander' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Pacific Islander'
					when ( race = '7- Filipino'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Filipino'
					when  (race ='8- Middle Eastern'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Middle Eastern'
					when race = '5- Native American' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Native American'
					--when (race = '7- Other' or race = '7-Other' or race = '6-Multi-racial' or race is NULL or race='' or race='race-other') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'race-other'
					when (race LIKE '7-Other%' or race = '7- Other' or race like '%Multi-racial%' or race is NULL or race='' or race = '7- Other' or 
							race LIKE '6%' or race = '9- Declined To Specify' or race = '9- Declined To Specify' or  race='race-other' )  AND 
							(ethnicity != 'Hispanic or Latino' or ethnicity is null  ) 
							and race not like '%hispanic/latinx%' then 'Unknown/Declined to Specify'										
					when race is null and (ethnicity ='Unknown/Declined to specify' or ethnicity = 'Not Hispanic or Latino') then 'Unknown/Declined to Specify'										
					when race='6- Hispanic/Latinx' or race like '%hispanic/latinx%' or ethnicity = 'Hispanic or Latino' or race='Hispanic' then 'Hispanic'
					else concat(coalesce(race, ''), '-', coalesce(ethnicity, '')) 
				end 


update #s1
set sexual_practices = 'MM'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='m' 
and hpi.opt_sexual_partners = '1'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'MMW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='m' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'WW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='f' 
and hpi.opt_sexual_partners = '2'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'WMW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='f' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'MM'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1' and (chk_sp_vulvas is null or chk_sp_vulvas = '0')
and a.DOS >'20181031'

update #s1
set sexual_practices = 'MMW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1' and chk_sp_vulvas= '1'
and a.DOS >'20181031'

update #s1
set sexual_practices = 'WW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='f' 
and chk_sp_vulvas= '1' and (chk_sp_penis is null or chk_sp_penis = '0')
and a.DOS >'20181031'

update #s1
set sexual_practices = 'WMW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='f' 
and chk_sp_vulvas= '1' and chk_sp_penis ='1'
and a.DOS >'20181031'

update #s1
set sexual_practices = 'other'
where sexual_practices is null

drop table #mrDOS, #s2, #lgb
select location_name, person_id, max(DOS) maxDOS
into #mrDOS
from #s1
group by location_name, person_id

select location_name, person_id, max(DOS) maxDOSSameSex
into #lgb
from #s1
where sexual_practices !='other'
group by location_name, person_id

select s.*
into #s2
from #s1 s
join #mrDOS m on s.person_id = m.person_id and s.location_name = m.location_name and s.DOS = m.maxDOS

select s.*
into #lgb1
from #s1 s
join #lgb m on s.person_id = m.person_id and s.location_name = m.location_name and s.DOS = m.maxDOSSameSex



select s.location_name, 
		count(distinct s.person_id) countLT25, 
		t.countPt, 
		count(distinct s.persoN_id) * 1.0 / t.countPt percLt25
from #s2 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where age < 25
group by s.location_name, t.countPt
order by s.location_name

select s.location_name, count(distinct s.person_id) countSameSex, t.countPt, count(distinct s.persoN_id) * 1.0 / t.countPt percSameSex
from #lgb1 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where sexual_practices !='other'
group by s.location_name, t.countPt
order by s.location_name


select s.location_name, count(distinct s.person_id) countPOC, t.countPt, count(distinct s.persoN_id) * 1.0 / t.countPt percPOC
from #s2 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where race_eth not in ('White','Unknown/Declined to Specify')
group by s.location_name, t.countPt
order by s.location_name

select s.location_name, count(distinct s.person_id) countAfrAm, t.countPt, count(distinct s.persoN_id) * 1.0 / t.countPt percAfrAm
from #s2 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where race_eth ='African American'
group by s.location_name, t.countPt
order by s.location_name


/************ Combinations *****************************/

select s.location_name, 
		count(distinct s.person_id) countLT25_SameSex, 
		t.countPt, 
		count(distinct s.persoN_id) * 1.0 / t.countPt percLT25_SameSex		
from #lgb1 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
join (select location_name, count(distinct persoN_id) countPtSameSex
		from #lgb1
		where sexual_practices !='other'
		group by location_name) t1 on t1.location_name = s.location_name
join (select location_name, count(distinct persoN_id) countPtLT25
		from #s2
		where age < 25
		group by location_name) t2 on t2.location_name = s.location_name
where sexual_practices !='other' and age < 25
group by s.location_name, t.countPt, t1.countPtSameSex, t2.countPtLT25
order by s.location_name


select s.location_name, 
		count(distinct s.person_id) countLT25_POC, 
		t.countPt, 
		count(distinct s.persoN_id) * 1.0 / t.countPt percLt25_POC
from #s2 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where age < 25 and race_eth not in ('White','Unknown/Declined to Specify')
group by s.location_name, t.countPt
order by s.location_name

select s.location_name, 
		count(distinct s.person_id) countLT25_AfrAm, 
		t.countPt, 
		count(distinct s.persoN_id) * 1.0 / t.countPt percLt25_AfrAm
from #s2 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where age < 25 and race_eth ='African American'
group by s.location_name, t.countPt
order by s.location_name

select s.location_name, count(distinct s.person_id) countSameSex_POC, t.countPt, count(distinct s.persoN_id) * 1.0 / t.countPt percSameSex_POC
from #lgb1 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where sexual_practices !='other' and race_eth not in ('White','Unknown/Declined to Specify')
group by s.location_name, t.countPt
order by s.location_name

select s.location_name, count(distinct s.person_id) countSameSex_AfrAm, t.countPt, count(distinct s.persoN_id) * 1.0 / t.countPt percSameSex_AfrAm
from #lgb1 s
join (select location_name, count(distinct persoN_id) countPt 
		from #s2
		group by location_name) t on t.location_name = s.location_name
where sexual_practices !='other' and race_eth ='African American'
group by s.location_name, t.countPt
order by s.location_name

