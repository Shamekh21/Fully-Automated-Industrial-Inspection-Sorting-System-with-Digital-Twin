import cv2
import matplotlib.pyplot as plt
import os

folder_ok = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\train\ok_front"
folder_defect = r"E:\AI\AI project\code\archive\temp\casting_data\casting_data\train\def_front"

try:
    if not os.path.isdir(folder_ok):
        raise FileNotFoundError(f"OK folder not found: {folder_ok}")
    if not os.path.isdir(folder_defect):
        raise FileNotFoundError(f"Defect folder not found: {folder_defect}")

    ok_files = sorted([f for f in os.listdir(folder_ok) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))])
    defect_files = sorted([f for f in os.listdir(folder_defect) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))])

    if not ok_files:
        raise FileNotFoundError(f"No image files found in OK folder: {folder_ok}")
    if not defect_files:
        raise FileNotFoundError(f"No image files found in defect folder: {folder_defect}")

    path_ok = os.path.join(folder_ok, ok_files[0])
    path_defect = os.path.join(folder_defect, defect_files[0])

    print(f"Loading OK Image from: {path_ok}")
    print(f"Loading Defect Image from: {path_defect}")

    img_ok = cv2.imread(path_ok, cv2.IMREAD_GRAYSCALE)
    img_def = cv2.imread(path_defect, cv2.IMREAD_GRAYSCALE)

    if img_ok is None:
        raise ValueError(f"Failed to read OK image: {path_ok}")
    if img_def is None:
        raise ValueError(f"Failed to read defect image: {path_defect}")

    plt.figure(figsize=(10, 5))

    plt.subplot(1, 2, 1)
    plt.title("OK Part (No Defects)")
    plt.imshow(img_ok, cmap='gray')
    plt.axis('off')

    plt.subplot(1, 2, 2)
    plt.title("Defective Part (Scratch/Crack)")
    plt.imshow(img_def, cmap='gray')
    plt.axis('off')

    plt.suptitle("Vision System Initialization (Camera Test)")
    plt.tight_layout()
    plt.show()

    print("\n✅ Vision system initialized successfully.")

except Exception as e:
    print(f"\n❌ Error: {e}")