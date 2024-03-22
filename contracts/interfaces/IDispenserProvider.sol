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
}
