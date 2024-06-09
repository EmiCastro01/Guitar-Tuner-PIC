import serial

def main():
    # Configurar el puerto serie
    ser = serial.Serial('COM3', 9600, timeout=1)
    
    try:
        while True:
            if ser.in_waiting > 0:
                byte_received = ser.read(1)
                # Mostrar el byte recibido
                print(f'Byte recibido: {byte_received}')
                print(f'Caracter recibido: {byte_received.decode("utf-8")}')
    except KeyboardInterrupt:
        print("Terminando el programa.")
    finally:
        ser.close()

if __name__ == "__main__":
    main()