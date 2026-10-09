require 'spec_helper'
require 'sorcery/providers/base'
require 'sorcery/providers/qq'
require 'webmock/rspec'

describe Sorcery::Providers::Qq do
  include WebMock::API

  let(:provider) { Sorcery::Controller::Config.qq }

  before(:all) do
    sorcery_reload!([:external])
    sorcery_controller_property_set(:external_providers, [:qq])
    sorcery_controller_external_property_set(:qq, :key, 'KEY')
    sorcery_controller_external_property_set(:qq, :secret, 'SECRET')
  end

  def stub_qq_token
    stub_request(:post, 'https://graph.qq.com/oauth2.0/token').to_return(
      status: 200,
      body: 'access_token=TOKEN&expires_in=7776000&refresh_token=REFRESH',
      headers: { 'content-type' => 'text/html' }
    )
  end

  context 'connection timeouts' do
    it 'applies short default timeouts' do
      stub_qq_token

      options = provider.process_callback({ code: 'CODE' }, nil).client.connection.options

      expect(options.open_timeout).to eq 5
      expect(options.read_timeout).to eq 10
    end

    it 'allows timeouts to be configured' do
      stub_qq_token
      sorcery_controller_external_property_set(:qq, :open_timeout, 2)
      sorcery_controller_external_property_set(:qq, :read_timeout, 3)

      options = provider.process_callback({ code: 'CODE' }, nil).client.connection.options

      expect(options.open_timeout).to eq 2
      expect(options.read_timeout).to eq 3
    ensure
      sorcery_controller_external_property_set(:qq, :open_timeout, 5)
      sorcery_controller_external_property_set(:qq, :read_timeout, 10)
    end

    it 'raises a connection error when graph.qq.com is unreachable' do
      stub_request(:post, 'https://graph.qq.com/oauth2.0/token').to_timeout

      expect { provider.process_callback({ code: 'CODE' }, nil) }.to raise_error(Faraday::ConnectionFailed)
    end
  end
end
