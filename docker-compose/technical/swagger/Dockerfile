FROM swaggerapi/swagger-ui:latest
#--start-period=10s --start-interval=5s
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget -Y off -O /dev/null http://localhost:8080/swagger/
    #CMD curl --fail --noproxy '*' -so /dev/null http://localhost:8080/swagger/
ENV PORT_IPV6: 8080

#hack for cors
ENV EMBEDDING: false
COPY --chmod=0666 ./proxy-cors.conf /etc/nginx/templates/embedding.conf

COPY --chmod=0666 ./swagger-initializer.js /usr/share/nginx/html/swagger-initializer.js
