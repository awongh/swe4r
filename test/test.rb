# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'swe4r'

class Swe4rTest < Test::Unit::TestCase
  DELTA = 1e-8

  def assert_array_in_delta(expected, actual, delta = DELTA)
    assert_equal(expected.size, actual.size, 'Array size mismatch')
    expected.each_with_index do |exp, i|
      if exp.is_a?(Array)
        assert_array_in_delta(exp, actual[i], delta)
      elsif exp.is_a?(Float)
        assert_in_delta(exp, actual[i], delta, "Index #{i}")
      else
        assert_equal(exp, actual[i], "Index #{i}")
      end
    end
  end

  def test_swe_set_ephe_path
    assert_equal(nil, Swe4r.swe_set_ephe_path('path'))
  end

  def test_swe_julday
    assert_in_delta(2_444_838.972916667, Swe4r.swe_julday(1981, 8, 22, 11.35), DELTA)
  end

  def test_swe_revjul
    assert_array_in_delta([1981, 8, 22, 11.350000005215406], Swe4r.swe_revjul(2_444_838.972916667))
  end

  def test_swe_set_topo
    assert_equal(nil, Swe4r.swe_set_topo(-112.183333, 45.45, 1524))
  end

  def test_swe_set_sid_mode
    assert_equal(nil, Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)) # Use Lahiri mode
    # Use user defined mode
    assert_equal(nil, Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_USER, 2_415_020.5, 22.460489112721632))
  end

  def test_swe_get_ayanamsa_ut
    # Test using default sidereal mode
    Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_FAGAN_BRADLEY, 0, 0)
    assert_in_delta(24.483840294903757, Swe4r.swe_get_ayanamsa_ut(2_444_838.972916667), DELTA)

    # Test using Lahari sidereal mode
    Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)
    assert_in_delta(23.600632656944185, Swe4r.swe_get_ayanamsa_ut(2_444_838.972916667), DELTA)

    # Test using user defined sidereal mode
    Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_USER, 2_415_020.5, 22.460489112721632)
    assert_in_delta(23.600591306635067, Swe4r.swe_get_ayanamsa_ut(2_444_838.972916667), DELTA)
  end

  def test_swe_get_ayanamsa_ex_ut
    Swe4r.swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)
    assert_in_delta(23.59667507149339, Swe4r.swe_get_ayanamsa_ex_ut(2_444_838.972916667, Swe4r::SEFLG_MOSEPH), DELTA)
  end

  def test_swe_calc_ut
    # The Moshier Ephemeris will be used for all tests since it does not require ephemeris files

    # Test #1...
    # Body: Sun
    # Flags: Moshier Ephemeris
    body = Swe4r.swe_calc_ut(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH)
    assert_in_delta(149.26566155075085, body[0], DELTA)
    assert_in_delta(-0.00012095608841323021, body[1], DELTA)
    assert_in_delta(1.0112944920684557, body[2], DELTA)
    assert_in_delta(0.0, body[3], DELTA)
    assert_in_delta(0.0, body[4], DELTA)
    assert_in_delta(0.0, body[5], DELTA)

    # Test #2...
    # Body: Sun
    # Flags: Moshier Ephemeris, High Precision Speed
    body = Swe4r.swe_calc_ut(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH | Swe4r::SEFLG_SPEED)
    assert_in_delta(149.26566155075085, body[0], DELTA)
    assert_in_delta(-0.0001209560884116579, body[1], DELTA)
    assert_in_delta(1.0112944920684555, body[2], DELTA)
    assert_in_delta(0.9636052090727139, body[3], DELTA)
    assert_in_delta(1.3573058519899091e-05, body[4], DELTA)
    assert_in_delta(-0.0002028500183236368, body[5], DELTA)

    # Test #3...
    # Body: Sun
    # Flags: Moshier Ephemeris, High Precision Speed, True Positions
    body = Swe4r.swe_calc_ut(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH | Swe4r::SEFLG_TRUEPOS | Swe4r::SEFLG_SPEED)
    assert_in_delta(149.27128949344328, body[0], DELTA)
    assert_in_delta(-0.00012086030263409888, body[1], DELTA)
    assert_in_delta(1.0112944920684555, body[2], DELTA)
    assert_in_delta(0.9636063426569487, body[3], DELTA)
    assert_in_delta(1.3573775684911814e-05, body[4], DELTA)
    assert_in_delta(-0.00020285001901355993, body[5], DELTA)

    # Test #4...
    # Body: Sun
    # Flags: Moshier Ephemeris, High Precision Speed, True Positions, Topocentric
    Swe4r.swe_set_topo(-112.183333, 45.45, 1524)
    body = Swe4r.swe_calc_ut(2_444_838.972916667, Swe4r::SE_SUN,
                             Swe4r::SEFLG_MOSEPH | Swe4r::SEFLG_TRUEPOS | Swe4r::SEFLG_SPEED | Swe4r::SEFLG_TOPOCTR)
    assert_in_delta(149.27327994957028, body[0], DELTA)
    assert_in_delta(-0.0013677823223172442, body[1], DELTA)
    assert_in_delta(1.0113041763512773, body[2], DELTA)
    assert_in_delta(0.9683657793763634, body[3], DELTA)
    assert_in_delta(0.0037440250636134086, body[4], DELTA)
    assert_in_delta(-0.0003579187534546972, body[5], DELTA)

    # Test #5...
    # Body: Sun
    # Flags: Moshier Ephemeris, High Precision Speed, True Positions, Topocentric, Sidereal (Lahiri Mode)
    Swe4r.swe_set_topo(-112.183333, 45.45, 1524)
    Swe4r.swe_set_sid_mode(1, 0, 0)
    body = Swe4r.swe_calc_ut(2_444_838.972916667, Swe4r::SE_SUN,
                             Swe4r::SEFLG_MOSEPH | Swe4r::SEFLG_TRUEPOS | Swe4r::SEFLG_SPEED | Swe4r::SEFLG_TOPOCTR | Swe4r::SEFLG_SIDEREAL)
    assert_in_delta(125.67660487807687, body[0], DELTA)
    assert_in_delta(-0.0013677823223169163, body[1], DELTA)
    assert_in_delta(1.0113041763512773, body[2], DELTA)
    assert_in_delta(0.9683250913810203, body[3], DELTA)
    assert_in_delta(0.0037468508076796666, body[4], DELTA)
    assert_in_delta(-0.0003579187527254481, body[5], DELTA)
  end

  def test_swe_houses
    # Test each house system
    systems = %w[P K O R C A E V X H T B] # 'G'
    systems.each do |s|
      Swe4r.swe_houses(2_444_838.972916667, 45.45, -112.183333, s)
      # puts s
    end

    # Test using Placidus house system
    assert_array_in_delta(
      [[0.0,
        133.95429950225963,
        153.80292074191388,
        178.80796487675514,
        210.87358004433614,
        248.4391877068773,
        284.26552526926207,
        313.95429950225963,
        333.8029207419139,
        358.80796487675514,
        30.873580044336133,
        68.43918770687732,
        104.26552526926204],
       [133.95429950225963,
        30.873580044336133,
        28.745753308674352,
        273.2404152103502,
        116.71405283378715,
        92.42567887228608,
        133.52799512863683,
        272.4256788722861,
        0.0,
        0.0]],
      Swe4r.swe_houses(2_444_838.972916667, 45.45, -112.183333, 'P')
    )
  end

  def test_swe_rise_trans
    sunrise = Swe4r.swe_rise_trans(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH,
                                   Swe4r::SE_CALC_RISE | Swe4r::SE_BIT_HINDU_RISING, 45.45, -112.183333, 0, 0, 0)
    assert_in_delta 2_444_839.210048978, sunrise, DELTA
  end

  def test_swe_rise_trans_true_hor
    sunrise = Swe4r.swe_rise_trans_true_hor(
      2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH,
      Swe4r::SE_CALC_RISE | Swe4r::SE_BIT_HINDU_RISING, 45.45, -112.183333, 0, 0, 0, 1
    )
    assert_in_delta 2_444_839.2188771414, sunrise, DELTA
  end

  def test_swe_azalt
    lat = 61.2163129
    lon = -149.894852
    longitude = 149.271
    latitude = -0.00012
    distance = 1.0113

    # longitude, latitude, distance
    azimuth, altitude, app_altitude = Swe4r.swe_azalt(2_444_838.972916667, Swe4r::SE_ECL2HOR, lon, lat, 0, 0, 0,
                                                      longitude, latitude, distance)
    assert_in_delta 199.96260368887175, azimuth, DELTA
    assert_in_delta(-15.418741801398292, altitude, DELTA)
    assert_in_delta(-15.418741801398292, app_altitude, DELTA)
  end

  def test_swe_cotrans
    a, b, c = Swe4r.swe_cotrans(90, 99, -8, 1)
    assert_in_delta 221.9365465392914, a, DELTA
    assert_in_delta(-77.98034646731611, b, DELTA)
    assert_in_delta 1.0, c, DELTA
  end

  def test_swe_pheno_ut
    result = Swe4r.swe_pheno_ut(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH)

    assert_array_in_delta(
      [
        0.0,
        0.0,
        0.0,
        0.5271817236383283,
        -26.835611616502774,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ], result
    )
  end

  # swe_sol_eclipse_when_loc(tjd...) finds the next eclipse for a given geographic position;
  def test_swe_sol_eclipse_when_loc
    res = Swe4r.swe_sol_eclipse_when_loc(2_444_838.972916667, 45.45, -112.183333, 0, Swe4r::SEFLG_MOSEPH)
    res[1][1]
    # assert_equal(expect_max_ecl_time, max_ecl_time)

    eclipse_type = res[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_CENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_CENTRAL)
    type_results << 'SE_ECL_NONCENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_NONCENTRAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)
    type_results << 'SE_ECL_ANNULAR_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR_TOTAL)
    type_results << 'SE_ECL_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_VISIBLE)
    type_results << 'SE_ECL_MAX_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_MAX_VISIBLE)
    type_results << 'SE_ECL_1ST_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_1ST_VISIBLE)
    type_results << 'SE_ECL_2ND_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_2ND_VISIBLE)
    type_results << 'SE_ECL_3RD_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_3RD_VISIBLE)
    type_results << 'SE_ECL_4TH_VISIBLE' if eclipse_type.allbits?(Swe4r::SE_ECL_4TH_VISIBLE)

    %w[
      SE_ECL_PARTIAL
      SE_ECL_VISIBLE
      SE_ECL_MAX_VISIBLE
      SE_ECL_1ST_VISIBLE
      SE_ECL_4TH_VISIBLE
    ]

    # assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_when_glob(tjd...) finds the next eclipse globally;
  def test_swe_sol_eclipse_when_glob
    result = Swe4r.swe_sol_eclipse_when_glob(2_444_838.972916667, Swe4r::SEFLG_MOSEPH, Swe4r::SE_ECL_TOTAL)
    # assert_equal(test_data, result)

    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_CENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_CENTRAL)
    type_results << 'SE_ECL_NONCENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_NONCENTRAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)
    type_results << 'SE_ECL_ANNULAR_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR_TOTAL)

    expected_type_results = %w[
      SE_ECL_TOTAL
      SE_ECL_CENTRAL
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_where() computes the geographic location of a solar eclipse for a given tjd;
  def test_swe_sol_eclipse_where_no_ecl
    result = Swe4r.swe_sol_eclipse_where(2_444_838.972916667, Swe4r::SEFLG_MOSEPH)
    # no eclipse
    assert_equal(0, result[0])
  end

  def test_swe_sol_eclipse_where
    result = Swe4r.swe_sol_eclipse_where(2_444_816.656780241, Swe4r::SEFLG_MOSEPH)
    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_CENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_CENTRAL)
    type_results << 'SE_ECL_NONCENTRAL' if eclipse_type.allbits?(Swe4r::SE_ECL_NONCENTRAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)

    expected_type_results = %w[
      SE_ECL_TOTAL
      SE_ECL_CENTRAL
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_how() computes attributes of a solar eclipse for a given tjd,
  # geographic longitude, latitude and height.
  def test_swe_sol_eclipse_how_no_ecl
    result = Swe4r.swe_sol_eclipse_how(2_444_838.972916667, 45.45, -112.183333, 0, Swe4r::SEFLG_MOSEPH)

    assert_equal(0, result[0])
  end

  def test_swe_sol_eclipse_how
    # puts JSON.pretty_generate type_results
    result = Swe4r.swe_sol_eclipse_how(2_444_816.656780241, 134.095226285374, 53.26284601844857, 0, Swe4r::SEFLG_MOSEPH)

    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_ANNULAR)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)

    expected_type_results = [
      'SE_ECL_TOTAL'
    ]

    assert_equal(expected_type_results, type_results)
  end

  # Lunar eclipses:

  def test_swe_lun_occult_when_glob
    result = Swe4r.swe_lun_occult_when_glob(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH, Swe4r::SE_ECL_TOTAL)

    assert_equal(5, result[0])
    assert_in_delta(2_445_496.689880746, result[1][1], DELTA)
  end

  def test_swe_lun_occult_where
    result = Swe4r.swe_lun_occult_where(2_444_838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH)
    assert_equal(0, result[0])
    assert_in_delta(-82.72166818322415, result[1][0], DELTA)
  end

  # swe_lun_eclipse_when_loc(tjd...) finds the next lunar eclipse for a given geographic position;
  def test_swe_lun_eclipse_when_loc
    result = Swe4r.swe_lun_eclipse_when_loc(2_444_838.972916667, 45.45, -112.183333, 0, Swe4r::SEFLG_MOSEPH)

    # assert_equal(test_data, result)

    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_PENUMBRAL)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)

    [
      'SE_ECL_PARTIAL'
    ]

    # assert_equal(expected_type_results, type_results)
  end

  # swe_lun_eclipse_when(tjd...) finds the next lunar eclipse;
  def test_swe_lun_eclipse_when
    result = Swe4r.swe_lun_eclipse_when(2_444_838.972916667, Swe4r::SEFLG_MOSEPH, Swe4r::SE_ECL_TOTAL)

    # assert_equal(test_data, result[1])
    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_PENUMBRAL)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)

    expected_type_results = [
      'SE_ECL_TOTAL'
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_lun_eclipse_how() computes the attributes of a lunar eclipse for a given tjd.
  def test_swe_lun_eclipse_how_no_ecl
    result = Swe4r.swe_lun_eclipse_how(2_444_838.972916667, 45.45, -112.183333, 0, Swe4r::SEFLG_MOSEPH)

    test_data = [
      0,
      [
        0.0,
        -103.94980007744492,
        0.0,
        0.0,
        47.80877365920145,
        -1.380322934446492,
        -1.380322934446492,
        0.0,
        0.0,
        -99_999_999.0,
        -99_999_999.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ]
    ]

    assert_array_in_delta(test_data, result)
  end

  def test_swe_lun_eclipse_how
    result = Swe4r.swe_lun_eclipse_how(2_444_802.699216498, 45.45, -112.183333, 0, Swe4r::SEFLG_MOSEPH)
    test_data = [
      16,
      [
        0.5487861737439879,
        1.5824536419454307,
        0.0,
        0.0,
        73.89769546498894,
        27.775810896814107,
        27.806572310066,
        0.6559847467475777,
        0.5487861737439879,
        119.0,
        59.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ]
    ]

    assert_array_in_delta(test_data, result)

    eclipse_type = result[0]
    type_results = []

    type_results << 'SE_ECL_TOTAL' if eclipse_type.allbits?(Swe4r::SE_ECL_TOTAL)
    type_results << 'SE_ECL_ANNULAR' if eclipse_type.allbits?(Swe4r::SE_ECL_PENUMBRAL)
    type_results << 'SE_ECL_PARTIAL' if eclipse_type.allbits?(Swe4r::SE_ECL_PARTIAL)

    expected_type_results = [
      'SE_ECL_PARTIAL'
    ]

    assert_equal(expected_type_results, type_results)
  end

  # maybe later

  # Risings, settings, and meridian transits of planets and stars:
  # swe_rise_trans();

  # swe_rise_trans_true_hor() returns rising and setting times for a local horizon with altitude != 0.
  # Occultations of planets by the moon:
  # These functions can also be used for solar eclipses. But they are slightly less efficient.
  # swe_lun_occult_when_loc(tjd...) finds the next occultation for a body and a given geographic position;
  # swe_lun_occult_when_glob(tjd...) finds the next occultation of a given body globally;
  # swe_lun_occult_where() computes the geographic location of an occultation for a given tjd.
end
