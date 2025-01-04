use [Actividad03-usetxt]
go

---------------------------- TABLA de raices --------------------------------------------
-- Creamos la tabla donde se guardara las raices con sus indices ----
create table raicesTable(
	raizRaicesTable varchar(50),
	idRaicesTable int
	)
-- Insertamos la informacion del txt en la tabla raicesTable -- 
BULK INSERT
	raicesTable
FROM
	'C:\Users\Angel\Documents\BDII_ProyectoFinal\Corpus de Google\raicesdefinitesinid.txt'
WITH(
	DATAFILETYPE='char',
	DATAFILETYPE='int',
	CODEPAGE = '65001',
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	FIRSTROW = 2
)

---------------------------- TABLA de relaciones de Stems --------------------------------------------
-- Creamos la tabla donde se guardara la relacion entre los lemas y sus pesos ----
create table RelStems1(
	idLema1_RealStems1 varchar(70),
	idLema2_RealStems1 varchar(70),
	frecuencia_RealStems1 bigint
	)

-- Insertamos la informacion del txt en la tabla RelStems1 -- 
BULK INSERT
	RelStems1
FROM
	'C:\Users\Angel\Documents\BDII_ProyectoFinal\Corpus de Google\relstems.txt'
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
	idLema1_RealStems1 = (SELECT idRaicesTable FROM raicesTable WHERE idLema1_RealStems1 = raizRaicesTable),
	idLema2_RealStems1 = (SELECT idRaicesTable FROM raicesTable WHERE idLema2_RealStems1 = raizRaicesTable)

UPDATE RelStems1
SET 
	idLema1_RealStems1 = (SELECT TOP 1 idRaicesTable FROM raicesTable WHERE idLema1_RealStems1 = raizRaicesTable),
	idLema2_RealStems1 = (SELECT TOP 1 idRaicesTable FROM raicesTable WHERE idLema2_RealStems1 = raizRaicesTable)

-- Eliminamos los que tengan Null
DELETE FROM RelStems1 WHERE idLema1_RealStems1 is NULL or idLema2_RealStems1 is NULL

-- Pasamos un filtro de factorizado mas a la tabla RelStems1 y guardamos la informacion en RealStems2
SELECT idLema1_RealStems1, idLema2_RealStems1, SUM(frecuencia_RealStems1) as 'frecuencia_RealStems1'
INTO RelStems2
FROM RelStems1
GROUP BY idLema1_RealStems1, idLema2_RealStems1

-- INDICES --
--raicesTable--
CREATE CLUSTERED INDEX IDX_idRaicesTable on raicesTable
(idRaicesTable)

execute sp_helpindex 'raicesTable' --verificar todos los indices

--RelStems2--
CREATE CLUSTERED INDEX IDX_idLema1_RealSteams1 on RelStems2
(idLema1_RealStems1)

execute sp_helpindex 'RelStems1' --verificar todos los indices

-- CONSULTA MAIN 1 --
IF OBJECT_ID('tempdb.dbo.#ResTableConsult', 'U') IS NOT NULL
  DROP TABLE #ResTableConsult; 

DBCC FREEPROCCACHE WITH NO_INFOMSGS
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS

SELECT idLema1_RealStems1, idLema2_RealStems1, frecuencia_RealStems1
INTO #ResTableConsult
FROM RelStems2 
WHERE idLema1_RealStems1 = (
							select TOP 1 idRaicesTable from raicesTable 
							where raizRaicesTable = 'angel' )

UPDATE #ResTableConsult
SET 
	idLema1_RealStems1 = (SELECT TOP 1 raizRaicesTable FROM raicesTable WHERE idLema1_RealStems1 = idRaicesTable),
	idLema2_RealStems1 = (SELECT TOP 1 raizRaicesTable FROM raicesTable WHERE idLema2_RealStems1 = idRaicesTable)

select * from #ResTableConsult

-- CONSULTA MAIN 2 --
select	
	R.raizRaicesTable, S.idLema2_RealStems1, S.frecuencia_RealStems1
from raicesTable R, RelStems2 S
where R.raizRaicesTable = 'angel' and R.idRaicesTable = S.idLema1_RealStems1

-- CONSULTA MAIN 3 --
select c1.raizRaicesTable, c2.raizRaicesTable, m.frecuencia_RealStems1
from 
    RelStems2 m
join raicesTable c1 on c1.idRaicesTable = m.idLema1_RealStems1 and c1.raizRaicesTable = 'god'
join raicesTable c2 on c2.idRaicesTable = m.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- CONSULTA # de lemas --
select count(*) 
from raicesTable

-- CONSULTA # de relaciones --
select count(*) 
from RelStems2

-- TF - IDF - W
--TF
select 
	idLema1_RealStems1, 
	idLema2_RealStems1, 
	(frecuencia_RealStems1*1.0)/(
							select MAX(frecuencia_RealStems1) 
							from RelStems2 
							where idLema1_RealStems1 = 1704) as TF
from RelStems2
where idLema1_RealStems1 = 1704

--IDF
select 
	M.idLema1_RealStems1, 
	M.idLema2_RealStems1,
	LOG( (select COUNT(*) from RelStems2) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems2 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) as IDF
from RelStems2 M
where M.idLema1_RealStems1 = 1704


--W
select 
	M.idLema1_RealStems1, 
	M.idLema2_RealStems1, 
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems2 where idLema1_RealStems1 = 1704))*( LOG( (select COUNT(*) from RelStems2) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems2 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from RelStems2 M
where idLema1_RealStems1 = 1704 

-- FINAL --
select 
	c1.raizRaicesTable, 
	c2.raizRaicesTable, 
	m.frecuencia_RealStems1,
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems2 where idLema1_RealStems1 = (select TOP 1 C3.idRaicesTable from raicesTable C3 where C3.raizRaicesTable = 'market') ))*( LOG( (select COUNT(*) from RelStems2) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems2 Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from 
    RelStems2 M
join raicesTable c1 on c1.idRaicesTable = M.idLema1_RealStems1 and c1.raizRaicesTable = 'market'
join raicesTable c2 on c2.idRaicesTable = M.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- Consluta para llevar a python --
select c1.raizRaicesTable, c3.raizRaicesTable, m.frecuencia_RealStems1
from 
    RelStems2 m
join RelStems2 v on m.idLema2_RealStems1 = v.idLema2_RealStems1 and m.idLema1_RealStems1 = 'god'
join raicesTable c1 on c1.idRaicesTable = m.idLema1_RealStems1 and c1.raizRaicesTable = 'god'
join raicesTable c3 on c3.idRaicesTable = m.idLema1_RealStems1 and c3.raizRaicesTable = 'buda'
join raicesTable c2 on c3.idRaicesTable = m.idLema2_RealStems1 and c1.idRaicesTable = m.idLema2_RealStems1 

--obtener los ids de las palabras (select)
--hacer un select que me muestre la relacion con la columna idLema_relStem1 (distinct)
--hacer un crosjoin entre los 2 select junto join left 

select 
	idRaicesTable
from raicesTable2
where idRaicesTable = 'god' and idRaicesTable = 'buda'

select m.raizRaicesTable, v.raizRaicesTable, m.frecuencia_RealStems1
from RelStems2 m
join RelStems2 v on m.idLema2_RealStems1 = v.idLema2_RealStems1 and (select raices table z on z.idRaicesTable = v.idLema1_RealStems1 and z.raizRaicesTable = 'god')

select 
	M1.idLema1_RealStems1, M2.idLema1_RealStems1
from RelStems2 M1
full join RelStems2 M2
on M1.idLema2_RealStems1 = M2.idLema2_RealStems1 and M1.idLema1_RealStems1 = 243 and M2.idLema1_RealStems1 = 543

select 
	*
from 
    RelStems2 m
full join raicesTable c
on c.raizRaicesTable = 'buda' and c.raizRaicesTable = 'god'



-- consultas adicionales --
SELECT * from raicesTable where raizRaicesTable = 'angel' --1704
select * from raicesTable;
select raizRaicesTable+1, idRaicesTable from raicesTable where idRaicesTable = 1
drop table raicesTable;
select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'raicesTable';


select * from RelStems1;
select idLema1_RealStems1, idLema2_RealStems1, frecuencia_RealStems1 from RelStems1 where idLema1_RealStems1 = 1 and idLema2_RealStems1 = 3401
select * from RelStems1 where idLema1_RealStems1 = 1 and idLema2_RealStems1 = 3401
drop table RelStems1;
select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'RelStems1';

select * from RelStems2
select idLema1_RealStems1, idLema2_RealStems1, frecuencia_RealStems1 from RelStems2 where idLema1_RealStems1 = 1 and idLema2_RealStems1 = 3401





--backup
--prueba de division con decimales
select 
	idLema1_RealStems1, 
	idLema2_RealStems1, 
	convert( decimal (10,2), (frecuencia_RealStems1/100) )
from RelStems2
where idLema1_RealStems1 = 1704

-- Oficial de como sacar decimales
select 
	idLema1_RealStems1, 
	idLema2_RealStems1, 
	(frecuencia_RealStems1 * 1.0) /100
from RelStems2
where idLema1_RealStems1 = 1704

--test w
select 
	idLema1_RealStems1, 
	idLema2_RealStems1, 
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems2 where idLema1_RealStems1 = 1704))*(  )
from RelStems2
where idLema1_RealStems1 = 1704 
