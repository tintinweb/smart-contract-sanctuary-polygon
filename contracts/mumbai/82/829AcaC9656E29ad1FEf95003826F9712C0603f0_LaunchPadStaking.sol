// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakeable {
    function getStakedAmount(address user) external view returns (uint);

    function isStaker(address user) external view returns (bool);

    function getTotalParticipants() external view returns (uint256);

    function getParticipantsByTierId(
        uint256 tierId,
        uint256 poolLevel
    ) external view returns (uint256);

    function isAllocationEligible(
        uint participationEndTime
    ) external view returns (bool);

    function getTierIdFromUser(
        address sender
    ) external view returns (uint, uint);

    function isWhiteListaddress(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IStakable.sol";

contract LaunchPadStaking is IStakeable, Ownable {
    IERC20Metadata public stakingToken;
    address public signer;
    uint256 public totalStaked;
    uint8 public decimals;

    enum tierLevel {
        Null,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM,
        EMERALD,
        DIAMOND
    }

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
    mapping(address => User) private Users;
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
    event SignerAddressUpdated(
        address indexed previousSigner,
        address indexed newSigner
    );

    constructor(address _stakingToken) {
        stakingToken = IERC20Metadata(_stakingToken);
        signer = msg.sender;
        decimals = stakingToken.decimals();

        pools[1] = poolDetail(1, 15, 5 seconds);

        pools[2] = poolDetail(2, 50, 180 seconds);

        pools[3] = poolDetail(3, 100, 360 seconds);
    }

    modifier onlySigner() {
        require(signer == msg.sender, "Ownable: caller is not the signer");
        _;
    }

    function setSignerAddress(address newSigner) external onlySigner {
        require(
            newSigner != address(0),
            "Ownable: new signer is the zero address"
        );
        address oldSigner = signer;
        signer = newSigner;
        emit SignerAddressUpdated(oldSigner, newSigner);
    }

    function verifySign(
        address caller,
        uint256 amount,
        uint tier,
        uint256 _stakePool,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(this, caller, amount, tier, _stakePool, sign.nonce)
        );
        require(
            signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function isWhiteListaddress(
        address account
    ) external view override returns (bool) {
        return isWhitelist[account];
    }

    function updateTier(uint amount) internal view returns (uint8) {
        if (amount >= 1000 * 10 ** decimals && amount < 3000 * 10 ** decimals) {
            return 1;
        } else if (
            amount >= 3000 * 10 ** decimals && amount < 6000 * 10 ** decimals
        ) {
            return 2;
        } else if (
            amount >= 6000 * 10 ** decimals && amount < 12000 * 10 ** decimals
        ) {
            return 3;
        } else if (
            amount >= 12000 * 10 ** decimals && amount < 25000 * 10 ** decimals
        ) {
            return 4;
        } else if (
            amount >= 25000 * 10 ** decimals && amount < 60000 * 10 ** decimals
        ) {
            return 5;
        } else if (amount >= 60000 * 10 ** decimals) {
            return 6;
        } else {
            return 0;
        }
    }

    function stake(
        uint256 amount,
        uint256 _stakePool,
        Sign memory sign
    ) external returns (bool) {
        require(
            _stakePool > 0 && _stakePool <= 3,
            "Pool value must be greater than zero or less than three"
        );
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        if (amount == 0) {
            require(Users[msg.sender].isStaker, "staking not enabled");
            verifySign(
                msg.sender,
                amount,
                uint256(tierLevel(Users[msg.sender].tierId)),
                _stakePool,
                sign
            );
            amount = getRewards(msg.sender);
            require(amount > 0, "amount must be greater than zero");
            uint256 tier = updateTier(amount);
            if (tierLevel(tier) != Users[msg.sender].tierId) {
                Users[msg.sender].tierId = tierLevel(tier);
                tierParticipants[tierLevel(Users[msg.sender].tierId)][
                    Users[msg.sender].poolLevel
                ] += 1;
            }
            Users[msg.sender].stakeAmount += amount;
            Users[msg.sender].rewards = 0;
            return true;
        }
        if (amount > 0) {
            require(
                amount >= 1000 * 10 ** decimals,
                "amount must be greater than or equal to minimum value"
            );
            uint256 tier = updateTier(amount);
            verifySign(msg.sender, amount, tier, _stakePool, sign);
            Users[msg.sender].tierId = tierLevel(tier);
            if (Users[msg.sender].poolLevel != 0) {
                require(Users[msg.sender].isStaker, "staking not enabled");
                Users[msg.sender].isStaker = true;
                Users[msg.sender].stakeAmount += amount;
                tierParticipants[tierLevel(Users[msg.sender].tierId)][
                    Users[msg.sender].poolLevel
                ] += 1;
                _stake(amount);
                return true;
            }
            Users[msg.sender].poolLevel = _stakePool;
            Users[msg.sender].isStaker = true;
            Users[msg.sender].stakeAmount += amount;
            Users[msg.sender].intialStakingTime = block.timestamp;
            tierParticipants[tierLevel(Users[msg.sender].tierId)][
                _stakePool
            ] += 1;
            _stake(amount);
            return true;
        }
        return true;
    }

    function _stake(uint256 amount) internal {
        updateReward();
        totalStaked += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender, amount);
    }

    function unStake(uint256 amount, Sign memory sign) external {
        verifySign(
            msg.sender,
            amount,
            uint(Users[msg.sender].tierId),
            Users[msg.sender].poolLevel,
            sign
        );
        updateReward();
        require(
            !Users[msg.sender].isUnstakeInitiated,
            "you have already initiated unstake"
        );

        if (Users[msg.sender].poolLevel == 1) {
            Users[msg.sender].unstakeLimit =
                block.timestamp +
                pools[1].poolLimit;
        } else if (Users[msg.sender].poolLevel == 2) {
            require(
                block.timestamp >=
                    Users[msg.sender].intialStakingTime + pools[2].poolLimit,
                "staking timeLimit is not reached"
            );
        } else if (Users[msg.sender].poolLevel == 3) {
            require(
                block.timestamp >=
                    Users[msg.sender].intialStakingTime + pools[3].poolLimit,
                "staking timeLimit is not reached"
            );
        }

        Users[msg.sender].unstakeAmount += amount;
        Users[msg.sender].stakeAmount -= amount;
        uint256 currentTier = uint256(Users[msg.sender].tierId);
        Users[msg.sender].tierId = tierLevel(
            updateTier(Users[msg.sender].stakeAmount)
        );
        updateParticipants(currentTier);

        Users[msg.sender].isStaker = Users[msg.sender].stakeAmount != 0
            ? true
            : false;
        Users[msg.sender].intialStakingTime = Users[msg.sender].stakeAmount != 0
            ? block.timestamp
            : 0;
        Users[msg.sender].isUnstakeInitiated = true;
        totalStaked -= amount;
        Users[msg.sender].unstakeInitiatedTime = block.timestamp;
        Users[msg.sender].poolLevel = Users[msg.sender].stakeAmount != 0
            ? Users[msg.sender].poolLevel
            : 0;
        emit Unstake(msg.sender, amount);
    }

    function updateParticipants(uint256 tierId) internal {
        if (Users[msg.sender].tierId != tierLevel(tierId)) {
            tierParticipants[tierLevel(tierId)][
                Users[msg.sender].poolLevel
            ] -= 1;
            tierParticipants[Users[msg.sender].tierId][
                Users[msg.sender].poolLevel
            ] += 1;
        }
    }

    function withdraw(Sign calldata sign) external {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(
            msg.sender,
            Users[msg.sender].unstakeAmount,
            uint256(tierLevel(Users[msg.sender].tierId)),
            Users[msg.sender].poolLevel,
            sign
        );
        require(
            Users[msg.sender].isUnstakeInitiated,
            "you should be initiate unstake first"
        );
        require(
            block.timestamp >= Users[msg.sender].unstakeLimit,
            "can't withdraw before unstake listed seconds"
        );
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
        require(
            Users[msg.sender].isStaker,
            "Withdraw: account must be stake some amount"
        );
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(
            msg.sender,
            Users[msg.sender].stakeAmount,
            uint256(tierLevel(Users[msg.sender].tierId)),
            Users[msg.sender].poolLevel,
            sign
        );
        uint amount = Users[msg.sender].stakeAmount;
        if (Users[msg.sender].poolLevel > 1) {
            uint256 txFee = (amount * fee) / 100;
            amount = amount - txFee;
        }
        tierParticipants[tierLevel(Users[msg.sender].tierId)][
            Users[msg.sender].poolLevel
        ] -= 1;
        stakingToken.transfer(msg.sender, amount);
        Users[msg.sender].withdrawStakedAmount += amount;
        Users[msg.sender].isStaker = false;
        Users[msg.sender].stakeAmount = 0;
        emit Withdraw(msg.sender, amount);
    }

    function getDetails(address sender) external view returns (User memory) {
        return Users[sender];
    }

    function getStakedAmount(
        address sender
    ) external view override returns (uint) {
        return Users[sender].stakeAmount;
    }

    function getRewards(address account) public view returns (uint256) {
        if (Users[account].isStaker) {
            uint256 stakeAmount = Users[account].stakeAmount;
            uint256 timeDiff;
            require(
                block.timestamp >= Users[account].intialStakingTime,
                "Time exceeds"
            );
            unchecked {
                timeDiff = block.timestamp - Users[account].intialStakingTime;
            }
            uint256 rewardRate = pools[Users[account].poolLevel]
                .poolRewardPercent;
            uint256 rewardAmount = (((stakeAmount * rewardRate) * timeDiff) /
                365 seconds) / 100;
            return rewardAmount;
        } else return 0;
    }

    function getTotalParticipants() external view override returns (uint256) {
        uint256 total;
        for (uint i = 1; i <= 6; i++) {
            for (uint j = 1; j <= 3; j++) {
                total += tierParticipants[tierLevel(i)][j];
            }
        }
        return total;
    }

    function getParticipantsByTierId(
        uint256 tierId,
        uint256 poolLevel
    ) external view override returns (uint256) {
        return tierParticipants[tierLevel(tierId)][poolLevel];
    }

    function isAllocationEligible(
        uint participationEndTime
    ) external view override returns (bool) {
        if (Users[msg.sender].intialStakingTime <= participationEndTime) {
            return true;
        }
        return false;
    }

    function getTierIdFromUser(
        address account
    ) external view override returns (uint tierId, uint poolLevel) {
        return (uint(Users[account].tierId), Users[account].poolLevel);
    }

    function addToWhiteList(address account) external onlyOwner returns (bool) {
        require(account != address(0), "WhiteList: addrss shouldn't be zero");
        require(
            !isWhitelist[account],
            "WhileList: account already whiteListed"
        );
        whiteList.push(account);
        isWhitelist[account] = true;
        whitelistCount += 1;
        emit AddedToWhiteList(account);
        return true;
    }

    function removeFromWhiteList(
        address account
    ) external onlyOwner returns (bool) {
        require(account != address(0), "WhiteList: addrss shouldn't be zero");
        require(
            isWhitelist[account],
            "WhileList: account already removed from whiteList"
        );
        isWhitelist[account] = false;
        whitelistCount -= 1;
        emit RemovedFromWhiteList(account);
        return true;
    }

    function getWhiteList() external view returns (address[] memory) {
        address[] memory accounts = new address[](whitelistCount);
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (isWhitelist[whiteList[i]]) {
                accounts[i] = whiteList[i];
            }
        }
        return accounts;
    }

    function isStaker(address user) external view override returns (bool) {
        return Users[user].isStaker;
    }

    function updateReward() internal returns (bool) {
        uint256 stakeAmount = Users[msg.sender].stakeAmount;
        uint256 timeDiff;
        require(
            block.timestamp >= Users[msg.sender].intialStakingTime,
            "Time exceeds"
        );
        unchecked {
            timeDiff = block.timestamp - Users[msg.sender].intialStakingTime;
        }
        uint256 rewardRate = pools[Users[msg.sender].poolLevel]
            .poolRewardPercent;
        Users[msg.sender].rewards =
            (((stakeAmount * rewardRate) * timeDiff) / 3600 seconds) /
            100;
        return true;
    }

    function setPoolLimit(
        uint256 poolLevel,
        uint256 limit
    ) external onlyOwner returns (bool) {
        pools[poolLevel].poolLimit = limit * 30 seconds;
        emit PoolUpadted(pools[poolLevel].poolLimit);
        return true;
    }

    function setPoolPercentage(
        uint256 poolLevel,
        uint256 percentage
    ) external onlyOwner returns (bool) {
        pools[poolLevel].poolRewardPercent = percentage;
        emit PoolUpadted(pools[poolLevel].poolRewardPercent);
        return true;
    }

    function setFeeForEmergencyWithdraw(
        uint256 _fee
    ) external onlyOwner returns (bool) {
        fee = _fee;
        emit FeeUpdated(fee);
        return true;
    }
}