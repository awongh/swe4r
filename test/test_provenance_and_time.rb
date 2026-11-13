# frozen_string_literal: true

require 'test/unit'
require 'swe4r'

class Swe4rProvenanceAndTimeTest < Test::Unit::TestCase
  J2000 = 2_451_545.0
  FLAGS = Swe4r::SEFLG_MOSEPH | Swe4r::SEFLG_SPEED
  SECOND_TOLERANCE = 0.001

  def setup
    Swe4r.swe_set_ephe_path('path')
  end

  def assert_calendar_time(expected, actual)
    assert_equal(expected[0, 5], actual[0, 5])
    assert_in_delta(expected[5], actual[5], SECOND_TOLERANCE)
  end

  def test_native_version_is_available
    assert_match(/\A\d+\.\d+\.\d+\z/, Swe4r.swe_version)
  end

  def test_metadata_preserves_legacy_values_and_reports_effective_flags
    result = Swe4r.swe_calc_ut_with_metadata(J2000, Swe4r::SE_SUN, FLAGS)

    assert_equal(%i[effective_flags values warning], result.keys.sort)
    assert_equal(Swe4r.swe_calc_ut(J2000, Swe4r::SE_SUN, FLAGS), result[:values])
    assert_equal(6, result[:values].length)
    assert_equal(FLAGS, result[:effective_flags])
    assert_nil(result[:warning])
  end

  def test_metadata_reports_flags_added_by_the_native_library
    requested = FLAGS | Swe4r::SEFLG_TRUEPOS
    result = Swe4r.swe_calc_ut_with_metadata(J2000, Swe4r::SE_SUN, requested)

    assert_not_equal(requested, result[:effective_flags])
    assert_equal(requested, result[:effective_flags] & requested)
    assert_equal(Swe4r::SEFLG_NOABERR, result[:effective_flags] & Swe4r::SEFLG_NOABERR)
    assert_equal(Swe4r::SEFLG_NOGDEFL, result[:effective_flags] & Swe4r::SEFLG_NOGDEFL)
  end

  def test_metadata_keeps_native_error_behavior
    error = assert_raise(RuntimeError) do
      Swe4r.swe_calc_ut_with_metadata(J2000, -999, FLAGS)
    end
    assert_match(/illegal planet number/, error.message)
  end

  def test_utc_conversion_has_the_known_tt_offset_at_j2000
    tt, ut1 = Swe4r.swe_utc_to_jd(2000, 1, 1, 12, 0, 0.0)

    # At this date TAI - UTC = 32 seconds, and TT - TAI = 32.184 seconds.
    assert_in_delta(J2000 + (64.184 / 86_400), tt, 1e-9)
    assert_in_delta(J2000, ut1, 1.0 / 86_400)
    assert_not_equal(J2000, ut1, 'Calendar-to-JD alone does not convert UTC to UT1')
  end

  def test_tt_and_ut1_round_trips_preserve_fractional_seconds
    original = [2000, 1, 1, 12, 34, 56.125]
    tt, ut1 = Swe4r.swe_utc_to_jd(*original)

    assert_calendar_time(original, Swe4r.swe_jdet_to_utc(tt))
    assert_calendar_time(original, Swe4r.swe_jdut1_to_utc(ut1))
  end

  def test_leap_second_and_following_midnight
    original = [2016, 12, 31, 23, 59, 60.25]
    tt, ut1 = Swe4r.swe_utc_to_jd(*original)
    next_tt, = Swe4r.swe_utc_to_jd(2017, 1, 1, 0, 0, 0.0)

    assert_in_delta(0.75, (next_tt - tt) * 86_400, SECOND_TOLERANCE)
    assert_calendar_time(original, Swe4r.swe_jdet_to_utc(tt))
    assert_calendar_time(original, Swe4r.swe_jdut1_to_utc(ut1))
  end

  def test_before_1972_input_is_interpreted_as_ut1
    original = [1880, 1, 1, 11, 50, 39.125]
    tt, ut1 = Swe4r.swe_utc_to_jd(*original)
    expected = Swe4r.swe_julday(1880, 1, 1, 11 + (50 / 60.0) + (39.125 / 3600.0))

    assert_in_delta(expected, ut1, 1e-9)
    assert_calendar_time(original, Swe4r.swe_jdet_to_utc(tt))
    assert_calendar_time(original, Swe4r.swe_jdut1_to_utc(ut1))
  end

  def test_gregorian_default_and_explicit_julian_calendar
    gregorian = [2000, 1, 14, 12, 34, 56.125]
    julian = [2000, 1, 1, 12, 34, 56.125]
    result = Swe4r.swe_utc_to_jd(*gregorian)

    assert_equal(result, Swe4r.swe_utc_to_jd(*gregorian, Swe4r::SE_GREG_CAL))
    assert_equal(result, Swe4r.swe_utc_to_jd(*julian, Swe4r::SE_JUL_CAL))
    assert_calendar_time(julian, Swe4r.swe_jdet_to_utc(result[0], Swe4r::SE_JUL_CAL))
    assert_calendar_time(julian, Swe4r.swe_jdut1_to_utc(result[1], Swe4r::SE_JUL_CAL))
  end

  def test_historical_and_future_dates_follow_native_ut1_policy
    [700, 3000].each do |year|
      original = [year, 6, 15, 12, 34, 56.125]
      tt, ut1 = Swe4r.swe_utc_to_jd(*original)
      expected = Swe4r.swe_julday(year, 6, 15, 12 + (34 / 60.0) + (56.125 / 3600.0))

      assert_in_delta(expected, ut1, 1e-9)
      assert_calendar_time(original, Swe4r.swe_jdet_to_utc(tt))
      assert_calendar_time(original, Swe4r.swe_jdut1_to_utc(ut1))
    end
  end

  def test_julian_leap_day_and_negative_year
    [[1500, 2, 29, 12, 0, 0.25], [-100, 1, 1, 12, 0, 0.25]].each do |original|
      tt, ut1 = Swe4r.swe_utc_to_jd(*original, Swe4r::SE_JUL_CAL)

      assert_calendar_time(original, Swe4r.swe_jdet_to_utc(tt, Swe4r::SE_JUL_CAL))
      assert_calendar_time(original, Swe4r.swe_jdut1_to_utc(ut1, Swe4r::SE_JUL_CAL))
    end
    assert_raise(RuntimeError) { Swe4r.swe_utc_to_jd(1500, 2, 29, 12, 0, 0.25) }
  end

  def test_invalid_dates_times_and_leap_seconds_raise_native_errors
    [[2000, 2, 30, 12, 0, 0.0], [2000, 13, 1, 12, 0, 0.0],
     [2000, 1, 1, 24, 0, 0.0], [2000, 1, 1, 12, 60, 0.0],
     [2000, 1, 1, 12, 0, -1.0], [2000, 1, 1, 12, 0, 61.0],
     [2000, 1, 1, 23, 59, 60.0]].each do |components|
      error = assert_raise(RuntimeError) { Swe4r.swe_utc_to_jd(*components) }
      assert_match(/invalid (date|time)/, error.message)
    end
  end

  def test_nonfinite_seconds_and_julian_days_are_rejected
    [Float::NAN, Float::INFINITY, -Float::INFINITY].each do |value|
      assert_raise(ArgumentError) { Swe4r.swe_utc_to_jd(2000, 1, 1, 12, 0, value) }
      assert_raise(ArgumentError) { Swe4r.swe_jdet_to_utc(value) }
      assert_raise(ArgumentError) { Swe4r.swe_jdut1_to_utc(value) }
    end
  end

  def test_invalid_calendar_flags_are_rejected
    assert_raise(ArgumentError) { Swe4r.swe_utc_to_jd(2000, 1, 1, 12, 0, 0, 2) }
    assert_raise(ArgumentError) { Swe4r.swe_jdet_to_utc(J2000, 2) }
    assert_raise(ArgumentError) { Swe4r.swe_jdut1_to_utc(J2000, 2) }
  end

  def test_new_methods_enforce_argument_counts
    assert_raise(ArgumentError) { Swe4r.swe_version(1) }
    assert_raise(ArgumentError) { Swe4r.swe_calc_ut_with_metadata(J2000, Swe4r::SE_SUN) }
    assert_raise(ArgumentError) { Swe4r.swe_utc_to_jd(2000, 1, 1, 12, 0) }
    assert_raise(ArgumentError) { Swe4r.swe_utc_to_jd(2000, 1, 1, 12, 0, 0, 1, 2) }
    %i[swe_jdet_to_utc swe_jdut1_to_utc].each do |method_name|
      assert_raise(ArgumentError) { Swe4r.public_send(method_name) }
      assert_raise(ArgumentError) { Swe4r.public_send(method_name, J2000, 1, 2) }
    end
  end
end
