class CowardBot < RTanque::Bot::Brain
  NAME = 'the cowardly robot'
  include RTanque::Bot::BrainHelper

  TICKS_TO_SCAN = (2 * Math::PI / MAX_RADAR_ROTATION).floor

  def initialize(*args)
    super *args
    @enemies = {}
    @path = RTanque::Heading.new
    # Scan right away
    full_scan
  end

  def tick!
    recon
    at_tick_interval(10) do
      run_away
    end
    at_tick_interval(3 * TICKS_TO_SCAN) { full_scan }
    move
    fire
  end

  private
  def recon
    sensors.radar.each do |enemy|
      @enemies[enemy.name] = get_coords sensors.position, enemy.heading, enemy.distance
      @seen_recently << enemy.name
    end

    if @radar_ticks > 0
      command.radar_heading = sensors.radar_heading + MAX_RADAR_ROTATION
      @radar_ticks -= 1
      clean_old_targets if @radar_ticks == 0
    elsif acquire_target
      command.radar_heading = acquire_target
    end
  end

  def move
    command.speed = MAX_BOT_SPEED
    command.heading = @path
  end

  def fire
    if acquire_target
      command.turret_heading = acquire_target
      command.fire MAX_FIRE_POWER
    end
  end

  def run_away
    unless @enemies.empty?
      @path = RTanque::Heading.new_between_points(sensors.position, most_remote_point)
    end
  end

  def acquire_target
    if @target_lock
      target = sensors.radar.find { |reflection| reflection.name == @target_lock }
      return target.heading if target
    end

    unless @enemies.empty?
      @target_lock, target = @enemies.min_by do |name,e|
        sensors.position.distance e
      end
      if target
        return RTanque::Heading.new_between_points(sensors.position, target)
      end
    end

    nil
  end

  def clean_old_targets
    @enemies.keys.each do |name|
      @enemies.delete name unless @seen_recently.include? name
    end
  end

  def get_coords loc, heading, distance
    # Trigofuckingnometry
    sign_x, sign_y = [1, 1]
    angle = heading - RTanque::Heading.new(0)
    delta_x = Math.sin(heading.radians) * distance
    delta_y = Math.cos(heading.radians) * distance
    RTanque::Point.new loc.x + sign_x * delta_x, loc.y + sign_y * delta_y
  end

  def most_remote_point
    # Brute force this shit
    granularity = 20
    best_d = 0
    best_p = nil
    (0..@arena.width/granularity).each do |x|
      (0..@arena.height/granularity).each do |y|
        p = RTanque::Point.new x*granularity, y*granularity
        d = @enemies.map do |_,e|
          p.distance e
        end.min
        if best_d < d
          best_d = d
          best_p = p
        end
      end
    end
    best_p
  end

  def full_scan
    @radar_ticks = TICKS_TO_SCAN
    @seen_recently = Set.new
  end
end