
class Overlord < RTanque::Bot::Brain
    include RTanque::Bot::BrainHelper
    NAME = 'ZERG'

    #Spins in circles
    #Returns true
    #
    #Sets the heading and speed using command so that the bot moves in a circular path
    def spin()
        speed = MAX_BOT_SPEED
        @direction = 1
        command.heading = sensors.heading + MAX_BOT_ROTATION
        command.speed = speed * @direction
        return true
    end


    def tick!
        command.heading = sensors.heading + MAX_BOT_ROTATION
        command.speed = MAX_BOT_SPEED
        command.radar_heading = sensors.radar_heading + MAX_RADAR_ROTATION
        command.turret_heading = sensors.turret_heading - MAX_TURRET_ROTATION
        command.fire(MIN_FIRE_POWER)
    end

end


class Ultralisk < Overlord
    NAME = "ZERG"
end


class Hydralisk < Ultralisk
    NAME = "ZERG"
end


class Zergling < Hydralisk
    NAME = "ZERG"
end


class Drone < Zergling
    NAME = "ZERG"
end
