// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// import "@openzeppelin/contracts/access/Ownable.sol";

/*  custom errors  */

error VendingMachine__ownerProperties(address owner);
error VendingMachine__payMoreEth(uint amount);
error VendingMachine__NotEnoughDonut(uint remainDonut);
error VendingMachine__Limitation(uint limitation);
error VendingMachine__FaildToSendEth();

contract VendingMachine {
    /*  variables  */
    address public owner;
    uint public constant price = 0.00001 ether;
    uint public constant initialBalance = 100;

    mapping(address => uint256) public donutBalances;

    constructor() {
        owner = msg.sender;
        donutBalances[address(this)] = initialBalance;
    }

    // anyone should be able to set amount of donut
    // getting total balance

    modifier ownerProperties(address _user) {
        if (_user != owner) {
            revert VendingMachine__ownerProperties(owner);
        }
        _;
    }

    // because update the value --> don't use the view or pure
    function restock(uint256 _amount) external ownerProperties(msg.sender) {
        if (donutBalances[address(this)] + _amount > initialBalance) {
            revert VendingMachine__Limitation(initialBalance);
        }
        donutBalances[address(this)] += _amount;
    }

    // payable for receive ether
    function purchase(uint256 _amount) external payable {
        // we need to check purchaser send enough money

        if (msg.value < _amount * price) {
            revert VendingMachine__payMoreEth(_amount * price);
        }
        // enough donuts in the vending machine for requests

        if (donutBalances[address(this)] < _amount) {
            revert VendingMachine__NotEnoughDonut(donutBalances[address(this)]);
        }

        donutBalances[address(this)] -= _amount;
        donutBalances[msg.sender] += _amount;
        (bool success, ) = address(this).call{value: msg.value}("");
        if (!success) {
            revert VendingMachine__FaildToSendEth();
        }
    }

    /*  getter functions  */

    function getVendingMachineBalance() public view returns (uint256) {
        return donutBalances[address(this)];
    }

    function getBuyerBalancer() public view returns (uint256) {
        return donutBalances[msg.sender];
    }

    fallback() external payable {}

    receive() external payable {}
}

// for this smart contract
// i can refactore some functions

// like this function
// for checking the vending machine stocks we can use it, if i can do it we can skip it

// for not enough donate i can use it, it can be very good.