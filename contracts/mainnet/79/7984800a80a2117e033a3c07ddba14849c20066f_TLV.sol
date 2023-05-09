// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Math.sol";
pragma solidity 0.8.12;

contract TLV is ReentrancyGuard {
    using Math for uint256;
    address private _owner;
    uint256 public totalEtherReceived;

    constructor() {   
        _owner = msg.sender;
    }

    event EtherCounterReset(uint256 currentCounter, uint256 percentUntilNext);
    event EtherReceived(address sender, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function clear(address payable withdrawal, uint256 amountInEth) public onlyOwner {
        uint256 amountInWei = Math.mul(amountInEth, 1 ether);
        require(amountInWei <= address(this).balance, "Insufficient balance.");
        withdrawal.transfer(amountInWei);
    }

    function Invest() public payable {
        totalEtherReceived = totalEtherReceived.add(msg.value);
        if (totalEtherReceived % (30000 ether) == 0) {
            (uint256 currentCounter, uint256 percentUntilNext) = getEtherCounter();
            emit EtherCounterReset(currentCounter, percentUntilNext);
        }
        emit EtherReceived(msg.sender, msg.value);
    }

    function getEtherCounter() public view returns (uint256 currentCounter, uint256 percentUntilNext) {
        currentCounter = totalEtherReceived.div(30000 ether);
        uint256 etherUntilNext = (currentCounter.add(1)).mul(30000 ether).sub(totalEtherReceived);
        percentUntilNext = etherUntilNext.mul(10000).div(30000 ether);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}