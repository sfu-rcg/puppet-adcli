require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'adcli' do

  let(:title) { 'adcli' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { { :ipaddress => '10.42.42.42' } }

  describe 'Test adcli installation' do
    it { should contain_package('adcli').with_ensure('present') }
    it { should contain_service('adcli').with_ensure('running') }
    it { should contain_service('adcli').with_enable('true') }
    it { should contain_file('adcli.conf').with_ensure('present') }
  end

  describe 'Test installation of a specific version' do
    let(:params) { {:version => '1.0.42' } }
    it { should contain_package('adcli').with_ensure('1.0.42') }
  end

  describe 'Test decommissioning - absent' do
    let(:params) { {:absent => true} }
    it 'should remove Package[adcli]' do should contain_package('adcli').with_ensure('absent') end
    it 'should stop Service[adcli]' do should contain_service('adcli').with_ensure('stopped') end
    it 'should not enable at boot Service[adcli]' do should contain_service('adcli').with_enable('false') end
    it 'should remove adcli configuration file' do should contain_file('adcli.conf').with_ensure('absent') end
  end

  describe 'Test decommissioning - disable' do
    let(:params) { {:disable => true} }
    it { should contain_package('adcli').with_ensure('present') }
    it 'should stop Service[adcli]' do should contain_service('adcli').with_ensure('stopped') end
    it 'should not enable at boot Service[adcli]' do should contain_service('adcli').with_enable('false') end
    it { should contain_file('adcli.conf').with_ensure('present') }
  end

  describe 'Test decommissioning - disableboot' do
    let(:params) { {:disableboot => true} }
    it { should contain_package('adcli').with_ensure('present') }
    it { should_not contain_service('adcli').with_ensure('present') }
    it { should_not contain_service('adcli').with_ensure('absent') }
    it 'should not enable at boot Service[adcli]' do should contain_service('adcli').with_enable('false') end
    it { should contain_file('adcli.conf').with_ensure('present') }
  end

  describe 'Test noops mode' do
    let(:params) { {:noops => true} }
    it { should contain_package('adcli').with_noop('true') }
    it { should contain_service('adcli').with_noop('true') }
    it { should contain_file('adcli.conf').with_noop('true') }
  end

  describe 'Test customizations - template' do
    let(:params) { {:template => "adcli/spec.erb" , :options => { 'opt_a' => 'value_a' } } }
    it 'should generate a valid template' do
      content = catalogue.resource('file', 'adcli.conf').send(:parameters)[:content]
      content.should match "fqdn: rspec.example42.com"
    end
    it 'should generate a template that uses custom options' do
      content = catalogue.resource('file', 'adcli.conf').send(:parameters)[:content]
      content.should match "value_a"
    end
  end

  describe 'Test customizations - source' do
    let(:params) { {:source => "puppet:///modules/adcli/spec"} }
    it { should contain_file('adcli.conf').with_source('puppet:///modules/adcli/spec') }
  end

  describe 'Test customizations - source_dir' do
    let(:params) { {:source_dir => "puppet:///modules/adcli/dir/spec" , :source_dir_purge => true } }
    it { should contain_file('adcli.dir').with_source('puppet:///modules/adcli/dir/spec') }
    it { should contain_file('adcli.dir').with_purge('true') }
    it { should contain_file('adcli.dir').with_force('true') }
  end

  describe 'Test customizations - custom class' do
    let(:params) { {:my_class => "adcli::spec" } }
    it { should contain_file('adcli.conf').with_content(/rspec.example42.com/) }
  end

  describe 'Test service autorestart' do
    let(:params) { {:service_autorestart => false } }
    it 'should not automatically restart the service, when service_autorestart => false' do
      content = catalogue.resource('file', 'adcli.conf').send(:parameters)[:notify]
      content.should be_nil
    end
  end

end
