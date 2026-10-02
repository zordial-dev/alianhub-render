FROM node:20-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends git openssl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/aliansoftwareteam/AlianHub-Project-Management-System.git .

RUN npm run setup

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

EXPOSE 4000

CMD ["sh", "-c", "printf 'PORT=%s\\nNODE_ENV=%s\\nMONGODB_URL=%s\\nJWT_SECRET=%s\\nAPIURL=%s\\nWEBURL=%s\\nSTORAGE_TYPE=%s\\nUNDER_MAINTENANCE=false\\nNOOFPRESETCOMPANY=10\\nPRECOMPANYKEY=%s\\nCORS_ORIGINS=%s\\n' \"$PORT\" \"$NODE_ENV\" \"$MONGODB_URL\" \"$JWT_SECRET\" \"$APIURL\" \"$WEBURL\" \"$STORAGE_TYPE\" \"$PRECOMPANYKEY\" \"$CORS_ORIGINS\" > /app/.env && exec npm start"]
