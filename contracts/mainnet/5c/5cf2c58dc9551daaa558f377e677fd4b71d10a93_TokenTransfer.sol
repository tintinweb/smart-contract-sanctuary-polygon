/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

contract TokenTransfer {
    address public tokenAddress;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferTokens(address[] memory _addresses, uint256[] memory _amounts, address _tokenaddress) external {
        require(_addresses.length == _amounts.length, "Arrays length mismatch");

        IERC20 token = IERC20(_tokenaddress);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Invalid address");
            totalAmount += _amounts[i];
        }

        require(token.approve(address(this),totalAmount),"token not approved");
	require(token.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed");
	
        for (uint256 i = 0; i < _addresses.length; i++) {
            _amounts[i] = _amounts[i];
            require(token.transfer(_addresses[i], _amounts[i]), "Token transfer failed");
        }
    }


    function withdrawTokens(address tokenaddress) external {
        require(msg.sender == owner, "Only owner can call this function");

        IERC20 token = IERC20(tokenaddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(token.transfer(owner, contractBalance), "Token transfer failed");
    }
}