// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface ISpartaStaking {
    error TransferFailed();
    error RewardBalanceTooSmall();
    error BeforeStakingStart();
    error AfterStakingFinish();
    error AmountZero();
    error TokensAlreadyClaimed();
    error RoundDoesNotExist();
    error BeforeReleaseTime();

    struct TokensToClaim {
        bool taken;
        uint256 release;
        uint256 value;
    }

    event Staked(address indexed wallet, uint256 value);
    event Unstaked(
        address indexed wallet,
        uint256 tokensAmount,
        uint256 tokensToClaim,
        uint256 duration
    );
    event TokensClaimed(
        address indexed wallet,
        uint256 indexed roundId,
        uint256 tokensToClaimid
    );
    event RewardTaken(address indexed wallet, uint256 amount);

    event Initialized(uint256 start, uint256 duration, uint256 reward);

    function finishAt() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IStakedSparta.sol";
import "./interfaces/ISpartaStaking.sol";
import "../ToInitialize.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpartaStaking is ISpartaStaking, ToInitialize, Ownable {
    IERC20 public immutable sparta;
    IStakedSparta public immutable stakedSparta;
    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public start;
    uint256 public updatedAt;
    uint256 public duration;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userTokensToClaimCounter;
    mapping(address => mapping(uint256 => TokensToClaim))
        public userTokensToClaim;

    constructor(IERC20 sparta_, IStakedSparta stakedSparta_) {
        sparta = sparta_;
        stakedSparta = stakedSparta_;
        _transferOwnership(msg.sender);
    }

    function stake(uint256 _amount) external {
        stakeAs(msg.sender, _amount);
    }

    function initialize(
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    ) external notInitialized onlyOwner updateReward(address(0)) {
        if (sparta.balanceOf(address(this)) < _amount) {
            revert RewardBalanceTooSmall();
        }

        duration = _duration;
        start = _start;
        rewardRate = _amount / duration;

        updatedAt = block.timestamp;

        initialized = true;

        emit Initialized(_start, _duration, _amount);
    }

    function finishAt() public view override returns (uint256) {
        return start + duration;
    }

    function stakeAs(
        address wallet,
        uint256 amount
    ) public isInitialized isOngoing updateReward(wallet) {
        if (amount == 0) {
            revert AmountZero();
        }
        if (!sparta.transferFrom(wallet, address(this), amount)) {
            revert TransferFailed();
        }

        balanceOf[wallet] += amount;
        totalSupply += amount;
        stakedSparta.mintTo(wallet, amount);

        emit Staked(wallet, amount);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0 || block.timestamp < start) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt(), block.timestamp);
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function unstake(
        uint256 _amount,
        uint256 _after
    ) public isInitialized updateReward(msg.sender) {
        if (_amount == 0) {
            revert AmountZero();
        }
        uint256 round = userTokensToClaimCounter[msg.sender];
        uint256 tokensToWidthdraw = calculateWithFee(_amount, _after);
        uint256 releaseTime = _after + block.timestamp;

        userTokensToClaim[msg.sender][round] = TokensToClaim(
            false,
            releaseTime,
            tokensToWidthdraw
        );
        stakedSparta.burnFrom(msg.sender, _amount);
        ++userTokensToClaimCounter[msg.sender];
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Unstaked(msg.sender, _amount, tokensToWidthdraw, releaseTime);
    }

    function calculateWithFee(
        uint256 input,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 saturatedDuration = _duration > 100 days ? 100 days : _duration;
        uint256 feesNominator = ((100 days - saturatedDuration) * 500) / 1 days;
        uint256 feesOnAmount = (input * feesNominator) / 100000;
        return input - feesOnAmount;
    }

    function getReward() public isInitialized updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) {
            revert AmountZero();
        }
        if (!sparta.transfer(msg.sender, reward)) {
            revert TransferFailed();
        }
        rewards[msg.sender] = 0;

        emit RewardTaken(msg.sender, reward);
    }

    function weiRewardRatioPerTokenStored() external view returns (uint256) {
        return totalSupply == 0 ? 0 : rewardRate / totalSupply;
    }

    function toEnd() external view returns (uint256) {
        return block.timestamp >= finishAt() ? 0 : finishAt() - block.timestamp;
    }

    function withdrawTokensToClaim(uint256 round) public {
        TokensToClaim storage tokensToClaim = userTokensToClaim[msg.sender][
            round
        ];
        if (tokensToClaim.release == 0) {
            revert RoundDoesNotExist();
        }
        if (block.timestamp < tokensToClaim.release) {
            revert BeforeReleaseTime();
        }
        if (tokensToClaim.taken) {
            revert TokensAlreadyClaimed();
        }
        if (!sparta.transfer(msg.sender, tokensToClaim.value)) {
            revert TransferFailed();
        }

        tokensToClaim.taken = true;

        emit TokensClaimed(msg.sender, tokensToClaim.value, round);
    }

    function withdrawTokensToClaimFromRounds(uint256[] memory rounds) external {
        uint256 roundsLength = 0;
        for (uint roundIndex = 0; roundIndex < roundsLength; ++roundIndex) {
            withdrawTokensToClaim(rounds[roundIndex]);
        }
    }

    function totalPendingToClaim(address wallet) public view returns (uint256) {
        uint256 toClaim = 0;
        uint256 rounds = userTokensToClaimCounter[wallet];
        for (uint256 roundIndex = 0; roundIndex < rounds; ++roundIndex) {
            TokensToClaim memory tokensToClaim = userTokensToClaim[wallet][
                roundIndex
            ];
            if (!tokensToClaim.taken) {
                toClaim += tokensToClaim.value;
            }
        }
        return toClaim;
    }

    function totalLocked(address wallet) external view returns (uint256) {
        return totalPendingToClaim(wallet) + earned(wallet) + balanceOf[wallet];
    }

    function getUserAllocations(
        address _wallet
    ) external view returns (TokensToClaim[] memory) {
        uint256 counter = userTokensToClaimCounter[_wallet];
        TokensToClaim[] memory toClaims = new TokensToClaim[](counter);

        for (uint256 i = 0; i < counter; ++i) {
            toClaims[i] = userTokensToClaim[_wallet][i];
        }

        return toClaims;
    }

    modifier isOngoing() {
        if (block.timestamp < start) {
            revert BeforeStakingStart();
        }
        if (finishAt() < block.timestamp) {
            revert AfterStakingFinish();
        }
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

contract ToInitialize {
    error AlreadyInitialized();
    error NotInitialized();

    bool internal initialized = false;

    modifier isInitialized() {
        _isInitialized();
        _;
    }

    function _isInitialized() internal view {
        if (!initialized) {
            revert NotInitialized();
        }
    }

    modifier notInitialized() {
        if (initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedSparta is IERC20 {
    function mintTo(address to, uint256 amount) external;

    function burnFrom(address wallet, uint256 amount) external;
}