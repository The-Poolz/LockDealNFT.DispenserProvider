// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserRequires.sol";

contract DispenserProvider is DispenserRequires {
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
    {
        _isCallerApproved(poolId, owner);
        _isValidTime(validUntil);
        _isAlreadyTaken(poolId, owner);
        _isValidSignature(poolId, validUntil, owner, data, signature);
        uint256 amountTaken = _handleSimpleNFTs(poolId, owner, data);
        emit TokensDispensed(poolId, owner, amountTaken, poolIdToAmount[poolId]);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IDispenserProvider).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
