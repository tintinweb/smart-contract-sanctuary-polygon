/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

pragma solidity ^0.8.0;

contract Exchange {
    mapping(address => uint) public avaxBalances;
    mapping(address => uint) public ulandBalances;
    address public avaxAddress;
    address public ulandAddress;
    uint public exchangeRate;

    constructor(address _avaxAddress, address _ulandAddress, uint _exchangeRate) public {
    require(_exchangeRate > 0, "Invalid exchange rate");
    avaxAddress = _avaxAddress;
    ulandAddress = _ulandAddress;
    exchangeRate = _exchangeRate;
}

   

    function depositAvax() public payable {
        require(msg.value > 0, "Cannot deposit zero or negative value");
        avaxBalances[msg.sender] += msg.value;
    }

    function depositUland() public payable {
        require(msg.value > 0, "Cannot deposit zero or negative value");
        ulandBalances[msg.sender] += msg.value;
    }

 


    function swapAvaxForUland(uint avaxAmount) public {
        require(avaxBalances[msg.sender] >= avaxAmount, "Insufficient AVAX balance");
        avaxBalances[msg.sender] -= avaxAmount;
        ulandBalances[msg.sender] += avaxAmount;
    }

    function swapUlandForAvax(uint ulandAmount) public {
        require(ulandBalances[msg.sender] >= ulandAmount, "Insufficient ULAND balance");
        ulandBalances[msg.sender] -= ulandAmount;
        avaxBalances[msg.sender] += ulandAmount;
    }
}