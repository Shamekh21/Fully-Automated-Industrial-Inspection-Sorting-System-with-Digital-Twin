import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import os
import random
from project_paths import MODEL_PTH, DATA_DIR

class DefectDetectionCNN(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 16, 3, padding=1)
        self.relu1 = nn.ReLU()
        self.pool1 = nn.MaxPool2d(2, 2)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)
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

def expert_system_decision(prediction_class):
    print("\n[ Expert System Processing... ]")
    if prediction_class == 0:
        rule_triggered = "IF Defect THEN Move to Scrap Bin"
        target_coordinates = [250.0, -150.0, 100.0]
        action = "REJECT"
    elif prediction_class == 1:
        rule_triggered = "IF OK THEN Move to Packaging Line"
        target_coordinates = [250.0, 150.0, 100.0]
        action = "ACCEPT"
    else:
        rule_triggered = "UNKNOWN ERROR"
        target_coordinates = [0.0, 0.0, 500.0]
        action = "STOP CONVEYOR"

    print(f"Rule Triggered : {rule_triggered}")
    print(f"Robot Action   : {action}")
    print(f"Target Coords  : X={target_coordinates[0]}, Y={target_coordinates[1]}, Z={target_coordinates[2]}")
    return target_coordinates

if __name__ == "__main__":
    print("--- Mechatronics AI Inspection System ---")

    model = DefectDetectionCNN()
    if not os.path.isfile(MODEL_PTH):
        raise FileNotFoundError(f"Model file not found: {MODEL_PTH}")
    state = torch.load(MODEL_PTH, map_location='cpu')
    model.load_state_dict(state)
    model.eval()
    print("AI Vision Model Loaded Successfully.")

    test_ok_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\test\ok_front"
    test_def_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\test\def_front"

    if not os.path.isdir(test_ok_dir):
        raise FileNotFoundError(f"Test OK folder not found: {test_ok_dir}")
    if not os.path.isdir(test_def_dir):
        raise FileNotFoundError(f"Test defect folder not found: {test_def_dir}")

    ok_images = sorted([f for f in os.listdir(test_ok_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))])
    def_images = sorted([f for f in os.listdir(test_def_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))])
    if not ok_images or not def_images:
        raise FileNotFoundError("Test folders do not contain valid images.")

    choose_defect = random.choice([True, False])
    selected_dir = test_def_dir if choose_defect else test_ok_dir
    selected_file = random.choice(def_images if choose_defect else ok_images)
    image_path = os.path.join(selected_dir, selected_file)

    print(f"\nScanning New Part on Conveyor...")
    print(f"Image Source: {selected_file}")

    transform = transforms.Compose([
        transforms.Grayscale(num_output_channels=1),
        transforms.Resize((64, 64)),
        transforms.ToTensor()
    ])

    image = Image.open(image_path)
    input_tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        output = model(input_tensor)
        _, predicted = torch.max(output.data, 1)
        predicted_class = predicted.item()

    vision_result = "DEFECTIVE" if predicted_class == 0 else "OK"
    print(f"Vision AI Result: Part is {vision_result}")

    final_robot_target = expert_system_decision(predicted_class)
    print("\n[ System Ready: Waiting to send coordinates to MATLAB ]")