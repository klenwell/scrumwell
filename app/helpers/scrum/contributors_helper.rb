module Scrum::ContributorsHelper
  def contributor_avatar(contributor, **options)
    size = options[:size] || 32
    avatar_class = format('avatar r%s', size)

    return '' if contributor.avatar_url.nil?
    image_tag contributor.avatar_url, class: avatar_class
  end
end
