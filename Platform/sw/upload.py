import os, sys, serial, time, threading
import serial.tools.list_ports

def find_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if "USB" in p.device or "Digilent" in p.description:
            return p.device
    return None

def kb_terminal(ser, stop_event):
    import tty, termios
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(sys.stdin.fileno())
        while not stop_event.is_set():
            if ser.writable():
                import select
                if select.select([sys.stdin], [], [], 0.05)[0]:
                    char = sys.stdin.read(1)
                    if char == '\x03': 
                        stop_event.set()
                        break
                    ser.write(char.encode())
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def do_upload(ser, bin_path, size):
    WHT = "\033[97m"; END = "\033[0m"
    # 1. Issue Size
    ser.write(size.to_bytes(4, 'little'))
    time.sleep(0.2) 
    # 2. Issue content
    with open(bin_path, 'rb') as f:
        sent = 0
        while sent < size:
            chunk = f.read(1024)
            ser.write(chunk)
            sent += len(chunk)
            bar = "█" * (30 * sent // size) + " " * (30 - (30 * sent // size))
            sys.stdout.write(f"\rProgress: [{WHT}{bar}{END}] {int(sent/size*100)}% ({sent}/{size} bytes)")
            sys.stdout.flush()
            time.sleep(0.001)
    print(f"\n>> {WHT}UPLOAD SUCCESSFUL!{END}")

def main():
    if len(sys.argv) < 2: return
    bin_path = sys.argv[1]
    port = find_port()
    if not port: sys.exit(1)

    size = os.path.getsize(bin_path)
    
    with serial.Serial(port, 115200, timeout=0.1) as ser:
        while True:
            print(f">> Listening on {port} for BIOS/App...")
            captured = ""
            

            while True:
                if ser.in_waiting > 0:
                    char = ser.read(ser.in_waiting).decode('utf-8', 'replace')
                    print(char, end='', flush=True)
                    captured += char
                    if "Waiting for App Size" in captured:
                        time.sleep(0.5)
                        do_upload(ser, bin_path, size)
                        break 
                time.sleep(0.01)

            stop_event = threading.Event()
            t = threading.Thread(target=kb_terminal, args=(ser, stop_event), daemon=True)
            t.start()

            try:
                terminal_captured = ""
                while not stop_event.is_set():
                    if ser.in_waiting:
                        data = ser.read(ser.in_waiting).decode('utf-8', 'replace')
                        print(data, end='', flush=True)
                        terminal_captured += data
                        if "Waiting for App Size" in terminal_captured:
                            print("\n>> [RELOAD] Detected BIOS request. Restarting pipeline...")
                            break 
                    time.sleep(0.01)
                
                if stop_event.is_set(): break
            except KeyboardInterrupt:
                break

if __name__ == "__main__":
    main()