FROM node:latest

RUN apt-get update && apt-get install -y git python g++ make \
    && npm install -g truffle

RUN git clone https://github.com/gnosis/safe-contracts.git

WORKDIR /safe-contracts

RUN npm install

RUN rm -rf truffle.js

COPY truffle.js truffle.js

EXPOSE 8080
ENTRYPOINT []