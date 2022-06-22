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
    
def analyze():
    
    array1 = [89,32,21,2,0,0]
    array2 = [79,1,0,2,89,98]
    
    a = num(array1,array2)
    b = den(array1)
    c = den(array2)

    return a/(b*c)


print(analyze())