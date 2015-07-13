require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  # Test that a missing :powerdns_mysql_hostname throws an error
  def test_initialize_without_settings
    assert_raise(RuntimeError) do
      klass.new(settings.delete_if { |k,v| k == :powerdns_mysql_hostname })
    end
  end

  # Test that correct initialization works
  def test_initialize_with_settings
    assert_nothing_raised do
      mock_mysql

      klass.new(settings)
    end
  end

  # Test A record creation
  def test_create_a
    mock_mysql

    instance = klass.new(settings)

    instance.expects(:domain).returns({'id' => 1})
    instance.expects(:dns_find).with(1, 'test.example.com').returns(false)
    instance.expects(:create_record).with(1, 'test.example.com', 84600, '10.1.1.1', 'A').returns(true)

    assert instance.create
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    mock_mysql

    instance = klass.new(settings)

    instance.expects(:domain).returns({'id' => 1})
    instance.expects(:dns_find).with(1, 'test.example.com').returns('192.168.1.1')

    assert_raise(Proxy::Dns::Collision) { instance.create }
  end

  # Test PTR record creation
  def test_create_ptr
    mock_mysql

    instance = klass.new(settings.merge(:type => 'PTR'))

    instance.expects(:domain).returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:dns_find).with(1, '1.1.1.10.in-addr.arpa').returns(false)
    instance.expects(:create_record).with(1, '1.1.1.10.in-addr.arpa', 84600, 'test.example.com', 'PTR').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.create
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    mock_mysql

    instance = klass.new(settings.merge(:type => 'PTR'))

    instance.expects(:domain).returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    instance.expects(:dns_find).with(1, '1.1.1.10.in-addr.arpa').returns('test2.example.com')

    assert_raise(Proxy::Dns::Collision) { instance.create }
  end

  # Test A record removal
  def test_remove_a
    mock_mysql

    instance = klass.new(settings)

    instance.expects(:domain).returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.remove
  end

  # Test PTR record removal
  def test_remove_ptr
    mock_mysql

    instance = klass.new(settings.merge(:type => 'PTR'))

    instance.expects(:domain).returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    instance.expects(:delete_record).with(1, '1.1.1.10.in-addr.arpa', 'PTR').returns(true)
    instance.expects(:rectify_zone).with('1.1.10.in-addr.arpa').returns(true)

    assert instance.remove
  end

  def mock_mysql
    Mysql2::Client.expects(:new).with(:host => 'localhost', :username => 'username', :password => 'password', :database => 'powerdns').returns(false)
  end

  private

  def klass
    Proxy::Dns::Powerdns::Record
  end

  def settings
    {
      :powerdns_mysql_hostname => 'localhost',
      :powerdns_mysql_username => 'username',
      :powerdns_mysql_password => 'password',
      :powerdns_mysql_database => 'powerdns',
      :fqdn => 'test.example.com',
      :value => '10.1.1.1',
      :type => 'A',
      :ttl => 84600,
    }
  end
end
