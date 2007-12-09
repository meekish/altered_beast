require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  define_models

  it 'creates user' do
    lambda do
      user = create_user
      violated "#{user.errors.full_messages.to_sentence}" if user.new_record?
    end.should change(User, :count).by(1)
  end

  [:login, :password, :password_confirmation, :email, :site_id].each do |attr|
    it "requires #{attr}" do
      lambda do
        u = create_user attr => nil
        u.errors.on(attr).should_not be_nil
      end.should_not change(User, :count)
    end
  end

  it 'resets password' do
    users(:default).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    User.authenticate(users(:default).login, 'new password').should == users(:default)
  end

  it 'does not rehash password' do
    users(:default).update_attributes(:login => users(:default).login.reverse)
    User.authenticate(users(:default).login, 'test').should == users(:default)
  end

  it 'authenticates user' do
    User.authenticate(users(:default).login, 'test').should == users(:default)
  end

  it 'sets remember token' do
    users(:default).remember_me
    users(:default).remember_token.should_not be_nil
    users(:default).remember_token_expires_at.should_not be_nil
  end

  it 'unsets remember token' do
    users(:default).remember_me
    users(:default).remember_token.should_not be_nil
    users(:default).forget_me
    users(:default).remember_token.should be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    users(:default).remember_me_for 1.week
    after = 1.week.from_now.utc
    users(:default).remember_token.should_not be_nil
    users(:default).remember_token_expires_at.should_not be_nil
    users(:default).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    users(:default).remember_me_until time
    users(:default).remember_token.should_not be_nil
    users(:default).remember_token_expires_at.should_not be_nil
    users(:default).remember_token_expires_at.should == time
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    users(:default).remember_me
    after = 2.weeks.from_now.utc
    users(:default).remember_token.should_not be_nil
    users(:default).remember_token_expires_at.should_not be_nil
    users(:default).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'suspends user' do
    users(:default).suspend!
    users(:default).should be_suspended
  end

  it 'does not authenticate suspended user' do
    users(:default).suspend!
    User.authenticate('quentin', 'test').should_not == users(:default)
  end

  it 'unsuspends user' do
    users(:suspended).unsuspend!
    users(:suspended).should be_active
  end

  it 'deletes user' do
    users(:default).deleted_at.should be_nil
    users(:default).delete!
    users(:default).deleted_at.should_not be_nil
    users(:default).should be_deleted
  end

protected
  def create_user(options = {})
    returning User.new({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options)) do |u|
      u.site_id = options.key?(:site_id) ? options[:site_id] : 1
      u.save
    end
  end
end

describe User, "with no created users" do
  define_models :copy => false do
    model User
  end
  
  it 'creates initial user as an admin' do
    user = User.new :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire'
    user.site_id = 1
    user.save!
    user.should be_admin
  end
end