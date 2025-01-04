use [Actividad05 - CorpusGoogle]
go

---------------------------- TABLA de raices --------------------------------------------
-- Creamos la tabla donde se guardara las raices con sus indices ----
create table raicesTable(
	raizRaicesTable varchar(50)
	)

-- Insertamos la informacion del txt en la tabla raicesTable -- 
BULK INSERT
	raicesTable
FROM
	'C:\Users\Angel\Documents\BDII_ProyectoFinal\Corpus de Google\raicestext.txt'
WITH(
	DATAFILETYPE='char',
	CODEPAGE = '65001',
	ROWTERMINATOR = '\n',
	FIRSTROW = 2
)

select 
	raizRaicesTable,
	ROW_NUMBER()over(order by raizRaicesTable) as idRaicesTable
into raicesTable2
from raicesTable

---------------------------- TABLA de relaciones de Stems --------------------------------------------
-- Creamos la tabla donde se guardara la relacion entre los lemas y sus pesos ----
create table RelStems1(
	idLema1_RealStems1 varchar(70),
	idLema2_RealStems1 varchar(70),
	frecuencia_RealStems1 bigint
	)

BULK INSERT
	RelStems1
FROM
	'C:\Users\Angel\Documents\BDII_ProyectoFinal\Corpus de Google\factorizados.txt'
WITH(
	CODEPAGE = '65001',
	FIELDTERMINATOR = '\t',
	ROWTERMINATOR = '0x0A',
	FIRSTROW = 2,
	ERRORFILE = 'C:\Users\Angel\Documents\BDII_ProyectoFinal\Corpus de Google\myRubbishData_log'
)

DROP INDEX IDX_idLema1_RealSteams1 ON RelStems1;
GO

select count(*) from RelStems1 --35526829
select count(*) from raicesTable2 --86763

ALTER TABLE RelStems1 ALTER COLUMN idLema1_RealStems1 bigint
ALTER TABLE RelStems1 ALTER COLUMN idLema2_RealStems1 bigint

----------------------- DIAGRAMA ENTIDAD RELACION  ------------------------------------
-- Objetivo: guardar en una tabla todos los valores de una tupla en base a una palabra que nosotros
-- escribamos. Por ejemplo:
-- Palabra: 'Leon'
-- Resultado en la tabla:

-- id | raiz1 | raiz1 | frecuencia
-- -------------------------------
--  1 |  Leon | bravo |     32
--  2 |  Leon | carnivoro | 32
--  1 |  Leon | africano|   32
-- -------------------------------

-- Actualizamos la tabla poniendo sus id's en vez de las palabras --
UPDATE RelStems1
SET 
	idLema1_RealStems1 = (SELECT idRaicesTable FROM raicesTable2 WHERE idLema1_RealStems1 = raizRaicesTable),
	idLema2_RealStems1 = (SELECT idRaicesTable FROM raicesTable2 WHERE idLema2_RealStems1 = raizRaicesTable)

-- Eliminamos los que tengan Null
DELETE FROM RelStems1 WHERE idLema1_RealStems1 is NULL or idLema2_RealStems1 is NULL

-- INDICES --
--raicesTable--
CREATE CLUSTERED INDEX IDX_idRaicesTable on raicesTable2
(idRaicesTable)

execute sp_helpindex 'raicesTable2' --verificar todos los indices

--RelStems1--
CREATE CLUSTERED INDEX IDX_idLema1_RealSteams1 on RelStems1
(idLema1_RealStems1)

execute sp_helpindex 'RelStems1' --verificar todos los indices

-- CONSULTA MAIN 1 --
IF OBJECT_ID('tempdb.dbo.#ResTableConsult', 'U') IS NOT NULL
  DROP TABLE #ResTableConsult; 

DBCC FREEPROCCACHE WITH NO_INFOMSGS
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS

SELECT idLema1_RealStems1, idLema2_RealStems1, frecuencia_RealStems1
INTO #ResTableConsult
FROM RelStems1
WHERE idLema1_RealStems1 = (
							select TOP 1 idRaicesTable from raicesTable2
							where raizRaicesTable = 'lion' )

UPDATE #ResTableConsult
SET 
	idLema1_RealStems1 = (SELECT TOP 1 raizRaicesTable FROM raicesTable2 WHERE idLema1_RealStems1 = idRaicesTable),
	idLema2_RealStems1 = (SELECT TOP 1 raizRaicesTable FROM raicesTable2 WHERE idLema2_RealStems1 = idRaicesTable)

select * from #ResTableConsult

-- CONSULTA MAIN 2 --
select c1.raizRaicesTable, c2.raizRaicesTable, m.frecuencia_RealStems1
from 
    RelStems1 m
join raicesTable2 c1 on c1.idRaicesTable = m.idLema1_RealStems1 and c1.raizRaicesTable = 'lion'
join raicesTable2 c2 on c2.idRaicesTable = m.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- TF - IDF - W
--TF
select 
	idLema1_RealStems1, 
	idLema2_RealStems1, 
	(frecuencia_RealStems1*1.0)/(
							select MAX(frecuencia_RealStems1) 
							from RelStems1
							where idLema1_RealStems1 = 1704) as TF
from RelStems1
where idLema1_RealStems1 = 1704

--IDF
select 
	M.idLema1_RealStems1, 
	M.idLema2_RealStems1,
	LOG( (select COUNT(*) from RelStems1) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) as IDF
from RelStems1 M
where M.idLema1_RealStems1 = 1704

--W
select 
	M.idLema1_RealStems1, 
	M.idLema2_RealStems1, 
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems1 where idLema1_RealStems1 = 1704))*( LOG( (select COUNT(*) from RelStems1) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from RelStems1 M
where idLema1_RealStems1 = 1704 

-- FINAL --
select 
	c1.raizRaicesTable, 
	c2.raizRaicesTable, 
	m.frecuencia_RealStems1,
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems1 where idLema1_RealStems1 = (select TOP 1 C3.idRaicesTable from raicesTable2 C3 where C3.raizRaicesTable = 'aal') ))*( LOG( (select COUNT(*) from RelStems1) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from 
    RelStems1 M
join raicesTable2 c1 on c1.idRaicesTable = M.idLema1_RealStems1 and c1.raizRaicesTable = 'aal'
join raicesTable2 c2 on c2.idRaicesTable = M.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- crear tabla W ....
create table RelStems1_Particionada_W(
	idLema1_RealStems1 bigint,
	idLema2_RealStems1 bigint,
	W float
	)

INSERT INTO RelStems1_Particionada_W
select 
	M.idLema1_RealStems1,
	M.idLema2_RealStems1,
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems1_Particionada where idLema1_RealStems1 = M.idLema1_RealStems1))*( LOG( (select COUNT(*) from RelStems1_Particionada) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1_Particionada Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
	from 
		RelStems1_Particionada M

select * from RelStems1_Particionada_W

-- Coseno
-- sacar vector
select sub.idlema1, sub.idlema2, sum(sub.w) as W_ordenado from 
(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
from RelStems1_Particionada_W v
right join (select distinct 86764 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
from RelStems1_Particionada_W a
where a.idLema1_RealStems1 = 1) as k
on k.idLema1_RealStems1 = v.idLema1_RealStems1 
and k.idLema2_RealStems1 = v.idLema2_RealStems1
union all
select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 86764) as sub
group by sub.idlema1, sub.idlema2
order by sub.idlema2

-- sacar coseno --usando views
select 1, 3, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
from (select top 283 sum(k.w) as kw,sum(p.w) as pw
		from col1_4 k
		join col1_5 p
		on k.idlema2 = p.idlema2
		group by k.idlema1, k.idlema2, p.idlema1,p.idlema2
		order by k.idlema2,p.idlema2) as l;

-- ambas juntas
select 1, 3, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
from 
		(select top 1000 sum(k1.W_ordenado) as kw,sum(p.W_ordenado) as pw
		from (
				select sub.idlema1, sub.idlema2, sub.w as W_ordenado from -- sum(sub.w) as W_ordenado from 
				(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
				from RelStems1_Particionada_W v
				right join (select distinct 3 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
				from RelStems1_Particionada_W a
				where a.idLema1_RealStems1 = 1) as k
				on k.idLema1_RealStems1 = v.idLema1_RealStems1 
				and k.idLema2_RealStems1 = v.idLema2_RealStems1
				union all
				select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 3) as sub
				--group by sub.idlema1, sub.idlema2
				--order by sub.idlema2
				) as k1
		join (
				select sub.idlema1, sub.idlema2, sub.w as W_ordenado from --sum(sub.w) as W_ordenado from 
				(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
				from RelStems1_Particionada_W v
				right join (select distinct 1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
				from RelStems1_Particionada_W a
				where a.idLema1_RealStems1 = 3) as k
				on k.idLema1_RealStems1 = v.idLema1_RealStems1 
				and k.idLema2_RealStems1 = v.idLema2_RealStems1
				union all
				select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 1) as sub
				--group by sub.idlema1, sub.idlema2
				--order by sub.idlema2
				) as p
		on k1.idlema2 = p.idlema2
		group by k1.idlema1, k1.idlema2, p.idlema1,p.idlema2
		order by k1.idlema2,p.idlema2) as l

go

declare @word1 as int
set @word1 = 1

select r1.idRaicesTable as lema1, r2.idRaicesTable as lema2, r1.idRaicesTable + r2.idRaicesTable as coseno
from raicesTable2 as r1
join raicesTable2 as r2 on r1.idRaicesTable in ( 
													select idRaicesTable from raicesTable2 
												) 
join (
		
		)
where r1.idRaicesTable = @word1
order by r1.idRaicesTable asc


--select l.campo1_l, l.campo2_l, 
select
							--case 
								--when (sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw)) = 0) then 0 --CAST(numerador AS FLOAT) / denominador
								--when (sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw)) > 0) then CAST(sum(l.kw*l.pw) AS FLOAT) / ( sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw)) )
							sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
							--end as cosine
from 
		--(select top 1000 p.idlema1 as campo1_l, p.idlema2, sum(p.W_ordenado) as pw, k1.idlema1 as campo2_l, k1.idlema2, sum(k1.W_ordenado) as kw
		(select top 1000 sum(p.W_ordenado) as pw, sum(k1.W_ordenado) as kw
		from (
				select sub.idlema1, sub.idlema2, sub.w as W_ordenado 
				from -- sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
					from RelStems1_Particionada_W v
					right join (
								select distinct 3 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
								from RelStems1_Particionada_W a
								where a.idLema1_RealStems1 = 1) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 3) as sub
				--group by sub.idlema1, sub.idlema2
				--order by sub.idlema2
				) as k1
		join (
				select sub.idlema1, sub.idlema2, sub.w as W_ordenado 
				from --sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
					from RelStems1_Particionada_W v
					right join (
								select distinct 1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
								from RelStems1_Particionada_W a
								where a.idLema1_RealStems1 = 3) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = 1) as sub
					--group by sub.idlema1, sub.idlema2
					--order by sub.idlema2
				) as p
		on k1.idlema2 = p.idlema2
		--where p.idlema2 = 1 and k1.idlema1 = 3
		--group by p.idlema1, k1.idlema1
		group by k1.idlema1, k1.idlema2, p.idlema1,p.idlema2
		--order by p.idlema2, k1.idlema1
		) as l
		--group by l.campo1_l, l.campo2_l
		--having (sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) > 0

-- test ambas juntas
-- aa es fijo
-- bb es el que varia
select *
from raicesTable2 as aa
	join raicesTable2 as bb on aa.idRaicesTable = 1
	join (select * from RelStems1_Particionada_W as aux1 where aa.IdRaicesTable = 1) as aux2 on aux2.idLema1_RealStems1 = 1
														-- no podemos usar idraicestable que proviende de aa

go

SELECT *
FROM raicesTable2 aa
	join raicesTable2 bb on aa.idRaicesTable = 1
	left join (
					select aa.IdRaicesTable as id1, bb.idRaicesTable as id2, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
					from 
							(
								select top 1000 sum(k1.W_ordenado) as kw,sum(p.W_ordenado) as pw
								from (
										select sub.idlema1, sub.idlema2, sub.w as W_ordenado from -- sum(sub.w) as W_ordenado from 
										(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
										from RelStems1_Particionada_W v
										right join (select distinct bb.idRaicesTable as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
													from RelStems1_Particionada_W a
													where a.idLema1_RealStems1 = aa.idRaicesTable) as k
										on k.idLema1_RealStems1 = v.idLema1_RealStems1 
										and k.idLema2_RealStems1 = v.idLema2_RealStems1
										union all
										select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = bb.idRaicesTable) as sub
										--group by sub.idlema1, sub.idlema2
										--order by sub.idlema2
										) as k1
								join (
										select sub.idlema1, sub.idlema2, sub.w as W_ordenado from --sum(sub.w) as W_ordenado from 
										(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
										from RelStems1_Particionada_W v
										right join (select distinct aa.idRaicesTable as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
										from RelStems1_Particionada_W a
										where a.idLema1_RealStems1 = bb.idRaicesTable) as k
										on k.idLema1_RealStems1 = v.idLema1_RealStems1 
										and k.idLema2_RealStems1 = v.idLema2_RealStems1
										union all
										select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = aa.idRaicesTable) as sub
										--group by sub.idlema1, sub.idlema2
										--order by sub.idlema2
										) as p
								on k1.idlema2 = p.idlema2
								group by k1.idlema1, k1.idlema2, p.idlema1,p.idlema2
								order by k1.idlema2,p.idlema2
							) as l
			  ) as ll 
						on ll.id1 = 1


-- Prueba Final
select j.raizRaicesTable, v.raizRaicesTable, z.coseno 
from Resultados as z
    join raicesTable2 j on z.idLema1_RealStems1 = j.idRaicesTable 
    join raicesTable2 v on z.idLema2_RealStems1 = v.idRaicesTable
    order by coseno desc

CREATE PROCEDURE prueba1
(@id1 AS bigint,
@id2 AS bigint)
AS
	select aa.idRaicesTable as id1rs, bb.idRaicesTable as id2rs, ll.cosine
	from raicesTable2 aa 
	join raicesTable2 bb on aa.idRaicesTable = @id1
	--set @id2 = bb.idRaicesTable
	right join (select @id1 as idd1, @id2 as idd2, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
	from 
			(select top 283 sum(k1.W_ordenado) as kw,sum(p.W_ordenado) as pw
			from (
					select sub.idlema1, sub.idlema2, sub.w as W_ordenado from -- sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce( v.W ,0) as w
					from RelStems1_Particionada_W v
					right join (select distinct @id1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
					from RelStems1_Particionada_W 
					right join raicesTable2 g on g.idRaicesTable = g.idRaicesTable
					where a.idLema1_RealStems1 = g.idRaicesTable) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = @id1) as sub
					--group by sub.idlema1, sub.idlema2
					--order by sub.idlema2
					) as k1
			join (
					select sub.idlema1, sub.idlema2, sub.w as W_ordenado from --sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
					from RelStems1_Particionada_W v
					right join (select distinct @id2 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
					from RelStems1_Particionada_W a
					where a.idLema1_RealStems1 = @id1) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = @id2) as sub
					--group by sub.idlema1, sub.idlema2
					--order by sub.idlema2
					) p
			on k1.idlema2 = p.idlema2
			group by k1.idlema1, k1.idlema2, p.idlema1,p.idlema2
			order by k1.idlema2,p.idlema2) as l) as ll on aa.idRaicesTable = ll.idd1
			--print id2rs



-- coseno de una palabra con todas en tablas distintas
drop procedure st_coseno
go

CREATE PROCEDURE st_coseno
(@par_id1 AS bigint,
@par_id2 AS bigint)
AS
	select @par_id1, @par_id2, sum(l.kw*l.pw)/(sqrt(sum(l.kw*l.kw))*sqrt(sum(l.pw*l.pw))) as cosine
	from 
			(select top 1000 sum(k1.W_ordenado) as kw,sum(p.W_ordenado) as pw
			from (
					select sub.idlema1, sub.idlema2, sub.w as W_ordenado from -- sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
					from RelStems1_Particionada_W v
					right join (select distinct @par_id2 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
					from RelStems1_Particionada_W a
					where a.idLema1_RealStems1 =@par_id1) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = @par_id2) as sub
					--group by sub.idlema1, sub.idlema2
					--order by sub.idlema2
					) as k1
			join (
					select sub.idlema1, sub.idlema2, sub.w as W_ordenado from --sum(sub.w) as W_ordenado from 
					(select distinct coalesce( v.idLema1_RealStems1,k.idLema1_RealStems1 ) as idlema1,coalesce(v.idLema2_RealStems1,k.idLema2_RealStems1) as idlema2,coalesce(v.W,0) as w
					from RelStems1_Particionada_W v
					right join (select distinct @par_id1 as idLema1_RealStems1, a.idLema2_RealStems1, 0 as W_a
					from RelStems1_Particionada_W a
					where a.idLema1_RealStems1 = @par_id2) as k
					on k.idLema1_RealStems1 = v.idLema1_RealStems1 
					and k.idLema2_RealStems1 = v.idLema2_RealStems1
					union all
					select  * from RelStems1_Particionada_W r where r.idLema1_RealStems1 = @par_id1) as sub
					--group by sub.idlema1, sub.idlema2
					--order by sub.idlema2
					) p
			on k1.idlema2 = p.idlema2
			group by k1.idlema1, k1.idlema2, p.idlema1,p.idlema2
			order by k1.idlema2,p.idlema2) as l


create table Resultados (
	idLema1_RealStems1 bigint,
	idLema2_RealStems1 bigint,
	coseno float
	)

CREATE CLUSTERED INDEX IDX_idLema1_RealSteams1R on Resultados
(idLema1_RealStems1)

execute sp_helpindex 'Resultados' --verificar todos los indices
go

CREATE PROCEDURE st_cosenoP
(@word1 AS bigint)
AS
	DECLARE @cnt INT = 1;
	WHILE @cnt < 86764
	BEGIN
   
	   insert into Resultados
	   exec st_coseno @word1, @cnt
	   SET @cnt = @cnt + 1;

	END;

	select * from Resultados 
	order by coseno desc

go

drop procedure st_cosenoP

---------------------- MAIN ---------------------
delete from Resultados

DECLARE @lema1 INT
set @lema1 = (select idRaicesTable from raicesTable2 where raizRaicesTable = 'book')
EXEC st_cosenoP @lema1
-------------------------------------------------

-- test --
DECLARE @lema1a INT
set @lema1a = (select idRaicesTable from raicesTable2 where raizRaicesTable = 'meat')
DECLARE @lema1b INT
set @lema1b = (select idRaicesTable from raicesTable2 where raizRaicesTable = 'ship')
exec st_coseno @lema1a, @lema1b

select * from RelStems1_Particionada_W where idLema1_RealStems1 = 40597 and idLema2_RealStems1 = 8937 order by W asc

insert into Resultados
exec st_coseno 1, 1

-- TEST Rendimiento --
DECLARE @cnt INT = 1;

WHILE @cnt < 86764
BEGIN
   select * from RelStems1
   where idLema1_RealStems1 = @cnt;
   SET @cnt = @cnt + 1;
END;

-- CONSULTAS ADICIONALES
select idRaicesTable from raicesTable2 where idRaicesTable > 20 and idRaicesTable <= 30

select * from RelStems1_Particionada_W
select * from RelStems1_Particionada order by idLema1_RealStems1 asc
select * from RelStems1 where idLema1_RealStems1 = 86763 --ultimo dato
select * from RelStems1_Particionada

select * from raicesTable2 where idRaicesTable = 9999
select * from raicesTable2 

select count(*) from RelStems1 --35526829
select count(*) from raicesTable2 --86763

select * from raicesTable2 where idRaicesTable = 40597
select * from raicesTable2 where idRaicesTable = 492

select * from raicesTable2 where raizRaicesTable = 'lion'
select * from raicesTable2 where raizRaicesTable = 'book'
