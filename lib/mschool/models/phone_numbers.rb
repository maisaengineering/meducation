module Mschool
  module Models
    module PhoneNumbers

      def extract_phone_number(phone)
        unless phone.blank?
          phone.gsub!(/[^0-9]/, "")
          phone.match(/(0+)/)
          if !$1.blank? and phone.index($1).eql?(0)
            phone.slice(($1.length)..-1)
          else
            phone
          end
        end
      end

      def parse_phone_number(phone_number)
        phone_number = extract_phone_number(phone_number.to_s).to_s
        regex = Regexp.new "\\A("+COUNTRIES.values.map{|c|c["country_code"] unless c["country_code"].blank?}.compact.uniq.join('|')+")"
        phone_number.match(regex)
        if !$1.blank? and phone_number.index($1).eql?(0)
          {:country_code=> phone_number.slice(0..($1.length-1)),
           :number=>phone_number.slice(($1.length)..-1)}
        end
      end

      def prefix_country_code(phone_number, alpha2 = 'US')
        unless phone_number.blank?
          country = COUNTRIES[alpha2 || 'US']
          unless country.blank?
            phone_number.is_a?(Array) ? phone_number.map{|phno|country["country_code"]+phno.to_s} : country["country_code"]+phone_number.to_s
          else
            phone_number
          end
        end
      end

      def convert_to_regex_pattern(phone_number)
        unless phone_number.blank?
          phone_number.is_a?(Array) ? phone_number.map{|phno| /#{phno}$/} : /#{phone_number}$/
        end
      end

      def strip_country_code(phone_number)
        pphno = parse_phone_number(phone_number)
        pphno[:number] if pphno
      end

    end
  end
end
