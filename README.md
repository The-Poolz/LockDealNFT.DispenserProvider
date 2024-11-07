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

-   **Token Pool Creation:** Allows the creation of token pools, storing tokens for later distribution.
-   **Token Dispensing:** Locks tokens for a specified recipient using a signature-based authorization.
-   **Integration with Multiple Providers:** Works with other provider contracts like LockDealProvider, DealProvider, and TimedDealProvider.
-   **Events and Notifications:** Emits events for tracking token distributions and errors.

## Contracts diagram

![classDiagram](https://github.com/user-attachments/assets/3b1d1012-7784-4d5d-b6f1-221cfa88868f)

## Create Dispenser Pool

`createNewPool` function is used to create a new token pool with specific parameters. This function accepts an array of addresses, an array of pool parameters, and a signature from the pool owner. It interacts with the `LockDealNFT` contract to mint and transfer the tokens, register the pool.

```solidity
    /**
     * @dev Creates a new pool with the specified parameters.
     * @param addresses[0] The address of the pool owner.
     * @param addresses[1] The address of the token associated with the pool.
     * @param params An array of pool parameters.
     * @param signature The signature of the pool owner.
     * @return poolId The ID of the newly created pool.
     */
    function createNewPool(
        address[] calldata addresses,
        uint256[] calldata params,
        bytes calldata signature
    )
        external
        returns (uint256 poolId);
```

### Typescript example

To interact with the `createNewPool` function from a TypeScript script, you can use the following example. Ensure you have installed the necessary dependencies such as ethers, hardhat, and appropriate network configuration.

```typescript
import { ethers } from "hardhat"

const amount = ethers.parseUnits("10", 18)
const tokenAddress = await token.getAddress()
const addresses = [await signer.getAddress(), tokenAddress]
const params = [amount]
const nounce = await vaultManager.nonces(fromAddress)
const creationSignature = await ethers.provider
    .getSigner()
    .signMessage(
        ethers.utils.arrayify(
            ethers.utils.solidityKeccak256(["address", "uint256", "uint256"], [tokenAddress, amount, nounce])
        )
    )
await token.approve(await vaultManager.getAddress(), amount)
await dispenserProvider.createNewPool([ownerAddress, tokenAddress], params, creationSignature)
```

## Dispense Lock

`dispenseLock` function is responsible for dispensing tokens from a pool to the specified owner based on predefined rules. It ensures that the caller is authorized, the request is valid, and that the signature provided matches the expected one. This function handles simple NFTs and emits an event when tokens are dispensed.

```solidity
    /**
     * @dev Dispenses tokens from the pool to the specified owner.
     * @param poolId The ID of the pool from which tokens are dispensed.
     * @param validUntil The time until which the dispensation is valid.
     * @param owner The address of the pool owner receiving the dispensed tokens.
     * @param data An array of Builder structs containing the details of the NFTs to be handled.
     * @param signature The signature of the pool owner authorizing the dispensation.
     */
function dispenseLock(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    ) external;
```

### TypeScript Example

To interact with the dispenseLock function in a TypeScript script, you can use the following example. Ensure that you have the necessary dependencies installed (ethers, hardhat, etc.), and adjust network configurations accordingly.

```typescript
import { ethers } from "hardhat"

const amount = ethers.parseUnits("10", 18)
const poolId = 1 // Example pool ID
const ONE_DAY = 86400
const validTime = (await time.latest()) + ONE_DAY
let userData: IDispenserProvider.BuilderStruct = {
    simpleProvider: await lockProvider.getAddress(), // or any simple provider.
    params: [amount / 2n, validTime],
}
let usersData: IDispenserProvider.BuilderStruct[] = [userData]
const signatureData = [poolId, validTime, await user.getAddress(), userData]
const signature = await createSignature(signer, signatureData)
await dispenserProvider.dispenseLock(poolId, validTime, await user.getAddress(), usersData, signature)

async function createSignature(signer: SignerWithAddress, data: any[]): Promise<string> {
    const types: string[] = []
    const values: any[] = []
    for (const element of data) {
        if (typeof element === "string") {
            types.push("address")
            values.push(element)
        } else if (typeof element === "object" && Array.isArray(element)) {
            types.push("uint256[]")
            values.push(element)
        } else if (typeof element === "number" || typeof element === "bigint") {
            types.push("uint256")
            values.push(element)
        } else if (typeof element === "object" && !Array.isArray(element)) {
            types.push("address")
            values.push(element.simpleProvider)
            types.push("uint256[]")
            values.push(element.params)
        }
    }
    const packedData = ethers.solidityPackedKeccak256(types, values)
    return signer.signMessage(ethers.getBytes(packedData))
}
```

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/blob/master/LICENSE).
