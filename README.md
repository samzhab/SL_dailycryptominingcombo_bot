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
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

Attribution: This project is published by Samael (AI Powered), 2024.

You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material for any purpose, even commercially.
Under the following terms:
- Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.

No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.
