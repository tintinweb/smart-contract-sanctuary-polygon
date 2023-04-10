// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// errors
error PaymentEscrow__NotArbiter();
error PaymentEscrow__TransactionUnsuccesful();

/**@title A Payment Escrow Contract
 * @author Ejim favour
 * @notice This contract ensures secure and credible payment for goods and services.
 */

contract PaymentEscrow {
    // state variables
    address public s_arbiter;
    address public s_beneficiary;
    address public s_payer;
    bool public s_isApproved;

    // events
    event Approved(
        address indexed payer,
        address indexed beneficiary,
        uint amount
    );

    event Payed(
        address indexed payer,
        address indexed beneficiary,
        uint amount
    );

    // modifiers
    modifier onlyArbiter() {
        if (msg.sender != s_arbiter) {
            revert PaymentEscrow__NotArbiter();
        }
        _;
    }

    // functions
    constructor(address _arbiter, address _beneficiary) payable {
        s_arbiter = _arbiter;
        s_beneficiary = _beneficiary;
        s_payer = msg.sender;

        emit Payed(msg.sender, _beneficiary, msg.value);
    }

    receive() external payable {}

    function approve() external onlyArbiter {
        uint balance = address(this).balance;

        uint fee = (address(this).balance / 1000) * 5;

        uint payedAmount = balance - (address(this).balance / 1000) * 5;

        (bool callSuccess, ) = s_beneficiary.call{value: payedAmount}("");

        if (!callSuccess) revert PaymentEscrow__TransactionUnsuccesful();

        (bool feeSuccess, ) = s_arbiter.call{value: fee}("");

        if (!feeSuccess) revert PaymentEscrow__TransactionUnsuccesful();

        emit Approved(s_payer, s_beneficiary, payedAmount);

        s_isApproved = true;
    }
}