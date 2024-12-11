// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ISimpleProvider.sol";

/// @title IDispenserProvider
/// @dev Interface for the Dispenser provider, responsible for dispensing tokens from a pool
///      and interacting with simple providers for NFT handling.
interface IDispenserProvider is ISimpleProvider {
    /// @dev Represents the data required to handle a token dispensation.
    /// @param simpleProvider The provider that handles the token dispensation logic.
    /// @param params Additional parameters required for dispensing the tokens.
    struct Builder {
        ISimpleProvider simpleProvider;
        uint256[] params;
    }

    /// @notice Dispenses tokens from the pool to the specified user.
    /// @dev Validates the provider, checks the signature, and processes the dispensation logic for the given pool.
    /// @param poolId The unique identifier for the pool.
    /// @param validUntil The timestamp until which the dispense is valid.
    /// @param receiver The address of the user receiving the tokens.
    /// @param data The array of Builder structs containing provider and parameters data.
    /// @param signature The cryptographic signature verifying the validity of the transaction.
    function dispenseLock(
        uint256 poolId,
        uint256 validUntil,
        address receiver,
        Builder[] calldata data,
        bytes calldata signature
    ) external;

    /// @notice Emitted when tokens are dispensed from the pool to a user.
    /// @param poolId The unique identifier for the pool.
    /// @param user The address of the user receiving the tokens.
    /// @param amountTaken The amount of tokens dispensed from the pool.
    /// @param leftAmount The remaining amount of tokens in the pool after dispensation.
    event TokensDispensed(uint256 poolId, address user, uint256 amountTaken, uint256 leftAmount);

    error CallerNotApproved(address caller, address receiver, uint256 poolId);
    error InvalidTime(uint256 currentTime, uint256 validUntil);
    error InvalidSignature(uint256 poolId, address receiver);
    error TokensAlreadyTaken(uint256 poolId, address receiver);
    error AmountMustBeGreaterThanZero();
    error NotEnoughTokensInPool(uint256 requestedAmount, uint256 availableAmount);
}
