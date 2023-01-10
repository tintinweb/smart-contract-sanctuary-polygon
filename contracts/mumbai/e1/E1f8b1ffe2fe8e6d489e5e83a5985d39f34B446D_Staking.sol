//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Staking {
    // stores address of the deployer of the contract
    address public owner;

    // This stores the amount an individual stakes at a given length of time
    struct Position {
        uint256 positionId;
        address walletAddress; // Address that creates the position
        uint256 createdDate;
        uint256 unlockDate; // date which stake will be withdraw without encountering a penalty
        uint256 percentInterest;
        uint256 weiStaked;
        uint256 weiInterest;
        bool open; //Boolean to tell whether the position is open or not
    }

    Position position;

    // This increment after each position is created
    uint256 public currentPositionId;

    // Every newly created position is stored in this mapping
    mapping(uint256 => Position) public positions;

    // Helps the user track all the position they have created
    mapping(address => uint256[]) public positionIdsByAddress;

    // contains data about the number of days and the interest rate a user can stake ether at
    mapping(uint256 => uint256) public tiers;

    // contains the lock period for the interest rate (30,90,180 days)
    uint256[] public lockPeriods;

    event TokenStaked(address indexed from, uint256 indexed lockPeriod, uint256 amount);

    /**
     * @dev Set the constructor to Payable to allow the deployer send some ether to contract when its been deployed
     *  @dev this is required to enable the contract pay interest to other addresses
     */

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        // APY (Annual Percent Yield) the amount they will earn if they keep the stake locked in for a year time
        tiers[30] = 700; // 7%
        tiers[90] = 1000; // 10%
        tiers[180] = 1200; // 12%

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
    }

    /**
     * @dev This function is called when a user want to stake some ethers
     * @dev make the contract external so it can be called outside the contract and also payable so it can receive ethers
     * @param numDays - Number of days ether is being stake for
     */
    function stakeEther(uint256 numDays) external payable {
        require(tiers[numDays] > 0, "Mapping not found");

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            msg.value,
            calculateInterest(tiers[numDays], numDays, msg.value),
            true
        );

        // This object allows user to pass in their address and get the ids of the position that they own
        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
        emit TokenStaked(msg.sender, numDays, msg.value);

    }

    /**
    * @dev This function calculates the interest rate that the user want to stake their token
    * @param basisPoints is the interest amount the user want to receive when they stake their token
    * @param numDays is the num of days the user want to stake their token
    * @param weiAmount is the amount the user is willing to stake for the given period of time selected
     */

    function calculateInterest(
        uint256 basisPoints,
        uint256 numDays,
        uint256 weiAmount
    ) private pure returns (uint256) {
        return basisPoints * weiAmount / 10000; // 700 / 10000 = 0.07%
    }

    /**
     * @dev This function allows the contract owner to create new lock periods
     * @dev If the owner of the address pass in a numDays that has been declared already it overrides it with the new update and if it does not exist a new tiers[numDays]  is created with its basisPoints(interest rate)
     * @param numDays is the num of days the user want to stake their token
     * @param basisPoints is the interest amount the user want to receive when they stake their token
     */

    function modifyLockPeriods(uint256 numDays, uint256 basisPoints) external {
        require(owner == msg.sender, "Only owner may modify staking periods");

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    /**
     * @dev This function returns all Lock periods available for the contract
     */
    function getLockPeriods() external view returns (uint256[] memory) {
        return lockPeriods;
    }

    /**
     * @dev This function returns the interest rate for a particular number of days
     */
    function getInterestRate(uint256 numDays) external view returns (uint256) {
        return tiers[numDays];
    }

    /**
     * @dev This function returns the position of the amount of stake ether
     */

    function getPositionById(uint256 positionId)
        external
        view
        returns (Position memory)
    {
        return positions[positionId];
    }

    /**
     * @dev This function returns all the list of position id for a particular address
     */

    function getPositionIdsForAddress(address walletAddress)
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[walletAddress];
    }

    /**
     * @dev This function allows the owner change the unlock date for a position
     */

    function changeUnlockDate(uint256 positionId, uint256 newUnlockDate)
        external
    {
        require(owner == msg.sender, "Only owner may modify unlock dates");
        positions[positionId].unlockDate = newUnlockDate;
    }

    /**
     * @dev This function allows the user to unstake their ether
     */

    function closePosition(uint256 positionId) external {
        require(
            positions[positionId].walletAddress == msg.sender,
            "Only the position creator may modify position"
        );
        require(positions[positionId].open == true, "Position is close");

        positions[positionId].open = false;

        if (block.timestamp > positions[positionId].unlockDate) {
            uint256 amount = positions[positionId].weiStaked +
                positions[positionId].weiInterest;
            payable(msg.sender).call{value: amount}("");
        } else {
            payable(msg.sender).call{value: positions[positionId].weiStaked}(
                ""
            );
        }
    }
}