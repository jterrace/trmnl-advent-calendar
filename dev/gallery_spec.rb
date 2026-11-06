# frozen_string_literal: true

# See "Seeing all possible outputs" in the README.
RSpec.describe 'Gallery' do
  let(:mocks) { {} }
  let(:custom_fields) { {} }

  views = %w[full half_horizontal half_vertical quadrant]
  devices = ENV.fetch('DEVICES', 'og_png').split(',')
  # Dec 1-24, Christmas, and one off-season day
  dates = (1..25).map { |day| format('2026-12-%02d', day) } + ['2026-11-30']

  dates.each do |date|
    %i[landscape portrait].each do |orientation|
      [false, true].each do |dark_mode|
        it "#{date} · #{dark_mode ? 'dark' : 'light'} · #{orientation}" do
          devices.product(views).each do |device, view|
            trmnl.render(view:, device:, orientation:, dark_mode:, now: "#{date}T12:00:00Z")
          end
        end
      end
    end
  end
end
