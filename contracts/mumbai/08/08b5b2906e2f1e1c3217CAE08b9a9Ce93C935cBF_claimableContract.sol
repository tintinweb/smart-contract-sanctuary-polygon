// SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

interface IStakeable{
    function getStakedAmount(address user) external view returns(uint);
    function isStaker(address user) external view returns(bool);
    function getTotalParticipants() external view returns(uint256);
    function getParticipantsByTierId(uint256 tierId, uint256 poolLevel) external view returns(uint256);
    function isAllocationEligible(uint participationEndTime) external view returns(bool);
    function getTierIdFromUser(address sender) external view returns(uint, uint);
}

contract claimableContract {
    //staking contract
    IStakeable public stakingContract;

    // reward token contract
    IERC20Metadata public rewardToken;

    uint public totalSupply;
    uint public totalSoldToken;
    uint public tokenBalance;
    uint public listingTime;
    uint public  totalParticipants;
    uint public participationEndTime;
    uint public roundOneStartTime;
    uint public roundOneEndTime;
    uint public FCFSStartTime;
    uint public vestingTime;
    uint public claimSlots;
    bool public roundOneStatus;
    bool public isAllocationEnd;
    bool public isFCFSAllocationEnd;
    bool public isCompleted;
    address public admin;

    struct poolDetail{
        uint256 tierLevel;
        uint256 poolLevel;
        uint256 poolWeight;
        uint256 allocatedAmount;
        uint256 participants;
    }

    mapping(uint => mapping( uint => poolDetail)) public tierDetails;

    event TokenBuyed(address user,uint tierId,uint amount);
    event TokenWithdrawn(address user,uint tierId, uint pool, uint amount);
    event participationCompleted(uint endTime);
    event BuyingCompleted();
    event Participate(address user,uint tierid);
    event AllocationRoundOneEnds(uint allocationEndTime);
    event AllocationRoundTwoEnds(uint tokenBalance);

    struct userDetail{
        uint buyedToken;
        uint remainingTokenToBuy;
        uint tokenToSend;
        uint nextVestingTime;
        bool FRtokenBuyed;
    }

    mapping(address => bool) internal participants;

    address[] participant;
   
    mapping(address => userDetail) userDetails;

    constructor (IStakeable _stakingContract, IERC20Metadata _rewardToken, uint _totalsupply, uint[] memory tierWeights, uint _listingTime, uint _claimSlots, uint _vestingTime, uint _roundOneStartTime,uint _roundOneEndTime,uint _FCFSStartTime) {
        admin = msg.sender;        
        stakingContract = _stakingContract;
        rewardToken = _rewardToken;
        totalSupply = _totalsupply * 10 ** rewardToken.decimals();
        uint k;
        for(uint i = 1; i <= 6; i++){
            for(uint j = 1; j <= 3; j++) {
                tierDetails[i][j].tierLevel = i;
                tierDetails[i][j].poolLevel = j;
                tierDetails[i][j].poolWeight = tierWeights[k];
                k++;
            }
        }

        listingTime = _listingTime * 3600;
        roundOneStartTime = _roundOneStartTime * 3600;
        roundOneEndTime = _roundOneEndTime * 3600;
        FCFSStartTime = _FCFSStartTime * 3600;
        claimSlots = _claimSlots;
        vestingTime = _vestingTime * 1 seconds;
    }

    modifier onlyOwner {
        require(msg.sender == admin, "Ownable: caller is not the owner");
        _;
    }

    function getTierAllocatedAmount() external view returns(poolDetail[] memory) {
        poolDetail[] memory allocationDetails = new poolDetail[](18);
        uint256 k;
        for(uint i = 1; i <= 6; i++){
            for(uint j = 1; j <= 3; j++) {
                allocationDetails[k].tierLevel = tierDetails[i][j].tierLevel;
                allocationDetails[k].poolLevel = tierDetails[i][j].poolLevel;
                allocationDetails[k].poolWeight = tierDetails[i][j].poolWeight;
                allocationDetails[k].allocatedAmount = tierDetails[i][j].allocatedAmount;
                allocationDetails[k].participants = tierDetails[i][j].participants;
                k++;
            }
        }
        return allocationDetails;
    }

    function allocation(address[] memory _allocation) external onlyOwner {
        require(!isAllocationEnd, "allocation cannot happen before after the participation ends");
        totalParticipants = stakingContract.getTotalParticipants();
        require(totalParticipants != 0, "allocation can't happen if there is no participants");
        participant = _allocation;

        for(uint8 i = 0; i < _allocation.length; i++) {
            participants[_allocation[i]] = true;
        }
        for(uint8 i = 1; i <= 6; i++){
            for(uint8 j = 1; j <= 3; j++) {
                tierDetails[i][j].participants = stakingContract.getParticipantsByTierId(i, j);
                if(tierDetails[i][j].participants == 0){
                    tierDetails[i][j].allocatedAmount = 0;
                }
                else{
                    tierDetails[i][j].allocatedAmount = (totalSupply *  tierDetails[i][j].poolWeight) / 100;
                    tierDetails[i][j].allocatedAmount = tierDetails[i][j].allocatedAmount / tierDetails[i][j].participants;
                }
            }
        }
        listingTime = block.timestamp + listingTime;
        roundOneStartTime = block.timestamp + roundOneStartTime;
        roundOneEndTime = roundOneStartTime + roundOneEndTime;
        FCFSStartTime = roundOneEndTime + FCFSStartTime;
        roundOneStatus = true ;
        isAllocationEnd = true;
        participationEndTime = block.timestamp;
        emit AllocationRoundOneEnds(block.timestamp);
    }

    function allocationRoundTwo() external onlyOwner {   

        require(block.timestamp >= roundOneEndTime, "allocation cannot happen before after the participation ends");
        require(!isFCFSAllocationEnd, "allocation cannot happen before after the participation ends");
        tokenBalance = totalSupply - totalSoldToken;
        isFCFSAllocationEnd = true;
        emit AllocationRoundTwoEnds(tokenBalance);

    }

    function getAllocation(address account) external view returns(uint){
        require(stakingContract.isAllocationEligible(participationEndTime), "not eligible");
        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(account);
        return tierDetails[tierId][pool].allocatedAmount;

    }

    function getUserDetails(address sender) external view returns(uint,uint) {
        return (userDetails[sender].buyedToken,userDetails[sender].tokenToSend);
    }

    function getNextVestingTime(address account) external view returns(uint, uint) {
        require(userDetails[msg.sender].tokenToSend > 0, "invalid claim");
        return (userDetails[account].nextVestingTime, userDetails[msg.sender].buyedToken / claimSlots);
    }

    function buyToken(uint amount) external returns(bool) {
        require(stakingContract.isStaker(msg.sender), "you must stake first to buy tokens");
        require(participants[msg.sender], "User doesn't have access to buy tokens");
        require(!isCompleted, "No token to buy");
        require(roundOneStatus && block.timestamp >= roundOneStartTime, "round one not yet started");

        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(msg.sender);
        if(block.timestamp <= roundOneEndTime){
            if(userDetails[msg.sender].buyedToken == 0 && !userDetails[msg.sender].FRtokenBuyed){
                userDetails[msg.sender].remainingTokenToBuy = tierDetails[tierId][pool].allocatedAmount;
            }
            require(amount <= userDetails[msg.sender].remainingTokenToBuy, "amount should be lesser than allocated amount");
            userDetails[msg.sender].remainingTokenToBuy -= amount;
            totalSoldToken += amount;
            userDetails[msg.sender].buyedToken += amount;
            userDetails[msg.sender].tokenToSend += amount;
            if(userDetails[msg.sender].remainingTokenToBuy == 0) {
                userDetails[msg.sender].FRtokenBuyed == true; 
            }
            emit TokenBuyed(msg.sender, tierId, amount);
            return true;
        }
        else {
            require(block.timestamp >= FCFSStartTime, "First come first serve still not start");
            require(amount <= tokenBalance, "amount should be lesser than allocated amount");
            totalSoldToken += amount;
            tokenBalance -= amount;
            if(tokenBalance == 0){
                isCompleted = true;
            }
            userDetails[msg.sender].buyedToken += amount;
            userDetails[msg.sender].tokenToSend += amount;
            emit TokenBuyed(msg.sender, tierId, amount);            
            return true;
        }
    }

    function claimToken() external returns(bool) {
        require(block.timestamp >= listingTime, "cannot claim before listing time");
        require(userDetails[msg.sender].tokenToSend > 0, "amount should be greater than zero");

        if(userDetails[msg.sender].tokenToSend == userDetails[msg.sender].buyedToken){
            userDetails[msg.sender].nextVestingTime = listingTime;
        }

        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(msg.sender);

        require(block.timestamp >= userDetails[msg.sender].nextVestingTime, "cannot be vested now");
        uint amountToBeSend = userDetails[msg.sender].buyedToken / claimSlots;
        rewardToken.transfer(msg.sender, amountToBeSend);
        userDetails[msg.sender].tokenToSend -= amountToBeSend;
        userDetails[msg.sender].nextVestingTime = block.timestamp + vestingTime;
        emit TokenWithdrawn(msg.sender, tierId, pool, amountToBeSend);
        return true;

    }
    
    function setTokenListingTime(uint time) external onlyOwner {
       listingTime = block.timestamp + (time * 60);
    }

    function setroundOneStartTime(uint time) external onlyOwner {
       roundOneStartTime = block.timestamp + (time * 60);
    }
    
    function setroundOneEndTime(uint time) external onlyOwner {
       roundOneEndTime = block.timestamp + (time * 60);
    }
    
    function setFCFSStartTime(uint time) external onlyOwner {
       FCFSStartTime = block.timestamp + (time * 60);
    }

    function setVestingTime(uint time) external onlyOwner {
        vestingTime = block.timestamp + (time * 60 seconds);
    }

}