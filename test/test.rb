require 'test/unit'
require 'json'
require 'swe4r'

class Swe4rTest < Test::Unit::TestCase
  
  def test_swe_set_ephe_path
    assert_equal(nil, Swe4r::swe_set_ephe_path('path'))
  end
  
  def test_swe_julday
    assert_equal(2444838.972916667, Swe4r::swe_julday(1981, 8, 22, 11.35))
  end

  def test_swe_revjul
    assert_equal( [1981, 8, 22, 11.350000005215406], Swe4r::swe_revjul(2444838.972916667) )
  end
  
  def test_swe_set_topo
    assert_equal(nil, Swe4r::swe_set_topo(-112.183333, 45.45, 1524))
  end 
  
  def test_swe_set_sid_mode
    assert_equal(nil, Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)) # Use Lahiri mode
    assert_equal(nil, Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_USER, 2415020.5, 22.460489112721632)) # Use user defined mode
  end
  
  def test_swe_get_ayanamsa_ut
    
    # Test using default sidereal mode
    Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_FAGAN_BRADLEY, 0, 0)
    assert_equal(24.483840294903757, Swe4r::swe_get_ayanamsa_ut(2444838.972916667))
    
    # Test using Lahari sidereal mode
    Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)
    assert_equal(23.600632656944185, Swe4r::swe_get_ayanamsa_ut(2444838.972916667))
    
    # Test using user defined sidereal mode
    Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_USER, 2415020.5, 22.460489112721632)
    assert_equal(23.600591306635067, Swe4r::swe_get_ayanamsa_ut(2444838.972916667))
    
  end
  
  def test_swe_get_ayanamsa_ex_ut
    Swe4r::swe_set_sid_mode(Swe4r::SE_SIDM_LAHIRI, 0, 0)
    assert_equal(23.59667507149339, Swe4r::swe_get_ayanamsa_ex_ut(2444838.972916667, Swe4r::SEFLG_MOSEPH))
  end

  def test_swe_calc_ut
    
    # The Moshier Ephemeris will be used for all tests since it does not require ephemeris files
    
    # Test #1...
    # Body: Sun
    # Flags: Moshier Ephemeris
    body = Swe4r::swe_calc_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH)
    assert_equal(149.26566155075085, body[0])
    assert_equal(-0.00012095608841323021, body[1])
    assert_equal(1.0112944920684557, body[2])
    assert_equal(0.0, body[3])
    assert_equal(0.0, body[4])
    assert_equal(0.0, body[5])
    
    # Test #2...
    # Body: Sun
    # Flags: Moshier Ephemeris, High Precision Speed
    body = Swe4r::swe_calc_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH|Swe4r::SEFLG_SPEED)
    assert_equal(149.26566155075085, body[0])
    assert_equal(-0.0001209560884116579, body[1])
    assert_equal(1.0112944920684555, body[2])
    assert_equal(0.9636052090727139, body[3])
    assert_equal(1.3573058519899091e-05, body[4])
    assert_equal(-0.0002028500183236368, body[5])
    
     # Test #3...
     # Body: Sun
     # Flags: Moshier Ephemeris, High Precision Speed, True Positions
     body = Swe4r::swe_calc_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH|Swe4r::SEFLG_TRUEPOS|Swe4r::SEFLG_SPEED)
     assert_equal(149.27128949344328, body[0])
     assert_equal(-0.00012086030263409888, body[1])
     assert_equal(1.0112944920684555, body[2])
     assert_equal(0.9636063426569487, body[3])
     assert_equal(1.3573775684911814e-05, body[4])
     assert_equal(-0.00020285001901355993, body[5])
     
     # Test #4...
     # Body: Sun
     # Flags: Moshier Ephemeris, High Precision Speed, True Positions, Topocentric
     Swe4r::swe_set_topo(-112.183333, 45.45, 1524)
     body = Swe4r::swe_calc_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH|Swe4r::SEFLG_TRUEPOS|Swe4r::SEFLG_SPEED|Swe4r::SEFLG_TOPOCTR)
     assert_equal(149.27327994957028, body[0])
     assert_equal(-0.0013677823223172442, body[1])
     assert_equal(1.0113041763512773, body[2])
     assert_equal(0.9683657793763634, body[3])
     assert_equal(0.0037440250636134086, body[4])
     assert_equal(-0.0003579187534546972, body[5])
    
     # Test #5...
     # Body: Sun
     # Flags: Moshier Ephemeris, High Precision Speed, True Positions, Topocentric, Sidereal (Lahiri Mode)
     Swe4r::swe_set_topo(-112.183333, 45.45, 1524)
     Swe4r::swe_set_sid_mode(1, 0, 0)
     body = Swe4r::swe_calc_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH|Swe4r::SEFLG_TRUEPOS|Swe4r::SEFLG_SPEED|Swe4r::SEFLG_TOPOCTR|Swe4r::SEFLG_SIDEREAL)
     assert_equal(125.67660487807687, body[0])
     assert_equal(-0.0013677823223169163, body[1])
     assert_equal(1.0113041763512773, body[2])
     assert_equal(0.9683250913810203, body[3])
     assert_equal(0.0037468508076796666, body[4])
     assert_equal(-0.0003579187527254481, body[5])
    
  end
  
  def test_swe_houses
    
    # Test each house system
    systems = ['P','K','O','R','C','A','E','V','X','H','T','B'] # 'G'
    systems.each do |s|
      Swe4r::swe_houses(2444838.972916667, 45.45, -112.183333, s)
      # puts s
    end
    
    # Test using Placidus house system
    assert_equal(
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
    Swe4r::swe_houses(2444838.972916667, 45.45, -112.183333, 'P'))
  end
  
  def test_swe_rise_trans
    sunrise = Swe4r::swe_rise_trans(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH, Swe4r::SE_CALC_RISE | Swe4r::SE_BIT_HINDU_RISING, 45.45, -112.183333, 0, 0, 0)
    assert_equal 2444839.210048978, sunrise
  end

  def test_swe_rise_trans_true_hor
    sunrise = Swe4r::swe_rise_trans_true_hor(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH, Swe4r::SE_CALC_RISE | Swe4r::SE_BIT_HINDU_RISING, 45.45, -112.183333, 0, 0, 0, 1)
    assert_equal 2444839.2188771414, sunrise
  end

  def test_swe_azalt
    lat =   61.2163129
    lon = -149.894852
    longitude, latitude, distance = 149.271, -0.00012, 1.0113

    # longitude, latitude, distance
    azimuth, altitude, app_altitude = Swe4r::swe_azalt(2444838.972916667, Swe4r::SE_ECL2HOR, lon, lat, 0,0,0, longitude, latitude, distance)
    assert_equal 199.96260368887175, azimuth
    assert_equal( -15.418741801398292, altitude )
    assert_equal( -15.418741801398292, app_altitude )
  end

  def test_swe_cotrans
    a,b,c = Swe4r::swe_cotrans( 90, 99, -8, 1)
    assert_equal 221.9365465392914, a
    assert_equal( -77.98034646731611, b )
    assert_equal 1.0, c
  end

  def test_swe_pheno_ut
    result = Swe4r::swe_pheno_ut(2444838.972916667, Swe4r::SE_SUN, Swe4r::SEFLG_MOSEPH)

    assert_equal(
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
        0.0],result)
  end

  # swe_sol_eclipse_when_loc(tjd...) finds the next eclipse for a given geographic position;
  def test_swe_sol_eclipse_when_loc
    res = Swe4r::swe_sol_eclipse_when_loc(2444838.972916667, 45.45, -112.183333, 0 , Swe4r::SEFLG_MOSEPH)

    expect_max_ecl_time = 2444640.3728770674
    max_ecl_time =  res[1][1]
    assert_equal(expect_max_ecl_time, max_ecl_time)

    eclipse_type = res[0]
    type_results = []

    type_results << "SE_ECL_TOTAL" if (eclipse_type & Swe4r::SE_ECL_TOTAL) == Swe4r::SE_ECL_TOTAL
    type_results << "SE_ECL_CENTRAL" if (eclipse_type & Swe4r::SE_ECL_CENTRAL) == Swe4r::SE_ECL_CENTRAL
    type_results << "SE_ECL_NONCENTRAL" if (eclipse_type & Swe4r::SE_ECL_NONCENTRAL) == Swe4r::SE_ECL_NONCENTRAL
    type_results << "SE_ECL_ANNULAR" if (eclipse_type & Swe4r::SE_ECL_ANNULAR) == Swe4r::SE_ECL_ANNULAR
    type_results << "SE_ECL_PARTIAL" if (eclipse_type & Swe4r::SE_ECL_PARTIAL) == Swe4r::SE_ECL_PARTIAL
    type_results << "SE_ECL_ANNULAR_TOTAL" if (eclipse_type & Swe4r::SE_ECL_ANNULAR_TOTAL) == Swe4r::SE_ECL_ANNULAR_TOTAL
    type_results << "SE_ECL_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_VISIBLE) == Swe4r::SE_ECL_VISIBLE
    type_results << "SE_ECL_MAX_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_MAX_VISIBLE) == Swe4r::SE_ECL_MAX_VISIBLE
    type_results << "SE_ECL_1ST_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_1ST_VISIBLE) == Swe4r::SE_ECL_1ST_VISIBLE
    type_results << "SE_ECL_2ND_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_2ND_VISIBLE) == Swe4r::SE_ECL_2ND_VISIBLE
    type_results << "SE_ECL_3RD_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_3RD_VISIBLE) == Swe4r::SE_ECL_3RD_VISIBLE
    type_results << "SE_ECL_4TH_VISIBLE" if (eclipse_type & Swe4r::SE_ECL_4TH_VISIBLE) == Swe4r::SE_ECL_4TH_VISIBLE

    expected_type_results = [
      "SE_ECL_PARTIAL",
      "SE_ECL_VISIBLE",
      "SE_ECL_MAX_VISIBLE",
      "SE_ECL_1ST_VISIBLE",
      "SE_ECL_4TH_VISIBLE"
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_when_glob(tjd...) finds the next eclipse globally;
  def test_swe_sol_eclipse_when_glob
    result = Swe4r::swe_sol_eclipse_when_glob(2444838.972916667, Swe4r::SEFLG_MOSEPH, Swe4r::SE_ECL_TOTAL)
    test_data = [
      5,
      [
        2444816.656780241,
        2444816.649699564,
        2444816.5496100746,
        2444816.764137677,
        2444816.5954617294,
        2444816.7181679048,
        2444816.595788629,
        2444816.717870053,
        0.0,
        0.0
      ]
    ]
    assert_equal(test_data, result)

    eclipse_type = result[0]
    type_results = []

    type_results << "SE_ECL_TOTAL" if (eclipse_type & Swe4r::SE_ECL_TOTAL) == Swe4r::SE_ECL_TOTAL
    type_results << "SE_ECL_CENTRAL" if (eclipse_type & Swe4r::SE_ECL_CENTRAL) == Swe4r::SE_ECL_CENTRAL
    type_results << "SE_ECL_NONCENTRAL" if (eclipse_type & Swe4r::SE_ECL_NONCENTRAL) == Swe4r::SE_ECL_NONCENTRAL
    type_results << "SE_ECL_ANNULAR" if (eclipse_type & Swe4r::SE_ECL_ANNULAR) == Swe4r::SE_ECL_ANNULAR
    type_results << "SE_ECL_PARTIAL" if (eclipse_type & Swe4r::SE_ECL_PARTIAL) == Swe4r::SE_ECL_PARTIAL
    type_results << "SE_ECL_ANNULAR_TOTAL" if (eclipse_type & Swe4r::SE_ECL_ANNULAR_TOTAL) == Swe4r::SE_ECL_ANNULAR_TOTAL

    expected_type_results = [
      "SE_ECL_TOTAL",
      "SE_ECL_CENTRAL"
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_where() computes the geographic location of a solar eclipse for a given tjd;
  def test_swe_sol_eclipse_where_no_ecl

    result = Swe4r::swe_sol_eclipse_where(2444838.972916667, Swe4r::SEFLG_MOSEPH)
    # no eclipse
    assert_equal(0, result[0])
  end

  def test_swe_sol_eclipse_where
    result = Swe4r::swe_sol_eclipse_where(2444816.656780241, Swe4r::SEFLG_MOSEPH)
    eclipse_type = result[0]
    type_results = []

    type_results << "SE_ECL_TOTAL" if (eclipse_type & Swe4r::SE_ECL_TOTAL) == Swe4r::SE_ECL_TOTAL
    type_results << "SE_ECL_CENTRAL" if (eclipse_type & Swe4r::SE_ECL_CENTRAL) == Swe4r::SE_ECL_CENTRAL
    type_results << "SE_ECL_NONCENTRAL" if (eclipse_type & Swe4r::SE_ECL_NONCENTRAL) == Swe4r::SE_ECL_NONCENTRAL
    type_results << "SE_ECL_ANNULAR" if (eclipse_type & Swe4r::SE_ECL_ANNULAR) == Swe4r::SE_ECL_ANNULAR
    type_results << "SE_ECL_PARTIAL" if (eclipse_type & Swe4r::SE_ECL_PARTIAL) == Swe4r::SE_ECL_PARTIAL

    expected_type_results = [
      "SE_ECL_TOTAL",
      "SE_ECL_CENTRAL"
    ]

    assert_equal(expected_type_results, type_results)
  end

  # swe_sol_eclipse_how() computes attributes of a solar eclipse for a given tjd, geographic longitude, latitude and height.
  def test_swe_sol_eclipse_how

    Swe4r::swe_sol_eclipse_how(2444838.972916667, 45.45, -112.183333, 0 , Swe4r::SEFLG_MOSEPH)
  end

  # Lunar eclipses:

  # swe_lun_eclipse_when_loc(tjd...) finds the next lunar eclipse for a given geographic position;
  def test_swe_lun_eclipse_when_loc
    result = Swe4r::swe_lun_eclipse_when_loc(2444838.972916667, 45.45, -112.183333, 0 , Swe4r::SEFLG_MOSEPH)
    test_data = [
      [
        2444802.699216498,
        0.0,
        2444802.642522555,
        2444802.7559142746,
        0.0,
        0.0,
        2444802.5881501106,
        2444802.8101914083,
        0.0,
        0.0
      ],
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
    assert_equal(test_data, result)
  end

  # swe_lun_eclipse_when(tjd...) finds the next lunar eclipse;
  def test_swe_lun_eclipse_when
    result = Swe4r::swe_lun_eclipse_when(2444838.972916667, Swe4r::SEFLG_MOSEPH, Swe4r::SE_ECL_TOTAL)
    test_data = [
      2444122.954302467,
      0.0,
      2444122.887636504,
      2444123.0209684223,
      2444122.9388237395,
      2444122.969784548,
      2444122.8483262495,
      2444123.060291385,
      0.0,
      0.0
    ]
    assert_equal(test_data, result)
  end

  # swe_lun_eclipse_how() computes the attributes of a lunar eclipse for a given tjd.
  def test_swe_lun_eclipse_how
    result = Swe4r::swe_lun_eclipse_how(2444838.972916667, 45.45, -112.183333, 0 , Swe4r::SEFLG_MOSEPH)
    test_data = [
      0.0,
      -103.94980007744492,
      0.0,
      0.0,
      47.80877365920145,
      -1.380322934446492,
      -1.380322934446492,
      0.0,
      0.0,
      -99999999.0,
      -99999999.0,
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
    assert_equal(test_data, result)
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

