module M::DocumentsHelper
  def user_defined_tags
    (@document.tags_array & @parent_profile.user_tags.map(&:tag)).to_a.join(', ')
  end
end
