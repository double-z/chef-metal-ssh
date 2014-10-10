hash1 = { 'a' => '1', 'b' => '2' }
hash2 = { 'a' => '1', 'b' => '2' }
#hash2 = { 'c' => '3', 'd' => '4' }

def compare(hash1, hash2)
  args = [hash1, hash2]

  return true if args.all? {|h| h.nil?}
  return false if args.one? {|h| h.nil?}

  hash1.each_key do |k|
    values = [hash1[k], hash2[k]]

    if values.all? {|h| h.is_a?(Hash)}
      return false unless compare(*values)
    else
      return false if values.one? {|value| value.nil? }
    end
  end

  true
end

case compare(hash1, hash2)
when true
  puts 'true'
when false
  puts 'false'
end
