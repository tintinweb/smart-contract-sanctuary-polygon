/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

pragma solidity ~0.8.13;

interface ERC20 {
    function transferFrom(address owner, address to, uint256 amount) external;
}

contract Vault {
    function deposit(address token, uint256 amount) external {
        ERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}