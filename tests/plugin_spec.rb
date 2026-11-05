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
    # Renders the full view at `now` for a user in `zone` and reads back its visible text.
    def screen_text(now, zone: 'Etc/UTC')
      html = trmnl.render(now:, variables: { trmnl: { user: { time_zone_iana: zone } } }).html
      Nokogiri::HTML(html).css('.layout').text.split.join(' ')
    end

    {
      '2026-12-01T12:00:00Z' => 'Snowflake 1 December 24 days until Christmas Snowflake',
      '2026-12-07T12:00:00Z' => 'Snowman 7 December 18 days until Christmas Snowman',
      '2026-12-24T12:00:00Z' => "Santa's Sleigh 24 December 1 day until Christmas Santa's Sleigh"
    }.each do |now, expected|
      it "shows '#{expected}' at #{now}" do
        expect(screen_text(now)).to eq(expected)
      end
    end

    it "uses the user's time zone, not UTC" do
      # 04:30 UTC on Dec 2 is still 23:30 on Dec 1 in New York
      expect(screen_text('2026-12-02T04:30:00Z', zone: 'America/New_York')).to include('24 days until Christmas')
      # 15:30 UTC on Dec 6 is already 00:30 on Dec 7 in Tokyo
      expect(screen_text('2026-12-06T15:30:00Z', zone: 'Asia/Tokyo')).to include('18 days until Christmas')
    end

    # Restore as each screen gets built: Nov 30 => 1 day until advent, Dec 25 => Christmas,
    # Dec 26 => 340, Dec 31 => 335, Jan 1 => 334, Feb 29 2028 => 276.
    it 'shows the Christmas and off-season screens' do
      skip 'Christmas and off-season screens are not built yet'
    end
  end
end
