# Sử dụng image Flutter để build
FROM cirrusci/flutter:stable AS build

# Thiết lập thư mục làm việc
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Sử dụng Nginx để phục vụ file tĩnh
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]