FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the pre-downloaded JAR, config, and map data
COPY graphhopper-web-9.1.jar /app/
COPY config.yml /app/
COPY nitc_fixed.osm.pbf /app/

# Copy the pre-built graph-cache to speed up boot times on Render
COPY graph-cache /app/graph-cache

# Expose GraphHopper's default port
EXPOSE 8989

# Start GraphHopper Server
CMD ["java", "-jar", "graphhopper-web-9.1.jar", "server", "config.yml"]
