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
