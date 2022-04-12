archivo_texto = open("texto2.txt", "r", encoding="utf8")
new_text = archivo_texto.read()

print(new_text)
print("hello")

archivo_texto.close()