require_relative 'enemy.rb'
require_relative 'vector.rb'
require_relative 'utilities.rb'
require_relative 'components.rb'


class Sheila < RTanque::Bot::Brain
    include Constants
    include RTanque::Bot::BrainHelper
    include HealthTracker
    include PositionTracker
    include EnemyTracker
    include Weapons
    include Navigation
    include Targetting

    NAME = 'Sheila'

    def initialize(arena)
        @arena = arena
        initialize_HealthTracker
        initialize_PositionTracker
        initialize_EnemyTracker
        initialize_Weapons
        initialize_Navigation
        initialize_Targetting
    end


    def update_my_health()
        update_health(self.sensors.health,now)
    end


    def update_my_position()
        update_position(self.sensors.position,now)
    end


    def update()
        update_my_health
        update_my_position
        update_enemy_positions
        update_radar
        return nil
    end


    def now()
        return self.sensors.ticks
    end


    #returns true of health is lower this turn than last turn
    def hit?()
        return ((now > 1) and (health(now) < health(now-1))) ? true : false
    end


    #Enjoys fleeing to the nearest corner, preparing the radar for a scanner sweep, and shooting at anything that enters its sights.
    def scared
        runaway(closest_corner(self.position(now)))

        enemy = target || nearest_enemy
        sweep_prep if enemy.nil? #manually override the radar settings from the update_radar method
        attack(enemy)
    end


    #Enjoys sitting in the corner, carefully choosing a target, and shooting at the target until it expires.
    def shy
        epsilon = 0.01 #floating point killed Kenny
        recently = 100 #ticks
        corner = closest_corner(position(now))
        adjacent_corner = RTanque::Point.new(corner.x,corner.y^(@arena.height),@arena)
        if @enemies.select {|enemy| (adjacent_corner.distance(enemy.last_position) < epsilon) && (enemy.last_time - now).abs < recently}.empty?
            waltz
        else
            runaway(corner)
        end
        attack(target || nearest_enemy)
    end


    def duelist
        if health(now) < 30
            if position(now).distance(closest_corner(position(now))) < RTanque::Bot::RADIUS
                spin
            else
                stalk(target) || spin
            end
        elsif health(now) < 50
            spin
        else
            runaway(closest_corner(self.position(now)))
        end
        attack(target || nearest_enemy)
    end


    def tick!
        update
        puts "Suffered hit for #{health(now-1) - health(now)} damage" if hit? and VERBOSE

        if (enemies_left == 1)
            duelist
        else
            if target.nil? or @sweeping
                scared
            else
                shy
            end
        end
    end

end
