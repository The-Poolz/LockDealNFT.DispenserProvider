// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ISimpleProvider.sol";

interface IDispenserProvider is ISimpleProvider {
    struct Builder {
        ISimpleProvider simpleProvider;
        uint256[] params;
    }

    function dispenseLock(
        uint256 poolId,
        uint256 validUntil,
        address owner,
        Builder[] calldata data,
        bytes calldata signature
    ) external;

    event TokensDispensed(uint256 poolId, address user, uint256 amountTaken, uint256 leftAmount);

    error CallerNotApproved(address caller, address owner, uint256 poolId);
    error InvalidTime(uint256 currentTime, uint256 validUntil);
    error InvalidSignature(uint256 poolId, address owner);
    error TokensAlreadyTaken(uint256 poolId, address owner);
    error AmountMustBeGreaterThanZero();
    error NotEnoughTokensInPool(uint256 requestedAmount, uint256 availableAmount);
}
