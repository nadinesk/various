USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[qcc_comb_audits]    Script Date: 4/8/2020 1:44:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[qcc_comb_audits]
(
	@Start_Date datetime,
	@End_Date datetime
)

AS

set nocount on



IF OBJECT_ID('tempdb..##fp1_1') IS NOT NULL DROP TABLE ##fp1_1
IF OBJECT_ID('tempdb..##fp_2') IS NOT NULL DROP TABLE ##fp_2

IF OBJECT_ID('tempdb..##b1_1') IS NOT NULL DROP TABLE ##b1_1
IF OBJECT_ID('tempdb..##b_2') IS NOT NULL DROP TABLE ##b_2

IF OBJECT_ID('tempdb..##c1_1') IS NOT NULL DROP TABLE ##c1_1
IF OBJECT_ID('tempdb..##c_2') IS NOT NULL DROP TABLE ##c_2

IF OBJECT_ID('tempdb..##imp1_1') IS NOT NULL DROP TABLE ##imp1_1
IF OBJECT_ID('tempdb..##imp_2') IS NOT NULL DROP TABLE ##imp_2

IF OBJECT_ID('tempdb..##breast1_1') IS NOT NULL DROP TABLE ##breast1_1
IF OBJECT_ID('tempdb..##breast_2') IS NOT NULL DROP TABLE ##breast_2


IF OBJECT_ID('tempdb..##colpo1_1') IS NOT NULL DROP TABLE ##colpo1_1
IF OBJECT_ID('tempdb..##colpo_2') IS NOT NULL DROP TABLE ##colpo_2

IF OBJECT_ID('tempdb..##b1') IS NOT NULL DROP TABLE ##b1
IF OBJECT_ID('tempdb..##fp1') IS NOT NULL DROP TABLE ##fp1
IF OBJECT_ID('tempdb..##c1') IS NOT NULL DROP TABLE ##c1
IF OBJECT_ID('tempdb..##imp1') IS NOT NULL DROP TABLE ##imp1
IF OBJECT_ID('tempdb..##breast1') IS NOT NULL DROP TABLE ##breast1
IF OBJECT_ID('tempdb..##colpo1') IS NOT NULL DROP TABLE ##colpo1


--declare @Start_date date = '20190701'
--declare @end_date date = '20191231'

--drop table #p1, #p2, #comb_audits, #ca1, #t2, #t3, #t1

exec [pp_CQR_MAB_Audit_automation_prov_quarterly] @Start_Date=@Start_date, @End_Date=@End_date
exec [pp_FP_Audit_automation_prov_quarterly]  @Start_Date=@Start_date, @End_Date=@End_date
exec [pp_IUC_Audit_automation_prov_quarterly]  @Start_Date=@Start_date, @End_Date=@End_date
exec [pp_Implant_Audit_automation_prov_quarterly]  @Start_Date=@Start_date, @End_Date=@End_date
exec [pp_Breast_Audit_automation_provider_quarterly]  @Start_Date=@Start_date, @End_Date=@End_date
exec [pp_colpo_Audit_automation_quarterly] @Start_Date=@Start_date, @End_Date=@End_date




select distinct mab_description, mab_prov_id
into #p1
from ##b1
union all
select distinct fp_description, fp_prov_id
from ##fp1
union all
select distinct iuc_description, iuc_prov_id
from ##c1
union all
select distinct imp_description, imp_prov_id
from ##imp1
union all 
select distinct breast_provider, breast_prov_id
from ##breast1
union all 
select distinct colpo_description, colpo_prov_id
from ##colpo1


select distinct mab_description provider_name, mab_prov_id provider_id 
into #p2
from #p1

select distinct p.provider_name, 
				fp.fp_Q3_2019, fp.fp_Q4_2019,fp.fp_total_min_qtr, fp.fp_total_max_qtr, 
				b.mab_Q3_2019, b.mab_Q4_2019, b.mab_total_min_qtr, b.mab_total_max_qtr, 
				c.iuc_Q3_2019, c.iuc_Q4_2019, c.iuc_total_min_qtr, c.iuc_total_max_qtr, 
				imp.implant_Q3_2019, imp.implant_Q4_2019,imp.imp_total_min_qtr, imp.imp_total_max_qtr, 
				 breast.breast_Q3_2019, breast.breast_Q4_2019, breast.breast_total_min_qtr, breast.breast_total_max_qtr, 
				 colpo.colpo_Q3_2019, colpo.colpo_Q4_2019, colpo.colpo_total_min_qtr, colpo.colpo_total_max_qtr
into #comb_audits
from #p2 p
left join ##fp1 fp on fp.fp_description=p.provider_name
left join ##b1 b on b.mab_description=p.provider_name
left join ##c1 c on c.iuc_description=p.provider_name
left join ##imp1 imp on imp.imp_description=p.provider_name
left join ##breast1 breast on breast.breast_provider=p.provider_name
left join ##colpo1 colpo on colpo.colpo_description=p.provider_name



select  provider_name, fp_Q4_2019 FamilyPlanning, fp_Q4_2019-fp_Q3_2019 Q4_Q3_change
into #t1
from #comb_audits

alter table #t1
add provider varchar(100)

select p.provider_name, t.provider
into #t2
from #p2 p 
left join #t1 t on p.provider_name=t.provider_name


insert into #t2 (provider_name, provider)
select distinct provider_name, provider_name
from #t2

insert into #t2 (provider_name, provider)
select distinct provider_name, 'Change from Q3 to Q4'
from #t2

insert into #t2 (provider_name, provider)
select distinct provider_name, 'Agency Avg'
from #t2

insert into #t2 (provider_name, provider)
select distinct provider_name, 'Provider vs Agency Avg'
from #t2

insert into #t2 (provider_name, provider)
select distinct provider_name, 'Total N'
from #t2

alter table #t2 
add order_rank int

update #t2
set order_rank = 1 
where provider_name = provider

update #t2
set order_rank = 2 
where provider = 'Change from Q3 to Q4'

update #t2
set order_rank = 3 
where provider = 'Agency Avg'

update #t2
set order_rank = 4 
where provider = 'Provider vs Agency Avg'

update #t2
set order_rank = 5
where provider = 'Total N'


select * 
into #ca1
from #comb_audits

alter table #ca1
add fp_Agency_Avg float

update #ca1
set fp_Agency_Avg = (select avg(cast(fp_Q4_2019 as decimal(10,2))) 
						from #ca1
					)

alter table #ca1
add MAB_Agency_Avg float

update #ca1
set MAB_Agency_Avg = (select avg(cast(MAB_Q4_2019 as decimal(10,2))) 
						from #ca1
					)

alter table #ca1
add IUC_Agency_Avg float

update #ca1
set IUC_Agency_Avg = (select avg(cast(iuc_Q4_2019 as decimal(10,2))) 
						from #ca1
					)

alter table #ca1
add Implant_Agency_Avg float

update #ca1
set Implant_Agency_Avg = (select avg(cast(implant_Q4_2019 as decimal(10,2))) 
						from #ca1
					)


alter table #ca1
add Breast_Agency_Avg float

update #ca1
set Breast_Agency_Avg = (select avg(cast(breast_Q4_2019 as decimal(10,2))) 
						from #ca1
					)



alter table #ca1
add Colpo_Agency_Avg float

update #ca1
set Colpo_Agency_Avg = (select avg(cast(colpo_Q4_2019 as decimal(10,2))) 
						from #ca1
					)


select t.*
into #t3
from #t2 t


alter table #t3
add Family_Planning float

update #t3
set Family_Planning = fp_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set Family_Planning = fp_Q4_2019  - fp_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set Family_Planning = (select avg(cast(fp_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'


update #t3
set Family_Planning = fp_Q4_2019 - fp_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set Family_Planning = fp_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'


alter table #t3
add MAB float

update #t3
set MAB = mab_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set MAB = MAB_Q4_2019  - MAB_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set MAB = (select avg(cast(MAB_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'


update #t3
set MAB = MAB_Q4_2019 - MAB_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set MAB = mab_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'


alter table #t3
add IUC float

update #t3
set IUC = iuc_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set IUC = iuc_Q4_2019  - iuc_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set IUC = (select avg(cast(iuc_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'

update #t3
set IUC = iuc_Q4_2019 - IUC_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set IUC = iuc_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'


alter table #t3
add Implant float

update #t3
set Implant = implant_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set Implant = implant_Q4_2019  - implant_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set Implant = (select avg(cast(implant_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'


update #t3
set Implant = implant_Q4_2019 - Implant_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set Implant = imp_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'


alter table #t3
add Breast float

update #t3
set Breast = breast_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set Breast = breast_Q4_2019  - breast_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set Breast = (select avg(cast(breast_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'

update #t3
set Breast = breast_Q4_2019 - Breast_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set Breast = breast_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'

alter table #t3
add Colpo float

update #t3
set Colpo = colpo_Q4_2019  
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where t.provider_name=t.provider

update #t3
set Colpo = colpo_Q4_2019  - colpo_Q3_2019
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider = 'Change from Q3 to Q4'

update #t3
set Colpo = (select avg(cast(colpo_Q4_2019 as decimal(10,2))) 
						from #ca1 )
where provider='Agency Avg'

update #t3
set Colpo = colpo_Q4_2019 - Colpo_Agency_Avg
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Provider vs Agency Avg'

update #t3
set Colpo = colpo_total_max_qtr
from #ca1 c
join #t3 t on c.provider_name=t.provider_name
where provider='Total N'


delete from #t3
where provider is null

select distinct provider_name, provider category, order_rank, Family_Planning, MAB, IUC, Implant, Breast, Colpo
from #t3
order by provider_name, order_rank

