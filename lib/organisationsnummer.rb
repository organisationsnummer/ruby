# -*- encoding: utf-8 -*-
require 'personnummer'

module Organisationsnummer
  class Error < StandardError; end

  class Organisationsnummer
    # ASCII digits only, and \A and \z since ^ and $ match at line boundaries in Ruby.
    # The input is matched here before anything is handed to Personnummer.
    PATTERN = /\A([0-9]{2})?([0-9]{2})([0-9]{2})([0-9]{2})[-+]?([0-9]{4})\z/

    TYPES = {
      '1' => 'Dödsbon',
      '2' => 'Stat, landsting, kommun eller församling',
      '3' => 'Utländska företag som bedriver näringsverksamhet eller äger fastigheter i Sverige',
      '5' => 'Aktiebolag',
      '6' => 'Enkelt bolag',
      '7' => 'Ekonomisk förening eller bostadsrättsförening',
      '8' => 'Ideella förening och stiftelse',
      '9' => 'Handelsbolag, kommanditbolag och enkelt bolag'
    }.freeze

    def initialize(organisationsnummer)
      input = organisationsnummer.to_s
      match = input.valid_encoding? ? PATTERN.match(input) : nil

      if !match
        raise Error, "Invalid Organisationsnummer"
      end

      prefix = match[1]
      first = match[2]
      second = match[3]
      @number = first + second + match[4] + match[5]
      @personnummer = nil

      # May only be prefixed with 16, may not start with a leading zero and
      # the third and fourth digit must be 20 or more.
      if (prefix.nil? || prefix == '16') && first.to_i >= 10 && second.to_i >= 20 && luhn?(@number)
        return
      end

      # A personal identity number is also a valid organization number.
      begin
        @personnummer = ::Personnummer.parse(input)
      rescue ::Personnummer::Error
        raise Error, "Invalid Organisationsnummer"
      end
      pnr = @personnummer
      @number = pnr.year + pnr.month + pnr.day + pnr.num + pnr.check
    end

    # Returns the formatted number, NNNNNN-NNNN, or NNNNNNNNNN when separator is false.
    # A personal identity number of someone 100 years or older gets + as separator.
    # (String)
    def format(separator=true)
      return @number unless separator
      return @personnummer.format if @personnummer

      "#{@number[0, 6]}-#{@number[6, 4]}"
    end

    # Checks if the Organisationsnummer is a personal identity number (Enskild firma)
    # (TrueClass/FalseClass)
    def is_personnummer?
      !@personnummer.nil?
    end

    # Returns the Personnummer object, or nil if the number belongs to a legal entity
    # (Personnummer::Personnummer, NilClass)
    def personnummer
      @personnummer
    end

    # Returns the type of organization, in Swedish
    # (String)
    def type
      return 'Enskild firma' if is_personnummer?

      TYPES.fetch(@number[0], 'Okänt')
    end

    # Returns the VAT number
    # (String)
    def vat_number
      "SE#{@number}01"
    end

    private

    # Checks that the last digit is a valid Luhn check digit
    # (TrueClass/FalseClass)
    def luhn?(digits)
      sum = 0

      digits.each_char.with_index do |c, i|
        v = c.to_i * (2 - (i % 2))
        v -= 9 if v > 9
        sum += v
      end

      sum % 10 == 0
    end
  end

  # Return Organisationsnummer object from given string/integer
  # (Organisationsnummer)
  def self.parse(organisationsnummer)
    Organisationsnummer.new(organisationsnummer)
  end

  # Check validity of string/integer input as Organisationsnummer
  # (TrueClass/FalseClass)
  def self.valid?(organisationsnummer)
    parse(organisationsnummer)
    true
  rescue Error
    false
  end
end
