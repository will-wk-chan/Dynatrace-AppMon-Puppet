#require_relative '../dynatrace_installer'
require File.join(File.dirname(__FILE__), '../dynatrace_installer')


Puppet::Type.type(:dynatrace_installer).provide(:jar, :parent => Puppet::Provider::DynatraceInstaller) do
  desc "Puppet type that models a Dynatrace .jar file installer."

  def get_install_dir(installer_path, java_home_bin = nil)
 
     FileUtils.cd("/tmp")
     jar_exec = "#{java_home_bin}jar"
 
     # extract an init script (includes reference to the dynatrace-x.y.z dir)
     init_script = execute("#{jar_exec} -tf #{installer_path} | grep -e 'init.d' | tail -n 1").strip
     execute("#{jar_exec} -xf #{installer_path} #{init_script}")
 
     # extract the dynatrace-x.y.z directory name from the init script
     install_dir = execute("grep -e 'DT_HOME=' #{init_script} | cut -d'=' -f2 | xargs basename").strip
 
     # remove temporary artefacts
     FileUtils.rm_rf('init.d')
 
     return install_dir
  end

  private

  def self.default?
    true
  end
end
