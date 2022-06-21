v0.12.0
-------------------------
- improve argument error management and allow amount equal to zero.

v0.11.0
-------------------------
- add `multi_part_interests_calculation` option.

v0.10.0
-------------------------
- fix `term_dates` options, notably with `starts_on`.

v0.9.1
-------------------------
- add spec importer `scripts/convert_export_to_spec.rb {csv_url}`
- fix period interests rate for realistic duration period overlapping leap & non leap years

v0.9.0
-------------------------
- add possibility to pass the argument `term_dates` for `LoanCreator::Bullet`, `LoanCreator::InFine` and `LoanCreator::Linear`
- `term_dates` option is based on `realistic_durations` and allow to compute terms custom date to custom date

v0.8.2
-------------------------

- manage initial value `due_interests` for Linear and InFine loan types

v0.8.1
-------------------------
- add `realistic_durations` option

v0.8.0
-------------------------

#### Feature
- due interests to date are now store into `due_interests_` columns for `LoanCreator::UncapitalizedBullet`

#### Bugfix
- fix `initial_values` not taking `paid_capital` and `paid_interests` into account for `LoanCreator::UncapitalizedBullet`
  and `LoanCreator::Bullet`

#### Breaking changes
- rename columns `capitalized_interests_beginning_of_period` and `capitalized_interests_end_of_period` for
  `due_interests_beginning_of_period` and `due_interests_end_of_period`
- rename `capitalized_interests` option in `:inital_values` into `due_interests`


v0.7.1
-------------------------

- fix `index` for `borrower_timetable` method that did not take into account starting index of `lender_timetables`

v0.7.0
-------------------------

- change `capitalized_interests` for `capitalized_interests_beginning_of_period`
  and `capitalized_interests_end_of_period` in `LoanCreator::Term`
- add `capitalized_interests` in `:inital_values` for `LoanCreator::Bullet` loans

v0.6.2
-------------------------

- add `:initial_values` for loans initialization
- add and compute `capitalized_interests` for `LoanCreator::Bullet` terms

v0.6.1
-------------------------

- fix homepage url

v0.6.0
-------------------------

- add `LoanCreator::UncapitalizedBullet`

v0.5.0
-------------------------

- add `interests_start_date` in `LoanCreator::Common` attributes, replacing `first_term_date`

v0.3.0
-------------------------

- add `first_term_date` in `LoanCreator::Common` attributes

v0.2.3
-------------------------

- rename `starts_at` -> `starts_on`

v0.2.2
-------------------------

- rename `date` -> `due_on`

v0.2.1
-------------------------

- convert some options to their expected type by default

v0.2.0
-------------------------

- Huge rework : add `period`, rename `amount_in_cents` to `amount` and other breaking changes.
