# Telegram Bot for Daily Coin/Token Mining Combos

This bot provides daily combinations for various coin/token mining bots such as Hamster, Gemz, PixelVerse, MemeFi, and more as they become available. Users can choose which mining bot they need a daily code for, and the bot sends a single file showing the successful daily combo picture stored in a local folder. Additionally, the bot provides links to other new mining bots.

## Getting Started

1. Clone the repository:
    ```sh
    git clone https://github.com/samzhab/SL_dailycryptominingcombo_bot.git
    ```
2. Crete a Gemset:
```sh
rvm 3.1.0@SlCryptMineComboBot --create
```

3. Install dependencies:
```sh
bundle install
```

4. Obtain a Telegram Bot API token from [@BotFather](https://t.me/BotFather). Create an env file and set it to TELEGRAM_BOT_TOKEN

5. Create YAML file with your refferal codes in the following format - and name it refferals.yml
    refferals:
      - bot: "Bot Name"
        url: "https://example.com"

6. Replace `YOUR_BOT_TOKEN` in the `.env` file with your actual bot token.

7. Create `logs` and `dailycombos` and `hamster`, `gemz`, etc folders:
    ```sh
    mkdir logs dailycombos
    ```

    ```sh
    cd dailycombos && mkdir dailycombos
    ```
8. Run the bot:
    ```sh
    ruby Sl_Crypt_Mine_Combo_Bot.rb
    ```

9. Interact with the bot in your Telegram app.

## Bot User Commands

- `/start` - Starts this bot
- `/help` - Displays available commands
- `/terms` - Read the terms

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
