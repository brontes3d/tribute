class NewRulesLoad4886 < ActiveRecord::Migration
  def self.up
    Rule.load_code_stub_rules
  end

  def self.down
  end
end
