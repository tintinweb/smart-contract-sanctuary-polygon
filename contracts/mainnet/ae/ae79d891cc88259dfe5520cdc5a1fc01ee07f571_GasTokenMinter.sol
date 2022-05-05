/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

interface Gastoken {
    function mint(uint256 value) external;
}

contract GasTokenMinter {
    address GasTokenAddress;
    address owner = address(0x75D0e28cedc1F7Ed31af3E045980e086fd32E0Ce);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function setGasTokenAddress(address gasTokenAddress) external onlyOwner {
        GasTokenAddress = gasTokenAddress;
    }
    
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function mintGasToken() external onlyOwner {
        Gastoken(GasTokenAddress).mint(100);
        IERC20(GasTokenAddress).transfer(msg.sender, IERC20(GasTokenAddress).balanceOf(address(this)));
    }
}