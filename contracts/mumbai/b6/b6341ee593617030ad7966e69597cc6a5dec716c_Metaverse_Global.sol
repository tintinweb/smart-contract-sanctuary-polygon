/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-31
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
contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
contract Metaverse_Global is Ownable {
    struct User {
        uint id;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        bool islevelActive;
        uint256 maxDeposit;
        bool isPoolActive;
        mapping(uint8 => AutoPool) autoMatrix;       
    }    
    struct AutoPool {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
    }
    struct RoyaltyInfo{
        uint256 payouts;
        uint256 directincome;
        uint256 levelincome;
        uint256 autopoolincome;
        uint256 topsponsor;
        uint256 topvolume;
        uint256 totalincome;
        uint256 totalwithdraw;
    }
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts; 
        bool isactive;
    }
    mapping(address => User) public users;
    mapping(address=>RoyaltyInfo) public royaltyInfo;
    mapping(address => OrderInfo[]) public orderInfos;
    IERC20 public tokenAPLX;
    
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(uint256=>address[5]) public dayTopSponsors;
    mapping(uint256=>address[5]) public dayTopVolume;
    uint public lastUserId = 2;
    address public id1;
    uint256 public topSponsorPool;
    uint256 public topVolumePool;

    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public autoPoolIncome;

    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;
    uint256 private constant directPercents = 10;
    uint256[7] private levelPercents = [5,3,2,1,1,1,2];
    uint256[7] private levelConditions = [1,3,5,7,9,11,13];
	
    mapping(uint256 => mapping(address => uint256)) public userLayerDaySponsorCount;
    mapping(uint256 => mapping(address => uint256)) public userLayerDayVolume;

    uint256 public lastDistribute;
    uint256 public startTime;

    uint256 private dayRewardPercents = 5;
    uint256 private constant timeStepdaily = 30*60;
    uint256 private constant timeStepweekly = 1 days; 
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    
    constructor(address _token) public {
        
        levelPrice[1] = 1000e8;
        levelPrice[2] = 2000e8;
        levelPrice[3] = 3000e8;
        levelPrice[4] = 5000e8;
        levelPrice[5] = 7000e8;
        levelPrice[6] = 10000e8;
        levelPrice[7] = 15000e8;
        levelPrice[8] = 20000e8;
        levelPrice[9] = 30000e8;
        levelPrice[10] = 40000e8;

        autoPoolIncome[1] = 1700e8;
        autoPoolIncome[2] = 4500e8;
        autoPoolIncome[3] = 10200e8;
        autoPoolIncome[4] = 23000e8;
        autoPoolIncome[5] = 68000e8;
        autoPoolIncome[6] = 170000e8;
        autoPoolIncome[7] = 450000e8;
        autoPoolIncome[8] = 1020000e8;

        id1 = msg.sender;
        tokenAPLX = IERC20(_token);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            islevelActive:true,
            isPoolActive:true,
            maxDeposit:0
        });
        lastDistribute = block.timestamp;
        startTime = block.timestamp;
        users[id1] = user;
        idToAddress[1] = id1;
        userIds[1] = id1;
        for (uint8 i = 1; i <= 8; i++) { 
            x6vId_number[i][1]=id1;
            x6Index[i]=1;
            x6CurrentvId[i]=1;         
        } 
    }
    function registrationExt(address referrerAddress,uint8 level) external {
        tokenAPLX.transferFrom(msg.sender, address(this),levelPrice[level]);
        registration(msg.sender, referrerAddress,level);
    }
    
    function buyNewLevel(uint8 level) external {
        tokenAPLX.transferFrom(msg.sender, address(this),levelPrice[level]);  
        require(isUserExists(msg.sender), "user is not exists. Register first."); 
        _deposit(msg.sender, levelPrice[level]);
        emit Upgrade(msg.sender,level);
    }
    function registration(address userAddress, address referrerAddress,uint8 level) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            entry_time:block.timestamp,
            partnersCount: 0,
            islevelActive:false,
            isPoolActive:false,
            maxDeposit:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;

        uint256 dayNow = getCurDay();
        _updateTopSponsor(users[userAddress].referrer, dayNow);
        _updateTopVolume(users[userAddress].referrer,levelPrice[level], dayNow);
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        if((users[referrerAddress].entry_time+15 days)>=block.timestamp && !users[referrerAddress].islevelActive)
        {
            users[referrerAddress].islevelActive=true;
        }
        _deposit(msg.sender, levelPrice[level]);
        if(users[referrerAddress].partnersCount>1 && !users[referrerAddress].isPoolActive)
        {
           address freeAutoPoolReferrer = findFreeG6Referrer(1);
           users[referrerAddress].autoMatrix[1].currentReferrer = freeAutoPoolReferrer;
           updateAutoPoolReferrer(referrerAddress, freeAutoPoolReferrer, 1);
           users[referrerAddress].isPoolActive=true;
        }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function _deposit(address _user, uint256 _amount) private {     
        if(users[_user].maxDeposit == 0){
            users[_user].maxDeposit = _amount;
        }else if(users[_user].maxDeposit < _amount){
            users[_user].maxDeposit = _amount;
        }
        _distributeDeposit(_amount);
        distributePoolRewards();
        royaltyInfo[users[_user].referrer].directincome += _amount*directPercents/100;                       
        royaltyInfo[users[_user].referrer].totalincome +=_amount*directPercents/100;
        _distributelevelIncome(msg.sender, _amount);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            false
        ));
    } 
    function _distributeDeposit(uint256 _amount) private {
        uint256 topSponsor = _amount*2/100;
        topSponsorPool += topSponsor;
        uint256 topVolume = _amount*3/100;
        topVolumePool += topVolume;        
    }
    function _distributelevelIncome(address _user, uint256 _amount) private {
        address upline = users[_user].referrer;
        for(uint256 i = 0; i < 7; i++){
            if(upline != address(0)){
                uint256 reward=_amount*levelPercents[i]/100; 
                if(users[upline].partnersCount >= levelConditions[i] && users[upline].islevelActive){
                    royaltyInfo[upline].levelincome += reward;                       
                    royaltyInfo[upline].totalincome +=reward;
                }                
                upline = users[upline].referrer;
            }else{
                break;
            }
        }
    }
    function maxPayoutOf(uint256 _amount,address _user) view external returns(uint256) {
        if(users[_user].partnersCount<6) return _amount * 2;
        else return _amount * 3;
    }
    function dailyPayoutOf(address _user) public {
        uint256 max_payout=0;
        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(order.isactive && block.timestamp>order.deposit_time){
                max_payout = this.maxPayoutOf(order.amount,_user);   
                if(order.payouts<max_payout){
                    uint256 dailypayout = (order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 1000) - order.payouts;
                    if(order.payouts+dailypayout > max_payout){
                        dailypayout = max_payout-order.payouts;
                    }
                    royaltyInfo[_user].payouts += dailypayout;            
                    royaltyInfo[_user].totalincome +=dailypayout;
                    order.payouts+=dailypayout;
                }
                else {
                    order.isactive=false;
                }
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
        if (users[referrerAddress].autoMatrix[level].firstLevelReferrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].autoMatrix[level].firstLevelReferrals.length));
            if (referrerAddress == id1) {
                return;
            }
            address ref = users[referrerAddress].autoMatrix[level].currentReferrer;            
            users[ref].autoMatrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 2, level, 3 + uint8(users[ref].autoMatrix[level].secondLevelReferrals.length));
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 3);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        if (referrerAddress == id1) {
            return;
        }
        address ref = users[referrerAddress].autoMatrix[level].currentReferrer;            
        users[ref].autoMatrix[level].secondLevelReferrals.push(userAddress);
        if (users[ref].autoMatrix[level].secondLevelReferrals.length < 9) {
            emit NewUserPlace(userAddress, ref, 2, level, 3+uint8(users[ref].autoMatrix[level].secondLevelReferrals.length));
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 12);
        tokenAPLX.transfer(referrerAddress, autoPoolIncome[level]);
        ++level;
		if(level<9 && ref!=id1){ 
            address freeReferrerAddress = findFreeG6Referrer(level);
            if (users[ref].autoMatrix[level].currentReferrer != freeReferrerAddress) {
                users[ref].autoMatrix[level].currentReferrer = freeReferrerAddress;
            }
            updateAutoPoolReferrer(ref, freeReferrerAddress, level);
		}
    }
    
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStepweekly){  
            uint256 dayNow = getCurDay();
           _distributeTopSponsorPool(dayNow);
           _distributeTopVolumePool(dayNow); 
           lastDistribute = lastDistribute+timeStepweekly;
        }
    }    
    function _distributeTopSponsorPool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,10,10];
        for(uint256 i = 0; i < 5; i++){
            address userAddr = dayTopSponsors[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = (topSponsorPool*rates[i])/100;
                royaltyInfo[userAddr].topsponsor += reward;
                royaltyInfo[userAddr].totalincome += reward;
            }
        }
        topSponsorPool = 0;
    }
    function _distributeTopVolumePool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,10,10];
        for(uint256 i = 0; i < 5; i++){
            address userAddr = dayTopVolume[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = (topVolumePool*rates[i])/100;
                royaltyInfo[userAddr].topvolume += reward;
                royaltyInfo[userAddr].totalincome += reward;
            }
        }
        topVolumePool = 0;
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
    function _updateTopVolume(address _user,uint256 _amount, uint256 _dayNow) private {
        userLayerDayVolume[_dayNow][_user] += _amount;
        bool updated;
        for(uint256 i = 0; i < 5; i++){
            address topUser = dayTopVolume[_dayNow][i];
            if(topUser == _user){
                _reOrderTopVolume(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopVolume[_dayNow][4];
            if(userLayerDayVolume[_dayNow][lastUser] < userLayerDayVolume[_dayNow][_user]){
                dayTopVolume[_dayNow][4] = _user;
                _reOrderTopVolume(_dayNow);
            }
        }
    }
   
    function _reOrderTopVolume(uint256 _dayNow) private {
        for(uint256 i = 5; i > 1; i--){
            address topUser1 = dayTopVolume[_dayNow][i - 1];
            address topUser2 = dayTopVolume[_dayNow][i - 2];
            uint256 amount1 = userLayerDayVolume[_dayNow][topUser1];
            uint256 amount2 = userLayerDayVolume[_dayNow][topUser2];
            if(amount1 > amount2){
                dayTopVolume[_dayNow][i - 1] = topUser2;
                dayTopVolume[_dayNow][i - 2] = topUser1;
            }
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp-startTime)/timeStepweekly;
    }
    function rewardWithdraw() public
    {
        dailyPayoutOf(msg.sender);
        uint balanceReward = royaltyInfo[msg.sender].totalincome - royaltyInfo[msg.sender].totalwithdraw;

        require(balanceReward>=0, "Insufficient reward to withdraw!");
        royaltyInfo[msg.sender].totalwithdraw+=balanceReward;
        tokenAPLX.transfer(msg.sender,balanceReward);  
    }
}