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
        mapping(address => uint256) tokenBalance;
        mapping(address => uint256) productFund; 

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
    address[] private currentERC20;


    uint public lastUserId = 2;
    address public owner;
    address private secondOwner;
    address private thirdOwner;
    address private forthOwner;
    address private fifthOwner;
    IERC20 private Dai;
    address public DaiAddress = 0x6D8873f56a56f0Af376091beddDD149f3592e854;
    IERC20 private JoinReward;
    address public Reward; 
    mapping(address => uint256) rewardBalance;

    mapping(uint8 => uint256) private levelPrice;
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
        JoinReward = IERC20(Reward);

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


        registration(secondOwnerAddress, ownerAddress);
        registration(thirdOwnerAddress, ownerAddress);
        registration(forthOwnerAddress, secondOwnerAddress);
        registration(fifthOwnerAddress, secondOwnerAddress);
        users[secondOwnerAddress].autoUpgradeStatus = false;

               for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[secondOwnerAddress].activeLevels[i] = true;
            users[ownerAddress].activeLevels[i] = true;
        }

            for (uint8 i = 1; i <= 5; i++) {
            users[thirdOwnerAddress].activeLevels[i] = true;
            users[forthOwnerAddress].activeLevels[i] = true;
            users[fifthOwnerAddress].activeLevels[i] = true;
        }

            for (uint8 i = 1; i <= 5; i++){
            users[thirdOwnerAddress].matrices[i].currentReferrer = ownerAddress;
            users[ownerAddress].matrices[i].firstLevelReferrals.push(thirdOwnerAddress);
            users[forthOwnerAddress].matrices[i].currentReferrer = secondOwnerAddress;
            users[fifthOwnerAddress].matrices[i].currentReferrer = secondOwnerAddress;
            users[secondOwnerAddress].matrices[i].firstLevelReferrals.push(forthOwnerAddress);
            users[secondOwnerAddress].matrices[i].firstLevelReferrals.push(fifthOwnerAddress);
            }

            for (uint8 i = 1; i <= LAST_LEVEL; i++){
                users[secondOwnerAddress].matrices[i].currentReferrer = ownerAddress;
                users[ownerAddress].matrices[i].firstLevelReferrals.push(secondOwnerAddress);
            }
            for (uint8 i = 1; i <= 5; i++){
                if(i != 3){
                    users[ownerAddress].matrices[i].secondLevelReferrals.push(forthOwnerAddress);
                    users[ownerAddress].matrices[i].secondLevelReferrals.push(fifthOwnerAddress);
                }
            }
        }}
    function registrationExt(address referrerAddress) external {
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(registrationApproval(msg.sender), "not Enough Allowance");
        registration(msg.sender, referrerAddress);
        }
    function registrationApproval(address userAddress) private returns (bool) {
        require(isUserExists(userAddress));
        uint8 level = 12;
        uint256 amount = levelPrice[level];
        bool success = Dai.approve(address(this), amount);
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
        users[userAddress].activeLevels[0] = true;
    }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function getPriceoflevel(uint8 level) private view returns(uint256) {
            return levelPrice[level];
    }
    function buyNewLevel(uint8 level) external  {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(userWallet[msg.sender].tokenBalance[DaiAddress] <= getPriceoflevel(level), "not enough Balance");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

                require(!users[msg.sender].activeLevels[level], "level already activated");

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                }
        
                address freeReferrer = findFreeReferrer(msg.sender, level);
                users[msg.sender].matrices[level].currentReferrer = freeReferrer;
                updateReferrer(msg.sender, freeReferrer, level);
                
                emit Upgrade(msg.sender, freeReferrer, level);
        }

    function getMatrixType(uint8 level) private pure returns (uint8) {
        if (level % 3 == 0 && level <= LAST_LEVEL) {
            return 3; 
        } else {
            return 6; 
        }}
    function updateReferrer(address userAddress, address referrerAddress, uint8 level) private {
        uint8 matrix = getMatrixType(level);
        if (matrix == 3){
            return updateX3Referrer(userAddress, referrerAddress, level);
        } else {
            return updateX6Referrer(userAddress, referrerAddress, level);
        }

    }
    
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
    function findFreeReferrer(address userAddress, uint8 level) internal view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                return users[userAddress].matrices[level].currentReferrer;
            }
            
            userAddress = users[userAddress].matrices[level].currentReferrer;
            }
    }
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
    function isUserExists(address user) internal view returns (bool) {
        return (users[user].id != 0);
    }
    function findReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedEthReceive(receiver, _from, level);
                    isExtraDividends = true;
                    receiver = users[receiver].matrices[level].currentReferrer;
        }}}

    function transferToken(address from, address to, uint8 level) internal { 
        uint256 amount = levelPrice[level];
        bool autoUpgrade = users[to].autoUpgradeStatus;
        userWallet[from].tokenBalance[DaiAddress] -= amount; 
        userWallet[to].tokenBalance[DaiAddress] += amount;
        if (autoUpgrade){
            require(level == getMaxActiveLevel(to));
            uint256 tokenBalance = userWallet[to].tokenBalance[DaiAddress];
            uint256 ProductFund = userWallet[to].productFund[DaiAddress];
            uint lenX6 = users[to].matrices[level].secondLevelReferrals.length;
            uint lenX3 = users[to].matrices[level].firstLevelReferrals.length;
            uint8 matrix = getMatrixType(level);
            if (matrix == 3){
                if(lenX3 <= 2){
                tokenBalance -= levelPrice[level];
                ProductFund += levelPrice[level];
                }
            } else {
                 if (lenX6 == 2 || lenX6 ==  3){
                tokenBalance -= levelPrice[level];
                ProductFund += levelPrice[level];
            }}}}
        
    function Withdraw(address ERC20, uint256 amount) external returns(bool) {
        require(isUserExists(msg.sender), "User Is Not Exists");
        require(userWallet[msg.sender].tokenBalance[ERC20] >= amount, "insufficient balance");
        require(getTokenStatus(ERC20), "token Is Freezed");
        bool success = Dai.transferFrom(address(this), msg.sender, amount);
        return success;
        }
    //false = freeze
    function setTokenFreeze(address ERC20, bool freeze) external onlyOwner {
         freezedToken[ERC20] = freeze;
    }
    function getTokenStatus(address ERC20) public view returns (bool) {
        return freezedToken[ERC20];
    }
    function Deposit(uint256 amount) external returns (bool) {
        uint256 dai = amount * 10 ** 18;
        require(isUserExists(msg.sender), "User Is Not Exists, Register First");
        bool success = Dai.transferFrom(msg.sender, address(this), dai); 
        userWallet[msg.sender].tokenBalance[DaiAddress] += amount;
        return success;
        }

    function sendDividends(address userAddress, address _from, uint8 level) internal {       
        (address receiver, bool isExtraDividends) = findReceiver(userAddress, _from, level);
        if(rewardBalance[Reward] >= levelPrice[level] * 10){
        transferReward(receiver, levelPrice[level]);}
        if(level == 12){
        transferToken(userAddress, receiver , level);
        users[userAddress].autoUpgradeStatus = false;

    } else {
        transferToken(userAddress, receiver, level);
        
    }
        if (isExtraDividends) {
            emit SentExtraDividends(_from, receiver, level);
        }}


    function setAutoUpgrade(bool Status) external {
            require(isUserExists(msg.sender));
            users[msg.sender].autoUpgradeStatus = Status;
            if(Status == false){
            transferProductFundtoWallet(msg.sender);}
    }

    function transferProductFundtoWallet(address userAddress) internal {
        require(userWallet[userAddress].productFund[DaiAddress] >1, "productFund must more than 1USD");
        uint256 amount = userWallet[userAddress].productFund[DaiAddress];
        uint256 prosessingFee = amount / 4;
        uint256 refund = amount - prosessingFee;
        uint256 tokenBalance = userWallet[userAddress].tokenBalance[DaiAddress];
                if(amount < prosessingFee){
            require(tokenBalance >= prosessingFee, "not enough balance to cancel Autoupgrade, Deposit First");
            tokenBalance -= prosessingFee;
            userWallet[owner].tokenBalance[DaiAddress] += prosessingFee;
        }
        amount -= refund; //0.75
        tokenBalance += refund; // 0.75
        amount -= prosessingFee; // 0.25
        userWallet[owner].tokenBalance[DaiAddress] += prosessingFee; // 0.25
    }

    function getUserTokenBalance(address erc20Address) public view returns (uint256) {
        InnerWallet storage wallet = userWallet[msg.sender];
        return wallet.tokenBalance[erc20Address];
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

    function currentRewardBalance() public view returns (uint256) {
        return rewardBalance[Reward];
    }
    
    function setReward(address _reward, uint256 amount) public onlyOwner returns (bool) {
        Reward = _reward;
        uint256 total = amount * 10 ** 18; 
        bool success = JoinReward.transferFrom(msg.sender, address(this), total);
        rewardBalance[_reward] += total;
        currentERC20.push(_reward);
            for (uint i = 0; i < lastUserId; i++) {
                InnerWallet storage wallet = userWallet[userIds[i]];
                wallet.tokenList.push(_reward);
        }       
        return success;
    }
    function transferReward(address userAddress, uint256 amount) internal {
        uint256 Rewardrate = 10;
        uint256 subtotal = Rewardrate * amount;
        rewardBalance[Reward] -= subtotal;
        userWallet[userAddress].tokenBalance[Reward] += subtotal;

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