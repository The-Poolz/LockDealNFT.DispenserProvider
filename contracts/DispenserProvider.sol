// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider.sol";
import "./DispenserState.sol";

contract DispenserProvider is DealProvider, DispenserState {
    using ECDSA for bytes32;

    event TokensDispensed(uint256 poolId, address user, bool isTaken, uint256 leftAmount);

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
        emit TokensDispensed(poolId, owner, true, poolIdToAmount[poolId]);
    }

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
        bytes memory signature
    ) internal view returns (bool success) {
        address signer = lockDealNFT.getData(poolId).owner;
        bytes32 hash = keccak256(data).toEthSignedMessageHash();
        address recoveredSigner = hash.recover(signature);
        success = recoveredSigner == signer;
    }
}
