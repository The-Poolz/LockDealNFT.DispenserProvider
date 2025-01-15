# LockDealNFT.DispenserProvider

[![Build and Test](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/actions/workflows/node.js.yml/badge.svg)](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/actions/workflows/node.js.yml)
[![codecov](https://codecov.io/gh/The-Poolz/LockDealNFT.DispenserProvider/branch/master/graph/badge.svg?token=s2B22Bif9x)](https://codecov.io/gh/The-Poolz/LockDealNFT.DispenserProvider)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/LockDealNFT.DispenserProvider/badge)](https://www.codefactor.io/repository/github/the-poolz/LockDealNFT.DispenserProvider)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/blob/master/LICENSE)

**DispenserProvider** contract is part of a system designed to manage and dispense tokens from a pool in response to approved requests. It allows creating token pools and locking tokens for distribution according to predefined conditions

### Audit report

The audit report is available here: [Audit Report](https://docs.google.com/document/d/1jOZR6fjlFECY7Or9taxpsHXea8OQwgHGA5R3yQumuMQ/edit?tab=t.0)

### Navigation

-   [Installation](#installation)
-   [Overview](#overview)
-   [Use case](#use-case)
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

## Use case

Every **IDO** goes through three stages:

1. **Registration.**
2. **Participation.**
3. **Token Distribution.**

**Dispenser Provider** is responsible for the third stage: **Token Distribution**.

Currently, the **Registration** stage is managed by the **Backend**, which sends a verification signature for registration to the **IDO**. When users decide to participate and have already registered, they need to purchase **IDO** tokens during the **Participation** stage. At this point, the [**InvestProvider**](https://github.com/The-Poolz/LockDealNFT.InvestProvider) contract takes action.

After the **Participation** stage, the **project owner** receives a list of participants along with their investment information. Based on this data, the total supply of required **IDO** tokens is calculated. The **project owner** then creates a new **dispenser pool** with this total amount, which will be used for distribution.

Every user who has registered and participated in the **IDO** can obtain a signature from the **Backend**, containing data related to their token distribution. The signature is valid for a limited time, can only be used once, and users cannot request multiple signatures. The signature may be **public**. Even if someone else obtains the signature, they cannot use it on their behalf. The signature is bound to the intended recipient, ensuring that only the rightful user can claim the associated tokens. Additionally, the receiver has the option to delegate the `dispenseLock` call to an approved address.

When the **User** receives the signature, they can claim **IDO** tokens using it. As a result, after the `dispenseLock` call, the receiver will receive locked tokens based on the **IDO** conditions.

![DispenserProvider_-_use_case](https://github.com/user-attachments/assets/0cbaef4f-cb9f-4b50-84cc-06cc90e9c987)

_This picture illustrates the relationships between actors and processes._

## Contracts diagram

![classDiagram](https://github.com/user-attachments/assets/69bdad49-51e0-41bd-ab40-a6495cbbd814)

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

**Testnet example call:** [BSC Testnet Transaction](https://testnet.bscscan.com/tx/0xc280793846ae9a205e1e574416054e1088f477ccf7da1bd4710438f9887a6071)

**Function selector:** `0x14877c38`

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

`dispenseLock` function is responsible for dispensing tokens from a pool to the specified receiver based on predefined rules. It ensures that the caller is authorized, the request is valid, and that the signature provided matches the expected one. This function handles simple NFTs and emits an event when tokens are dispensed.

To call this function, caller must have the pool owner's signature, be the recipient or an approved representative of the recipient, or the pool owner can call it on behalf of a specific user. Upon successful execution, the recipient will receive locked tokens from simple providers.

```solidity
    /// @notice Dispenses tokens from a locked pool based on provided data and signature.
    /// If the pool owner intends to dispense tokens to himself, using the Withdraw
    /// or Split followed by Withdraw option is recommended.
    /// This function supports dispensing tokens to any address specified by the owner.
    /// The signature provided is unique and can be used only once
    /// @dev Validates the caller's approval, the signature, the availability of tokens, and the lock time before dispensing.
    ///      If successful, it dispenses the tokens and emits an event.
    /// @param message The message struct containing the pool ID, receiver address, data, and validUntil timestamp.
    /// @param signature The signature provided by the pool owner to validate the message.
    function dispenseLock(
        MessageStruct calldata message,
        bytes calldata signature
    )
```

**EIP-712 JSON** signature format: https://github.com/The-Poolz/LockDealNFT.DispenserProvider/issues/60#issuecomment-2582469583

**Testnet example call:** [BSC Testnet Transaction](https://testnet.bscscan.com/tx/0x86869217eff90469297574324c0153f3786500ee064e469fd896c3387d3ac7cd)

**Function selector:** `0xad43114e`

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
const signatureData: IDispenserProvider.MessageStructStruct = {
    poolId: poolId,
    receiver: await receiver.getAddress(),
    validUntil: validTime,
    data: usersData,
}
const signature = await createEIP712Signature(
    poolId,
    await receiver.getAddress(),
    validTime,
    signer,
    await dispenserProvider.getAddress(),
    usersData
)
await dispenserProvider.dispenseLock(signatureData, signature)

async function createEIP712Signature(
    poolId: bigint,
    receiver: string,
    validUntil: number,
    signer: SignerWithAddress,
    contractAddress: string,
    data: IDispenserProvider.BuilderStruct[]
): Promise<string> {
    const domain = {
        name: "DispenserProvider",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: contractAddress,
    }
    const types = {
        Builder: [
            { name: "simpleProvider", type: "address" },
            { name: "params", type: "uint256[]" },
        ],
        MessageStruct: [
            { name: "poolId", type: "uint256" },
            { name: "receiver", type: "address" },
            { name: "validUntil", type: "uint256" },
            { name: "data", type: "Builder[]" },
        ],
    }
    const value = {
        data: data,
        poolId: poolId.toString(),
        receiver: receiver,
        validUntil: validUntil,
    }

    // Use signTypedData to create the signature
    return await signer.signTypedData(domain, types, value)
}
```

## License

[The-Poolz](https://poolz.finance/) Contracts is released under the [MIT License](https://github.com/The-Poolz/LockDealNFT.DispenserProvider/blob/master/LICENSE).
