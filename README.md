# token_rds

A Sui Move package implementing the RDS token standard with support for:

- Fix cap 1M token
- Can only mint once by owner
- Transferring full or partial amounts between addresses


## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)


## Prerequisites

- [Install Sui](https://docs.sui.io/build/install)


## Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/hieupd2/token-rds.git
   cd token-rds
   ```

2. Install dependencies and build

   ```powershell
   sui move build
   ```


## Running Tests

Execute all Move unit tests with:

```powershell
sui move test
```


## Test Coverage

Generate a coverage report with:

```powershell
sui move test --coverage
sui move coverage summary
```

