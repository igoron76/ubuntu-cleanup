# Ubuntu Server Tools

Набор скриптов для первоначальной настройки, очистки и администрирования Ubuntu Server.

## Скрипты

### 1. Ubuntu Cleanup

`ubuntu-cleanup.sh` предназначен для очистки Ubuntu Server после установки или обновления системы.

#### Запуск

```bash
curl -fsSL https://raw.githubusercontent.com/igoron76/ubuntu-cleanup/main/ubuntu-cleanup.sh | sudo bash
```

#### Что делает скрипт

- удаляет установленные Snap-пакеты;
- отключает службы `snapd`;
- удаляет `snapd`;
- удаляет `cloud-init`;
- удаляет ненужные зависимости через APT;
- очищает APT cache;
- удаляет оставшиеся каталоги Snap и Cloud-Init;
- сохраняет сетевую конфигурацию `/etc/netplan`;
- выполняет проверку системы после очистки.

> Перед запуском на production-сервере рекомендуется ознакомиться с содержимым скрипта.

---

### 2. Добавление администратора igoron

`add-igoron-admin.sh` автоматически создаёт и настраивает административного пользователя `igoron` с доступом по SSH-ключу.

#### Запуск

```bash
curl -fsSL https://raw.githubusercontent.com/igoron76/ubuntu-cleanup/main/add-igoron-admin.sh | sudo bash
```

#### Что делает скрипт

- создаёт пользователя `igoron`, если он ещё не существует;
- создаёт домашний каталог пользователя;
- создаёт каталог `~/.ssh`;
- добавляет SSH public key в `authorized_keys`;
- не добавляет ключ повторно при повторном запуске;
- устанавливает правильные владельца и права для `.ssh` и `authorized_keys`;
- добавляет пользователя `igoron` в группу `sudo`;
- создаёт файл `/etc/sudoers.d/igoron`;
- разрешает выполнение `sudo` без ввода пароля;
- проверяет конфигурацию sudo через `visudo`.

Устанавливаемое правило sudo:

```text
igoron ALL=(ALL) NOPASSWD: ALL
```

После установки можно подключиться к серверу:

```bash
ssh igoron@SERVER_IP
```

Получить root:

```bash
sudo -i
```

#### Безопасность

`add-igoron-admin.sh` является персональным provisioning-скриптом.

В репозитории находится только **публичный SSH-ключ**. Приватный SSH-ключ в репозитории не хранится.

При этом запуск данного скрипта предоставляет владельцу соответствующего приватного ключа:

- SSH-доступ под пользователем `igoron`;
- полный доступ через `sudo`;
- возможность получить root без ввода пароля.

Не запускайте этот скрипт на серверах, где такой административный доступ не требуется.

---

## Проверка перед запуском

Вместо выполнения через `curl | bash` скрипт можно сначала скачать и проверить.

### Ubuntu Cleanup

```bash
curl -fsSLO https://raw.githubusercontent.com/igoron76/ubuntu-cleanup/main/ubuntu-cleanup.sh

less ubuntu-cleanup.sh

sudo bash ubuntu-cleanup.sh
```

### Добавление пользователя igoron

```bash
curl -fsSLO https://raw.githubusercontent.com/igoron76/ubuntu-cleanup/main/add-igoron-admin.sh

less add-igoron-admin.sh

sudo bash add-igoron-admin.sh
```

---

## Требования

- Ubuntu Server
- `root` или пользователь с `sudo`
- доступ в интернет для загрузки скриптов

## Репозиторий

https://github.com/igoron76/ubuntu-cleanup