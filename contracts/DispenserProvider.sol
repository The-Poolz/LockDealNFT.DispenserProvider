// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserModifiers.sol";

contract DispenserProvider is DispenserModifiers {
    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        name = "DispenserProvider";
    }

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
    {
        _isValidSignature(poolId, validUntil, owner, data, signature);
        _createSimpleNFTs(poolId, owner, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IDispenserProvider).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
