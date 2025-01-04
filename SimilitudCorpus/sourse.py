#before running... pip install pyodbc
import pyodbc
from math import sqrt

def den(arr):
    val = 0
    for i in range(0,len(arr)):
        val = val + (arr[i]*arr[i])
    return sqrt(val)

def num(arr1, arr2):
    val = 0
    for i in range(0,len(arr1)):
        val = val + (arr1[i]*arr2[i])
    return val
    
def analyze2():
    
    array1 = [89,32,21,2,0,0]
    array2 = [79,1,0,2,89,98]
    
    a = num(array1,array2)
    b = den(array1)
    c = den(array2)

    return a/(b*c)

def analyze(array1, array2):
    
    a = num(array1,array2)
    b = den(array1)
    c = den(array2)

    return a/(b*c)
 
#variables...
direccion_servidor = 'LAPTOP-ANGEL'
nombre_bd = 'Actividad05 - CorpusGoogle'
nombre_usuario = 'sa'
password = '123456789huarachi'
try:
    conexion = pyodbc.connect('DRIVER={SQL Server};SERVER=' +
                              direccion_servidor+';DATABASE='+nombre_bd+';UID='+nombre_usuario+';PWD=' + password)
    # OK! conexión exitosa
    print("Conexcion exitosa")
    
    # -------------------------------------------------------------------------------------------------------    
    #Para sacar el primer arr
    cursor1 = conexion.cursor()
    consulta = 'select idRaicesTable from raicesTable2 where idRaicesTable > 20 and idRaicesTable <= 30'
    cursor1.execute(consulta) #cursor.execute(consulta, 'man') #'man' reemplaza el ?
    rows1 = cursor1.fetchall()
    
    list_dict1 = []
    for row in rows1:
        list_dict1.append(row[0])
    
    #Para sacar el segundo arr
    cursor2 = conexion.cursor()
    consulta2 = 'select idRaicesTable from raicesTable2 where idRaicesTable > 20 and idRaicesTable <= 30'
    cursor2.execute(consulta2)
    rows2 = cursor2.fetchall()
    
    list_dict2 = []
    for row in rows2:
        list_dict2.append(row[0])
    
    print(analyze(list_dict1, list_dict2))
    
    # --------------------------------------------------------------------------------------------------
except Exception as ex:
    # Atrapar error
    print("Ocurrió un error al conectar a SQL Server: ", ex)
    
