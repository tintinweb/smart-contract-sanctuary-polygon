/**
 *Submitted for verification at polygonscan.com on 2022-10-10
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
        uint256[] royalty6;
        uint256 totalRevenue;
        uint256 directs;
    }
    mapping(address=>RoyaltyInfo) public royaltyInfo;
    uint8 public constant LAST_LEVEL = 12;
    IERC20 public tokenDai;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public id1;
    uint256 public gR3Pool;
    uint256 public gR6Pool;
    
    mapping(uint8 => address[]) public gR3Pool_User;
    mapping(uint8 => address[]) public gR6Pool_User;
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
    uint256 public lastDistribute;
    uint256 private constant timeStep = 60*60;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    constructor(address ownerAddress, address _token) public {
        
        levelST3Price[1] = 7e18;
        levelGT3Price[1] = 2e18;            
        levelGR3Price[1] = 1e18;

        levelST6Price[1] = 9e18;
        levelST6Price[1] = 2e18;
        levelGR6Price[1] = 1e18;

        for (uint8 i = 2; i <= 11; i++) {
            levelST3Price[i] = levelST3Price[i-1] * 2;            
            levelGT3Price[i] = levelGT3Price[i-1] * 2;            
            levelGR3Price[i] = levelGR3Price[i-1] * 2;

            levelGT6Price[i] = levelGT6Price[i-1] * 2;
            levelST6Price[i] = levelST6Price[i-1] * 2;
            levelGR6Price[i] = levelGR6Price[i-1] * 2;
        }
        
        id1 = ownerAddress;
        tokenDai = IERC20(_token);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        lastDistribute = block.timestamp;
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {    
            x3vId_number[i][1]=ownerAddress;
            x3Index[i]=1;
            x3CurrentvId[i]=1;  
            users[ownerAddress].activeX3Levels[i] = true;
            x6vId_number[i][1]=ownerAddress;
            x6Index[i]=1;
            x6CurrentvId[i]=1;      
            users[ownerAddress].activeX6Levels[i] = true;          
        }
        for (uint8 i = 6; i <= LAST_LEVEL; i++) {          
            gR3Pool_User[i].push(ownerAddress);
            gR6Pool_User[i].push(ownerAddress);          
        }         
        userIds[1] = ownerAddress;
    }
    function registrationExt(address referrerAddress) external {
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
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
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
            gR3Pool_User[level].push(_userAddress);
            emit Upgrade(_userAddress, freeX3Referrer, 1, level);

        } else {
            require(users[_userAddress].activeX6Levels[level-1], "buy previous level first");
            require(!users[_userAddress].activeX6Levels[level], "level already activated"); 

            if (users[_userAddress].x6Matrix[level-1].blocked) {
                users[_userAddress].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(_userAddress, level);
            users[_userAddress].activeX6Levels[level] = true;
            updateX6Referrer(_userAddress, freeX6Referrer, level);
            
            address freeG6Referrer = findFreeG6Referrer(level);
            users[_userAddress].x6Matrix[level].currentReferrer = freeG6Referrer;
            updateG6Referrer(_userAddress, freeG6Referrer, level);

            gR6Pool = gR6Pool+levelGR6Price[level]; 
            if(level>5)
            gR6Pool_User[level].push(_userAddress);
            emit Upgrade(_userAddress, freeX6Referrer, 2, level);
        }
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStep){  
           _distributeGR3Pool(6);
           _distributeGR6Pool(6); 
            lastDistribute = block.timestamp;
        }
    }
    function _distributeGR3Pool(uint8 rank) private {
        uint256 managerCount=gR3Pool_User[rank].length;
        if(managerCount > 0){
            uint256 reward = gR3Pool/managerCount;
            for(uint256 i = 0; i < gR3Pool_User[rank].length; i++){
                if(royaltyInfo[gR3Pool_User[rank][i]].totalRevenue == 2000e18){
                    royaltyInfo[gR3Pool_User[rank][i]].royalty3[rank] += reward;
                    royaltyInfo[gR3Pool_User[rank][i]].totalRevenue = reward;
                }
            }            
        }
    }
    function _distributeGR6Pool(uint8 rank) private {
        uint256 managerCount=gR6Pool_User[rank].length;
        if(managerCount > 0){
            uint256 reward = gR6Pool/managerCount;
            for(uint256 i = 0; i < gR6Pool_User[rank].length; i++){
                if(royaltyInfo[gR6Pool_User[rank][i]].totalRevenue == 3000e18){
                    royaltyInfo[gR6Pool_User[rank][i]].royalty6[rank] += reward;
                    royaltyInfo[gR6Pool_User[rank][i]].totalRevenue = reward;
                }
            }            
        }
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
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
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
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividendsS3(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
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
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividendsS3(id1, userAddress, 1, level);
            users[id1].x3Matrix[level].reinvestCount++;
            emit Reinvest(id1, address(0), userAddress, 1, level);
        }
    }
    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
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
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
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
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
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

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(id1, address(0), userAddress, 2, level);
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
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].g3Matrix[level].referrals.length));
            tokenDai.transfer(referrerAddress, levelGT3Price[level]);
            return;
        }
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        users[referrerAddress].g3Matrix[level].referrals = new address[](0);
        x3CurrentvId[level]=x3CurrentvId[level]+1;
        address freeReferrerAddress = findFreeG3Referrer(level);
        if (users[referrerAddress].g3Matrix[level].currentReferrer != freeReferrerAddress) {
            users[referrerAddress].g3Matrix[level].currentReferrer = freeReferrerAddress;
        }            
        users[referrerAddress].g3Matrix[level].reinvestCount++;
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
        updateG3Referrer(referrerAddress, freeReferrerAddress, level);
    }
    function updateG6Referrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x6Index[level]+1;
        x6vId_number[level][newIndex]=userAddress;
        x6Index[level]=newIndex;
        users[referrerAddress].g6Matrix[level].firstLevelReferrals.push(userAddress);        
        if (users[referrerAddress].g6Matrix[level].firstLevelReferrals.length < 2) {
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].g6Matrix[level].firstLevelReferrals.length));
            if (referrerAddress == id1) {
                tokenDai.transfer(referrerAddress, levelGT6Price[level]);
                return;
            }
            address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
            users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, ref, 1, level, uint8(users[referrerAddress].g6Matrix[level].secondLevelReferrals.length));
            tokenDai.transfer(ref, levelGT6Price[level]);
            return;
            
        }
        emit NewUserPlace(userAddress, referrerAddress, 2, level, 2);
        address ref = users[referrerAddress].g6Matrix[level].currentReferrer;            
        users[ref].g6Matrix[level].secondLevelReferrals.push(userAddress);
        if (users[referrerAddress].g6Matrix[level].secondLevelReferrals.length == 4) {
            emit NewUserPlace(userAddress, ref, 1, level, uint8(users[referrerAddress].g6Matrix[level].secondLevelReferrals.length));
            tokenDai.transfer(ref, levelGT6Price[level]);
            return;
        }
        emit NewUserPlace(userAddress, ref, 2, level, 6);
        users[ref].g6Matrix[level].firstLevelReferrals = new address[](0);
        users[ref].g6Matrix[level].secondLevelReferrals = new address[](0);
        x6CurrentvId[level]=x6CurrentvId[level]+1;
        address freeReferrerAddress = findFreeG6Referrer(level);
        if (users[referrerAddress].g6Matrix[level].currentReferrer != freeReferrerAddress) {
            users[referrerAddress].g6Matrix[level].currentReferrer = freeReferrerAddress;
        }            
        users[ref].g3Matrix[level].reinvestCount++;
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
        updateG6Referrer(ref, freeReferrerAddress, level);
    }
    
}