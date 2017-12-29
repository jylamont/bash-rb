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

  describe :repl do
    it "should raise an error if a language is not supported" do
      expect do 
        subject.repl("ruby") { "irb" }
      end.to raise_error(NotImplementedError, "Language: ruby not implemented")

      BashRb::Session.define_repl(
        "ruby" => BashRb::Handlers::Ruby
      )

      expect { subject.repl("ruby") { "irb" } }.to_not raise_error
    end

    it "should return Terminal object" do
      BashRb::Session.define_repl(
        "ruby" => BashRb::Handlers::Ruby
      )

      expect(subject.repl("ruby") { "irb" }).to eq(subject)
    end

    context "ruby" do
      before do
        BashRb::Session.define_repl(
          "ruby" => BashRb::Handlers::Ruby
        )
      end

      after { subject.close }

      it "should execute ruby code" do
        subject.repl("ruby") { "irb" }
        expect(subject.push("1 + 1")).to eq(2)
      end
    end
  end

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
  end
end
