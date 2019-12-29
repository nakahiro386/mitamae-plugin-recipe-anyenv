packages = %w(git curl wget)
node[:anyenv][:envs].each do |env, options|
  if env == 'pyenv'
    # Common build problems · pyenv/pyenv Wiki · GitHub
    # https://github.com/pyenv/pyenv/wiki/common-build-problems
    case node[:platform]
    when 'ubuntu', 'debian'
      packages = packages | %w(make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils libffi-dev liblzma-dev python-openssl)
    when 'fedora', 'redhat', 'amazon'
      check_command = node[:platform] == 'redhat' && node[:platform_version].to_i >= 8 ?
        "env LANG=C dnf group list --installed -v" :
        "env LANG=C yum groups list -e0 -q installed hidden ids"
      groups = run_command(check_command).stdout
      unless groups.include?('(development)')
        packages = packages | %w(@development)
      end
      packages = packages | %w(zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel findutils)
    end
  end
  if env == 'rbenv'
    # Home · rbenv/ruby-build Wiki · GitHub
    # https://github.com/rbenv/ruby-build/wiki#suggested-build-environment
    case node[:platform]
    when 'ubuntu', 'debian'
      packages =  packages | %w(autoconf bison build-essential libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev)
    when 'fedora', 'redhat', 'amazon'
      if node[:platform] == 'redhat' && node[:platform_version].to_i >= 8
        execute "env LANG=C dnf config-manager --set-enabled PowerTools" do
          not_if "env LANG=C dnf -e0 -q repolist --enabled | grep -q -e ^PowerTools"
        end
      end
      packages =  packages | %w(gcc bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel)
    end
  end
end
packages.each do |pkg|
  package pkg
end
