// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider.sol";
import "./interfaces/IDispenserProvider.sol";
import "./DispenserState.sol";

abstract contract DispenserInternal is IDispenserProvider, DealProvider, DispenserState {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    function _encodeBuilder(
        Builder[] calldata builder
    ) internal pure returns (bytes memory data) {
        for (uint256 i = 0; i < builder.length; ++i) {
            data = _encodeBuilder(builder[i], data);
        }
    }

    function _encodeBuilder(Builder calldata builder, bytes memory data) internal pure returns(bytes memory) {
        return abi.encodePacked(data, address(builder.simpleProvider), builder.params);
    }

    function _handleSimpleNFTs(
        uint256 tokenPoolId,
        address owner,
        Builder[] calldata data
    ) internal returns (uint256 amountTaken) {
        for (uint256 i = 0; i < data.length; ++i) {
            amountTaken += _nftIterator(tokenPoolId, owner, data[i]);
        }
        _finalizeDeal(tokenPoolId, owner, amountTaken);
    }

    function _nftIterator(
        uint256 tokenPoolId,
        address owner,
        Builder calldata data
    ) internal returns (uint256 amountTaken) {
        amountTaken = data.params[0]; // calling function must check for an array of non-zero length
        if (amountTaken == 0) {
            revert AmountMustBeGreaterThanZero();
        }
        uint256 poolId = _createSimpleNFT(tokenPoolId, owner, data);
        _withdrawIfAvailable(data.simpleProvider, poolId, owner);
    }

    function _finalizeDeal(uint256 tokenPoolId, address owner, uint256 amountTaken) internal {
        if (amountTaken > poolIdToAmount[tokenPoolId]) {
            revert NotEnoughTokensInPool(amountTaken, poolIdToAmount[tokenPoolId]);
        }
        poolIdToAmount[tokenPoolId] -= amountTaken;
        isTaken[tokenPoolId][owner] = true;
    }

    function _createSimpleNFT(
        uint256 tokenPoolId,
        address owner,
        Builder calldata data
    ) internal returns(uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, data.simpleProvider);
        data.simpleProvider.registerPool(poolId, data.params);
        lockDealNFT.cloneVaultId(poolId, tokenPoolId);
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
