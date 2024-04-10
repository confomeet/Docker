# В данном репозитории собрана информация и скрипты, необходимые для деплоя проекта Confomeet
Содержимое данного репозитория основано на https://github.com/jitsi/docker-jitsi-meet.

Текущая используемая версия docker-jitsi-meet: stable-9364-1

## Развертывание в продакшн среде
**TODO**

## Развертывание локально (для разработки)
**TODO**

## Кастомизация self-hosted jitsi meet
Confomeet использует компоненты jitsi meet как составные части. Некоторые компоненты были доработаны, об этих
доработках рассказано ниже:

### Общие изменения
Во всех сервисах имя сети заменено с `meet.jitsi` на `confomeetnet`.

### Jibri
В контейнеры добавлена установка встроенных перменных окружения, которые используются при конфигурации jibri:
- `JIBRI_ALL_MUTED_TIMEOUT`
- `JIBRI_NO_MEDIA_TIMEOUT`

В контейнеры добавлена установка новых переменных окружения, которые используеются при конфигурации доступа к
S3 хранилищу:
- `CONFOMEET_S3_URL`
- `CONFOMEET_Si_CLIENT_ID`
- `CONFOMEET_S3_CLIENT_SECRET`
- `CONFOMEET_S3_REGION`
- `CONFOMEET_S3_BUCKET`

Добавлены файлы для поддержки загрузки записей в хранилище S3.
- rootfs/defaults/aws-config.conf
- rootfs/defaults/aws-credentials.conf
- rootfs/etc/cont-init.d/11-awscli
- rootfs/etc/fit-attrs.d/11-awscli
- rootfs/usr/bin/install-awscli
- rootfs/usr/bin/finalize-s3.sh

## Обновление на новую версию docker-jitsi-meet
**TODO**
