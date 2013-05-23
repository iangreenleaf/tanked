#A basic 2-dimensional vector implementation

class Vector
    attr_accessor :x
    attr_accessor :y 

    #note: the supplied angle is treated in radians
    def self.new_from_polar(r,theta)
        self.new(r * Math.sin(theta), r * Math.cos(theta))
    end


    def self.new_from_points(head,tail) 
        self.new(head.x - tail.x, head.y - tail.y)
    end


    def initialize(x,y)
        @x = x
        @y = y
    end


    def *(scalar)
        return self.class.new(x*scalar,y*scalar)
    end


    def +(other)
        return self.class.new(x+other.x,y+other.y)
    end


    def -(other)
        return self.class.new(x-other.x,y-other.y)
    end


    def coerce(other) #allows commutivity with other object (unclear why)
        return self, other
    end


    def length()
        return Math.sqrt(x*x + y*y)
    end


    def normalize()
        if length > 0
            len = length #remember, length is a method
            @x = x/len
            @y = y/len
            return self
        else
            raise ZeroDivisionError
        end
    end


    def dot(other)
        return @x*other.x + @y*other.y
    end


    #note:
    # -rotation is counter-clockwise
    # -the supplied angle is treated in radians
    def rotate(theta)
        theta *= -1
        newx = @x * Math.cos(theta) - @y * Math.sin(theta)
        newy = @x * Math.sin(theta) + @y * Math.cos(theta)
        @x = newx
        @y = newy
        return self
    end
end
