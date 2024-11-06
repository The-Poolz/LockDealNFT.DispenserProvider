// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserInternal.sol";

abstract contract DispenserReverts is DispenserInternal {
    function _isCallerApproved(uint256 poolId, address owner) internal view {
        if (
            msg.sender != owner &&
            lockDealNFT.getApproved(poolId) != msg.sender &&
            !lockDealNFT.isApprovedForAll(owner, msg.sender)
        ) {
            revert CallerNotApproved(msg.sender, owner, poolId);
        }
    }

    function _isValidTime(uint256 validUntil) internal view {
        if (validUntil < block.timestamp) {
            revert InvalidTime(block.timestamp, validUntil);
        }
    }

    function _isValidSignature(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    ) internal view {
        if (
            !_checkData(
                poolId,
                abi.encodePacked(poolId, validUntil, owner, _encodeBuilder(data)),
                signature
            )
        ) {
            revert InvalidSignature(poolId, owner);
        }
    }

    function _isAlreadyTaken(uint256 poolId, address owner) internal view {
        if (isTaken[poolId][owner]) {
            revert TokensAlreadyTaken(poolId, owner);
        }
    }
}
