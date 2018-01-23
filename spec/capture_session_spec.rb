require 'spec_helper'

RSpec.describe BashRb::CaptureSession do
  before { BashRb::CaptureSession.reset_repl_languages }
  subject { BashRb::CaptureSession.new }

  it "should capture commands" do 
    subject.push("pwd")
    subject.push("cd $STACK_PATH")

    expect(subject.commands).to eq(["pwd", "cd $STACK_PATH"])
  end

  it "should support dynamic commands" do 
    subject.pwd
    subject.cd("$STACK_PATH")

    expect(subject.commands).to eq(["pwd", "cd $STACK_PATH"])
  end

  it "should support repl" do
    BashRb::Session.define_repl(
      ruby: BashRb::Handlers::Ruby
    )

    subject.cd("$STACK_PATH")
    subject.repl("ruby") { "bundle exec irb" }
    subject.repl("ruby") { |cmd| cmd.bundle("exec rails c") }

    expect(subject.commands).to eq([
      "cd $STACK_PATH",
      "bundle exec irb",
      "bundle exec rails c"
    ])
  end
end