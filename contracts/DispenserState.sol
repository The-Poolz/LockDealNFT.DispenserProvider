// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDispenserProvider.sol";
import "@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider.sol";

/// @title DispenserState
/// @dev This contract maintains the state of token claim status for each pool and address.
abstract contract DispenserState is IDispenserProvider, DealProvider {
    /// @notice Tracks if tokens have been taken by a specific address for a specific pool ID.
    /// @dev The `isTaken` mapping uses `poolId` and `address` to store claim status.
    ///      Returns `true` if the user has already taken tokens from the pool, otherwise `false`.
    /// @return bool The claim status of the user in the pool.
    mapping(uint256 => mapping(address => bool)) public isTaken;

    /// @notice Hash of the message type for the EIP712 signature. Represented as:
    // keccak256(
    //     "MessageStruct(uint256 poolId,address receiver,uint256 validUntil,Builder[] data)Builder(address simpleProvider,uint256[] params)"
    // )
    bytes32 public constant MESSAGE_TYPEHASH = 0xc2a80ef40562cfc2e32b4a47b86995910d348d24ae413ebd09b6ecfbcf6b4f13;

    /// @notice Hash of the builder type for the EIP712 signature. Represented as:
    /// keccak256("Builder(address simpleProvider,uint256[] params)");
    bytes32 public constant BUILDER_TYPEHASH = 0xa5a2654c59a9d1110e55d822043f207b74f770a35ca104ce94fedba9a3dc5173;
}
