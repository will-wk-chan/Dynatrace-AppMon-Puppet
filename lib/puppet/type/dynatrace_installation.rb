Puppet::Type.newtype(:dynatrace_installation) do
  desc "Puppet type that models a Dynatrace installation."

  ensurable do
    newvalue(:present) do
      provider.install
    end

    newvalue(:installed) do
      provider.install
    end

    # Alias the 'present' value.
    aliasvalue(:installed, :present)

    newvalue(:absent) do
      provider.uninstalled
    end

    newvalue(:uninstalled) do
      provider.uninstalled
    end

    # Alias the 'present' value.
    aliasvalue(:uninstalled, :absent)

  end

  newparam(:name, :namevar => :true) do
  end

  newparam(:installer_prefix_dir) do
    defaultto '/opt'
  end

  newparam(:installer_file_name) do
  end

  newparam(:installer_file_url) do
  end

  newparam(:installer_script_name) do
  end

  newparam(:installer_path_part) do
    defaultto ''
  end
  
  newparam(:installer_path_detailed) do
    defaultto ''
  end

  newparam(:installer_owner) do
    defaultto 'dynatrace'
  end

  newparam(:installer_group) do
    defaultto 'dynatrace'
  end

  newparam(:installer_cache_dir) do
    defaultto '/tmp'
  end

  newparam(:java_home_bin) do
    defaultto ''
  end

end

