# organisationsnummer [![Build Status](https://github.com/organisationsnummer/ruby/workflows/build/badge.svg)](https://github.com/organisationsnummer/ruby/actions)

Validate Swedish organization numbers. Follows version 1.1 of the [specification](https://github.com/organisationsnummer/meta#package-specification-v11).

A personal identity number is also a valid organization number. The gem uses the [personnummer](https://github.com/personnummer/ruby) gem for those.

## Installation

Add this to your `Gemfile`

```
gem 'organisationsnummer'
```

Then run `bundle install`

## Example

A company number:

```ruby
require 'organisationsnummer'

Organisationsnummer.valid?("556016-0680")
# => true

org = Organisationsnummer.parse("5560160680")
org.format           # => "556016-0680"
org.format(false)    # => "5560160680"
org.type             # => "Aktiebolag"
org.vat_number       # => "SE556016068001"
org.is_personnummer? # => false
org.personnummer     # => nil
```

A personal identity number:

```ruby
org = Organisationsnummer.parse("900101-0017")
org.type             # => "Enskild firma"
org.vat_number       # => "SE900101001701"
org.is_personnummer? # => true
org.personnummer     # => a Personnummer::Personnummer
org.personnummer.get_date.to_s # => "1990-01-01"
```

`parse` raises `Organisationsnummer::Error` when the input is not a valid number. The input can be a string or an integer, other input is invalid.

### Rules

- The input is ten digits with an optional `-` or `+` before the last four. A leading `16` is allowed and removed.
- The first two digits are 10 or higher and the third and fourth digit are 20 or higher.
- The last digit is a Luhn check digit.
- Anything else is parsed as a personal identity number, with the default options of the `personnummer` gem.

See [test/test_organisationsnummer.rb](test/test_organisationsnummer.rb) for more examples.

## In memoriam

Fredrik "Frozzare" Forsmo (1991-2026) was the initiator, co-founder and a core contributor of the organisationsnummer project. This library carries his work. He is missed.

## License

MIT
