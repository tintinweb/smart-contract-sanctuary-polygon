pragma solidity >=0.4.23 <0.6.0;

import "./IERC20.sol";

contract SmartInfinityMatrix {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool autoUpgradeStatus; 
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Matrix) matrices; 
    }

    struct InnerWallet {
        address[] tokenList; 
        mapping(address => uint) tokenBalance;
        mapping(address => uint) productFund; 

    }

    struct Matrix {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    

    uint8 internal MAX_LEVEL;
    uint8 public constant LAST_LEVEL = 12;

    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    address[] public currentERC20;

    uint public lastUserId = 2;
    address public owner;
    address private secondOwner;
    address private thirdOwner;
    address private forthOwner;
    address private fifthOwner;
    IERC20 public Dai;
    address public DaiAddress = 0x6D8873f56a56f0Af376091beddDD149f3592e854;

    mapping(uint8 => uint256) public levelPrice;
    mapping(address => InnerWallet) userWallet; 
    mapping(address => bool) freezedToken; 
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraDividends(address indexed from, address indexed receiver, uint8 level);
    event DisableAutoUpgrade(address indexed from, uint256 amount); 
    


        
    constructor(address ownerAddress,
                address secondOwnerAddress,
                address thirdOwnerAddress,
                address forthOwnerAddress,
                address fifthOwnerAddress) public {
        uint256 firstLevelPriceInUSD = 10 * 10**18; 
        levelPrice[1] = firstLevelPriceInUSD;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        Dai = IERC20(DaiAddress);

        currentERC20.push(DaiAddress);
        
        {owner = ownerAddress; 
        InnerWallet memory walletOwner;
        walletOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[ownerAddress] = walletOwner;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 0,
            autoUpgradeStatus: false
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
        }
    }
    {

        InnerWallet memory walletSecondOwner;
        walletSecondOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[secondOwnerAddress] = walletSecondOwner;
        secondOwner = secondOwnerAddress;
    User memory user2 = User({
            id: lastUserId,
            referrer: ownerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true
        });
        users[secondOwnerAddress] = user2;
        idToAddress[lastUserId] = secondOwnerAddress;
        users[secondOwnerAddress].referrer = ownerAddress;
        for (uint8 i = 1; i <= LAST_LEVEL; i++){
        users[secondOwnerAddress].activeLevels[i] = true; 
        }
        userIds[lastUserId] = secondOwnerAddress;
        lastUserId++;
        users[ownerAddress].partnersCount++;
    }

        {

        InnerWallet memory walletThirdOwner;
        walletThirdOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[thirdOwnerAddress] = walletThirdOwner;
        thirdOwner = thirdOwnerAddress;
    User memory user3 = User({
            id: lastUserId,
            referrer: ownerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true
        });
        users[thirdOwnerAddress] = user3;
        idToAddress[lastUserId] = thirdOwnerAddress;
        users[thirdOwnerAddress].referrer = ownerAddress;
        for (uint8 i = 1; i <= 5; i++){
        users[thirdOwnerAddress].activeLevels[i] = true; 
        }
        userIds[lastUserId] = thirdOwnerAddress;
        lastUserId++;
        users[secondOwnerAddress].partnersCount++;
        users[thirdOwnerAddress].autoUpgradeStatus = true;
    }

            {
        InnerWallet memory walletForthOwner;
        walletForthOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[forthOwnerAddress] = walletForthOwner;
        forthOwner = forthOwnerAddress;
    User memory user4 = User({
            id: lastUserId,
            referrer: secondOwnerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true
        });
        users[forthOwnerAddress] = user4;
        idToAddress[lastUserId] = forthOwnerAddress;
        users[forthOwnerAddress].referrer = secondOwnerAddress;
        for (uint8 i = 1; i <= 5; i++){
        users[forthOwnerAddress].activeLevels[i] = true; 
        }
        userIds[lastUserId] = forthOwnerAddress;
        lastUserId++;
        users[secondOwnerAddress].partnersCount++;
        users[forthOwnerAddress].autoUpgradeStatus = true;
    }

    {
        InnerWallet memory walletFifthOwner;
        walletFifthOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[fifthOwnerAddress] = walletFifthOwner;
        fifthOwner = fifthOwnerAddress;
    User memory user5 = User({
            id: lastUserId,
            referrer: secondOwnerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true
        });
        users[fifthOwnerAddress] = user5;
        idToAddress[lastUserId] = fifthOwnerAddress;
        users[fifthOwnerAddress].referrer = secondOwnerAddress;
        for (uint8 i = 1; i <= 5; i++){
        users[fifthOwnerAddress].activeLevels[i] = true; 
        }
        userIds[lastUserId] = fifthOwnerAddress;
        lastUserId++;
        users[secondOwnerAddress].partnersCount++;
        users[fifthOwnerAddress].autoUpgradeStatus = true;
    }

        

    }

    function registrationExt(address referrerAddress) external returns(bool) {
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        bool success = Dai.approve(address(this), 40950 *10 ** 18);
        if(success == true){
        registration(msg.sender, referrerAddress);
        }
        return success;

    }

    function registration(address userAddress, address referrerAddress) internal {
    
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true
        });
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeLevels[0] = true; 
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        users[userAddress].autoUpgradeStatus = true;
     
        InnerWallet storage wallet = userWallet[userAddress];
        wallet.tokenList.push(DaiAddress);
    for (uint i = 0; i < currentERC20.length; i++) {
        address ERC20 = currentERC20[i];
        wallet.tokenList.push(ERC20);
    }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

        function getPriceoflevel(uint8 level) private view returns(uint256) {
            return levelPrice[level];
        }

    function addERC20towallet(address ERC20) external onlyOwner {
        currentERC20.push(ERC20);
            for (uint i = 0; i < lastUserId; i++) {
                InnerWallet storage wallet = userWallet[userIds[i]];
                wallet.tokenList.push(ERC20);
        }
    }


    //upgrade   
    function buyNewLevel(uint8 level) public  {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(Dai.balanceOf(msg.sender) <= getPriceoflevel(level), "not enough Balance");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");


            uint8 matrix = getMatrixType(level); 

            if (matrix == 3) {
                require(!users[msg.sender].activeLevels[level], "level already activated");

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                }
        
                address freeX3Referrer = findFreeReferrer(msg.sender, level);
                users[msg.sender].matrices[level].currentReferrer = freeX3Referrer;
                updateX3Referrer(msg.sender, freeX3Referrer, level);
                
                emit Upgrade(msg.sender, freeX3Referrer, level);
            } else {
                require(!users[msg.sender].activeLevels[level], "level already activated"); 

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                }

                address freeX6Referrer = findFreeReferrer(msg.sender, level);
                
                updateX6Referrer(msg.sender, freeX6Referrer, level);
                
                emit Upgrade(msg.sender, freeX6Referrer, level);
            }
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
        address[] storage X3Referral = users[referrerAddress].matrices[level].firstLevelReferrals;
        uint ReferralLength = users[referrerAddress].matrices[level].firstLevelReferrals.length;
        
        X3Referral.push(userAddress);

        if (ReferralLength < 3) {
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(ReferralLength));
            return sendDividends(referrerAddress, userAddress, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, level, 3);
        //close matrix
        users[referrerAddress].matrices[level].firstLevelReferrals = new address[](0);
        if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].matrices[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
            address currentX3referrer = users[referrerAddress].matrices[level].currentReferrer;
            if (currentX3referrer != freeReferrerAddress) {
                currentX3referrer = freeReferrerAddress;
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
        emit NewUserPlace(userAddress, referrerAddress, level, uint8(users[referrerAddress].matrices[level].firstLevelReferrals.length));

        // Set current level
        users[userAddress].matrices[level].currentReferrer = referrerAddress;

        if (referrerAddress == owner) {
            return sendDividends(referrerAddress, userAddress, level);
        }

        address ref = users[referrerAddress].matrices[level].currentReferrer;
        users[ref].matrices[level].secondLevelReferrals.push(userAddress);

        uint len = users[ref].matrices[level].firstLevelReferrals.length;
        address[] storage firstReferrer = users[ref].matrices[level].firstLevelReferrals;
        uint LenfirstReferrer = users[referrerAddress].matrices[level].firstLevelReferrals.length;
        if ((len == 2) && (firstReferrer[0] == referrerAddress) && (firstReferrer[1] == referrerAddress)) {
            emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 5 : 6);
        } else if ((len == 1 || len == 2) && firstReferrer[0] == referrerAddress) {
            emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 3 : 4);
        } else if (len == 2 && firstReferrer[1] == referrerAddress) {
            emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 5 : 6);
        }

        return updateX6ReferrerSecondLevel(userAddress, ref, level);
    }
        address[] storage refFirstReferrals = users[referrerAddress].matrices[level].firstLevelReferrals;
    users[referrerAddress].matrices[level].secondLevelReferrals.push(userAddress);

    if (users[referrerAddress].matrices[level].closedPart != address(0)) {
        if ((refFirstReferrals[0] == refFirstReferrals[1]) &&
            (refFirstReferrals[0] == users[referrerAddress].matrices[level].closedPart)) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (refFirstReferrals[0] == users[referrerAddress].matrices[level].closedPart) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    if (refFirstReferrals[1] == userAddress) {
        updateX6(userAddress, referrerAddress, level, false);
        return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    } else if (refFirstReferrals[0] == userAddress) {
        updateX6(userAddress, referrerAddress, level, true);
        return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    if (users[refFirstReferrals[0]].matrices[level].firstLevelReferrals.length <=
        users[refFirstReferrals[1]].matrices[level].firstLevelReferrals.length) {
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
    Matrix memory cReferrerdata = users[currentReferrer].matrices[level];
    users[currentReferrer].matrices[level].firstLevelReferrals.push(userAddress);

    emit NewUserPlace(userAddress, currentReferrer, level, uint8(cReferrerdata.firstLevelReferrals.length));
    emit NewUserPlace(userAddress, referrerAddress, level, 2 + uint8(cReferrerdata.firstLevelReferrals.length));

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
    Matrix storage userData = users[referrerAddress].matrices[level];

    userData.firstLevelReferrals = new address[](0);
    userData.secondLevelReferrals = new address[](0);
    userData.closedPart = address(0);

    if (!users[referrerAddress].activeLevels[level + 1] && level != LAST_LEVEL) {
        userData.blocked = true;
    }

    userData.reinvestCount++;

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
    
            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedEthReceive(receiver, _from, level);
                    isExtraDividends = true;
                    receiver = users[receiver].matrices[level].currentReferrer;

        }}}

    

    function transferProductFund(address userAddress, uint256 amount) private {
        require(users[userAddress].autoUpgradeStatus == true);
        userWallet[userAddress].tokenBalance[DaiAddress] -= amount;
        userWallet[userAddress].productFund[DaiAddress] += amount;
        }

//innerwallet transfer

    function transferTokenDAI(address to, address from, uint256 amount) internal { 
        userWallet[from].tokenBalance[DaiAddress] -= amount; 
        userWallet[to].tokenBalance[DaiAddress] += amount;
        }

    function Withdraw(address ERC20, uint256 amount) external  {
        require(isUserExists(msg.sender), "User Is Not Exists");
        require(userWallet[msg.sender].tokenBalance[ERC20] >= amount, "insufficient balance");
        require(freezedToken[ERC20], "token Is Freezed");
        require(Dai.transferFrom(address(this), msg.sender, amount), "Withdraw Fail");
        }
    
    function Deposit(uint256 amount) external returns (bool) {
        require(isUserExists(msg.sender), "User Is Not Exists, Register First");
        bool success = Dai.transferFrom(msg.sender, address(this), amount); 
        userWallet[msg.sender].tokenBalance[DaiAddress] += amount;
        return success;
        }

//                                   receiver           sender          price
    function sendDividends(address userAddress, address _from, uint8 level) internal {       
        (address receiver, bool isExtraDividends) = findReceiver(userAddress, _from, level);
        uint256 amount = getPriceoflevel(level);

        transferTokenDAI(userAddress, _from, amount);
        if (isExtraDividends) {
            emit SentExtraDividends(_from, receiver, level);
        }
        if(users[userAddress].autoUpgradeStatus == true){
            require(level == getMaxActiveLevel(userAddress));
            return autoUpgrade(userAddress, level);
        }
    }


    function autoUpgrade(address userAddress, uint8 level) internal {
        uint lenX6 = users[userAddress].matrices[level].secondLevelReferrals.length;
        uint lenX3 = users[userAddress].matrices[level].firstLevelReferrals.length;
        uint8 matrix = getMatrixType(level);
        if (matrix == 3){
            if(lenX3 <= 2){
                transferProductFund(userAddress, getPriceoflevel(getMaxActiveLevel(userAddress)));
            }
        } else {
            if (lenX6 == 2 && lenX6 == 3){
                transferProductFund(userAddress, getPriceoflevel(getMaxActiveLevel(userAddress)));
            }}}

    function setAutoUpgrade(bool Status) external {
            require(isUserExists(msg.sender));
            users[msg.sender].autoUpgradeStatus = Status;
            if(Status == false){
            transferProductFundtoWallet(msg.sender);}
    }

    function transferProductFundtoWallet(address userAddress) internal {
        uint8 level = getMaxActiveLevel(userAddress);
        uint256 amount = userWallet[userAddress].productFund[DaiAddress];
        uint256 prosessingFee = levelPrice[level + 1] / 4;
        uint256 refund = amount - prosessingFee;
        uint256 productFund = userWallet[userAddress].productFund[DaiAddress];
        uint256 tokenBalance = userWallet[userAddress].tokenBalance[DaiAddress];
                if(productFund <= prosessingFee){
            require(tokenBalance <= prosessingFee, "not enough balance to cancel Autoupgrade, Deposit First");
            tokenBalance -= prosessingFee;
            userWallet[owner].tokenBalance[DaiAddress] -= prosessingFee;
        }
        productFund -= refund;
        tokenBalance += refund;
        productFund -= prosessingFee;
        userWallet[owner].tokenBalance[DaiAddress] += prosessingFee;


    }



    function getMaxActiveLevel(address userAddress) private view returns (uint8) {
        uint8 maxLevel;

        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            if (users[userAddress].activeLevels[i]) {
                maxLevel = i;
            }
        }
        return maxLevel;
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
}