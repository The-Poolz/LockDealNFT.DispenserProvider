// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./DispenserState.sol";

/// @title DispenserInternal
/// @dev Abstract contract that implements the logic for handling token dispensing and NFT management.
///      This contract is responsible for encoding builder data, handling simple NFTs, and ensuring the correct
///      amount of tokens are dispensed from the pool.
abstract contract DispenserInternal is DispenserState {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @notice Encodes an array of Builder structs into a single byte array.
    /// @param builder An array of Builder structs to be encoded.
    /// @return data The encoded byte array representing the Builders.
    function _encodeBuilder(
        Builder[] calldata builder
    ) internal pure returns (bytes memory data) {
        for (uint256 i = 0; i < builder.length; ++i) {
            data = _encodeBuilder(builder[i], data);
        }
    }

    /// @notice Encodes a single Builder struct into a byte array.
    /// @param builder A single Builder struct to be encoded.
    /// @param data The byte array to which the encoded builder will be appended.
    /// @return The updated byte array after encoding the builder.
    function _encodeBuilder(Builder calldata builder, bytes memory data) internal pure returns(bytes memory) {
        return abi.encodePacked(data, address(builder.simpleProvider), builder.params);
    }

    /// @notice Handles the dispensation of simple NFTs from a token pool.
    /// @dev Iterates through all Builders, dispensing the NFTs and finalizing the deal.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param owner The address of the owner requesting to dispense tokens.
    /// @param data An array of Builder structs containing the necessary data for each NFT to be dispensed.
    /// @return amountTaken The total amount of tokens dispensed from the pool.
    function _handleSimpleNFTs(
        uint256 tokenPoolId,
        address owner,
        Builder[] calldata data
    ) internal firewallProtectedSig(0x32aa97c4) returns (uint256 amountTaken) {
        for (uint256 i = 0; i < data.length; ++i) {
            amountTaken += _nftIterator(tokenPoolId, owner, data[i]);
        }
        _finalizeDeal(tokenPoolId, owner, amountTaken);
    }

    /// @notice Iterates through the NFTs and dispenses them from the pool.
    /// @dev Ensures that the amount taken is greater than 0 and performs the necessary actions to create and withdraw NFTs.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param owner The address of the owner requesting to dispense tokens.
    /// @param data The Builder struct containing the data for the NFT to be dispensed.
    /// @return amountTaken The amount of tokens dispensed for this NFT.
    function _nftIterator(
        uint256 tokenPoolId,
        address owner,
        Builder calldata data
    ) internal firewallProtectedSig(0x592181eb) returns (uint256 amountTaken) {
        amountTaken = data.params[0]; // calling function must check for an array of non-zero length
        if (amountTaken == 0) {
            revert AmountMustBeGreaterThanZero();
        }
        uint256 poolId = _createSimpleNFT(tokenPoolId, owner, data);
        if (lockDealNFT.isApprovedForAll(owner, address(this))) {
            _withdrawIfAvailable(poolId);
        }
    }

    /// @notice Finalizes the deal by ensuring the dispensed amount does not exceed the available tokens in the pool.
    /// @dev Updates the pool amount and marks the transaction as completed for the owner.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param owner The address of the owner requesting to dispense tokens.
    /// @param amountTaken The total amount of tokens dispensed from the pool.
    function _finalizeDeal(
        uint256 tokenPoolId,
        address owner,
        uint256 amountTaken
    ) internal firewallProtectedSig(0x52f83cd6) {
        if (amountTaken > poolIdToAmount[tokenPoolId]) {
            revert NotEnoughTokensInPool(amountTaken, poolIdToAmount[tokenPoolId]);
        }
        poolIdToAmount[tokenPoolId] -= amountTaken;
        isTaken[tokenPoolId][owner] = true;
    }

    /// @notice Creates a simple NFT for a given pool and owner.
    /// @param tokenPoolId The unique identifier for the token pool.
    /// @param owner The address of the owner requesting to mint the NFT.
    /// @param data The Builder struct containing the data for the NFT to be minted.
    /// @return poolId The unique identifier of the minted NFT.
    function _createSimpleNFT(
        uint256 tokenPoolId,
        address owner,
        Builder calldata data
    ) internal firewallProtectedSig(0xe64fbb17) returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, data.simpleProvider);
        data.simpleProvider.registerPool(poolId, data.params);
        lockDealNFT.cloneVaultId(poolId, tokenPoolId);
    }

    /// @notice Withdraws tokens from the provider if the withdrawable amount is greater than zero.
    /// @dev Transfers the NFT token from its owner to the `lockDealNFT` contract if there is a withdrawable amount
    /// @param poolId The unique identifier for the pool to withdraw from.
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
        return keccak256(data).toEthSignedMessageHash().recover(signature) == lockDealNFT.getData(poolId).owner;
    }
}
