Feature: Satoshi Calculator

  Scenario Outline: btc2satoshi
    Given a btc value of "<btc>"
    When I ask for it to be converted to satoshi
    Then it should return "<satoshi>" satoshi

    Examples:
      |   btc      |    satoshi  |
      | 0.0036     |     360000  |
      | -0.0036    |    -360000  |
      | 1.2987     |  129870000  |
      | 12.2       | 1220000000  |
      | 12.2       | 1220000000  |
      | 0.00000001 |          1  |
      | 0.00065468 |      65468  |

  Scenario Outline: satoshi2btc
    Given a satoshi value of "<satoshi>"
    When I ask for it to be converted to decimal btc
    Then it should return "<btc>" btc

    Examples:
      |    satoshi  |    btc      |
      |     360000  |  0.00360000 |
      |    -360000  | -0.00360000 |
      |  129870000  |  1.29870000 |
      | 1220000000  | 12.20000000 |
      |-1220000000  |-12.20000000 |
      |          1  |  0.00000001 |
      |      65468  |  0.00065468 |
