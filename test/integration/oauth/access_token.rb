require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class AccessTokenTest < Test::Unit::TestCase
  include TestHelpers::AuthorizeAssertions
  include TestHelpers::Fixtures
  include TestHelpers::Integration

  def setup
    Storage.instance(true).flushdb

    setup_oauth_provider_fixtures

    @application = Application.save(:service_id => @service.id,
                                    :id         => next_id,
                                    :state      => :active,
                                    :plan_id    => @plan_id,
                                    :plan_name  => @plan_name)
  end

  test 'create and read oauth_access_token' do
    post "/services/#{@service.id}/oauth_access_tokens.xml", :provider_key => @provider_key,
                                                             :app_id => @application.id,
                                                             :token => 'VALID-TOKEN'
    assert_equal 200, last_response.status

    get "/services/#{@service.id}/applications/#{@application.id}/oauth_access_tokens.xml",
        :provider_key => @provider_key

    assert_equal 200, last_response.status

    xml  = Nokogiri::XML(last_response.body)
    node = xml.at('oauth_access_tokens/oauth_access_token')

    assert_equal 1, node.count
    assert_equal 'VALID-TOKEN', node.content
    assert_equal '-1', node.attribute('ttl').value
  end

  test 'create and read oauth_access_token with ttl' do
    post "/services/#{@service.id}/oauth_access_tokens.xml", :provider_key => @provider_key,
                                                             :app_id => @application.id,
                                                             :token => 'VALID-TOKEN',
                                                             :ttl => 10
    assert_equal 200, last_response.status

    get "/services/#{@service.id}/applications/#{@application.id}/oauth_access_tokens.xml",
        :provider_key => @provider_key

    assert_equal 200, last_response.status

    xml  = Nokogiri::XML(last_response.body)
    node = xml.at('oauth_access_tokens/oauth_access_token')

    assert_equal 1, node.count
    assert_equal 'VALID-TOKEN', node.content
    assert node.attribute('ttl').value.to_i >= 1, "ttl should be greater than 1, might not be 2 because of delay"
  
  
  test 'create and read oauth_access_token with malformed ttl' do
    
    [-666, nil, '', 'adbc'].each |item|
      post "/services/#{@service.id}/oauth_access_tokens.xml", :provider_key => @provider_key,
                                                               :app_id => @application.id,
                                                               :token => 'VALID-TOKEN',
                                                               :ttl => item
                                                                                                                       
      assert_equal 403, last_response.status

      get "/services/#{@service.id}/applications/#{@application.id}/oauth_access_tokens.xml",
          :provider_key => @provider_key

      assert_equal 200, last_response.status

      xml  = Nokogiri::XML(last_response.body)
      node = xml.at('oauth_access_tokens/oauth_access_token')

      assert_equal 0, node.count
    
    end
    
  end
  
  test 'malformed request to create and read oauth_access_token' do
    
    ['', nil, [], {}, 'foo bar'].each do |item| 
      post "/services/#{@service.id}/oauth_access_tokens.xml", :provider_key => @provider_key,
                                                               :app_id => @application.id,
                                                               :token => item
                                                                                                                       
      assert_equal 403, last_response.status

      get "/services/#{@service.id}/applications/#{@application.id}/oauth_access_tokens.xml",
          :provider_key => @provider_key

      assert_equal 200, last_response.status

      xml  = Nokogiri::XML(last_response.body)
      node = xml.at('oauth_access_tokens/oauth_access_token')

      assert_equal 0, node.count    
    end
  end
  
  test 'test create and delete' do 
    
    
  end
  
  # test create token and delete it
  # test create token and delete it twice, should raise error on the second one
  # test create token with ttl, wait for it to expire, and then delete it (should raise error)
  # test create token with ttl, check that it's on the list of token, wait for it to expire, check that the list is empty, finally delete it (should raise error)
  # test create 10000 tokens for the single service and get the list of all the tokens. Check that it does not take less than 1 second.
  
  # test create token with service_id, app_id_1, then create the same token, same service_id and different app_id. 
  # It should raise an error that the token is already assigned elsewhere.
  
  # test the same as above with a ttl. Wait for the first app_id->token to expire and assign the same token, it should not raise an error because the token is already
  # taken.
  
  
  
  
  

  
  # TODO: TTL
  # TODO: multiservice

end

