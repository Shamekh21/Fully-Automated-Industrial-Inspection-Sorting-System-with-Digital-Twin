import serial
import serial.tools.list_ports
import socket
import sys

# 🌟 The port (19001) so as not to conflict with the copy 🌟
SOCKET_HOST = '127.0.0.1'
SOCKET_PORT = 19001

def find_arduino():
    # find the Arduino automatically
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if "Arduino" in p.description or "CH340" in p.description or "USB Serial Device" in p.description or "Serial" in p.description:
            return p.device
    return "COM10" # اYour default port if you can't find it

def main():
    arduino_port = find_arduino()
    try:
        ser = serial.Serial(arduino_port, 9600, timeout=1)
        print(f"✅ [Serial] Connected to Arduino on {arduino_port} ...")
    except Exception as e:
        print(f"❌ [Serial] Failed to connect to Arduino on {arduino_port}: {e}")
        print("اتأكد إن الأردوينو متوصل، وإن مفيش برنامج تاني (زي السيريال مونيتور) فاتحه.")
        sys.exit(1)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # How to fix a stuck port in Windows
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
    
    server.bind((SOCKET_HOST, SOCKET_PORT))
    server.listen(1)
    print(f"✅ [Socket] Bridge is LIVE and listening on port {SOCKET_PORT} ...")

    while True:
        try:
            conn, addr = server.accept()
            data = conn.recv(1024).decode('utf-8')
            if data:
                print(f"📥 Received from AI: {data.strip()}")
                ser.write(data.encode('utf-8')) # Send to Arduino
            conn.close()
        except KeyboardInterrupt:
            print("\n🛑 [Bridge] Shutting down...")
            break
        except Exception as e:
            print(f"⚠️ Error: {e}")

    ser.close()
    server.close()

if __name__ == "__main__":
    main()
