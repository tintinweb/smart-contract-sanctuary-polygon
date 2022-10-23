/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// File: contracts/etherBridge.sol


pragma solidity ^0.8.0;

interface IERC20{
    function mint(address account,uint256 amount) external;
    function burn(address account,uint256 amount) external;
}

contract EBridge is IERC20{
    IERC20  public token;
    constructor(address _token) {
        token = IERC20(_token);
    }

    function mint(address account, uint256 amount) public{
        token.mint(account, amount);
    }

function burn(address account, uint256 amount) public{
        token.mint(account, amount);
    }

}