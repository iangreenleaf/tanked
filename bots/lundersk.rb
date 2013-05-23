class MyBot < RTanque::Bot::Brain
  NAME = 'Lunderskillah'
  include RTanque::Bot::BrainHelper

  def tick!
    command.speed = 1
    command.heading = sensors.heading + MAX_BOT_ROTATION
    command.turret_heading = sensors.turret_heading - MAX_TURRET_ROTATION
    command.fire MIN_FIRE_POWER
  end
end