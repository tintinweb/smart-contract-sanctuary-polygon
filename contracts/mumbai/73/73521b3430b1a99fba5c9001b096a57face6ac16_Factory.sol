/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


/// @title Community contract
contract Community {
    uint256 public requiredStackingAmount = 1.5 ether;
    uint256 public communityCounter;
    address public ownerTreasuryAddress;

    struct communityDetail {
        uint256 totalCommunityStack;
        uint256 stackingStartTime;
        uint256 stackingDuration;
        uint256 maxUsersCap;
        uint256 totalParticipatedUsers;
        address communityOwner;
        mapping(uint256 => address) users;
        mapping(uint256 => address) winners;
        mapping(uint256 => uint256) winnersPrizePercent;
        mapping(address => uint256) winnersPrizeAmount;
        // mapping(address => uint256) usersStackingAmount;
        mapping(address => bool) isUserParticipated;
    }

    communityDetail public newCommunityDetail;
    // mapping (uint256 => communityDetail) public communityDetails;

    /**
     * @notice Initializes a new community contract
     * @dev _Owner address can't be the contract address 
     * @param _Owner The address of the community owner
     * @param _ownerTreasuryAddress The address where the treasury funds will be transferred
     * @param _communityCounter The counter for the community
     * @param _maxUsersCap The maximum number of users that can participate in the community
     * @param _stackingDuration The duration of the stacking period
     * @param _winnersPrizePercent An array containing the prize percentages for each winner
     */
    constructor(
        address _Owner,
        address _ownerTreasuryAddress,
        uint256 _communityCounter,
        uint256 _maxUsersCap,
        uint256 _stackingDuration,
        uint256[] memory _winnersPrizePercent
    ) {
        require (_Owner.code.length<=0,"Owner can't be contract address.");
        require(_winnersPrizePercent.length<=3,"Limit exceeds!");
        communityCounter = _communityCounter;
        newCommunityDetail.communityOwner = _Owner;
        ownerTreasuryAddress=_ownerTreasuryAddress;
        newCommunityDetail.maxUsersCap = _maxUsersCap;
        newCommunityDetail.stackingStartTime = block.timestamp;
        newCommunityDetail.stackingDuration = _stackingDuration;

        for (uint256 i; i < _winnersPrizePercent.length; i++) {
            newCommunityDetail.winnersPrizePercent[i + 1] = _winnersPrizePercent[i];
        }
    }

    modifier onlyOwner() {
        require(
            msg.sender == newCommunityDetail.communityOwner,
            "Only owner can access"
        );
        _;
    }

    /**
     * @notice Stack required stacking amount and participate in community
     * @dev Any user can stack and participate in community   
     */
    function stackAmount() public payable {
        require(block.timestamp <(newCommunityDetail.stackingStartTime) + newCommunityDetail.stackingDuration,"Stacking time is over");
        require(msg.value > 0, "amount should be greater then zero");
        require(msg.value == requiredStackingAmount,"amout should be equal to requireStackingAmount");
        require(newCommunityDetail.isUserParticipated[msg.sender]==false,"You are already participated");
        require(newCommunityDetail.totalParticipatedUsers < newCommunityDetail.maxUsersCap,"User limit reached!");

        newCommunityDetail.totalParticipatedUsers += 1;
        newCommunityDetail.users[newCommunityDetail.totalParticipatedUsers] = msg.sender;
        newCommunityDetail.isUserParticipated[msg.sender] = true;
        // newCommunityDetail.usersStackingAmount[msg.sender] = msg.value;
        newCommunityDetail.totalCommunityStack += (msg.value-0.5 ether);
        payable(ownerTreasuryAddress).transfer(0.5 ether); 
    }

    /**
     * @notice Declare community winners and distributing winner's prize amount
     * @dev Only community owner can call this function
     * @param _winners An array containing the winners addresses       
     */
    function declareCommunityWinner(address[] memory _winners) external onlyOwner {

        require(_winners.length<=3,"Limit exceeds!");

        for (uint256 i; i < _winners.length; i++) {
            require(newCommunityDetail.isUserParticipated[_winners[i]] == true,"Winner is not participant of this community");
            newCommunityDetail.winners[i + 1] = _winners[i];

            newCommunityDetail.winnersPrizeAmount[newCommunityDetail.winners[i + 1]] =
                ((newCommunityDetail.totalCommunityStack) *
                    newCommunityDetail.winnersPrizePercent[i + 1]) /100;

            payable(_winners[i]).transfer(
                newCommunityDetail.winnersPrizeAmount[_winners[i]]
            );
        }

        newCommunityDetail.totalCommunityStack=0;        
    }

    /**
     * @notice Set a require stacking amount
     * @dev Update requiredStackingAmount state variable and only community owner can call this function
     * @param amount An amount to set as require stacking amount
     */
    function setRequiredStackingAmount(uint256 amount) external  onlyOwner {
        require(amount>=1.5 ether,"Amount should be greater then or Equal to 1.5 ether.");
        requiredStackingAmount = amount;
    }

    /**
     * @notice Set an owner's treasury address
     * @dev Update an ownerTreasuryAddress state variable and only community owner can call this function
     * @param treasuryAddress An address for set as treasuryAddress
     */
    function setTreasuryAddress(address treasuryAddress ) external onlyOwner{
        ownerTreasuryAddress=treasuryAddress;
    }

    /**
     * @notice Set a prize percentages for distributing winner's prize amount
     * @dev Update winnersPrizePercent state variable declare inside struct and only community owner can call this function
     * @param _winnersPrizePercent An array containing winner's prize percentages
     */
    function setWinnersPrizePercent(uint256[] memory _winnersPrizePercent) external  onlyOwner {
        require(_winnersPrizePercent.length<=3,"Limit exceeds!");
        require(_winnersPrizePercent[0]+_winnersPrizePercent[1]+_winnersPrizePercent[2]==100,"Total percentage must be equal to 100");
        for (uint256 i; i < _winnersPrizePercent.length; i++) {
            newCommunityDetail.winnersPrizePercent[i + 1] = _winnersPrizePercent[i];
        }
    }

    /**
     * @notice Retrieves the total staked amount in community
     * @return Total staked community amount
     */
    function getTotalCommunityStack() external  view returns (uint256) {
        return newCommunityDetail.totalCommunityStack;
    }

    /**
     * @notice Retrieves the maximum user can stack and participate in community 
     * @return Maximum user cap number
     */
    function getMaxUserCap() external  view returns (uint256) {
        return newCommunityDetail.maxUsersCap;
    }

    /**
     * @notice Retrieves the total number of user participated in community
     * @return Total number of user participated in community
     */
    function getTotalParticipatedUsers() external  view returns (uint256) {
        return newCommunityDetail.totalParticipatedUsers;
    }

    /**
     * @notice Retrieves the owner of community
     * @return Community owner
     */
    function communityOwner() external view returns (address) {
        return newCommunityDetail.communityOwner;
    }

    /**
     * @notice Retrieves the user by index number from total community users
     * @param num Index number of user which one to retrieve
     * @return user address
     */
    function getUsers(uint256 num) external view returns(address){
        return newCommunityDetail.users[num];
    } 

    /**
     * @notice Retrieves the winner by index number
     * @param num Index number of winner which one to retrieve
     * @return winner address
     */
    function getWinners(uint256 num) external  view returns(address) {
        return newCommunityDetail.winners[num];
    }

    /**
     * @notice Retrieves the prize amount which is distributed to each winner
     * @param winnerAddr Winner address whose prize amount want to retrieve
     * @return An amount which distributed to winner
     */
    function getWinnersPrizeAmount(address winnerAddr) external  view returns(uint256) {
        return newCommunityDetail.winnersPrizeAmount[winnerAddr];
    }


    // function getUserStackAmount(address user) public view returns(uint256){
    //    return newCommunityDetail.usersStackingAmount[user];
    // }
}

/// @title Factory contract
contract Factory {
    address public Owner;
    uint256 public communityCounter;
    mapping(uint256 => address) private communityContractIndex;

    constructor() {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Only owner can access.");
        _;
    }

    event CommunityContract(address contractAddress);

    /**
     * @notice Creates a new community contract
     * @dev Only the contract owner can call this function
     * @param _ownerTreasuryAddress The address where the treasury funds will be transferred
     * @param _maxUsersCap The maximum number of users that can participate in the community
     * @param _stackingDuration The duration of the stacking period
     * @param _winnersPrizePercent An array containing the prize percentages for each winner
     * @return The address of the created community contract
     */
    function createCommunity(
        address _ownerTreasuryAddress,
        uint256 _maxUsersCap,
        uint256 _stackingDuration,
        uint256[] memory _winnersPrizePercent
    ) external onlyOwner returns (address) {
        require(_winnersPrizePercent.length<=3,"Limit exceeds!");
        require(_winnersPrizePercent[0]+_winnersPrizePercent[1]+_winnersPrizePercent[2]==100,"Total percentage must be equal to 100");
        // require(newConfig.isPrizesSet==true,"Winning amount is not set.");
        communityCounter += 1;

        Community newContract = new Community(
            Owner,
            _ownerTreasuryAddress,
            communityCounter,
            _maxUsersCap,
            _stackingDuration,
            _winnersPrizePercent
        );

        communityContractIndex[communityCounter]=address(newContract);
        emit CommunityContract(address(newContract));

        return address(newContract);
    }

    /**
     * @notice Retrieves the community contract address by its index number
     * @param indexNum The index number of the community contract
     * @return The address of the community contract
     */
    function getCommunityContractByIndex(uint256 indexNum) external view returns (address)  {
        return communityContractIndex[indexNum];
    }
}