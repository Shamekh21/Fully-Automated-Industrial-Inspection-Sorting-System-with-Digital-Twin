import os
import json
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from project_paths import MODEL_PTH, DATA_DIR, EVAL_JSON

train_dir = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\train"

transform = transforms.Compose([
    transforms.Grayscale(num_output_channels=1),
    transforms.Resize((64, 64)),
    transforms.ToTensor()
])

try:
    dataset = datasets.ImageFolder(root=train_dir, transform=transform)
    train_loader = DataLoader(dataset, batch_size=32, shuffle=True)
    print("✅ Data loaded successfully!")
    print(f"📊 Training images: {len(dataset)}")
    print(f"🏷️ Classes: {dataset.class_to_idx}\n")
except Exception as e:
    print(f"❌ Data loading error: {e}")
    raise SystemExit(1)

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

model = DefectDetectionCNN()
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)
epochs = 3

history = []
print("🚀 Training started...\n")
for epoch in range(epochs):
    running_loss = 0.0
    correct = 0
    total = 0
    model.train()
    for images, labels in train_loader:
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        running_loss += loss.item()
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()
    epoch_loss = running_loss / max(1, len(train_loader))
    epoch_acc = 100 * correct / max(1, total)
    history.append({'epoch': epoch + 1, 'loss': epoch_loss, 'accuracy': epoch_acc})
    print(f"Epoch [{epoch+1}/{epochs}] | Loss: {epoch_loss:.4f} | Accuracy: {epoch_acc:.2f}%")

MODEL_PTH.parent.mkdir(parents=True, exist_ok=True)
torch.save(model.state_dict(), MODEL_PTH)

summary = {
    'train_dir': train_dir,
    'classes': dataset.class_to_idx,
    'epochs': epochs,
    'final_loss': history[-1]['loss'],
    'final_accuracy': history[-1]['accuracy'],
    'model_path': str(MODEL_PTH)
}

EVAL_JSON.parent.mkdir(parents=True, exist_ok=True)
with open(EVAL_JSON, 'w', encoding='utf-8') as f:
    json.dump(summary, f, indent=2, ensure_ascii=False)

print("\n🎉 Training complete.")
print(f"💾 Model saved to: {MODEL_PTH}")
print(f"📝 Training summary saved to: {EVAL_JSON}")