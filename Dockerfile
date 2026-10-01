FROM node:20-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends git openssl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/aliansoftwareteam/AlianHub-Project-Management-System.git .

# Install dependencies
RUN npm install

RUN cd frontend && npm install

# Build frontend
RUN cd frontend && npm run build

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

EXPOSE 4000

CMD ["npm", "start"]
