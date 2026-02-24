FROM golang:1.21-alpine as builder

WORKDIR /app
COPY . .
RUN go build -o engine main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/engine .
CMD ["./engine"]
