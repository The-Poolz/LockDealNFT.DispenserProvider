// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider.sol";
import "./interfaces/IDispenserProvider.sol";
import "./DispenserState.sol";

abstract contract DispenserInternal is IDispenserProvider, DealProvider, DispenserState {
    using ECDSA for bytes32;

    function _encodeBuilder(
        Builder[] calldata builder
    ) internal pure returns (bytes memory data) {
        for (uint256 i = 0; i < builder.length; ++i) {
            data = abi.encodePacked(data, address(builder[i].simpleProvider), builder[i].params);
        }
    }

    function _createSimpleNFTs(
        uint256 tokenPoolId,
        address owner,
        Builder[] calldata data
    ) internal {
        for (uint256 i = 0; i < data.length; ++i) {
            uint256 poolId = lockDealNFT.mintForProvider(owner, data[i].simpleProvider);
            data[i].simpleProvider.registerPool(poolId, data[i].params);
            lockDealNFT.cloneVaultId(poolId, tokenPoolId);
            poolIdToAmount[tokenPoolId] -= data[i].params[0];
            _withdrawIfAvailable(data[i].simpleProvider, poolId, owner);
        }
        isTaken[tokenPoolId][owner] = true;
    }

    function _withdrawIfAvailable(
        ISimpleProvider provider,
        uint256 poolId,
        address owner
    ) internal {
        if (provider.getWithdrawableAmount(poolId) > 0) {
            lockDealNFT.safeTransferFrom(owner, address(lockDealNFT), poolId);
        }
    }

    function _checkData(
        uint256 poolId,
        bytes memory data,
        bytes calldata signature
    ) internal view returns (bool) {
        return keccak256(data).toEthSignedMessageHash().recover(signature) == lockDealNFT.getData(poolId).owner;
    }
}
