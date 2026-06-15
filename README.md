# 🏭 Fully Automated Industrial Inspection & Sorting System

### AI-Powered Digital Twin for Smart Manufacturing using Computer Vision, Robotics Optimization, MATLAB, CoppeliaSim and Hardware-in-the-Loop Integration

![Python](https://img.shields.io/badge/Python-3.10-blue)
![PyTorch](https://img.shields.io/badge/PyTorch-DeepLearning-red)
![MATLAB](https://img.shields.io/badge/MATLAB-Robotics-orange)
![CoppeliaSim](https://img.shields.io/badge/CoppeliaSim-DigitalTwin-green)
![Arduino](https://img.shields.io/badge/Arduino-HMI-blue)

---

# 🎥 Full System Demonstration

This GIF demonstrates the complete synchronized operation of:

* AI Vision Inspection
* CNN Defect Classification
* Expert System Decision Making
* MATLAB Robotics Controller
* Optimization Algorithms
* CoppeliaSim Digital Twin
* Arduino HMI
* TCP/IP Communication
* Automated Pick-and-Place Sorting

<p align="center">
<img src="docs/gifs/full_system_demo.gif" width="950">
</p>

---

# 📌 Project Overview

This project presents a complete **Cyber-Physical Production System (CPPS)** and **Digital Twin Architecture** developed for automated industrial quality inspection and sorting applications.

The system integrates Artificial Intelligence, Robotics, Optimization Algorithms, Digital Twin Technology, and Hardware-in-the-Loop communication into a unified smart manufacturing framework.

A camera-based inspection module analyzes casting parts moving on a conveyor belt. A custom Convolutional Neural Network (CNN) identifies defective products in real-time. Based on the classification result, an Expert System generates industrial decisions which are transmitted to a MATLAB robotics controller.

MATLAB computes robot motion using Forward Kinematics, Inverse Kinematics, and Optimization Algorithms before sending commands to a UR5 robot operating inside a CoppeliaSim Digital Twin environment.

The final system creates a fully automated inspection and sorting workflow that closely resembles Industry 4.0 manufacturing systems.

---

# 🏗 System Architecture

<p align="center">
<img src="docs/images/System_Architecture.jpg" width="1000">
</p>

The project consists of four synchronized computational layers:

| Layer              | Technology       | Function                  |
| ------------------ | ---------------- | ------------------------- |
| AI Layer           | Python + PyTorch | Defect Detection          |
| Decision Layer     | Expert System    | Sorting Logic             |
| Control Layer      | MATLAB           | Kinematics & Optimization |
| Digital Twin Layer | CoppeliaSim      | Virtual Factory           |
| Hardware Layer     | Arduino          | HMI & Monitoring          |

---

# ⚡ Cyber-Physical System Data Flow

```text
Industrial Camera
        │
        ▼
Image Acquisition
        │
        ▼
CNN Vision Model
        │
        ▼
Expert System
        │
        ▼
TCP/IP Communication
        │
        ▼
MATLAB Controller
        │
        ▼
Optimization Engine
        │
        ▼
Inverse Kinematics
        │
        ▼
UR5 Robot
        │
        ▼
Pick & Place Action
        │
        ▼
Arduino HMI Feedback
```

---

# 🌐 Communication Architecture

The entire system is synchronized through multiple communication channels.

| Port    | Protocol   | Function                |
| ------- | ---------- | ----------------------- |
| 65432   | TCP/IP     | Python ↔ MATLAB         |
| 19000   | Remote API | MATLAB ↔ CoppeliaSim    |
| 19001   | TCP Socket | Python ↔ Arduino Bridge |
| USB COM | Serial     | Bridge ↔ Arduino        |

This distributed architecture allows each subsystem to operate independently while maintaining real-time synchronization.

---

# 🌍 Digital Twin Environment

The industrial workcell was developed in CoppeliaSim and serves as a Digital Twin of the physical manufacturing station.

The environment contains:

* Conveyor Belt
* Proximity Sensor
* Sorting Zones
* UR5 Robot Manipulator
* Pick-and-Place Workspace

<p align="center">
<img src="docs/images/coppeliasim_workcell.jpg" width="900">
</p>

## Sorting an OK Part

<p align="center">
<img src="docs/gifs/coppeliasim_ok.gif" width="850">
</p>

## Sorting a Defective Part

<p align="center">
<img src="docs/gifs/coppeliasim_defect.gif" width="850">
</p>

---

# 🧠 AI Vision System

The vision subsystem performs automated quality inspection using a custom CNN implemented with PyTorch.

The processing pipeline consists of:

1. Image Acquisition
2. Grayscale Conversion
3. Image Resizing (64×64)
4. Tensor Conversion
5. CNN Inference
6. Confidence Estimation
7. Expert System Decision

## Camera Initialization

<p align="center">
<img src="docs/images/camera_test.png" width="750">
</p>

## Image Processing Pipeline

<p align="center">
<img src="docs/images/image_processing_pipeline.png" width="900">
</p>

## Histogram Analysis

<p align="center">
<img src="docs/images/histogram_analysis.png" width="850">
</p>

## Detailed Dataset Analysis

<p align="center">
<img src="docs/images/detailed_image_analysis.png" width="850">
</p>

---

# 🤖 CNN Architecture

The defect detection model was developed using PyTorch.

Architecture:

```text
Input (64×64×1)

↓
Conv2D (1 → 16)
↓
ReLU
↓
MaxPooling

↓
Conv2D (16 → 32)
↓
ReLU
↓
MaxPooling

↓
Flatten

↓
Fully Connected (8192 → 128)

↓
ReLU

↓
Fully Connected (128 → 2)

↓
Output Layer
```

Training Configuration:

* Framework: PyTorch
* Optimizer: Adam
* Learning Rate: 0.001
* Loss Function: CrossEntropyLoss
* Binary Classification
* Real Industrial Casting Dataset

---

# 📈 Model Training

<p align="center">
<img src="docs/images/training_curve.png" width="850">
</p>

The CNN demonstrates stable convergence and reliable classification performance during training.

---

# 🎯 Model Evaluation

<p align="center">
<img src="docs/images/confusion_matrix.png" width="750">
</p>

Evaluation Metrics:

* Accuracy
* Precision
* Recall
* F1 Score
* Confusion Matrix

The trained model successfully distinguishes acceptable parts from defective products.

---

# 🧩 Expert System Layer

The Expert System acts as the bridge between Artificial Intelligence and Robotics.

Decision Rules:

```text
IF Part = OK
    → Packaging Line
    → Green Bin

IF Part = Defective
    → Scrap Bin
    → Red Bin
```

Generated outputs include:

* Robot Target Coordinates
* Sorting Decision
* MATLAB Commands
* Arduino Status Signals

---

# ⚙ MATLAB Robotics Control Center

MATLAB serves as the central controller of the robotic system.

Responsibilities:

* TCP Server
* Robot Simulation
* Forward Kinematics
* Inverse Kinematics
* Optimization Algorithms
* Real-Time Monitoring
* Performance Benchmarking

<p align="center">
<img src="docs/images/matlab_gui.jpg" width="950">
</p>

## MATLAB GUI – OK Part

<p align="center">
<img src="docs/gifs/matlab_ok.gif" width="850">
</p>

## MATLAB GUI – Defective Part

<p align="center">
<img src="docs/gifs/matlab_defect.gif" width="850">
</p>

---

# 🤖 Robotics Mathematics

The controller implements core robotics concepts including:

* Forward Kinematics
* Inverse Kinematics
* Homogeneous Transformation Matrices
* Workspace Validation
* End-Effector Pose Estimation
* Joint Constraint Handling
* Trajectory Planning

These mathematical models enable accurate robot positioning and industrial pick-and-place operations.

---

# 🚀 Optimization Algorithms

Multiple optimization algorithms were implemented and benchmarked.

Implemented Planners:

* Analytical Inverse Kinematics
* Genetic Algorithm (GA)
* Simulated Annealing (SA)
* Particle Swarm Optimization (PSO)
* Hill Climbing Pattern Search

Evaluation Criteria:

* Convergence Speed
* Position Accuracy
* Joint Smoothness
* Computational Cost

The GUI supports automatic benchmarking and best-solution selection.

---

# 🔌 Hardware-in-the-Loop (Arduino HMI)

A physical Arduino subsystem was integrated to emulate industrial HMI behavior.

Features:

* Real-Time Status Monitoring
* LCD Feedback
* OK / Defective Indicators
* Serial Communication

<p align="center">
<img src="docs/images/Arduion_circuit.jpg" width="850">
</p>

## LCD Status – OK Part

<p align="center">
<img src="docs/gifs/lcd_ok.gif" width="600">
</p>

## LCD Status – Defective Part

<p align="center">
<img src="docs/gifs/lcd_defect.gif" width="600">
</p>

---

# 📂 Repository Structure

```text
Industrial-AI-Sorting-System
│
├── python/
│   ├── training
│   ├── evaluation
│   ├── realtime_controller
│   └── bridge
│
├── matlab/
│   ├── GUI
│   ├── IK
│   ├── FK
│   └── Optimization
│
├── coppeliasim/
│   └── workcell_scene
│
├── arduino/
│   └── HMI
│
├── docs/
│   ├── images
│   └── gifs
│
└── README.md
```

---

# 🚀 System Startup Sequence

Launch the software in the following order:

1. Start CoppeliaSim and run the scene.
2. Run Arduino Bridge (`bridge.py`).
3. Launch MATLAB GUI.
4. Press Connect.
5. Run Python Real-Time Controller.

The system will automatically begin monitoring incoming parts and sorting them accordingly.

---

# 🏆 Key Achievements

✔ Custom CNN Defect Detection Model

✔ Expert-System-Based Decision Layer

✔ MATLAB Robotics Controller

✔ Advanced Optimization Algorithms

✔ UR5 Digital Twin

✔ Real-Time TCP/IP Communication

✔ Hardware-in-the-Loop Integration

✔ Industrial HMI Interface

✔ Automated Pick-and-Place Sorting

✔ Cyber-Physical System Architecture

✔ Industry 4.0 Oriented Design

---

# 🔮 Future Work

Potential future extensions include:

* YOLO-Based Defect Detection
* ROS2 Integration
* PLC Communication
* Real Industrial Camera Deployment
* Reinforcement Learning Motion Planning
* Multi-Robot Coordination
* Edge AI Deployment

---

# 👨‍💻 Author

**Mahmoud Shamekh**

Mechatronics Engineering

Areas of Interest:

* Robotics
* Artificial Intelligence
* Industrial Automation
* Digital Twin Systems
* Industry 4.0

---

# 📜 License

This repository is intended for educational, research, and demonstration purposes.
