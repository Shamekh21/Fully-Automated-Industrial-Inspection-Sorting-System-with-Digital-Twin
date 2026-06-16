import os
import json
import torch
import torch.nn as nn
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from sklearn.metrics import confusion_matrix, classification_report, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
from project_paths import MODEL_PTH, EVAL_JSON, CONFUSION_MATRIX_PNG

class DefectDetectionCNN(nn.Module):
    def __init__(self):
        super().__init__()
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

def main():
    test_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\test"
    if not os.path.isdir(test_dir):
        raise FileNotFoundError(f"Test directory not found: {test_dir}")

    transform = transforms.Compose([
        transforms.Grayscale(num_output_channels=1),
        transforms.Resize((64, 64)),
        transforms.ToTensor()
    ])

    test_dataset = datasets.ImageFolder(root=test_dir, transform=transform)
    test_loader = DataLoader(test_dataset, batch_size=32, shuffle=False)

    print("✅ Test Dataset Loaded Successfully")
    print(f"📊 Number of Test Images: {len(test_dataset)}")
    print(f"🏷️ Class mapping: {test_dataset.class_to_idx}")

    if not os.path.isfile(MODEL_PTH):
        raise FileNotFoundError(f"Model file not found: {MODEL_PTH}")
    model = DefectDetectionCNN()
    state = torch.load(MODEL_PTH, map_location='cpu')
    model.load_state_dict(state)
    model.eval()
    print("✅ Trained AI Model Loaded Successfully")

    all_predictions = []
    all_labels = []
    correct = 0
    total = 0

    with torch.no_grad():
        for images, labels in test_loader:
            outputs = model(images)
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
            all_predictions.extend(predicted.cpu().numpy().tolist())
            all_labels.extend(labels.cpu().numpy().tolist())

    accuracy = 100 * correct / total
    print("\n===================================")
    print(f"🎯 Test Accuracy = {accuracy:.2f}%")
    print("===================================")

    target_names = list(test_dataset.class_to_idx.keys())
    print("\n📋 Classification Report:\n")
    report = classification_report(all_labels, all_predictions, target_names=target_names)
    print(report)

    cm = confusion_matrix(all_labels, all_predictions)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=target_names)
    fig, ax = plt.subplots(figsize=(6, 5))
    disp.plot(cmap="Blues", ax=ax, values_format='d')
    plt.title("Confusion Matrix - AI Vision System")
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_PNG, dpi=200)
    plt.show()

    out = {
        "y_true": all_labels,
        "y_pred": all_predictions,
        "class_names": target_names,
        "accuracy": accuracy,
        "confusion_matrix": cm.tolist(),
        "class_to_idx": test_dataset.class_to_idx
    }
    with open(EVAL_JSON, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    print(f"💾 Saved {EVAL_JSON}")
    print(f"💾 Saved {CONFUSION_MATRIX_PNG}")

if __name__ == "__main__":
    main()