# LoanCreator

`loan_creator` gem intends to provide a set of methods to allow automatic generation of loan timetables, for simulation, from a lender point of view and from a borrower point of view, regarding financial rounding differences. As of today, the gem makes the borrower support any rounding issue. In a later work, an option should be provided to decide who supports such issues.

Link to Loan_Creator excel simulator [Click here] (Excel)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'loan_creator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install loan_creator

## Usage

Parent module

```ruby
    module LoanCreator
```

There are four types of loans. All inherit from a `LoanCreator::Common` class.

```ruby
    LoanCreator::Standard
    LoanCreator::Linear
    LoanCreator::InFine
    LoanCreator::Bullet
```

Each instance of one of the previous classes has the following attributes:

```ruby
    :period
    :amount
    :annual_interests_rate
    :starts_at
    :duration_in_periods
    :deferred_in_periods (default to zero)
    :first_term_date (optional)
```

There is also a `LoanCreator::Timetable` class dedicated to record the data of the loans' terms. Each instance of `LoanCreator::Timetable` represents an array of `LoanCreator::Term` records, each having the following attributes:

```ruby
      # Term number (starts at 1)
      :index

      # Term date
      :date

      # Remaining due capital at the beginning of the term
      :crd_beginning_of_period

      # Remaining due capital at the end of the term
      :crd_end_of_period

      # Theoricaly due interests
      :period_theoric_interests

      # Difference between theorical and real (rounded) due interests
      :delta_interests

      # Accrued interests' delta
      :accrued_delta_interests

      # Adjustment of -0.01 0 or +0.01 cent depending on accrued_delta_interests
      :amount_to_add

      # Interests to pay this term
      :period_interests

      # Capital to pay this term
      :period_capital

      # Total capital paid so far (including current term)
      :total_paid_capital_end_of_period

      # Total interests paid so far (including current term)
      :total_paid_interests_end_of_period

      # Amount to pay this term
      :period_amount_to_pay
```

`#periodic_interests_rate` renders a precise calculation of the loan's periodic interests rate based on two inputs: `#annual_interests_rate` and `#period`.

`#lender_timetable` shall be defined in each loan class. It renders an instance of `LoanCreator::Timetable` which contains an ascending order array of `LoanCreator::Term`. It takes into account financial rounding differences and makes the borrower
support all those differences.

`.borrower_timetable(*lenders_timetables)` (class method) intends to sum each attribute of each provided `lender_timetable` on each term and thus to provide an ascending order array of `LoanCreator::Term`. It should be used for the borrower of a loan, once all lenders and their lending amounts
are known. It makes the borrower support all financial rounding differences.

## Example

```ruby
loan_creator = LoanCreator::Standard.new(
  period: :year,
  amount: 42_000,
  annual_interests_rate: 4,
  starts_on: '2019-03-01',
  duration_in_periods: 5,
  deferred_in_periods: 1,
  first_term_date: '2019-02-10'
)
loan_creator.lender_timetable
# => #<LoanCreator::Timetable:0x0000000003198bd0 @terms=[...] ...>
loan_creator.lender_timetable.terms.first
# => #<LoanCreator::Term:0x00000000030f1a88 @crd_beginning_of_period=0.42e5,
# [...] @period_amount_to_pay=0.8745e2, @index=0, @due_on=Sun, 10 Feb 2019>
````

## Explanation

### Classes

`Standard` loan generates terms with constant payments.

`Linear` loan generates terms with constant capital share payment.

`Standard` and `Linear` loans may be capital-deferred, i.e. capital repayment is delayed.\
Interests are to be payed normally during this period.

`InFine` loan generates terms where terms' payments are composed by interests only.\
Capital share shall be repaid in full at loan's end.

`Bullet` loan generates terms where terms' payments are zero. \
Interests are capitalized, i.e. added to the borrowed capital on each term.\
Capital share shall be repaid in full and all interests paid at loan's end.

There is no deferred time for `InFine` and `Bullet` loans as it would be equivalent to increasing loan's duration.

### Attributes

`period`: A `Symbol`. `:month`, `:quarter`, `:semester` or `:year`.

`duration_in_periods`: An `Integer`.

`amount`: Any number that can be converted to `BigDecimal`.

`annual_interests_rate`: In percentage. Any number that can be converted to `BigDecimal`.

`starts_at`: A `Date`, or a `String` that can be parsed.

`deferred_in_periods`: Optional. An `Integer`, smaller than `duration_in_periods`. Number of periods during which no
capital is refunded, only interest. Only relevant for `Standard` and `Linear` loans.

`first_term_date`: Optional. To be used when the loan starts before the first full term date. This then compute an
additional term with only interests for the time difference.  
For example, with a `start_at` in january 2020 and a `first_term_date` in october 2019, the timetable will include a
first term corresponding to 3 months of interests.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/loan_creator.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
