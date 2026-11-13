require 'minitest/autorun'
require 'json'
require 'net/http'
require 'organisationsnummer'

# Shared test data, also used by the other organisationsnummer packages.
# `long_format` has the separator (NNNNNN-NNNN), `short_format` does not.
TESTDATA_URL = 'https://raw.githubusercontent.com/organisationsnummer/meta/HEAD/testdata/list.json'.freeze

def load_testdata
  response = Net::HTTP.get_response(URI(TESTDATA_URL))
  raise "could not load testdata: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

TESTDATA = load_testdata.freeze

# Appends the Luhn check digit to nine digits.
def with_check_digit(digits)
  sum = digits.each_char.with_index.sum do |c, i|
    v = c.to_i * (2 - i % 2)
    v > 9 ? v - 9 : v
  end
  digits + ((10 - sum % 10) % 10).to_s
end

class OrganisationsnummerTest < Minitest::Test
    def inputs(item)
      [item['input'], item['long_format'], item['short_format']]
    end

    def test_testdata_loaded
      refute_empty TESTDATA
    end

    def test_valid
      TESTDATA.each do |item|
        inputs(item).each do |input|
          assert_equal item['valid'], Organisationsnummer.valid?(input), input
        end
      end
    end

    def test_parse_raises
      TESTDATA.reject { |item| item['valid'] }.each do |item|
        inputs(item).each do |input|
          assert_raises(Organisationsnummer::Error, input) { Organisationsnummer.parse(input) }
          assert_raises(Organisationsnummer::Error, input) { Organisationsnummer::Organisationsnummer.new(input) }
        end
      end
    end

    def test_format
      TESTDATA.select { |item| item['valid'] }.each do |item|
        # `short_format` is left out as input, a personnummer without
        # separator has an ambiguous century.
        [item['input'], item['long_format']].each do |input|
          org = Organisationsnummer.parse(input)
          assert_equal item['long_format'], org.format, input
          assert_equal item['long_format'], org.format(true), input
          assert_equal item['short_format'], org.format(false), input
        end
      end
    end

    def test_format_old_personnummer
      assert_equal '121212+1212', Organisationsnummer.parse('191212121212').format
      assert_equal '1212121212', Organisationsnummer.parse('191212121212').format(false)
    end

    def test_type
      TESTDATA.select { |item| item['valid'] }.each do |item|
        assert_equal item['type'], Organisationsnummer.parse(item['input']).type, item['input']
      end
    end

    def test_type_by_first_digit
      types = {
        '1' => 'Dödsbon',
        '2' => 'Stat, landsting, kommun eller församling',
        '3' => 'Utländska företag som bedriver näringsverksamhet eller äger fastigheter i Sverige',
        '4' => 'Okänt',
        '5' => 'Aktiebolag',
        '6' => 'Enkelt bolag',
        '7' => 'Ekonomisk förening eller bostadsrättsförening',
        '8' => 'Ideella förening och stiftelse',
        '9' => 'Handelsbolag, kommanditbolag och enkelt bolag'
      }
      types.each do |digit, type|
        number = with_check_digit(digit + '02100548')
        org = Organisationsnummer.parse(number)
        assert_equal type, org.type, number
        assert_equal false, org.is_personnummer?, number
        assert_nil org.personnummer, number
      end
    end

    def test_vat_number
      TESTDATA.select { |item| item['valid'] }.each do |item|
        assert_equal item['vat_number'], Organisationsnummer.parse(item['input']).vat_number, item['input']
      end
    end

    def test_personnummer
      TESTDATA.select { |item| item['valid'] }.each do |item|
        org = Organisationsnummer.parse(item['input'])
        is_personnummer = item['type'] == 'Enskild firma'
        assert_equal is_personnummer, org.is_personnummer?, item['input']
        assert_equal is_personnummer, !org.personnummer.nil?, item['input']
        if is_personnummer
          assert_instance_of ::Personnummer::Personnummer, org.personnummer
          assert_equal item['long_format'], org.personnummer.format, item['input']
        end
      end
    end

    def test_century_prefix
      assert_equal true, Organisationsnummer.valid?('165560160680')
      assert_equal true, Organisationsnummer.valid?('16556016-0680')
    end

    def test_prefix_other_than_16_is_invalid
      %w[15 17 18 19 20 00].each do |prefix|
        assert_equal false, Organisationsnummer.valid?(prefix + '5560160680'), prefix
      end
    end

    def test_invalid_input
      [
        '',
        '-',
        '556016068',
        '55601606800',
        '556016--0680',
        '556016 0680',
        ' 5560160680',
        '5560160680 ',
        '556016-068A',
        'xx5560160680yy',
        '0560160680',
        '0000000000',
        '1234567890'
      ].each do |input|
        assert_equal false, Organisationsnummer.valid?(input), input
      end
    end

    def test_anchoring
      assert_equal false, Organisationsnummer.valid?("5560160680\n")
      assert_equal false, Organisationsnummer.valid?("556016-0680\n")
      assert_equal false, Organisationsnummer.valid?("\n5560160680")
      assert_equal false, Organisationsnummer.valid?("foo\n5560160680")
      assert_equal false, Organisationsnummer.valid?("5560160680\nfoo")
      assert_equal false, Organisationsnummer.valid?("5560160680\n5560160680")
      # The personnummer fallback must not see multi-line input either.
      assert_equal false, Organisationsnummer.valid?("foo\n9001010017")
      assert_equal false, Organisationsnummer.valid?("9001010017\n")
      assert_equal false, Organisationsnummer.valid?("9001010017\nfoo")
      assert_equal true, Organisationsnummer.valid?('9001010017')
    end

    def test_non_ascii_digits
      # Arabic-Indic digits.
      assert_equal false, Organisationsnummer.valid?('٥٥٦٠١٦٠٦٨٠')
      assert_equal false, Organisationsnummer.valid?('١٢١٢١٢١٢١٢')
      # Fullwidth digits.
      assert_equal false, Organisationsnummer.valid?('５５６０１６０６８０')
      assert_equal false, Organisationsnummer.valid?('５５６０１６-０６８０')
      assert_equal false, Organisationsnummer.valid?('９００１０１００１７')
    end

    def test_invalid_encoding
      assert_equal false, Organisationsnummer.valid?("5560160680\xff")
      assert_raises(Organisationsnummer::Error) { Organisationsnummer.parse("\xff") }
    end

    def test_wrong_types
      # Same as the personnummer gem, anything is converted with `to_s`.
      assert_equal true, Organisationsnummer.valid?(5560160680)
      assert_equal true, Organisationsnummer.valid?(9001010017)
      assert_equal false, Organisationsnummer.valid?(nil)
      assert_equal false, Organisationsnummer.valid?([])
      assert_equal false, Organisationsnummer.valid?({})
      assert_equal false, Organisationsnummer.valid?(false)
      assert_equal false, Organisationsnummer.valid?(true)
      assert_equal false, Organisationsnummer.valid?(0)
      assert_equal false, Organisationsnummer.valid?(1234567890)
      assert_equal '556016-0680', Organisationsnummer.parse(5560160680).format
    end

    def test_personnummer_fallback
      org = Organisationsnummer.parse('900101-0017')
      assert_equal true, org.is_personnummer?
      assert_equal 'Enskild firma', org.type
      assert_equal '900101-0017', org.format
      assert_equal '9001010017', org.format(false)
      assert_equal 'SE900101001701', org.vat_number
      # Coordination numbers are accepted, interim numbers are not.
      assert_equal true, Organisationsnummer.valid?('850769-9810')
      assert_equal false, Organisationsnummer.valid?('000101-T220')
    end

    def test_error_class
      assert_operator Organisationsnummer::Error, :<, StandardError
      assert_equal 'Organisationsnummer::Error', Organisationsnummer::Error.name
      error = assert_raises(Organisationsnummer::Error) { Organisationsnummer.parse('Just a string') }
      assert_equal 'Invalid Organisationsnummer', error.message
      assert_raises(Organisationsnummer::Error) { Organisationsnummer.parse('1234567890') }
    end
end
