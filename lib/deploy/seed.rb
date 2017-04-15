# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


 user = Owner.new(first_name:"Jame" , last_name:"Rock" , email: "poulin@gmail.com", password:"shiv@260!" , role: "Super Admin")
 if  user.valid?
   user.save
 end
 
#  Monthly plans
 user.plans.create( name: "Solo", no_doctors: 1 , price: 45, category: "Monthly")
 user.plans.create( name: "Team", no_doctors: 5 , price: 95, category: "Monthly")
 user.plans.create( name: "Medium", no_doctors: 8 , price: 145, category: "Monthly")
 user.plans.create( name: "Group", no_doctors: 12 , price: 195, category: "Monthly")
 user.plans.create( name: "Large", no_doctors: 25 , price: 295, category: "Monthly")
 user.plans.create( name: "University", no_doctors: 150 , price: 395, category: "Monthly")

#  Yearly Plans 
 user.plans.create( name: "Solo", no_doctors: 1 , price: 495, category: "Yearly")
 user.plans.create( name: "Team", no_doctors: 5 , price: 1045, category: "Yearly")
 user.plans.create( name: "Medium", no_doctors: 8 , price: 1595, category: "Yearly")
 user.plans.create( name: "Group", no_doctors: 12 , price: 2145, category: "Yearly")
 user.plans.create( name: "Large", no_doctors: 25 , price: 3245, category: "Yearly")
 user.plans.create( name: "University", no_doctors: 150 , price: 4345, category: "Yearly")
 
 puts "subscription plans created successfully !"
 
#  sms plans 
 user.sms_plans.create(amount: 50, no_sms: 500)
 user.sms_plans.create(amount: 100, no_sms: 1000)
 user.sms_plans.create(amount: 500, no_sms: 5000)
 
 puts " sms plans created successfully !"  
