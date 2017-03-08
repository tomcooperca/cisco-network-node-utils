# Copyright (c) 2015-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'yaml'
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/yum'
require_relative '../lib/cisco_node_utils/platform'

# TestYum - Minitest for Yum node utility class
class TestYum < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@skip = false
  @@run_setup = true
  # rubocop:enable Style/ClassVars

  @skip_unless_supported = 'yum'

  def select_pkg
    path = File.expand_path('../yum_package.yaml', __FILE__)
    skip('Cannot find tests/yum_package.yaml') unless File.file?(path)
    pkginfo = YAML.load(File.read(path))

    # rubocop:disable Style/ClassVars
    #
    # Replace [.,(,)] characters with '_' for yaml key lookup.
    # Image Version before gsub: 7.0(3)I3(1)
    # Image Version after  gsub: 7_0_3_I3_1_
    @@pv = Platform.image_version.gsub(/[.()]/, '_')[/\S+/]
    info "Image version detected: #{Platform.image_version}"
    skip("No pkginfo filename found for image version #{@@pv}") if
      pkginfo[@@pv].nil?

    @@pkg_filename = pkginfo[@@pv]['filename']
    @@pkg = pkginfo[@@pv]['name']
    @@pkg_ver = pkginfo[@@pv]['version']

    @@incompatible_rpm_msg =
      ": Sample rpm is compatible with version #{Platform.image_version}."  \
      'This test will fail with other versions.'
    # rubocop:enable Style/ClassVars
  end

  def setup
    super
    # only run check once (can't use initialize because @device isn't ready)
    return unless @@run_setup

    select_pkg
    s = @device.cmd("show file bootflash:#{@@pkg_filename} cksum")
    if s[/No such file/]
      @@skip = true # rubocop:disable Style/ClassVars
    else
      # Remnants of the package my still exist from a previous install attempt.
      if Yum.pkg_name(@@pkg_filename).empty?
        steps = []
      else
        info 'Executing test setup... Please be patient, this will take a while.'
        pkg = Yum.pkg_name(@@pkg_filename)
        steps = ["install deactivate #{pkg}",
                 "install commit #{pkg}",
                 "install remove #{pkg} forced",
                 'install remove inactive forced']
      end
      steps.each do |step|
        info "Executing setup step: #{step}..."
        s = @device.cmd(step)
        sleep 20
        debug "Step Complete.\n\n#{s}\n"
      end
    end
    node.cache_flush
    info "Yum pkg_name: |#{Yum.pkg_name(@@pkg_filename)}|"
    unless Yum.query_removed(@@pkg_filename) 
       skip "Unable to remove existing package: #{@@pkg_filename}"
    end
    info "Set @@run_setup: false"
    Yum.add(@@pkg_filename)
    @@run_setup = false # rubocop:disable Style/ClassVars
  end

  def skip?
    skip "file bootflash:#{@@pkg_filename} is required. " \
      'this file can be found in the cisco_node_utils/tests directory' if @@skip
  end

  def test_install_query_remove
    skip?
    # On dublin and later images, must specify the full rpm name.
    package = @@pv[/7_0_3_I2_1_/] ? @@pkg : @@pkg_filename


    # INSTALL
    # Specify "management" vrf for install
    Yum.install(package, 'management')
    assert(Yum.query(@@pkg), "failed to find installed package #{@@pkg}")

    # QUERY INSTALLED
    assert_equal(@@pkg_ver, Yum.query(@@pkg), @@incompatible_rpm_msg)

    # REMOVE
    Yum.remove(Yum.pkg_name(@@pkg_filename))

    # QUERY REMOVED
    assert_nil(Yum.query(@@pkg))

  rescue RuntimeError => e
    assert(false, e.message + @@incompatible_rpm_msg)
  end

  def test_ambiguous_package_error
    skip?
    assert_raises(RuntimeError) { Yum.query('busybox') }
  end

  def test_package_does_not_exist_error
    assert_raises(Cisco::CliError) do
      Yum.install('bootflash:this_is_not_real.rpm', 'management')
    end
    assert_raises(Cisco::CliError) do
      Yum.install('also_not_real', 'management')
    end
  end

  def test_query_added
    #Yum.add(@@pkg_filename)
    #Yum.activate(Yum.pkg_name(@@pkg_filename))
    #Yum.commit(Yum.pkg_name(@@pkg_filename))
    #Yum.remove(Yum.pkg_name(@@pkg_filename))
    #puts "Package Name: #{Yum.pkg_name(@@pkg_filename)}"
    #puts "Query Added: #{Yum.query_added(@@pkg_filename)}"
    #puts "Query Activated: #{Yum.query_activated(@@pkg_filename)}"
    #puts "Query Committed: #{Yum.query_committed(@@pkg_filename)}"
    #puts "Query Inactive: #{Yum.query_inactive(@@pkg_filename)}"
    #puts "Query Removed: #{Yum.query_removed(@@pkg_filename)}"
  end
end
