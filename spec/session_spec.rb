require 'spec_helper'

RSpec.describe BashRb::Session do
  subject { BashRb::Session.new }

  describe :push do
    it "should execute a command" do
      expect(subject.push("echo 'Testing123'")).to eq(["Testing123"])
    end

    it "should not cache responses" do
      expect(subject.response).to be_empty
      expect(subject.push("echo 'Testing123'")).to eq(["Testing123"])
      expect(subject.response).to be_empty
    end
  end

  describe :close do 
    it "should close an opened terminal" do 
      expect { subject.push("echo test") }.to_not raise_error

      subject.close

      expect { subject.push("echo test") }.to raise_error("Terminal closed. You will need to create a new BashRb::Session.")
    end

    it "should gracefully handle closing a closed terminal" do 
      expect { subject.push("echo test") }.to_not raise_error

      Process.kill("TERM", subject.instance_variable_get(:@process).pid)
      Process.wait
      
      expect { subject.close }.to_not raise_error
      expect { subject.push("echo test") }.to raise_error("Terminal closed. You will need to create a new BashRb::Session.")
    end
  end

  # describe :repl do
  #   it "should raise an error if a language is not supported" do
  #     expect { subject.repl("irb", language: "ruby") }.to raise_error(NotImplementedError, "Language: ruby not implemented")

  #     BashRb::Session.define_repl(
  #       "ruby" => { handler: Allison::Services::Core::RubyHandler }
  #     )

  #     expect { subject.repl("irb", language: "ruby") }.to_not raise_error
  #   end

  #   it "should return Terminal object" do
  #     BashRb::Session.define_repl(
  #       "ruby" => { handler: Allison::Services::Core::RubyHandler }
  #     )

  #     expect(subject.repl("irb", language: "ruby")).to eq(subject)
  #   end

  #   context "ruby" do
  #     before do
  #       BashRb::Session.define_repl(
  #         "ruby" => { handler: Allison::Services::Core::RubyHandler }
  #       )
  #     end

  #     after { subject.close }

  #     it "should execute ruby code" do
  #       subject.repl("irb", language: "ruby")
  #       expect(subject.push("1 + 1")).to eq(2)
  #     end
  #   end
  # end

  describe "dynamic commands" do
    it "should pass basic commands to push" do
      expect(subject).to receive(:push).with("echo 'Testing123'")
      subject.echo("'Testing123'")
    end

    it "should pass in commands with flags" do
      expect(subject).to receive(:push).with("ls -alh")
      subject.ls("-alh")
    end

    it "should pass in commands with flags via options" do
      expect(subject).to receive(:push).with("ls -a -l -h")
      subject.ls(flags: {a: nil, l: nil, h: nil})

      expect(subject).to receive(:push).with("ssh -i ~/.ssh/x.pem a@b.com")
      subject.ssh("a@b.com", flags: {i: "~/.ssh/x.pem"})

      expect(subject).to receive(:push).with("cx ssh -s some_app console")
      subject.cx("ssh", "-s some_app console")
    end

    # describe "#define_service" do
    #   it "should allow you define a shortcut for a command" do
    #     BashRb::Session.define_service(
    #       some_app: {
    #         ssh: lambda { |term, options| term.cx("ssh -s abc machine_name") }
    #       }
    #     )
    #     expect(subject).to receive(:push).with("cx ssh -s abc machine_name")
    #     subject.ssh(service: "some_app")
    #   end

    #   it "should raise Allison::CommandNotFound when service doesn't exist" do
    #     expect { subject.ssh(service: "blah") }.to raise_error(Allison::CommandNotFound)
    #   end
    # end
  end
end
