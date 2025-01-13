// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserInternal.sol";

/// @title DispenserModifiers
/// @dev Contract for handling the revert logic during token dispensing operations in the Dispenser.
abstract contract DispenserModifiers is DispenserInternal {
    bytes32 MESSAGE_TYPEHASH =
        keccak256(
            "SigStruct(Builder[] data,uint256 poolId,address receiver,uint256 validUntil)Builder(address simpleProvider,uint256[] params)"
        );

    /// @notice Ensures that the caller is the receiver, owner, or approved by the receiver.
    /// @dev Reverts with a `CallerNotApproved` error if the caller is not receiver, owner or approved.
    /// @param poolId The ID of the pool to verify the caller’s approval for.
    /// @param receiver The address of the receiver of the tokens.
    modifier isAuthorized(uint256 poolId, address receiver) {
        if (
            !(_isReceiver(receiver) ||
                _isPoolOwner(poolId) ||
                _isApprovedByReceiver(receiver))
        ) {
            revert CallerNotApproved(msg.sender, receiver, poolId);
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
    modifier isValidSignature(
        SigStruct calldata sigData,
        bytes calldata signature
    ) {
        if (
            !_checkData(
                sigData.poolId,
                abi.encodePacked(
                    MESSAGE_TYPEHASH,
                    keccak256(abi.encodePacked(_encodeBuilder(sigData.data))),
                    sigData.poolId,
                    abi.encode(sigData.receiver),
                    sigData.validUntil
                ),
                signature
            )
        ) {
            revert InvalidSignature(sigData.poolId, sigData.receiver);
        }
        _;
    }

    /// @notice Ensures that the tokens have not already been taken for the specified pool and owner.
    /// @dev Reverts with a `TokensAlreadyTaken` error if tokens have already been dispensed for the given pool and owner.
    /// @param poolId The pool ID to check.
    /// @param receiver The address of the receiver to check.
    modifier isUnclaimed(uint256 poolId, address receiver) {
        if (isTaken[poolId][receiver]) {
            revert TokensAlreadyTaken(poolId, receiver);
        }
        _;
    }

    /// @notice Ensures that the caller is the receiver.
    /// @param receiver The address of the receiver to check.
    function _isReceiver(address receiver) private view returns (bool) {
        return receiver == msg.sender;
    }

    /// @notice Ensures that the caller is the owner of the dispenser pool.
    /// @param poolId The pool Id to check.
    function _isPoolOwner(uint256 poolId) private view returns (bool) {
        return lockDealNFT.ownerOf(poolId) == msg.sender;
    }

    /// @notice Ensures that the caller is approved by the receiver.
    /// @param receiver The address of the receiver to check.
    function _isApprovedByReceiver(
        address receiver
    ) private view returns (bool) {
        return lockDealNFT.isApprovedForAll(receiver, msg.sender);
    }
}
