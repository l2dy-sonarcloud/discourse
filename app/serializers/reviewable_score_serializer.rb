# frozen_string_literal: true

class ReviewableScoreSerializer < ApplicationSerializer
  REASONS_AND_SETTINGS = {
    post_count: "approve_post_count",
    trust_level: "approve_unless_trust_level",
    group: "approve_unless_allowed_groups",
    new_topics_unless_trust_level: "approve_new_topics_unless_trust_level",
    new_topics_unless_allowed_groups: "approve_new_topics_unless_allowed_groups",
    fast_typer: "first_post_typing_time",
    auto_silence_regex: "auto_silence_first_post_regex",
    staged: "approve_unless_staged",
    must_approve_users: "must_approve_users",
    invite_only: "invite_only",
    email_spam: "email_in_spam_header",
    suspect_user: "approve_suspect_users",
    contains_media: "skip_media_review_groups",
  }

  attributes :id, :score, :agree_stats, :reason, :created_at, :reviewed_at

  attribute :status_for_database, key: :status

  has_one :user, serializer: BasicUserSerializer, root: "users"
  has_one :score_type, serializer: ReviewableScoreTypeSerializer
  has_one :reviewable_conversation, serializer: ReviewableConversationSerializer
  has_one :reviewed_by, serializer: BasicUserSerializer, root: "users"

  def agree_stats
    {
      agreed: user.user_stat.flags_agreed,
      disagreed: user.user_stat.flags_disagreed,
      ignored: user.user_stat.flags_ignored,
    }
  end

  def reason
    return unless object.reason

    link_text = setting_name_for_reason(object.reason)
    link_text = I18n.t("reviewables.reasons.links.#{object.reason}", default: nil) if link_text.nil?

    if link_text
      link = build_link_for(object.reason, link_text)

      if object.reason == "watched_word"
        text = watched_word_reason(link)
      else
        text = I18n.t("reviewables.reasons.#{object.reason}", link: link, default: object.reason)
      end
    else
      text = I18n.t("reviewables.reasons.#{object.reason}", default: object.reason)
    end

    text
  end

  def include_reason?
    reason.present?
  end

  def setting_name_for_reason(reason)
    setting_name = REASONS_AND_SETTINGS[reason.to_sym]

    if setting_name.nil?
      plugin_options = DiscoursePluginRegistry.reviewable_score_links
      option = plugin_options.detect { |o| o[:reason] == reason.to_sym }

      setting_name = option[:setting] if option
    end

    setting_name
  end

  private

  def watched_word_reason(link)
    if object.context.nil?
      # If the words weren't recorded, try to guess them based on current settings.
      if object.reviewable.respond_to?(:post)
        s = object.reviewable.post.raw.clone
        s << " #{object.reviewable.post.topic.title}" if object.reviewable.post.post_number == 1
      elsif object.reviewable.respond_to?(:payload)
        s = object.reviewable.payload["raw"].clone
        s << " #{object.reviewable.payload["title"]}" if object.reviewable.payload.key?("title")
      end

      words = WordWatcher.new(s).word_matches_across_all_actions
    else
      words = object.context.split(",")
    end

    if words.nil? || words.empty?
      text =
        I18n.t("reviewables.reasons.no_context.watched_word", link: link, default: "watched_word")
    else
      text =
        I18n.t(
          "reviewables.reasons.watched_word",
          link: link,
          words: words.join(", "),
          count: words.length,
          default: "watched_word",
        )
    end

    text
  end

  def url_for(reason, text)
    case reason
    when "watched_word"
      "#{Discourse.base_url}/admin/customize/watched_words"
    when "category"
      "#{Discourse.base_url}/c/#{object.reviewable.category&.slug}/edit/settings"
    else
      "#{Discourse.base_url}/admin/site_settings/category/all_results?filter=#{text}"
    end
  end

  def build_link_for(reason, text)
    return text.gsub("_", " ") unless scope.is_staff?

    "<a href=\"#{url_for(reason, text)}\">#{text.gsub("_", " ")}</a>"
  end
end
