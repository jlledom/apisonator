require File.dirname(__FILE__) + '/../../test_helper'

module Validators
  class ReferrerTest < Test::Unit::TestCase
    include TestHelpers::Sequences
    include Validators

    def setup
      Storage.instance(true).flushdb

      service_id     = next_id
      application_id = next_id

      @application = Application.save(:service_id => service_id,
                                      :id         => application_id,
                                      :state => :active)

      @status = Transactor::Status.new(@application, {})
    end

    test 'succeeds if no access rule is defined and no referrer is passed' do
      assert Referrer.apply(@status, {})
    end
  
    test 'succeeds if no access rule is defined and blank referrer is passed' do
      assert Referrer.apply(@status, :referrer => '')
    end
    
    test 'succeeds if simple domain access rule is defined and matching referrer is passed' do
      @application.create_referrer_filter('example.org')
      assert Referrer.apply(@status, :referrer => 'example.org')
    end

    test 'fails if access rule is defined but no referrer is passed' do
      @application.create_referrer_filter('example.org')

      assert !Referrer.apply(@status, {})

      assert_equal 'referrer_not_allowed', @status.rejection_reason_code
      assert_equal 'referrer is missing',  @status.rejection_reason_text
    end

    test 'fails if non-matching referrer is passed' do
      @application.create_referrer_filter('foo.example.org')
      
      assert !Referrer.apply(@status, :referrer => 'bar.example.org')

      assert_equal 'referrer_not_allowed',                      @status.rejection_reason_code
      assert_equal 'referrer "bar.example.org" is not allowed', @status.rejection_reason_text
    end
  end
end