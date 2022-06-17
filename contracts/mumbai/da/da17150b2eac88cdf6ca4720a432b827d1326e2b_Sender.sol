/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-22
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint16 value) external returns (bool);
    function transferFrom(address from, address to, uint16 value) external returns (bool);
}


contract Sender {
    function Senderether(address[] recipients, uint16[] values) external payable {
        for (uint16 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
        msg.sender.transfer(balance);
    }

    function SenderToken(IERC20 token, address[] recipients, uint16[] values) external {
        uint16 total = 0;
        for (uint16 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

  
}