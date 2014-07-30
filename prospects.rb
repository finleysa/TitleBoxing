#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'csv'
require_relative 'keys'

agent = Mechanize.new
page = agent.get('https://clear.titleboxingclub.com/clubLogin.aspx')

# LOGIN
login_form = page.form_with(:id => 'aspnetForm') do |f|
  f.field_with(:name => 'ctl00$cphBody$tbID').value = get_username
  f.field_with(:name => 'ctl00$cphBody$tbPWD').value = get_password
end
puts "Logged in!"

# NEW PROSPECT FORM
page = login_form.click_button
page = page.link_with(:href => '/prospects/NewProspect.aspx').click

# READ IN  NEW CSV
prospects = Array.new
CSV.foreach(ARGV[0]).each do |row|
  prospects << row
end
puts "New CSV loaded!"

old_prospects = Array.new
CSV.foreach(ARGV[1]).each do |row|
old_prospects << row
end
puts "Old CSV loaded!"

if prospects.length > old_prospects.length
  # FILL OUT NEW PROSPECT FORM
  count = 0
  input = 'ctl00$ctl00$ctl00$cphMainBody$cphBody$cphProspectBody$'
  for prospect in prospects
    # 0email 1date 2name 3fbid 4blank 5blank 6blank 7ip 8first 9last 10phone 11blank 12birthday 13location 14email
    does_contain = old_prospects.include?(prospect)
    if does_contain == false
      name = prospect[2].split(' ')

      new_form = page.form_with(:id => 'aspnetForm') do |f|
        f.field_with(:name => "#{input}tbFirstName").value = "#{name[0]}"
        if name.length > 2
          f.field_with(:name => "#{input}tbLastName").value = "#{name[2]}"
        else
          f.field_with(:name => "#{input}tbLastName").value = "#{name[1]}"
        end
        if prospects[10] != ''
        f.field_with(:name => "#{input}tbHomePhone").value = "#{prospect[10]}"
        else
        f.field_with(:name => "#{input}tbHomePhone").value = "5555555555"
        end
        if prospect[13]
          location = prospect[13].split(', ')
          f.field_with(:name => "#{input}tbCity").value = "#{location[0]}"
        end
        f.field_with(:name => "#{input}ddReferralSource").options[7].select
        f.field_with(:name => "#{input}ddEnteredBy").options[2].select
        f.field_with(:name => "#{input}ddSalesPerson").options[2].select
        f.field_with(:name => "#{input}tbEmail").value = "#{prospect[0]}"
      end
      print "."
      count = count + 1
      new_form.click_button(new_form.button_with(:name => "#{input}bSave"))
      page = page.link_with(:href => '/prospects/NewProspect.aspx').click
    end
  end
  puts "\n #{count} prospects successfully added!"
else
  puts "The new file has less prospects than the old."
  puts "Aborting"
end

