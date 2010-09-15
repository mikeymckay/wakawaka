
Given /^(?:|I )wait (\d+) seconds*$/ do |seconds|
  sleep(seconds.to_i)
end

Then /^dump the page$/ do
  puts body
end

Then /^lynxdump the page$/ do
  name = File.join(*[Capybara.save_and_open_page_path, "capybara-#{Time.new.strftime("%Y%m%d%H%M%S")}.html"].compact)

  unless Capybara.save_and_open_page_path.nil? || File.directory?(Capybara.save_and_open_page_path )
    FileUtils.mkdir_p(Capybara.save_and_open_page_path)
  end
  FileUtils.touch(name) unless File.exist?(name)

  tempfile = File.new(name,'w')
  tempfile.write(body)
  tempfile.close

  puts `lynx --dump #{tempfile.path}`

end

Given /^(?:|I )click on "([^\"]*)"?$/ do |selector|
  #click("//*[text()='#{selector}']")
  #find("//*[text()='#{selector}']").click
  # Click on the last matched element that contains the text in selector
  page.execute_script("$(':contains(#{selector}):last').click()")
end
