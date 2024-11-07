# LockDealNFT.DispenserProvider

[![Build and Test](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/actions/workflows/node.js.yml/badge.svg)](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/actions/workflows/node.js.yml)
[![codecov](https://codecov.io/gh/The-Poolz/LockDealNFT.DispenserProvider/branch/master/graph/badge.svg?token=s2B22Bif9x)](https://codecov.io/gh/The-Poolz/LockDealNFT.DispenserProvider)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/LockDealNFT.DispenserProvider/badge)](https://www.codefactor.io/repository/github/the-poolz/LockDealNFT.DispenserProvider)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/blob/master/LICENSE)

**DispenserProvider** contract is part of a system designed to manage and dispense tokens from a pool in response to approved requests. It allows creating token pools and locking tokens for distribution according to predefined conditions

### Navigation

-   [Installation](#installation)
-   [Overview](#overview)
-   [UML](#contracts-diagram)
-   [Create Dispenser pool](#create-dispenser-pool)
-   [Dispense Lock](#dispense-lock)

## Installation

**Install the packages:**

```console
npm i
```

**Compile contracts:**

```console
npx hardhat compile
```

**Run tests:**

```console
npx hardhat test
```

**Run coverage:**

```console
npx hardhat coverage
```

**Deploy:**

```console
npx truffle dashboard
```

```console
npx hardhat run ./scripts/deploy.ts --network truffleDashboard
```

## Overview

The `DispenserProvider` contract manages token dispensing in collaboration with `LockDealNFT`, `Simple Providers`, and `VaultManager` contracts. It creates token pools, locks tokens, and distributes them based on predefined rules set by these providers.

### Key Features
* **Token Pool Creation:** Allows the creation of token pools, storing tokens for later distribution.
* **Token Dispensing:** Locks tokens for a specified recipient using a signature-based authorization.
* **Integration with Multiple Providers:** Works with other provider contracts like LockDealProvider, DealProvider, and TimedDealProvider.
* **Events and Notifications:** Emits events for tracking token distributions and errors.


## Contracts diagram

## Create Dispenser Pool

## Dispense Lock

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/blob/master/LICENSE).
