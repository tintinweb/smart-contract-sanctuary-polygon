/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

pragma solidity ^0.8.7;

///SPDX-License-Identifier: MIT

contract SplitPayFactory {
    mapping (address => address[]) public ownedContracts;


    function getSum(uint[] memory array) public pure returns(uint) {
        uint sum = 0;
    
        for (uint i = 0; i < array.length; i++) {
            sum = sum + array[i];
        }

        return sum;
    }

    function createSplitPay (address[] memory owners, uint[] memory shares) public {
        require(owners.length <= 5);
        require(owners.length == shares.length);
        require(getSum(shares) == 100);

        address newSplitPay = address(new Splitpay(owners, shares));

        for (uint i = 0; i < owners.length; i++) {
            ownedContracts[owners[i]].push(newSplitPay);
        }
    }

    function getDeployedContracts(address owner) public view returns (address[] memory) {
        return ownedContracts[owner];
    }
}

contract Splitpay {
    address[] public owners;
    uint[] public shares;

    constructor (address[] memory initOwners, uint[] memory initShares) {
        owners = initOwners;
        shares = initShares;
    }

    function withdraw() public payable {
        uint balance = address(this).balance/100;

        for (uint i = 0; i < owners.length; i++) {
            uint value = balance*shares[i];
            address owner = owners[i];
            payable(owner).transfer(value); 
        }
    }

    function deposit(uint value) public payable {
        require(msg.value >= value);
    }
}