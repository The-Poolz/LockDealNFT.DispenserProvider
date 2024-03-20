// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockVaultManager {
    mapping(address => uint) public tokenToVaultId;
    mapping(uint256 => address) vaultIdtoToken;
    bool public transfers = true;
    uint256 public Id = 0;

    function safeDeposit(address _tokenAddress, uint _amount, address from, bytes memory signature) external returns (uint vaultId) {
        require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("signature")), "wrong signature");
        IERC20(_tokenAddress).transferFrom(from, address(this), _amount);
        vaultId = _depositByToken(_tokenAddress);
    }

    function _depositByToken(address _tokenAddress) internal returns (uint vaultId) {
        vaultId = ++Id;
        vaultIdtoToken[vaultId] = _tokenAddress;
        tokenToVaultId[_tokenAddress] = vaultId;
    }

    function withdrawByVaultId(uint _vaultId, address _to, uint _amount) external {
        IERC20(vaultIdtoToken[_vaultId]).transfer(_to, _amount);
    }

    function vaultIdToTokenAddress(uint _vaultId) external view returns (address) {
        return vaultIdtoToken[_vaultId];
    }
}
