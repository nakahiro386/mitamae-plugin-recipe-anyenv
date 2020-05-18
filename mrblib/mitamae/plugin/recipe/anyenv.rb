default_values = YAML.load(File.read("#{File.dirname(__FILE__)}/anyenv.yaml"))

node[:anyenv] ||= {}
node[:anyenv].reverse_merge!(default_values["anyenv"])

unless node[:anyenv][:user]
  user = ENV['SUDO_USER']  # vagrant
  user ||= ENV['USER'] # root
  node[:anyenv][:user] = user
end
unless node[:anyenv][:group]
  node[:anyenv][:group] ||= run_command("id -gn #{node[:anyenv][:user]}").stdout.strip!
end

user_info = node['user'][node[:anyenv][:user]]
user_home = user_info['directory']
node[:anyenv][:user_home] ||= user_info['directory']

node[:anyenv][:anyenv_root] ||= File.join(node[:anyenv][:user_home], '.anyenv')


unless node[:anyenv][:profile]
  profile = '.profile'
  if ['fedora', 'redhat', 'amazon'].include?(node[:platform])
    profile = '.bash_profile'
  end
  node[:anyenv][:profile] = File.join(node[:anyenv][:user_home], profile)
end

if node[:anyenv][:install_dependency]
  include_recipe 'anyenv::dependency'
end

include_recipe 'anyenv::install'

