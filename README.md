# kbot
Just a test golang based bot for telegram.
It does nothing :)
May be found here: https://t.me/piavik_bot

Інсталяція:
1. Встановити Golang та налаштувати середовище розробки
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz

    sudo tar -C /usr/local -xzf ./go1.21.6.linux-amd64.tar.gz

    export PATH=$PATH:/usr/local/go/bin
2. Створити Telegram-бота за допомогою BotFather.
3. Отримати токен бота та зберегти його у змінну середовища TELE_TOKEN.

    read -s TELE_TOKEN
4. Скомпілювати програму, задавши версію при компіляції

    go build -ldflags "-X="github.com/piavik/kbot/cmd.appVersion=v1.0.ХХХ
5. Запустити

    .kbot start

Приклади використання:
- Показати допомогу:

    kbot help
- Показати версію

    kbot version
- Запуск бота:

    kbot start