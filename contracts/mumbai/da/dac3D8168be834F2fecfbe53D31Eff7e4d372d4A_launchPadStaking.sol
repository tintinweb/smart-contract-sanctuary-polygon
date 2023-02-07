// SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.13;

    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    interface IERC20Metadata is IERC20 {

        function decimals() external view returns (uint8);

    }

    interface IStakeable {

        function getStakedAmount(address user) external view returns(uint);
        function isStaker(address user) external view returns(bool);
        function getTotalParticipants() external view returns(uint256);
        function getParticipantsByTierId(uint256 tierId, uint256 poolLevel) external view returns(uint256);
        function isAllocationEligible(uint participationEndTime) external view returns(bool);
        function getTierIdFromUser(address sender) external view returns(uint, uint);
        function isWhiteListaddress(address account) external view returns(bool);

    }

    contract launchPadStaking is IStakeable {

        IERC20Metadata public stakingToken;
        address public owner; 
        address public signer;
        uint256 public totalStaked;
        uint8 public decimals;


        enum tierLevel {Null,BRONZE,SILVER,GOLD,PLATINUM,EMERALD,DIAMOND}
        

        uint256 fee = 10;


        struct poolDetail {
            uint256 poolLevel;
            uint256 poolRewardPercent;
            uint256 poolLimit;
        }

        struct User {
            tierLevel tierId;
            uint256 poolLevel;
            uint256 stakeAmount;
            uint256 rewards;
            uint256 intialStakingTime;
            uint256 lastWithdrawTime;
            bool isStaker;
            bool isUnstakeInitiated;
            uint256 unstakeAmount;
            uint256 unstakeInitiatedTime;
            uint256 unstakeLimit;
            uint256 withdrawStakedAmount;
            uint256 withdrawRewardAmount;
        } 

        struct Sign {
            uint8 v;
            bytes32 r;
            bytes32 s;
            uint256 nonce;
        }

        mapping(tierLevel => mapping(uint => uint)) tierParticipants;
        mapping (address => User) private Users;
        mapping(uint256 => poolDetail) private pools;
        mapping(uint256 => bool) private usedNonce;
        mapping(address => bool) private isWhitelist;
        address[] private whiteList;
        uint256 private whitelistCount;


        event Stake(address user, uint amount);
        event Unstake(address user, uint unstakedAmount);
        event Withdraw(address user, uint withdrawAmount);
        event AddedToWhiteList(address account);
        event RemovedFromWhiteList(address account);
        event PoolUpadted(uint256 pooldetails);
        event FeeUpdated(uint256 fee);
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        event SignerAddressUpdated(address indexed previousSigner, address indexed newSigner);

        constructor (IERC20Metadata _stakingToken){
            stakingToken = _stakingToken;
            owner = msg.sender;
            signer = msg.sender;
            decimals = stakingToken.decimals();

            pools[1] = poolDetail(1, 15, 5 seconds);

            pools[2] = poolDetail(2, 50, 180 seconds);

            pools[3] = poolDetail(3, 100, 360 seconds);

        }


        modifier onlyOwner() {
            require(owner == msg.sender, "Ownable: caller is not the owner");
            _;
        }

        modifier onlySigner() {
            require(signer == msg.sender, "Ownable: caller is not the signer");
            _;
        }

        function transferOwnership(address newOwner) external onlyOwner returns(bool){
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            address oldOwner = owner;
            owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
            return true;
        }

        function setSignerAddress(address newSigner) external onlySigner {
            require(newSigner != address(0), "Ownable: new signer is the zero address");
            address oldSigner = signer;
            signer = newSigner;
            emit SignerAddressUpdated(oldSigner, newSigner);
        }

        function verifySign(address caller, uint256 amount, uint tier, uint256 _stakePool, Sign memory sign) internal view {
            bytes32 hash = keccak256(abi.encodePacked(this, caller, amount, tier, _stakePool, sign.nonce));
            require(signer == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");

        }
        
        function getTotalStaked() external view returns(uint256){
            return totalStaked;
        }
        
        function isWhiteListaddress(address account) external override view returns(bool) {
            return isWhitelist[account];
        }

        function updateTier(uint amount) internal view returns(uint8){

            if(amount >= 1000 * 10 ** decimals  && amount < 3000 * 10 ** decimals){
                return 1;
            }
            else if(amount >= 3000 * 10 ** decimals && amount < 6000 * 10 ** decimals){
                return 2;
            }
            else if(amount >= 6000 * 10 ** decimals && amount < 12000 * 10 ** decimals){
                return 3;
            }
            else if(amount >= 12000 * 10 ** decimals && amount < 25000 * 10 ** decimals){
                return 4;
            }
            else if(amount >= 25000 * 10 ** decimals && amount < 60000 * 10 ** decimals ){
                return 5;
            }
            else if(amount >= 60000 * 10 ** decimals) {
                return 6;
            }
            else {
                return 0;
            }
        }

        function stake(uint256 amount, uint256 _stakePool, Sign memory sign) external returns(bool) {
            require(_stakePool > 0 && _stakePool <= 3, "Pool value must be greater than zero or less than three");
            require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
            usedNonce[sign.nonce] = true;
            if(amount == 0) {
                require(Users[msg.sender].isStaker, "staking not enabled");
                amount = getRewards(msg.sender);
                require(amount > 0, "amount must be greater than zero");
                verifySign(msg.sender, amount, uint256(tierLevel(Users[msg.sender].tierId)), _stakePool, sign);
                uint256 tier = updateTier(amount);
                if(tierLevel(tier) != Users[msg.sender].tierId) {
                    Users[msg.sender].tierId = tierLevel(tier);
                    tierParticipants[tierLevel(Users[msg.sender].tierId)][Users[msg.sender].poolLevel] += 1;
                }
                Users[msg.sender].stakeAmount += amount;
                _stake(amount);
                return true;
            }
            if(amount > 0) {
                require(amount >= 1000 * 10 ** decimals, "amount must be greater than or equal to minimum value");
                uint256 tier = updateTier(amount);
                verifySign(msg.sender, amount, tier, _stakePool, sign);
                Users[msg.sender].tierId = tierLevel(tier);
                if(Users[msg.sender].poolLevel !=0) {
                    require(Users[msg.sender].isStaker, "staking not enabled");
                    Users[msg.sender].isStaker = true;
                    Users[msg.sender].stakeAmount += amount;
                    tierParticipants[tierLevel(Users[msg.sender].tierId)][Users[msg.sender].poolLevel] += 1;
                    _stake(amount);
                    return true;
                }
                Users[msg.sender].poolLevel = _stakePool;
                Users[msg.sender].isStaker = true;
                Users[msg.sender].stakeAmount += amount;
                Users[msg.sender].intialStakingTime = block.timestamp;
                tierParticipants[tierLevel(Users[msg.sender].tierId)][_stakePool] += 1;
                _stake(amount);
                return true;
            }
            return true;
        }
        
        function _stake(uint256 amount) internal {
            updateReward();
            totalStaked += amount;
            stakingToken.transferFrom(msg.sender, address(this), amount);
            emit Stake(msg.sender,amount);
        }

        function unStake(uint256 amount, Sign memory sign) external {
            verifySign(msg.sender, amount, uint(Users[msg.sender].tierId), Users[msg.sender].poolLevel, sign);
            updateReward();
            require(!Users[msg.sender].isUnstakeInitiated, "you have already initiated unstake");

            if(Users[msg.sender].poolLevel == 1) {
                Users[msg.sender].unstakeLimit = block.timestamp + pools[1].poolLimit;
            }
            else if(Users[msg.sender].poolLevel == 2) {
                require(block.timestamp >= Users[msg.sender].intialStakingTime + pools[2].poolLimit, "staking timeLimit is not reached");
            }
            else if(Users[msg.sender].poolLevel == 3) {
                require(block.timestamp >= Users[msg.sender].intialStakingTime + pools[3].poolLimit, "staking timeLimit is not reached");
            }
        
            Users[msg.sender].unstakeAmount += amount;
            Users[msg.sender].stakeAmount -= amount;
            uint256 currentTier = uint256(Users[msg.sender].tierId);
            Users[msg.sender].tierId = tierLevel(updateTier(Users[msg.sender].stakeAmount));
            updateParticipants(currentTier);

            Users[msg.sender].isStaker = Users[msg.sender].stakeAmount != 0 ? true : false;
            Users[msg.sender].intialStakingTime = Users[msg.sender].stakeAmount != 0 ? block.timestamp : 0;
            Users[msg.sender].isUnstakeInitiated = true;
            totalStaked -= amount;
            Users[msg.sender].unstakeInitiatedTime = block.timestamp;
            Users[msg.sender].poolLevel = Users[msg.sender].stakeAmount != 0 ? Users[msg.sender].poolLevel : 0;
            emit Unstake(msg.sender, amount);
        }

        function updateParticipants(uint256 tierId) internal {
            if(Users[msg.sender].tierId != tierLevel(tierId)) {
                tierParticipants[tierLevel(tierId)][Users[msg.sender].poolLevel] -= 1;
                tierParticipants[Users[msg.sender].tierId][Users[msg.sender].poolLevel] += 1;
            }
        }

        function withdraw(Sign calldata sign) external {
            require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
            usedNonce[sign.nonce] = true;
            verifySign(msg.sender, Users[msg.sender].unstakeAmount, uint256(tierLevel(Users[msg.sender].tierId)), Users[msg.sender].poolLevel, sign);
            require(Users[msg.sender].isUnstakeInitiated, "you should be initiate unstake first");
            require(block.timestamp >= Users[msg.sender].unstakeLimit, "can't withdraw before unstake listed seconds");
            uint _unstakeAmount = Users[msg.sender].unstakeAmount;
            uint _rewardAmount = Users[msg.sender].rewards;
            uint amount = _unstakeAmount + _rewardAmount;
            stakingToken.transfer(msg.sender, amount);
            Users[msg.sender].isUnstakeInitiated = false;
            Users[msg.sender].unstakeLimit = 0;
            Users[msg.sender].unstakeAmount -= _unstakeAmount;
            Users[msg.sender].withdrawStakedAmount += _unstakeAmount;
            Users[msg.sender].withdrawRewardAmount += _rewardAmount;
            Users[msg.sender].rewards = 0;
            emit Withdraw(msg.sender, _unstakeAmount);
        }

        function emergencyWithdraw(Sign calldata sign) external {
            require(Users[msg.sender].isStaker, "Withdraw: account must be stake some amount");
            require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
            usedNonce[sign.nonce] = true;           
            verifySign(msg.sender, Users[msg.sender].stakeAmount, uint256(tierLevel(Users[msg.sender].tierId)), Users[msg.sender].poolLevel, sign);
            uint amount = Users[msg.sender].stakeAmount;
            if(Users[msg.sender].poolLevel > 1) {
                uint256 txFee = amount * fee / 100;
                amount = amount - txFee;
            }
            tierParticipants[tierLevel(Users[msg.sender].tierId)][Users[msg.sender].poolLevel] -= 1;
            stakingToken.transfer(msg.sender,amount);
            Users[msg.sender].withdrawStakedAmount += amount;
            Users[msg.sender].isStaker = false;
            Users[msg.sender].stakeAmount = 0;
            emit Withdraw(msg.sender, amount);
        }

        function getDetails(address sender) external view returns(User memory) {
            return Users[sender];
        }

        function getStakedAmount(address sender) external override view returns(uint){
            return Users[sender].stakeAmount;
        }
             

        function getRewards(address account) public view returns(uint256) {
            if(Users[account].isStaker) {
                uint256 stakeAmount = Users[account].stakeAmount;
                uint256 timeDiff;
                require(block.timestamp >= Users[account].intialStakingTime, "Time exceeds");
                unchecked {
                    timeDiff = block.timestamp - Users[account].intialStakingTime;
                }
                uint256 rewardRate = pools[Users[account].poolLevel].poolRewardPercent;
                uint256 rewardAmount = ((stakeAmount * rewardRate ) * timeDiff / 365 seconds) / 100 ;
                return rewardAmount;
            }
            else return 0;
        }

        function getTotalParticipants() external override view returns(uint256){
            uint256 total;
            for(uint i = 1; i <= 6; i++){
                for(uint j = 1; j <= 3; j++) {
                    total += tierParticipants[tierLevel(i)][j];
                }
            }
            return total;
        }
        
        function getParticipantsByTierId(uint256 tierId, uint256 poolLevel) external override view returns(uint256){
            return tierParticipants[tierLevel(tierId)][poolLevel];
        }

        function isAllocationEligible(uint participationEndTime) external override view returns(bool){
            if(Users[msg.sender].intialStakingTime <= participationEndTime){
                return true;
            }
            return false;
        }

        function getTierIdFromUser(address account) external override view returns(uint tierId, uint poolLevel){
            return (uint(Users[account].tierId), Users[account].poolLevel);
        }

        function addToWhiteList(address account) external onlyOwner returns(bool) {
            require(account != address(0), "WhiteList: addrss shouldn't be zero");
            require(!isWhitelist[account], "WhileList: account already whiteListed");
            whiteList.push(account);
            isWhitelist[account] = true;
            whitelistCount += 1;
            emit AddedToWhiteList(account);
            return true;
        }
        
        function removeFromWhiteList(address account) external onlyOwner returns(bool) {
            require(account != address(0), "WhiteList: addrss shouldn't be zero");
            require(isWhitelist[account], "WhileList: account already removed from whiteList");
            isWhitelist[account] = false;
            whitelistCount -= 1; 
            emit RemovedFromWhiteList(account);
            return true;
        }

        function getWhiteList() external view returns(address[] memory) {
            address[] memory accounts = new address[] (whitelistCount);
            for(uint256 i = 0; i < whiteList.length; i++) {
            if(isWhitelist[whiteList[i]]) {
                accounts[i] = whiteList[i];
            }
        }
        return accounts;
        }

        function isStaker(address user) external override view returns(bool){
            return Users[user].isStaker;
        }

        function updateReward() internal returns(bool) {
            uint256 stakeAmount = Users[msg.sender].stakeAmount;
            uint256 timeDiff;
            require(block.timestamp >= Users[msg.sender].intialStakingTime, "Time exceeds");
            unchecked {
                timeDiff = block.timestamp - Users[msg.sender].intialStakingTime;
            }
            uint256 rewardRate = pools[Users[msg.sender].poolLevel].poolRewardPercent;
            Users[msg.sender].rewards = ((stakeAmount * rewardRate) * timeDiff / 3600 seconds) / 100;
            return true;
        }

        function setPoolLimit(uint256 poolLevel, uint256 limit) external onlyOwner returns(bool) {
            pools[poolLevel].poolLimit = limit * 30 seconds;
            emit PoolUpadted(pools[poolLevel].poolLimit);
            return true;
        }

        function setPoolPercentage(uint256 poolLevel, uint256 percentage) external onlyOwner returns(bool) {
            pools[poolLevel].poolRewardPercent = percentage;
            emit PoolUpadted(pools[poolLevel].poolRewardPercent);
            return true;
        }

        function setFeeForEmergencyWithdraw(uint256 _fee) external onlyOwner returns(bool) {
            fee = _fee;
            emit FeeUpdated(fee);
            return true;
        }


    }