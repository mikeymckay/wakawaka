After do |scenario|
  # Do something after each scenario.
  # The +scenario+ argument is optional, but
  # if you use it, you can inspect status with
  # the #failed?, #passed? and #exception methods.

  if scenario.exception and scenario.exception.message.match(/expected #has_content/)
    name = File.join(*["/tmp", "capybara-#{Time.new.strftime("%Y%m%d%H%M%S")}.html"].compact)

    unless Capybara.save_and_open_page_path.nil? || File.directory?(Capybara.save_and_open_page_path )
      FileUtils.mkdir_p(Capybara.save_and_open_page_path)
    end
    FileUtils.touch(name) unless File.exist?(name)

    tempfile = File.new(name,'w')
    tempfile.write(body)
    tempfile.close

    puts "Page text during exception:\n" + `lynx --dump #{tempfile.path}`
  end
end

