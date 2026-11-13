# frozen_string_literal: true

require 'test/unit'
require 'swe4r'
require 'json'
require 'tempfile'
require 'rbconfig'

class Swe4rRegressionTest < Test::Unit::TestCase
  J2000 = 2_451_545.0
  TOTAL_ECLIPSE = 2_457_987.267726
  FLAGS = Swe4r::SEFLG_MOSEPH
  EXTENSION_PATH = $LOADED_FEATURES.find { |path| path.end_with?("/swe4r.#{RbConfig::CONFIG.fetch('DLEXT')}") }
  EXTENSION_LOAD_PATH = File.dirname(EXTENSION_PATH, 2)

  # Crashes and calls that hold the GVL must fail a test without taking down
  # the runner or preventing its timeout from firing. Also inherits ASan.
  def isolated_result(code)
    command = [RbConfig.ruby, '-I', EXTENSION_LOAD_PATH, '-I', File.expand_path('../lib', __dir__),
               '-rswe4r', '-rjson', '-e', "result = begin; #{code}; end; puts JSON.generate(result)"]
    # macOS may remove DYLD_INSERT_LIBRARIES from an instrumented parent's
    # environment. Pass it explicitly when spawning each instrumented child.
    env = {}
    env[ENV.fetch('SWE4R_ASAN_PRELOAD_KEY')] = ENV.fetch('SWE4R_ASAN_RUNTIME') if ENV['SWE4R_ASAN_RUNTIME']
    Tempfile.create('swe4r-stdout') do |stdout|
      Tempfile.create('swe4r-stderr') do |stderr|
        pid = Process.spawn(env, *command, in: File::NULL, out: stdout, err: stderr)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
        status = nil
        begin
          loop do
            finished = Process.waitpid2(pid, Process::WNOHANG)
            if finished
              status = finished.last
              break
            end
            if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
              flunk('Native calculation did not finish within 10 seconds')
            end
            sleep 0.01
          end
        ensure
          unless status
            begin
              Process.kill('KILL', pid)
            rescue Errno::ESRCH
              # The process exited just as the deadline was reached.
            end
            Process.waitpid(pid)
          end
        end
        stdout.rewind
        stderr.rewind
        output = stdout.read
        errors = stderr.read
        assert_predicate(status, :success?, "Native subprocess failed:\n#{output}\n#{errors}")
        JSON.parse(output)
      end
    end
  end

  def test_solar_where_without_eclipse_is_safe_and_has_initialized_attributes
    result = isolated_result("Swe4r.swe_sol_eclipse_where(#{J2000}, #{FLAGS})")
    assert_equal(0, result[0])
    assert_equal(2, result[1].length)
    assert_equal(20, result[2].length)
    assert_equal(0.0, result[2][2])
    assert_equal(Array.new(9, 0.0), result[2][11..])
  end

  def test_calculation_metadata_exposes_ephemeris_fallback_and_warning
    result = isolated_result(<<~RUBY)
      require 'tmpdir'
      Dir.mktmpdir('swe4r-empty-ephe-') do |directory|
        ENV['SE_EPHE_PATH'] = directory
        Swe4r.swe_set_ephe_path(directory)
        Swe4r.swe_calc_ut_with_metadata(#{J2000}, Swe4r::SE_SUN, Swe4r::SEFLG_SWIEPH | Swe4r::SEFLG_SPEED)
      end
    RUBY

    effective_flags = result.fetch('effective_flags')
    assert_equal(Swe4r::SEFLG_MOSEPH, effective_flags & Swe4r::SEFLG_MOSEPH)
    assert_equal(0, effective_flags & Swe4r::SEFLG_SWIEPH)
    assert_equal(Swe4r::SEFLG_SPEED, effective_flags & Swe4r::SEFLG_SPEED)
    assert_equal(6, result.fetch('values').length)
    assert_match(/using Moshier eph/, result.fetch('warning'))
  end

  def test_solar_where_during_eclipse_keeps_two_coordinate_api
    result = isolated_result("Swe4r.swe_sol_eclipse_where(#{TOTAL_ECLIPSE}, #{FLAGS})")
    assert_not_equal(0, result[0] & Swe4r::SE_ECL_TOTAL)
    assert_equal(2, result[1].length)
    assert_in_delta(-87.664666, result[1][0], 0.001)
    assert_in_delta(36.974371, result[1][1], 0.001)
    assert_equal(Array.new(9, 0.0), result[2][11..])
  end

  def test_gauquelin_houses_return_all_36_sectors
    %w[G g].each do |system|
      cusps, angles = isolated_result("Swe4r.swe_houses(#{J2000}, 45.0, 10.0, '#{system}')")
      assert_equal(37, cusps.length)
      assert_equal(10, angles.length)
      assert_equal(0.0, cusps[0])
      assert(cusps[1..].all? { |value| value.finite? && value >= 0 && value < 360 })
      assert_in_delta(180.0, (cusps[19] - cusps[1]) % 360, 1e-8)
    end
  end

  def test_extended_gauquelin_houses_return_all_cusps_and_speeds
    cusps, angles, speeds, angle_speeds = isolated_result(
      "Swe4r.swe_houses_ex2(#{J2000}, 0, 45.0, 10.0, 'G'.ord)"
    )
    assert_equal([37, 10, 37, 10], [cusps.length, angles.length, speeds.length, angle_speeds.length])
    later = isolated_result("Swe4r.swe_houses(#{J2000 + 0.00001}, 45.0, 10.0, 'G')")[0]
    [1, 13, 24, 36].each do |index|
      motion = (((later[index] - cusps[index] + 180) % 360) - 180) / 0.00001
      # Native analytic sector speeds approximate the numerical derivative.
      assert_in_delta(motion, speeds[index], motion.abs * 0.01, "Sector #{index} speed")
    end
  end

  def test_normal_houses_keep_13_cusps
    assert_equal([13, 10], Swe4r.swe_houses(J2000, 45.0, 10.0, 'P').map(&:length))
    assert_equal([13, 10, 13, 10], Swe4r.swe_houses_ex2(J2000, 0, 45.0, 10.0, 'P').map(&:length))
  end

  def test_failed_house_calculation_has_a_deterministic_error
    %w[P K].each do |system|
      error = isolated_result(<<~RUBY)
        begin
          Swe4r.swe_houses(#{J2000}, 80.0, 10.0, '#{system}')
          nil
        rescue RuntimeError => e
          e.message
        end
      RUBY
      assert_equal("House calculation failed for system #{system}", error)
    end
  end

  def test_star_rising_does_not_modify_mutable_or_frozen_input
    %i[swe_rise_trans swe_rise_trans_true_hor].each do |method|
      %w[spica ,GP1958].each do |name|
        [false, true].each do |frozen|
          result = isolated_result(<<~RUBY)
            name = #{name.inspect}.dup
            name.freeze if #{frozen}
            args = [#{J2000}, name, #{FLAGS}, Swe4r::SE_CALC_RISE, 10.0, 45.0, 0, 0, 10]
            args << 1 if :#{method} == :swe_rise_trans_true_hor
            time = Swe4r.#{method}(*args)
            [time, name, name.frozen?]
          RUBY
          assert_operator(result[0], :>, J2000)
          assert_equal(name, result[1])
          assert_equal(frozen, result[2])
        end
      end
    end
  end

  def test_star_names_are_bounded_and_nul_free
    %i[swe_rise_trans swe_rise_trans_true_hor].each do |method|
      ['s' * 257, "spica\0ignored"].each do |name|
        args = [J2000, name, FLAGS, Swe4r::SE_CALC_RISE, 10.0, 45.0, 0, 0, 10]
        args << 1 if method == :swe_rise_trans_true_hor
        assert_raise(ArgumentError) { Swe4r.public_send(method, *args) }
      end
    end
  end

  def test_crossing_wrappers_return_the_next_crossing
    { swe_solcross_ut: Swe4r::SE_SUN, swe_mooncross_ut: Swe4r::SE_MOON }.each do |method, body|
      [J2000.to_i, J2000].each do |start|
        date = Swe4r.public_send(method, 10.0, start, FLAGS)
        assert_operator(date, :>, start)
        assert_in_delta(10.0, Swe4r.swe_calc_ut(date, body, FLAGS)[0], 1e-6)
      end
      et_method = method.to_s.delete_suffix('_ut')
      ut = Swe4r.public_send(method, 10.0, J2000, FLAGS)
      et = Swe4r.public_send(et_method, 10.0, J2000, FLAGS)
      assert_in_delta(ut, et, 0.002, 'ET and UT crossings differ only by Delta T')
      assert_operator(et, :>, ut)
    end
  end

  def test_crossing_wrappers_propagate_native_failures
    %i[swe_solcross swe_solcross_ut swe_mooncross swe_mooncross_ut].each do |method|
      error = assert_raise(RuntimeError) { Swe4r.public_send(method, 10.0, 10_000_000.0, FLAGS) }
      assert_not_empty(error.message)
    end
  end

  def test_heliocentric_solar_crossings_follow_earth_instead_of_hanging
    [0.0, 10.0, 180.0].each do |target|
      ut, et, longitude = isolated_result(<<~RUBY)
        flags = #{FLAGS} | Swe4r::SEFLG_HELCTR
        ut = Swe4r.swe_solcross_ut(#{target}, #{J2000}, flags)
        et = Swe4r.swe_solcross(#{target}, #{J2000}, flags)
        [ut, et, Swe4r.swe_calc_ut(ut, Swe4r::SE_EARTH, flags)[0]]
      RUBY
      assert_operator(ut, :>, J2000)
      assert_operator(et, :>, ut)
      assert_in_delta(ut, et, 0.002)
      assert_in_delta(0.0, ((longitude - target + 180) % 360) - 180, 1e-6)
    end
  end

  def test_unused_occultation_coordinates_and_attributes_are_zero
    [J2000, TOTAL_ECLIPSE].each do |date|
      result = isolated_result("Swe4r.swe_lun_occult_where(#{date}, Swe4r::SE_SUN, #{FLAGS})")
      assert_equal(10, result[1].length)
      assert_equal(Array.new(8, 0.0), result[1][2..])
      assert_equal(Array.new(9, 0.0), result[2][11..])
    end
  end

  def test_solar_local_search_and_observation_have_initialized_attribute_tails
    expressions = [
      "Swe4r.swe_sol_eclipse_how(#{TOTAL_ECLIPSE}, -87.664666, 36.974371, 0, #{FLAGS})",
      "Swe4r.swe_sol_eclipse_when_loc(2457966.5, -106.3, 42.85, 0, #{FLAGS}, false)"
    ]
    expressions.each do |expression|
      result = isolated_result(expression)
      assert_equal(20, result.last.length)
      assert_equal(Array.new(9, 0.0), result.last[11..])
    end
  end

  def test_calendar_round_trip_preserves_signed_years
    [Swe4r::SE_GREG_CAL, Swe4r::SE_JUL_CAL].each do |calendar|
      [-4712, -100, -1, 0, 1, 2000].each do |year|
        jd = Swe4r.swe_julday(year, 3, 1, 12.0, calendar)
        assert_equal([year, 3, 1, 12.0], Swe4r.swe_revjul(jd, calendar))
      end
    end
  end

  def test_failed_koch_house_position_raises_instead_of_returning_zero
    error = assert_raise(RuntimeError) { Swe4r.swe_house_pos(270.0, 80.0, 23.44, 'K'.ord, 0.0, 0.0) }
    assert_match(/Koch house position failed/, error.message)
    assert_in_delta(1.0, Swe4r.swe_house_pos(0.0, 0.0, 23.44, 'N'.ord, 0.0, 0.0), 1e-8)
  end

  def test_total_eclipse_obscuration_is_exactly_one
    result = isolated_result("Swe4r.swe_sol_eclipse_how(#{TOTAL_ECLIPSE}, -87.664666, 36.974371, 0, #{FLAGS})")
    assert_not_equal(0, result[0] & Swe4r::SE_ECL_TOTAL)
    assert_operator(result[1][1], :>, 1.0, 'Diameter ratio may exceed one')
    assert_equal(1.0, result[1][2], 'Covered fraction must be exactly one')
  end

  def test_no_eclipse_has_zero_obscuration
    result = isolated_result("Swe4r.swe_lun_occult_where(#{J2000}, Swe4r::SE_SUN, #{FLAGS})")
    assert_equal(0, result[0])
    assert_equal(0.0, result[2][2])
  end

  def test_annular_and_partial_eclipse_obscuration
    # Locate the 2023 Oct 14 annular eclipse using the independent search path.
    result = isolated_result(<<~RUBY)
      date = Swe4r.swe_sol_eclipse_when_glob(2460220.5, #{FLAGS}, Swe4r::SE_ECL_ANNULAR, false)[1][0]
      Swe4r.swe_sol_eclipse_where(date, #{FLAGS})
    RUBY
    assert_not_equal(0, result[0] & Swe4r::SE_ECL_ANNULAR)
    assert_in_delta(result[2][1]**2, result[2][2], 1e-8)
    assert_operator(result[2][2], :<, 1.0)

    partial = isolated_result("Swe4r.swe_sol_eclipse_how(#{TOTAL_ECLIPSE}, -106.3, 42.85, 0, #{FLAGS})")
    assert_not_equal(0, partial[0] & Swe4r::SE_ECL_PARTIAL)
    assert_operator(partial[1][2], :>, 0.0)
    assert_operator(partial[1][2], :<, 1.0)
  end
end
