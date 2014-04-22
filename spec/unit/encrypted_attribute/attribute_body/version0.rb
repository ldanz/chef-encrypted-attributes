#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
# License:: Apache License, Version 2.0
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
#

require 'spec_helper'

describe Chef::EncryptedAttribute::AttributeBody::Version0 do
  before do
    @AttributeBodyVersion = Chef::EncryptedAttribute::AttributeBody::Version
    @AttributeBodyVersion0 = Chef::EncryptedAttribute::AttributeBody::Version0
  end

  context '#new' do

    it 'should create an AttributeBody::Version0 object without errors' do
      lambda { @AttributeBodyVersion0.new }.should_not raise_error
    end

    it 'should set the CHEF_TYPE key' do
      o = @AttributeBodyVersion0.new
      o[@AttributeBodyVersion::CHEF_TYPE].should eql(@AttributeBodyVersion::CHEF_TYPE_VALUE)
    end

    it 'should set the JSON_CLASS key' do
      o = @AttributeBodyVersion0.new
      o[@AttributeBodyVersion::JSON_CLASS].should eql(@AttributeBodyVersion0.to_s)
    end

  end # context #new

  context '#encrypt and #can_be_decrypted_by?' do

    it 'should encrypt a value passing a OpenSSL::PKey::RSA key' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.can_be_decrypted_by?(key).should eql(false)
      body.encrypt('value1', key.public_key)
      body.can_be_decrypted_by?(key).should eql(true)
    end

    it 'should encrypt a value passing a PEM String key' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.can_be_decrypted_by?(key).should eql(false)
      body.encrypt('value1', key.public_key.to_pem)
      body.can_be_decrypted_by?(key).should eql(true)
    end

    it 'should encrypt a value passing a OpenSSL::PKey::RSA array' do
      keys = [ OpenSSL::PKey::RSA.new(256), OpenSSL::PKey::RSA.new(256) ]
      body = @AttributeBodyVersion0.new
      body.can_be_decrypted_by?(keys).should eql(false)
      body.encrypt('value1', keys.map { |k| k.public_key })
      body.can_be_decrypted_by?(keys).should eql(true)
    end

    it 'should encrypt a value passing a Strings array' do
      keys = [ OpenSSL::PKey::RSA.new(256), OpenSSL::PKey::RSA.new(256) ]
      body = @AttributeBodyVersion0.new
      body.can_be_decrypted_by?(keys).should eql(false)
      body.encrypt('value1', keys.map { |k| k.public_key.to_pem })
      body.can_be_decrypted_by?(keys).should eql(true)
    end

    it 'should throw an InvalidPrivateKey error if the key is invalid' do
      body = @AttributeBodyVersion0.new
      lambda { body.encrypt('value1', 'invalid-key') }.should raise_error(Chef::EncryptedAttribute::InvalidPrivateKey, /The provided key is invalid:/)
    end

    it 'should throw an InvalidPrivateKey error if the public key is missing' do
      key = OpenSSL::PKey::RSA.new(256)
      OpenSSL::PKey::RSA.any_instance.stub(:public?).and_return(false)
      body = @AttributeBodyVersion0.new
      lambda { body.encrypt('value1', key.public_key) }.should raise_error(Chef::EncryptedAttribute::InvalidPublicKey)
    end

    it 'should throw an error if there is an RSA Error' do
      key = OpenSSL::PKey::RSA.new(32) # will raise "OpenSSL::PKey::RSAError: data too large for key size" on encryption
      body = @AttributeBodyVersion0.new
      lambda { body.encrypt('value1', key) }.should raise_error(Chef::EncryptedAttribute::EncryptionFailure)
    end

  end # context #encrypt and #can_be_decrypted_by?

  context '#decrypt' do

    [
      true, false, 0, 'value1', [], {}
    ].each do |v|
      it "should decrypt an encrypted #{v}" do
        key = OpenSSL::PKey::RSA.new(256)
        body = @AttributeBodyVersion0.new
        body.encrypt(v, key.public_key)
        body.decrypt(key).should eql(v)
      end
    end

    it 'should throw an InvalidPrivateKey error if the private key is invalid' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', key.public_key)
      lambda { body.decrypt('invalid-private-key') }.should raise_error(Chef::EncryptedAttribute::InvalidPrivateKey, /The provided key is invalid:/)
    end

    it 'should throw an InvalidPrivateKey error if only the public key is provided' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', key.public_key)
      lambda { body.decrypt(key.public_key) }.should raise_error(Chef::EncryptedAttribute::InvalidPrivateKey, /The provided key for decryption is invalid, a valid public and private key is required\./)
    end

    it 'should throw a DecryptionFailure error if the private key cannot decrypt it' do
      key = OpenSSL::PKey::RSA.new(256)
      bad_key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', key.public_key)
      lambda { body.decrypt(bad_key) }.should raise_error(Chef::EncryptedAttribute::DecryptionFailure, /Attribute data cannot be decrypted by the provided key\./)
    end

    it 'should throw a DecryptionFailure error if the data is corrupted and cannot be decrypted' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', key.public_key)
      body['encrypted_data'] = Hash[body['encrypted_data'].map do |k, v|
        [ k, 'Corrupted data' ]
      end]
      lambda { body.decrypt(key) }.should raise_error(Chef::EncryptedAttribute::DecryptionFailure, /OpenSSL::PKey::RSAError/)
    end

    it 'should throw a DecryptionFailure error if the embedded JSON is corrupted' do
      key = OpenSSL::PKey::RSA.new(256)
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', key.public_key)
      body['encrypted_data'] = Hash[body['encrypted_data'].map do |k, v|
        [ k, Base64.encode64(key.public_encrypt('bad-json')) ]
      end]
      lambda { body.decrypt(key) }.should raise_error(Chef::EncryptedAttribute::DecryptionFailure, /JSON::ParserError/)
    end

  end # context #decrypt

  context '#needs_update?' do

    it 'should return false if there no new keys' do
      keys = [ OpenSSL::PKey::RSA.new(256).public_key ]
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', keys )
      body.needs_update?(keys).should be_false
    end

    it 'should return true if there are new keys' do
      keys = [ OpenSSL::PKey::RSA.new(256).public_key ]
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', keys)
      keys.push(OpenSSL::PKey::RSA.new(256).public_key)
      body.needs_update?(keys).should be_true
    end

    it 'should return true if some keys are removed' do
      keys = [ OpenSSL::PKey::RSA.new(256).public_key, OpenSSL::PKey::RSA.new(256).public_key ]
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', keys)
      body.needs_update?(keys[0]).should be_true
    end

    it 'should return false if the keys are the same, but in different order or format' do
      keys = [ OpenSSL::PKey::RSA.new(256).public_key, OpenSSL::PKey::RSA.new(256).public_key ]
      body = @AttributeBodyVersion0.new
      body.encrypt('value1', keys)
      body.needs_update?([ keys[1], keys[0].to_pem ]).should be_false
    end

  end # context #needs_update?

end # describe Chef::EncryptedAttribute::AttributeBody::Version
