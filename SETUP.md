### 1. Install System Dependencies (Mac)

Open Terminal and run these commands:

```bash
   # Install Homebrew (if not already installed)
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install required tools
   brew install tesseract imagemagick ghostscript
```

### 2. Clone the Repository

```bash
   git clone https://github.com/zeeshangulzar/ucop.git
   cd ucop
```

### 3. Install Ruby Dependencies

```bash
   bundle install
```

### 4. Setup Database

```bash
   rails db:create
   rails db:migrate
```

### 5. Configure API Key

Create a file named `.env` in the project root and add:

```
OPENAI_API_KEY=provided
```

---

## Running the Application

### Start the Server

```bash
   cd ~/Desktop/ucop
   rails server
```