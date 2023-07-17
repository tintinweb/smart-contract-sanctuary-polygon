pragma solidity >=0.4.23 <0.6.0;

import "./IERC20.sol";

contract SmartMatrix {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool autoUpgradeStatus; 
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => Matrix) matrices;
        uint8 Max_Level;
    }
    struct Matrix {
        address currentReferrer;
        address[] Referrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    uint8 public constant LAST_LEVEL = 12;
    mapping(address => User) public users;

    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    address[] private currentERC20;
    uint rewardRate = 10 * 10 ** 18;
    uint public lastUserId = 2;
    address public owner;
    IERC20 private Dai;
    address public DaiAddress = 0x6D8873f56a56f0Af376091beddDD149f3592e854; 
    IERC20 private reward;
    address public currentReward;
    mapping(address => address) RewardToUser;
    mapping(address => uint256) rewardBalance;
    mapping(address => uint256) productFund;
    uint256 BonusReward;
    mapping(uint8 => uint256) public levelPrice;
    bool FreezeToken;
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event MissedReceive(address indexed receiver, address indexed from, uint8 level);
    event SentExtraDividends(address indexed from, address indexed receiver, uint8 level);
    


        
    constructor(address ownerAddress, address second, address third, address forth, address fifth) public {
        levelPrice[1] = 10 * 10**18;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        Dai = IERC20(DaiAddress);

        reward = IERC20(currentReward);

        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            autoUpgradeStatus: false,
            Max_Level:12
        });

        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        

        
        userIds[1] = ownerAddress;

        

        registration(second, ownerAddress);
        registration(third, ownerAddress);
        registration(forth, second);
        registration(fifth, second);

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
            users[second].activeLevels[i] = true;
            users[ownerAddress].matrices[i].Referrals.push(second);
            users[second].matrices[i].currentReferrer = ownerAddress;

        }

        for(uint8 i = 1; i <= 5; i++) {
            users[third].activeLevels[i] = true;
            users[forth].activeLevels[i] = true;
            users[fifth].activeLevels[i] = true;
            users[third].matrices[i].currentReferrer = ownerAddress;
            users[forth].matrices[i].currentReferrer = second;
            users[fifth].matrices[i].currentReferrer = second;
            users[ownerAddress].matrices[i].Referrals.push(third);
            users[second].matrices[i].Referrals.push(forth);
            users[second].matrices[i].Referrals.push(fifth);
        }

        users[second].autoUpgradeStatus = false;

    }
    


//register
    function registrationExt(address referrerAddress) external {
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        registration(msg.sender, referrerAddress);
        }

    function registration(address userAddress, address referrerAddress) internal {
        require(!isContract(userAddress), "cannot be a contract");

        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            autoUpgradeStatus: true,
            Max_Level:0
        });

        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[userAddress].activeLevels[0] = true;

        emit Registration(userAddress, referrerAddress, user.id, users[referrerAddress].id);
    }


//buy level
    function buyNewLevels(uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(Dai.balanceOf(msg.sender) >= levelPrice[level], "not enough Balance");
        require(level >= 1 && level <= LAST_LEVEL, "invalid level");
        require(!users[msg.sender].activeLevels[level], "level already activated");

        if (users[msg.sender].matrices[level-1].blocked) {
            users[msg.sender].matrices[level-1].blocked = false;
        }

        address freeReferrer = findFreeReferrer(msg.sender, level);
        if (level == 3 ||level == 6 ||level == 9 ||level == 12 ) {
            updateX3Referrer(msg.sender, freeReferrer, level);
        } else {
            updateX6Referrer(msg.sender, freeReferrer, level);
        }

        emit Upgrade(msg.sender, freeReferrer, level);
        users[msg.sender].Max_Level++;
    }



//updateX3Referrer
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) internal {
            uint referralsCount = users[referrerAddress].matrices[level].Referrals.length;
            users[referrerAddress].matrices[level].Referrals.push(userAddress);

            if (referralsCount < 3) {
                return sendDividends(referrerAddress, userAddress, level, 3, referralsCount);
            }

            Matrix storage refMatrix = users[referrerAddress].matrices[level];
            refMatrix.Referrals = new address[](0);

            if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
                refMatrix.blocked = true;
            }

            if (referrerAddress != owner) {
                address freeReferrerAddress = findFreeReferrer(referrerAddress, level);
                refMatrix.currentReferrer = freeReferrerAddress;
                refMatrix.reinvestCount++;
                emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
                updateX3Referrer(referrerAddress, freeReferrerAddress, level);
            } else {
                sendDividends(owner, userAddress, level, 3, referralsCount);
                refMatrix.reinvestCount++;
                emit Reinvest(owner, address(0), userAddress, 1, level);
            }
        }

//updateX6Referrer
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeLevels[level], "500. Referrer level is inactive");
        uint reflength = users[referrerAddress].matrices[level].Referrals.length;
        
        if (reflength < 2) {
            users[referrerAddress].matrices[level].Referrals.push(userAddress);

            
            //set current level
            users[userAddress].matrices[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendDividends(referrerAddress, userAddress, level, 6, reflength);
            }
            
            address ref = users[referrerAddress].matrices[level].currentReferrer;            
            users[ref].matrices[level].secondLevelReferrals.push(userAddress); 
            
            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].matrices[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].matrices[level].closedPart != address(0)) {
            if ((users[referrerAddress].matrices[level].Referrals[0] == 
                users[referrerAddress].matrices[level].Referrals[1]) &&
                (users[referrerAddress].matrices[level].Referrals[0] ==
                users[referrerAddress].matrices[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].matrices[level].Referrals[0] == 
                users[referrerAddress].matrices[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].matrices[level].Referrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].matrices[level].Referrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].matrices[level].Referrals[0]].matrices[level].Referrals.length <= 
            users[users[referrerAddress].matrices[level].Referrals[1]].matrices[level].Referrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].matrices[level].Referrals[0]].matrices[level].Referrals.push(userAddress);
            //set current level
            users[userAddress].matrices[level].currentReferrer = users[referrerAddress].matrices[level].Referrals[0];
        } else {
            users[users[referrerAddress].matrices[level].Referrals[1]].matrices[level].Referrals.push(userAddress);
            //set current level
            users[userAddress].matrices[level].currentReferrer = users[referrerAddress].matrices[level].Referrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        uint secondreflength = users[referrerAddress].matrices[level].secondLevelReferrals.length;
        if (secondreflength < 4) {
            return sendDividends(referrerAddress, userAddress, level, 6, secondreflength);
        }
        
        address[] memory x6 = users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].Referrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].matrices[level].currentReferrer].matrices[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].matrices[level].Referrals = new address[](0);
        users[referrerAddress].matrices[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].matrices[level].closedPart = address(0);

        if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].matrices[level].blocked = true;
        }

        users[referrerAddress].matrices[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendDividends(owner, userAddress, level, 6, secondreflength);
        }
    }
//findFreeReferrer
    function findFreeReferrer(address userAddress, uint8 level) internal view returns (address) {
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
            

        }}

//read userMatrix Data
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
//userExists
    function isUserExists(address user) internal view returns (bool) {
        return (users[user].id != 0);
    }
//findReceiver
    function findReceiver(address userAddress, address _from, uint8 level) internal returns(address) {
        address receiver = userAddress;
            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedReceive(receiver, _from, level);
                    receiver = users[receiver].matrices[level].currentReferrer;
    }}}




    function withdrawReward() public canExecute {
        uint256 userRewardBalance = rewardBalance[msg.sender];
        require(userRewardBalance > 0, "No reward balance available.");
        rewardBalance[msg.sender] = 0;
        }



//sendDividends
    function sendDividends(address from, address to, uint8 level, uint8 matrix, uint length) internal {
        address receiver = findReceiver(to, from, level);
        uint256 amount = levelPrice[level];
        bool autoUpgrade = users[receiver].autoUpgradeStatus;
        Dai.transferFrom(from, address(this), amount);
        if(autoUpgrade){
            if(matrix == 3 || length <= 2){
                productFund[receiver] += amount;
            } else if(matrix == 6 || length == 2 || length == 3) {
                productFund[receiver] += amount;
            }
        } else {
            Dai.transfer(receiver, amount);
        }
        }

//cancel AutoUpgrade
    function cancelAutoUpgrade(bool status) internal {
        if(status == false){
        require(productFund[msg.sender] >1, "productFund must more than 1USD");
        require(users[msg.sender].autoUpgradeStatus == true);
        uint256 amount = productFund[msg.sender];
        uint256 prosessingFee = levelPrice[users[msg.sender].Max_Level + 1];
        uint256 refund = amount - prosessingFee;
        Dai.transferFrom(address(this), msg.sender, refund);
        users[msg.sender].autoUpgradeStatus = status;
        BonusReward += refund;//ask
    } else {
        users[msg.sender].autoUpgradeStatus = status;
    }}
//getRewardBalance
    function currentRewardBalance() public view returns (uint256) {
        return rewardBalance[currentReward];
    }
//userActiveLevel   
    function UserActiveLevel(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].activeLevels[level];
        }
    
//setRewardOnlyOwner
    modifier onlyOwner {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;
    }
//setFreezetokenStatus
    modifier canExecute {
    require(!FreezeToken, "Execution is not allowed when tokens are frozen");
    _;
}
//cannot be contract 
    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function OwnerTransferERC20 (address ERC20, uint256 amount) external onlyOwner returns (bool){
        return IERC20(ERC20).transfer(msg.sender, amount);
    }
    }