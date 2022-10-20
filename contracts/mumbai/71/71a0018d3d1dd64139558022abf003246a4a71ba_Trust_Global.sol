/**
 *Submitted for verification at polygonscan.com on 2022-10-20
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
contract Trust_Global is Ownable {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX3Levels;  
        mapping(uint8 => bool) activeX6Levels;  
        mapping(uint8 => bool) activeG3Matrix;
        mapping(uint8 => X3) x3Matrix;     
        mapping(uint8 => G3) g3Matrix;     
        mapping(uint8 => X6) x6Matrix;  
        mapping(uint8 => G6) g6Matrix;       
    }
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    struct G3 {
        address currentReferrer;
        address[] referrals;
        uint reinvestCount;
        uint cycleCount;
    }
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    struct G6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;
        address cycleCount;
    }
    struct RoyaltyInfo{
        uint256[] royalty3;
        uint256 top;
        uint256 grtop;
        uint256 direct3;
        uint256 totalRevenue;
        uint256 totalRelease;
    }
    mapping(address=>RoyaltyInfo) public royaltyInfo;
    uint8 public constant LAST_LEVEL = 12;
    IERC20 public tokenDai;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(uint256=>address[5]) public dayTopUsers;
    mapping(uint256=>address[5]) public dayTopGR3Users;
    uint public lastUserId = 2;
    address public id1;
    uint256 public gR3Pool;
    uint256 public gR6Pool;
    

    mapping(uint8 => uint) public levelST3Price;
    mapping(uint8 => uint) public levelST6Price;
    mapping(uint8 => uint) public levelGT3Price;
    mapping(uint8 => uint) public levelGT6Price;
    mapping(uint8 => uint) public levelGR3Price;
    mapping(uint8 => uint) public levelGR6Price;

    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;

    mapping(uint8 => mapping(uint256 => address)) public x6vId_number;
    mapping(uint8 => uint256) public x6CurrentvId;
    mapping(uint8 => uint256) public x6Index;
	
	mapping(uint8 => mapping(uint256 => address)) public gR3Pool_User;
    mapping(uint8 => uint256) public gR3Index;
	
    mapping(uint256 => mapping(address => uint256)) public userLayerDaySponsorCount; 
    mapping(uint256 => mapping(address => uint256)) public userLayerDayGR3Count;
    uint256 public lastDistribute;
    uint256 public startTime;

    uint256 private constant timeStep = 1 days;    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level,uint8 mtype);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place,uint8 mtype);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    constructor(address _token) public {
        
        levelST3Price[1] = 7e18;
        levelGT3Price[1] = 2e18;            
        levelGR3Price[1] = 1e18;

        levelST6Price[1] = 9e18;
        levelGT6Price[1] = 2e18;
        levelGR6Price[1] = 1e18;

        for (uint8 i = 2; i <= 11; i++) {
            levelST3Price[i] = levelST3Price[i-1] * 2;            
            levelGT3Price[i] = levelGT3Price[i-1] * 2;            
            levelGR3Price[i] = levelGR3Price[i-1] * 2;

            levelST6Price[i] = levelST6Price[i-1] * 2;
            levelGT6Price[i] = levelGT6Price[i-1] * 2;
            levelGR6Price[i] = levelGR6Price[i-1] * 2;
        }
        
        id1 = msg.sender;
        tokenDai = IERC20(_token);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        lastDistribute = block.timestamp;
        startTime = block.timestamp;
        users[id1] = user;
        idToAddress[1] = id1;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {    
            x3vId_number[i][1]=id1;
            x3Index[i]=1;
            x3CurrentvId[i]=1;  
            users[id1].activeX3Levels[i] = true;
            x6vId_number[i][1]=id1;
            x6Index[i]=1;
            x6CurrentvId[i]=1;      
            users[id1].activeX6Levels[i] = true;          
        }
        for (uint8 i = 6; i <= LAST_LEVEL; i++) {  
            gR3Index[i]=1;
            gR3Pool_User[i][1]=id1;   
        }         
        userIds[1] = id1;
    }
    function registrationExt(address referrerAddress) external {
        tokenDai.transferFrom(msg.sender, address(this), (levelST3Price[1]+levelGT3Price[1]+levelGR3Price[1]));
        registration(msg.sender, referrerAddress);
    }

    function registrationFor(address userAddress, address referrerAddress) external onlyOwner {
        registration(userAddress, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external {         
        _buyNewLevel(msg.sender, matrix, level);
    }

    function buyNewLevelFor(address userAddress, uint8 matrix, uint8 level) external onlyOwner() {
        _buyNewLevel(userAddress, matrix, level);
    }

    function _buyNewLevel(address _userAddress, uint8 matrix, uint8 level) internal {
        require(isUserExists(_userAddress), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");       

        if (matrix == 1) {
            tokenDai.transferFrom(msg.sender, address(this), (levelST3Price[level]+levelGT3Price[level]+levelGR3Price[level]));
            require(level > 1 && level <= LAST_LEVEL, "invalid level");
            require(users[_userAddress].activeX3Levels[level-1], "buy previous level first");
            require(!users[_userAddress].activeX3Levels[level], "level already activated");

            if (users[_userAddress].x3Matrix[level-1].blocked) {
                users[_userAddress].x3Matrix[level-1].blocked = false;
            }
    
            address freeX3Referrer = findFreeX3Referrer(_userAddress, level);
            users[_userAddress].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[_userAddress].activeX3Levels[level] = true;
            updateX3Referrer(_userAddress, freeX3Referrer, level);

            address freeG3Referrer = findFreeG3Referrer(level);
            users[_userAddress].x3Matrix[level].currentReferrer = freeG3Referrer;
            updateG3Referrer(_userAddress, freeG3Referrer, level);
            gR3Pool = gR3Pool+levelGR3Price[level]; 
            if(level>5)
            {
                uint256 newIndex=x6Index[level]+1;
			    gR3Index[level]=newIndex;
                gR3Pool_User[level][newIndex]=id1; 
			}
            if(level==6)
            {
                uint256 dayNow = getCurDay();
               _updateTopUserGR3(users[_userAddress].referrer, dayNow);
            }
            emit Upgrade(_userAddress, freeX3Referrer, 1, level);

        } else {
            tokenDai.transferFrom(msg.sender, address(this), (levelST6Price[level]+levelGT6Price[level]+levelGR6Price[level]));
            if(level>1)
            {
                require(level > 1 && level <= LAST_LEVEL, "invalid level");
                require(users[_userAddress].activeX6Levels[level-1], "buy previous level first");
                require(!users[_userAddress].activeX6Levels[level], "level already activated"); 

                if (users[_userAddress].x6Matrix[level-1].blocked) {
                    users[_userAddress].x6Matrix[level-1].blocked = false;
                }
            }
            address freeX6Referrer = findFreeX6Referrer(_userAddress, level);
            users[_userAddress].activeX6Levels[level] = true;
            updateX6Referrer(_userAddress, freeX6Referrer, level);
            
            address freeG6Referrer = findFreeG6Referrer(level);
            users[_userAddress].x6Matrix[level].currentReferrer = freeG6Referrer;
            updateG6Referrer(_userAddress, freeG6Referrer, level);

            gR6Pool = gR6Pool+levelGR6Price[level]; 
            emit Upgrade(_userAddress, freeX6Referrer, 2, level);
        }
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStep){  
            uint256 dayNow = getCurDay();
            for(uint8 i = 6; i <= 12; i++){
                _distributeGR3Pool(i);
            }
           _distributeTopPool(dayNow); 
           _distributeTopGR3Pool(dayNow); 
           _distribute3DirectPool(dayNow);
           gR3Pool=0;     
           gR6Pool=0;      
           lastDistribute = block.timestamp;
        }
    }
    function _distributeGR3Pool(uint8 rank) public {
        uint256 managerCount=x6Index[rank];
        uint8[7] memory rates = [10, 11, 12,13,14,15,25];
        uint80[7] memory maxReward = [2000e18, 4000e18,8000e18,20000e18, 32000e18,64000e18,140000e18];
        if(managerCount > 0){
            uint256 reward = (gR3Pool*rates[rank-6])/100*managerCount;
            for(uint256 i = 0; i < managerCount; i++){
                if(royaltyInfo[gR3Pool_User[rank][i]].royalty3[rank] <= maxReward[rank-6]){
                    royaltyInfo[gR3Pool_User[rank][i]].royalty3[rank] += reward;
                    royaltyInfo[gR3Pool_User[rank][i]].totalRevenue = reward;
                }
            }     
        }
    }
    function _distributeTopPool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,15,5];
        uint256 topPool=gR6Pool*30/100;
        uint256 totalReward;
        for(uint256 i = 0; i < 3; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = (topPool*rates[i])/100;
                royaltyInfo[userAddr].top += reward;
                royaltyInfo[userAddr].totalRevenue += reward;
                totalReward += reward;
            }
        }
        if(topPool > totalReward){
            topPool -= totalReward;
        }else{
            topPool = 0;
        }
    }
    function _distributeTopGR3Pool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,15,5];
        uint256 topPool=gR6Pool*40/100;
        uint256 totalReward;
        for(uint256 i = 0; i < 3; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = (topPool*rates[i])/100;
                royaltyInfo[userAddr].grtop += reward;
                royaltyInfo[userAddr].totalRevenue += reward;
                totalReward += reward;
            }
        }
        if(topPool > totalReward){
            topPool -= totalReward;
        }else{
            topPool = 0;
        }
    }
    function _distribute3DirectPool(uint256 _dayNow) public {
        uint256 direct3Bonus=gR6Pool*30/100;
        uint256 totalReward;
        uint256 direct3Count;
        for(uint256 i = 0; i < dayTopUsers[_dayNow - 1].length; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            if(userLayerDaySponsorCount[_dayNow][userAddr]== 3){
                direct3Count +=1;
            }
        }
        if(direct3Count > 0){
            uint256 reward = direct3Bonus/direct3Count;
            for(uint256 i = 0; i < dayTopUsers[_dayNow - 1].length; i++){
                address userAddr = dayTopUsers[_dayNow - 1][i];
                if(userLayerDaySponsorCount[_dayNow][userAddr]==3 && userAddr != address(0)){
                    royaltyInfo[userAddr].direct3 += reward;
                    royaltyInfo[userAddr].totalRevenue += reward;
                    totalReward += reward;
                }
            }        
            if(direct3Bonus > totalReward){
                direct3Bonus -= totalReward;
            }else{
                direct3Bonus = 0;
            }
        }
    }
    
    function _updateTopUser(address _user, uint256 _dayNow) private {
        userLayerDaySponsorCount[_dayNow][_user] += 1;
        bool updated;
        for(uint256 i = 0; i < 5; i++){
            address topUser = dayTopUsers[_dayNow][i];
            if(topUser == _user){
                _reOrderTop(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopUsers[_dayNow][2];
            if(userLayerDaySponsorCount[_dayNow][lastUser] < userLayerDaySponsorCount[_dayNow][_user]){
                dayTopUsers[_dayNow][2] = _user;
                _reOrderTop(_dayNow);
            }
        }
    }

    function _reOrderTop(uint256 _dayNow) private {
        for(uint256 i = 5; i > 1; i--){
            address topUser1 = dayTopUsers[_dayNow][i - 1];
            address topUser2 = dayTopUsers[_dayNow][i - 2];
            uint256 count1 = userLayerDaySponsorCount[_dayNow][topUser1];
            uint256 count2 = userLayerDaySponsorCount[_dayNow][topUser2];
            if(count1 > count2){
                dayTopUsers[_dayNow][i - 1] = topUser2;
                dayTopUsers[_dayNow][i - 2] = topUser1;
            }
        }
    }
    function _updateTopUserGR3(address _user, uint256 _dayNow) private {
        userLayerDayGR3Count[_dayNow][_user] += 1;
        bool updated;
        for(uint256 i = 0; i < 5; i++){
            address topUser = dayTopGR3Users[_dayNow][i];
            if(topUser == _user){
                _reOrderTopGR3(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopGR3Users[_dayNow][2];
            if(userLayerDayGR3Count[_dayNow][lastUser] < userLayerDayGR3Count[_dayNow][_user]){
                dayTopGR3Users[_dayNow][2] = _user;
                _reOrderTopGR3(_dayNow);
            }
        }
    }

    function _reOrderTopGR3(uint256 _dayNow) private {
        for(uint256 i = 3; i > 1; i--){
            address topUser1 = dayTopGR3Users[_dayNow][i - 1];
            address topUser2 = dayTopGR3Users[_dayNow][i - 2];
            uint256 count1 = userLayerDaySponsorCount[_dayNow][topUser1];
            uint256 count2 = userLayerDaySponsorCount[_dayNow][topUser2];
            if(count1 > count2){
                dayTopGR3Users[_dayNow][i - 1] = topUser2;
                dayTopGR3Users[_dayNow][i - 2] = topUser1;
            }
        }
    }
    function getCurDay() public view returns(uint256) {
        return (block.timestamp-startTime)/timeStep;
    }
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        uint256 dayNow = getCurDay();
        _updateTopUser(users[userAddress].referrer, dayNow);
        users[userAddress].activeX3Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        address freeG3Referrer = findFreeG3Referrer(1);
        users[userAddress].x3Matrix[1].currentReferrer = freeG3Referrer;
        updateG3Referrer(userAddress, freeG3Referrer, 1);
        gR3Pool = gR3Pool+levelGR3Price[1]; 
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length),1);
            return sendETHDividendsS3(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3,1);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != id1) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level,1);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividendsS3(id1, userAddress, 1, level);
            users[id1].x3Matrix[level].reinvestCount++;
            emit Reinvest(id1, address(0), userAddress, 1, level,1);
        }
    }
    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length),1);
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == id1) {
                return sendETHDividendsS6(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,1);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,1);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3,1);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4,1);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5,1);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6,1);
                }
            }
            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),1);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length),1);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),1);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length),1);
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividendsS6(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != id1) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level,1);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(id1, address(0), userAddress, 2, level,1);
            sendETHDividendsS6(id1, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function findFreeG3Referrer(uint8 level) public view returns(address){
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
    } 
    function findFreeG6Referrer(uint8 level) public view returns(address){
            uint256 id=x6CurrentvId[level];
            return x6vId_number[level][id];
    }    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart);
    }
    function usersG3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].g3Matrix[level].currentReferrer,
                users[userAddress].g3Matrix[level].referrals);
    }

    function usersG6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory) {
        return (users[userAddress].g6Matrix[level].currentReferrer,
                users[userAddress].g6Matrix[level].firstLevelReferrals,
                users[userAddress].g6Matrix[level].secondLevelReferrals);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividendsS3(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        tokenDai.transfer(receiver, levelST3Price[level]);     
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    function sendETHDividendsS6(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        tokenDai.transfer(receiver, levelST6Price[level]);        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function updateG3Referrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        users[referrerAddress].g3Matrix[level].referrals.push(userAddress);
        if (users[referrerAddress].g3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].g3Matrix[level].referrals.length),2);
            tokenDai.transfer(referrerAddress, levelGT3Price[level]);
            return;
        }
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3,2);
        users[referrerAddress].g3Matrix[level].referrals = new address[](0);
        x3CurrentvId[level]=x3CurrentvId[level]+1;
        address freeReferrerAddress = findFreeG3Referrer(level);
        if (users[referrerAddress].g3Matrix[level].currentReferrer != freeReferrerAddress) {
            users[referrerAddress].g3Matrix[level].currentReferrer = freeReferrerAddress;
        }            
        users[referrerAddress].g3Matrix[level].reinvestCount++;
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level,2);
        updateG3Referrer(referrerAddress, freeReferrerAddress, level);
    }
    function updateG6Referrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x6Index[level]+1;
        x6vId_number[level][newIndex]=userAddress;
        x6Index[level]=newIndex;
        users[referrerAddress].g6Matrix[level].firstLevelReferrals.push(userAddress);        
        if (users[referrerAddress].g6Matrix[level].firstLevelReferrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].g6Matrix[level].firstLevelReferrals.length),2);
            if (referrerAddress == id1) {
                tokenDai.transfer(referrerAddress, levelGT6Price[level]);
                return;
            }
            address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
            users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 1, level, uint8(users[referrerAddress].g6Matrix[level].secondLevelReferrals.length),2);
            tokenDai.transfer(ref, levelGT6Price[level]);
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2,2);
        if (referrerAddress == id1) {
            tokenDai.transfer(referrerAddress, levelGT6Price[level]);
            return;
        }
        address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
        users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
        if (users[referrerAddress].g6Matrix[level].secondLevelReferrals.length < 4) {
            emit NewUserPlace(userAddress, ref, 1, level, uint8(users[referrerAddress].g6Matrix[level].secondLevelReferrals.length),2);
            tokenDai.transfer(ref, levelGT6Price[level]);
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6,2);
        users[ref].g6Matrix[level].firstLevelReferrals = new address[](0);
        users[ref].g6Matrix[level].secondLevelReferrals = new address[](0);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        address freeReferrerAddress = findFreeG6Referrer(level);
        if (users[referrerAddress].g6Matrix[level].currentReferrer != freeReferrerAddress) {
            users[referrerAddress].g6Matrix[level].currentReferrer = freeReferrerAddress;
        }            
        users[ref].g3Matrix[level].reinvestCount++;
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level,2);
        updateG6Referrer(ref, freeReferrerAddress, level);
    }
    function rewardWithdraw() public
    {
        uint balanceReward = royaltyInfo[msg.sender].totalRevenue - royaltyInfo[msg.sender].totalRelease;
        require(balanceReward>=0, "Insufficient reward to withdraw!");
        royaltyInfo[msg.sender].totalRelease+=balanceReward;
        tokenDai.transfer(msg.sender,balanceReward);  
    }
}