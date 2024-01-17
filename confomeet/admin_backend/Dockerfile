FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app

ARG ADMIN_FRONTEND_GIT_USER
ENV ADMIN_FRONTEND_GIT_USER=${ADMIN_FRONTEND_GIT_USER}
ARG ADMIN_FRONTEND_GIT_PASS
ENV ADMIN_FRONTEND_GIT_PASS=${ADMIN_FRONTEND_GIT_PASS}
ARG ADMIN_BACKEND_BRANCH
ENV ADMIN_BACKEND_BRANCH=${ADMIN_BACKEND_BRANCH}


RUN git clone https://${ADMIN_FRONTEND_GIT_USER}:${ADMIN_FRONTEND_GIT_PASS}@code.event33.ru/confomeet/ConfOMeetBackend.git . && \
    git checkout ${ADMIN_BACKEND_BRANCH}

# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build-env /app/out .
ENTRYPOINT ["dotnet", "VideoProjectCore6.dll"]
