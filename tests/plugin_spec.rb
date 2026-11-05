# frozen_string_literal: true

# This plugin's tests, run with `trmnlp test` (add `--report report` for a page of every screen it drew).
# Docs: https://github.com/usetrmnl/trmnlp#testing-plugins
RSpec.describe 'Advent Calendar' do
  # Canned answers for the requests the plugin makes, its polling urls and its transform's own, e.g.
  #   { 'https://api.example.com/*' => { json: { temperature: 21 } } }
  let(:mocks) { {} }

  # The values of the custom fields in src/settings.yml to test with.
  let(:custom_fields) { {} }

  # Every view on TRMNL's devices, a failing API and every select option, checked for page errors and leaked values.
  it_behaves_like 'a publishable recipe'

  describe 'date logic' do
    # Renders the full view at `now` for a user in `zone` and reads back the debug line.
    def date_state(now, zone: 'Etc/UTC')
      html = trmnl.render(now:, variables: { trmnl: { user: { time_zone_iana: zone } } }).html
      html[/state=[^<]*/].strip
    end

    {
      '2026-11-30T12:00:00Z' => 'state=offseason door= christmas= advent=1',
      '2026-12-01T12:00:00Z' => 'state=advent door=1 christmas=24 advent=',
      '2026-12-24T12:00:00Z' => 'state=advent door=24 christmas=1 advent=',
      '2026-12-25T12:00:00Z' => 'state=christmas door=25 christmas=0 advent=',
      '2026-12-26T12:00:00Z' => 'state=offseason door= christmas= advent=340',
      '2026-12-31T12:00:00Z' => 'state=offseason door= christmas= advent=335',
      '2027-01-01T12:00:00Z' => 'state=offseason door= christmas= advent=334',
      '2028-02-29T12:00:00Z' => 'state=offseason door= christmas= advent=276'
    }.each do |now, expected|
      it "is #{expected} at #{now}" do
        expect(date_state(now)).to eq(expected)
      end
    end

    it "uses the user's time zone, not UTC" do
      # 04:30 UTC on Dec 1 is still 23:30 on Nov 30 in New York
      expect(date_state('2026-12-01T04:30:00Z', zone: 'America/New_York'))
        .to eq('state=offseason door= christmas= advent=1')
      # 15:30 UTC on Dec 24 is already 00:30 on Christmas in Tokyo
      expect(date_state('2026-12-24T15:30:00Z', zone: 'Asia/Tokyo'))
        .to eq('state=christmas door=25 christmas=0 advent=')
    end
  end
end
