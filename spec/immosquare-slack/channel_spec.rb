# frozen_string_literal: true

require "json"
require "webmock/rspec"

##============================================================##
## `post_message` runs against a fake Slack API stubbed at the
## HTTP level. The examples pin what Slack receives, not the
## private helpers that build it, so the internals can change
## without touching this file. WebMock also blocks any real
## network call.
##============================================================##
RSpec.describe(ImmosquareSlack::Channel) do
  let(:api) { "https://slack.com/api" }

  ##============================================================##
  ## The general channel is renamed on purpose: it must be found
  ## by its `is_general` flag, not by its name.
  ##============================================================##
  let(:channels) do
    [
      {"id" => "CGEN", "name" => "annonces", "is_general" => true,  "is_archived" => false},
      {"id" => "CDEV", "name" => "dev",      "is_general" => false, "is_archived" => false}
    ]
  end

  let(:users) do
    [
      {"id" => "UIN",  "deleted" => false, "profile" => {"email" => "in@immosquare.com"}},
      {"id" => "UOUT", "deleted" => false, "profile" => {"email" => "out@immosquare.com"}},
      {"id" => "UOLD", "deleted" => true,  "profile" => {"email" => "old@immosquare.com"}}
    ]
  end

  let(:dev_members)        { ["UIN"] }
  let(:refused_recipients) { [] }
  let(:posts)              { [] }

  def stub_slack_get(endpoint, *payloads)
    stub_request(:get, /\A#{Regexp.escape("#{api}/#{endpoint}")}/).to_return(*payloads.map {|p| {:body => {"ok" => true}.merge(p).to_json} })
  end

  def posted_to
    posts.map {|p| p["channel"] }
  end

  before do
    ImmosquareSlack.configuration                     = ImmosquareSlack::Configuration.new
    ImmosquareSlack.configuration.slack_api_token_bot = "xoxb-test"

    ##============================================================##
    ## The channel list is memoized for the lifetime of the
    ## process: without this reset, an example would see the list
    ## fetched by the previous one.
    ##============================================================##
    described_class.instance_variable_set(:@list_channels, nil)

    stub_slack_get("conversations.list", {"channels" => channels})
    stub_slack_get("users.list", {"members" => users})
    stub_slack_get("conversations.members", {"members" => dev_members})

    stub_request(:post, "#{api}/chat.postMessage").to_return do |request|
      body = JSON.parse(request.body)
      posts << body
      response = refused_recipients.include?(body["channel"]) ? {"ok" => false, "error" => "user_disabled"} : {"ok" => true}
      {:body => response.to_json}
    end
  end

  describe(".post_message") do
    context("when the channel exists") do
      it("mentions the members and sends a DM only to those outside the channel") do
        described_class.post_message("Deploy done", :channel_name => "dev", :notify => ["in@immosquare.com", "out@immosquare.com"])

        expect(posted_to).to(eq(["CDEV", "UOUT"]))
        expect(posts.first["text"]).to(include("<@UIN>", "<@UOUT>", "Deploy done"))
        expect(posts.last["text"]).to(include("Deploy done"))
      end

      it("neither mentions nor messages a deactivated account") do
        described_class.post_message("Deploy done", :channel_name => "dev", :notify => ["old@immosquare.com"])

        expect(posted_to).to(eq(["CDEV"]))
        expect(posts.first["text"]).not_to(include("UOLD"))
      end

      it("sends no DM when direct_message_unreachable_mentions is disabled") do
        ImmosquareSlack.configuration.direct_message_unreachable_mentions = false

        described_class.post_message("Deploy done", :channel_name => "dev", :notify => ["out@immosquare.com"])

        expect(posted_to).to(eq(["CDEV"]))
      end

      it("succeeds without posting twice when Slack refuses a DM") do
        refused_recipients << "UOUT"

        expect { described_class.post_message("Deploy done", :channel_name => "dev", :notify => ["out@immosquare.com"]) }.not_to(raise_error)
        expect(posted_to.count("CDEV")).to(eq(1))
      end

      it("finds a channel created after the channel list was memoized") do
        stub_slack_get("conversations.list", {"channels" => channels.reject {|c| c["id"] == "CDEV" }}, {"channels" => channels})

        described_class.post_message("Deploy done", :channel_name => "dev")

        expect(posted_to).to(eq(["CDEV"]))
      end
    end

    context("when the channel does not exist") do
      it("falls back to the general channel and sends a DM to every mentioned member") do
        described_class.post_message("Deploy done", :channel_name => "missing", :notify => ["in@immosquare.com", "out@immosquare.com"])

        expect(posted_to).to(contain_exactly("UIN", "UOUT", "CGEN"))
        expect(posts.find {|p| p["channel"] == "CGEN" }["text"]).to(include("<!channel>", "missing", "Deploy done"))
      end

      it("still posts to the general channel when Slack refuses a DM") do
        refused_recipients << "UIN"

        described_class.post_message("Deploy done", :channel_name => "missing", :notify => ["in@immosquare.com"])

        expect(posted_to).to(include("CGEN"))
      end

      it("raises without posting when notify_general_if_invalid_channel is false") do
        expect { described_class.post_message("Deploy done", :channel_name => "missing", :notify_general_if_invalid_channel => false) }.to(raise_error(/missing/))
        expect(posts).to(be_empty)
      end

      it("raises without posting when the general channel cannot be found either") do
        stub_slack_get("conversations.list", {"channels" => channels.reject {|c| c["is_general"] }})

        expect { described_class.post_message("Deploy done", :channel_name => "missing") }.to(raise_error(/general/))
        expect(posts).to(be_empty)
      end
    end
  end
end
