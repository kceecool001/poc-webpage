FROM node:20-alpine AS build
WORKDIR /src
COPY index.html .
RUN test -f index.html && grep -q "<h1>" index.html \
 && npm install -g html-minifier-terser@7.2.0 \
 && mkdir -p /out \
 && html-minifier-terser --collapse-whitespace --remove-comments \
      -o /out/index.html index.html

FROM nginx:alpine
RUN apk upgrade --no-cache
COPY --from=build /out/index.html /usr/share/nginx/html/index.html
EXPOSE 80