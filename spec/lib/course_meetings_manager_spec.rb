require 'rails_helper'

describe CourseMeetingsManager do
  # starts with a comma to mimic real data. will fix data later
  let(:day_ex) { ",20151013,20151201,20151203,20151208,20151209,
                  20151210,20151215,20151217,20151222,
                  20151224,20151229,20151231,20160105" }
  let(:t_start) { Date.new(2015, 8, 28) } # Friday
  let(:t_end)   { Date.new(2016, 1, 13) } # Wednesday
  let!(:course) do
    create(:course,
           timeline_start: t_start,
           timeline_end: t_end,
           day_exceptions: day_ex,
           weekdays: '0010100'
          )
  end

  let(:expected) do
    ["()", # August 23 - 29, 2015
     "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", # August 30 - October 10
     "(Thu)", # October 11 - 17
     "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", # October 18 - November 28
     "()", # November 29 - December 5
     "(Wed)", # December 6 - 12, including exception not on a Tues/Thurs
     "()", "()", "()", # December 13 - January 2
     "(Thu)", # January 3 - 9
     "(Tue)"] # January 10 - 16
  end

  describe '#week_meetings' do
    subject { described_class.new(course).week_meetings }
    context 'course with timeline start and end' do
      it 'returns an array of day meetings for each week, factoring in blackout dates' do
        expect(subject).to eq(expected)
      end
    end

    context 'course has no timeline start or end' do
      let(:t_start) { nil }
      let(:t_end)   { nil }
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#day_meetings' do
    subject { described_class.new(course).send(:day_meetings) }
    it 'returns an array of symbols reprensenting the course meeting days' do
      expect(subject).to eq([:tuesday, :thursday])
    end
  end

  describe '#calculate_timeline_week_count' do
    subject { described_class.new(course).send(:calculate_timeline_week_count) }
    context 'course has start and end dates' do
      it 'returns an integer representing the weeks in the timeline, irrespective of blackouts' do
        expect(subject).to eq(21)
      end
    end

    context 'course has no timeline start or end' do
      let(:t_start) { nil }
      let(:t_end)   { nil }
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#all_potential_meetings' do
    let(:expected) do
      [ Date.new(2015, 8, 25),
        Date.new(2015, 8, 27),
        Date.new(2015, 9, 01) ]
    end
    subject { described_class.new(course).send(:all_potential_meetings) }
    it 'returns an array of all days the course would have met, irrespective of blackouts' do
      expect(subject.first(3)).to eq(expected)
    end
  end

  describe '#open_weeks' do
    subject { described_class.new(course).open_weeks }
    # an array with 12 elements
    let(:weeks) { %w(foo foo foo foo foo foo foo foo foo foo foo foo) }
    before { allow_any_instance_of(Course).to receive(:weeks).and_return(weeks) }
    context 'course has timeline start/end' do
      it 'returns an int representing the weeks the timeline can accomodate' do
        # There are 16 weeks with meetings, so 4 open weeks.
        expect(subject).to eq(4)
      end
    end

    context 'course has no timeline start or end' do
      let(:t_start) { nil }
      let(:t_end)   { nil }
      it 'returns zero' do
        expect(subject).to be_zero
      end
    end
  end

  describe '#week_is_blackout?' do
    let(:t_start) { Date.new(2015, 8, 25) }
    let(:t_end)   { t_start + 3.weeks }
    let!(:course) do
      create(:course,
             timeline_start: t_start,
             timeline_end: t_end,
             day_exceptions: day_ex,
             weekdays: '0010100'
            )
    end
    let(:order) { 1 }
    let!(:week) { create(:week, course_id: course.id, order: order) }
    subject { described_class.new(course).send(:week_is_blackout?, week) }
    describe 'first week - class meets both days' do
      let(:day_ex) { nil }
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
    describe 'Thursday of first week is exception' do
      let(:day_ex) { '20150827' }
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
    describe 'both days of first week are exceptions' do
      let(:day_ex) { ',20150825,20150827' }
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end
end
