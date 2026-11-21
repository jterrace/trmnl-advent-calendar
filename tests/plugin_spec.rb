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
      html = trmnl.render(now:, custom_fields:, variables: { trmnl: { user: { time_zone_iana: zone } } }).html
      Nokogiri::HTML(html).css('.layout').text.split.join(' ')
    end

    {
      '2026-11-30T12:00:00Z' => '1 day until the Advent Calendar',
      '2026-12-01T12:00:00Z' => '1 December 24 days until Christmas Snowflake',
      '2026-12-07T12:00:00Z' => '7 December 18 days until Christmas Snowman',
      '2026-12-24T12:00:00Z' => "24 December 1 day until Christmas Santa's Sleigh",
      '2026-12-25T12:00:00Z' => '25 December Merry Christmas! Christmas Tree',
      '2026-12-26T12:00:00Z' => '340 days until the Advent Calendar',
      '2026-12-31T12:00:00Z' => '335 days until the Advent Calendar',
      '2027-01-01T12:00:00Z' => '334 days until the Advent Calendar',
      '2028-02-29T12:00:00Z' => '276 days until the Advent Calendar'
    }.each do |now, expected|
      it "shows '#{expected}' at #{now}" do
        expect(screen_text(now)).to eq(expected)
      end
    end

    it "uses the user's time zone, not UTC" do
      # 04:30 UTC on Dec 1 is still 23:30 on Nov 30 in New York
      expect(screen_text('2026-12-01T04:30:00Z', zone: 'America/New_York')).to include('1 day until the Advent Calendar')
      # 15:30 UTC on Dec 24 is already 00:30 on Christmas in Tokyo
      expect(screen_text('2026-12-24T15:30:00Z', zone: 'Asia/Tokyo')).to include('Merry Christmas!')
    end

    it 'uses UTC when there is no time zone, as on the public demo page' do
      expect(screen_text('2026-11-20T12:00:00Z', zone: nil)).to eq('11 days until the Advent Calendar')
    end

    context 'with a Fixed Date' do
      let(:custom_fields) { { fixed_date: '2026-12-01' } }

      it 'shows that day instead of today' do
        expect(screen_text('2027-03-15T12:00:00Z')).to eq('1 December 24 days until Christmas Snowflake')
      end

      it 'ignores the time zone' do
        expect(screen_text('2027-03-15T23:30:00Z', zone: 'Asia/Tokyo')).to include('Snowflake')
      end
    end

    context 'with an off-season Fixed Date' do
      let(:custom_fields) { { fixed_date: '2026-11-30' } }

      it 'counts down from that day' do
        expect(screen_text('2027-03-15T12:00:00Z')).to eq('1 day until the Advent Calendar')
      end
    end
  end
end
