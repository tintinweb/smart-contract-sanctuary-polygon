/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

pragma solidity 0.8.11;

/**
@title TrustFund
@author Jonathan Emig
*/
contract TrustFund {
    struct Beneficiary {
        address beneficiaryAddress;
        uint256 withdrawalDate;
        uint256 amount;
        bool withdrawn;
    }

    mapping(address => Beneficiary) public beneficiaries;

    event FundsDeposited(address indexed depositor, uint256 amount, uint256 withdrawalDate);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getFundsAmount(address beneficiaryAddress) external view returns (uint256) {
        return beneficiaries[beneficiaryAddress].amount;
    }

    function getFundsWithdrawalDate(address beneficiaryAddress) external view returns (uint256) {
        return beneficiaries[beneficiaryAddress].withdrawalDate;
    }

    function depositFunds(address beneficiaryAddress, uint256 withdrawalDate) external payable {
        require(beneficiaryAddress != address(0), "Invalid beneficiary address");
        require(withdrawalDate > block.timestamp, "Withdrawal date must be in the future");
        require(msg.value > 0, "Amount must be greater than zero");

        if (beneficiaries[beneficiaryAddress].amount == 0) { // only set the value if it hasn't been set yet
            beneficiaries[beneficiaryAddress] = Beneficiary(beneficiaryAddress, withdrawalDate, msg.value, false);
        } else {
            beneficiaries[beneficiaryAddress].amount += msg.value;
        }

        emit FundsDeposited(msg.sender, msg.value, withdrawalDate);
    }

    function withdrawFunds() external {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        require(beneficiary.amount != 0, "No funds available for withdrawal");
        require(!beneficiary.withdrawn, "Funds have already been withdrawn");
        require(block.timestamp >= beneficiary.withdrawalDate, "Withdrawal date has not yet passed");
        require(msg.sender == beneficiary.beneficiaryAddress, "Only the beneficiary can withdraw funds");

        beneficiary.withdrawn = true;
        payable(msg.sender).transfer(beneficiary.amount);

        emit FundsWithdrawn(msg.sender, beneficiary.amount);
    }
}