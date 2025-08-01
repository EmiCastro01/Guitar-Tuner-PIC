import tkinter as tk

root = tk.Tk()
root.title("Afinador de guitarra")


canvas = tk.Canvas(root, width=600, height=500)
canvas.pack()
barra = canvas.create_rectangle(50, 10, 550, 40, fill="red", offset="center") #buscar como hacer para centrar la barra 

def actualizar_barra(afinacion):
    if afinacion < -10:
        color = "red"
    elif afinacion > 10:
        color = "red"
    else:
        color = "green"
    canvas.itemconfig(barra, fill=color)

# Simulo la afinacion d la guitarra
for afinacion in range(-20, 21):
    actualizar_barra(afinacion)
    root.update()
    root.after(100)

root.mainloop()