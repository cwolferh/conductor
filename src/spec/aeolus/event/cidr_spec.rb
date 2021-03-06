#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require 'event_spec_helper'

module Aeolus
  module Event
    describe Cidr do

      describe "#new" do
        it "should set default values on creation" do
          event = Cidr.new
          event.event_id.should == "020001"
        end
        it "should set all attributes passed in" do
          event = Cidr.new({:owner=>'fred', :hardware_profile => 'm1.large'})
          event.owner.should == 'fred'
          event.hardware_profile.should == 'm1.large'
        end
        it "should set class default overrides" do
          event = Cidr.new
          event.event_id.should =='020001'
        end
      end
      describe "#attributes" do
        it "should return the Cidr attributes plus the 2 defined in the Base class as a single level array" do
          event = Cidr.new
          event.attributes.include?(:event_id).should be_true
          event.attributes.include?(:owner).should be_true
          event.attributes.include?(:hardware_profile).should be_true
        end
      end
      describe "#changed_fields" do
        it "should return a list if changes present" do
          event = Cidr.new({:owner=>'sseago',:old_values=>{:owner=>'jayg'}})
          result = event.changed_fields
          result.should == [:owner]
        end
      end
    end
  end
end
