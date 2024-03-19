// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DispenserState.sol";
import "@poolzfinance/lockdeal-nft/contracts/SimpleProviders/Provider/ProviderModifiers.sol";

abstract contract DispenserView is DispenserState, ProviderModifiers {
    function getParams(uint256 poolId) external override view returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = leftAmount[poolId]; 
    }

    function getWithdrawableAmount(uint256 poolId) external override view returns (uint256 amount) {
        amount = leftAmount[poolId];
    }    
}
