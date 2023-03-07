/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;

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
    
    mapping(uint8 => uint) public packagePrice;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    uint256 private directPercents =10;
    uint256[30] private levelPercents = [15,5,5,5,5,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1];
    address public id1=0xe127a38BAB6DC057fa3a0FEA50b97dAA502711DA;
    address public owner;
    address deductionWallet=0x02981a74A96F40EB54380C0ebbfBc8FA83b7928B;
    uint256 private dayRewardPercents = 5;
    uint256 private constant timeStepdaily =1 days;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint256 value);
    event Upgrade(address indexed user, uint256 value);
    event Transaction(address indexed user,address indexed from,uint256 value,uint256 flash, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);

    constructor() public {
        owner=msg.sender;
        User memory user = User({
            id: 1,
            rankId:0,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            directIds:new address[](0),
            totalBusiness:0,
            totalDeposit:300000e18,
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
            300000e18, 
            block.timestamp, 
            0,
            true
        ));
        map_ranks[1] = Rank({Id:1,Business:1000e18,Income:200e18,Daily:2e18,Period:100}); 
        map_ranks[2] = Rank({Id:2,Business:6000e18,Income:1000e18,Daily:10e18,Period:100}); 
        map_ranks[3] = Rank({Id:3,Business:13500e18,Income:1500e18,Daily:15e18,Period:100}); 
        map_ranks[4] = Rank({Id:4,Business:31000e18,Income:3500e18,Daily:35e18,Period:100}); 
        map_ranks[5] = Rank({Id:5,Business:56000e18,Income:5000e18,Daily:50e18,Period:100}); 
        map_ranks[6] = Rank({Id:6,Business:96000e18,Income:8000e18,Daily:80e18,Period:100}); 
        map_ranks[7] = Rank({Id:7,Business:153500e18,Income:11500e18,Daily:115e18,Period:100}); 
        map_ranks[8] = Rank({Id:8,Business:303500e18,Income:30000e18,Daily:300e18,Period:100});        
        map_ranks[9] = Rank({Id:9,Business:603500e18,Income:60000e18,Daily:600e18,Period:100}); 
        map_ranks[10] = Rank({Id:10,Business:1103500e18,Income:100000e18,Daily:1000e18,Period:100}); 
        map_ranks[11] = Rank({Id:11,Business:1853500e18,Income:150000e18,Daily:1500e18,Period:100}); 
        map_ranks[12] = Rank({Id:12,Business:3353500e18,Income:300000e18,Daily:3000e18,Period:100});        
        map_ranks[13] = Rank({Id:13,Business:6353500e18,Income:600000e18,Daily:6000e18,Period:100}); 
        map_ranks[14] = Rank({Id:14,Business:12353500e18,Income:1200000e18,Daily:12000e18,Period:100}); 
        map_ranks[15] = Rank({Id:15,Business:24353500e18,Income:2400000e18,Daily:24000e18,Period:100}); 
    }
    function registrationExt(address referrerAddress) external payable  {
        uint256 _amount=msg.value;
        require(_amount >= 100e18, "less than min");
        registration(msg.sender, referrerAddress,_amount);
    }
    function buyNewLevel() external payable {
        uint256 _amount=msg.value;
        require(_amount >= (users[msg.sender].lastDeposit+users[msg.sender].lastDeposit*20/100), "less than min");
        buyLevel(msg.sender,_amount);
    }
    function buyLevel(address userAddress,uint256 _amount) private {        
        require(isUserExists(userAddress), "user is not exists. Register first."); 
        users[userAddress].totalDeposit +=_amount;
        users[userAddress].lastDeposit=_amount;
        _updatebusinessIncome(userAddress,_amount);
        dailyPayoutOf(userAddress);
        dailyPayoutOfReward(userAddress);
        address referrerAddress= users[userAddress].referrer;
        uint256 _remainingCapping=this.maxPayoutOf(referrerAddress);        
        if(_remainingCapping>0)
        {            
            uint256 reward= _amount*directPercents/100;
            uint256 flash=0;
            if(_remainingCapping<reward){
                flash=reward-_remainingCapping;
                reward=_remainingCapping;                
            }
            if(reward>0){
                users[referrerAddress].directincome += reward;                       
                users[referrerAddress].totalincome +=reward;
                emit Transaction(referrerAddress,userAddress,reward,flash,1,1);
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
            uint256 flash=0;
            if(_remainingCapping<reward){
                flash=reward-_remainingCapping;
                reward=_remainingCapping;                
            }
            if(reward>0){
                users[referrerAddress].directincome += reward;                       
                users[referrerAddress].totalincome +=reward;
                emit Transaction(referrerAddress,userAddress,reward,flash,1,1);
            }
        }
        orderInfos[userAddress].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true
        ));
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,_amount);
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
                uint256 _remainingCapping=this.maxPayoutOf(upline);        
                if(_remainingCapping>0)
                {
                    uint256 reward=_amount*levelPercents[i]/100;
                    uint256 flash=0;
                    if(_remainingCapping<reward){
                        flash=reward-_remainingCapping;
                        reward=_remainingCapping;                        
                    }
                    if(reward>0){
                        users[upline].levelincome +=reward;                       
                        users[upline].totalincome +=reward;   
                        emit Transaction(upline,_user,reward,flash,(i+1),3);                        
                    }
            
                }
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
        return (totaldeposit*(200+rank*40)/100-totalincome);
    }
    function dailyPayoutOf(address _user) public {
        uint256 max_payout = this.maxPayoutOf(_user);
        uint rank=users[_user].rankId; 
        uint256 totalincome=users[_user].totalincome;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            uint256 maxpay=order.amount*(200+rank*40)/100;
            if(totalincome<maxpay)
            {
                if(order.isactive && block.timestamp>order.deposit_time){                       
                    uint256 dailypayout =(order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 1000) - order.payouts;
                    order.payouts+=dailypayout;
                    uint256 flash=0;
                    if(max_payout<dailypayout){
                        flash=dailypayout-dailypayout;
                        dailypayout = max_payout;                            
                    }
                    if(dailypayout>0)
                    {
                        _distributelevelIncome(_user,dailypayout);
                        users[_user].payouts += dailypayout;            
                        users[_user].totalincome +=dailypayout;
                        emit Transaction(_user,_user,dailypayout,flash,1,2);                            
                    }                    
                }
            }
            else {
               order.isactive=false;
            }
        }
    }
    function dailyPayoutOfReward(address _user) public {
        uint256 max_payout=0;
        for(uint8 i = 0; i < rewardInfos[_user].length; i++){
            RewardInfo storage dailyreward = rewardInfos[_user][i];
            if(block.timestamp>dailyreward.deposit_time){
                max_payout = this.maxPayoutOf(_user);
                uint256 dailypayout =dailyreward.reward*((block.timestamp - dailyreward.deposit_time) / timeStepdaily) - dailyreward.payouts;
                uint256 flash=0;
                dailyreward.payouts+=dailypayout;
                if(max_payout<dailypayout){
                    flash=dailypayout-dailypayout;
                    dailypayout = max_payout;                            
                }
                if(dailypayout>0)
                {
                    users[_user].rewardincome += dailypayout;            
                    users[_user].totalincome +=dailypayout;
                    emit Transaction(_user,_user,dailypayout,flash,1,4);                            
                }
            }
        }
    }
    function updateDeductionWallet(address _deductionWallet) external {
        if(msg.sender==owner)
        deductionWallet=_deductionWallet; 
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
        require(balanceReward>=20e18, "Insufficient reward to withdraw!");
        users[msg.sender].totalwithdraw+=balanceReward;
        payable(msg.sender).transfer(balanceReward*90/100);  
        payable(deductionWallet).transfer(balanceReward*10/100);  
        emit withdraw(msg.sender,balanceReward);
    }
}