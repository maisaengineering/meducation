module DocumentsHelper

  def is_clicked?(category_name)
    (params.include?(:clicked_on) and params[:clicked_on].eql?(category_name))
  end

  def user_defined_tags
    (@document.tags_array & @parent_profile.user_tags.map(&:tag)).to_a.join(', ')
  end

  def profile_user_custom_tags(category_id)
    # get custom tag documents of parents who managing the kid
    if @kid_profile
      @kid_profile.parent_profiles.map(&:user_tags).flatten.reject{ |user_tag| !user_tag.category_ids.include?(category_id.to_s)}.uniq{|ut| ut.tag}
      # get custom tag documents of family parents(doc share permission on both sides)
    else
      Profile.in(id: @parent_profile.self_and_shared_docs).map(&:user_tags).flatten.reject{ |user_tag| !user_tag.category_ids.include?(category_id.to_s)}.uniq{|ut| ut.tag}
    end
  end

end
