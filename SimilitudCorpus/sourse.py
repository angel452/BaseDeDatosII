
def analyze():
	val1 = ["leon",89,32,21,2,1,0,0]
	val1_cop = generararr(val1)
	val2 = ["tigre",89,32,21,2,1,0,0]
	val2_cop = generararr(val2)
	val3 = ["Dios",89,32,21,2,1,0,0]
	val3_cop = generararr(val3)
	val4 = ["buda",89,32,21,2,1,0,0]
	val4_cop = generararr(val4)
	val_num = generar_num(val1,val2)
	res = val_num/(val1*val2)
	return res;

def generararr(val):
	for i in range(1,len(val)):
		val += val[i]*val[i]
	return val
def generar_num(val1, val2):
	for i in range(1,len(val)):
		val += val1[i]*val2[i]
	return val	

int main(): 
	print(analyze());