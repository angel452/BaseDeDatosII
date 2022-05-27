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
join raicesTable2 c1 on c1.idRaicesTable = m.idLema1_RealStems1 and c1.raizRaicesTable = 'god'
join raicesTable2 c2 on c2.idRaicesTable = m.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- CONSULTA # de lemas --
select count(*) 
from raicesTable2

-- CONSULTA # de relaciones --
select count(*) 
from RelStems1

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
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems1 where idLema1_RealStems1 = (select TOP 1 C3.idRaicesTable from raicesTable2 C3 where C3.raizRaicesTable = 'god') ))*( LOG( (select COUNT(*) from RelStems1) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from 
    RelStems1 M
join raicesTable2 c1 on c1.idRaicesTable = M.idLema1_RealStems1 and c1.raizRaicesTable = 'god'
join raicesTable2 c2 on c2.idRaicesTable = M.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- Consluta para llevar a python --
create view temp_ids as 
select
	idRaicesTable
from raicesTable2
where raizRaicesTable = 'god'

create view temp_rel as
select distinct 
	idLema2_RealStems1
from RelStems1
where idLema1_RealStems1 = 10110 or idLema1_RealStems1 = 29885

create view temp_res2 as
select 
	 idRaicesTable,idLema2_RealStems1
from temp_ids s
cross join temp_rel

select
	*
from RelStems1
where idLema1_RealStems1 = 10110

select
	temp_res2.idRaicesTable,
	temp_res2.idLema2_RealStems1,
	isnull(v.frecuencia_RealStems1,0)
from temp_res2
left join ( select
				*
			from RelStems1
			where idLema1_RealStems1 = 10110) V
on temp_res2.idLema2_RealStems1 = V.idLema2_RealStems1
order by idLema2_RealStems1 asc