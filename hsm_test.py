import serial
import time

# Change this to your actual serial port when CP2102 arrives
# On Windows it will be something like COM3, COM4 etc
# In WSL it will be /dev/ttyUSB0 or /dev/ttyS3
PORT = '/dev/ttyUSB0'
BAUD = 115200

def send_command(ser, cmd, payload=None):
    packet = bytes([cmd])
    if payload:
        packet += bytes([len(payload)]) + bytes(payload)
    else:
        packet += bytes([0])
    ser.write(packet)
    time.sleep(0.1)
    return ser.read(ser.in_waiting)

def encrypt(ser, plaintext_hex):
    payload = bytes.fromhex(plaintext_hex)
    ser.write(bytes([0x02, 0x10]) + payload)
    time.sleep(0.5)
    response = ser.read(ser.in_waiting)
    if response and response[0] == 0xAA:
        return response[1:17].hex()
    return None

with serial.Serial(PORT, BAUD, timeout=1) as ser:
    print("Connected to HSM")
    
    # KEYGEN
    ser.write(bytes([0x01, 0x00]))
    time.sleep(0.1)
    resp = ser.read(ser.in_waiting)
    print(f"KEYGEN response: {resp.hex()}")
    
    # ENCRYPT test block
    plaintext = "00000000000000000000000000000000"
    print(f"Encrypting: {plaintext}")
    ciphertext = encrypt(ser, plaintext)
    print(f"Ciphertext: {ciphertext}")
