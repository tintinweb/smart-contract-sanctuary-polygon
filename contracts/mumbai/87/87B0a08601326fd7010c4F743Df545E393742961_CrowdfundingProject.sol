// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

contract CrowdfundingProject {
    //defining state variables
    string public projTitle;
    string public projDescription;
    uint256 public goalAmount;
    uint256 public raisedAmount;
    uint256 public transactionFee; // This fee will go to the feeWalletAddr. Percentage 0.05 = 500
    uint64[8] public stockPerTier; // This will represent the stock per tier at i index
    uint128[8] public costPerTier; // This will represent the cost per tier at i index
    address ownerWalletAddr; // Wallet address of the Project Owner.
    address feeWalletAddr; // Address where amount to be transfered


    event Funded(
        address indexed donor,
        uint256 indexed totalAmount,
        uint256 indexed option,
        uint256  calculatedFeeAmount,
        uint256  donationAmount,        
        uint256  timestamp
    );

    constructor(
        string memory projectTitle_,
        uint256 projGoalAmount_,
        string memory projDescript,
        address ownerWalletAddr_,
        address feeWalletAddr_,
        uint256 transactionFee_,
        uint64[8] memory stockPerTier_,
        uint128[8] memory costPerTier_
    ) {
        //mapping values
        projTitle = projectTitle_;
        goalAmount = projGoalAmount_;
        projDescription = projDescript;
        ownerWalletAddr = ownerWalletAddr_;
        feeWalletAddr = feeWalletAddr_;
        stockPerTier = stockPerTier_;
        costPerTier = costPerTier_;
        transactionFee = transactionFee_;
    }

    //donation function
    function makeDonation(uint256 option) public payable {
        //if goal amount is achieved, close the proj
        require(goalAmount > raisedAmount, "Goal Achieved");
        require(option <8, "Opt greader than 8");
        uint256 currentStockInTier = stockPerTier[option];
        require(currentStockInTier >0, "No stock left");

        // Calculated Fee amount that will go to the fee wallet.
        uint256 calculatedFeeAmount = msg.value / (10000 * transactionFee);
        uint256 donationAmount = msg.value - calculatedFeeAmount;

        //record walletaddress of donor
        (bool success, ) = payable(feeWalletAddr).call{value: calculatedFeeAmount}("");
        require(success, "fee NOT TRANSFERRED");

        //record walletaddress of donor
        (success, ) = payable(ownerWalletAddr).call{value: donationAmount}("");
        require(success, "donation NOT TRANSFERRED");

        //calculate total amount raised
        raisedAmount += donationAmount;

        currentStockInTier=currentStockInTier-1;
        stockPerTier[option] = uint64(currentStockInTier);
        emit Funded(msg.sender, msg.value,option,calculatedFeeAmount,donationAmount,block.timestamp);
    }
}