class IdGenerator < ActiveRecord::Base
  
  #for help finding primes, see http://primes.utm.edu/lists/small/10000.txt
  def self.default_generator_params
    {
      :number_adder => 10001,
      :number_prime => 1,
      :scrambled_digits => 0      
    }
  end
  
  def self.generator_for(purpose, initial_params)
    @@sequential_generators ||= {}
    @@sequential_generators[purpose] ||= IdGenerator.find_by_purpose(purpose)    
    if(@@sequential_generators[purpose].nil?)
      generator = IdGenerator.new
      IdGenerator.transaction_in_seperate_connection(generator) do |conn|
        generator.purpose = purpose
        generator.number_adder = initial_params[:number_adder].to_i
        generator.number_prime = initial_params[:number_prime].to_i
        if generator.number_prime < 1
          raise ArgumentError, "number_prime param must be greater than 1, in #{initial_params.inspect}"
        end
        generator.scrambled_digits = initial_params[:scrambled_digits].to_i
        unless generator.number_prime > (10 ** (generator.scrambled_digits - 1))
          raise ArgumentError, "number_prime must be at least #{generator.scrambled_digits} digits "+
                               "(based on value of scrambled_digits), in #{initial_params.inspect}"
        end
        unless generator.number_adder >= (10 ** (generator.scrambled_digits))
          raise ArgumentError, "number_adder must be at least #{generator.scrambled_digits + 1} digits "+
                               "(one more than the value of scrambled_digits), in #{initial_params.inspect}"          
        end
        generator.save!
      end
      @@sequential_generators[purpose] = generator
    end
    return @@sequential_generators[purpose]
  end
  
  def self.transaction_in_seperate_connection(generator = nil)
    @@transactionsemaphore ||= Mutex.new
    @@transactionsemaphore.synchronize do
      IdGenerator.connection_pool.with_connection do |conn|
          conn.transaction do
            if generator
              #this hack won't be needed when: http://github.com/rails/rails/commit/5501b99a19a2a67a9a920fd3c7bff071a2ecf058
              generator.instance_eval do
                class << self
                  attr_accessor :connection
                end
              end
              generator.connection = conn              
            end
            yield conn
          end
      end
    end
  end
  
  def generate_id(seed)
    to_return = seed + number_adder      
    if scrambled_digits.to_i > 0
      mod = (10 ** scrambled_digits)
      to_return = (to_return / mod) * mod
      to_return += ((seed * number_prime) + number_adder) % mod
    end
    # puts "result #{to_return}"
    (10 * to_return) + calc_check_digit(to_return)    
  end
  
  def next_id
    seed_to_use = nil
    IdGenerator.transaction_in_seperate_connection do |conn|
      conn.execute("Update id_generators set last_seed = last_seed + 1 WHERE id = #{self.id}")
      value_selected = conn.uncached {
        conn.select_value("Select last_seed from id_generators WHERE id = #{self.id}")
      }
      unless value_selected
        raise ArgumentError, "ERROR: Somebody deleted me from the database, but I'm still cached in rails: #{self.inspect}"
      end
      seed_to_use = value_selected.to_i
    end

    return generate_id(seed_to_use)
  end
  
  def calc_check_digit(number)
    digits = number.to_s
    sum = 0;
    (0...digits.size).each do |index|
      digit = digits[index,1].to_i
      digit = ((digit*2) % 9) if(index % 2 == 0)
      sum += digit
    end
    sum % 10;
  end
  
    
end
