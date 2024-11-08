// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserModifiers.sol";

/// @title DispenserProvider
/// @dev A contract that provides the functionality for dispensing tokens based on a locking mechanism.
///      This contract extends the functionality of `DispenserRequires` and interacts with `DealProvider`.
///      It allows users to dispense locked tokens from a specified pool after passing multiple validation checks.
contract DispenserProvider is DispenserModifiers {
    /// @param _lockDealNFT The address of the `ILockDealNFT` contract, which is used for handling NFT minting and vault management.
    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        name = "DispenserProvider";
    }

    /// @notice Dispenses tokens from a locked pool based on provided data and signature.
    /// @dev Validates the caller's approval, the signature, the availability of tokens, and the lock time before dispensing.
    ///      If successful, it dispenses the tokens and emits an event.
    /// @param poolId The unique identifier for the pool from which tokens will be dispensed.
    /// @param validUntil The timestamp until which the transaction is valid. Must be greater than or equal to the current block time.
    /// @param owner The address of the owner requesting to dispense tokens from the pool.
    /// @param data An array of `Builder` structs containing the necessary data to perform the dispensing.
    /// @param signature A cryptographic signature validating the request from the specified owner.
    function dispenseLock(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    )
        external
        validProviderId(poolId)
        isCallerApproved(poolId, owner)
        isValidTime(validUntil)
        isAlreadyTaken(poolId, owner)
        isValidSignature(poolId, validUntil, owner, data, signature)
    {
        uint256 amountTaken = _handleSimpleNFTs(poolId, owner, data);

        emit TokensDispensed(
            poolId,
            owner,
            amountTaken,
            poolIdToAmount[poolId]
        );
    }

    /// @notice Determines if the contract supports a specific interface.
    /// @dev Checks if the interface ID matches the `IDispenserProvider` or `IERC165` interface.
    /// @param interfaceId The interface identifier to check for compatibility.
    /// @return bool True if the contract supports the specified interface, otherwise false.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IDispenserProvider).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
