#Implements a class to track enemy movements in an RTanque match
require '/home/tsedberry/Documents/Scripts/RTANQUE/SHEILA/components.rb'

class Enemy
    include Constants
    include RTanque::Bot::BrainHelper
    include PositionTracker

    def initialize(name,location,time)
        initialize_PositionTracker
        update_position(location,time)
        @name = name
    end


    def name()
        return @name
    end


    #last time this enemy was detected
    def last_time
        return @position.keys.max
    end


    #last location this enemy was detected at
    def last_position
        return position(last_time)
    end


    #returns true if this enemy could be at the specified location at the specified time
    def is_here_now?(location,time)
        epsilon = 1
        return location.distance(last_position) <= (time - last_time) * MAX_BOT_SPEED + epsilon
    end

end
