// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./DispenserState.sol";

/// @title DispenserInternal
/// @dev Abstract contract that implements the logic for handling token dispensing and NFT management.
///      This contract is responsible for encoding builder data, handling simple NFTs, and ensuring the correct
///      amount of tokens are dispensed from the pool.
abstract contract DispenserInternal is DispenserState, EIP712 {
    using ECDSA for bytes32;

    modifier notZeroValue(uint256 value) {
        if (value == 0) revert AmountMustBeGreaterThanZero();
        _;
    }

    /// @notice Encodes an array of Builder structs into a single byte array.
    /// @param builder An array of Builder structs to be encoded.
    /// @return builderData An array of bytes32 values representing the encoded builders.
    function _encodeBuilder(
        Builder[] calldata builder
    ) internal pure returns (bytes32[] memory builderData) {
        builderData = new bytes32[](builder.length);
        for (uint256 i = 0; i < builder.length; ++i) {
            builderData[i] = _encodeBuilder(builder[i]);
        }
    }

    /// @notice Encodes a single Builder struct into a byte array.
    /// @param builder A single Builder struct to be encoded.
    /// @return The updated byte array after encoding the builder.
    function _encodeBuilder(Builder calldata builder) internal pure returns(bytes32) {
        return keccak256(abi.encode(BUILDER_TYPEHASH, builder.simpleProvider, keccak256(abi.encodePacked(builder.params))));
    }

    /// @notice Handles the dispensation of simple NFTs from a token pool.
    /// @dev Iterates through all Builders, dispensing the NFTs and finalizing the deal.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param receiver The address of the user who will receive the dispensed tokens.
    /// @param data An array of Builder structs containing the necessary data for each NFT to be dispensed.
    /// @return amountTaken The total amount of tokens dispensed from the pool.
    /// `0x32aa97c4` - represent the bytes4(keccak256("_handleSimpleNFTs(uint256,address,(address,uint256[])[])"))
    function _handleSimpleNFTs(
        uint256 tokenPoolId,
        address receiver,
        Builder[] calldata data
    ) internal firewallProtectedSig(0x32aa97c4) returns (uint256 amountTaken) {
        for (uint256 i = 0; i < data.length; ++i) {
            if (data[i].params.length == 0) revert ZeroParamsLength();
            amountTaken += _nftIterator(tokenPoolId, receiver, data[i]);
        }
    }

    /// @notice Iterates through the NFTs and dispenses them from the pool.
    /// @dev Ensures that the amount taken is greater than 0 and performs the necessary actions to create and withdraw NFTs.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param receiver The address of the user who will receive the dispensed tokens.
    /// @param data The Builder struct containing the data for the NFT to be dispensed.
    /// @return amountTaken The amount of tokens dispensed for this NFT.
    /// `0x592181eb` - represent the bytes4(keccak256("_nftIterator(uint256,address,(address,uint256[]))"))
    function _nftIterator(
        uint256 tokenPoolId,
        address receiver,
        Builder calldata data
    ) internal firewallProtectedSig(0x592181eb) notZeroValue(data.params[0]) returns (uint256 amountTaken) {
        amountTaken = data.params[0];
        uint256 poolId = _createSimpleNFT(tokenPoolId, receiver, data);
        if (lockDealNFT.isApprovedForAll(receiver, address(this))) {
            _withdrawIfAvailable(poolId);
        }
    }

    /// @notice Finalizes the deal by ensuring the dispensed amount does not exceed the available tokens in the pool.
    /// @dev Updates the pool amount and marks the transaction as completed for the owner.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param receiver The address of the user who will receive the dispensed tokens.
    /// @param amountTaken The total amount of tokens dispensed from the pool.
    /// `0x52f83cd6` - represent the bytes4(keccak256("_finalizeDeal(uint256,address,uint256)"))
    function _finalizeDeal(
        uint256 tokenPoolId,
        address receiver,
        uint256 amountTaken
    ) internal firewallProtectedSig(0x52f83cd6) {
        if (amountTaken > poolIdToAmount[tokenPoolId]) {
            revert NotEnoughTokensInPool(amountTaken, poolIdToAmount[tokenPoolId]);
        }
        poolIdToAmount[tokenPoolId] -= amountTaken;
        isTaken[tokenPoolId][receiver] = true;
    }

    /// @notice Creates a simple NFT for a given pool and owner.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param receiver The address of the user who will receive the dispensed tokens.
    /// @param data The Builder struct containing the data for the NFT to be minted.
    /// @return poolId The unique identifier of the minted NFT.
    ///  `0xe64fbb17` - represent the bytes4(keccak256("_createSimpleNFT(uint256,address,(address,uint256[])))")
    function _createSimpleNFT(
        uint256 tokenPoolId,
        address receiver,
        Builder calldata data
    ) internal firewallProtectedSig(0xe64fbb17) returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(receiver, data.simpleProvider);
        data.simpleProvider.registerPool(poolId, data.params);
        lockDealNFT.cloneVaultId(poolId, tokenPoolId);
        emit PoolCreated(poolId, data.simpleProvider);
    }

    /// @notice Withdraws tokens from the provider if the withdrawable amount is greater than zero.
    /// @dev Transfers the NFT token from its owner to the `lockDealNFT` contract if there is a withdrawable amount
    /// @param poolId The unique identifier for the pool to withdraw from.
    /// `0xa7008a13`- represent bytes4(keccak256("_withdrawIfAvailable(uint256)"))
    function _withdrawIfAvailable(
        uint256 poolId
    ) internal firewallProtectedSig(0xa7008a13) {
        if (lockDealNFT.getWithdrawableAmount(poolId) > 0) {
            lockDealNFT.safeTransferFrom(lockDealNFT.ownerOf(poolId), address(lockDealNFT),poolId);
        }
    }

    /// @notice Verifies that the data and signature provided match the expected data for the given pool.
    /// @dev Checks that the provided signature matches the expected data hash for the pool and owner.
    /// @param poolId The unique identifier for the pool.
    /// @param data The data associated with the transaction.
    /// @param signature The cryptographic signature verifying the transaction.
    /// @return bool True if the signature is valid for the given data, otherwise false.
    function _checkData(
        uint256 poolId,
        bytes memory data,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(keccak256(data));
        address signer = ECDSA.recover(hash, signature);
        return signer == lockDealNFT.getData(poolId).owner;
    }
}
