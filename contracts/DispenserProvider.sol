// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./DispenserView.sol";

contract DispenserProvider is DispenserView {
    using ECDSA for bytes32;

    constructor(ILockDealNFT _lockDealNFT) {
        require(
            address(_lockDealNFT) != address(0),
            "DispenserProvider: Invalid lockDealNFT address"
        );
        name = "DispenserProvider";
        lockDealNFT = _lockDealNFT;
    }

    function deposit(
        address signer,
        IERC20 tokenAddress,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256 poolId) {
        require(
            signer != address(0),
            "DispenserProvider: Invalid signer address"
        );
        require(
            address(tokenAddress) != address(0),
            "DispenserProvider: Invalid token address"
        );
        require(amount > 0, "DispenserProvider: Invalid amount");
        poolId = lockDealNFT.safeMintAndTransfer(
            signer,
            address(tokenAddress),
            msg.sender,
            amount,
            this,
            data
        );
        uint256[] memory params = new uint256[](1);
        params[0] = amount;
        _registerPool(poolId, params);
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    )
        external
        onlyProvider
        validProviderId(poolId)
        validParamsLength(params.length, currentParamsTargetLength())
    {
        _registerPool(poolId, params);
    }

    function _registerPool(uint256 poolId, uint256[] memory params) internal {
        leftAmount[poolId] = params[0];
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
            leftAmount[tokenPoolId] -= data[i].params[0];
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

    function withdraw(uint256) external pure override returns (uint256, bool) {
        require(false, "DispenserProvider: Not implemented yet");
    }

    function split(uint256, uint256, uint256) external pure override {
        require(false, "DispenserProvider: Not implemented yet");
    }
}
