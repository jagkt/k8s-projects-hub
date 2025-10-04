FROM nginx:alpine

ARG COMMIT_HASH
ARG BUILD_DATE

LABEL org.label-schema.vcs-ref=$COMMIT_HASH \
      org.label-schema.build-date=$BUILD_DATE

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]