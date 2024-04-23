FROM node:16.17-slim

RUN apt-get update -y && apt-get upgrade -y  && \
    apt-get install -y  wget gettext-base curl git netcat

RUN mkdir -p /excalidraw-backend


# COPY package.json package-lock.json tsconfig.json src ./
RUN  git clone https://github.com/jitsi/excalidraw-backend.git
WORKDIR /excalidraw-backend
RUN rm -rf src/index.ts 
COPY index.ts  src/
RUN npm install
RUN echo "PORT=3002" >.env.production
RUN npm run build

EXPOSE 3002
EXPOSE 9091

ENV DEBUG=*


CMD ["npm", "start"]