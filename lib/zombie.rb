class Zombie 
  attr_accessor :name , :brain , :rating     
  
  def initialize
    @name ="Ash"
    @brain = 0
    @rating =  true
  end 
  
  def hungry?
    true 
  end 
  
end
