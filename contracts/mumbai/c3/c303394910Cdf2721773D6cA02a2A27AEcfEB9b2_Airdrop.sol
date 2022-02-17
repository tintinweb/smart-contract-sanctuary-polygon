/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address _recipient, uint256 _value)
        public
        returns (bool success);
}

contract Airdrop {
    address public owner;

    function Airdrop() public {
        owner = msg.sender;
    }

    function drop(
        ERC20 token,
        address[] recipients,
        uint256[] values
    ) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], values[i]);
        }
    }
}