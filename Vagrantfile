Vagrant::Config.run do |config|
  config.vm.box = "socorro-all"
  config.vm.network "33.33.33.10"
  config.vm.provision :puppet do |puppet|
    puppet.manifest_file = "init.pp"
  end
end
