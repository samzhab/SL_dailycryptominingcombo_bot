# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'httparty'
require 'logger'
require 'byebug'
require 'yaml'
require 'date'
require 'rqrcode'
require 'open-uri'
# Module for helper methods
module BotHelpers
  def self.validate_presence(values, names)
    Array(values).zip(Array(names)).each do |value, name|
      raise ArgumentError, "Invalid or missing #{name}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end

# Module for Error handling
module ErrorHandler
  def handle_error(error, context = 'General')
    error_message = "#{context}: #{error.message}"
    puts error_message
  end
end

# Helper class to allow Logger to write to multiple outputs
class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each { |target| target.write(*args) }
  end

  def close
    @targets.each(&:close)
  end
end

# Set up the logger
LOG_FILE = File.join('logs', 'bot.log')
LOGGER = Logger.new(MultiIO.new(File.open(LOG_FILE, 'a'), $stdout), 'daily')
LOGGER.formatter = proc do |severity, datetime, _progname, msg|
  "#{datetime}: #{severity} -- #{msg}\n"
end

class SlCryptMineComboBot
  include BotHelpers # This mixes in BotHelpers methods as instance methods
  include ErrorHandler
  extend ErrorHandler

  class << self
    def load_ui_strings
      file_path = 'ui_strings.yml'
      if File.exist?(file_path)
        YAML.load_file(file_path)
      else
        error_message = "Error: UI strings file not found at #{file_path}"
        handle_error(RuntimeError.new(error_message), 'load_ui_strings')
        {}
      end
    end

    def load_referrals
      file_path = 'referrals.yml'
      if File.exist?(file_path)
        YAML.load_file(file_path)
      else
        error_message = "Error: Referrals file not found at #{file_path}"
        handle_error(RuntimeError.new(error_message), 'load_referrals')
        {}
      end
    end

    def run(token)
      BotHelpers.validate_presence(token, 'token')
      bot_instance = new # Create an instance of MyTelegramBot
      Telegram::Bot::Client.run(token) do |bot|
        bot_instance.bot_listen(bot) # Call instance method 'bot_listen' on the created instance
      end
    rescue StandardError => e
      handle_error(e, 'run') # Assuming handle_error is correctly defined to handle such errors
    end
    # end of class methods
  end

  UI_STRINGS = load_ui_strings
  REFERRALS = load_referrals

  def bot_listen(bot)
    puts '-----------------------------------------------------------------'
    bot.listen do |update|
      LOGGER.info("Received update: #{update.to_json}")
      case update
      when Telegram::Bot::Types::Message
        clear_screen(bot, update.from.id, update.message_id)
        respond_to_message(bot, update)
      when Telegram::Bot::Types::CallbackQuery
        clear_screen(bot, update.from.id, update.message.message_id)
        handle_callback_query(bot, update)
      end
    end
  end

  def respond_to_message(bot, message)
    LOGGER.info("Responding to message from user #{message.from.id}: '#{message.text}'")
    BotHelpers.validate_presence([bot, message], %w[bot message])
    begin
      command = extract_command(message.text) # Extracting the first word of the command
      if !command.nil? && !command.empty?
        case command.first
        when '/start', '/start@SlCryptMineComboBot'
          send_start_message(bot, message)
        when '/combos', '/combos@SlCryptMineComboBot'
          send_data_with_buttons(bot, message)
        when '/privacy', '/privacy@SlCryptMineComboBot'
          send_privacy_message(bot, message)
        when '/terms', '/terms@SlCryptMineComboBot'
          send_terms_message(bot, message)
        else
          send_helpful_message(bot, message)
        end
      end
    rescue ArgumentError, StandardError => e
      LOGGER.error("#{e.class} - respond_to_message: #{e.message}")
      handle_error(e, "#{e.class} - respond_to_message")
    end
  end

  def extract_command(text)
    # Regular expression to extract the command, link, username (optional), day (optional), and time (optional)
    # command = text.match(/^\/(set\d|upd|rmv)\s+(?:(t\.me\/\S+)|(\w+))(?:\s+(\w+)(?:\s+(\d{4})))?/)
    return '' if text.nil?
    text.split
  end

  def load_data
    # Find YAML file starting with "data" and having ".yml" or ".yaml" extension
    yaml_file = Dir.glob('data*.yaml').first || Dir.glob('data*.yml').first

    if yaml_file
      # Load YAML file
      YAML.load_file(yaml_file)
    else
      # Handle case when no matching file is found
      puts "No YAML file starting with 'data' found."
      {}
    end
  end

  def set_link(bot, message, key, link, data)
    data[key] = link
    File.open("data#{Time.now.to_s.split[0]}.yaml", 'w') { |file| file.write(data.to_yaml) }
    bot.api.send_message(chat_id: message.chat.id, text: "#{key.capitalize} set to: #{link}")
  end

  def send_start_message(bot, message)
    bot.api.send_message(chat_id: message.chat.id,
      text: "✔️ ቦት ተጀምሯል እና ለእርስዎ ዝግጁ ነው። /combos ይሞክሩ | The bot has started and is ready for you. try /combos")
  end

  def send_data_with_buttons(bot, message)
    # Prepare message text
    message_text = 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'

    # Load buttons from YAML file
    button_data = YAML.load_file('buttons.yml')['buttons']

    # Randomly select 2 buttons
    selected_buttons = button_data.sample(2).map do |button|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: button['text'],
        callback_data: button['callback_data']
      )
    end

    # Create inline keyboard markup with the selected buttons
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [selected_buttons])

    # Send message with inline keyboard
    bot.api.send_message(chat_id: message.chat.id, text: message_text, reply_markup: markup)
  end

  def parse_time(time_of_day_string, target_date)
    # Attempt to parse with HH:MM format
    parsed_time = begin
      DateTime.strptime(time_of_day_string, '%H:%M')
    rescue ArgumentError
      # Attempt to parse with HHMM format
      DateTime.strptime(time_of_day_string, '%H%M')
    rescue ArgumentError
      puts "Invalid time format: #{time_of_day_string}"
      nil
    end

    if parsed_time
      Time.new(target_date.year, target_date.month, target_date.day, parsed_time.hour,
               parsed_time.min).strftime('%Y-%m-%d %H:%M:%S')
    else
      # Handle invalid time format
      nil
    end
  end

  def clear_screen(bot, chat_id, message_id)
    LOGGER.info("Clering the screen for user #{chat_id} - message id - #{message_id}")
    bot.api.delete_message(chat_id: chat_id, message_id: message_id)
  rescue StandardError => e
    LOGGER.error("Error in clear_screen: #{e.class}: #{e.message}")
  end

  def handle_callback_query(bot, callback_query)
    BotHelpers.validate_presence([bot, callback_query], %w[bot callback_query])
    LOGGER.info("Handling callback query from user #{callback_query.from.id} - #{callback_query.from.username}: '#{callback_query.data}'")
    begin
      case callback_query.data
      when 'Hamster'
        hamster_combo(bot, callback_query)
      when 'PixelVerse'
        pixelverse_combo(bot, callback_query)
      when 'Gemz'
        gemz_combo(bot, callback_query)
      when 'Swopin'
        swopin_combo(bot, callback_query)
      when 'Chaindrops'
        chaindrops_combo(bot, callback_query)
      else ''
      end
    rescue StandardError => e
      LOGGER.error("Error in handle_callback_query: #{e.class}: #{e.message}")
      bot.api.send_message(chat_id: callback_query.from.id,
                           text: UI_STRINGS['request_error_info'])
    end
  end

  def hamster_combo(bot, callback_query)
    # Send the formatted message
    bot.api.send_message(chat_id: callback_query.message.chat.id, text: 'የዛሬው combo ነው።')

    # Prepare the image file for upload
    image_path = 'dailycombos/hamster/hamster.jpg' # Replace with the actual path to your image file
    image_file = Faraday::UploadIO.new(image_path, 'image/jpg')

    # Send the image as a photo
    bot.api.send_photo(
      chat_id: callback_query.message.chat.id,
      photo: image_file,
      caption: 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'
    )
    send_squad_invites(bot, callback_query.message)
  end

  def pixelverse_combo(bot, callback_query)
    # Send the formatted message
    bot.api.send_message(chat_id: callback_query.message.chat.id, text: 'የዛሬው combo ነው።')

    # Prepare the image file for upload
    image_path = 'dailycombos/pixelverse/pixelverse.jpg' # Replace with the actual path to your image file
    image_file = Faraday::UploadIO.new(image_path, 'image/jpg')

    # Send the image as a photo
    bot.api.send_photo(
      chat_id: callback_query.message.chat.id,
      photo: image_file,
      caption: 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'
    )
    send_squad_invites(bot, callback_query.message)
  end

  def gemz_combo(bot, callback_query)
    # Send the formatted message
    bot.api.send_message(chat_id: callback_query.message.chat.id, text: 'የዛሬው combo ነው።')

    # Prepare the image file for upload
    image_path = 'dailycombos/gemz/gemz.jpg' # Replace with the actual path to your image file
    image_file = Faraday::UploadIO.new(image_path, 'image/jpg')

    # Send the image as a photo
    bot.api.send_photo(
      chat_id: callback_query.message.chat.id,
      photo: image_file,
      caption: 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'
    )
    send_squad_invites(bot, callback_query.message)
  end

  def swopin_combo(bot, callback_query)
    # Send the formatted message
    bot.api.send_message(chat_id: callback_query.message.chat.id, text: 'የዛሬው combo ነው።')

    # Prepare the image file for upload
    image_path = 'dailycombos/swopin/swopin.jpg' # Replace with the actual path to your image file
    image_file = Faraday::UploadIO.new(image_path, 'image/jpg')

    # Send the image as a photo
    bot.api.send_photo(
      chat_id: callback_query.message.chat.id,
      photo: image_file,
      caption: 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'
    )
    send_squad_invites(bot, callback_query.message)
  end

  def chaindrops_combo(bot, callback_query)
    # Send the formatted message
    bot.api.send_message(chat_id: callback_query.message.chat.id, text: 'የዛሬው combo ነው።')

    # Prepare the image file for upload
    image_path = 'dailycombos/chaindrops/chaindrops.jpg' # Replace with the actual path to your image file
    image_file = Faraday::UploadIO.new(image_path, 'image/jpg')

    # Send the image as a photo
    bot.api.send_photo(
      chat_id: callback_query.message.chat.id,
      photo: image_file,
      caption: 'የዛሬውን combo ይመልከቱ! ቻናላችንን ይቀላቀሉ @SamaelLabs'
    )
    send_squad_invites(bot, callback_query.message)
  end

  def send_squad_invites(bot, message)
    BotHelpers.validate_presence([bot, message], %w[bot message])

    # Access the array of referrals
    referrals_array = REFERRALS['referrals']

    # Select two random items from the array
    selected_referrals = referrals_array.shuffle.take(2)

    # Create inline keyboard buttons with the selected items
    referrals_buttons = selected_referrals.map do |referral|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: referral['bot'],
        url: referral['url'],
      )
    end

    # Create inline keyboard markup with the selected buttons
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [referrals_buttons])
    message_text = "🎁🎁🎁🎁🎁5 X ቴሌግራም ፕሪሚየም ስጦታዎች (3 ወራት) ለመሳተፍ ቻናላችንን ይቀላቀሉ"
    # Send message with inline keyboard
    bot.api.send_message(chat_id: message.chat.id, text: message_text, reply_markup: markup)
  rescue StandardError => e
    LOGGER.error("Error in send_squad_invites: #{e.class}: #{e.message}")
  end

  def send_helpful_message(bot, message)
    helpful_message = UI_STRINGS['help_message']
    LOGGER.info("Sending helpful message to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: helpful_message)
    # Check if the message was successfully sent and record its message_id
    # @displayed_messages[message.from.id] = message.message_id
    # @displayed_messages[response.from.id] = response.message_id
  rescue StandardError => e
    LOGGER.error("Error in send_helpful_message: #{e.class}: #{e.message}")
  end

  def send_terms_message(bot, message)
    terms_of_use = UI_STRINGS['terms_of_use']
    LOGGER.info("Sending helpful message to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: terms_of_use)
  rescue StandardError => e
    LOGGER.error("Error in send_terms_of_use: #{e.class}: #{e.message}")
  end

  def send_privacy_message(bot, message)
    privacy_policy = UI_STRINGS['privacy_policy']
    LOGGER.info("Sending helpful message to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: privacy_policy)
  rescue StandardError => e
    LOGGER.error("Error in send_terms_of_use: #{e.class}: #{e.message}")
  end

  def send_default_message(bot, message)
    default_response = format(UI_STRINGS['default_response'], message_text: message.text)
    LOGGER.info("Sending default response to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: default_response)
  rescue StandardError => e
    LOGGER.error("Error in send_default_message: #{e.class}: #{e.message}")
  end
end
# Remember to implement all the helper methods needed for the logic above.

# start - ይሄንን ቦት ለመጀመር | Starts This Bot
# combos - Combos አሳይ | Display Available Combos
# privacy- ስለ ግላዊ መረጃ አሰባብ ያሳይዎታል | Privacy Policy
# terms - ስለ አጠቃቀም ግዴታዎችና መብቶችን ያሳይዎታል። | Terms of Use

SlCryptMineComboBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
