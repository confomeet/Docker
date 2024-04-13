# В данном репозитории собрана информация и скрипты, необходимые для деплоя проекта Confomeet
Содержимое данного репозитория основано на https://github.com/jitsi/docker-jitsi-meet.

Текущая используемая версия docker-jitsi-meet: stable-9364-1

## Развертывание в продакшн среде
Процесс развертывания системы состоит из нескольких шагов.
1. Клонирвоание данного репозитория.
2. Развертывание базы данных.
3. Конфигурирование системы.
4. Создание образов контейнеров.
5. Запуск контейнеров.

### Клонирвоание данного репозитория
```
$ git clone https://code.event33.ru/confomeet/ConfOMeetDocker.git
$ cd ConfOMeetDocker
```

### Развертывание базы данных
В качестве базы данных для системы ConfOMeet использует PostgreSQL.
Это серверная БД, она может быть расположена на той же машине, где остальные сервисы системы или на другом удаленном
сервере, а может подниматься как еще один контейнер в рамках confomeet. Подробнее про варианты развертывания и настройки
PostgreSQL рекоммендуется обратится к [официальной документации по PostgreSQL](https://www.postgresql.org/docs/).

После разворачивания базы данных нужно применить к ней скрипт `init.sql` из данного репозитория.

### Конфигурирование системы
Необходимо сконфигурировать систему с помощью переменных окружения, рекоммендуется скопировать файл _example.env_
в _.env_ и в файле _.env_ задать нужные значения.

Большинство настроек системы можно оставить без изменений, но есть те, которые надо обязательно изменить:
* CONFIG - путь в файловой системе хоста, по которому будут раполагаться артефакты работы сервисов, артефакты включают
логи, файл конфигурации инстанциированные из шаблонов, файлы записей конференций.
* ADMIN_BACKEND_BRANCH - тэг в системе управление версиями git, указывающий на версию бэкэнда confomeet.
* ADMIN_FRONTEND_BRANCH - тэг в системе управление версиями git, указывающий на версию фронтэнда confomeet.
* ADMIN_FRONTEND_GIT_PASS - пароль учетной записи на сервере git.
* ADMIN_FRONTENT_GIT_USER - логин учетной записи на сервере git.
* CONFOMEET_DB_CONNECTION_STRING - строка подключения к базе данных. Содержимое поля зависит от того, как был развернут
PostgreSQL. Например, строка может быть такой `Username=backend;Host=172.17.0.1;Port=5050;Database=confomeet;SearchPath=public`.
* CONFOMEET_AUTH_JWT_KEY - строка из симовлов таблицы ASCII, которая используется для формирования ключа, которым
подписываются AuthJWT токены.
* CONFOMEET_BASE_URL - строк содержащая путь, по которому отркрывается главная страница сервиса. Например: `https://event33.ru/meet`.
* JICOFO_AUTH_PASSWORD - строка, содержащая пароль сервиса Jicofo, например: `EdSlhu0Pf04y1ZSA`.
* JWT_APP_ID - строка содержащая название системы для внутреннего использования, например event33ru.
* JWT_APP_SECRET - строка содержащая секрет, из которого строится ключ для подписи MeetingJWT токенов.
* JIBRI_INSTANCE_ID - строка, уникально идентифицирующая инстанс Jibri, например "jibri-slakjf89we".
* JIBRI_RECORDER_PASSWORD - строка, содержащая пароль для авторизации сервиса Jibri, записывающего конферецнии в
сервисе prosody, например: `47epKnF4w`.
* JVB_AUTH_PASSWORD - строка, содержащая пароль для авторизации сервиса Jvb, выполняющего роль SFU, в сервисе prosody,
например: `I7!CQtme`.
* PUBLIC_URL - строка, содержащая базовый url, который будут видеть пользователи при подключении к конференции, например
`https://myevent33.ru`.
* TZ - строка, содержащая временную зона, в которой расположен сервер, например: `Europe/Moscow`.
* XMPP_DOMAIN - строка, содержащая домен, на котором работает сервер, например `event33.ru`.

Параметры PUBLIC_URL, XMPP_DOMAIN и CONFOMEET_BASE_URL должны быть согласованы между собой.

WebRTC стэк Jitsi также требует заполнения нескольких настроек на основе значения `XMPP_DOMAIN`:
* XMPP_AUTH_DOMAIN - строка, вычисляющаяся так: `auth.$XMPP_DOMAIN`.
* XMPP_INTERNAL_MUC_DOMAIN - строка вычислающая так: `internal.auth.$XMPP_DOMAIN`.
* XMPP_MUC_DOMAIN - строка, вычисляющаяся так: `conference.$XMPP_DOMAIN`.
* XMPP_RECORDER_DOMAIN - строка, вычисляющася так: `recorder.$XMPP_DOMAIN`.

Настройки, которые можно оставить не заполненными, чтобы использовать значения по умолчанию:
* CONFOMEET_ACTIVATE_ON_REGISTER - флаг включающий активацию аккаунта при регистрации без подтверждения адреса
электронной почты. По умолчанию включена.
* CONFOMEET_AUTH_JWT_LIFETIME_MINUTES - число, задающее время жизни AuthJWT токена. Указывается в минутах.
Значение по умолчанию - 960.
* CONFOMEET_ACTIVATE_ON_REGISTER - флаг, выключающий необходимость подтверждения адреса электронной почты при
регистрации.
* CONFOMEET_ENABLE_REGISTRATION - флаг, включающий работу страницы авторизации. По умолчанию флаг не выставлен.
* CONFOMEET_LOCKOUT_TIME_MINUTES - число, контролирующее на сколько минут пользователю блокируется возможность
авторизации, после нескольких неудачных попыток входа. Значение по умолчанию - `2`.
* CONFOMEET_LOGIN_ATTEMPS_BEFORE_LOCKOUT - число контролирующее, сколько раз пользователь можно попытаться ввести
пароль прежде, чем ему заблокируют авторизацию, значение по умолчанию - `3`.
* CONFOMEET_OTP_PERIOD_IN_MINUTES - число, задающее время в течение которого одноразовый код для авторизации
остается действительным. Значение по умолчанию - `960`.

Если требуется включить интеграцию с внешним провайдером авторизации, работающим по Open ID Connect, то заполняются
следующие два параметра.
* CONFOMEET_OIDC_AUTHORITY - строка, содержащая authority, выдается провайдером OIDC,
например: `https://auth.event33.ru:8443/realms/ConfOMeet`.
* CONFOMEET_OIDC_CLIENT_ID - строка, содержащая идентификатор системы у провайдера OIDC, например: `myevent33`.

Если требуется включить загрузку файлов записи конференции в облако по протоколу S3, то надо заполнить следующие параметры:
* CONFOMEET_S3_CLIENT_ID - строка, содержащая идентификатор клиента в протоколе OAuth2.0, например: `dskljfgdu93408jgodfgj`.
* CONFOMEET_S3_CLIENT_SECRET - строка, содержащая секрет клиента в протоколе OAuth2.0, например: `9asdfjkasdhflk30qfuidhfjk`.
* CONFOMEET_S3_REGION - строка, содержащая зону доступности, в которой надо сохранять файлы, например: `ru-central1`.
* CONFOMEET_S3_URL - строка, содержащая адрес, который выдает провайдер S3, например: `https://storage.yandexcloud.net/`.
* CONFOMEET_S3_URL_OVERRIDE_FOR_AWS_SDK - строка, содержащая дополнительный адрес, который выдает провайдер S3,
например: `https://s3.yandexcloud.net/`.
* JIBRI_FINALIZE_RECORDING_SCRIPT_PATH - надо установить в значение `finalize-s3.sh`

### Создание образов контейнеров
Для построения всех образов контейнеров нужно запустить команду
```
$ docker compose build
$ docker comopse -f jibri.yml build
```

Сервис jibri описывается отдельно, т.к. каждый новый инстанс данного сервиса требует задания нового значения
JIBRI_INSTANCE_ID из-за чего каждый инстанс надо запускать как отдельный проект.

### Запуск контейнеров
```
$ docker compose up
$ docker compose -f jibri.yml up
```

## Развертывание локально (для разработки)
### Разработка бэкенда
Для разработки бэкенда сделан отдельный файл `dev-docker-compose.yml`, который отличается от основного тем, что в нем
нет сервиса admin_backend. Вместо этого у сервиса nginx добавлена конфигурация в compose файле:
```
services:
  # ...
  nginx:
    # ...
    extra_hosts:
      - "admin_backend:host-gateway"
```

Также поскольку prosody не может разрзолвить доменные адреса, у которых нет настоящей записи DNS, необходимо изменить
настройку `conference_logger_url` для плагинов prosody, указав адрес локальной машины разработчика, выданный роутером,
в переменной окружения GLOBAL_CONFIG в файле _.env_. Например, 192.168.1.7. Адрес 127.0.0.1 не подойдет, т.к.
сетевые пакет от prosody при такой настройке не будут доходить до запущенного локально бэкенда.

### Разработка фронтенда
Разработка фронтенда ведется с применением React Dev Server. Это ПО, выполняющее работу HTTP сервера, чтобы разрабочик
мог видеть результаты разрботки на React.JS локально, не выкладывая свой код на удаленный сервер. Но данный сервер, конечно,
не реализует обработку запросов к бэкенду Confomeet. Однако он предоставляет механизм проксирования запросов на
настоящий бэкенд. Для этого в заготовленном файле _src/setupProxy.js_ надо указать IP адрес и порт развернутого
удаленного или локально бэкенда.

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
- `CONFOMEET_S3_CLIENT_ID`
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

_Важно._ Чтобы добавить необходимые файлы мы собираем свой контейнер jibri. При обновлении на новую версию
docker-jitsi-meet об этом надо помнить.

### Jicofo
Мы подменяем настройку `jicofo.conference.shared-document.use-random-name`. Данная настройка в текущий момент не
вынесена в конфигурацию _jicofo_ через перменные окружения, поэтому мы делаем эту настройку напрямую в конфиге _jicofo_
и собираем свой образ контейнера _jicofo_.

_Важно._ Чтобы добавить необходимые файлы мы собираем свой контейнер _jicofo_. При обновлении на новую версию
_docker-jitsi-meet_ об этом надо помнить.


### Prosody
Мы используем собранный образ _prosody_, но подменяем путь, из которого монтируется директория с кастомными плагинами,
т.к. плагины удобно хранить в репозитории, а логи, инстанциированные из шаблонов конфиги и другие артефакты работы
системы в отдельном месте.

Для сервера prosody мы разработали дополнительные модули, которые используем для реализации функций, которых нет в jitsi-meet.

#### Плагин mod_confomeet_context
`mod_confomeet_context` - это базовый модуль, который встраивается в процесс авторизации по jwt токену,
реализованный в плагине `mod_auth_token`. Наш модуль подписывется на событие `jitsi-authentication-token-verified`,
и когда оно наступает обогащает сессию пользователя данными из jwt токена.
При таком подходе нам не приходится парсить и валидировать jwt токен в каждом нашем плагине повторно, что в свою
очередь упрощает конфигурацию, т.к. для новых плагинов не требуется конфигурировать общий секрет и идентификатор
приложения, которые нужны для валидации токена.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom_

Сессия пользователя обогащется следующими данными:
* autoLobby: bool - флаг, отражающий, нужно ли включать комнату ожидания для данной конференции.
* moderator: bool - флаг, отражающий, является ли данный пользователь модератором конференции.
* autoRec: bool - флаг, отражающий, нужно ли автоматически включать запись данной конференции.
* singleAccess: bool - флаг, отражающий, нужно ли контролировать, что пользователи могу присоединиться к конференции
под одним аккаунтом только один раз.
* anonymous: bool - флаг, отражающий являтся ли данный пользователь анонимом, т.е. незарегистрированным в системе,
например если пользователь присоединяется по публичный ссылке конференции.
* user_id: string - уникальный идентификатор пользователя, зарегистрированного в нашей системе, если пользователь не
анонимный. Если пользователь анонимный, то строка пустая.
* user_email: string - электронный адрес пользователя, если это не аноним. Если участник аноним, то строка пустая.
* participant_guid: string - уникальный идентификатор участника конференции, выдаваемый бэкендом.

#### Плагин mod_conf_http_log
`mod_conf_http_log` - это плагин, собирающий события происходящие в конференции и отправляющий их в бэкэнд, для
дальнейшего анализа модулем статистики.

Плагин сигнализирует о следующих событиях:
* `room_created` - создана конференции.
* `occupant_joined` - участник присоединился к конференции.
* `occupant_leaving` - участник покинул конференцию.
* `room_destroyed` - конференция завершена.

Перед использованием плагин не обходимо сконфигурировать задав параметер `conference_logger_url`.

Файл с плагином: _confomeet/prosody/porosody-plugins-custom/mod\_conf\_http\_log.lua_

#### Плагин mod_auto_lobby
`mod_auto_lobby` - это плагин, который проверяет наличие флага autoLobby в сессии пользователя и включает комнату
ожидания, если флаг выставлен. Данный плагин требует, чтобы был включен плагин `muc_lobby_rooms`, входящий в поставку docker-jits-meet.
При создании конференеции плагин создает комнату ожидания, а когда в комнату начинаются присоединяться
участники, перенапрвляет в комнату ожидания вместо комнаты конференции всех участников, в сессии которых флаг `autoLobby`
выставлен, а флаг `moderator` не выставлен.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom/mod\_auto\_lobby.lua_

#### Плагин mod_grant_moderator_rights
`mod_grant_moderator_rights` - это плагин, который выдает права модератора всем участникам, у которых в сессии выставлен
флаг `moderator` и забирает выдаваемые jitsi по умолчанию права модератора у тех участников, в чьей сесси этот флаг
не выставлен.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom/mod\_grant\_moderator\_rights.lua_.

#### Плагин mod_jibri_autostart
`mod_jibri_autostart` - это плагин, который при присоединении модератора к конференции проверяет, выставлен ли в его
сессии флаг `autoRec`, и запускает запись конференции, если данный флаг выставлен.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom/mod\_jibri\_autostart.lua_


#### Плагин mod_kick_back_to_lobby
`mod_kick_back_to_lobby` - это плагин, который позволяет модератору конференции отправлять участников в комнату ожидания,
откуда эти участники могут снова попытаться присоединиться к встрече, проходя через процесс одобрения их присоединения
модератором.

Данный плагин обрабатывает специальный запрос, отправляемый модератором конференции по специальному протоколу расширению
протокола xmpp. Данный запрос и ответ на него требуют поддержки со стороны клиентского кода, поэтому данный плагин
работает только с нашей версией jitsi-meet, которая была доработана для поддержки данного функционала.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom/mod\_kick\_back\_to\_lobby.lua_.

#### Плагин mod_single_access
`mod_single_access` - это плагин, позволяющий контролировать, чтобы только каждый учетная запись, под которой участник
присоединился к конференции была в данной конфернеции в единственной. Плагин не позволяет пользователю повторно
присоединиться к конференции с другого устройства или из другой вкладки браузера.

Если в сессии пользователя выставлен флаг `singleAccess`, то при попытке его присоединения к конференции плагин
сравнивает `participant_guid` из сессии каждого участника с `participant_guid` в сессии данного участника. И запрещает
подключение нового пользователя к конференции, если в комнате конференции уже есть пользователь с такими же данными.

Файл с плагином: _confomeet/prosody/prosody-plugins-custom/mod\_mod\_single\_access.lua_.

## Обновление

После обновления каждого из сервисов его следует перезапускать с полным пересозданием, чтобы конфигурация переменных
окружения контейнера была в актульном состоянии.
Используется команда
```
$ docker compose up -d --force-recreate <SERVICE>
```

### Обновление на новую версию docker-jitsi-meet
При обновлении на новую версию jitsi meet нельзя просто заменить файлы сервисов jicofo и jibri, а требуется выполнить
слияние изменений из новой версии docker-jitsi-meet и наших кастомизаций. Кастомизации описаны в предыдущем разделе
_Кастомизация self-hosted jitsi meet_.

После слияния, при выкладывании в продакшн окружение необходимо выполнить полную пересборку всех образов контейнеров
системы.

### Обновление компонентов confomeet
Обновление сервиса бэкенда и сервиса nginx выполняется полной пересборкой образов контейнеров.
