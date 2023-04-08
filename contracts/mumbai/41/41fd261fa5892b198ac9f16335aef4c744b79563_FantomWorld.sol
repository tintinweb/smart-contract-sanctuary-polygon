/**
 *Submitted for verification at polygonscan.com on 2023-04-07
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

contract FantomWorld {
    struct User {
        address account;
        uint referrer;
        uint8 rank;
        uint partnersCount;
        uint256 totalDeposit;  
        uint256 lastDeposit;
        uint256 directBusiness;
        uint256 totalincome;
        uint256 totalwithdraw;
        uint256 blockcapping;
        mapping(uint8 => Level) levelMatrix;
    }    
    struct Level {
        uint currentReferrer;
        uint[] referrals;
    }
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts;
        bool isactive;
        bool unstake;
    }
    struct RewardInfo {
        uint256 directincome;    
        uint256 payouts;
        uint256 levelincome;
        uint256 autofillincome;       
        uint256 singlelegincome; 
        uint256 poolincomea;
        uint256 poolincomeb;
    }
    struct Rank
    {
        uint Id;
        uint Business;
        uint Income;
        uint Daily;
        uint Period;
    }
    mapping(uint => User) public users;
    mapping(uint => OrderInfo[]) public orderInfos;
    mapping(uint => RewardInfo) public rewardInfo;
    IERC20 public tokenDAI;
    mapping(uint8 => uint) public packagePrice;
    mapping(address => uint) public AddressToId;
    uint public lastUserId = 2;
    uint256 private directPercents =5;
    uint256[10] private levelPercents = [7,7,7,7,7,7,7,7,7,7];
    address public id1=0x6137d3e622920543Cf36923496Cb9738E959D3dC;
    address public owner;
    address deductionWallet=0x6137d3e622920543Cf36923496Cb9738E959D3dC;
    uint256 private dayRewardPercents = 4;
    uint256 private constant timeStepdaily =60*60;
    mapping(uint8 => uint) public pooldirectCond;
    mapping(uint8 => uint) public poolbusinessCond;
    mapping(uint=>uint[]) public poolUsers;  
    mapping(uint8 => mapping(uint256 => uint)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId,uint256 value);
    event Upgrade(address indexed user, uint256 value);
    event Transaction(address indexed user,address indexed from,uint256 value,uint256 flash, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);

    constructor(address _token) public {        
        tokenDAI = IERC20(_token);
        owner=msg.sender;
        pooldirectCond[1]=10;
        pooldirectCond[2]=20;
        pooldirectCond[3]=30;
        pooldirectCond[4]=0;
        pooldirectCond[5]=0;

        poolbusinessCond[1]=5000e18;
        poolbusinessCond[2]=10000e18;
        poolbusinessCond[3]=15000e18;
        poolbusinessCond[4]=25000e18;
        poolbusinessCond[5]=50000e18;
        
        x2vId_number[1][1]=1;
        x2Index[1]=1;
        x2CurrentvId[1]=1;

        User memory user = User({
            account:id1,
            referrer: 0,
            rank:0,
            partnersCount: uint(0),
            directBusiness:0,
            totalDeposit:100e18,
            lastDeposit:100e18,
            totalincome:0,
            totalwithdraw:0,
            blockcapping:0
        });
        users[1] = user;
        AddressToId[id1] = 1;
        orderInfos[1].push(OrderInfo(
            100e18, 
            block.timestamp, 
            0,
            true,
            false
        ));
    }
    function registrationExt(address referrerAddress,uint256 _amount) external {
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        require(_amount >= 100e18, "less than min");
        registration(msg.sender, referrerAddress,_amount);
    }
    function registrationFor(address referrerAddress,address userAddress,uint256 _amount) external {
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        require(_amount >= 100e18, "less than min");
        registration(userAddress, referrerAddress,_amount);
    }
    function buyNewLevel(uint256 _amount) external {
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        uint userid=AddressToId[msg.sender];
        require(_amount >= users[userid].lastDeposit && _amount%20==0, "less than min");
        buyLevel(userid,_amount);
    }
    function buyLevel(uint userid,uint256 _amount) private {
        users[userid].totalDeposit +=_amount;
        users[userid].lastDeposit=_amount;
        uint referrerid=users[userid].referrer;
        users[referrerid].directBusiness+=_amount;
        _calLevelNow(referrerid);
        dailyPayoutOf(userid); 
        
        uint256 _remainingCapping=this.maxPayoutOf(referrerid);        
        if(_remainingCapping>0)
        {            
            uint256 reward=_amount*directPercents/100;
            uint256 flash=0;
            uint256 parentpackage=users[referrerid].lastDeposit;
            if(parentpackage<_amount)
            {
                reward= parentpackage*directPercents/100;
            } 
            if(_remainingCapping<reward){
                flash=reward-_remainingCapping;
                reward=_remainingCapping;                
            }
            if(reward>0){
                rewardInfo[referrerid].directincome += reward;                       
                users[referrerid].totalincome +=reward;
                emit Transaction(users[referrerid].account,users[userid].account,reward,flash,1,1);
            }
        }       
        orderInfos[userid].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true,
            false
        ));        
        emit Upgrade(users[userid].account,_amount);
    }
    
      
    function registration(address userAddress, address referrerAddress,uint256 _amount) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        uint referrerid=AddressToId[referrerAddress];
        User memory user = User({
            account:userAddress,
            referrer: referrerid,
            rank:0,
            partnersCount: 0,
            directBusiness:0,
            totalDeposit:_amount,
            lastDeposit:_amount,
            totalincome:0,
            totalwithdraw:0,
            blockcapping:0
        });
        uint userid=lastUserId;
        lastUserId++;
        users[userid] = user;
        AddressToId[userAddress] = userid;
        users[userid].referrer = referrerid;
        users[referrerid].directBusiness+=_amount;
        users[referrerid].partnersCount++;  
        _calLevelNow(referrerid);
        uint freeLevelReferrer = findFreeLevelReferrer(1);
        users[userid].levelMatrix[1].currentReferrer = freeLevelReferrer;
        updateLevelReferrer(userid, freeLevelReferrer, 1);
        uint256 _remainingCapping=this.maxPayoutOf(referrerid);        
        if(_remainingCapping>0)
        {            
            uint256 reward= _amount*directPercents/100;
            uint256 flash=0;
            uint256 parentpackage=users[referrerid].lastDeposit;
            if(parentpackage<_amount)
            {
                reward= parentpackage*directPercents/100;
            }            
            if(_remainingCapping<reward){
                flash=reward-_remainingCapping;
                reward=_remainingCapping;                
            }
            if(reward>0){
                rewardInfo[referrerid].directincome += reward;                       
                users[referrerid].totalincome +=reward;
                emit Transaction(referrerAddress,userAddress,reward,flash,1,1);
            }
        }
        orderInfos[userid].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true,
            false
        ));
        emit Registration(userAddress, referrerAddress, userid, referrerid,_amount);
    }
    function updateLevelReferrer(uint userid, uint referrerid, uint8 level) private{
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userid;
        x2Index[level]=newIndex;
        
        users[referrerid].levelMatrix[level].referrals.push(userid); 
        if (users[referrerid].levelMatrix[level].referrals.length == 2) {
            x2CurrentvId[level]=x2CurrentvId[level]+1;
        }
    }   
    
    
    function _distributelevelIncome(uint _userid, uint256 _amount,uint256 _package) private {
        uint upline = users[_userid].referrer;
        for(uint8 i = 0; i < 10; i++){
            if(upline != 0){
                if(users[_userid].partnersCount>=(i+1) && users[_userid].directBusiness>=(i*300e18))
                {
                    uint256 _remainingCapping=this.maxPayoutOf(upline);        
                    if(_remainingCapping>0)
                    {
                        uint256 reward=_amount*levelPercents[i]/100;
                        uint256 parentpackage=users[_userid].lastDeposit;
                        if(parentpackage<_package)
                        {
                            reward=_amount*(parentpackage/_package)*levelPercents[i]/100;
                        }
                        uint256 flash=0;
                        if(_remainingCapping<reward){
                            flash=reward-_remainingCapping;
                            reward=_remainingCapping;                        
                        }
                        if(reward>0){
                            rewardInfo[upline].levelincome +=reward;                       
                            users[upline].totalincome +=reward;   
                            emit Transaction(users[upline].account,users[_userid].account,reward,flash,(i+1),3);                        
                        }
            
                    }
                }
                upline = users[upline].referrer;
                
            }else{
                break;
            }
        }
    }
    function _distributeLevelReferrer(uint userid, uint8 level,uint roi,uint _package) private{         
        uint upline = users[userid].levelMatrix[level].currentReferrer;
        uint256 reward=roi*5/100; 
        uint8 i = 1;
        for(i=1; i <= 5; i++){            
            if(upline != 0){
                uint256 parentpackage=users[userid].lastDeposit;
                if(parentpackage<_package)
                {
                    reward=reward*(parentpackage/_package);
                }
                rewardInfo[upline].autofillincome += reward;                       
                users[upline].totalincome +=reward;
                emit Transaction(users[upline].account,users[userid].account,reward,0,level,4);
                upline = users[upline].levelMatrix[level].currentReferrer;
            }
            else {
                break;
            }
        } 
    } 
    function _distributePoolIncome(uint8 _level,uint256 _poolamount,uint256 _package) private {
        uint256 poolCount=poolUsers[_level].length;
        if(poolCount > 0){
            uint256 reward = _poolamount*5/(poolCount*100);
            for(uint256 i = 0; i < poolCount; i++){
                uint256 parentpackage=users[poolUsers[_level][i]].lastDeposit;
                if(parentpackage<_package)
                {
                    reward=reward*(parentpackage/_package);
                }
                if(_level<=3)
                rewardInfo[poolUsers[_level][i]].poolincomea += reward;
                else 
                rewardInfo[poolUsers[_level][i]].poolincomeb += reward;
                users[poolUsers[_level][i]].totalincome +=reward;   
                emit Transaction(users[poolUsers[_level][i]].account,id1,reward,0,_level,5);               
            }
        }
    }
    function _distributesingleg(uint userid,uint roi,uint256 _package) private{         
        uint upline = userid+1;
        uint256 reward=roi*2/100; 
        uint8 i = 1;
        for(i=1; i <= 10; i++){            
            if(upline != 0){
                uint256 parentpackage=users[userid].lastDeposit;
                if(parentpackage<_package)
                {
                    reward=reward*(parentpackage/_package);
                }
                rewardInfo[upline].singlelegincome += reward;                       
                users[upline].totalincome +=reward;
                emit Transaction(users[upline].account,users[userid].account,reward,0,1,6);
                upline = upline+1;
            }
            else {
                break;
            }
        } 
    } 
    function maxPayoutOf(uint _user) view external returns(uint256) {
        uint256 totaldeposit=users[_user].totalDeposit;
        uint256 totalincome=users[_user].totalincome;  
        return (totaldeposit*4-totalincome);
    }
    function dailyPayoutOf(uint _user) public {
        uint256 max_payout = this.maxPayoutOf(_user);
        uint256 totalincome=users[_user].totalincome;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            uint256 maxpay=order.amount*4;
            if(totalincome<maxpay && order.isactive)
            {
                if(block.timestamp>order.deposit_time){                       
                    uint256 dailypayout =(order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 1000) - order.payouts;
                    order.payouts+=dailypayout;
                    uint256 flash=0;
                    uint256 actualpayout=0;
                    if(max_payout<dailypayout){
                        flash=dailypayout-dailypayout;
                        actualpayout = max_payout;                            
                    }
                    if(actualpayout>0)
                    {
                        _distributelevelIncome(_user,dailypayout,order.amount);
                        _distributeLevelReferrer(_user,1,dailypayout,order.amount);
                        _distributePoolIncome(1,dailypayout,order.amount);
                        _distributePoolIncome(2,dailypayout,order.amount);
                        _distributePoolIncome(3,dailypayout,order.amount);
                        _distributePoolIncome(4,dailypayout,order.amount);
                        _distributePoolIncome(5,dailypayout,order.amount);
                        _distributesingleg(_user,dailypayout,order.amount);
                        rewardInfo[_user].payouts += actualpayout;            
                        users[_user].totalincome +=actualpayout;
                        emit Transaction(users[_user].account,users[_user].account,actualpayout,flash,1,2);                            
                    }                    
                }
            }
            else if(order.isactive){
               order.isactive=false;
               users[_user].blockcapping+=maxpay;
            }
            if(block.timestamp>order.deposit_time+15*30*timeStepdaily && !order.unstake){ 
                order.unstake=true;
                users[_user].totalincome +=order.amount*15/100;
                emit Transaction(users[_user].account,users[_user].account,order.amount*15/100,0,1,7);
            }
        }
    }
    function stakePayoutOf(uint _user) public returns(uint256){
        uint256 unstakeamount=0;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];            
            if(block.timestamp>order.deposit_time+15*30*timeStepdaily && !order.unstake){ 
                order.unstake=true;
                unstakeamount +=order.amount*15/100;
                emit Transaction(users[_user].account,users[_user].account,order.amount*15/100,0,1,7);
            }
        }
    }
    function updateDeductionWallet(address _deductionWallet) external {
        if(msg.sender==owner)
        deductionWallet=_deductionWallet; 
    }
    function isUserExists(address user) public view returns (bool) {
        return (AddressToId[user] != 0);
    }    
    function getOrderLength(uint _userid) external view returns(uint256) {
        return orderInfos[_userid].length;
    }   
    function findFreeLevelReferrer(uint8 level) public view returns(uint){
            uint256 id=x2CurrentvId[level];
            return x2vId_number[level][id];
    } 
    function _calLevelNow(uint _userid) private {
        uint8 rank=users[_userid].rank;
        uint8 nextrank=rank+1;
        if(users[_userid].partnersCount>=pooldirectCond[nextrank] && users[_userid].directBusiness>=poolbusinessCond[nextrank] && nextrank<=5)
        {
            users[_userid].rank=nextrank;
            poolUsers[nextrank].push(_userid);
        }
    }
    function stakingWithdraw() public
    {
        uint userid=AddressToId[msg.sender];
        uint256 balanceStake=stakePayoutOf(userid);
        require(balanceStake>0, "Insufficient stake to withdraw!");
        tokenDAI.transfer(msg.sender,balanceStake*95/100);
        emit withdraw(msg.sender,balanceStake);
    }
    function rewardWithdraw() public
    {
        uint userid=AddressToId[msg.sender];
        dailyPayoutOf(userid);
        uint balanceReward = users[userid].totalincome - users[userid].totalwithdraw;
        require(balanceReward>=15e18, "Insufficient reward to withdraw!");
        users[userid].totalwithdraw+=balanceReward;
        tokenDAI.transfer(msg.sender,balanceReward*90/100);  
        tokenDAI.transfer(deductionWallet,balanceReward*10/100);  
        emit withdraw(msg.sender,balanceReward);
    }
}