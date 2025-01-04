use [Actividad05 - CorpusGoogle]
go
-- RANGE PARTITIONI
sp_helpdb [Actividad05 - CorpusGoogle] -- ver cuantos files tenemos

-- Creamos los filesgroup
ALTER DATABASE [Actividad05 - CorpusGoogle]
ADD FILEGROUP Corpus_1

ALTER DATABASE [Actividad05 - CorpusGoogle]
ADD FILEGROUP Corpus_2

ALTER DATABASE [Actividad05 - CorpusGoogle]
ADD FILEGROUP Corpus_3

ALTER DATABASE [Actividad05 - CorpusGoogle]
ADD FILEGROUP Corpus_4
go

ALTER DATABASE [Actividad05 - CorpusGoogle]
ADD FILEGROUP Corpus_5
go

-- Asociamos cada file 
ALTER DATABASE [Actividad05 - CorpusGoogle]
	ADD FILE
	(
	NAME = Corpus_1,
	FILENAME = 'C:\Users\Angel\Documents\CorpusFileGroup\Corpus_1.ndf',
		SIZE = 10 MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 64 MB
	) TO FILEGROUP Corpus_1

ALTER DATABASE [Actividad05 - CorpusGoogle]
	ADD FILE
	(
	NAME = Corpus_2,
	FILENAME = 'C:\Users\Angel\Documents\CorpusFileGroup\Corpus_2.ndf',
		SIZE = 10 MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 64 MB
	) TO FILEGROUP Corpus_2

ALTER DATABASE [Actividad05 - CorpusGoogle]
	ADD FILE
	(
	NAME = Corpus_3,
	FILENAME = 'C:\Users\Angel\Documents\CorpusFileGroup\Corpus_3.ndf',
		SIZE = 10 MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 64 MB
	) TO FILEGROUP Corpus_3

ALTER DATABASE [Actividad05 - CorpusGoogle]
	ADD FILE
	(
	NAME = Corpus_4,
	FILENAME = 'C:\Users\Angel\Documents\CorpusFileGroup\Corpus_4.ndf',
		SIZE = 10 MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 64 MB
	) TO FILEGROUP Corpus_4

ALTER DATABASE [Actividad05 - CorpusGoogle]
	ADD FILE
	(
	NAME = Corpus_5,
	FILENAME = 'C:\Users\Angel\Documents\CorpusFileGroup\Corpus_5.ndf',
		SIZE = 10 MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 64 MB
	) TO FILEGROUP Corpus_5


-- Crear Funcion 
CREATE PARTITION FUNCTION [FP_Corpus] (int)
AS RANGE LEFT FOR VALUES (17400,34800,52200,69600)

CREATE PARTITION FUNCTION [FP2_Corpus] (bigint) -- usamos esta
AS RANGE LEFT FOR VALUES (17400,34800,52200,69600)

1 -> 0     17400
2    17401 34800
3    34801 52200
4    52201 69600
5    69000   -

1 -> 0     3 600 000
2    -     7 200 000
3    34801 10 800 000
4    52201 14 400 000
5    69000 18 000 000
           21 600 000
		   25 200 000
		   28 800 000
		   32 400 000
	   -   -

--35526829

-- Creamos Esquema
CREATE PARTITION SCHEME Particionamiento
AS PARTITION [FP_Corpus]
TO ([PRIMARY], Corpus_1, Corpus_2, Corpus_3,Corpus_4)

CREATE PARTITION SCHEME Particionamiento2 --usamos esta
AS PARTITION [FP2_Corpus]
TO ([PRIMARY], Corpus_1, Corpus_2, Corpus_3,Corpus_4)

-- Creamos nueva tabla particionada
drop table RelStems1_Particionada

create table RelStems1_Particionada(
	idLema1_RealStems1 bigint,
	idLema2_RealStems1 bigint,
	frecuencia_RealStems1 bigint
	) ON Particionamiento2 (idLema1_RealStems1)

-- Insertamos datos a la nueva tabla
insert into RelStems1_Particionada
SELECT [idLema1_RealStems1]
      ,[idLema2_RealStems1]
      ,[frecuencia_RealStems1]
  FROM [Actividad05 - CorpusGoogle].[dbo].[RelStems1]

-- Comprobamos cuantos datos estan en cada particion
SELECT 
t.name AS TableName, 
--i.name AS field, 
fg.name,
p.partition_number,
r.value AS BoundaryValue ,
rows
From Sys.Tables AS t 
Join Sys.Indexes AS i On t.object_id = i.object_id
Join sys.partitions AS p On i.object_id = p.object_id And i.index_id = p.index_id 
INNER JOIN sys.allocation_units au ON au.container_id = p.hobt_id 
INNER JOIN sys.filegroups fg ON fg.data_space_id = au.data_space_id
Join  sys.partition_schemes AS s On i.data_space_id = s.data_space_id
Join sys.partition_functions AS f ON s.function_id = f.function_id
Left Join sys.partition_range_values AS r On  f.function_id = r.function_id and r.boundary_id = p.partition_number
Where i.type <= 1 ---t.name = 'Producto1' and
Order By p.partition_number;

-- Probamos con consultas
-- W
select 
	c1.raizRaicesTable, 
	c2.raizRaicesTable, 
	m.frecuencia_RealStems1,
	((frecuencia_RealStems1*1.0)/( select MAX(frecuencia_RealStems1) from RelStems1_Particionada where idLema1_RealStems1 = (select TOP 1 C3.idRaicesTable from raicesTable2 C3 where C3.raizRaicesTable = 'dog') ))*( LOG( (select COUNT(*) from RelStems1_Particionada) / (select 
													count(Z.idLema2_RealStems1)
											from RelStems1_Particionada Z 
											where Z.idLema2_RealStems1 = M.idLema2_RealStems1
											group by Z.idLema2_RealStems1) ) ) as W
from 
    RelStems1_Particionada M
join raicesTable2 c1 on c1.idRaicesTable = M.idLema1_RealStems1 and c1.raizRaicesTable = 'dog'
join raicesTable2 c2 on c2.idRaicesTable = M.idLema2_RealStems1 
order by frecuencia_RealStems1 desc

-- Rendimiento:
select *
from RelStems1_Particionada z
left join raicesTable2 v on v.idRaicesTable = z.idLema1_RealStems1
order by v.idRaicesTable

-- Consultas adicionales
select * from RelStems1
select * from RelStems1_Particionada
select count(*) from RelStems1_Particionada --35526829