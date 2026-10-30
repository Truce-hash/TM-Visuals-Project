<div align="center">

<img src="assets/readme/banner.png" alt="TM Visuals - Photography & Film" width="600" />

### Photography & Videography Client Management System

*The photographer's mobile app for managing client bookings and delivering content securely.*

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![ASP.NET](https://img.shields.io/badge/ASP.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)

![Stage](https://img.shields.io/badge/Stage-Phase%203%20Development%20%26%20Testing-FFB000?style=flat-square)
![Module](https://img.shields.io/badge/Module-ITC327W-333333?style=flat-square)
![Last commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/YOUR_REPO?style=flat-square)

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
<!--- [Screenshots](#-screenshots)-->
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Stage](#-project-stage)
- [Stakeholder](#-stakeholder)
- [Team](#-team)

---

## 🎯 Overview

<!--This project is being developed as part of the **ITC327W Work-Integrated Learning** module at the **Central University of Technology**.-->

It is the **Photographer Website & Client Management Platform**, built for **TM Visuals** (Photography and Videography). The platform has two parts that share one backend:

| | Component | Used by | Purpose |
|---|---|---|---|
| 🌐 | **ASP.NET web app** | Clients | Book shoots, browse the portfolio, and securely access delivered photos and videos |
| 📱 | **Flutter mobile app** | TM Visuals (admin) | Manage client bookings and deliver content on the go |

It addresses real business needs around:

| | Need | What it solves |
|---|---|---|
| 📅 | **Booking** | Clients request shoots online and the photographer manages them from their phone |
| 🖼️ | **Portfolio visibility** | Showcases TM Visuals' work to prospective clients |
| 🔒 | **Secure content delivery** | The photographer uploads finished content and each client accesses only their own |

> [!NOTE]
> This repository contains **both** the ASP.NET website and the Flutter mobile app. Both connect to the same **Supabase** backend for authentication and storage.

<!--## 📸 Screenshots

 Replace with real screenshots. Side-by-side layout: 
<div align="center">
  <img src="assets/readme/home.png" width="220" alt="Dashboard" />
  <img src="assets/readme/bookings.png" width="220" alt="Bookings screen" />
  <img src="assets/readme/delivery.png" width="220" alt="Content delivery screen" />
</div>
-->
---

## ✨ Features

- 🔐 **Secure admin login** powered by Supabase Auth
- 📅 **Booking management** to review and manage client bookings
- 👥 **Client management** with client details and shoot history
- 📤 **Content delivery** by uploading photos and videos to Supabase Storage for specific clients

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| 📱 Mobile app | **Flutter** | Admin app for the photographer |
| 🌐 Web app | **ASP.NET** | Client-facing website: booking, portfolio, content access |
| 🔑 Auth & Storage | **Supabase** | Authentication and secure file storage |

---

## 🧩 Architecture

```mermaid
flowchart LR
    A[📱 Flutter Mobile App<br/>Photographer / Admin] --> C[(☁️ Supabase<br/>Auth + Storage)]
    B[🌐 ASP.NET Web App<br/>Clients] --> C
```
---

## 🚧 Project Stage

```mermaid
timeline
    title Project Progress
    Phase 1 : Planning
    Phase 2 : Design
    Phase 3 : System Development and Testing 📍
```

> [!IMPORTANT]
> Currently in **Phase 3, System Development and Testing**. 

---

## 🤝 Stakeholder

**TM Visuals**, a photography and film business based in Johannesburg, represented by **Tshedza Mulaudzi**.

---

## 👥 Team

| Name |
|---|
| S Lukhele |
| M Bonga |
| S Mbasa |
| Z Mvimbi |
| K Matsane |
| KTJ Phatsoane |
| MF Mulaudzi |
| B Lombaard |

<a href="https://github.com/Truce-hash/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Truce-hash/TM-Visuals-Project" />
</a>
<a href="https://github.com/blessingmikay19-cyber/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=blessingmika-cyber19/TM-Visuals-Project" />
</a>
<a href="https://github.com/musabonga253-blip/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=musabonga253/TM-Visuals-Project" />
</a>
<a href="https://github.com/koketsomatsane/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=koketsomatsane/TM-Visuals-Project" />
</a>
<a href="https://github.com/MphoZAR1/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=MphoZAR1/TM-Visuals-Project" />
</a>
<a href="https://github.com/HilmNameless/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=HilmNameless/TM-Visuals-Project" />
</a>
<a href="https://github.com/224107046/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=224107046/TM-Visuals-Project" />
</a>
<a href="https://github.com/Zukes101/TM-Visuals-Project/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Zukes101/TM-Visuals-Project" />
</a>

</a>

---

<div align="center">

Built with 💙 for **TM Visuals** · Central University of Technology 

</div>
