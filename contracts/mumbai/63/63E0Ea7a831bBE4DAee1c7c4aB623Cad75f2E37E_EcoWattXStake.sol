//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EcoWattXStake {
    // stores address of the deployer of the contract
    address public owner;

    // This stores the amount an individual stakes at a given length of time
    struct Asset {
        uint256 positionId;
        address walletAddress; // Address that creates the position
        uint256 createdDate;
        uint256 unlockDate; // date which stake will be withdraw without encountering a penalty
        uint256 percentInterest;
        uint256 weiStaked;
        uint256 weiInterest;
        bool open; //Boolean to tell whEWX the position is open or not
    }

    Asset position;

    uint256 public currentPositionId;

    // Every newly created position is stored in this mapping
    mapping(uint256 => Asset) public positions;

    // Helps the user track all the position they have created
    mapping(address => uint256[]) public assetIdsByAddress;

    // contains data about the number of days and the interest rate a user can stake EWX at
    mapping(uint256 => uint256) public plans;

    // contains the lock period for the interest rate (30,90,180 days)
    uint256[] public stakePeriod;

    event TokenStaked(address indexed from, uint256 indexed lockPeriod, uint256 amount);

    /**
     * Set the constructor to Payable to allow the deployer send some EWX to contract when its been deployed
     * this is required to enable the contract pay interest to other addresses
     */

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        // APY (Annual Percent Yield) the amount they will earn if they keep the stake locked in for a year time
        plans[30] = 200;
        plans[60] = 300;
        plans[90] = 500;
        plans[180] = 700;
        plans[365] = 1000;

        stakePeriod.push(30);
        stakePeriod.push(60);
        stakePeriod.push(90);
        stakePeriod.push(180);
        stakePeriod.push(365);
    }

    
    //This function is called when a user want to stake some EWXs
    function stakeEWX(uint256 numDays) external payable {
        require(plans[numDays] > 0, "Mapping not found");

        positions[currentPositionId] = Asset(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            plans[numDays],
            msg.value,
            calculateAPY(plans[numDays], msg.value),
            true
        );

        // This object allows user to pass in their address and get the ids of the position that they own
        assetIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
        emit TokenStaked(msg.sender, numDays, msg.value);

    }

    
    //Calculates the interest rate that the user want to stake their token
    function calculateAPY(
        uint256 apy,
        uint256 weiAmount
    ) private pure returns (uint256) {
        return apy * weiAmount / 10000; // 700 / 10000 = 0.07%
    }

    
    //This function allows the contract owner to create new lock periods

    function changeStakingDuration(uint256 numDays, uint256 apy) external {
        require(owner == msg.sender, "Only owner may modify staking periods");

        plans[numDays] = apy;
        stakePeriod.push(numDays);
    }

    
    //This function returns all Lock periods available for the contract
    function getStakingDurations() external view returns (uint256[] memory) {
        return stakePeriod;
    }

    
    //This function returns the interest rate for a particular number of days
    function getInterestRate(uint256 numDays) external view returns (uint256) {
        return plans[numDays];
    }

    
    //This function returns the position of the amount of stake EWX
    function getPositionById(uint256 positionId)
        external
        view
        returns (Asset memory)
    {
        return positions[positionId];
    }

 
    //This function returns all the list of position id for a particular address

    function getPositionIdsForAddress(address walletAddress)
        external
        view
        returns (uint256[] memory)
    {
        return assetIdsByAddress[walletAddress];
    }

 
    //This function allows the owner change the unlock date for a position
    function changeUnlockDate(uint256 positionId, uint256 newUnlockDate)
        external
    {
        require(owner == msg.sender, "Only owner may modify unlock dates");
        positions[positionId].unlockDate = newUnlockDate;
    }


    //This function allows the user to unstake their EWX
    function closePosition(uint256 positionId) external {
        require(
            positions[positionId].walletAddress == msg.sender,
            "Only the position creator may modify position"
        );
        require(positions[positionId].open == true, "Asset is already closed");

        positions[positionId].open = false;

        if (block.timestamp > positions[positionId].unlockDate) {
            uint256 amount = positions[positionId].weiStaked +
                positions[positionId].weiInterest;
            payable(msg.sender).call{value: amount};
        } else {
            payable(msg.sender).call{value: positions[positionId].weiStaked};
        }
    }
}