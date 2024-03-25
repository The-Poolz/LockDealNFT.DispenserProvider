// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserInternal.sol";

abstract contract DispenserRequires is DispenserInternal {
    function _isCallerApproved(uint256 poolId, address owner) internal view {
        require(
            msg.sender == owner ||
                lockDealNFT.getApproved(poolId) == msg.sender ||
                lockDealNFT.isApprovedForAll(owner, msg.sender),
            "DispenserProvider: Caller is not approved"
        );
    }

    function _isValidTime(uint256 validUntil) internal view {
        require(
            validUntil >= block.timestamp,
            "DispenserProvider: Invalid validUntil"
        );
    }

    function _isValidSignature(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    ) internal view {
        require(
            _checkData(
                poolId,
                abi.encodePacked(
                    poolId,
                    validUntil,
                    owner,
                    _encodeBuilder(data)
                ),
                signature
            ),
            "DispenserProvider: Invalid signature"
        );
    }

    function _isAlreadyTaken(uint256 poolId, address owner) internal view {
        require(
            !isTaken[poolId][owner],
            "DispenserProvider: Tokens already taken"
        );
    }
}
