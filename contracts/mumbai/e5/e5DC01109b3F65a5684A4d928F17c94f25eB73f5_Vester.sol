// SPDX-License-Identifier: MIT

import "../games/Rewards/Reward.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../access/Governable.sol";
import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";

pragma solidity ^0.8.0;

contract Vester is IVester, IERC20, ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;
    Reward public reward;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public vestingDuration;

    address public esToken;
    address public pairToken;
    address public claimableToken;

    address public rewardTracker;

    uint256 public override totalSupply;
    uint256 public pairSupply;

    bool public hasMaxVestableAmount;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public pairAmounts;
    mapping (address => uint256) public cumulativeClaimAmounts;
    mapping (address => uint256) public claimedAmounts;
    mapping (address => uint256) public lastVestingTimes;

    mapping (address => uint256) public override transferredAverageStakedAmounts;
    mapping (address => uint256) public override transferredCumulativeRewards;
    mapping (address => uint256) public override cumulativeRewardDeductions;
    mapping (address => uint256) public override bonusRewards;

    mapping (address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);
    event PairTransfer(address indexed from, address indexed to, uint256 value);

    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _pairToken,
        address _claimableToken,
        address _rewardTracker,
        address _reward
    ) {
        name = _name;
        symbol = _symbol;
        vestingDuration = _vestingDuration;
        esToken = _esToken;
        pairToken = _pairToken;
        claimableToken = _claimableToken;
        rewardTracker = _rewardTracker;
        reward = Reward(_reward);

        if (rewardTracker != address(0)) {
            hasMaxVestableAmount = true;
        }
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setHasMaxVestableAmount(bool _hasMaxVestableAmount) external onlyGov {
        hasMaxVestableAmount = _hasMaxVestableAmount;
    }

    function deposit(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function depositForAccount(address _account, uint256 _amount) external nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccount(address _account, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        _claim(account, _receiver);

        uint256 claimedAmount = cumulativeClaimAmounts[account];
        uint256 balance = balances[account];
        uint256 totalVested = balance + (claimedAmount); 
        require(totalVested > 0, "Vester: vested amount is zero");

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[account];
            _burnPair(account, pairAmount);
            IERC20(pairToken).safeTransfer(_receiver, pairAmount);
        }

        _burn(account, balance);

        delete cumulativeClaimAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingTimes[account];

        emit Withdraw(account, claimedAmount, balance);
    }

    function transferStakeValues(address _sender, address _receiver) external override nonReentrant {
        _validateHandler();

        transferredAverageStakedAmounts[_receiver] = getCombinedAverageStakedAmount(_sender);
        transferredAverageStakedAmounts[_sender] = 0;

        uint256 transferredCumulativeReward = transferredCumulativeRewards[_sender];
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_sender);

        transferredCumulativeRewards[_receiver] = transferredCumulativeReward + (cumulativeReward);
        cumulativeRewardDeductions[_sender] = cumulativeReward;
        transferredCumulativeRewards[_sender] = 0;

        bonusRewards[_receiver] = bonusRewards[_sender];
        bonusRewards[_sender] = 0;
    }

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        transferredAverageStakedAmounts[_account] = _amount;
    }

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        transferredCumulativeRewards[_account] = _amount;
    }

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        cumulativeRewardDeductions[_account] = _amount;
    }

    function setBonusRewards(address _account, uint256 _amount) external override nonReentrant {
        _validateHandler();
        bonusRewards[_account] = _amount;
    }

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account] - (claimedAmounts[_account]);
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return amount + (nextClaimable);
    }

    function getMaxVestableAmount(address _account) public override view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 transferredCumulativeReward = transferredCumulativeRewards[_account];
        uint256 bonusReward = bonusRewards[_account];
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        uint256 maxVestableAmount = cumulativeReward + (transferredCumulativeReward) + (bonusReward);

        uint256 cumulativeRewardDeduction = cumulativeRewardDeductions[_account];

        if (maxVestableAmount < cumulativeRewardDeduction) {
            return 0;
        }

        return maxVestableAmount - (cumulativeRewardDeduction);
    }

    function getCombinedAverageStakedAmount(address _account) public override view returns (uint256) {
        uint256 cumulativeReward = IRewardTracker(rewardTracker).cumulativeRewards(_account);
        uint256 transferredCumulativeReward = transferredCumulativeRewards[_account];
        uint256 totalCumulativeReward = cumulativeReward + (transferredCumulativeReward);
        if (totalCumulativeReward == 0) { return 0; }

        uint256 averageStakedAmount = IRewardTracker(rewardTracker).averageStakedAmounts(_account);
        uint256 transferredAverageStakedAmount = transferredAverageStakedAmounts[_account];

        return averageStakedAmount
            *(cumulativeReward)
            /(totalCumulativeReward)
            +(
                transferredAverageStakedAmount * (transferredCumulativeReward) / (totalCumulativeReward)
            );
    }

    function getPairAmount(address _account, uint256 _esAmount) public view returns (uint256) {
        if (!hasRewardTracker()) { return 0; }

        uint256 combinedAverageStakedAmount = getCombinedAverageStakedAmount(_account);
        if (combinedAverageStakedAmount == 0) {
            return 0;
        }

        uint256 maxVestableAmount = getMaxVestableAmount(_account);
        if (maxVestableAmount == 0) {
            return 0;
        }

        return _esAmount*(combinedAverageStakedAmount)/(maxVestableAmount);
    }

    function hasRewardTracker() public view returns (bool) {
        return rewardTracker != address(0);
    }

    function hasPairToken() public view returns (bool) {
        return pairToken != address(0);
    }

    function getTotalVested(address _account) public view returns (uint256) {
        return balances[_account]+(cumulativeClaimAmounts[_account]);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    // empty implementation, tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override pure returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    function getVestedAmount(address _account) public view returns (uint256) {
        uint256 balance = balances[_account];
        uint256 cumulativeClaimAmount = cumulativeClaimAmounts[_account];
        return balance+(cumulativeClaimAmount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply + (_amount);
        balances[_account] = balances[_account] + (_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _mintPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        pairSupply = pairSupply + (_amount);
        pairAmounts[_account] = pairAmounts[_account] + (_amount);

        emit PairTransfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account] - (_amount);
        totalSupply = totalSupply -  (_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _burnPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        pairAmounts[_account] = pairAmounts[_account] - (_amount);
        pairSupply = pairSupply -  (_amount);

        emit PairTransfer(_account, address(0), _amount);
    }

    function _deposit(address _account, uint256 _amount) private {
        require(_amount > 0, "Vester: invalid _amount");
        require(uint(reward.rewards(msg.sender)) >= _amount, "You do not have enough funds to deposit");
        reward.decreaseRewardBalance(msg.sender, int(_amount));

        _updateVesting(_account);

        _mint(_account, _amount);

        if (hasPairToken()) {
            uint256 pairAmount = pairAmounts[_account];
            uint256 nextPairAmount = getPairAmount(_account, balances[_account]);
            if (nextPairAmount > pairAmount) {
                uint256 pairAmountDiff = nextPairAmount -  (pairAmount);
                IERC20(pairToken).safeTransferFrom(_account, address(this), pairAmountDiff);
                _mintPair(_account, pairAmountDiff);
            }
        }

        if (hasMaxVestableAmount) {
            uint256 maxAmount = getMaxVestableAmount(_account);
            require(getTotalVested(_account) <= maxAmount, "Vester: max vestable amount exceeded");
        }

        emit Deposit(_account, _amount);
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);

        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account] + (amount);
    }

    function _getNextClaimableAmount(address _account) private view returns (uint256) {
        uint256 timeDiff = block.timestamp -  (lastVestingTimes[_account]);

        uint256 balance = balances[_account];
        if (balance == 0) { return 0; }

        uint256 vestedAmount = getVestedAmount(_account);
        uint256 claimableAmount = vestedAmount * (timeDiff) / (vestingDuration);

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account] + (amount);
        IERC20(claimableToken).safeTransfer(_receiver, amount);
        emit Claim(_account, amount);
        return amount;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/Governable.sol";

contract Reward is Governable {

    address vester;

    mapping(address => int) public rewards;
    mapping(address => bool) public caller;

    event RewardUpdated(address caller, address recipient, int reward);
    event RewardDeducted(address caller, address recipient, int reward);

    modifier authorisedOnly() {
      require(caller[msg.sender], "Not Authorised");
      _;
    }

    modifier onlyVester() {
        require(msg.sender == vester, "Only vesting contract can call");
        _;
    }

    function setCaller(address contractAddr) external onlyAdmin {
      caller[contractAddr] = true;
    }

    function setVesterAddr(address vesterAddr) external onlyAdmin {
        vester = vesterAddr;
    }

    function updateReward(address recipient, int amount) external authorisedOnly {
        rewards[recipient] += amount;

    emit RewardUpdated(msg.sender, recipient, amount);
    }

    function decreaseRewardBalance(address recipient, int amount) external onlyVester {
        require(msg.sender == vester, "Not Authorised");
        rewards[recipient] -= amount;
        emit RewardDeducted(msg.sender, recipient, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,          
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {

    address public gov;
    mapping (address => bool) public admins;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Only Gov can call");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only Admin can call");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external onlyGov {
        admins[_account] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVester {
    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}