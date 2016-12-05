# LoanCreator

`loan_creator` gem intends to provide a set of methods to allow automatic
generation of loan time tables, for simulation, from a lender point of view
and from a borrower point of view, regarding financial rounding differences.
As of today, the gem makes the borrower support any rounding issue. In a
later work, an option should be provided to decide who supports such issues.

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

There are four categories of loan, initiated with a `Common` class which inherits the following:
```ruby
    LoanCreator::Standard
    LoanCreator::Linear
    LoanCreator::Infine
    LoanCreator::Bullet
```
Each instance of one of the previous classes has the following attributes:
```ruby
    :amount_in_cents
    :annual_interests_rate
    :starts_at
    :duration_in_months
    :deferred_in_months (default to zero)
```

There is also a `TimeTable` class dedicated to record the data of the loans' terms.
Each instance of `LoanCreator::TimeTable` has the following attributes:
```ruby
    :term
    :monthly_payment
    :monthly_payment_capital_share
    :monthly_payment_interests_share
    :remaining_capital
    :paid_capital
    :remaining_interests
    :paid_interests
```

`end_date` common method intends to render loan end date based on two inputs:
`starts_at` and `duration_in_months`

`monthly_interests_rate` common method intends to render a precise calculation
of the loan monthly rate based on one input: `annual_interests_rate`, which is
the rate usually given when creating a loan or asking for a loan.

`lender_time_table(amount)` should be defined in each loan class. It renders
an array of `LoanCreator::TimeTable` ordered from first loan term to last one
based on a provided amount. It should be used for any lender of a loan.
It takes into account financial rounding differences and makes the borrower
support all those differences.

`time_table` is a specific use of `lender_time_table(amount)` with
amount defined as the whole loan amount (as if there were only one lender
for the full loan). It should be used for borrower simulation purpose.

`borrower_time_table(*args)` common method intends to sum each attribute of
each provided `lender_time_table` on each term and thus to provide an array of
`LoanCreator::TimeTable` ordered from first loan term to last one. It should
be used for the borrower of a loan, once all lenders and their lending amounts
are known. Based on `lender_time_table` method, it makes the borrower support
all financial rounding differences.

## Explanation

Standard loan generates time tables with constant payments.

Linear loan generates time tables with constant capital share payment.

Standard and linear loans may be deferred, i.e. capital repayment is delayed. Interests are to be payed normally during this period.

In fine loan generates time tables where terms' payments are composed by interests only.
Capital share shall be repaid in full at loan's end.

Bullet loan generates time tables where terms' payments are zero.
Interests are capitalized, i.e. added to the borrowed capital on each term.
Capital share shall be repaid in full and all interests paid at loan's end.

There is no deferred time for in fine and bullet loans as it is the same as increasing the loan duration.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/loan_creator.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
