#Factory.sequence :name do |n|
#  "First Last #{n}"
#end
#
#Factory.sequence :username do |n|
#  "firstlast#{n}"
#end
#
#Factory.sequence :phone_number do |n|
#  "+1234567890#{n}"
#end
#
#Factory.define :user do |user|
#  user.twitter_username  { Factory.next :username }
#  user.facebook_name { Factory.next :name }
#  user.phone_number      { Factory.next :phone_number }
#  user.team              { "LAA" }
#end
#
#Factory.define :admin, :parent => :user do |user|
#  user.admin { true }
#end
