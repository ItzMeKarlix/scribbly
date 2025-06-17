# 📝 Scribbly — A Simple Note-Taking App

Scribbly is a lightweight note-taking web app built with **Perl (Dancer2)** and designed to help you jot down your ideas anytime, anywhere.

---

## 🚀 Getting Started

Follow these steps to run **Scribbly** on your local machine.

---

### 🧰 Requirements

Before running the app, you need to install the following:

#### 1. ✅ Install Strawberry Perl (for Windows users)

> Strawberry Perl includes everything you need to run Perl and install Mojolicious.

- Go to https://strawberryperl.com
- Download the latest **64-bit** or **32-bit** version (based on your system)
- Run the installer and follow the installation instructions
- After installation, open a **new Command Prompt** or **PowerShell** and type:

```bash
perl -v
```

You should see your Perl version if it was installed correctly.

---

#### 2. ✅ Install Mojolicious

Once Perl is installed, open your terminal and run:

```bash
cpan Mojolicious
```

You may be prompted to configure CPAN the first time — just press **Enter** to accept defaults.

To confirm Mojolicious was installed:

```bash
morbo -v
```

---

## 📁 Running the App

1. Open **Visual Studio Code** or your terminal
2. Navigate to your project directory:

```bash
cd path/to/scribbly
```

> Replace `path/to/scribbly` with the actual path where your `scribbly` project is located.

3. Start the app using **morbo**:

```bash
morbo app.pl
```

4. If there are no errors, open your browser and go to:

```
http://localhost:3000/
```

---

## 📌 Notes

- Make sure the file you're running is named `app.pl` and located in the root of the `scribbly` folder.
- If you want live reloading during development, `morbo` will handle it automatically.
- For production, consider using a full Mojolicious deployment (like `hypnotoad`).

---

## 📫 Contact

For any questions, feel free to open an issue or message me through the GitHub repository.

---
