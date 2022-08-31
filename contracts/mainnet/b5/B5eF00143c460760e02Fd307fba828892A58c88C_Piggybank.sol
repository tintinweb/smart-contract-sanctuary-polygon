/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

contract Piggybank {
    event Deposit(address sender, uint amount);
    event Withdraw(address receiver, uint amount);
    event Destroy(uint amount, string text);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    function depositEther() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawEther(address payable _to, uint _amount) external onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "probably no money in contract");
        emit Withdraw(_to, _amount);
    }

    function destroyContract(address _to) external onlyOwner{
        selfdestruct(payable(_to));
        emit Destroy(address(this).balance, "contract is destroyed");
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
    /*
    Next time create this: Also, you can do the same for deposit and withdraw. It is a little pain to do them with React&Ethers

    function getBalance() external view returns(uint) {
        uint balanceFinal = address(this).balance / (10**18);
        return balanceFinal;
    }
     */

    function getOwner() external view returns(address) {
        return owner;
    }

    function getContractAddress() external view returns(address) {
        return address(this);
    }
}