FROM node:26-alpine AS build

WORKDIR /app


COPY package.json ./
RUN npm install


COPY public/ ./public/
COPY src/ ./src/
RUN npm run build

FROM nginx:1.31-alpine


COPY nginx.conf /etc/nginx/conf.d/default.conf


COPY --from=build /app/build /usr/share/nginx/html


COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
