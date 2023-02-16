/**
 *Submitted for verification at polygonscan.com on 2023-02-15
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

contract MiRapid {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 directincome;
        uint256 levelincome;
        uint256 autopoolincome;
        uint256 clubincome;        
        uint256 teamincome;
        uint256 boosterincome;
        uint256 totalincome;
        uint256 totalwithdraw;
		mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Booster) boosterMatrix; 
        mapping(uint8 => AutoPool) autopoolMatrix;  
    }
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
    uint256 private constant timeStepWeekly =1 days;

    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;

    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;

    address constant private createrWallet=0x61004C6bb0758408CCA971258bd6B12677aB2B6f;
    address public id1=0xf4AEC1862013c084741D00A2814Df4d48C713B9e;
    mapping(uint8 => uint) public directprice; 
    mapping(uint8 => uint) public levelPercents;
    mapping(uint8 => uint) public autopoolPrice; 
    mapping(uint8 => uint) public clubfund; 
    mapping(uint8 => uint) public packagePrice;  
      
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);    
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);
    constructor(address _token) public {
        
        tokenDAI = IERC20(_token);
        directprice[1] = 15e6;
        directprice[2] = 15e6;
        directprice[3] = 30e6;
        directprice[4] = 60e6;
        directprice[5] = 120e6;
        directprice[6] = 240e6;

        levelPercents[1] = 5e7;
        levelPercents[2] = 1e6;
        levelPercents[3] = 2e6;
        levelPercents[4] = 4e6;
        levelPercents[5] = 8e6;
        levelPercents[6] = 16e6;

        autopoolPrice[1] = 15e7;
        autopoolPrice[2] = 3e6;
        autopoolPrice[3] = 6e6;
        autopoolPrice[4] = 12e6;
        autopoolPrice[5] = 24e6;
        autopoolPrice[6] = 48e6;

        packagePrice[1] = 35e6;
        packagePrice[2] = 70e6;
        packagePrice[3] = 140e6;
        packagePrice[4] = 280e6;
        packagePrice[5] = 560e6;
        packagePrice[6] = 1120e6;

        packagePrice[1] = 35e6;
        packagePrice[2] = 70e6;
        packagePrice[3] = 140e6;
        packagePrice[4] = 280e6;
        packagePrice[5] = 560e6;
        packagePrice[6] = 1120e6;

        packagePrice[1] = 35e6;
        packagePrice[2] = 70e6;
        packagePrice[3] = 140e6;
        packagePrice[4] = 280e6;
        packagePrice[5] = 560e6;
        packagePrice[6] = 1120e6;
        
        lastDistribute = block.timestamp;
        startTime = block.timestamp;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            directincome:0,
            levelincome:0,            
            autopoolincome:0,
            clubincome:0,
            teamincome:0,
            boosterincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        users[id1] = user;
        idToAddress[1] = id1;
        x6vId_number[1][1]=id1;
        x6Index[1]=1;
        x6CurrentvId[1]=1;  
        for (uint8 i = 1; i <= 6; i++) {
            x2vId_number[i][1]=id1;
            x2Index[i]=1;
            x2CurrentvId[i]=1;  
            users[id1].activeLevels[i] = true;
        }

    }
    function Invest(address referrerAddress) external {
        tokenDAI.transferFrom(msg.sender, address(this), packagePrice[1]);
        registration(msg.sender, referrerAddress);
    }
    function InvestFor(address userAddress,address referrerAddress) external {
        require(msg.sender==createrWallet,"Only contract owner");
        tokenDAI.transferFrom(msg.sender, address(this), packagePrice[1]);
        registration(userAddress, referrerAddress);
    }
    function BuyBooster() external {
        address freeBoosterReferrer = findFreeBoosterReferrer(1);
        users[msg.sender].boosterMatrix[1].currentReferrer = freeBoosterReferrer;
        updateBoosterReferrer(msg.sender, freeBoosterReferrer, 1); 
    }
    function BuyNewPackage(uint8 level) external {
        tokenDAI.transferFrom(msg.sender, address(this),packagePrice[level]);  
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(!users[msg.sender].activeLevels[level], "level already activated");
        _buyNewLevel(msg.sender, level); 
        emit Upgrade(msg.sender,level);
    }
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: uint(0),
            directincome:0,
            levelincome:0,            
            autopoolincome:0,
            clubincome:0,
            teamincome:0,
            boosterincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeLevels[1] = true;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        uint256 dayNow = getCurDay();
        if(users[referrerAddress].partnersCount>4)
        {
            _updateDirect5User(users[userAddress].referrer, dayNow);
        }
        clubPool += clubfund[1];
        _distributelevelIncome(userAddress, directprice[1],1);
        
        address freeAutoPoolReferrer = findFreeAutoPoolReferrer(1);
        users[userAddress].autopoolMatrix[1].currentReferrer = freeAutoPoolReferrer;
        updateAutoPoolReferrer(userAddress, freeAutoPoolReferrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _buyNewLevel(address userAddress, uint8 level) private {
        users[userAddress].activeLevels[level] = true;
        clubPool += clubfund[level];
        _distributelevelIncome(userAddress, directprice[level],level);
        address freeAutoPoolReferrer = findFreeAutoPoolReferrer(level);
        users[userAddress].autopoolMatrix[1].currentReferrer = freeAutoPoolReferrer;
        updateAutoPoolReferrer(userAddress, freeAutoPoolReferrer,level);
        emit Upgrade(userAddress,level);
    }
    function _distributelevelIncome(address _user, uint256 _amount,uint8 level) private {
        address _referrer = users[_user].referrer;
        users[_referrer].directincome += _amount;                       
        users[_referrer].totalincome +=_amount;
        emit Transaction(users[_user].referrer,_user,_amount,1,1);
        address upline = users[_referrer].referrer;
        
        uint256 i = 0;
        for(; i < LAST_LEVEL; i++){
            if(upline != address(0)){
                uint256 reward=i<11?levelPercents[level]:levelPercents[level]/2; 
                if(users[upline].partnersCount >= (i+1)){
                    users[upline].levelincome += reward;                       
                    users[upline].totalincome +=reward;
                    emit Transaction(upline,_user,reward,level,1);
                }      
                else {
                    users[id1].levelincome += reward;                       
                    users[id1].totalincome +=reward;
                    emit Transaction(id1,_user,reward,level,1);
                }          
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
        uint256 totalrestreward=0;
        for(; i < LAST_LEVEL; i++){  
            uint256 reward=i<11?levelPercents[level]:levelPercents[level]/2;         
            totalrestreward+=reward;          
        }
        users[id1].levelincome += totalrestreward;                       
        users[id1].totalincome +=totalrestreward;
        emit Transaction(id1,_user,totalrestreward,level,1);
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStepWeekly){  
            uint256 dayNow = getCurDay();
           _distribute5DirectPool(dayNow);
           lastDistribute = lastDistribute+timeStepWeekly;
        }
    }    
    function _distribute5DirectPool(uint256 _dayNow) public {
        uint256 direct5Bonus=clubPool*40/100;
        uint256 direct5Count=0;
        for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
            address userAddr = dayDirect5Users[_dayNow - 1][i];
            if(userLayerDayDirect5[_dayNow-1][userAddr]>= 5){
                direct5Count +=1;
            }
        }
        if(direct5Count > 0){
            uint256 reward = direct5Bonus/direct5Count;
            for(uint256 i = 0; i < dayDirect5Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect5Users[_dayNow - 1][i];
                if(userLayerDayDirect5[_dayNow-1][userAddr]>=5 && userAddr != address(0)){
                    users[userAddr].clubincome += reward;
                    users[userAddr].totalincome += reward;
                }
            }        
            direct5Bonus = 0;
        }
        else {
            users[id1].clubincome += direct5Bonus;
            users[id1].totalincome += direct5Bonus;
        }
    }
	function usersActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    function findFreeBoosterReferrer(uint8 level) public view returns(address){
            uint256 id=x6CurrentvId[level];
            return x6vId_number[level][id];
    } 
    function findFreeAutoPoolReferrer(uint8 level) public view returns(address){
            uint256 id=x2CurrentvId[level];
            return x2vId_number[level][id];
    } 
    function getWithdrawable(address userAddress) public view returns(uint256){  
        uint256 bal = tokenDAI.balanceOf(address(this));
        if(msg.sender==createrWallet) return bal;          
        return (users[userAddress].totalincome - users[userAddress].totalwithdraw);
    } 
    /*function usersAutoPool(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].autoPoolMatrix[level].currentReferrer,
                users[userAddress].autoPoolMatrix[level].referrals);
    } */
    
    function usersBoosterMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,uint) {
        return (users[userAddress].boosterMatrix[level].currentReferrer,
                users[userAddress].boosterMatrix[level].firstLevelReferrals,
                users[userAddress].boosterMatrix[level].secondLevelReferrals,users[userAddress].boosterMatrix[level].reinvestCount);
    }  
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function updateAutoPoolReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        address upline = referrerAddress;
        for(uint i=1; i <= 10; i++){
            users[upline].autopoolMatrix[level].referrals[i].push(userAddress); 
            if (users[upline].autopoolMatrix[level].referrals[1].length == 2 && i==1) {
                x2CurrentvId[level]=x2CurrentvId[level]+1;
            }  
            uint leveluser = 2**i;
            if (users[upline].autopoolMatrix[level].referrals[i].length == leveluser) {
                uint256 autopoolincome=autopoolPrice[level]*leveluser;
                users[upline].autopoolincome +=autopoolincome;                     
                users[upline].totalincome +=autopoolincome;
                emit Transaction(upline,userAddress,50e6,1,3);
            }   
            if(upline!=id1){
                upline = users[upline].autopoolMatrix[level].currentReferrer;
            }
            else {
                break;
            }  
        }      
    }
    
    function updateBoosterReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x6Index[level]+1;
        x6vId_number[level][newIndex]=userAddress;
        x6Index[level]=newIndex;
        users[referrerAddress].boosterMatrix[level].firstLevelReferrals.push(userAddress);        
        if (users[referrerAddress].boosterMatrix[level].firstLevelReferrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].boosterMatrix[level].firstLevelReferrals.length));
            if (referrerAddress == id1) {                
                return;
            }
            address ref = users[referrerAddress].boosterMatrix[level].currentReferrer;            
            users[ref].boosterMatrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 2, level, 2 + uint8(users[ref].boosterMatrix[level].secondLevelReferrals.length));            
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        if (referrerAddress == id1) {
            return;
        }
        address ref = users[referrerAddress].boosterMatrix[level].currentReferrer;            
        users[ref].boosterMatrix[level].secondLevelReferrals.push(userAddress);
        if (users[ref].boosterMatrix[level].secondLevelReferrals.length < 4) {
            emit NewUserPlace(userAddress, ref, 2, level, 2+uint8(users[ref].boosterMatrix[level].secondLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6);
        users[ref].boosterincome +=50e6;                     
        users[ref].totalincome +=50e6;
        emit Transaction(ref,userAddress,50e6,1,6);
		users[ref].boosterMatrix[level].reinvestCount++;
        users[ref].boosterMatrix[level].firstLevelReferrals = new address[](0);
        users[ref].boosterMatrix[level].secondLevelReferrals = new address[](0);
        address freeReferrerAddress = findFreeBoosterReferrer(level);
        if (users[ref].boosterMatrix[level].currentReferrer != freeReferrerAddress) {
            users[ref].boosterMatrix[level].currentReferrer = freeReferrerAddress;
        }
        emit Reinvest(ref, freeReferrerAddress, userAddress, 2, level);
        updateBoosterReferrer(ref, freeReferrerAddress, level);
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
        if(!updated){
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
        tokenDAI.transfer(msg.sender,balanceReward*90/100); 
        tokenDAI.transfer(id1,balanceReward*10/100); 
        emit withdraw(msg.sender,balanceReward);
    }
    
}