/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

pragma solidity ^0.5.16;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrixForsage {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Matrix) matrices; 
    }

    struct Matrix {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 5;
    address public owner;
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 level);
    
    IERC20 public daiCoin;
    address public daiCoinContract = 0x6D8873f56a56f0Af376091beddDD149f3592e854;

    
constructor(address ownerAddress, address secondOwnerAddress, address thirdOwnerAddress) public {
    daiCoin = IERC20(daiCoinContract);
    uint256 firstLevelPriceInUSD = 10 * 10**18; 
    levelPrice[1] = firstLevelPriceInUSD;
    for (uint8 i = 2; i <= LAST_LEVEL; i++) {
        levelPrice[i] = levelPrice[i-1] * 2;
    }

    owner = ownerAddress;
    User memory user = User({
        id: 1,
        referrer: address(0),
        partnersCount: uint(0)
    });
    users[ownerAddress] = user;
    idToAddress[1] = ownerAddress;

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
        users[ownerAddress].activeLevels[i] = true;
    }

    userIds[1] = ownerAddress;

    // Adding second owner
    User memory secondUser = User({
        id: 2,
        referrer: ownerAddress,
        partnersCount: uint(0)
    });
    users[secondOwnerAddress] = secondUser;
    idToAddress[2] = secondOwnerAddress;

    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
        users[secondOwnerAddress].activeLevels[i] = true;
    }

    userIds[2] = secondOwnerAddress;

    User memory thirdUser = User({
        id: 3,
        referrer: secondOwnerAddress,
        partnersCount: uint(0)
    });
    users[thirdOwnerAddress] = thirdUser;
    idToAddress[3] = thirdOwnerAddress;

    for (uint8 i = 1; i <= 5; i++) {
        users[thirdOwnerAddress].activeLevels[i] = true;
    }
    userIds[3] = thirdOwnerAddress;
    for(uint8 i = 1; i <= 5; i++){
    users[secondOwnerAddress].matrices[i].currentReferrer = thirdOwnerAddress;
    }
    for(uint8 i = 1; i <= LAST_LEVEL; i++){
    users[ownerAddress].matrices[i].currentReferrer = secondOwnerAddress;

    }
}

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function getPriceoflevel(uint8 level) private view returns(uint256) {
        return levelPrice[level];
    }
    //upgrade   
    function buyNewLevel(uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(daiCoin.balanceOf(msg.sender) <= getPriceoflevel(level), "not enough Balance");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

        if (level == 1) {
            require(!users[msg.sender].activeLevels[level], "level already activated");
            address freeX6Referrer = findFreeReferrer(msg.sender, level);
            users[msg.sender].matrices[1].currentReferrer = freeX6Referrer; 
            users[msg.sender].activeLevels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        } else {
            uint8 matrix = getMatrixType(level); 

            if (matrix == 3) {
                require(!users[msg.sender].activeLevels[level], "level already activated");

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                }
        
                address freeX3Referrer = findFreeReferrer(msg.sender, level);
                users[msg.sender].matrices[level].currentReferrer = freeX3Referrer;
                updateX3Referrer(msg.sender, freeX3Referrer, level);
                
                emit Upgrade(msg.sender, freeX3Referrer, 1, level);
            } else {
                require(!users[msg.sender].activeLevels[level], "level already activated"); 

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                }

                address freeX6Referrer = findFreeReferrer(msg.sender, level);
                
                updateX6Referrer(msg.sender, freeX6Referrer, level);
                
                emit Upgrade(msg.sender, freeX6Referrer, 2, level);
            }
        }
        
        daiCoin.transferFrom(msg.sender, address(this), levelPrice[level]);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0 ether, "registration cost 0.05");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeLevels[1] = true; 
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
//获得形状
    function getMatrixType(uint8 level) private pure returns (uint8) {
        if (level % 3 == 0 && level <= LAST_LEVEL) {
            return 3; 
        } else {
            return 6; 
        }
        
        }
    
//updateReferrer 根据level 判断矩阵类型

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        uint ReferralLength = users[referrerAddress].matrices[level].firstLevelReferrals.length;
        users[referrerAddress].matrices[level].firstLevelReferrals.push(userAddress);

        if (users[referrerAddress].matrices[level].firstLevelReferrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].matrices[level].firstLevelReferrals.length));
            return sendDividends(referrerAddress, userAddress, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].matrices[level].firstLevelReferrals = new address[](0);
        if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].matrices[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
            if (users[referrerAddress].matrices[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].matrices[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].matrices[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendDividends(owner, userAddress, level);
            users[owner].matrices[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
    require(users[referrerAddress].activeLevels[level], "500. Referrer level is inactive");

    if (users[referrerAddress].matrices[level].firstLevelReferrals.length < 2) {
        users[referrerAddress].matrices[level].firstLevelReferrals.push(userAddress);
        emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].matrices[level].firstLevelReferrals.length));

        // Set current level
        users[userAddress].matrices[level].currentReferrer = referrerAddress;

        if (referrerAddress == owner) {
            return sendDividends(referrerAddress, userAddress, level);
        }

        address ref = users[referrerAddress].matrices[level].currentReferrer;
        users[ref].matrices[level].secondLevelReferrals.push(userAddress);

        uint len = users[ref].matrices[level].firstLevelReferrals.length;

        if ((len == 2) && (users[ref].matrices[level].firstLevelReferrals[0] == referrerAddress) && (users[ref].matrices[level].firstLevelReferrals[1] == referrerAddress)) {
            emit NewUserPlace(userAddress, ref, 2, level, users[referrerAddress].matrices[level].firstLevelReferrals.length == 1 ? 5 : 6);
        } else if ((len == 1 || len == 2) && users[ref].matrices[level].firstLevelReferrals[0] == referrerAddress) {
            emit NewUserPlace(userAddress, ref, 2, level, users[referrerAddress].matrices[level].firstLevelReferrals.length == 1 ? 3 : 4);
        } else if (len == 2 && users[ref].matrices[level].firstLevelReferrals[1] == referrerAddress) {
            emit NewUserPlace(userAddress, ref, 2, level, users[referrerAddress].matrices[level].firstLevelReferrals.length == 1 ? 5 : 6);
        }

        return updateX6ReferrerSecondLevel(userAddress, ref, level);
    }

    users[referrerAddress].matrices[level].secondLevelReferrals.push(userAddress);

    if (users[referrerAddress].matrices[level].closedPart != address(0)) {
        if ((users[referrerAddress].matrices[level].firstLevelReferrals[0] == users[referrerAddress].matrices[level].firstLevelReferrals[1]) &&
            (users[referrerAddress].matrices[level].firstLevelReferrals[0] == users[referrerAddress].matrices[level].closedPart)) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].matrices[level].firstLevelReferrals[0] == users[referrerAddress].matrices[level].closedPart) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    if (users[referrerAddress].matrices[level].firstLevelReferrals[1] == userAddress) {
        updateX6(userAddress, referrerAddress, level, false);
        return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    } else if (users[referrerAddress].matrices[level].firstLevelReferrals[0] == userAddress) {
        updateX6(userAddress, referrerAddress, level, true);
        return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    if (users[users[referrerAddress].matrices[level].firstLevelReferrals[0]].matrices[level].firstLevelReferrals.length <=
        users[users[referrerAddress].matrices[level].firstLevelReferrals[1]].matrices[level].firstLevelReferrals.length) {
        updateX6(userAddress, referrerAddress, level, false);
    } else {
        updateX6(userAddress, referrerAddress, level, true);
    }

    updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
}

function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
    address[] storage firstLevelReferrals = users[referrerAddress].matrices[level].firstLevelReferrals;
    uint8 referralIndex = x2 ? 1 : 0;

    address currentReferrer = firstLevelReferrals[referralIndex];

    users[currentReferrer].matrices[level].firstLevelReferrals.push(userAddress);

    emit NewUserPlace(userAddress, currentReferrer, 2, level, uint8(users[currentReferrer].matrices[level].firstLevelReferrals.length));
    emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[currentReferrer].matrices[level].firstLevelReferrals.length));

    users[userAddress].matrices[level].currentReferrer = currentReferrer;
}

function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
    if (users[referrerAddress].matrices[level].secondLevelReferrals.length < 4) {
        return sendDividends(referrerAddress, userAddress, level);
    }

    address currentReferrer = users[referrerAddress].matrices[level].currentReferrer;
    address[] memory x6 = users[currentReferrer].matrices[level].firstLevelReferrals;

    if (x6.length == 2 && (x6[0] == referrerAddress || x6[1] == referrerAddress)) {
        users[currentReferrer].matrices[level].closedPart = referrerAddress;
    } else if (x6.length == 1 && x6[0] == referrerAddress) {
        users[currentReferrer].matrices[level].closedPart = referrerAddress;
    }

    users[referrerAddress].matrices[level].firstLevelReferrals = new address[](0);
    users[referrerAddress].matrices[level].secondLevelReferrals = new address[](0);
    users[referrerAddress].matrices[level].closedPart = address(0);

    if (!users[referrerAddress].activeLevels[level + 1] && level != LAST_LEVEL) {
        users[referrerAddress].matrices[level].blocked = true;
    }

    users[referrerAddress].matrices[level].reinvestCount++;

    if (referrerAddress != owner) {
        address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
        emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
        updateX6Referrer(referrerAddress, freeReferrerAddress, level);
    } else {
        emit Reinvest(owner, address(0), userAddress, 2, level);
        sendDividends(owner, userAddress, level);
    }
}

//大公排滑落

    function findFreeReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                return users[userAddress].matrices[level].currentReferrer;
            }
            
            userAddress = users[userAddress].matrices[level].currentReferrer;
        }
    }
    

//检查用户开通的等级根据得到level判断矩阵类型。     
    function userActiveLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }

//查看用户的matrix 数据

    function userMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address) {
                Matrix storage userData = users[userAddress].matrices[level];
                return (
                userData.currentReferrer,
                userData.firstLevelReferrals, 
                userData.secondLevelReferrals, 
                userData.blocked, 
                userData.closedPart
                );
                    
    }   

//检查用户是否存在
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
//转账逻辑
    function findReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        uint8 matrix = getMatrixType(level);
        if (matrix == 3) {
            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedEthReceive(receiver, _from, level);
                    isExtraDividends = true;
                    receiver = users[receiver].matrices[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedEthReceive(receiver, _from, level);
                    isExtraDividends = true;
                    receiver = users[receiver].matrices[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendDividends(address userAddress, address _from, uint8 level) private {
        (address receiver, bool isExtraDividends) = findReceiver(userAddress, _from, level);

        if (!daiCoin.transfer(receiver, levelPrice[level])) {
            (bool success) = daiCoin.transferFrom(address(this), receiver, levelPrice[level]);
            require(success, "token Transfer failed");
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    modifier onlyOwner {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;
}

    function OwnerTransfer(uint256 amount) public onlyOwner {
        daiCoin.transferFrom(address(this), msg.sender, amount);

    }
}