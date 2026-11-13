# Sử dụng runtime .NET 10.0 cho môi trường chạy
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

# Sử dụng SDK .NET 10.0 để build code
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy các file csproj để restore thư viện trước
COPY ["PaperChat.API/PaperChat.API.csproj", "PaperChat.API/"]
COPY ["PaperChat.Service/PaperChat.Service.csproj", "PaperChat.Service/"]
COPY ["PaperChat.Repositories/PaperChat.Repositories.csproj", "PaperChat.Repositories/"]
RUN dotnet restore "PaperChat.API/PaperChat.API.csproj"

# Copy toàn bộ mã nguồn của cả 3 project
COPY . .
WORKDIR "/src/PaperChat.API"
RUN dotnet build "PaperChat.API.csproj" -c Release -o /app/build

# Publish ứng dụng
FROM build AS publish
RUN dotnet publish "PaperChat.API.csproj" -c Release -o /app/publish

# Copy bản publish sang môi trường chạy
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PaperChat.API.dll"]