#Provides mixins that add functionality to classes that describe objects in a RTanque arena
require '/home/tsedberry/Documents/Scripts/RTANQUE/SHEILA/vector.rb'
require '/home/tsedberry/Documents/Scripts/RTANQUE/SHEILA/utilities.rb'


module Constants
    BUFFER_SIZE = 100
    VERBOSE = true
end


#Implements health tracking
#
#This mixin tracks the health of an object using a hash whose keys are times (in ticks) and values are the health of the object at the specified tick.
#The hash is made accessible through the health() method.
#
#This module imposes the following requirements on the recipient class in order to function properly:
# -The initialize_HealthTracker() method must be called by the inititalize() method of the recipient class.
# -Every tick, the update_health() method must be called before any calls are made to the health() method.
#
#Example:
#     class Example < RTanque::Bot::Brain
#     include HealthTracker
#     NAME = 'Example'
#
#     def initialize(arena)
#         @arena = arena
#         initialize_HealthTracker
#     end
#
#     def now()
#         return self.sensors.ticks
#     end
#
#     def tick!()
#         update_health(self.sensors.health,now)
#         puts("I have #{health(now)}" hit points left")
#     end
module HealthTracker
    include Constants

    #This method should be called by the initialize method of the recipient class.
    def initialize_HealthTracker()
        @health = {} #keys are Fixnum instances representing time (in ticks), values are Fixnum instances representing health (in hit points)
    end

    #Returns the health of the object at the specified time.
    def health(time)
        return @health[time]
    end

    #Sets the health of the object at the specified time to the specified value.
    #This method should be called every tick, before the health method is used.
    def update_health(hp,time)
        @health[time] = hp
        @health.delete(@health.keys.min) if @health.size > BUFFER_SIZE
        return nil
    end
end


#Implements position tracking
#
#This mixin tracks the position of an object using a hash whose keys are times (in ticks) and values are the position of the object at the specified tick.
#The hash is made accessible through the position() method.
#
#This module imposes the following requirements on the recipient class in order to function properly:
# -The initialize_PositionTracker() method must be called by the inititalize() method of the recipient class.
# -Every tick, the update_position() method must be called before any calls are made to the position() method.
#
#Example:
#     class Example < RTanque::Bot::Brain
#     include PositionTracker
#     NAME = 'Example'
#
#     def initialize(arena)
#         @arena = arena
#         initialize_PositionTracker
#     end
#
#     def now()
#         return self.sensors.ticks
#     end
#
#     def tick!()
#         update_position(self.sensors.position,now)
#         puts("I am located at (#{position(now).x},#{position(now).y}) right now")
#     end
module PositionTracker
    include Constants

    #This method should be called by the initialize method of the recipient class.
    def initialize_PositionTracker()
        @position = {} #keys are Fixnum instances representing time (in ticks), values are RTanque::Point instances representing locations
    end

    #Returns the position of the object at the specified time
    def position(time)
        return @position[time]
    end

    #Sets the position of the object at the specified time to the specified value.
    #This method should be called every tick, before the position method is used.
    def update_position(location,time)
        @position[time] = location
        @position.delete(@position.keys.min) if @position.size > BUFFER_SIZE
        return nil
    end
end


#Implements enemy position tracking
#
#This mixin tracks the position of a colleciton of objects, each of whom are using the PositionTracker mixin.
#The tracked objects are contained in the @enemies attribute, which is an array.
#
#This module imposes the following requirements on the recipient class in order to function properly:
# -Every requirement in the PositionTracker module
# -The recipient class must have a sensors method (e.g. RTanque::Bot::Brain.sensors)
# -The recipient class must have a now method, which returns the current time (in ticks)
# -The initialize_EnemyTracker() method must be called by the inititalize() method of the recipient class.
# -Every tick, the update_enemy_positions() method must be called before any inquries are made to objects in the @enemies array.
#
#Example:
#     class Example < RTanque::Bot::Brain
#     include EnemyTracker
#     NAME = 'Example'
#
#     def initialize(arena)
#         @arena = arena
#         initialize_EnemyTracker
#     end
#
#     def tick!()
#         update_enemy_positions()
#         puts("I have seen #{@enemies.length} distinct enemies with my radar so far")
#     end
module EnemyTracker
    include Constants
    include PositionTracker

    def initialize_EnemyTracker()
        raise(NotImplementedError,"EnemyTracker module requires a sensors method") if not self.respond_to?(:sensors)
        raise(NotImplementedError,"EnemyTracker module requires a now method") if not self.respond_to?(:now)
        @enemies = [] #list of Enemy instances
    end


    #returns the absolute position inside the arena of the supplied reflection as a new RTanque::Point instance
    def absolute_position(reflection)
        v = Vector.new_from_polar(reflection.distance,reflection.heading.radians)
        return apply(v,self.position(now))
    end


    def update_enemy_positions()
        @enemies.sort! {|a,b| a.last_time <=> b.last_time}
        self.sensors.radar.each do |reflection|
            location = absolute_position(reflection)
            matches = []

            #match this reflection with an enemy
            @enemies.each do |enemy|
                if enemy.last_time == now
                    next # we already know the location of this enemy
                elsif enemy.is_here_now?(location,now) && enemy.name == reflection.name
                    matches << enemy
                end
            end

            #pick the best match
            matches.sort! {|a,b| a.last_position.distance(location) <=> b.last_position.distance(location)}
            if matches.size > 0
                matches.first.update_position(location,now)
            else
                puts "New enemy detected: #{reflection.name}" if VERBOSE
                @enemies << Enemy.new(reflection.name,location,now) #new enemy!
            end
        end
    end

end


#Provides tools to assist in aiming at moving targets
#
#This mixin uses physics to predict the path of objects using the PositionTracker mixin.
#
#This module imposes the following requirements on the recipient class in order to function properly:
# -Every requirement in the PositionTracker module
# -The recipient class must have a sensors method (e.g. RTanque::Bot::Brain.sensors)
# -The recipient class must have a command method (e.g. RTanque::Bot::Brain.command)
# -The recipient class must have a now method which returns the current time (in ticks)
# -The recipient class must have an arena attribute (e.g. RTanque::Bot::Brain.@arena)
module Weapons
    include RTanque::Bot::BrainHelper
    include PositionTracker

    def initialize_Weapons
        raise(NotImplementedError,"Weapons module requires a sensors method") if not self.respond_to?(:sensors)
        raise(NotImplementedError,"Weapons module requires a command method") if not self.respond_to?(:command)
        raise(NotImplementedError,"Weapons module requires a now method") if not self.respond_to?(:now)
        raise(NotImplementedError,"Weapons module requires an arena attribute") if not self.respond_to?(:arena)
    end


    #returns true if the enemy is in the same location as the caller
    #
    #Bosons are not subject to the Pauli exclusion priciple, which states that no two fermions can share identical quantum states.
    def boson?(enemy)
        return enemy.position(now) == self.position(now)
    end


    #returns true if the enemy has been sitting in a corner for a sufficiently long amount of time, false otherwise
    #
    #By wedging into a corner and then trying to turn in a particular manner,
    #it is possible to undergo rapid acceleration in opposite directions while
    #remaining stationary. This behavior confuses the firing_solution method,
    #and must be dealt with as a special case.
    #
    #The Camper sample bot frequently exhibits this behavior
    def camper?(enemy)
        return false if enemy.position(now).nil? #insufficient data available to determine if enemy is a camper
        longtime = 8 #number of ticks to observe enemy for
        corner = closest_corner(enemy.position(now)) #closest corner to the enemy's current location
        longtime.times do |i|
            return false if enemy.position(now-i).nil? or (corner.distance(enemy.position(now-i)) > RTanque::Bot::RADIUS)
        end
        return true #bot has been in this corner for at least longtime ticks
    end


    #returns true if there is sufficient data available to compute a firing solution for the specified enemy
    def firing_solution?(enemy)
        if acceleration(enemy,now).nil?
            return false
        else
            return true
        end
    end


    #returns the heading to shoot at in order to hit the target, or nil if there is insufficient information to compute the firing solution
    #
    #assumes the target is undergoing constant acceleration, relative to its velocity.
    def firing_solution(enemy)
        raise RuntimeError("Cannot compute firing solution for this enemy at this time") if !firing_solution?(enemy)

        epsilon = 0.01 #fuck floating point arithmetic
        bullet_speed = RTanque::Shell::SHELL_SPEED_FACTOR * MAX_FIRE_POWER #22.5
        ticks = Math.sqrt(@arena.width**2 + @arena.height**2)/bullet_speed #longest amount of time a shell could possibly spend on the screen
        initial_velocity = velocity(enemy,now)
        initial_acceleration = acceleration(enemy,now)

        #compute angle between initial velocity and acceleration (*relative* acceleration)
        theta = (initial_acceleration.length > epsilon) ? heading(initial_acceleration).radians - heading(initial_velocity).radians : 0

        locations = {} #values are future enemy locations, keys are distance between shell (future position cone) and enemy
        location = enemy.position(now) #projected enemy location at a future time
        v = initial_velocity #projected enemy velocity at a future time
        a = initial_acceleration #projected enemy acceleration at a future time
        ticks.round.times do |tick|
            locations[(location.distance(self.position(now)) - bullet_speed*tick).abs] = location

            #apply constant acceleration, relative to enemy velocity
            a = Vector.new(0,initial_acceleration.length)
            a.rotate(heading(v).radians + theta)
            v = v+a

            #throttle speed
            if MAX_BOT_SPEED < v.length
                v.normalize
                v *= MAX_BOT_SPEED
            end

            #update location
            location = bind_to_arena(apply(v,location))
        end

        #the location (as an RTanque::Point instance) to shoot at now in order to hit the specified enemy in the future
        location = locations[locations.keys.min]

        #returns the heading to shoot at in order to hit the target
        return RTanque::Heading.new_between_points(self.position(now),location)
    end


    #Given a target Enemy instance, decides whether to fire a shot or not
    #Returns true if a shot will be fired, and false if there is insufficient gun energy to fire a shot
    def attack(target)
        if target and boson?(target)
            center = RTanque::Point.new(@arena.width/2,@arena.height/2,@arena)
            heading = position(now).heading(center) + Math::PI #points offscreen (presumably this forces shell instantiation on screen, at edge, and results in a hit)
            firepower = MAX_FIRE_POWER #maximizes DPS for this guaranteed hit
        elsif target and camper?(target)
            heading = RTanque::Heading.new_between_points(self.position(now),target.position(now)) #bots in a corner can perform erratic movements that confuses the firing_solution method
            firepower = MAX_FIRE_POWER-1 #Full powered shots often land right next to enemy bot, but off the screen, and so they never detonate (and deal no damage)
        elsif target and firing_solution?(target)
            heading = firing_solution(target)
            firepower = MAX_FIRE_POWER
        else
            heading = sensors.radar_heading
            firepower = MIN_FIRE_POWER
        end

        #fire at the specified target, using the specified heading, if the turret is pointing in the right direction.
        if sensors.turret_heading.delta(heading).abs < RTanque::Heading::ONE_DEGREE * 1.0
            command.fire(firepower)
        else
            command.fire(MIN_FIRE_POWER)
        end

        #set the turret heading
        command.turret_heading = heading

        return (sensors.gun_energy and (sensors.gun_energy >= 0)) ? true : false
    end
end


#Provides methods to control the movement of an object using the PositionTracker method
module Navigation
    include RTanque::Bot::BrainHelper
    include PositionTracker

    def initialize_Navigation
        raise(NotImplementedError,"Navigation module requires a sensors method") if not self.respond_to?(:sensors)
        raise(NotImplementedError,"Navigation module requires a command method") if not self.respond_to?(:command)
        raise(NotImplementedError,"Weapons module requires a now method") if not self.respond_to?(:now)
        @direction = 1 #forward=1 reverse=-1
    end


    #Moves to the specified location
    #Returns true
    #
    #Sets the heading and speed using command so that the bot moves to the specified location
    def runaway(location)
        if position(now) == location
            speed = 0
            return true
        end
        heading = self.position(now).heading(location)
        u = Vector.new_from_points(self.position(now),location)
        v = Vector.new_from_polar(1,sensors.heading.radians)
        if u.dot(v) > 0
            @direction = -1
            heading += Math::PI
        else
            @direction = 1
        end

        speed = MAX_BOT_SPEED
        command.heading = heading
        command.speed = speed * @direction
        return true
    end


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


    #Bobs and weaves along a circular path around the target
    #Returns nil if that specified target doesn't exist or its current position is not known, otherwise returns true
    #
    #Sets the heading and speed using command so that the bot circles the specified target
    def stalk(target)
        return nil if target.nil? || target.position(now).nil?
        danger_close = MAX_BOT_SPEED * 20
        epsilon = 0.01 #floating point is a bitch sometimes
        heading = RTanque::Heading.new_between_points(target.position(now),self.position(now)) + Math::PI / 2.0
        v = Vector.new_from_polar(danger_close, heading.radians) * @direction
        @direction *= -1 if !inside_arena?(apply(v,self.position(now))) #reverse direction if headed offscreen
        @direction *= -1 if (velocity(self,now).length-MAX_BOT_SPEED).abs < epsilon #bob and weave
        speed = MAX_BOT_SPEED
        command.heading = heading
        command.speed = speed * @direction
        return true
    end


    #oscillates about the bisector of the narrowest dimension of the arena
    def waltz
        arena = position(now).arena
        @direction = (position(now).y < arena.height/2) ? 1 : -1
        command.heading = RTanque::Heading::NORTH
        command.speed = @direction * MAX_BOT_SPEED
    end
end


# Provides tools for scanning the arena and choosing enemies to target
#
# See target(), update_Targetting(), and sweep()
module Targetting
    include Constants
    include RTanque::Bot::BrainHelper
    include PositionTracker
    include EnemyTracker

    def initialize_Targetting()
        raise(NotImplementedError,"Targetting module requires a sensors method") if not self.respond_to?(:sensors)
        raise(NotImplementedError,"Targetting module requires a command method") if not self.respond_to?(:command)
        raise(NotImplementedError,"Weapons module requires a now method") if not self.respond_to?(:now)
        @sweeping = nil #indicates if a scan is in progress (values are :first, :second, or :third)
        @target = nil #The current target (an Enemy instance)
        @targets = [] #An array of potential targets (populated by the first_sweep method) @targets.size indicates (roughly) the number of remaining enemies
        @point_of_interest = nil #desired radar heading (a RTanque::Point instance)
    end


    #Returns an Enemy instance representing the nearest visible enemy (or nil if there are no enemies visible)
    def nearest_enemy()
        targets = @enemies.select {|enemy| enemy.position(now)}
        targets.sort! {|a,b| a.position(now).distance(self.position(now)) <=> b.position(now).distance(self.position(now))}
        #puts "Enemy: #{targets.first.name} is in range" if VERBOSE and !targets.empty? and targets.first.position(now) and targets.first.position(now-1).nil?
        return (targets.empty?) ? nil : targets.first
    end


    #Given an array of Enemy instances, returns the Enemy instance whose last observed location was closest to self
    def pick_nearest_target(targets)
        raise RuntimeError ("A non-empty, non-nil array of targets is required") if targets.nil? or targets.empty?
        targets.sort! {|a,b| a.last_position.distance(self.position(now)) <=> b.last_position.distance(self.position(now))}
        return targets.first
    end


    #Given an array of Enemy instances, returns an randomly selected Enemy
    def pick_random_target(targets)
        raise RuntimeError ("A non-empty, non-nil array of targets is required") if targets.nil? or targets.empty?
        target = targets.sample
        return target
    end


    #Identical to pick_nearest_target method, except we give preference to enemies who are very close to corners
    #
    #RTanque currently has a glitch that makes it difficult to hit targets in corners, but I've figured out how to
    #circumvent it.
    def pick_cornered_target(targets)
        epsilon = RTanque::Bot::RADIUS/4
        cornered_targets = targets.select {|target| closest_corner(target.last_position).distance(target.last_position) < epsilon}
        return (cornered_targets.empty?) ? pick_nearest_target(targets) : pick_nearest_target(cornered_targets)
    end


    #returns a heading (never nil) to aim the radar at
    #
    #special treatment is given when self is located in a corner or on an edge to avoid wasting time scanning space outside of the arena
    def smarter_radar_heading()
        corner = closest_corner(position(now))
        arena = corner.arena
        if position(now) == corner #corner behavior
            if @point_of_interest.nil?
                @point_of_interest = RTanque::Point.new(corner.x,(corner.y)^(arena.height))
            end
            if sensors.radar_heading == position(now).heading(@point_of_interest)
                opposite_corner = RTanque::Point.new(@point_of_interest.x^arena.width,@point_of_interest.y^arena.height)
                @point_of_interest = opposite_corner
            end
            return position(now).heading(@point_of_interest)
        elsif on_edge(position(now)) #edge behavior
            #compute vector normal to edge
            if position(now).x == 0
                v = Vector.new(1,0)
            elsif position(now).x == arena.width
                v = Vector.new(-1,0)
            elsif position(now).y == 0
                v = Vector.new(0,1)
            elsif position(now).y == arena.height
                v = Vector.new(0,-1)
            else
                raise RuntimeError("But... you said we were on a corner.")
            end
            if @point_of_interst.nil?
                @point_of_interest = apply(v,corner)
            end
            if sensors.radar_heading == position(now).heading(@point_of_interest)
                x = @point_of_interest.x ^ (arena.width * v.x.abs)
                y = @point_of_interest.y ^ (arena.height * v.y.abs)
                @point_of_interest = RTanque::Point.new(x,y,arena)
            end
            return position(now).heading(@point_of_interest)
        else
            return sensors.radar_heading + MAX_RADAR_ROTATION
        end
    end


    #returns a heading (never nil) to aim the radar at
    #
    #special treatment is given when self is located in a corner to avoid wasting time scanning space outside of the arena
    def smart_radar_heading()
        #check if we're in a corner
        corner = closest_corner(position(now))
        if position(now) == closest_corner(position(now))
            if @point_of_interest.nil?
                adjacent_corner = (rand < 0.5) ? RTanque::Point.new(corner.x,(corner.y)^(@arena.height)) : RTanque::Point.new((corner.x)^(@arena.width),corner.y)
                @point_of_interest = adjacent_corner
            end
            if sensors.radar_heading == position(now).heading(@point_of_interest)
                opposite_corner = RTanque::Point.new(@point_of_interest.x^@arena.width,@point_of_interest.y^@arena.height)
                @point_of_interest = opposite_corner
            end
            return position(now).heading(@point_of_interest)
        else
            return sensors.radar_heading + MAX_RADAR_ROTATION
        end
    end


    #Returns an RTanque::Heading that places the radar in a good position to begin a sweep
    #
    #This method assume that the bot is headed for the nearest corner
    def sweep_prep()
        corner = closest_corner(position(now))
        starting_corner = RTanque::Point.new(corner.x,(corner.y)^(@arena.height))
        return position(now).heading(starting_corner)
    end


    #initiates a (triple pass) scanner sweep of the arena
    #returns a heading to aim the radar at (or nil if the sweep has terminated)
    #
    #the method requires that self be located in a corner (otherwise nil is returned)
    def sweep()
        corner = closest_corner(position(now))
        return @sweeping = nil if position(now) != corner #we cannot sweep unless we're in a corner

        if @sweeping.nil?
            puts "starting sweep" if VERBOSE
            return first_sweep(corner)
        elsif @sweeping == :first
            return first_sweep(corner)
        elsif @sweeping == :second
            return second_sweep(corner)
        elsif @sweeping == :third
            return third_sweep(corner)
        end
    end


    #scans the arena, identifying enemies
    #
    #all identified enemies are placed in the @targets array
    def first_sweep(corner)
        #beginning a sweep
        if @sweeping.nil?
            @sweeping = :first
            @point_of_interest = nil
            @target = nil
            @targets = []
        end

        starting_corner = RTanque::Point.new(corner.x,(corner.y)^(@arena.height))
        ending_corner = RTanque::Point.new((corner.x)^(@arena.width),corner.y)

        @sweeping = :second if sensors.radar_heading == position(now).heading(ending_corner) and @point_of_interest
        @point_of_interest = starting_corner if @point_of_interest.nil?
        @point_of_interest = ending_corner if sensors.radar_heading == position(now).heading(starting_corner)

        if @point_of_interest == ending_corner
            @enemies.each {|enemy| @targets << enemy if (enemy.last_time == now) and (@targets.count(enemy) < 1)}
        end

        return position(now).heading(@point_of_interest)
    end


    #scans the arena, searching for a chosen target enemy
    #
    #this method also chooses a target from the @targets array, setting the @target data member
    def second_sweep(corner)
        return @sweeping = nil if @targets.empty?
        starting_corner = RTanque::Point.new((corner.x)^(@arena.width),corner.y)
        ending_corner = RTanque::Point.new(corner.x,(corner.y)^(@arena.height))

        #reset radar for new sweep (if necessary), then choose target
        if @target.nil?
            if sensors.radar_heading != position(now).heading(starting_corner)
                return position(now).heading(starting_corner)
            else
                @target = pick_cornered_target(@targets)
                puts "There are #{@targets.size} enemies remaining" if VERBOSE
                puts "Chose #{@target.name}" if VERBOSE
                @point_of_interest = ending_corner
            end
        end

        #target found, stop sweep
        if @target.last_time == now
            puts "found target #{@target.name}" if VERBOSE
            @sweeping = nil
            @point_of_interest = nil
            return position(now).heading(@target.position(now))
        end

        #finished the sweep without finding the target
        @sweeping = :third if sensors.radar_heading == position(now).heading(ending_corner)

        return position(now).heading(ending_corner)
    end


    #scans the arena, searching for any enemy
    #
    #in the event that the target chosen by second_sweep is destroyed while we're not looking,
    #we will take any available target 
    def third_sweep(corner)
        starting_corner = RTanque::Point.new(corner.x,(corner.y)^(@arena.height))
        ending_corner = RTanque::Point.new((corner.x)^(@arena.width),corner.y)

        #reset radar for final sweep (if necessary)
        if @target
            if sensors.radar_heading != position(now).heading(starting_corner)
                return position(now).heading(starting_corner)
            else
                @target = nil
                @point_of_interest = ending_corner
            end
        end

        @target = nearest_enemy
        if @target
            puts "Using target #{@target.name}" if VERBOSE
            @sweeping = nil
            return self.position(now).heading(@target.position(now))
        end

        #big trouble; couldn't find any enemies. Restarting sweep...
        @sweeping = :first if sensors.radar_heading == position(now).heading(ending_corner)

        return position(now).heading(@point_of_interest)
    end


    #Returns the number of live enemies who remain
    #
    #This is determined by the size of the @targets array, which is populated by the sweep methods.
    #As such, if a sweep is currently in progress, the size of the @targets array may not provide an accurate reading.
    def enemies_left()
        if @sweeping.nil?
            return @targets.size
        else
            return nil
        end
    end


    #Returns an Enemy instance representing a visible bot, as a suggested target to attack
    #
    #Note that the existence of @target and @target.position(now) necessarily means that we have stopped sweeping
    def target()
        return (@target and @target.position(now)) ? @target : nil
    end


    #Updates the radar heading according to the following (ordered) rules:
    #
    # 1. If we are in the process of sweeping, continue to sweep
    # 2. If we have a target, focus on the target
    # 3. If we don't have a target and we're in a corner, begin a sweep
    # 4. If there is a visible enemy, target it
    # 5. Spin the radar
    def update_radar()
        if @sweeping
            command.radar_heading = sweep
        elsif target
            command.radar_heading = position(now).heading(target.position(now))
        elsif (position(now) == closest_corner(position(now)))
            command.radar_heading = sweep
        elsif nearest_enemy
            command.radar_heading = position(now).heading(nearest_enemy.position(now))
        else
            command.radar_heading = smarter_radar_heading
        end
    end

end
