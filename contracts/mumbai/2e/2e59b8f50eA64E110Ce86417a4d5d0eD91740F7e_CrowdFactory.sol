import "./crowdfundingproject.sol";

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

//contract to record all crowdfunding projects
contract CrowdFactory {
    address[] public publishedProjs;
    // wallet where all the fees will go. This value will be sent to all the contracts created with this factory. This setting cannot be changed.
    address public feeWalletAddr;
    uint256 public feePercentageAmount = 1500; // This number is represented in integers

    event ProjectCreated(
        string projTitle,
        uint256 goalAmount,
        address indexed ownerWalletAddr,
        address projAddress,
        address feeWalletAddr,
        uint256 indexed timestamp,
        uint64[8] stockPerTier,
        uint256[8] costPerTier
    );

    // Constructor needed to create the factory.
    constructor(address factoryOwnerAddr) {
        feeWalletAddr = factoryOwnerAddr;
    }

    function totalPublishedProjs() public view returns (uint256) {
        return publishedProjs.length;
    }

    function createProject(
        string memory projectTitle,
        string memory projDescript,
        uint256 projGoalAmount,
        uint64[8] memory stockPerTier_,
        uint256[8] memory costPerTier_,
        address projOwnerAddr
    ) public {
        //initializing CrowdfundingProject contract

        // Max value for free donation.
        stockPerTier_[7] = 2**64 - 1;
        costPerTier_[7] = 0;

        CrowdfundingProject newproj = new CrowdfundingProject(
            //passing arguments from constructor function
            projectTitle,
            projGoalAmount,
            projDescript,
            projOwnerAddr,
            feeWalletAddr,
            feePercentageAmount,
            stockPerTier_,
            costPerTier_
        );

        //pushing project address
        publishedProjs.push(address(newproj));

        //calling ProjectCreated (event above)
        emit ProjectCreated(
            projectTitle,
            projGoalAmount,
            msg.sender,
            address(newproj),
            feeWalletAddr,
            block.timestamp,
            stockPerTier_,
            costPerTier_
        );
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

contract CrowdfundingProject {
    //defining state variables
    string public projTitle;
    string public projDescription;
    uint256 public goalAmount;
    uint256 public raisedAmount;
    uint256 public transactionFee; // This fee will go to the feeWalletAddr. Percentage 0.05 = 500
    uint256 public numOfContributions; // Number of times people contributed to this project.
    uint64[8] stockPerTier; // This will represent the stock per tier at i index
    uint256[8] costPerTier; // This will represent the cost per tier at i index
    address ownerWalletAddr; // Wallet address of the Project Owner.
    address feeWalletAddr; // Address where amount to be transfered

    event Funded(
        address indexed donor,
        uint256 indexed totalAmount,
        uint256 indexed option,
        uint256 calculatedFeeAmount,
        uint256 donationAmount,
        uint256 timestamp
    );

    constructor(
        string memory projectTitle_,
        uint256 projGoalAmount_,
        string memory projDescript,
        address ownerWalletAddr_,
        address feeWalletAddr_,
        uint256 transactionFee_,
        uint64[8] memory stockPerTier_,
        uint256[8] memory costPerTier_
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
        require(option < 8, "Opt greader than 8");
        uint256 currentStockInTier = stockPerTier[option];
        require(currentStockInTier > 0, "No stock left");

        uint256 currentPriceofOption = costPerTier[option];
        require(
            currentPriceofOption <= msg.value,
            "Amount sent too low for selected opt."
        );

        // Calculated Fee amount that will go to the fee wallet.
        uint256 calculatedFeeAmount = msg.value / 50;
        uint256 donationAmount = msg.value - calculatedFeeAmount;

        //record walletaddress of donor
        (bool success, ) = payable(feeWalletAddr).call{
            value: calculatedFeeAmount
        }("");
        require(success, "fee NOT TRANSFERRED");

        //record walletaddress of donor
        (success, ) = payable(ownerWalletAddr).call{value: donationAmount}("");
        require(success, "donation NOT TRANSFERRED");

        //calculate total amount raised
        raisedAmount += donationAmount;
        numOfContributions = numOfContributions+1;
        currentStockInTier = currentStockInTier - 1;
        stockPerTier[option] = uint64(currentStockInTier);
        emit Funded(
            msg.sender,
            msg.value,
            option,
            calculatedFeeAmount,
            donationAmount,
            block.timestamp
        );
    }

    function getStocks() public view returns (uint64[8] memory s) {
        s = stockPerTier;
    }

    function getCosts() public view returns (uint256[8] memory c) {
        c = costPerTier;
    }
}