# syntax=docker/dockerfile:1
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 go build -o /out/api .

FROM alpine:3.20
WORKDIR /app
COPY --from=build /out/api /app/api
EXPOSE 8080
CMD ["/app/api"]
