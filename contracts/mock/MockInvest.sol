// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDispenserProvider.sol";

contract MockInvest {
    IDispenserProvider public dispenserProvider;

    constructor(IDispenserProvider _dispenserProvider) {
        dispenserProvider = _dispenserProvider;
    }

    function callDispenseLock(
        IDispenserProvider.MessageStruct calldata sigData,
        bytes calldata signature
    ) external {
        dispenserProvider.dispenseLock(sigData, signature);
    }
}
