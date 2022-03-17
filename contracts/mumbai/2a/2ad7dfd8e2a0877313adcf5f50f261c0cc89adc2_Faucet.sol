/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IERC20 {
  function balanceOf(address owner) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
}

contract Faucet {

    address immutable owner;
    mapping(address => bool) used;
    event SentMonies(address reciever);

    // IERC20 public token = IERC20(0xbe49ac1EadAc65dccf204D4Df81d650B50122aB2); // fUSDC on rinkeby
    IERC20 public token = IERC20(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e); // USDC on mumbai

    constructor () {
        owner = msg.sender;
    }
    
    function getBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getMonies() public {
        uint amount = 300*(10**6);
        
        require(used[msg.sender] == false, "sorry, you have already used the faucet");
        require(amount <= getBalance(), "not enough monies in the reserve, pleaz donate!");

        used[msg.sender] = true;
        token.transfer(msg.sender, amount);

        emit SentMonies(msg.sender);
    }    

    function withdrawMonies() public {
        require(msg.sender == owner, "only owner can withdraw!");
        require(getBalance() >= 0, "no monies left");

        token.transfer(msg.sender, getBalance());
    }

}