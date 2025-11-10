## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
## SPDX-License-Identifier: Apache-2.0

FROM public.ecr.aws/docker/library/maven:3.9-amazoncorretto-17 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

FROM public.ecr.aws/docker/library/amazoncorretto:17-alpine

RUN apk add --no-cache curl bash

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar
COPY generate-traffic.sh .

RUN chmod +x generate-traffic.sh

EXPOSE 8080
ENV PORT=8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["java", "-jar", "app.jar"]
