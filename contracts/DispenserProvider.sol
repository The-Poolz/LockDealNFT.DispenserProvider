// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserModifiers.sol";

/// @title DispenserProvider
/// @dev A contract that provides the functionality for dispensing tokens based on a locking mechanism.
///      This contract extends the functionality of `DispenserRequires` and interacts with `DealProvider`.
///      It allows users to dispense locked tokens from a specified pool after passing multiple validation checks.
contract DispenserProvider is DispenserModifiers {
    /// @param _lockDealNFT The address of the `ILockDealNFT` contract, which is used for handling NFT minting and vault management.
    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) EIP712("DispenserProvider", "1") {
        name = "DispenserProvider";
    }

    /// @notice Dispenses tokens from a locked pool based on provided data and signature.
    /// If the pool owner intends to dispense tokens to himself, using the Withdraw 
    /// or Split followed by Withdraw option is recommended. 
    /// This function supports dispensing tokens to any address specified by the owner.
    /// The signature provided is unique and can be used only once
    /// @dev Validates the caller's approval, the signature, the availability of tokens, and the lock time before dispensing.
    ///      If successful, it dispenses the tokens and emits an event.
    /// @param poolId The unique identifier for the pool from which tokens will be dispensed.
    /// @param validUntil The timestamp until which the transaction is valid. Must be greater than or equal to the current block time.
    /// @param receiver The address of the user who will receive the dispensed tokens.
    /// @param data An array of `Builder` structs containing the necessary data to perform the dispensing.
    /// @param signature A cryptographic signature validating the request from the specified owner.
    function dispenseLock(
        uint256 poolId,
        uint256 validUntil,
        address receiver,
        Builder[] calldata data,
        bytes calldata signature
    )
        external
        firewallProtected
        validProviderId(poolId)
        isAuthorized(poolId, receiver)
        isValidTime(validUntil)
        isUnclaimed(poolId, receiver)
        isValidSignature(poolId, validUntil, receiver, data, signature)
    {
        uint256 amountTaken = _handleSimpleNFTs(poolId, receiver, data);
        _finalizeDeal(poolId, receiver, amountTaken);

        emit TokensDispensed(
            poolId,
            receiver,
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
