FROM node:20-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends git openssl \
    && rm -rf /var/lib/apt/lists/*

# Get AlianHub source
RUN git clone --depth 1 https://github.com/aliansoftwareteam/AlianHub-Project-Management-System.git .

# Install dependencies
RUN npm install
RUN cd frontend && npm install
RUN cd installation && npm install

# Build the installation wizard FIRST
RUN cd installation && npm run build

# Build the normal application
RUN cd frontend && npm run build

# IMPORTANT:
# AlianHub normally always serves frontend/dist at "/".
# Change it so incomplete installations use installation/dist.
RUN node - <<'NODE'
const fs = require('fs');

const file = '/app/index.js';
let s = fs.readFileSync(file, 'utf8');

const old = `app.use(express.static(path.join(__dirname, './frontend/dist')));
    app.use(express.static(path.join(__dirname, './installation/dist')));
    // RUN FRONTEND SERVER
    app.get("/", (req, res) => {
        res.sendFile(path.join(__dirname, './frontend/dist/index.html'));
    });`;

const replacement = `app.use(express.static(path.join(__dirname, './installation/dist')));
    app.use(express.static(path.join(__dirname, './frontend/dist')));

    // Serve installation wizard until installation steps 7 and 8 are complete.
    app.get("/", (req, res) => {
        let installed = false;

        try {
            const installFile = path.join(__dirname, './installationSteps.json');

            if (fs.existsSync(installFile)) {
                const data = JSON.parse(fs.readFileSync(installFile, 'utf8'));
                const steps = data.installSteps || [];

                const step7 = steps.find(s => s.step === 7);
                const step8 = steps.find(s => s.step === 8);

                installed =
                    step7?.status === 'done' &&
                    step8?.status === 'done';
            }
        } catch (error) {
            console.error('Installation state check failed:', error.message);
        }

        const indexFile = installed
            ? path.join(__dirname, './frontend/dist/index.html')
            : path.join(__dirname, './installation/dist/index.html');

        res.sendFile(indexFile);
    });`;

if (!s.includes(old)) {
    console.error('Could not find expected AlianHub frontend route block.');
    process.exit(1);
}

s = s.replace(old, replacement);
fs.writeFileSync(file, s);

console.log('AlianHub installation routing patched successfully.');
NODE

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

EXPOSE 4000

# Create the .env file at runtime because AlianHub requires a physical /app/.env
CMD ["sh", "-c", "printf 'PORT=%s\\nNODE_ENV=%s\\nMONGODB_URL=%s\\nJWT_SECRET=%s\\nAPIURL=%s\\nWEBURL=%s\\nSTORAGE_TYPE=%s\\nUNDER_MAINTENANCE=false\\nNOOFPRESETCOMPANY=10\\nPRECOMPANYKEY=%s\\nCORS_ORIGINS=%s\\n' \"$PORT\" \"$NODE_ENV\" \"$MONGODB_URL\" \"$JWT_SECRET\" \"$APIURL\" \"$WEBURL\" \"$STORAGE_TYPE\" \"$PRECOMPANYKEY\" \"$CORS_ORIGINS\" > /app/.env && exec npm start"]
