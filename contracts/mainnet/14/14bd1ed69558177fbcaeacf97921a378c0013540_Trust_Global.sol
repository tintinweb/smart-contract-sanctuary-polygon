/**
 *Submitted for verification at polygonscan.com on 2022-12-01
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
contract Trust_Global {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint isIncome;
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
        uint256 royaltyactivator;
        uint256 royaltymaster;
        uint256 royaltyroyal;
        uint256 top;
        uint256 grtop;
        uint256 direct3;
        uint256 donation;
        uint256 totalRevenue;
        uint256 totalRelease;
    }
    mapping(address=>RoyaltyInfo) public royaltyInfo;
    uint8 public constant LAST_LEVEL = 12;
    IERC20 public tokenDai;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(address => uint) public balances; 
    mapping(uint256=>address[5]) public dayTopUsers;
    mapping(uint256=>address[5]) public dayTopGR3Users;
    uint public lastUserId = 2;
    address public id1=0x889140B7454f2963093D05FF565B0D76d96c4A1d;
    uint256 public gR3Pool;
    uint256 public gR6Pool;
    uint256 public gR3PoolLast;
    uint256 public gR6PoolLast;
    uint256 public donationFund;
    uint256 public donationFundLast;
    uint256 public totalDonationFund;

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
	
	mapping(uint256 => address) public gR3ActivatorPool_User;
    uint256 public gR3ActivatorIndex;
    mapping(uint256 => address) public gR3MasterPool_User;
    uint256 public gR3MasterIndex;
    mapping(uint256 => address) public gR3RoyalPool_User;
    uint256 public gR3RoyalIndex;
	
    mapping(uint256 => mapping(address => uint256)) public userLayerDaySponsorCount; 
    mapping(uint256 => mapping(address => uint256)) public userLayerDayGR3Count;
    mapping(uint256 => mapping(address => uint256)) public userLayerDayDirect3; 
    mapping(uint256=>address[]) public dayDirect3Users;   

    uint256 public lastDistribute;
    uint256 public lastGR3Distribute;
    uint256 public lastDonationDistribute;

    uint256 public startTime;

    uint256 private constant timeStep = 7 days; 
    uint256 private constant timeStep7 = 7 days; 
    uint256 private constant timeStep30 = 30 days;    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level,uint8 mtype);
    event Payment(address indexed from, address indexed to, uint256 value,uint8 mtype);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place,uint8 mtype);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    constructor(address _token) public {
        
        levelST3Price[1] = 7e18;
        levelGT3Price[1] = 2e18;            
        levelGR3Price[1] = 1e18;

        levelST6Price[1] = 9e18;
        levelGT6Price[1] = 2e18;
        levelGR6Price[1] = 1e18;

        for (uint8 i = 2; i <= 12; i++) {
            levelST3Price[i] = levelST3Price[i-1] * 2;            
            levelGT3Price[i] = levelGT3Price[i-1] * 2;            
            levelGR3Price[i] = levelGR3Price[i-1] * 2;

            levelST6Price[i] = levelST6Price[i-1] * 2;
            levelGT6Price[i] = levelGT6Price[i-1] * 2;
            levelGR6Price[i] = levelGR6Price[i-1] * 2;
        }
        
        tokenDai = IERC20(_token);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            isIncome:1
        });
        lastDistribute = block.timestamp;
        lastGR3Distribute = block.timestamp;
        lastDonationDistribute = block.timestamp;
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
        gR3ActivatorIndex=1;
        gR3ActivatorPool_User[1]=id1;
        gR3MasterIndex=1;
        gR3MasterPool_User[1]=id1;
        gR3RoyalIndex=1;
        gR3RoyalPool_User[1]=id1;
    }
    function registrationExt(address referrerAddress) external {
        tokenDai.transferFrom(msg.sender, address(this), (levelST3Price[1]+levelGT3Price[1]+levelGR3Price[1]));
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external {         
        _buyNewLevel(msg.sender, matrix, level);
    }
    function donateYourFund(uint256 _amount) external {
        tokenDai.transferFrom(msg.sender, address(this), _amount);
        totalDonationFund+=_amount;
        donationFund+=_amount;
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
            users[_userAddress].g3Matrix[level].currentReferrer = freeG3Referrer;
            updateG3Referrer(_userAddress, freeG3Referrer, level);
            gR3Pool = gR3Pool+levelGR3Price[level]; 
            if(level==6)
            {
                uint256 dayNow = getCurDay();
               _updateTopUserGR3(users[_userAddress].referrer, dayNow);

                gR3ActivatorIndex+=1;
                gR3ActivatorPool_User[gR3ActivatorIndex]=_userAddress;
            }       
            else if(level==9)
            {
                gR3MasterIndex+=1;
                gR3MasterPool_User[gR3MasterIndex]=_userAddress;
            }
            else if(level==12)
            {
                gR3RoyalIndex+=1;
                gR3RoyalPool_User[gR3RoyalIndex]=_userAddress;
            }     
            emit Upgrade(_userAddress, freeX3Referrer, 1, level);

        } else {
            tokenDai.transferFrom(msg.sender, address(this), (levelST6Price[level]+levelGT6Price[level]+levelGR6Price[level]));
            require(!users[_userAddress].activeX6Levels[level], "level already activated"); 
            if(level>1)
            {
                require(level > 1 && level <= LAST_LEVEL, "invalid level");
                require(users[_userAddress].activeX6Levels[level-1], "buy previous level first");                

                if (users[_userAddress].x6Matrix[level-1].blocked) {
                    users[_userAddress].x6Matrix[level-1].blocked = false;
                }
            }
            address freeX6Referrer = findFreeX6Referrer(_userAddress, level);
            users[_userAddress].activeX6Levels[level] = true;
            updateX6Referrer(_userAddress, freeX6Referrer, level);
            
            address freeG6Referrer = findFreeG6Referrer(level);
            users[_userAddress].g6Matrix[level].currentReferrer = freeG6Referrer;
            updateG6Referrer(_userAddress, freeG6Referrer, level);

            gR6Pool = gR6Pool+levelGR6Price[level]; 
            emit Upgrade(_userAddress, freeX6Referrer, 2, level);
        }
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            isIncome:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        uint256 dayNow = getCurDay();
        _updateTopUser(users[userAddress].referrer, dayNow);
        _updateDirect3User(users[userAddress].referrer, dayNow);
        users[userAddress].activeX3Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        
        updateX3Referrer(userAddress, freeX3Referrer, 1);
        address freeG3Referrer = findFreeG3Referrer(1);
        users[userAddress].g3Matrix[1].currentReferrer = freeG3Referrer;
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
    function usersG3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint) {
        return (users[userAddress].g3Matrix[level].currentReferrer,
                users[userAddress].g3Matrix[level].referrals,users[userAddress].g3Matrix[level].reinvestCount);
    }
    function usersG6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,uint) {
        return (users[userAddress].g6Matrix[level].currentReferrer,
                users[userAddress].g6Matrix[level].firstLevelReferrals,
                users[userAddress].g6Matrix[level].secondLevelReferrals,users[userAddress].g6Matrix[level].reinvestCount);
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
        if(users[receiver].isIncome==0) users[receiver].isIncome=1;
        tokenDai.transfer(receiver, levelST3Price[level]); 
        emit Payment(userAddress,receiver, levelST3Price[level],1);    
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    function sendETHDividendsS6(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
        if(users[receiver].isIncome==0) users[receiver].isIncome=1;
        tokenDai.transfer(receiver, levelST6Price[level]);  
        emit Payment(userAddress,receiver, levelST6Price[level],1);      
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
            if(users[referrerAddress].isIncome==0) users[referrerAddress].isIncome=1;
            tokenDai.transfer(referrerAddress, levelGT3Price[level]);
            emit Payment(userAddress,referrerAddress, levelGT3Price[level],2);  
            return;
        }
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3,2);
        users[referrerAddress].g3Matrix[level].referrals = new address[](0);
        x3CurrentvId[level]=x3CurrentvId[level]+1;
        users[referrerAddress].g3Matrix[level].reinvestCount++;
        if(users[referrerAddress].g3Matrix[level].reinvestCount<5){        
            address freeReferrerAddress = findFreeG3Referrer(level);
            if (users[referrerAddress].g3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].g3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level,2);            
            updateG3Referrer(referrerAddress, freeReferrerAddress, level);
        }
		else{
			tokenDai.transfer(referrerAddress, levelGT3Price[level]);
            emit Payment(userAddress,referrerAddress, levelGT3Price[level],2);  
		}

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
                emit Payment(userAddress,referrerAddress, levelGT6Price[level],2); 
                return;
            }
            address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
            users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 2, level, 2 + uint8(users[ref].g6Matrix[level].secondLevelReferrals.length),2);
            if(users[ref].isIncome==0) users[ref].isIncome=1;
            tokenDai.transfer(ref, levelGT6Price[level]);
            emit Payment(userAddress,ref, levelGT6Price[level],2);
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2,2);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        if (referrerAddress == id1) {
            tokenDai.transfer(referrerAddress, levelGT6Price[level]);
            emit Payment(userAddress,referrerAddress, levelGT6Price[level],2);
            return;
        }
        address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
        users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
        if (users[ref].g6Matrix[level].secondLevelReferrals.length < 4) {
            emit NewUserPlace(userAddress, ref, 2, level, 2+uint8(users[ref].g6Matrix[level].secondLevelReferrals.length),2);
            tokenDai.transfer(ref, levelGT6Price[level]);
            emit Payment(userAddress,ref, levelGT6Price[level],2);
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6,2);
		users[ref].g6Matrix[level].reinvestCount++;
		if(users[ref].g6Matrix[level].reinvestCount<5){ 
            users[ref].g6Matrix[level].firstLevelReferrals = new address[](0);
            users[ref].g6Matrix[level].secondLevelReferrals = new address[](0);
            address freeReferrerAddress = findFreeG6Referrer(level);
            if (users[ref].g6Matrix[level].currentReferrer != freeReferrerAddress) {
                users[ref].g6Matrix[level].currentReferrer = freeReferrerAddress;
            }
            emit Reinvest(ref, freeReferrerAddress, userAddress, 2, level,2);
            updateG6Referrer(ref, freeReferrerAddress, level);
		}
		else
		{
			tokenDai.transfer(ref, levelGT6Price[level]);
            emit Payment(userAddress,ref, levelGT6Price[level],2);
		}
    }
    function distributePoolRoyalty() public {
        if(block.timestamp > lastGR3Distribute+timeStep7){  
           _distributeGR3ActivatorPool();
           _distributeGR3MasterPool();
           _distributeGR3RoyalPool();
           gR3PoolLast=gR3Pool;
           gR3Pool=0;     
           lastGR3Distribute = lastGR3Distribute+timeStep7;
        }
    }
    
    function distributeDonation() public {
        if(block.timestamp > lastDonationDistribute+timeStep30){  
           _distributeDonation();
           donationFundLast=donationFund;
           donationFund=0;     
           lastDonationDistribute = lastDonationDistribute+timeStep30;
        }
    }
    function _distributeDonation() public {
        uint256 noIncomeCount=0;
        for(uint256 i = 1; i < lastUserId; i++){
            address userAddr = idToAddress[i];
            if(users[userAddr].isIncome== 0){
                noIncomeCount +=1;
            }
        }
        if(noIncomeCount > 0){
            uint256 reward = donationFund/noIncomeCount;
            for(uint256 i = 1; i < lastUserId; i++){
                address userAddr = idToAddress[i];
                if(users[userAddr].isIncome== 0){
                    royaltyInfo[userAddr].donation += reward;
                    royaltyInfo[userAddr].totalRevenue += reward;
                    users[userAddr].isIncome=1;
                }
            }  
        }
        else {
            royaltyInfo[id1].donation += donationFund;
            royaltyInfo[id1].totalRevenue += donationFund;
        }
    }
    function _distributeGR3ActivatorPool() public {  
        if(gR3ActivatorIndex > 0){
            uint256 reward = (gR3Pool*25)/(100*gR3ActivatorIndex);
            for(uint256 i = 1; i <= gR3ActivatorIndex; i++){
                if(royaltyInfo[gR3ActivatorPool_User[i]].royaltyactivator <= 5000e18){
                    royaltyInfo[gR3ActivatorPool_User[i]].royaltyactivator += reward;
                    royaltyInfo[gR3ActivatorPool_User[i]].totalRevenue += reward;
                }
            }     
        }
    }
    function _distributeGR3MasterPool() public {  
        if(gR3MasterIndex > 0){
            uint256 reward = (gR3Pool*30)/(100*gR3MasterIndex);
            for(uint256 i = 1; i <= gR3MasterIndex; i++){
                if(royaltyInfo[gR3MasterPool_User[i]].royaltymaster <= 25000e18){
                    royaltyInfo[gR3MasterPool_User[i]].royaltymaster += reward;
                    royaltyInfo[gR3MasterPool_User[i]].totalRevenue += reward;
                }
            }     
        }
    }
    function _distributeGR3RoyalPool() public {  
        if(gR3RoyalIndex > 0){
            uint256 reward = (gR3Pool*45)/(100*gR3RoyalIndex);
            for(uint256 i = 1; i <= gR3RoyalIndex; i++){
                if(royaltyInfo[gR3RoyalPool_User[i]].royaltyroyal <= 200000e18){
                    royaltyInfo[gR3RoyalPool_User[i]].royaltyroyal += reward;
                    royaltyInfo[gR3RoyalPool_User[i]].totalRevenue += reward;
                }
            }     
        }
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStep){  
            uint256 dayNow = getCurDay();
           _distributeTopPool(dayNow); 
           _distributeTopGR3Pool(dayNow); 
           _distribute3DirectPool(dayNow);
           gR6PoolLast=gR6Pool;
           gR6Pool=0;      
           lastDistribute = lastDistribute+timeStep;
        }
    }    
    function _distributeTopPool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,15,5];
        uint256 topPool=gR6Pool*30/100;
        for(uint256 i = 0; i < 5; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            uint256 reward = (topPool*rates[i])/100;
            if(userAddr != address(0)){                
                royaltyInfo[userAddr].top += reward;
                royaltyInfo[userAddr].totalRevenue += reward;
            }
            else 
            {
                royaltyInfo[id1].top += reward;
                royaltyInfo[id1].totalRevenue += reward;
            }
        }
        topPool = 0;
    }
    function _distributeTopGR3Pool(uint256 _dayNow) public {
        uint8[5] memory rates = [35,25,20,15,5];
        uint256 topPool=gR6Pool*40/100;
        for(uint256 i = 0; i < 5; i++){
            address userAddr = dayTopGR3Users[_dayNow - 1][i];
            uint256 reward = (topPool*rates[i])/100;
            if(userAddr != address(0)){                
                royaltyInfo[userAddr].grtop += reward;
                royaltyInfo[userAddr].totalRevenue += reward;
            }
            else 
            {
                royaltyInfo[id1].grtop += reward;
                royaltyInfo[id1].totalRevenue += reward;
            }
        }
        topPool = 0;
    }
    function _distribute3DirectPool(uint256 _dayNow) public {
        uint256 direct3Bonus=gR6Pool*30/100;
        uint256 direct3Count=0;
        for(uint256 i = 0; i < dayDirect3Users[_dayNow - 1].length; i++){
            address userAddr = dayDirect3Users[_dayNow - 1][i];
            if(userLayerDayDirect3[_dayNow-1][userAddr]>= 3){
                direct3Count +=1;
            }
        }
        if(direct3Count > 0){
            uint256 reward = direct3Bonus/direct3Count;
            for(uint256 i = 0; i < dayDirect3Users[_dayNow - 1].length; i++){
                address userAddr = dayDirect3Users[_dayNow - 1][i];
                if(userLayerDayDirect3[_dayNow-1][userAddr]>=3 && userAddr != address(0)){
                    royaltyInfo[userAddr].direct3 += reward;
                    royaltyInfo[userAddr].totalRevenue += reward;
                }
            }        
            direct3Bonus = 0;
        }
        else {
            royaltyInfo[id1].direct3 += direct3Bonus;
            royaltyInfo[id1].totalRevenue += direct3Bonus;
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
            address lastUser = dayTopUsers[_dayNow][4];
            if(userLayerDaySponsorCount[_dayNow][lastUser] < userLayerDaySponsorCount[_dayNow][_user]){
                dayTopUsers[_dayNow][4] = _user;
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
    function _updateDirect3User(address _user, uint256 _dayNow) private {
        userLayerDayDirect3[_dayNow][_user] += 1;
        bool updated;
        for(uint256 i = 0; i < dayDirect3Users[_dayNow].length; i++){
            address direct3User = dayDirect3Users[_dayNow][i];
            if(direct3User == _user){
                updated = true;
                break;
            }
        }
        if(!updated){
            dayDirect3Users[_dayNow].push(_user);
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
            address lastUser = dayTopGR3Users[_dayNow][4];
            if(userLayerDayGR3Count[_dayNow][lastUser] < userLayerDayGR3Count[_dayNow][_user]){
                dayTopGR3Users[_dayNow][4] = _user;
                _reOrderTopGR3(_dayNow);
            }
        }
    }

    function _reOrderTopGR3(uint256 _dayNow) private {
        for(uint256 i = 5; i > 1; i--){
            address topUser1 = dayTopGR3Users[_dayNow][i - 1];
            address topUser2 = dayTopGR3Users[_dayNow][i - 2];
            uint256 count1 = userLayerDayGR3Count[_dayNow][topUser1];
            uint256 count2 = userLayerDayGR3Count[_dayNow][topUser2];
            if(count1 > count2){
                dayTopGR3Users[_dayNow][i - 1] = topUser2;
                dayTopGR3Users[_dayNow][i - 2] = topUser1;
            }
        }
    }
    function getCurDay() public view returns(uint256) {
        return (block.timestamp-startTime)/timeStep;
    }
    function getdayDirect3UsersLength(uint256 _day) external view returns(uint256) {
        return dayDirect3Users[_day].length;
    }
    function rewardWithdraw() public
    {
        uint balanceReward = royaltyInfo[msg.sender].totalRevenue - royaltyInfo[msg.sender].totalRelease;
        require(balanceReward>=0, "Insufficient reward to withdraw!");
        royaltyInfo[msg.sender].totalRelease+=balanceReward;
        tokenDai.transfer(msg.sender,balanceReward);  
    }
}