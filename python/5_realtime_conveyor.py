import sys
sys.stdout.reconfigure(encoding='utf-8')

import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import cv2
import os
import random
import socket
import msvcrt 

class DefectDetectionCNN(nn.Module):
    def __init__(self):
        super(DefectDetectionCNN, self).__init__()
        self.conv1 = nn.Conv2d(1, 16, kernel_size=3, padding=1)
        self.relu1 = nn.ReLU()
        self.pool1 = nn.MaxPool2d(2, 2)
        self.conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)
        self.relu2 = nn.ReLU()
        self.pool2 = nn.MaxPool2d(2, 2)
        self.fc1 = nn.Linear(32 * 16 * 16, 128)
        self.relu3 = nn.ReLU()
        self.fc2 = nn.Linear(128, 2)

    def forward(self, x):
        x = self.pool1(self.relu1(self.conv1(x)))
        x = self.pool2(self.relu2(self.conv2(x)))
        x = x.view(x.size(0), -1)
        x = self.relu3(self.fc1(x))
        x = self.fc2(x)
        return x

model = DefectDetectionCNN()
model.load_state_dict(torch.load(r"E:\AI\AI project\code\data\robot_vision_brain.pth", weights_only=True))
model.eval()
print("✅ AI Vision System Loaded (AUTO/MANUAL + ARDUINO SYNC)")

transform = transforms.Compose([
    transforms.Grayscale(num_output_channels=1),
    transforms.Resize((64, 64)),
    transforms.ToTensor()
])

ok_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\test\ok_front"
def_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\test\def_front"

ok_images = [os.path.join(ok_dir, f) for f in os.listdir(ok_dir)]
def_images = [os.path.join(def_dir, f) for f in os.listdir(def_dir)]
all_images = ok_images + def_images
random.shuffle(all_images)


def send_to_arduino(label):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('127.0.0.1', 19001)) 
        
        if label == "DEFECTIVE":
            command = "DEFECT\n"
        elif label == "OK":
            command = "OK\n"
        elif label == "MANUAL":
            command = "MANUAL\n"
        else:
            command = "RESET\n"
            
        s.sendall(command.encode('utf-8'))
        s.close()
        print(f"🔌 Arduino: Sent '{command.strip()}'")
    except Exception:
        pass 
# ────────────────────────────────────────────────────────

# 🌟Open the connection with MATLAB🌟
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 65432))
    print("🔗 Successfully Connected to MATLAB TCP Server!")
except Exception as e:
    print("❌ ERROR: MATLAB is not ready. Please run MATLAB first and click 'Connect'.")
    sys.exit()

cv2.namedWindow("AI Conveyor Inspection System")

mode = "AUTO" 
idx = 0       

while idx < len(all_images):
    image_path = all_images[idx]
    
    if mode == "AUTO":
        print("\n" + "="*50)
        print("⏳ [AUTO] Waiting for Proximity Sensor... (Press 'M' for Manual, 'Q' to Quit)")
        
        trigger_received = False
        while True:
            if msvcrt.kbhit():
                key = msvcrt.getch().decode('utf-8').upper()
                if key == 'Q':
                    try: s.sendall("STOP_SYSTEM\r\n".encode('utf-8')) 
                    except: pass
                    send_to_arduino("RESET")
                    print("\n🛑 Shutting down Python, MATLAB, and Arduino...")
                    sys.exit()
                elif key == 'M':
                    mode = "MANUAL"
                    send_to_arduino("MANUAL")
                    print("\n🔄 Switched to MANUAL Mode.")
                    break
            
            try:
                s.settimeout(0.1)
                msg = s.recv(1024).decode('utf-8')
                if "TRIGGER" in msg:
                    print("🎯 Sensor Trigger Received! Analyzing part...")
                    trigger_received = True
                    break
                elif "QUIT" in msg:
                    send_to_arduino("RESET")
                    print("\n🛑 MATLAB closed the system. Shutting down...")
                    sys.exit()
            except socket.timeout:
                continue
            except Exception as e:
                print(f"\n❌ Connection Error: {e}")
                sys.exit()
                
        if mode == "MANUAL":
            continue 
            
    elif mode == "MANUAL":
        print("\n" + "="*50)
        cmd = input("⚙️ [MANUAL] Press [Enter] to process next part, 'A' for AUTO, 'Q' to QUIT: ").strip().upper()
        
        if cmd == 'Q':
            try: s.sendall("STOP_SYSTEM\r\n".encode('utf-8'))
            except: pass
            send_to_arduino("RESET")
            print("🛑 Shutting down Python, MATLAB, and Arduino...")
            sys.exit()
            
        elif cmd == 'A':
            mode = "AUTO"
            send_to_arduino("RESET") 
            print("🔄 Switched to AUTO Mode.")
            continue 

    # ==========================================
    # Image processing 
    # ==========================================
    image = cv2.imread(image_path)
    if image is None: 
        idx += 1
        continue
    original = image.copy()

    pil_image = Image.open(image_path)
    input_tensor = transform(pil_image).unsqueeze(0)

    with torch.no_grad():
        output = model(input_tensor)
        probabilities = torch.softmax(output, dim=1)
        confidence, predicted = torch.max(probabilities, 1)
        predicted_class = predicted.item()
        confidence_score = confidence.item() * 100

    if predicted_class == 0:
        label = "DEFECTIVE"
        color = (0, 0, 255)
        target_coords = [250.0, -500.0, 150.0]
        status_code = 0  
    else:
        label = "OK"
        color = (0, 255, 0)
        target_coords = [250.0, 500.0, 150.0]
        status_code = 1  

    h, w, _ = image.shape
    try:
        cv2.rectangle(original, (5, 5), (max(10, w - 5), max(10, h - 5)), color, 4)
        cv2.putText(original, f"{label} | {confidence_score:.2f}%", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
    except:
        pass 
    
    cv2.imshow("AI Conveyor Inspection System", original)
    cv2.waitKey(1000)

    print(f"👁️ Vision Result: {label} ({confidence_score:.1f}%)")
    
    # Send the result to Arduino
    send_to_arduino(label)
    
    try:
        response = f"{target_coords[0]},{target_coords[1]},{target_coords[2]},{status_code}\r\n"
        s.sendall(response.encode('utf-8'))
        print(f"📡 Command Sent to MATLAB! Moving to Y={target_coords[1]}")
    except Exception as e:
        print(f"❌ Failed to send command to MATLAB: {e}")
        break

    idx += 1 

s.close()
cv2.destroyAllWindows()
