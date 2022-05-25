/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract VotingMESH {
    // ======== ERC20 ========
    event Transfer(address indexed from, address indexed to, uint amount);
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;
    mapping(address => uint) public balanceOf;

    address public governance;
    address payable public implementation;

    // ======== Staking ========
    mapping(address => uint) public lockedMESH;
    mapping(address => uint) public unlockTime;
    mapping(address => uint) public lockPeriod;

    mapping(address => uint) public snapShotCount;
    mapping(address => mapping(uint => uint)) public snapShotBlock;
    mapping(address => mapping(uint => uint)) public snapShotBalance;

    // ======== Mining ========
    uint public mining;
    uint public lastMined;
    uint public miningIndex;
    mapping(address => uint) public userLastIndex;
    mapping(address => uint) public userRewardSum;

    bool public entered = false;
    
    address public policyAdmin;
    bool public paused = false;
    
    constructor(string memory _name, string memory _symbol, address payable _implementation, address _governance) public {
        name = _name;
        symbol = _symbol;
        implementation = _implementation;
        governance = _governance;
        policyAdmin = msg.sender;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == governance);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IMESH {
    function mined() external view returns (uint);
}

interface IGovernance {
    function mesh() external view returns (address);
    function poolVoting() external view returns (address);
    function ecoPotVoting() external view returns (address);
    function sendReward(address, uint) external;
    function getEpochMining(address) external view returns(uint, uint, uint[] memory, uint[] memory);
    function acceptEpoch() external;
}

interface IPoolVoting{
    function removeAllVoting(address, bool) external;
}

interface IEcoPotVoting{
    function removeAllVoting(address) external;
}

contract VotingMESHImpl is VotingMESH {

    using SafeMath for uint256;
    
    event SetPolicyAdmin(address policyAdmin);
    event ChangePaused(bool paused);
    event LockMESH(address user, uint lockPeriod, uint MESHAmount, uint totalLockedMESH, uint unlockTime);
    event RefixBoosting(address user, uint lockPeriod, uint boostingAmount, uint unlockTime);
    event UnlockMESH(address user, uint vMESHAmount, uint MESHAmount);
    event UnlockMESHUnlimited(address user, uint vMESHBefore, uint vMESHAfter, uint MESHAmount, uint unlockTime);

    event ChangeMiningRate(uint _mining);
    event UpdateMiningIndex(uint lastMined, uint miningIndex);
    event GiveReward(address user, uint amount, uint lastIndex, uint rewardSum);
    event Compound(address user, uint reward, uint compoundAmount, uint transferAmount, uint mintAmount);

    constructor() public VotingMESH("", "", address(0), address(0)){}

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    function version() public pure returns (string memory) {
        return "VotingMESHImpl20220331";
    }

    function setPolicyAdmin(address _policyAdmin) public {
        require(msg.sender == policyAdmin);
        policyAdmin = _policyAdmin;

        emit SetPolicyAdmin(_policyAdmin);
    }

    function changePaused(bool _paused) public {
        require(msg.sender == policyAdmin);

        paused = _paused;
        emit ChangePaused(_paused);
    }
    
    // ======== Staking ========

    function getUserUnlockTime(address user) public view returns (uint) {
        if (unlockTime[user] == 0) return 0;

        if(now <= unlockTime[user]){
            return unlockTime[user];
        }
        else if(now.sub(unlockTime[user]).mod(lockPeriod[user]) > 30 days){
            return unlockTime[user].add(now.sub(unlockTime[user]).div(lockPeriod[user]).add(1).mul(lockPeriod[user]));
        }
        else{
            return unlockTime[user].add(now.sub(unlockTime[user]).div(lockPeriod[user]).mul(lockPeriod[user]));
        }
    }

    function getCurrentBalance(address user) public view returns (uint) {
        require(user != address(0));

        uint index = snapShotCount[user];
        return index > 0 ? snapShotBalance[user][index - 1] : 0;
    }

    function getPriorBalance(address user, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number);
        require(user != address(0));

        uint index = snapShotCount[user];
        if (index == 0) {
            return 0;
        }

        if (snapShotBlock[user][index - 1] <= blockNumber) {
            return snapShotBalance[user][index - 1];
        }

        if (snapShotBlock[user][0] > blockNumber) {
            return 0;
        }

        uint lower = 0;
        uint upper = index - 1;
        while (upper > lower) {
            uint center = upper - ((upper - lower) / 2);
            uint centerBlock = snapShotBlock[user][center];
            uint centerBalance = snapShotBalance[user][center];

            if (centerBlock == blockNumber) {
                return centerBalance;
            } else if (centerBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return snapShotBalance[user][lower];
    }

    function getPriorSupply(uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number);
        require(snapShotBlock[address(0)][0] != 0 && blockNumber >= snapShotBlock[address(0)][0]);

        uint index = snapShotCount[address(0)];
        if (index == 0) {
            return 0;
        }

        if (snapShotBlock[address(0)][index - 1] <= blockNumber) {
            return snapShotBalance[address(0)][index - 1];
        }

        uint lower = 0;
        uint upper = index - 1;
        while (upper > lower) {
            uint center = upper - ((upper - lower) / 2);
            uint centerBlock = snapShotBlock[address(0)][center];
            uint centerBalance = snapShotBalance[address(0)][center];

            if (centerBlock == blockNumber) {
                return centerBalance;
            } else if (centerBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return snapShotBalance[address(0)][lower];
    }

    function vMESHAmountByPeriod(uint amount, uint period) internal pure returns (uint) {
        if (period == 120 days) {
            return amount;
        } else if (period == 240 days) {
            return amount.mul(2);
        } else if (period == 360 days) {
            return amount.mul(4);
        } else if (period == 18000 days) {
            return amount.mul(8);
        } else {
            require(false);
        }
    }

    function lockMESH(uint amount, uint lockPeriodRequested) public nonReentrant {
        require(!paused, "Voting: Paused");
        if (Address.isContract(msg.sender)) {
            require(lockPeriodRequested == 18000 days);
        } else {
            require(lockPeriodRequested == 120 days || lockPeriodRequested == 240 days || lockPeriodRequested == 360 days || lockPeriodRequested == 18000 days);
        }

        giveReward(msg.sender, msg.sender);

        if (amount > 0) {
            amount = amount.mul(10 ** 18);
            require(IERC20(IGovernance(governance).mesh()).transferFrom(msg.sender, address(this), amount));

            if (lockPeriod[msg.sender] == 18000 days) {
                require(lockPeriodRequested == 18000 days);
            }

            uint mintAmount = (lockPeriod[msg.sender] <= lockPeriodRequested) ? 
                vMESHAmountByPeriod(lockedMESH[msg.sender].add(amount), lockPeriodRequested).sub(balanceOf[msg.sender]) 
                : vMESHAmountByPeriod(amount, lockPeriodRequested);

            updateMiningIndex();
            lockedMESH[msg.sender] = lockedMESH[msg.sender].add(amount);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(mintAmount);
            totalSupply = totalSupply.add(mintAmount);
            emit Transfer(address(0), msg.sender, mintAmount);

            if (now.add(lockPeriodRequested) > getUserUnlockTime(msg.sender)){
                unlockTime[msg.sender] = now.add(lockPeriodRequested);
            }
            
            if (lockPeriod[msg.sender] < lockPeriodRequested){
                lockPeriod[msg.sender] = lockPeriodRequested;
            }

            addSnapShot(msg.sender);
            addSupplySnapShot();
        } else {
            require(lockedMESH[msg.sender] > 0);

            if (lockPeriod[msg.sender] <= lockPeriodRequested) {
                updateMiningIndex();
                uint mintAmount = vMESHAmountByPeriod(lockedMESH[msg.sender], lockPeriodRequested).sub(balanceOf[msg.sender]);
                if (mintAmount > 0) {
                    balanceOf[msg.sender] = balanceOf[msg.sender].add(mintAmount);
                    totalSupply = totalSupply.add(mintAmount);
                    emit Transfer(address(0), msg.sender, mintAmount);
                }
                lockPeriod[msg.sender] = lockPeriodRequested;
                
                addSnapShot(msg.sender);
                addSupplySnapShot();
            } 
            
            uint userUnlockTime = getUserUnlockTime(msg.sender);
            
            if (now.add(lockPeriodRequested) > userUnlockTime) {
                unlockTime[msg.sender] = (now > userUnlockTime) ? 
                    userUnlockTime.add(lockPeriodRequested)
                    : now.add(lockPeriodRequested);
            }
        } 
        
        emit LockMESH(msg.sender, lockPeriodRequested, amount, lockedMESH[msg.sender], getUserUnlockTime(msg.sender));
    }

    function refixBoosting(uint lockPeriodRequested) public nonReentrant {
        require(!paused, "Voting: Paused");
        require(lockedMESH[msg.sender] > 0);
        require(lockPeriodRequested == 240 days || lockPeriodRequested == 360 days || lockPeriodRequested == 18000 days);

        giveReward(msg.sender, msg.sender);

        uint boostingAmount = vMESHAmountByPeriod(lockedMESH[msg.sender], lockPeriodRequested);
        require(boostingAmount > balanceOf[msg.sender]);

        updateMiningIndex();
        uint mintAmount = boostingAmount.sub(balanceOf[msg.sender]);
        totalSupply = totalSupply.add(mintAmount);
        emit Transfer(address(0), msg.sender, mintAmount);

        balanceOf[msg.sender] = boostingAmount;

        if (now.add(lockPeriodRequested) > getUserUnlockTime(msg.sender)) {
            unlockTime[msg.sender] = now.add(lockPeriodRequested);
        }

        if (lockPeriod[msg.sender] < lockPeriodRequested){
            lockPeriod[msg.sender] = lockPeriodRequested;
        }

        addSnapShot(msg.sender);
        addSupplySnapShot();

        emit RefixBoosting(msg.sender, lockPeriodRequested, boostingAmount, getUserUnlockTime(msg.sender));
    }

    function unlockMESH() public nonReentrant {
        require(!Address.isContract(msg.sender));
        require(unlockTime[msg.sender] != 0 && balanceOf[msg.sender] != 0);
        require(now > getUserUnlockTime(msg.sender));
        require(lockPeriod[msg.sender] <= 360 days);

        giveReward(msg.sender, msg.sender);

        uint userLockedMESH = lockedMESH[msg.sender];
        uint userBalance = balanceOf[msg.sender];

        IPoolVoting(IGovernance(governance).poolVoting()).removeAllVoting(msg.sender, true);
        if (IGovernance(governance).ecoPotVoting() != address(0)) {
            IEcoPotVoting(IGovernance(governance).ecoPotVoting()).removeAllVoting(msg.sender);
        }
        require(IERC20(IGovernance(governance).mesh()).transfer(msg.sender, lockedMESH[msg.sender]));

        updateMiningIndex();
        totalSupply = totalSupply.sub(balanceOf[msg.sender]);
        emit Transfer(msg.sender, address(0), balanceOf[msg.sender]);

        lockedMESH[msg.sender] = 0;
        balanceOf[msg.sender] = 0;
        unlockTime[msg.sender] = 0;
        lockPeriod[msg.sender] = 0;

        addSnapShot(msg.sender);
        addSupplySnapShot();

        emit UnlockMESH(msg.sender, userBalance, userLockedMESH);
    }

    function unlockMESHUnlimited() public nonReentrant {
        require(!Address.isContract(msg.sender));
        require(lockedMESH[msg.sender] > 0);
        require(lockPeriod[msg.sender] == 18000 days);
        require(lockedMESH[msg.sender].mul(8) == balanceOf[msg.sender]);

        giveReward(msg.sender, msg.sender);

        uint userBalanceBefore = balanceOf[msg.sender];
        uint userBalanceAfter = balanceOf[msg.sender].div(2);
        IPoolVoting(IGovernance(governance).poolVoting()).removeAllVoting(msg.sender, false);
        if (IGovernance(governance).ecoPotVoting() != address(0)) {
            IEcoPotVoting(IGovernance(governance).ecoPotVoting()).removeAllVoting(msg.sender);
        }

        updateMiningIndex();
        totalSupply = totalSupply.sub(userBalanceAfter);
        emit Transfer(msg.sender, address(0), userBalanceAfter);

        balanceOf[msg.sender] = userBalanceAfter;
        require(lockedMESH[msg.sender].mul(4) == balanceOf[msg.sender]);

        unlockTime[msg.sender] = now.add(360 days);
        lockPeriod[msg.sender] = 360 days;

        addSnapShot(msg.sender);
        addSupplySnapShot();

        emit UnlockMESHUnlimited(msg.sender, userBalanceBefore, userBalanceAfter, lockedMESH[msg.sender], unlockTime[msg.sender]);
    }

    function addSnapShot(address user) private {
        uint index = snapShotCount[user];

        if(index == 0 && snapShotBlock[user][index] == block.number){
            snapShotBalance[user][index] = balanceOf[user];
        }
        else if(index != 0 && snapShotBlock[user][index - 1] == block.number){
            snapShotBalance[user][index - 1] = balanceOf[user];
        }
        else{
            snapShotBlock[user][index] = block.number;
            snapShotBalance[user][index] = balanceOf[user];
            snapShotCount[user] = snapShotCount[user].add(1);
        }
    }

    function addSupplySnapShot() private {
        uint index = snapShotCount[address(0)];

        if(index == 0 && snapShotBlock[address(0)][index] == block.number){
            snapShotBalance[address(0)][index] = totalSupply;
        }
        else if(index != 0 && snapShotBlock[address(0)][index - 1] == block.number){
            snapShotBalance[address(0)][index - 1] = totalSupply;
        }
        else{
            snapShotBlock[address(0)][index] = block.number;
            snapShotBalance[address(0)][index] = totalSupply;
            snapShotCount[address(0)] = snapShotCount[address(0)].add(1);
        }
    }

    // ======== Mining ========

    function setEpochMining() private {
        (uint curEpoch, uint prevEpoch, uint[] memory rates, uint[] memory mined) = IGovernance(governance).getEpochMining(address(0));
        if(curEpoch == prevEpoch) return;

        uint epoch = curEpoch.sub(prevEpoch);
        require(rates.length == epoch);
        require(rates.length == mined.length);

        uint thisMined;
        for(uint i = 0; i < epoch; i++){
            thisMined = mining.mul(mined[i].sub(lastMined)).div(10000);

            require(rates[i] <= 10000);
            mining = rates[i];
            lastMined = mined[i];
            if (thisMined != 0 && totalSupply != 0) {
                miningIndex = miningIndex.add(thisMined.mul(10 ** 18).div(totalSupply));
            }

            emit ChangeMiningRate(mining);
            emit UpdateMiningIndex(lastMined, miningIndex);
        }

        IGovernance(governance).acceptEpoch();
    }

    function updateMiningIndex() public returns (uint) {
        setEpochMining();

        uint mined = IMESH(IGovernance(governance).mesh()).mined();

        if (mined > lastMined) {
            uint thisMined = mining.mul(mined.sub(lastMined)).div(10000);

            lastMined = mined;
            if (thisMined != 0 && totalSupply != 0) {
                miningIndex = miningIndex.add(thisMined.mul(10 ** 18).div(totalSupply));
            }

            emit UpdateMiningIndex(lastMined, miningIndex);
        }

        return miningIndex;
    }

    function giveReward(address user, address to) private {
        uint lastIndex = userLastIndex[user];
        uint currentIndex = updateMiningIndex();

        uint have = balanceOf[user];

        if (currentIndex > lastIndex) {
            userLastIndex[user] = currentIndex;

            if (have != 0) {
                uint amount = have.mul(currentIndex.sub(lastIndex)).div(10 ** 18);
                IGovernance(governance).sendReward(to, amount);

                userRewardSum[user] = userRewardSum[user].add(amount);
                emit GiveReward(user, amount, currentIndex, userRewardSum[user]);
            }
        }
    }

    function claimReward() public nonReentrant {
        giveReward(msg.sender, msg.sender);
    }

    function compoundReward() public nonReentrant {
        require(!paused, "Voting: Paused");
        address user = msg.sender;
        IERC20 mesh = IERC20(IGovernance(governance).mesh());

        uint diff = mesh.balanceOf(address(this));
        giveReward(user, address(this));
        diff = mesh.balanceOf(address(this)).sub(diff);
        require(diff >= 10 ** 18);

        uint compoundAmount = (diff / 10 ** 18) * 10 ** 18;
        uint transferAmount = diff.sub(compoundAmount);
        if(transferAmount != 0){
            require(mesh.transfer(user, transferAmount));
        }

        uint mintAmount = vMESHAmountByPeriod(compoundAmount, lockPeriod[user]);
        require(mintAmount != 0);

        updateMiningIndex();
        lockedMESH[user] = lockedMESH[user].add(compoundAmount);
        balanceOf[user] = balanceOf[user].add(mintAmount);
        totalSupply = totalSupply.add(mintAmount);
        emit Transfer(address(0), user, mintAmount);

        addSnapShot(user);
        addSupplySnapShot();

        emit Compound(user, diff, compoundAmount, transferAmount, mintAmount);
    }

    function () payable external {
        revert();
    }
}