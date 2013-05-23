#Includes a number of useful functions involving Vectors, RTanque::Points, and RTanque::Headings.
require_relative 'vector.rb'


#returns the velocity of the specified object at the specified time as a Vector
#the object argument must have a position method
def velocity(object,time)
    if object.position(time).nil? or object.position(time-1).nil?
        return nil
    else
        return Vector.new_from_points(object.position(time),object.position(time-1))
    end
end


#returns the acceleration of the specified object at the specified time as a Vector
#the object argument must have a position method
def acceleration(object,time)
    if velocity(object,time) && velocity(object,time-1)
        return velocity(object,time) - velocity(object,time-1)
    else
        return nil
    end
end


#converts the supplied vector to an RTanque::Point instance, using the supplied point as a basepoint
def apply(vector,point)
    return RTanque::Point.new(point.x + vector.x, point.y + vector.y, point.arena)
end


#converts the supplied vector to an RTanque::Heading instance
#(use RTanque::Heading.radians to get the angle this vector forms with the vertical) 
def heading(vector)
    origin = RTanque::Point.new(0,0,@arena)
    phi = RTanque::Heading.new_between_points(origin, apply(vector,origin))
    return phi
end


#returns a new Point instance located at the corner of the arena closest to the specified point
def closest_corner(point)
    arena = point.arena
    x = (point.x < arena.width/2) ? 0 : arena.width
    y = (point.y < arena.height/2) ? 0 : arena.height
    return RTanque::Point.new(x,y,arena)
end


#returns true if the point is located inside the arena, false otherwise
def inside_arena?(point)
    return point.x.between?(0,point.arena.width) && point.y.between?(0,point.arena.height)
end


#Returns a new point, guaranteed to be inside the arena
#
#If the supplied point is inside the arena, it is returned, otherwise
#a new point is created by projecting the supplied point onto the boundary of the arena
def bind_to_arena(point)
    x = [[0,point.x].max,arena.width].min
    y = [[0,point.y].max,arena.height].min
    return RTanque::Point.new(x,y,point.arena)
end


#Returns true if the specified point lies on an edge of the arena
def on_edge(point)
    x = point.x
    y = point.y
    width = point.arena.width
    height = point.arena.height
    return (x == width) || (x == 0) || (y == height) || (y == 0)
end
