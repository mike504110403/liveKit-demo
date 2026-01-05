FROM golang:1.23-alpine AS builder

WORKDIR /app

# 安裝依賴
COPY go.mod go.sum ./
RUN go mod download

# 複製源碼
COPY . .

# 編譯
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 運行階段
FROM alpine:latest

RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

# 從 builder 複製編譯好的二進制文件
COPY --from=builder /app/main .

EXPOSE 3000

CMD ["./main"]

