require 'test_helper'
require 'ostruct'

require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'
require 'smart_proxy_dns_powerdns/dns_powerdns_configuration_validator'

class DnsPowerdnsConfigurationValidatorTest < Test::Unit::TestCase
  def setup
    @config_validator = Proxy::Dns::Powerdns::ConfigurationValidator.new
  end

  def test_initialize_missing_backend
    settings = OpenStruct.new(:dns_provider => 'powerdns', :powerdns_backend => nil)

    assert_raise Proxy::Error::ConfigurationError do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_invalid_backend
    settings = OpenStruct.new(:dns_provider => 'powerdns', :powerdns_backend => 'invalid')

    assert_raise Proxy::Error::ConfigurationError do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_dummy_with_settings
    settings = OpenStruct.new(:dns_provider => 'powerdns', :powerdns_backend => 'dummy')

    assert_nothing_raised do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_mysql_without_settings
    settings = OpenStruct.new(:dns_provider => 'powerdns', :powerdns_backend => 'mysql')

    assert_raise Proxy::Error::ConfigurationError do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_mysql_with_settings
    settings = OpenStruct.new(
      :dns_provider => 'powerdns',
      :powerdns_backend => 'mysql',
      :powerdns_mysql_hostname => 'localhost',
      :powerdns_mysql_username => 'username',
      :powerdns_mysql_password => 'password',
      :powerdns_mysql_database => 'powerdns'
    )

    assert_nothing_raised do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_postgresql_without_settings
    settings = OpenStruct.new(:dns_provider => 'powerdns', :powerdns_backend => 'postgresql')

    assert_raise Proxy::Error::ConfigurationError do
      @config_validator.validate_settings!(settings)
    end
  end

  def test_initialize_postgresql_with_settings
    settings = OpenStruct.new(
      :dns_provider => 'powerdns',
      :powerdns_backend => 'postgresql',
      :powerdns_postgresql_connection => 'dbname=powerdns'
    )

    assert_nothing_raised do
      @config_validator.validate_settings!(settings)
    end
  end
end
