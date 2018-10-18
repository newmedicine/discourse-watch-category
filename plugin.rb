# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/newmedicine/discourse-watch-category

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      "consultants" => [ "cons" ],
      "trust_level_2" => [ "general" ]
      # "everyone" makes every user watch the listed categories
      # "everyone" => [ "announcements" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)
    #groups_cats_first = {
    #  "trust_level_2" => [ "clinical" ]
    #}
    #WatchCategory.change_notification_pref_for_group(groups_cats_first, :watching_first_post)
    #groups_cats = {
    #  "infolit" => [ ["interest-groups", "information-literacy"] ],
    #  "pedagogy" => [ ["interest-groups", "pedagogy"] ],
    #  "coordinating-cmte" => [ "announcements" ],
    #  "representatives" => [ "announcements" ]
    #}
    #WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == "everyone"
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 6.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
