/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BaserampLiqudityManager {
    address public _liquidityProvider;
    address public _withdrawer;

    constructor(address liquidityProvider, address withdrawer) {
        _liquidityProvider = liquidityProvider;
        _withdrawer = withdrawer;
    }

    function provideLiquidity() payable public {
        require(
            msg.sender == _liquidityProvider
        );
    }

    struct Transaction {
        uint amount;
        address payable destination;
    }

    function settleTransactions(Transaction[] calldata transactions) public {
        require(msg.sender == _withdrawer);

        for (uint8 i = 0; i < transactions.length; i++) {
            Transaction calldata transaction = transactions[i];
            settleTransaction(transaction);
        }
    }

    function settleTransaction(Transaction calldata transaction) private {
        require(
            address(this).balance >= transaction.amount,
            "insufficient balance"
        );

        (bool sent, ) = transaction.destination.call{ value: transaction.amount, gas: 0 }("");

        // Ignore the return value and continue. We don't want a single broken
        // receiver to be able to cause the entire batch to fail.
    }

    function balance() public view returns (uint) {
        uint returnedBalance = address(this).balance;
        return returnedBalance;
    }

    function drain() public {
        require(msg.sender == _liquidityProvider);
        payable(msg.sender).transfer(address(this).balance);
    }
}