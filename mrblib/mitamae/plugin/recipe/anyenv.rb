
anyenv = {
  # user: 'vagrant', # ENV['SUDO_USER'] > ENV['USER']
  # group: 'vagrant',# run_command("id -gn #{node[:anyenv][:user]}").stdout.strip!
  # anyenv_root: '', # node[:user][node[:anyenv][:user]][:directory]/.anyenv
  repository: 'https://github.com/anyenv/anyenv',
  revision: 'HEAD',
  anyenv_plugins: [
    'https://github.com/znz/anyenv-update.git',
    'https://github.com/znz/anyenv-git.git',
  ],
  install_dependency: true,
  build_envs: {
    PYTHON_CONFIGURE_OPTS: "--enable-shared",
    PIPENV_VENV_IN_PROJECT: "true",
    RUBY_CONFIGURE_OPTS: "--enable-shared"
  },
  envs: {
    pyenv: {
      versions: [
        '3.7.4'
      ],
      global: '3.7.4',
      plugins: [
        'https://github.com/momo-lab/xxenv-latest.git',
        'https://github.com/pyenv/pyenv-doctor.git',
        'https://github.com/pyenv/pyenv-installer.git',
        'https://github.com/pyenv/pyenv-update.git',
        'https://github.com/pyenv/pyenv-virtualenv.git',
        'https://github.com/pyenv/pyenv-which-ext.git'
      ]
    },
    rbenv: {
      versions: [],
      plugins: [
        'https://github.com/momo-lab/xxenv-latest.git',
        'https://github.com/sstephenson/rbenv-default-gems.git',
        'https://github.com/sstephenson/rbenv-gem-rehash.git'
      ]
    }
  },
}
node[:anyenv] ||= {}
node[:anyenv].reverse_merge!(anyenv)

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

