module Policr
  class CleanModeCommander < Commander
    alias EnableStatus = Policr::EnableStatus
    alias DeleteTarget = Policr::CleanDeleteTarget

    def initialize(bot)
      super(bot, "clean_mode")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("clean_mode.desc"), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def create_markup(chat_id)
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "CleanMode:#{name}")
      }
      symbol = ->(delete_target : DeleteTarget) {
        cm = Model::CleanMode.where { (_chat_id == chat_id) & (_delete_target == delete_target.value) }.first
        if cm
          cm.status == EnableStatus::TurnOn.value ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }
      markup = Markup.new
      def_button_list ["timeout_verified", "wrong_verified", "welcome", "from"]

      markup
    end

    macro def_button_list(target_list)
      {% for target_s in target_list %}
        {{ delete_target = target_s.camelcase }}
        markup << [
                    btn.call("#{symbol.call(DeleteTarget::{{delete_target.id}})} #{t("clean_mode.{{target_s.id}}")}", {{target_s}}),
                    btn.call("#{t("clean_mode.delay_time")} #{MORE_SYMBOL}", "{{target_s.id}}_delay_time")
                  ]
      {% end %}
    end
  end
end