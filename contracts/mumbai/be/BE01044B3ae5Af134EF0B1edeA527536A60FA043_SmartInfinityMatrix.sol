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
        uint8 Max_Level;
    }
    struct InnerWallet {
        address[] tokenList; 
        mapping(address => uint256) tokenBalance;
        mapping(address => uint256) productFund; 

    }
    struct Matrix {
        address currentReferrer;
        address[] Referrals;
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
    address public joinReward; 
    IERC20 private reward;
    address public currentReward;
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
        JoinReward = IERC20(joinReward);
        reward = IERC20(currentReward);

        currentERC20.push(DaiAddress);
        freezedToken[DaiAddress] = false;
        
        owner = ownerAddress; 
        InnerWallet memory walletOwner;
        walletOwner.tokenList = new address[](0);
        address[] memory tokenList = new address[](1);
        tokenList[0] = DaiAddress;
        userWallet[ownerAddress] = walletOwner;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 0,
            autoUpgradeStatus: false,
            Max_Level: 0
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;


        registration(secondOwnerAddress, ownerAddress);
        registration(thirdOwnerAddress, ownerAddress);
        registration(forthOwnerAddress, secondOwnerAddress);
        registration(fifthOwnerAddress, secondOwnerAddress);
        users[secondOwnerAddress].autoUpgradeStatus = false;

            for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;     
        }
            for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[secondOwnerAddress].activeLevels[i] = true;     
        }


            for (uint8 i = 0; i <= 5; i++) {
            users[thirdOwnerAddress].activeLevels[i] = true;
            users[forthOwnerAddress].activeLevels[i] = true;
            users[fifthOwnerAddress].activeLevels[i] = true;
            }
            users[ownerAddress].Max_Level += 12;
            users[secondOwnerAddress].Max_Level += 12;
            users[thirdOwnerAddress].Max_Level += 5;
            users[forthOwnerAddress].Max_Level += 5;
            users[fifthOwnerAddress].Max_Level += 5;

            for (uint8 i = 0; i <= 5; i++){
            users[thirdOwnerAddress].matrices[i].currentReferrer = ownerAddress;
            users[ownerAddress].matrices[i].Referrals.push(thirdOwnerAddress);
            users[forthOwnerAddress].matrices[i].currentReferrer = secondOwnerAddress;
            users[fifthOwnerAddress].matrices[i].currentReferrer = secondOwnerAddress;
            users[secondOwnerAddress].matrices[i].Referrals.push(forthOwnerAddress);
            users[secondOwnerAddress].matrices[i].Referrals.push(fifthOwnerAddress);
            }

            for (uint8 i = 0; i <= LAST_LEVEL; i++){
                users[secondOwnerAddress].matrices[i].currentReferrer = ownerAddress;
                users[ownerAddress].matrices[i].Referrals.push(secondOwnerAddress);
            }
            for (uint8 i = 0; i <= 5; i++){
                if(i != 3){
                    users[ownerAddress].matrices[i].secondLevelReferrals.push(forthOwnerAddress);
                    users[ownerAddress].matrices[i].secondLevelReferrals.push(fifthOwnerAddress);
                }
            }
        }

    function registrationExt(address referrerAddress) external returns (bool) {
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        registration(msg.sender, referrerAddress);
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
            autoUpgradeStatus: true,
            Max_Level: 0
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
        users[userAddress].matrices[0].currentReferrer = referrerAddress;
    }
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }


    function buyNewLevel(uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(userWallet[msg.sender].tokenBalance[DaiAddress] >= levelPrice[level], "not enough Balance");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");

                require(!users[msg.sender].activeLevels[level], "level already activated");

                if (users[msg.sender].matrices[level-1].blocked) {
                    users[msg.sender].matrices[level-1].blocked = false;
                    
                }
        
                address freeReferrer = findFreeReferrer(msg.sender, level);
                users[msg.sender].matrices[level].currentReferrer = freeReferrer;
                updateReferrer(msg.sender, freeReferrer, level);
                
                emit Upgrade(msg.sender, freeReferrer, level);
                users[msg.sender].Max_Level ++;
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
        address ReferrerAddress = referrerAddress;
        address[] storage X3Referral = users[ReferrerAddress].matrices[level].Referrals;
        uint ReferralLength = users[ReferrerAddress].matrices[level].Referrals.length;
        X3Referral.push(userAddress);
        if (ReferralLength < 3) {
            emit NewUserPlace(userAddress, ReferrerAddress, level, uint8(ReferralLength));
            return sendDividends(ReferrerAddress, userAddress, level);
        } else {
        emit NewUserPlace(userAddress, ReferrerAddress, level, 3);
        //close matrix
        users[ReferrerAddress].matrices[level].Referrals = new address[](0);
        if (!users[ReferrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            users[ReferrerAddress].matrices[level].blocked = true;
        }
        //create new one by recursion
        if (ReferrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeReferrer(ReferrerAddress, level);
            address currentX3referrer = users[ReferrerAddress].matrices[level].currentReferrer;
            if (currentX3referrer != freeReferrerAddress) {
                currentX3referrer = freeReferrerAddress;
            }
            users[ReferrerAddress].matrices[level].reinvestCount++;
            emit Reinvest(ReferrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(ReferrerAddress, freeReferrerAddress, level);
        } else {
            sendDividends(owner, userAddress, level);
            users[owner].matrices[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }}}

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        address ReferrerAddress = referrerAddress ;
        if(!users[referrerAddress].activeLevels[level]){
        ReferrerAddress = findFreeReferrer(userAddress, level);
        } else {
            

        if (users[ReferrerAddress].matrices[level].Referrals.length < 2) {
            users[ReferrerAddress].matrices[level].Referrals.push(userAddress);
            emit NewUserPlace(userAddress, ReferrerAddress, level, uint8(users[ReferrerAddress].matrices[level].Referrals.length));

            // Set current level
            users[userAddress].matrices[level].currentReferrer = referrerAddress;

            if (ReferrerAddress == owner) {
                return sendDividends(referrerAddress, userAddress, level);
            }

            address ref = users[ReferrerAddress].matrices[level].currentReferrer;
            users[ref].matrices[level].secondLevelReferrals.push(userAddress);

            uint len = users[ref].matrices[level].Referrals.length;
            address[] storage firstReferrer = users[ref].matrices[level].Referrals;
            uint LenfirstReferrer = users[ReferrerAddress].matrices[level].Referrals.length;
            if ((len == 2) && (firstReferrer[0] == ReferrerAddress) && (firstReferrer[1] == ReferrerAddress)) {
                emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 5 : 6);
            } else if ((len == 1 || len == 2) && firstReferrer[0] == referrerAddress) {
                emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 3 : 4);
            } else if (len == 2 && firstReferrer[1] == referrerAddress) {
                emit NewUserPlace(userAddress, ref, level, LenfirstReferrer == 1 ? 5 : 6);
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
            address[] storage refFirstReferrals = users[ReferrerAddress].matrices[level].Referrals;
        users[ReferrerAddress].matrices[level].secondLevelReferrals.push(userAddress);
        if (users[ReferrerAddress].matrices[level].closedPart != address(0)) {
            if ((refFirstReferrals[0] == refFirstReferrals[1]) &&
                (refFirstReferrals[0] == users[ReferrerAddress].matrices[level].closedPart)) {
                updateX6(userAddress, ReferrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
            } else if (refFirstReferrals[0] == users[ReferrerAddress].matrices[level].closedPart) {
                updateX6(userAddress, ReferrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
            } else {
                updateX6(userAddress, ReferrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
            }
        }
        if (refFirstReferrals[1] == userAddress) {
            updateX6(userAddress, ReferrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
        } else if (refFirstReferrals[0] == userAddress) {
            updateX6(userAddress, ReferrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
        }
        if (users[refFirstReferrals[0]].matrices[level].Referrals.length <=
            users[refFirstReferrals[1]].matrices[level].Referrals.length) {
            updateX6(userAddress, ReferrerAddress, level, false);
        } else {
            updateX6(userAddress, ReferrerAddress, level, true);
        }
        updateX6ReferrerSecondLevel(userAddress, ReferrerAddress, level);
        }}


    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        address[] storage firstLevelReferrals = users[referrerAddress].matrices[level].Referrals;
        uint8 referralIndex = x2 ? 1 : 0;
        address currentReferrer = firstLevelReferrals[referralIndex];
        Matrix memory cReferrerdata = users[currentReferrer].matrices[level];
        users[currentReferrer].matrices[level].Referrals.push(userAddress);
        emit NewUserPlace(userAddress, currentReferrer, level, uint8(cReferrerdata.Referrals.length));
        emit NewUserPlace(userAddress, referrerAddress, level, 2 + uint8(cReferrerdata.Referrals.length));
        users[userAddress].matrices[level].currentReferrer = currentReferrer;
        }

        function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].matrices[level].secondLevelReferrals.length < 4) {
            return sendDividends(referrerAddress, userAddress, level);
        }
        address currentReferrer = users[referrerAddress].matrices[level].currentReferrer;
        address[] memory x6 = users[currentReferrer].matrices[level].Referrals;

        if (x6.length == 2 && (x6[0] == referrerAddress || x6[1] == referrerAddress)) {
            users[currentReferrer].matrices[level].closedPart = referrerAddress;
        } else if (x6.length == 1 && x6[0] == referrerAddress) {
            users[currentReferrer].matrices[level].closedPart = referrerAddress;
        }
        Matrix storage userData = users[referrerAddress].matrices[level];

        userData.Referrals = new address[](0);
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
                userData.Referrals, 
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
            require(level == users[to].Max_Level);
            uint256 tokenBalance = userWallet[to].tokenBalance[DaiAddress];
            uint256 ProductFund = userWallet[to].productFund[DaiAddress];
            uint lenX6 = users[to].matrices[level].secondLevelReferrals.length;
            uint lenX3 = users[to].matrices[level].Referrals.length;
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
        
    function Withdraw(address Reward, uint256 amount) external returns(bool) {
        require(isUserExists(msg.sender), "User Is Not Exists");
        require(userWallet[msg.sender].tokenBalance[Reward] >= amount, "insufficient balance");
        require(!freezedToken[Reward], "token Is Freezed");
        bool success = IERC20(Reward).transferFrom(address(this), msg.sender, amount);
        userWallet[msg.sender].tokenBalance[Reward] -= amount;
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
        userWallet[msg.sender].tokenBalance[DaiAddress] += dai;
        return success;
        }
//                                   to                 from       
    function sendDividends(address userAddress, address _from, uint8 level) internal {       
        (address receiver, bool isExtraDividends) = findReceiver(userAddress, _from, level);
        if(rewardBalance[joinReward] >= levelPrice[level] * 10){
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

    function getUserTokenBalance(address userAddress, address erc20Address) public view returns (uint256) {
        return userWallet[userAddress].tokenBalance[erc20Address];
    }

    function getUserActiveLevel(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeLevels[level];
    }


    function currentRewardBalance() public view returns (uint256) {
        return rewardBalance[joinReward];
    }
    
    function setReward(address currentjoinReward, uint256 amount) public onlyOwner returns (bool) {
        currentReward = currentjoinReward;
        uint256 total = amount * 10 ** 18; 
        bool success = IERC20(currentjoinReward).transferFrom(msg.sender, address(this), total);
        rewardBalance[currentjoinReward] += total;
        currentERC20.push(currentjoinReward);
            for (uint i = 0; i < lastUserId; i++) {
                InnerWallet storage wallet = userWallet[userIds[i]];
                wallet.tokenList.push(currentjoinReward);
        }       
        return success;
    }
    function transferReward(address userAddress, uint256 amount) internal {
        uint256 Rewardrate = 10 * 10 ** 18;
        uint256 subtotal = Rewardrate * amount;
        rewardBalance[joinReward] -= subtotal;
        userWallet[userAddress].tokenBalance[joinReward] += subtotal;

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