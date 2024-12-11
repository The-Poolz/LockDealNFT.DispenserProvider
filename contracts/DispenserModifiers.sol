// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserInternal.sol";

/// @title DispenserModifiers
/// @dev Contract for handling the revert logic during token dispensing operations in the Dispenser.
abstract contract DispenserModifiers is DispenserInternal {
    /// @notice Ensures the caller is either the owner or an approved address for the specified pool.
    /// @dev Reverts with a `CallerNotApproved` error if the caller is not the owner or approved.
    /// @param poolId The ID of the pool to verify the caller’s approval for.
    /// @param owner The address of the pool owner.
    /// @dev Reverts if the caller is neither the owner nor approved by the owner.
    modifier isCallerApproved(uint256 poolId, address owner) {
        if (
            !(owner == msg.sender ||
                lockDealNFT.ownerOf(poolId) == msg.sender ||
                lockDealNFT.isApprovedForAll(owner, msg.sender))
        ) {
            revert CallerNotApproved(msg.sender, owner, poolId);
        }
        _;
    }

    /// @notice Ensures that the `validUntil` timestamp is not in the past.
    /// @dev Reverts with an `InvalidTime` error if the `validUntil` timestamp is earlier than the current block timestamp.
    /// @param validUntil The timestamp until which the dispense is valid.
    /// @dev Reverts if the `validUntil` timestamp is in the past.
    modifier isValidTime(uint256 validUntil) {
        if (validUntil < block.timestamp) {
            revert InvalidTime(block.timestamp, validUntil);
        }
        _;
    }

    /// @notice Validates the signature provided for the dispense action.
    /// @dev Reverts with an `InvalidSignature` error if the signature is not valid.
    /// @param poolId The pool ID for the dispensation.
    /// @param validUntil The timestamp until which the dispensation is valid.
    /// @param owner The owner of the pool.
    /// @param data The data associated with the dispensation.
    /// @param signature The cryptographic signature to verify.
    modifier isValidSignature(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    ) {
        if (
            !(lockDealNFT.getData(poolId).owner == msg.sender ||
                _checkData(
                    poolId,
                    abi.encodePacked(
                        poolId,
                        validUntil,
                        owner,
                        _encodeBuilder(data)
                    ),
                    signature
                ))
        ) {
            revert InvalidSignature(poolId, owner);
        }
        _;
    }

    /// @notice Ensures that the tokens have not already been taken for the specified pool and owner.
    /// @dev Reverts with a `TokensAlreadyTaken` error if tokens have already been dispensed for the given pool and owner.
    /// @param poolId The pool ID to check.
    /// @param owner The owner to verify if tokens have already been dispensed.
    modifier isAlreadyTaken(uint256 poolId, address owner) {
        if (isTaken[poolId][owner]) {
            revert TokensAlreadyTaken(poolId, owner);
        }
        _;
    }
}
