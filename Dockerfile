FROM node:20-bookworm

WORKDIR /app

# Clone the current AlianHub source
RUN apt-get update && apt-get install -y --no-install-recommends git openssl \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth 1 https://github.com/aliansoftwareteam/AlianHub-Project-Management-System.git .

# Install root dependencies
RUN npm install

# Install frontend dependencies
RUN cd frontend && npm install

# Install wizard dependencies if present
RUN if [ -d "wizard" ]; then cd wizard && npm install; fi

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0

EXPOSE 4000

CMD ["npm", "start"]
