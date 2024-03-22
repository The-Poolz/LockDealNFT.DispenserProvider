// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserInternal.sol";

contract DispenserProvider is DispenserInternal {
    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        name = "DispenserProvider";
    }

    function createLock(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes memory signature
    ) external validProviderId(poolId) {
        require(
            msg.sender == owner ||
                lockDealNFT.getApproved(poolId) == msg.sender ||
                lockDealNFT.isApprovedForAll(owner, msg.sender),
            "DispenserProvider: Caller is not approved"
        );
        require(
            validUntil >= block.timestamp,
            "DispenserProvider: Invalid validUntil"
        );
        require(!isTaken[poolId][owner], "DispenserProvider: Tokens already taken");
        // Check the signature
        bytes memory dataToCheck = abi.encodePacked(
            poolId,
            validUntil,
            owner,
            _encodeBuilder(data)
        );
        require(
            _checkData(poolId, dataToCheck, signature),
            "DispenserProvider: Invalid signature"
        );
        _createSimpleNFTs(poolId, owner, data);
        isTaken[poolId][owner] = true;
    }
}
