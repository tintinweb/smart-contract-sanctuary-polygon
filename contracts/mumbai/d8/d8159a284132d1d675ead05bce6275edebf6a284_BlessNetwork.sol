/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

pragma solidity >=0.4.23 <0.6.0;
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

contract BlessNetwork {
    struct User {
        uint id;
        uint8 rank;
        address referrer;
        uint partnersCount;
        uint teamCount;
        uint256 directincome;
        uint256 sponsorincome;
        uint256 levelincome;
        uint256 autopoolincome;
        uint256 clubincome;        
        uint256 teamincome;
        uint256 totalincome;
        uint256 totalwithdraw;  
		mapping(uint8 => bool) activeLevels;
        mapping(uint8 => AutoPool) autopoolMatrix; 
        mapping(uint8 => Level) levelMatrix;  
    }
    struct HoldInfo{
        uint256 directincome;
        uint256 sponsorincome;
        uint256 autopoolincome;
        uint teamCount;
        mapping(uint8 => uint) directhold; 
        mapping(uint8 => uint) sponsorhold;
        mapping(uint8 => uint) autopoolhold; 
    }
    mapping(address=>HoldInfo) public holdInfo;
    struct Booster {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;
    }
    struct AutoPool {
        address currentReferrer;
        mapping(uint256=>address[]) referrals;
    }
    struct Level {
        address currentReferrer;
        address[] referrals;
    }
    uint8 public constant LAST_LEVEL = 20;
    IERC20 public tokenDAI;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    uint256 public clubPool;
    

    mapping(uint256 => mapping(address => uint256)) public userLayerDayDirect5; 
    mapping(uint256=>address[]) public dayDirect5Users;  
    
    uint256 public lastDistribute;
    uint256 public startTime;
    uint256 private constant timeStepWeekly =15*60*60;

    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;

    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;
    
    
    address public createrWallet=0xd34375A5F3de7D6fA2AFDc20eF6ab8cF72088597;
    address public id1=0x5582d905EBAcb327287eD603b4C70F41eaB50Bf0;
    address[4] public id2=[0x8D00BE4d073bD852dd41e7755ecDFD562Ea6CE80,0x8DCAB78a0E5d13Cb53753F1C96C4C783B177BFf0,0xb3b4595B8831d18cD85E73C4056FbE1F87522F00,0x4dC2e5De997ab116086Ff35eF5A00abD9A8aaaC5];
    mapping(uint8 => uint) public directprice;
    mapping(uint8 => uint) public sponsorprice; 
    mapping(uint8 => uint) public levelPercents;
    mapping(uint8 => uint) public autopoolPrice; 
    mapping(uint8 => uint) public clubfund; 
    mapping(uint8 => uint) public packagePrice;  
    mapping(uint8 => uint) public teamIncome;
    mapping(uint8 => uint) public teamCount;
    mapping(uint8 => uint) public directCond;
    mapping(uint8 => uint) public teamdirectCond;
    address private creation;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);    
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event booster(address indexed user,uint256 value);
    event withdraw(address indexed user,uint256 value);
    constructor(address _token) public {
        
        tokenDAI = IERC20(_token);
        directprice[1] = 75e5;
        directprice[2] = 75e5;
        directprice[3] = 15e6;
        directprice[4] = 30e6;
        directprice[5] = 60e6;
        directprice[6] = 120e6;

        sponsorprice[1] = 25e5;
        sponsorprice[2] = 5e6;
        sponsorprice[3] = 10e6;
        sponsorprice[4] = 20e6;
        sponsorprice[5] = 40e6;
        sponsorprice[6] = 80e6;

        levelPercents[1] = 25e4;
        levelPercents[2] = 5e5;
        levelPercents[3] = 1e6;
        levelPercents[4] = 2e6;
        levelPercents[5] = 4e6;
        levelPercents[6] = 8e6;

        autopoolPrice[1] = 75e4;
        autopoolPrice[2] = 225e4;
        autopoolPrice[3] = 45e5;
        autopoolPrice[4] = 9e6;
        autopoolPrice[5] = 18e6;
        autopoolPrice[6] = 36e6;

        clubfund[1] = 125e4;
        clubfund[2] = 25e5;
        clubfund[3] = 5e6;
        clubfund[4] = 10e6;
        clubfund[5] = 20e6;
        clubfund[6] = 40e6;

        packagePrice[1] = 25e6;
        packagePrice[2] = 50e6;
        packagePrice[3] = 100e6;
        packagePrice[4] = 200e6;
        packagePrice[5] = 400e6;
        packagePrice[6] = 800e6;
        
        teamIncome[1]=50e6;
        teamIncome[2]=100e6;
        teamIncome[3]=500e6;
        teamIncome[4]=1500e6;
        teamIncome[5]=5000e6;
        teamIncome[6]=15000e6;

        teamCount[1]=50;
        teamCount[2]=150;
        teamCount[3]=650;
        teamCount[4]=2150;
        teamCount[5]=7150;
        teamCount[6]=22150;

        directCond[1]=2;
        directCond[2]=4;
        directCond[3]=6;
        directCond[4]=8;
        directCond[5]=10;
        directCond[6]=12;

        teamdirectCond[1]=5;
        teamdirectCond[2]=10;
        teamdirectCond[3]=15;
        teamdirectCond[4]=20;
        teamdirectCond[5]=25;
        teamdirectCond[6]=30;

        creation=msg.sender;
        lastDistribute = block.timestamp;
        startTime = block.timestamp;
        User memory user = User({
            id: 1,
            rank:0,
            referrer: address(0),
            partnersCount: uint(0),
            teamCount:0,
            directincome:0,
            sponsorincome:0,
            levelincome:0,            
            autopoolincome:0,
            clubincome:0,
            teamincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        users[id1] = user;
        idToAddress[1] = id1;
        
        for (uint8 i = 1; i <=6; i++) {
            x2vId_number[i][1]=id1;
            x2Index[i]=1;
            x2CurrentvId[i]=1;  
            users[id1].activeLevels[i] = true;

            x3vId_number[i][1]=id1;
            x3Index[i]=1;
            x3CurrentvId[i]=1;  
        }
    }
    function init() external{
        require(msg.sender==creation,"Only contract owner"); 
        for (uint8 i = 0; i < 4; i++) {
            registration(id2[i], id1);
            _buyNewLevel(id2[i], 2);
            _buyNewLevel(id2[i], 3);
            _buyNewLevel(id2[i], 4);
            _buyNewLevel(id2[i], 5);
            _buyNewLevel(id2[i], 6);
        }
    }
    function Invest(address referrerAddress) external {
        tokenDAI.transferFrom(msg.sender, address(this), packagePrice[1]);
        registration(msg.sender, referrerAddress);
    }
    function InvestAnother(address userAddress,address referrerAddress) external {
        tokenDAI.transferFrom(msg.sender, address(this), packagePrice[1]);
        registration(userAddress, referrerAddress);
    }
    function BuyBooster(uint256 _amount) external {
        tokenDAI.transferFrom(msg.sender, address(this),_amount);
        require(isUserExists(msg.sender), "user is not exists. Register first.");        
        require(_amount>=10e6, "Amount should be 10 usdt!");
        emit booster(msg.sender,_amount);
    }
    
    function BuyNewPackage(uint8 level) external {
        tokenDAI.transferFrom(msg.sender, address(this),packagePrice[level]);  
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(level > 1 && level <= 6, "invalid level");
        require(!users[msg.sender].activeLevels[level], "level already activated");
        require(users[msg.sender].activeLevels[level-1], "buy previous level first");
        _buyNewLevel(msg.sender, level); 
    }
    function BuyNewPackageAnother(address userAddress,uint8 level) external {
        tokenDAI.transferFrom(msg.sender, address(this),packagePrice[level]);  
        require(isUserExists(userAddress), "user is not exists. Register first.");
        require(level > 1 && level <= 6, "invalid level");
        require(!users[userAddress].activeLevels[level], "level already activated");
        require(users[userAddress].activeLevels[level-1], "buy previous level first");
        _buyNewLevel(userAddress, level); 
        
    }
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            rank:0,
            referrer: referrerAddress,
            partnersCount: uint(0),
            teamCount:0,
            directincome:0,
            sponsorincome:0,
            levelincome:0,            
            autopoolincome:0,
            clubincome:0,
            teamincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeLevels[1] = true;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        releaseHoldAutoPooolAmount(referrerAddress,1);
        uint256 dayNow = getCurDay();
        _updateDirect5User(users[userAddress].referrer, dayNow);
        clubPool += clubfund[1];
        _distributelevelIncome(userAddress, directprice[1],1);
        address upline = users[userAddress].referrer;
        for(uint8 i = 1; i <= LAST_LEVEL; i++){
            if(upline != address(0)){
                users[upline].teamCount++;
                manageReward(upline);
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
        address freeAutoPoolReferrer = findFreeAutoPoolReferrer(1);
        users[userAddress].autopoolMatrix[1].currentReferrer = freeAutoPoolReferrer;
        updateAutoPoolReferrer(userAddress, freeAutoPoolReferrer, 1);

        address freeLevelReferrer = findFreeLevelReferrer(1);
        users[userAddress].levelMatrix[1].currentReferrer = freeLevelReferrer;
        updateLevelReferrer(userAddress, freeLevelReferrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _buyNewLevel(address userAddress, uint8 level) private {
        users[userAddress].activeLevels[level] = true;
        clubPool += clubfund[level];
        releaseHoldAmount(userAddress,level);
        _distributelevelIncome(userAddress, directprice[level],level);
        
        address freeAutoPoolReferrer = findFreeAutoPoolReferrer(level);
        users[userAddress].autopoolMatrix[level].currentReferrer = freeAutoPoolReferrer;
        updateAutoPoolReferrer(userAddress, freeAutoPoolReferrer,level);

        address freeLevelReferrer = findFreeLevelReferrer(level);
        users[userAddress].levelMatrix[level].currentReferrer = freeLevelReferrer;
        updateLevelReferrer(userAddress, freeLevelReferrer, level);

        emit Upgrade(userAddress,level);
    }
    function releaseHoldAmount(address userAddress, uint8 level) private {
        for (uint8 i = level; i >=2; i--) {
            uint256 _releasedirectamount=holdInfo[userAddress].directhold[level];
            if(_releasedirectamount>0){
                users[userAddress].directincome += _releasedirectamount;
                users[userAddress].totalincome += _releasedirectamount;
                holdInfo[userAddress].directhold[level]=0;
            }
            uint256 _releasesponsoramount=holdInfo[userAddress].sponsorhold[level];
            if(_releasesponsoramount>0){
                users[userAddress].sponsorincome += _releasesponsoramount;
                users[userAddress].totalincome += _releasesponsoramount;
                holdInfo[userAddress].sponsorhold[level]=0;
            }
            uint256 _releaseautopoolamount=holdInfo[userAddress].autopoolhold[level-1];
            if(_releaseautopoolamount>0 && users[userAddress].partnersCount>=directCond[level-1]){
                users[userAddress].autopoolincome += _releaseautopoolamount;
                users[userAddress].totalincome += _releaseautopoolamount;
                holdInfo[userAddress].autopoolhold[level-1]=0;
            }
            if(level==6){
                uint256 _releaseautopoolamount6=holdInfo[userAddress].autopoolhold[level];
                if(_releaseautopoolamount6>0 && users[userAddress].partnersCount>=directCond[level]){
                    users[userAddress].autopoolincome += _releaseautopoolamount6;
                    users[userAddress].totalincome += _releaseautopoolamount6;
                    holdInfo[userAddress].autopoolhold[level]=0;
                }
            }
        }
    }
    function releaseHoldAutoPooolAmount(address userAddress, uint8 level) private {
        uint256 _releaseautopoolamount=holdInfo[userAddress].autopoolhold[level];
        if(_releaseautopoolamount>0 && users[userAddress].partnersCount>=directCond[level]){
            users[userAddress].autopoolincome += _releaseautopoolamount;
            users[userAddress].totalincome += _releaseautopoolamount;
            holdInfo[userAddress].autopoolhold[level]=0;
        }
    }
    function _distributelevelIncome(address _user, uint256 _amount,uint8 level) private {
        address _referrer = users[_user].referrer;    
        holdInfo[_referrer].directincome += _amount;
        emit Transaction(_referrer,_user,_amount,level,1);
        if(users[_referrer].activeLevels[level])
        {
            users[_referrer].directincome += _amount;
            users[_referrer].totalincome += _amount;
        }
        else {
            holdInfo[_referrer].directhold[level] += _amount;
        }
        address _sponsor = users[_user].referrer; 
        uint256 reward=sponsorprice[level];
        holdInfo[_sponsor].sponsorincome += reward;
        emit Transaction(_sponsor,_user,reward,level,1);
        if(users[_sponsor].activeLevels[level])
        {
            users[_sponsor].sponsorincome += reward;
            users[_sponsor].totalincome += reward;
        }
        else {
            holdInfo[_sponsor].sponsorhold[level] += reward;
        }
    }
    function manageReward(address _user) private {
        uint8 rank=users[_user].rank;
        uint8 nextrank=rank+1;
        if(users[_user].teamCount>=teamCount[nextrank] && users[_user].partnersCount>=teamdirectCond[nextrank] && nextrank<=6)
        {
            users[_user].rank=nextrank;
            users[_user].teamincome+=teamIncome[nextrank];
            users[_user].totalincome+=teamIncome[nextrank];
            emit Transaction(_user,id1,teamIncome[nextrank],1,5);  
        }
        if(rank==6)
        {
            users[_user].teamCount=1;
            users[_user].rank=0;
            holdInfo[_user].teamCount+=teamCount[6];
        }
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStepWeekly){  
            uint256 dayNow = getCurDay();
           _distribute5DirectPool(dayNow);
           clubPool=0;
           lastDistribute = lastDistribute+timeStepWeekly;
        }
    }    
    function getDirect5Length(uint256 _dayNow) external view returns(uint) {
        return dayDirect5Users[_dayNow].length;
    }    
    function _distribute5DirectPool(uint256 _dayNow) public {
        uint256 direct5Bonus=clubPool*40/100;
        uint256 direct10Bonus=clubPool*30/100;
        uint256 direct15Bonus=clubPool*20/100;
        uint256 direct25Bonus=clubPool*10/100;
        uint256 direct5Count=0;
        uint256 direct10Count=0;
        uint256 direct15Count=0;
        uint256 direct25Count=0;
        for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
            address userAddr = dayDirect5Users[_dayNow - 1][i];
            if(userLayerDayDirect5[_dayNow-1][userAddr]>= 5){
                direct5Count +=1;
            }
            if(userLayerDayDirect5[_dayNow-1][userAddr]>= 10){
                direct10Count +=1;
            }
            if(userLayerDayDirect5[_dayNow-1][userAddr]>= 15){
                direct15Count +=1;
            }
            if(userLayerDayDirect5[_dayNow-1][userAddr]>= 25){
                direct25Count +=1;
            }
        }
        if(direct5Count > 0){
            uint256 reward = direct5Bonus/direct5Count;
            for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect5Users[_dayNow - 1][i];
                if(userLayerDayDirect5[_dayNow-1][userAddr]>=5 && userAddr != address(0)){
                    users[userAddr].clubincome += reward;
                    users[userAddr].totalincome += reward;
                    emit Transaction(id1,userAddr,reward,1,4);
                }
            }        
            direct5Bonus = 0;
        }
        else {
            users[id1].clubincome += direct5Bonus;
            users[id1].totalincome += direct5Bonus;
        }
        if(direct10Count > 0){
            uint256 reward = direct10Bonus/direct10Count;
            for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect5Users[_dayNow - 1][i];
                if(userLayerDayDirect5[_dayNow-1][userAddr]>=10 && userAddr != address(0)){
                    users[userAddr].clubincome += reward;
                    users[userAddr].totalincome += reward;
                    emit Transaction(id1,userAddr,reward,2,4);
                }
            }        
            direct10Bonus = 0;
        }
        else {
            users[id1].clubincome += direct10Bonus;
            users[id1].totalincome += direct10Bonus;
        }
        if(direct15Count > 0){
            uint256 reward = direct15Bonus/direct15Count;
            for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect5Users[_dayNow - 1][i];
                if(userLayerDayDirect5[_dayNow-1][userAddr]>=15 && userAddr != address(0)){
                    users[userAddr].clubincome += reward;
                    users[userAddr].totalincome += reward;
                    emit Transaction(id1,userAddr,reward,3,4);
                }
            }        
            direct15Bonus = 0;
        }
        else {
            users[id1].clubincome += direct15Bonus;
            users[id1].totalincome += direct15Bonus;
        }
        if(direct25Count > 0){
            uint256 reward = direct25Bonus/direct25Count;
            for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect5Users[_dayNow - 1][i];
                if(userLayerDayDirect5[_dayNow-1][userAddr]>=25 && userAddr != address(0)){
                    users[userAddr].clubincome += reward;
                    users[userAddr].totalincome += reward;
                    emit Transaction(id1,userAddr,reward,4,4);
                }
            }        
            direct25Bonus = 0;
        }
        else {
            users[id1].clubincome += direct25Bonus;
            users[id1].totalincome += direct25Bonus;
        }
    }
	function usersActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    function usersDirectHold(address userAddress, uint8 level) public view returns(uint256) {
        return holdInfo[userAddress].directhold[level];
    }
    function usersSponsorHold(address userAddress, uint8 level) public view returns(uint256) {
        return holdInfo[userAddress].sponsorhold[level];
    }
    function usersAutoPoolHold(address userAddress, uint8 level) public view returns(uint256) {
        return holdInfo[userAddress].autopoolhold[level];
    }
    function findFreeLevelReferrer(uint8 level) public view returns(address){
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
    } 
    function findFreeAutoPoolReferrer(uint8 level) public view returns(address){
            uint256 id=x2CurrentvId[level];
            return x2vId_number[level][id];
    } 
    function getWithdrawable(address userAddress) public view returns(uint256){  
        //uint256 bal = tokenDAI.balanceOf(address(this));
        //if(msg.sender==creation) return bal;          
        return (users[userAddress].totalincome - users[userAddress].totalwithdraw);
    }
    function usersAutoPool(address userAddress, uint8 level,uint8 step) public view returns(address, address[] memory) {
        return (users[userAddress].autopoolMatrix[level].currentReferrer,
                users[userAddress].autopoolMatrix[level].referrals[step]);
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function updateAutoPoolReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        address upline = referrerAddress;
        uint place=0;
        for(uint i=1; i <= 10; i++){
            users[upline].autopoolMatrix[level].referrals[i].push(userAddress); 
            if (users[upline].autopoolMatrix[level].referrals[1].length == 2 && i==1) {
                x2CurrentvId[level]=x2CurrentvId[level]+1;
            }  
            uint leveluser = 2**i;
            if (users[upline].autopoolMatrix[level].referrals[i].length == leveluser) {
                uint256 autopoolincome=autopoolPrice[level]*leveluser;
                holdInfo[upline].autopoolincome += autopoolincome;
                if((users[upline].activeLevels[level+1] && users[upline].partnersCount>=directCond[level]) || (users[upline].activeLevels[6] && users[upline].partnersCount>=directCond[6]))
                {
                    users[upline].autopoolincome +=autopoolincome;                     
                    users[upline].totalincome +=autopoolincome;
                }
                else 
                {
                    holdInfo[upline].autopoolhold[level] += autopoolincome;
                }
                emit Transaction(upline,userAddress,autopoolincome,1,3);
            } 
            place +=i==1?0:2**(i-1);
            emit NewUserPlace(userAddress, upline,1, level,uint8(place)+ uint8(users[upline].autopoolMatrix[level].referrals[i].length));
            if(upline!=id1){
                upline = users[upline].autopoolMatrix[level].currentReferrer;
            }
            else {
                break;
            }  
        }      
    }   
    function updateLevelReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        
        users[referrerAddress].levelMatrix[level].referrals.push(userAddress); 
        if (users[referrerAddress].levelMatrix[level].referrals.length == 3) {
            x3CurrentvId[level]=x3CurrentvId[level]+1;
        } 
        address upline = referrerAddress;
        uint8 i = 1;
        for(i=1; i <= LAST_LEVEL; i++){            
            if(upline != address(0)){
                uint256 reward=levelPercents[level]; 
                users[upline].levelincome += reward;                       
                users[upline].totalincome +=reward;
                emit Transaction(upline,userAddress,reward,level,2);
                upline = users[upline].levelMatrix[level].currentReferrer;
            }
            else {
                break;
            }
        }      
        uint256 totalrestreward=0;
        for(; i <= LAST_LEVEL; i++){  
            uint256 reward=levelPercents[level];         
            totalrestreward+=reward;          
        }
        if(totalrestreward>0){
            users[id1].levelincome += totalrestreward;                       
            users[id1].totalincome +=totalrestreward;
            emit Transaction(id1,userAddress,totalrestreward,level,18);
        }
    }   
    function boosterWithdraw(address _user,uint256 _amount) external
    {
        require(msg.sender==creation,"Only owner");
        tokenDAI.transfer(_user,_amount); 
        emit withdraw(_user,_amount);
    }
    function _updateDirect5User(address _user, uint256 _dayNow) private {
        userLayerDayDirect5[_dayNow][_user] += 1;
        bool updated;
        for(uint256 i = 0; i < dayDirect5Users[_dayNow].length; i++){
            address direct3User = dayDirect5Users[_dayNow][i];
            if(direct3User == _user){
                updated = true;
                break;
            }
        }
        if(!updated && userLayerDayDirect5[_dayNow][_user]>=5){
            dayDirect5Users[_dayNow].push(_user);
        }
    } 
    function getCurDay() public view returns(uint256) {
        return (block.timestamp-startTime)/timeStepWeekly;
    } 
    function IncomeWithdraw() public
    {
        uint256 balanceReward = getWithdrawable(msg.sender);
        require(balanceReward>=0, "Insufficient reward to withdraw!");
        users[msg.sender].totalwithdraw+=balanceReward;
        tokenDAI.transfer(msg.sender,balanceReward*95/100); 
        tokenDAI.transfer(createrWallet,balanceReward*5/100); 
        emit withdraw(msg.sender,balanceReward);
    }
    
}