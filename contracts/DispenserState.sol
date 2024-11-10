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
}
