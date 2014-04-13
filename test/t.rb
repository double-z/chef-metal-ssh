one = { :v1 => 'one' }
two = { :v1 => 'one', :v2 => 'two' }
onea = one.to_a
twoa = two.to_a

puts 'onea'
onea.each do |eone|
if twoa.include?(eone)
puts eone
end
#else 
#puts 'nope'
end
