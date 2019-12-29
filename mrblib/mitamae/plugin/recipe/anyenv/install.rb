directory File.join(node[:anyenv][:user_home], '.local') do
  action :create
  owner node[:anyenv][:user]
  group node[:anyenv][:group]
  mode "700"
end

directory File.join(node[:anyenv][:user_home], '.local', 'bin') do
  action :create
  owner node[:anyenv][:user]
  group node[:anyenv][:group]
  mode "775"
end

directory File.join(node[:anyenv][:user_home], '.cache') do
  action :create
  owner node[:anyenv][:user]
  group node[:anyenv][:group]
  mode "700"
end

config_home = ENV['XDG_CONFIG_HOME']
config_home ||= File.join(node[:anyenv][:user_home], '.config')
directory config_home do
  action :create
  owner node[:anyenv][:user]
  group node[:anyenv][:group]
  mode "700"
end

git node[:anyenv][:anyenv_root] do
  repository node[:anyenv][:repository]
  revision node[:anyenv][:revision]
  user node[:anyenv][:user]
  not_if "test -d #{node[:anyenv][:anyenv_root]}"
end

build_envs = node[:anyenv][:build_envs].map do |key, value|
  %Q[export #{key}="#{value}"\n]
end.join
anyenv_bin = File.join(node[:anyenv][:anyenv_root], 'bin', 'anyenv')
file "#{node[:anyenv][:profile]}" do
  action :edit
  user node[:anyenv][:user]
  block do |content|
    unless content =~ /ANYENV_ROOT/
      content.concat <<-CONF
# mitamae managed START
if [ -x "#{anyenv_bin}" ] ; then
    export ANYENV_ROOT=#{node[:anyenv][:anyenv_root]};
    export PATH="$ANYENV_ROOT/bin:$PATH"

    ANYENV_INIT_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/.anyenv_cache"
    if [ -r "$ANYENV_INIT_CACHE" ] ; then
        source "$ANYENV_INIT_CACHE" 
    else
        anyenv init - bash --no-rehash > "$ANYENV_INIT_CACHE"
        eval "$(anyenv init - bash)"
    fi
fi
#{build_envs}
# mitamae managed END
      CONF
    end
  end
end

execute "#{anyenv_bin} install --force-init" do
  not_if "test -d #{config_home}/anyenv/anyenv-install"
  user node[:anyenv][:user]
end


plugins_dir = File.join(node[:anyenv][:anyenv_root], 'plugins')

node[:anyenv][:anyenv_plugins].each do |plugin|
  plugin_name = File.basename(plugin).gsub(/\.git$/, '')
  plugin_dir = File.join(plugins_dir, plugin_name)
  git plugin_dir do
    repository plugin
    revision 'HEAD'
    user node[:anyenv][:user]
    not_if "test -d #{plugin_dir}"
  end
end

anyenv_init = <<-EOS
  export ANYENV_ROOT=#{node[:anyenv][:anyenv_root]};
  export PATH="$ANYENV_ROOT/bin:$PATH"
  eval "$(anyenv init - bash --no-rehash)"
EOS

node[:anyenv][:envs].each do |env, options|
  env_dir = File.join(node[:anyenv][:anyenv_root], 'envs', env)
  execute  "#{anyenv_init} #{build_envs} #{anyenv_bin} install --skip-existing #{env}" do
    not_if "test -d #{env_dir}"
    user node[:anyenv][:user]
  end
  directory "#{env_dir}/cache" do
    action :create
    user node[:anyenv][:user]
  end
  options['plugins'].each do |plugin|
    plugin_name = File.basename(plugin).gsub(/\.git$/, '')
    plugin_dir = File.join(node[:anyenv][:anyenv_root], 'envs', env, 'plugins', plugin_name)
    git plugin_dir do
      repository plugin
      revision 'HEAD'
      not_if "test -d #{plugin_dir}"
      user node[:anyenv][:user]
    end
  end
  options['versions'].each do |version|
    execute  "#{anyenv_init} #{build_envs} #{env_dir}/bin/#{env} install --skip-existing #{version}" do
      not_if "test -d #{env_dir}/versions/#{version}"
      user node[:anyenv][:user]
    end
  end
  if options['global']
    execute  "#{anyenv_init} #{build_envs} #{env_dir}/bin/#{env} global #{options['global']}" do
      not_if "#{anyenv_init} #{build_envs} #{env_dir}/bin/#{env} global | grep -x #{options['global']}"
      user node[:anyenv][:user]
    end
  end

end
