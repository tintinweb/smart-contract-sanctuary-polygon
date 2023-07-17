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
    


        
    constructor(address ownerAddress) public {
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

        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;

        }}

    


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
    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) internal {
        Matrix storage referrer = users[referrerAddress].matrices[level];
        Matrix storage referrer1 = users[referrer.Referrals[0]].matrices[level];
        Matrix storage referrer2 = users[referrer.Referrals[1]].matrices[level];

        if (referrer1.Referrals.length == 0 && referrer2.Referrals.length == 0) {
            users[userAddress].matrices[level].currentReferrer = referrer.Referrals[0];
            referrer1.Referrals.push(userAddress);
        } else if (referrer1.Referrals.length <= referrer2.Referrals.length) {
            users[userAddress].matrices[level].currentReferrer = referrer.Referrals[0];
            referrer1.Referrals.push(userAddress);
        } else {
            users[userAddress].matrices[level].currentReferrer = referrer.Referrals[1];
            referrer2.Referrals.push(userAddress);
        }

        if (referrerAddress == owner) {
            return sendDividends(owner, userAddress, level, 6, referrer.Referrals.length);
        }

        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }


    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) internal {
        Matrix storage referrerMatrix = users[referrerAddress].matrices[level];

        if (referrerMatrix.secondLevelReferrals.length < 4) {
            return sendDividends(referrerAddress, userAddress, level, 6, referrerMatrix.secondLevelReferrals.length);
        }

        Matrix storage referrer = users[referrerAddress].matrices[level];
        Matrix storage ref = users[referrer.currentReferrer].matrices[level];

        if (referrer.Referrals.length == 2 && (referrer.Referrals[0] == referrerAddress || referrer.Referrals[1] == referrerAddress)) {
            ref.closedPart = referrerAddress;
        } else if (referrer.Referrals.length == 1 && referrer.Referrals[0] == referrerAddress) {
            ref.closedPart = referrerAddress;
        }

        referrer.Referrals = new address[](0);
        referrer.secondLevelReferrals = new address[](0);
        referrer.closedPart = address(0);

        if (!users[referrerAddress].activeLevels[level+1] && level != LAST_LEVEL) {
            referrer.blocked = true;
        }

        referrer.reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendDividends(owner, userAddress, level, 6, referrerMatrix.secondLevelReferrals.length);
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
  function findReceiver(address userAddress, address _from, uint8 level) private returns(address) {
        address receiver = userAddress;

            while (true) {
                if (users[receiver].matrices[level].blocked) {
                    emit MissedReceive(receiver, _from, level);
                    receiver = users[receiver].matrices[level].currentReferrer;
                } else {
                    return receiver;
                }
            }}




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