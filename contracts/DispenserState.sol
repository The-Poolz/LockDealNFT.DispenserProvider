// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ILockDealNFT.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IVaultManager.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ISimpleProvider.sol";

contract DispenserState {
    mapping(uint256 => mapping(address => bool)) public isTaken;
    mapping(uint256 => uint256) public leftAmount;

    struct Builder {
        ISimpleProvider simpleProvider;
        uint256[] params;
    }
}
