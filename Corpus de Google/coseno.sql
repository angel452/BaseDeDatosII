use [Actividad05 - CorpusGoogle]
go

create view col1_4 
as
    select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.frecuencia_RealStems1,0) as w
    from RelStems1_Particionada_W v
    right join (select distinct 3 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
    from RelStems1_Particionada_W a
    where a.idLema1_RealStems1 = 1) as k
    on k.idLema1_RealStems1 = v.idLema1_RealStems1 
    and k.idLema2_RealStems1 = v.idLema2_RealStems1
    union all
    select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 3;

create view col1_5
as
    select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.frecuencia_RealStems1,0) as w
    from RelStems1_Particionada v
    right join (select distinct 1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as frecuencia_RealStems1
    from RelStems1_Particionada a
    where a.idLema1_RealStems1 = 3) as k
    on k.idLema1_RealStems1 = v.idLema1_RealStems1 
    and k.idLema2_RealStems1 = v.idLema2_RealStems1
    union all
    select  * from RelStems1_Particionada r where r.idLema1_RealStems1 = 1;


select k.idlema1,k.idlema2,sum(k.w)
from col1_4 k
group by k.idlema1, k.idlema2
order by k.idlema2

select k.idlema1,k.idlema2,sum(k.w)
from col1_5 k
group by k.idlema1, k.idlema2
order by k.idlema2

Select k.w,p.w FROM col1_4 k, col1_5 p

select 1, 3, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
from (select top 283 sum(k.w) as kw,sum(p.w) as pw
from col1_4 k
join col1_5 p
on k.idlema2 = p.idlema2
group by k.idlema1, k.idlema2, p.idlema1,p.idlema2
order by k.idlema2,p.idlema2) as l;

select v.raizRaicesTable FROM raicesTable2 v where v.idRaicesTable = 1 or v.idRaicesTable = 3

GO

CREATE PROCEDURE st_coseno
@par_id1 AS bigint,
@par_id2 AS bigint
AS
	create view columna1
	as
		select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.frecuencia_RealStems1,0) as w
		from RelStems1_Particionada v
		right join (select distinct @par_id1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as frecuencia_RealStems1
		from RelStems1_Particionada a
		where a.idLema1_RealStems1 = @par_id2) as k
		on k.idLema1_RealStems1 = v.idLema1_RealStems1 
		and k.idLema2_RealStems1 = v.idLema2_RealStems1
		union all
		select  * from RelStems1_Particionada r where r.idLema1_RealStems1 = @par_id1;

	create view columna2
	as
		select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.frecuencia_RealStems1,0) as w
		from RelStems1_Particionada v
		right join (select distinct @par_id2 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as frecuencia_RealStems1
		from RelStems1_Particionada a
		where a.idLema1_RealStems1 = @par_id1) as k
		on k.idLema1_RealStems1 = v.idLema1_RealStems1 
		and k.idLema2_RealStems1 = v.idLema2_RealStems1
		union all
		select  * from RelStems1_Particionada r where r.idLema1_RealStems1 = @par_id2;


	select @par_id2, @par_id1, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
	from (select top 1000 sum(k.w) as kw,sum(p.w) as pw
	from col1_4 k
	join col1_5 p
	on k.idlema2 = p.idlema2
	group by k.idlema1, k.idlema2, p.idlema1,p.idlema2
	order by k.idlema2,p.idlema2) as l


	

