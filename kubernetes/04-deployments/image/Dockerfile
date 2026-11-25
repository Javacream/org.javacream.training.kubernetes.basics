FROM nginx:stable
COPY hostinfo.sh /docker-entrypoint.d/hostinfo.sh
RUN chmod +x /docker-entrypoint.d/hostinfo.sh
RUN sed -i 's/keepalive_timeout[[:space:]]\+65;/keepalive_timeout 0;/' /etc/nginx/nginx.conf \
    && grep -q 'keepalive_timeout 0;' /etc/nginx/nginx.conf

RUN printf '%s\n' 'add_header Cache-Control "no-store" always;' > /etc/nginx/conf.d/cache-control.conf \
    && nginx -t

EXPOSE 80
