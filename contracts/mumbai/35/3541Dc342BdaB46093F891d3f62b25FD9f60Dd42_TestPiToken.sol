// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PiAdmin.sol";
import "../interfaces/IPiToken.sol";
import "../interfaces/IController.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IWNative.sol";

contract Archimedes is PiAdmin, ReentrancyGuard {
    // using Address for address;
    using SafeERC20 for IERC20;

    // Used for native token deposits/withdraws
    IWNative public immutable WNative;

    // Info of each pool.
    struct PoolInfo {
        IERC20 want;             // Address of token contract.
        uint weighing;           // How much weighing assigned to this pool. PIes to distribute per block.
        uint lastRewardBlock;    // Last block number that PIes distribution occurs.
        uint accPiTokenPerShare; // Accumulated PIes per share, times SHARE_PRECISION. See below.
        address controller;      // Token controller
    }

    // IPiToken already have safe transfer from SuperToken
    IPiToken public immutable piToken;

    // Used to made multiplications and divitions over shares
    uint public constant SHARE_PRECISION = 1e18;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    // Users can't transfer controller's minted tokens
    mapping(uint => mapping(address => uint)) public userPaidRewards;
    // Total weighing. Must be the sum of all pools weighing.
    uint public totalWeighing;
    // The block number when PI mining starts.
    uint public immutable startBlock;

    // PiToken referral contract address.
    IReferral public referralMgr;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 10; // 1%
    // Max referral commission rate: 5%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 50; // 5%
    uint16 public constant COMMISSION_RATE_PRECISION = 1000;

    event Deposit(uint indexed pid, address indexed user, uint amount);
    event Withdraw(uint indexed pid, address indexed user, uint amount);
    event EmergencyWithdraw(uint indexed pid, address indexed user, uint amount);
    event NewPool(uint indexed pid, address want, uint weighing);
    event PoolWeighingUpdated(uint indexed pid, uint oldWeighing, uint newWeighing);
    event Harvested(uint indexed pid, address indexed user, uint amount);

    constructor(IPiToken _piToken, uint _startBlock, IWNative _wNative) {
        require(address(_piToken) != address(0), "Pi address !ZeroAddress");
        require(_startBlock > _blockNumber(), "StartBlock must be in the future");

        piToken = _piToken;
        startBlock = _startBlock;
        WNative = _wNative;
    }

    // Deposit Native
    receive() external payable { }

    modifier onlyController(uint _pid) {
        require(poolInfo[_pid].controller == msg.sender, "!Controller");
        _;
    }

    // Add a new want token to the pool. Can only be called by the owner.
    function addNewPool(IERC20 _want, address _ctroller, uint _weighing, bool _massUpdate) external onlyAdmin {
        require(address(_want) != address(0), "Address zero not allowed");
        require(IController(_ctroller).archimedes() == address(this), "Not an Archimedes controller");
        require(IController(_ctroller).strategy() != address(0), "Controller without strategy");

        // Update pools before a weighing change
        if (_massUpdate) { massUpdatePools(); }

        uint lastRewardBlock = _blockNumber() > startBlock ? _blockNumber() : startBlock;

        totalWeighing += _weighing;

        poolInfo.push(PoolInfo({
            want: _want,
            weighing: _weighing,
            lastRewardBlock: lastRewardBlock,
            accPiTokenPerShare: 0,
            controller: _ctroller
        }));

        uint _pid = poolInfo.length - 1;
        uint _setPid = IController(_ctroller).setPid(_pid);
        require(_pid == _setPid, "Pid doesn't match");

        emit NewPool(_pid, address(_want), _weighing);
    }

    // Update the given pool's rewards weighing .
    function changePoolWeighing(uint _pid, uint _weighing, bool _massUpdate) external onlyAdmin {
        emit PoolWeighingUpdated(_pid, poolInfo[_pid].weighing, _weighing);

        // Update pools before a weighing change
        if (_massUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        totalWeighing = (totalWeighing - poolInfo[_pid].weighing) + _weighing;
        poolInfo[_pid].weighing = _weighing;
    }

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(uint _from, uint _to) internal pure returns (uint) {
        return _to - _from;
    }

    // View function to see pending PIes on frontend.
    function pendingPiToken(uint _pid, address _user) external view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];

        uint accPiTokenPerShare = pool.accPiTokenPerShare;
        uint sharesTotal = _controller(_pid).totalSupply();

        if (_blockNumber() > pool.lastRewardBlock && sharesTotal > 0 && piToken.communityLeftToMint() > 0) {
            uint multiplier = _getMultiplier(pool.lastRewardBlock, _blockNumber());
            uint piTokenReward = (multiplier * piTokenPerBlock() * pool.weighing) / totalWeighing;
            accPiTokenPerShare += (piTokenReward * SHARE_PRECISION) / sharesTotal;
        }
        return ((_userShares(_pid, _user) * accPiTokenPerShare) / SHARE_PRECISION) - paidRewards(_pid, _user);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
            if (_outOfGasForLoop()) { break; }
        }
    }

    // Mint community tokens for a given pool pid
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        // If same block as last update return
        if (_blockNumber() <= pool.lastRewardBlock) { return; }

        // If community Mint is already finished
        uint communityLeftToMint = piToken.communityLeftToMint();
        if (communityLeftToMint <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        uint sharesTotal = _controller(_pid).totalSupply();

        if (sharesTotal <= 0 || pool.weighing <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        uint multiplier = _getMultiplier(pool.lastRewardBlock, _blockNumber());
        uint piTokenReward = (multiplier * piTokenPerBlock() * pool.weighing) / totalWeighing;

        // No rewards =( update lastRewardBlock
        if (piTokenReward <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        // If the reward is greater than the left to mint
        if (piTokenReward > communityLeftToMint) {
            piTokenReward = communityLeftToMint;
        }

        piToken.communityMint(address(this), piTokenReward);

        pool.accPiTokenPerShare += (piTokenReward * SHARE_PRECISION) / sharesTotal;
        pool.lastRewardBlock = _blockNumber();
    }

    // Direct native deposit
    function depositNative(uint _pid, address _referrer) external payable nonReentrant {
        uint _amount = msg.value;
        require(_amount > 0, "Insufficient deposit");
        require(address(poolInfo[_pid].want) == address(WNative), "Only Native token pool");

        // Update pool rewards
        updatePool(_pid);

        // Record referral if it's needed
        _recordReferral(_pid, _referrer);

        // Pay rewards
        _calcPendingAndPayRewards(_pid, msg.sender);

        // With that Archimedes already has the wNative
        WNative.deposit{value: _amount}();

        // Deposit in the controller
        _depositInStrategy(_pid, _amount);
    }

    // Deposit want token to Archimedes for PI allocation.
    function deposit(uint _pid, uint _amount, address _referrer) public nonReentrant {
        require(_amount > 0, "Insufficient deposit");

        // Update pool rewards
        updatePool(_pid);

        // Record referral if it's needed
        _recordReferral(_pid, _referrer);

        // Pay rewards
        _calcPendingAndPayRewards(_pid, msg.sender);

        // Transfer from user => Archimedes
        poolInfo[_pid].want.safeTransferFrom(msg.sender, address(this), _amount);

        // Deposit in the controller
        _depositInStrategy(_pid, _amount);
    }

    function depositAll(uint _pid, address _referrer) external {
        require(address(poolInfo[_pid].want) != address(WNative), "Can't deposit all Native");
        uint _balance = poolInfo[_pid].want.balanceOf(msg.sender);

        deposit(_pid, _balance, _referrer);
    }

    // Withdraw want token from Archimedes.
    function withdraw(uint _pid, uint _shares) public nonReentrant {
        require(_shares > 0, "0 shares");
        require(_userShares(_pid) >= _shares, "withdraw: not sufficient founds");

        updatePool(_pid);

        // Pay rewards
        _calcPendingAndPayRewards(_pid, msg.sender);

        PoolInfo storage pool = poolInfo[_pid];

        uint _before = _wantBalance(pool.want);
        // this should burn shares and control the amount
        uint withdrawn = _controller(_pid).withdraw(msg.sender, _shares);
        require(withdrawn > 0, "No funds withdrawn");

        uint _balance = _wantBalance(pool.want) - _before;

        // In case we have WNative we unwrap to Native
        if (address(pool.want) == address(WNative)) {
            // Unwrap WNative => Native
            WNative.withdraw(_balance);

            Address.sendValue(payable(msg.sender), _balance);
        } else {
            pool.want.safeTransfer(address(msg.sender), _balance);
        }

        // This is to "save" like the new amount of shares was paid
        _updateUserPaidRewards(_pid, msg.sender);

        emit Withdraw(_pid, msg.sender, _shares);
    }

    function withdrawAll(uint _pid) external {
        withdraw(_pid, _userShares(_pid));
    }

    // Claim rewards for a pool
    function harvest(uint _pid) public nonReentrant {
        _harvest(_pid, msg.sender);
    }

    function _harvest(uint _pid, address _user) internal {
        if (_userShares(_pid, _user) <= 0) { return; }

        updatePool(_pid);

        _calcPendingAndPayRewards(_pid, _user);

        _updateUserPaidRewards(_pid, _user);
    }

    function harvestAll() external {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            harvest(pid);
            if (_outOfGasForLoop()) { break; }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid) external nonReentrant {
        IERC20 want = poolInfo[_pid].want;

        userPaidRewards[_pid][msg.sender] = 0;

        uint _shares = _userShares(_pid);

        require(_shares > 0, "No shares to withdraw");

        uint _before = _wantBalance(want);
        // this should burn shares and control the amount
        _controller(_pid).withdraw(msg.sender, _shares);

        uint __wantBalance = _wantBalance(want) - _before;
        want.safeTransfer(address(msg.sender), __wantBalance);

        emit EmergencyWithdraw(_pid, msg.sender, _shares);
    }

    // Controller callback before transfer to harvest users rewards
    function beforeSharesTransfer(uint _pid, address _from, address _to, uint amount) external onlyController(_pid) {
        if (amount <= 0) { return; }

        // harvest rewards for
        _harvest(_pid, _from);

        // Harvest the shares receiver just in case
        _harvest(_pid, _to);
    }

    // Controller callback after transfer to update users rewards
    function afterSharesTransfer(uint _pid, address _from, address _to, uint amount) external onlyController(_pid) {
        if (amount <= 0) { return; }

        // Reset users "paidRewards"
        _updateUserPaidRewards(_pid, _from);
        _updateUserPaidRewards(_pid, _to);
    }

    function _updateUserPaidRewards(uint _pid, address _user) internal {
        userPaidRewards[_pid][_user] = (_userShares(_pid, _user) * poolInfo[_pid].accPiTokenPerShare) / SHARE_PRECISION;
    }

    function _wantBalance(IERC20 _want) internal view returns (uint) {
        return _want.balanceOf(address(this));
    }

    // Record referral in referralMgr contract if needed
    function _recordReferral(uint _pid, address _referrer) internal {
        // only if it's the first deposit
        if (_userShares(_pid) <= 0 && _referrer != address(0) &&
            _referrer != msg.sender && address(referralMgr) != address(0)) {

            referralMgr.recordReferral(msg.sender, _referrer);
        }
    }

    function _depositInStrategy(uint _pid, uint _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];

        // Archimedes => controller transfer & deposit
        pool.want.safeIncreaseAllowance(pool.controller, _amount);
        _controller(_pid).deposit(msg.sender, _amount);

        // This is to "save" like the new amount of shares was paid
        _updateUserPaidRewards(_pid, msg.sender);

        emit Deposit(_pid, msg.sender, _amount);
    }

    // Pay rewards
    function _calcPendingAndPayRewards(uint _pid, address _user) internal returns (uint pending) {
        uint _shares = _userShares(_pid, _user);

        if (_shares > 0) {
            pending = ((_shares * poolInfo[_pid].accPiTokenPerShare) / SHARE_PRECISION) - paidRewards(_pid, _user);

            if (pending > 0) {
                _safePiTokenTransfer(_user, pending);
                _payReferralCommission(_user, pending);

                emit Harvested(_pid, _user, pending);
            }
        }
    }

    // Safe piToken transfer function, just in case if rounding error causes pool to not have enough PI.
    function _safePiTokenTransfer(address _to, uint _amount) internal {
        uint piTokenBal = piToken.balanceOf(address(this));

        if (_amount > piTokenBal) {
            _amount = piTokenBal;
        }

        // piToken.transfer is safe
        piToken.transfer(_to, _amount);
    }

    // Update the referral contract address by the owner
    function setReferralAddress(IReferral _newReferral) external onlyAdmin {
        require(_newReferral != referralMgr, "Same Manager");
        require(address(_newReferral) != address(0), "!ZeroAddress");
        referralMgr = _newReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyAdmin {
        require(_referralCommissionRate != referralCommissionRate, "Same rate");
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "rate greater than MaxCommission");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function _payReferralCommission(address _user, uint _pending) internal {
        if (address(referralMgr) != address(0) && referralCommissionRate > 0) {
            address referrer = referralMgr.getReferrer(_user);

            uint commissionAmount = (_pending * referralCommissionRate) / COMMISSION_RATE_PRECISION;
            if (referrer != address(0) && commissionAmount > 0) {
                uint communityLeftToMint = piToken.communityLeftToMint();

                if (communityLeftToMint < commissionAmount) {
                    commissionAmount = communityLeftToMint;
                }

                if (commissionAmount > 0) {
                    piToken.communityMint(referrer, commissionAmount);
                    referralMgr.referralPaid(referrer, commissionAmount); // sum paid
                }
            }
        }
    }

    // View functions
    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    function _userShares(uint _pid) public view returns (uint) {
        return _controller(_pid).balanceOf(msg.sender);
    }
    function _userShares(uint _pid, address _user) public view returns (uint) {
        return _controller(_pid).balanceOf(_user);
    }

    function paidRewards(uint _pid) public view returns (uint) {
        return userPaidRewards[_pid][msg.sender];
    }
    function paidRewards(uint _pid, address _user) public view returns (uint) {
        return userPaidRewards[_pid][_user];
    }
    function _controller(uint _pid) internal view returns (IController) {
        return IController(poolInfo[_pid].controller);
    }

    function getPricePerFullShare(uint _pid) external view returns (uint) {
        uint _totalSupply = _controller(_pid).totalSupply();
        uint precision = 10 ** decimals(_pid);

        return _totalSupply <= 0 ? precision : ((_controller(_pid).balance() * precision) / _totalSupply);
    }
    function decimals(uint _pid) public view returns (uint) {
        return _controller(_pid).decimals();
    }
    function balance(uint _pid) external view returns (uint) {
        return _controller(_pid).balance();
    }
    function balanceOf(uint _pid, address _user) external view returns (uint) {
        return _controller(_pid).balanceOf(_user);
    }

    function paused(uint _pid) external view returns (bool) {
        return IStrategy(_controller(_pid).strategy()).paused();
    }

    function availableDeposit(uint _pid) external view returns (uint) {
        return _controller(_pid).availableDeposit();
    }

    function availableUserDeposit(uint _pid, address _user) external view returns (uint) {
        return _controller(_pid).availableUserDeposit(_user);
    }

    function piTokenPerBlock() public view returns (uint) {
        // Skip 0~5% of minting per block for Referrals
        uint reserve = COMMISSION_RATE_PRECISION - referralCommissionRate;
        return piToken.communityMintPerBlock() * reserve / COMMISSION_RATE_PRECISION;
    }

    function poolStrategyInfo(uint _pid) external view returns (
        IStrategy strategy,
        string memory stratIdentifier
    ) {
        strategy = IStrategy(_controller(_pid).strategy());
        stratIdentifier = strategy.identifier();
    }

    // Only to be mocked
    function _blockNumber() internal view virtual returns (uint) {
        return block.number;
    }

    // In case of stucketd 2Pi tokens after 2.5 years
    // check if any holder has pending tokens then call this fn
    // E.g. in case of a few EmergencyWithdraw the rewards will be stucked
    function redeemStuckedPiTokens() external onlyAdmin {
        require(piToken.totalSupply() == piToken.MAX_SUPPLY(), "PiToken still minting");
        // 2.5 years (2.5 * 365 * 24 * 3600) / 2.4s per block == 32850000
        require(_blockNumber() > (startBlock + 32850000), "Still waiting");

        uint _balance = piToken.balanceOf(address(this));

        if (_balance > 0) { piToken.transfer(msg.sender, _balance); }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
// import "hardhat/console.sol";

abstract contract PiAdmin is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    // @dev Used to break loops if gasleft is less than 20k
    function _outOfGasForLoop() internal view returns (bool) {
        return gasleft() <= 20_000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../vendor_contracts/NativeSuperTokenProxy.sol";

// Used in Archimedes
interface IPiToken is ISuperToken {
    function apiMint(address _receiver, uint _supply) external;
    function communityMint(address _receiver, uint _supply) external;
    function communityMintPerBlock() external view returns(uint);
    function apiMintPerBlock() external view returns(uint);
    function communityLeftToMint() external view returns(uint);
    function apiLeftToMint() external view returns(uint);
    function MAX_SUPPLY() external view returns(uint);
}

// Used for tests
interface IPiTokenMocked is IPiToken {
    function initRewardsOn(uint _startBlock) external;
    function init() external;
    function addMinter(address newMinter) external;
    function addBurner(address newBurner) external;
    function cap() external view returns(uint);
    function INITIAL_SUPPLY() external view returns(uint);
    function setBlockNumber(uint n) external;
    function setCommunityMintPerBlock(uint n) external;
    function setApiMintPerBlock(uint n) external;
    function mintForMultiChain(uint n, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IController {
    function strategy() external view returns (address);
    function totalSupply() external view returns (uint);
    function balance() external view returns (uint);
    function balanceOf(address _user) external view returns (uint);
    function decimals() external view returns (uint);
    function archimedes() external view returns (address);
    function deposit(address _depositor, uint _amount) external;
    function withdraw(address _depositor, uint _shares) external returns (uint);
    function setPid(uint pid) external returns (uint);
    function depositLimit() external view returns (uint);
    function userDepositLimit(address) external view returns (uint);
    function availableDeposit() external view returns (uint);
    function availableUserDeposit(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IReferral {
    function recordReferral(address, address referrer) external;
    function referralPaid(address user, uint amount) external;
    function getReferrer(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStrategy {
    function balance() external view returns (uint);
    function balanceOf() external view returns (uint);
    function beforeMovement() external;
    function deposit() external;
    function paused() external view returns (bool);
    function retireStrat() external;
    function want() external view returns (address);
    function withdraw(uint) external returns (uint);
    function identifier() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWNative is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

interface ISuperfluidToken {

    /**************************************************************************
     * Basic information
     *************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /**
    * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
    * @param account for the query
    * @param timestamp Time of balance
    * @return availableBalance Real-time balance
    * @return deposit Account deposit
    * @return owedDeposit Account owed Deposit
    */
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit);

    /// @dev realtimeBalanceOf with timestamp equals to block timestamp
    function realtimeBalanceOfNow(
       address account
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp);

    /**
    * @dev Check if one account is critical
    * @param account Account check if is critical by a future time
    * @param timestamp Time of balance
    * @return isCritical
    */
    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isCritical);

    /**
    * @dev Check if one account is critical now
    * @param account Account check if is critical by a future time
    * @return isCritical
    */
    function isAccountCriticalNow(
        address account
    )
        external view
        returns(bool isCritical);

    /**
     * @dev Check if one account is solvent
     * @param account Account check if is solvent by a future time
     * @param timestamp Time of balance
     * @return isSolvent
     */
    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isSolvent);

    /**
     * @dev Check if one account is solvent now
     * @param account Account check if is solvent now
     * @return isSolvent
     */
    function isAccountSolventNow(
        address account
    )
        external view
        returns(bool isSolvent);

    /**
    * @dev Get a list of agreements that is active for the account
    * @dev An active agreement is one that has state for the account
    * @param account Account to query
    * @return activeAgreements List of accounts that have non-zero states for the account
    */
    function getAccountActiveAgreements(address account)
       external view
       returns(ISuperAgreement[] memory activeAgreements);


   /**************************************************************************
    * Super Agreement hosting functions
    *************************************************************************/

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external;

    /**
     * @dev Agreement creation event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementCreated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view
        returns(bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external;

    /**
     * @dev Agreement creation event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementUpdated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external;

    /**
     * @dev Agreement termination event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */
    event AgreementTerminated(
        address indexed agreementClass,
        bytes32 id
    );

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * NOTE
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external;

    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */
    event AgreementStateUpdated(
        address indexed agreementClass,
        address indexed account,
        uint256 slotId
    );

    /**
     * @dev Get data of the slot of the state of a agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view
        returns (bytes32[] memory slotData);

    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account of the agrement
     * @param state Agreement state of the account
     */
    event AgreementAccountStateUpdated(
        address indexed agreementClass,
        address indexed account,
        bytes state
    );

    /**
     * @dev Settle balance from an account by the agreement.
     *      The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * Modifiers:
     *  - onlyAgreement
     */
    function settleBalance(
        address account,
        int256 delta
    )
        external;

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATIED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     */
    event Bailout(
        address indexed bailoutAccount,
        uint256 bailoutAmount
    );

    /**
     * @dev Agreement liquidation event (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * NOTE:
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );

    /**
     * @dev Make liquidation payouts
     * @param id Agreement ID
     * @param liquidator Address of the executer of liquidation
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of account bailout needed
     *
     * NOTE:
     * Liquidation rules:
     *  - If a bailout is required (bailoutAmount > 0)
     *     - the actual reward goes to the liquidator,
     *     - while the reward account becomes the bailout account
     *     - total bailout include: bailout amount + reward amount
     *
     * Modifiers:
     *  - onlyAgreement
     */
    function makeLiquidationPayouts
    (
        bytes32 id,
        address liquidator,
        address penaltyAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    )
        external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *************************************************************************/

     /// @dev The msg.sender must be host contract
     //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

}

interface ISuperAgreement {

    /**
     * @dev Initialize the agreement contract
     */
    function initialize() external;

    /**
     * @dev Get the type of the agreement class.
     */
    function agreementType() external view returns (bytes32);

    /**
     * @dev Calculate the real-time balance for the account of this agreement class.
     * @param account Account the state belongs to
     * @param time Future time used for the calculation.
     * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement.
     * @return deposit Account deposit amount of this agreement.
     * @return owedDeposit Account owed deposit amount of this agreement.
     */
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        );

}

interface TokenInfo {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {

    /// @dev Initialize the contract
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    ) external;

    /**************************************************************************
    * TokenInfo & ERC777
    *************************************************************************/

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: SuperToken always uses 18 decimals.
     *
     * Note: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(TokenInfo) returns (uint8);

    /**************************************************************************
    * ERC20 & ERC777
    *************************************************************************/

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns(uint256 balance);

    /**************************************************************************
    * ERC20
    *************************************************************************/

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external override(IERC20) view returns (uint256);

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
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**************************************************************************
    * ERC777
    *************************************************************************/

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For super token contracts, this value is 1 always
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external override(IERC777) view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external override(IERC777) view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    /**
     * @dev Mint new tokens for the account
     *
     * Modifiers:
     *  - onlySelf
     */
    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    ) external;

   /**
    * @dev Burn existing tokens for the account
    *
    * Modifiers:
    *  - onlySelf
    */
   function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
   ) external;

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns(address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * NOTE: It will use ´transferFrom´ to get tokens. Before calling this
     * function you should ´approve´ this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to received upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * NOTE: It will use ´transferFrom´ to get tokens. Before calling this
     * function you should ´approve´ this contract
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are upgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

    /**************************************************************************
    * Batch Operations
    *************************************************************************/

    /**
    * @dev Perform ERC20 approve by host contract.
    * @param account The account owner to be approved.
    * @param spender The spender of account owner's funds.
    * @param amount Number of tokens to be approved.
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationApprove(
        address account,
        address spender,
        uint256 amount
    ) external;

    /**
    * @dev Perform ERC20 transfer from by host contract.
    * @param account The account to spend sender's funds.
    * @param spender  The account where the funds is sent from.
    * @param recipient The recipient of thefunds.
    * @param amount Number of tokens to be transferred.
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    ) external;

    /**
    * @dev Upgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be upgraded (in 18 decimals)
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationUpgrade(address account, uint256 amount) external;

    /**
    * @dev Downgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be downgraded (in 18 decimals)
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationDowngrade(address account, uint256 amount) external;


    /**************************************************************************
    * Function modifiers for access control and parameter validations
    *
    * While they cannot be explicitly stated in function definitions, they are
    * listed in function definition comments instead for clarity.
    *
    * NOTE: solidity-coverage not supporting it
    *************************************************************************/

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual

}

interface ISuperfluidGovernance {

    /**
     * @dev Replace the current governance with a new governance
     */
    function replaceGovernance(
        ISuperfluid host,
        address newGov) external;

    /**
     * @dev Register a new agreement class
     */
    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass) external;

    /**
     * @dev Update logics of the contracts
     *
     * NOTE:
     * - Because they might have inter-dependencies, it is good to have one single function to update them all
     */
    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    ) external;

    /**
     * @dev Update supertoken logic contract to the latest that is managed by the super token factory
     */
    function updateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken token) external;

    /// @dev Get configuration as address value
    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (address value);

    /// @dev Get configuration as uint256 value
    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (uint256 value);

}

abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {}

interface ISuperTokenFactory {

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /// @dev Initialize the contract
    function initialize() external;

    /**
     * @dev Get the current super token logic used by the factory
     */
    function getSuperTokenLogic() external view returns (ISuperToken superToken);

    /**
     * @dev Upgradability modes
     */
    enum Upgradability {
        /// Non upgradable super token, `host.updateSuperTokenLogic` will revert
        NON_UPGRADABLE,
        /// Upgradable through `host.updateSuperTokenLogic` operation
        SEMI_UPGRADABLE,
        /// Always using the latest super token logic
        FULL_UPGRADABE
    }

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token
     * @param underlyingToken Underlying ERC20 token
     * @param underlyingDecimals Underlying token decimals
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     */
    function createERC20Wrapper(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token with extra token info
     * @param underlyingToken Underlying ERC20 token
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     *
     * NOTE:
     * - It assumes token provide the .decimals() function
     */
    function createERC20Wrapper(
        ERC20WithTokenInfo underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external;

    event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

    event SuperTokenCreated(ISuperToken indexed token);

    event CustomSuperTokenCreated(ISuperToken indexed token);

}

interface ISuperApp {

    /**
     * @dev Callback before a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * NOTE:
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
     * @dev Callback after a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param cbdata The data returned from the before-hook callback.
     * @param ctx The context data.
     * @return newCtx The current context of the transaction.
     *
     * NOTE:
     * - State changes is permitted.
     * - Only revert with a "reason" is permitted.
     */
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
     * @dev Callback before a new agreement is updated.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * NOTE:
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);


    /**
    * @dev Callback after a new agreement is updated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * NOTE:
    * - State changes is permitted.
    * - Only revert with a "reason" is permitted.
    */
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
    * @dev Callback before a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param ctx The context data.
    * @return cbdata A free format in memory data the app can use to pass
    *          arbitary information to the after-hook callback.
    *
    * NOTE:
    * - It will be invoked with `staticcall`, no state changes are permitted.
    * - Revert is not permitted.
    */
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
    * @dev Callback after a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * NOTE:
    * - State changes is permitted.
    * - Revert is not permitted.
    */
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);
}

library SuperAppDefinitions {

    /**************************************************************************
    / App manifest config word
    /**************************************************************************/

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 constant internal APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 constant internal APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 constant internal APP_LEVEL_SECOND = 1 << 1;

    function getAppLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 constant internal APP_JAIL_BIT = 1 << 15;
    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**************************************************************************
    / Callback implementation bit masks
    /**************************************************************************/
    uint256 constant internal AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 constant internal BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 constant internal AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 constant internal BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 constant internal AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 constant internal BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 constant internal AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**************************************************************************
    / App Jail Reasons
    /**************************************************************************/

    uint256 constant internal APP_RULE_REGISTRATION_ONLY_IN_CONSTRUCTOR = 1;
    uint256 constant internal APP_RULE_NO_REGISTRATION_FOR_EOA = 2;
    uint256 constant internal APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 constant internal APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 constant internal APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 constant internal APP_RULE_CTX_IS_READONLY = 20;
    uint256 constant internal APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 constant internal APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 constant internal APP_RULE_MAX_APP_LEVEL_REACHED = 40;
}

library ContextDefinitions {

    /**************************************************************************
    / Call info
    /**************************************************************************/

    // app level
    uint256 constant internal CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 constant internal CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 constant internal CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 constant internal CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo)
        internal pure
        returns (uint8 appLevel, uint8 callType)
    {
        appLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appLevel, uint8 callType)
        internal pure
        returns (uint256 callInfo)
    {
        return uint256(appLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }

}

library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes calldata, bytes userdata)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
}

library SuperfluidGovernanceConfigs {

    bytes32 constant internal SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");

    bytes32 constant internal CFAv1_LIQUIDATION_PERIOD_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.liquidationPeriod");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.trustedForwarder",
            forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
            deployer,
            registrationKey));
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.factory",
            factory));
    }
}

interface ISuperfluid {

    /**************************************************************************
     * Governance
     *************************************************************************/

    /**
     * @dev Get the current governace of the Superfluid host
     */
    function getGovernance() external view returns(ISuperfluidGovernance governance);

    event GovernanceReplaced(ISuperfluidGovernance oldGov, ISuperfluidGovernance newGov);
    /**
     * @dev Replace the current governance with a new one
     */
    function replaceGovernance(ISuperfluidGovernance newGov) external;

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    event AgreementClassRegistered(bytes32 agreementType, address code);
    /**
     * @dev Register a new agreement class to the system
     * @param agreementClassLogic INitial agreement class code
     *
     * Modifiers:
     *  - onlyGovernance
     */
    function registerAgreementClass(ISuperAgreement agreementClassLogic) external;

    event AgreementClassUpdated(bytes32 agreementType, address code);
    /**
    * @dev Update code of an agreement class
    * @param agreementClassLogic New code for the agreement class
    *
    * Modifiers:
    *  - onlyGovernance
    */
    function updateAgreementClass(ISuperAgreement agreementClassLogic) external;

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementTypeListed(bytes32 agreementType) external view returns(bool yes);

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementClassListed(ISuperAgreement agreementClass) external view returns(bool yes);

    /**
    * @dev Get agreement class
    */
    function getAgreementClass(bytes32 agreementType) external view returns(ISuperAgreement agreementClass);

    /**
    * @dev Map list of the agreement classes using a bitmap
    * @param bitmap Agreement class bitmap
    */
    function mapAgreementClasses(uint256 bitmap)
        external view
        returns (ISuperAgreement[] memory agreementClasses);

    /**
    * @dev Create a new bitmask by adding a agreement class to it.
    * @param bitmap Agreement class bitmap
    */
    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**
    * @dev Create a new bitmask by removing a agreement class from it.
    * @param bitmap Agreement class bitmap
    */
    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**************************************************************************
    * Super Token Factory
    **************************************************************************/

    /**
     * @dev Get the super token factory
     * @return factory The factory
     */
    function getSuperTokenFactory() external view returns (ISuperTokenFactory factory);

    /**
     * @dev Get the super token factory logic (applicable to upgradable deployment)
     * @return logic The factory logic
     */
    function getSuperTokenFactoryLogic() external view returns (address logic);

    event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);
    /**
     * @dev Update super token factory
     * @param newFactory New factory logic
     */
    function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;

    event SuperTokenLogicUpdated(ISuperToken indexed token, address code);
    /**
     * @dev Update the super token logic to the latest
     *
     * NOTE:
     * - Refer toISuperTokenFactory.Upgradability for expected behaviours.
     */
    function updateSuperTokenLogic(ISuperToken token) external;

    /**************************************************************************
     * App Registry
     *************************************************************************/

    /**
     * @dev App registered event
     */
    event AppRegistered(ISuperApp indexed app);

    /**
     * @dev Jail event for the app
     */
    event Jail(ISuperApp indexed app, uint256 reason);

    /**
     * @dev Message sender declares it as a super app
     * @param configWord The super app manifest configuration, flags are defined in
     *                   `SuperAppDefinitions`
     */
    function registerApp(uint256 configWord) external;

    /**
     * @dev Message sender declares it as a super app, using a registration key
     * @param configWord The super app manifest configuration, flags are defined in
     *                   `SuperAppDefinitions`
     * @param registrationKey The registration key issued by the governance
     */
    function registerAppWithKey(uint256 configWord, string calldata registrationKey) external;

    /**
     * @dev Message sender declares app as a super app
     * @param configWord The super app manifest configuration, flags are defined in
     *                   `SuperAppDefinitions`
     * NOTE: only factory contracts authorized by governance can register super apps
     */
    function registerAppByFactory(ISuperApp app, uint256 configWord) external;

    /**
     * @dev Query if the app is registered
     * @param app Super app address
     */
    function isApp(ISuperApp app) external view returns(bool);

    /**
     * @dev Query app level
     * @param app Super app address
     */
    function getAppLevel(ISuperApp app) external view returns(uint8 appLevel);

    /**
     * @dev Get the manifest of the super app
     * @param app Super app address
     */
    function getAppManifest(
        ISuperApp app
    )
        external view
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        );

    /**
     * @dev Query if the app has been jailed
     * @param app Super app address
     */
    function isAppJailed(ISuperApp app) external view returns (bool isJail);

    /**
     * @dev White-list the target app for app composition for the source app (msg.sender)
     * @param targetApp The taget super app address
     */
    function allowCompositeApp(ISuperApp targetApp) external;

    /**
     * @dev Query if source app  is allowed to call the target app as downstream app.
     * @param app Super app address
     * @param targetApp The taget super app address
     */
    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view
        returns (bool isAppAllowed);

    /**************************************************************************
     * Agreement Framework
     *
     * Agreements use these function to trigger super app callbacks, updates
     * app allowance and charge gas fees.
     *
     * These functions can only be called by registered agreements.
     *************************************************************************/

    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // isAppActive(app)
        returns(bytes memory cbdata);

    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // isAppActive(app)
        returns(bytes memory appCtx);

    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appAllowanceGranted,
        int256 appAllowanceUsed,
        ISuperfluidToken appAllowanceToken
    )
        external
        // onlyAgreement
        returns (bytes memory appCtx);

    function appCallbackPop(
        bytes calldata ctx,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    function ctxUseAllowance(
        bytes calldata ctx,
        uint256 appAllowanceWantedMore,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    /**************************************************************************
     * Contextless Call Proxies
     *
     * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
     * with agreements or apps.
     *
     * NOTE: The contextual call data should be generated using
     * abi.encodeWithSelector. The context parameter should be set to "0x",
     * an empty bytes array as a placeholder to be replaced by the host
     * contract.
     *************************************************************************/

     /**
      * @dev Call agreement function
      * @param callData The contextual call data with placeholder ctx
      * @param userData Extra user data being sent to the super app callbacks
      */
     function callAgreement(
         ISuperAgreement agreementClass,
         bytes calldata callData,
         bytes calldata userData
     )
        external
        //cleanCtx
        returns(bytes memory returnedData);

    /**
     * @dev Call app action
     * @param callData The contextual call data.
     *
     * NOTE: See callAgreement about contextual call data.
     */
    function callAppAction(
        ISuperApp app,
        bytes calldata callData
    )
        external
        //cleanCtx
        //isAppActive(app)
        returns(bytes memory returnedData);

    /**************************************************************************
     * Contextual Call Proxies and Context Utilities
     *
     * For apps, they must use context they receive to interact with
     * agreements or apps.
     *
     * The context changes must be saved and returned by the apps in their
     * callbacks always, any modification to the context will be detected and
     * the violating app will be jailed.
     *************************************************************************/

    /**
     * @dev ABIv2 Encoded memory data of context
     *
     * NOTE on backward compatibility:
     * - Non-dynamic fields are padded to 32bytes and packed
     * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
     * - The order of the fields hence should not be rearranged in order to be backward compatible:
     *    - non-dynamic fields will be parsed at the same memory location,
     *    - and dynamic fields will simply have a greater offset than it was.
     */
    struct Context {
        //
        // Call context
        //
        // callback level
        uint8 appLevel;
        // type of call
        uint8 callType;
        // the system timestsamp
        uint256 timestamp;
        // The intended message sender for the call
        address msgSender;

        //
        // Callback context
        //
        // For callbacks it is used to know which agreement function selector is called
        bytes4 agreementSelector;
        // User provided data for app callbacks
        bytes userData;

        //
        // App context
        //
        // app allowance granted
        uint256 appAllowanceGranted;
        // app allowance wanted by the app callback
        uint256 appAllowanceWanted;
        // app allowance used, allowing negative values over a callback session
        int256 appAllowanceUsed;
        // app address
        address appAddress;
        // app allowance in super token
        ISuperfluidToken appAllowanceToken;
    }

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external
        // validCtx(ctx)
        // onlyAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData);

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external
        // validCtx(ctx)
        // isAppActive(app)
        returns (bytes memory newCtx);

    function decodeCtx(bytes calldata ctx)
        external pure
        returns (Context memory context);

    function isCtxValid(bytes calldata ctx) external view returns (bool);

    /**************************************************************************
    * Batch call
    **************************************************************************/
    /**
     * @dev Batch operation data
     */
    struct Operation {
        // Operation. Defined in BatchOperation (Definitions.sol)
        uint32 operationType;
        // Operation target
        address target;
        // Data specific to the operation
        bytes data;
    }

    /**
     * @dev Batch call function
     * @param operations Array of batch operations.
     */
    function batchCall(Operation[] memory operations) external;

    /**
     * @dev Batch call function for trusted forwarders (EIP-2771)
     * @param operations Array of batch operations.
     */
    function forwardBatchCall(Operation[] memory operations) external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * TODO: turning these off because solidity-coverage don't like it
     *************************************************************************/

     /* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev The superfluid context is valid.
     modifier validCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}

abstract contract CustomSuperTokenBase {
    // This is the hard-coded number of storage slots used by the super token
    uint256[32] internal _storagePaddings;
}

interface INativeSuperTokenCustom {
    function initialize(string calldata name, string calldata symbol, uint256 initialSupply) external;
}

library UUPSUtils {

    /**
     * @dev Implementation slot constant.
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address.
    function implementation() internal view returns (address impl) {
        assembly { // solium-disable-line
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function setImplementation(address codeAddress) internal {
        assembly {
            // solium-disable-line
            sstore(
                _IMPLEMENTATION_SLOT,
                codeAddress
            )
        }
    }

}

abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

contract UUPSProxy is Proxy {

    /**
     * @dev Proxy initialization function.
     *      This should only be called once and it is permission-less.
     * @param initialAddress Initial logic contract code address to be used.
     */
    function initializeProxy(address initialAddress) external {
        require(initialAddress != address(0), "UUPSProxy: zero address");
        require(UUPSUtils.implementation() == address(0), "UUPSProxy: already initialized");
        UUPSUtils.setImplementation(initialAddress);
    }

    /// @dev Proxy._implementation implementation
    function _implementation() internal virtual override view returns (address)
    {
        return UUPSUtils.implementation();
    }

}

// SPDX-License-Identifier: AGPLv3
/**
 * @dev Native SuperToken custom super token implementation
 *
 * NOTE: this is a merged one-file from 1.0.0-rc7 contracts/tokens/NativeSuperToken.sol
 *
 */
contract NativeSuperTokenProxy is INativeSuperTokenCustom, CustomSuperTokenBase, UUPSProxy {
    function initialize(string calldata /*name*/, string calldata /*symbol*/, uint256 /*initialSupply*/) external pure override {
        revert("Can't call initialize directly");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { Archimedes, IPiToken, IWNative } from "../Archimedes.sol";

contract ArchimedesMock is Archimedes {
    uint private mockedBlockNumber;

    constructor(
        IPiToken _piToken,
        uint _startBlock,
        IWNative _wNative
    ) Archimedes(_piToken, _startBlock, _wNative) { }

    function setBlockNumber(uint _n) public {
        mockedBlockNumber = _n;
    }

    function _blockNumber() internal view override returns (uint) {
        return mockedBlockNumber == 0 ? block.number : mockedBlockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/*
    Zap contracts based on PancakeBunny ZapSushi
    Many thanks for the team =)
    https://github.com/PancakeBunny-finance/PolygonBUNNY/blob/main/contracts/zap/ZapSushi.sol
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PiAdmin.sol";

import "../interfaces/IUniswapPair.sol";
import "../interfaces/IUniswapRouter.sol";
import "../interfaces/IWNative.sol";

contract UniZap is PiAdmin, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant WNative = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    address public constant WETH = address(0x3C68CE8504087f89c640D02d133646d98e64ddd9);

    IUniswapRouter public exchange = IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    mapping(address => address) public routePairAddresses;

    receive() external payable {}

    event NewExchange(address oldExchange, address newExchange);

    function zapInToken(address _from, uint amount, address _to) external nonReentrant {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);

        _zapInToken(_from, amount, _to);
    }

    function zapIn(address _to) external payable nonReentrant {
        IWNative(WNative).deposit{value: msg.value}();

        _zapInToken(WNative, msg.value, _to);
    }

    // zapOut only should work to split LPs
    function zapOut(address _from, uint amount) external nonReentrant {
        if (_isLP(_from)) {
            IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);

            IUniswapPair pair = IUniswapPair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();

            _approveToken(_from, amount);

            if (token0 == WNative || token1 == WNative) {
                exchange.removeLiquidityETH(
                    token0 != WNative ? token0 : token1,
                    amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp + 60
                );
            } else {
                exchange.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp + 60);
            }

            _removeAllowance(_from);
        }
    }

    function estimateReceiveTokens(address _from, address _to, uint _amount) public view returns (uint) {
        address[] memory route = _getRoute(_from, _to);

        uint[] memory amounts = exchange.getAmountsOut(_amount, route);

        return amounts[amounts.length - 1];
    }

    /* ========== Private Functions ========== */
    function _approveToken(address _token, uint _amount) internal {
        IERC20(_token).safeApprove(address(exchange), _amount);
    }

    function _removeAllowance(address _token) internal {
        if (IERC20(_token).allowance(address(this), address(exchange)) > 0) {
            IERC20(_token).safeApprove(address(exchange), 0);
        }
    }

    function _isLP(address _addr) internal view returns (bool) {
        try IUniswapPair(_addr).token1() returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function _zapInToken(address _from, uint amount, address _to) internal {
        if (_isLP(_to)) {
            IUniswapPair pair = IUniswapPair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            uint sellAmount = amount / 2;

            uint amount0 = amount - sellAmount;
            uint amount1;

            // If _from is one of the LP tokens we need to swap just 1
            if (_from == token0) {
                amount1 = _swap(_from, sellAmount, token1, address(this));
            } else if (_from == token1) {
                amount1 = amount0; // amount - sellAmount
                amount0 = _swap(_from, sellAmount, token0, address(this));
            } else {
                // If _from isn't one of LP tokens we swap half for each one
                amount1 = _swap(_from, amount0, token1, address(this));
                amount0 = _swap(_from, sellAmount, token0, address(this));
            }
            // Double check that lp has reserves
            pair.skim(address(this));

            // Approve only needed amounts
            _approveToken(token0, amount0);
            _approveToken(token1, amount1);
            // Add liquidity to the LP
            exchange.addLiquidity(
                token0,
                token1,
                amount0,
                amount1,
                0,
                0,
                msg.sender,
                block.timestamp + 60
            );

            _removeAllowance(token0);
            _removeAllowance(token1);
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function _swap(address _from, uint amount, address _to, address receiver) private returns (uint) {
        address[] memory route = _getRoute(_from, _to);

        _approveToken(_from, amount);
        uint[] memory amounts = exchange.swapExactTokensForTokens(amount, 0, route, receiver, block.timestamp);
        _removeAllowance(_from);

        return amounts[amounts.length - 1];
    }

    function _getRoute(address _from, address _to) internal view returns (address[] memory route) {
        if (
            routePairAddresses[_from] != address(0) &&
            routePairAddresses[_to] != address(0) &&
            routePairAddresses[_from] != routePairAddresses[_to]
        ) {
            if (routePairAddresses[_from] == WETH || routePairAddresses[_to] == WETH) {
                route = new address[](4);
                route[0] = _from;
                route[1] = routePairAddresses[_from];
                route[2] = routePairAddresses[_to];
                route[3] = _to;
            } else {
                route = new address[](5);
                route[0] = _from;
                route[1] = routePairAddresses[_from];
                route[2] = WETH;
                route[3] = routePairAddresses[_to];
                route[4] = _to;
            }
        } else if (routePairAddresses[_from] != address(0) && routePairAddresses[_from] != WETH) {
            route = new address[](4);
            route[0] = _from;
            route[1] = routePairAddresses[_from];
            route[2] = WETH;
            route[3] = _to;
        } else if (routePairAddresses[_to] != address(0) && routePairAddresses[_to] != WETH) {
            route = new address[](4);
            route[0] = _from;
            route[2] = WETH;
            route[1] = routePairAddresses[_to];
            route[3] = _to;
        } else if (_from == WETH || _to == WETH) {
            route = new address[](2);
            route[0] = _from;
            route[1] = _to;
        } else {
            route = new address[](3);
            route[0] = _from;
            route[1] = WETH;
            route[2] = _to;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setExchange(address _newExchange) external onlyAdmin {
        require(_newExchange != address(0), "!ZeroAddress");
        emit NewExchange(address(exchange), _newExchange);
        exchange = IUniswapRouter(_newExchange);

    }

    function setRoutePairAddress(address asset, address route) external onlyAdmin {
        routePairAddresses[asset] = route;
    }

    // Sweep airdroips / remains
    function sweep(address _token) external onlyAdmin {
        if (_token == address(0)) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        } else {
            uint amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapPair {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function skim(address to) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapRouter {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Swappable.sol";
import "../interfaces/IUniswapPair.sol";
import "../interfaces/IUniswapRouter.sol";

contract SwapperWithCompensation is Swappable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    address public immutable strategy;
    address public exchange = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IUniswapPair public immutable lp;
    IERC20Metadata public immutable token0;
    IERC20Metadata public immutable token1;
    IERC20Metadata public immutable want;

    mapping(address => mapping(address => address[])) public routes;

    uint public reserveSwapRatio = 50; // 0.5% (0.3% of swap fee + a little more to get the more LP as possible
    uint public offsetRatio = 80; // 0.8% (0.3% of swap fee + 0.5% of staking deposit fee

    constructor(IERC20Metadata _want, IUniswapPair _lp, address _strategy) {
        // Check that want is at least an ERC20
        _want.symbol();
        require(_want.balanceOf(address(this)) == 0, "Invalid ERC20");
        require(_want.allowance(msg.sender, address(this)) == 0, "Invalid ERC20");

        want = _want;
        lp = _lp;
        token0 = IERC20Metadata(lp.token0());
        token1 = IERC20Metadata(lp.token1());

        strategy = _strategy;
    }

    modifier onlyStrat() {
        require(msg.sender == strategy, "!Strategy");
        _;
    }

    function setRoute(address _from, address[] calldata _route) external onlyAdmin {
        require(_from != address(0), "!ZeroAddress");
        require(_route[0] == _from, "First route isn't from");
        require(_route[_route.length - 1] != _from, "Last route is same as from");
        require(_route.length > 1, "Route length < 2");

        routes[_from][_route[_route.length - 1]] = _route;
    }

    function setReserveSwapRatio(uint newRatio) external onlyAdmin {
        require(newRatio != reserveSwapRatio, "same ratio");
        require(newRatio <= RATIO_PRECISION, "greater than 100%");

        reserveSwapRatio = newRatio;
    }

    function setOffsetRatio(uint newRatio) external onlyAdmin {
        require(newRatio != offsetRatio, "same ratio");
        require(newRatio <= RATIO_PRECISION, "greater than 100%");

        offsetRatio = newRatio;
    }

    function swapLpTokensForWant(uint _amount0, uint _amount1) external onlyStrat returns (uint _amount) {
        uint prevBal = wantBalance();
        if (token0 != want) {
            token0.safeTransferFrom(strategy, address(this), _amount0);
            _swap(address(token0), _amount0, address(want));
        }
        if (token1 != want) {
            token1.safeTransferFrom(strategy, address(this), _amount1);
            _swap(address(token1), _amount1, address(want));
        }

        // This is because the wantBalance could be more to compensate swaps
        _amount = wantBalance() - prevBal;
        want.safeTransfer(strategy, _amount);
    }

    function swapWantForLpTokens(uint _balance) external onlyStrat returns (uint _amount0, uint _amount1) {
        // Ensure the strategy has the _balance
        want.safeTransferFrom(msg.sender, address(this), _balance);

        // Compensate swap
        uint _amount = _balance * (RATIO_PRECISION + offsetRatio) / RATIO_PRECISION;

        if (_amount > wantBalance()) { _amount = wantBalance(); }

        uint _sellAmount;
        (_amount0, _sellAmount) = _wantAmountToLpTokensAmount(_amount);

        // If want is one of the LP tokens we need to swap just 1
        if (want == token0) {
            _amount1 = _swap(address(want), _sellAmount, address(token1));
        } else if (want == token1) {
            _amount1 = _amount0; // _amount - _sellAmount
            _amount0 = _swap(address(want), _sellAmount, address(token0));
        } else {
            // If want isn't one of LP tokens we swap half for each one
            _amount1 = _swap(address(want), _amount0, address(token1));
            _amount0 = _swap(address(want), _sellAmount, address(token0));
        }

        token0.safeTransfer(msg.sender, _amount0);
        token1.safeTransfer(msg.sender, _amount1);
    }

    function _swap(address _from, uint _amount, address _to) internal returns (uint) {
        address[] memory _route = _getRoute(_from, _to);

        if (_amount > 0) {
            uint _expected = _expectedForSwap(_amount, _from, _to);

            if (_expected > 1) {
                _approveToken(_from, _amount);

                uint[] memory _amounts = IUniswapRouter(exchange).swapExactTokensForTokens(
                    _amount,
                    _expected,
                    _route,
                    address(this),
                    block.timestamp
                );

                _removeAllowance(_from);

                return _amounts[_amounts.length - 1];
            }
        }

        return 0;
    }

    function lpInWant(uint _lpAmount) public view returns (uint) {
        (uint112 _reserve0, uint112 _reserve1,) = lp.getReserves();

        uint _lpTotalSupply = lp.totalSupply();
        uint _amount0 = _reserve0 * _lpAmount / _lpTotalSupply;
        uint _amount1 = _reserve1 * _lpAmount / _lpTotalSupply;
        uint _received0 = _getAmountsOut(token0, want, _amount0);
        uint _received1 = _getAmountsOut(token1, want, _amount1);

        return _received0 + _received1;
    }

    function lpToMinAmounts(uint _liquidity) public view returns (uint _amount0Min, uint _amount1Min) {
        uint _lpTotalSupply = lp.totalSupply();
        (uint112 _reserve0, uint112 _reserve1,) = lp.getReserves();

        _amount0Min = _liquidity * _reserve0 / _lpTotalSupply;
        _amount1Min = _liquidity * _reserve1 / _lpTotalSupply;
    }

    function _getAmountsOut(IERC20Metadata _from, IERC20Metadata _to, uint _amount) internal view returns (uint) {
        if (_from == _to) {
            return _amount;
        } else {
            address[] memory _route = _getRoute(address(_from), address(_to));
            uint[] memory amounts = IUniswapRouter(exchange).getAmountsOut(_amount, _route);

            return amounts[amounts.length - 1];
        }
    }

    function _getRoute(address _from, address _to) internal view returns (address[] memory) {
        address[] memory _route = routes[_from][_to];

        require(_route.length > 1, "Invalid route!");

        return _route;
    }

    function _approveToken(address _token, uint _amount) internal {
        IERC20Metadata(_token).safeApprove(exchange, _amount);
    }

    function _removeAllowance(address _token) internal {
        if (IERC20Metadata(_token).allowance(address(this), exchange) > 0) {
            IERC20Metadata(_token).safeApprove(exchange, 0);
        }
    }

    function _max(uint _x, uint _y) internal pure returns (uint) {
        return _x > _y ? _x : _y;
    }

    function wantBalance() public view returns (uint) {
        return want.balanceOf(address(this));
    }

    function _reservePrecision() internal view returns (uint) {
        if (token0.decimals() >= token1.decimals()) {
            return (10 ** token0.decimals()) / (10 ** token1.decimals());
        } else {
            return (10 ** token1.decimals()) / (10 ** token0.decimals());
        }
    }

    function wantToLP(uint _amount) public view returns (uint) {
        (uint112 _reserve0, uint112 _reserve1,) = lp.getReserves();

        // convert amount from want => token0
        if (want != token0 && want != token1) {
            _amount = _getAmountsOut(want, token0, _amount);
        }

        (uint _amount0, uint _amount1) = _wantAmountToLpTokensAmount(_amount);

        uint _lpTotalSupply = lp.totalSupply();

        // They should be equal, but just in case we strive for maximum liquidity =)
        return _max(_amount0 * _lpTotalSupply / _reserve0, _amount1 * _lpTotalSupply / _reserve1);
    }

    function _wantAmountToLpTokensAmount(uint _amount) internal view returns (uint _amount0, uint _amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = lp.getReserves();

        // Reserves in token0 precision
        uint totalReserves = _reserve0;
        totalReserves += _reserve1 / _reservePrecision();

        // Get the reserve ratio plus the 0.5% of the swap
        _amount0 = _amount * _reserve0 *
            (RATIO_PRECISION + reserveSwapRatio) /
            totalReserves / RATIO_PRECISION;

        _amount1 = _amount - _amount0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";

import "./PiAdmin.sol";
import "../interfaces/IChainLink.sol";
import "../interfaces/IUniswapRouter.sol";

abstract contract Swappable is PiAdmin {
    uint constant public SWAP_PRECISION = 1e18;
    uint constant public RATIO_PRECISION = 10000; // 100%
    uint public swapSlippageRatio = 100; // 1%

    mapping(address => IChainLink) public oracles;

    uint public maxPriceOffset = 600; // 10 minutes

    function setSwapSlippageRatio(uint _ratio) external onlyAdmin {
        require(_ratio != swapSlippageRatio, "Same ratio");
        require(_ratio <= RATIO_PRECISION, "Can't be more than 100%");
        swapSlippageRatio = _ratio;
    }

    function setMaxPriceOffset(uint _offset) external onlyAdmin {
        require(_offset != maxPriceOffset, "Same offset");
        require(_offset <= 86400, "Can't be more than 1 day");
        maxPriceOffset = _offset;
    }

    function setPriceFeed(address _token, IChainLink _feed) external onlyAdmin {
        require(_token != address(0), "!ZeroAddress");
        (uint80 round, int price,,,) = _feed.latestRoundData();
        require(round > 0 && price > 0, "Invalid feed");

        oracles[_token] = _feed;
    }

    function _expectedForSwap(uint _amount, address _fromToken, address _toToken) internal view returns (uint) {
        // ratio is a 18 decimals ratio number calculated to get the minimum
        // amount of want-tokens. So the balance is multiplied by the ratio
        // and then divided by 9 decimals to get the same "precision".
        // Then the result should be divided for the decimal diff between tokens.
        // Oracle Price Feed has always 8 decimals.
        // E.g want is USDT with only 6 decimals:
        // tokenDiffPrecision = 1e21 ((1e18 MATIC decimals / 1e6 USDT decimals) * 1e9 ratio precision)
        // ratio = 1_507_423_500 ((152265000 * 1e9) / 100000000) * 99 / 100 [with 1.52 USDT/MATIC]
        // _balance = 1e18 (1.0 MATIC)
        // expected = 1507423 (1e18 * 1_507_423_500 / 1e21) [1.507 in USDT decimals]
        // we should keep in mind the order of the token decimals

        uint ratio = (
            (_getPriceFor(_fromToken) * SWAP_PRECISION) / _getPriceFor(_toToken)
        ) * (RATIO_PRECISION - swapSlippageRatio) / RATIO_PRECISION;

        if (IERC20Metadata(_fromToken).decimals() >= IERC20Metadata(_toToken).decimals()) {
            uint tokenDiffPrecision = (10 ** IERC20Metadata(_fromToken).decimals()) / (10 ** IERC20Metadata(_toToken).decimals());

            tokenDiffPrecision *= SWAP_PRECISION;

            return (_amount * ratio / tokenDiffPrecision);
        } else {
            uint tokenDiffPrecision = (10 ** IERC20Metadata(_toToken).decimals()) / (10 ** IERC20Metadata(_fromToken).decimals());

            return (_amount * ratio * tokenDiffPrecision / SWAP_PRECISION);
        }
    }

    function _getPriceFor(address _token) internal view returns (uint) {
        // This could be implemented with FeedRegistry but it's not available in polygon
        (, int price,,uint timestamp,) = oracles[_token].latestRoundData();

        require(timestamp >= (block.timestamp - maxPriceOffset), "Old price");

        return uint(price);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IChainLink {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  function decimals() external view returns (uint8);
  function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/*
    Zap contracts based on PancakeBunny ZapSushi
    Many thanks for the team =)
    https://github.com/PancakeBunny-finance/PolygonBUNNY/blob/main/contracts/zap/ZapSushi.sol
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PiAdmin.sol";

import "../interfaces/IUniswapPair.sol"; // Solidly pairs are _fairly_ similar
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/IWNative.sol";

contract SolidlyZap is PiAdmin, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant WFTM = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    ISolidlyRouter public exchange = ISolidlyRouter(0xa38cd27185a464914D3046f0AB9d43356B34829D);

    mapping(address => route) public routePairAddresses;

    receive() external payable {}

    event NewExchange(address oldExchange, address newExchange);

    function zapInToken(address _from, uint _amount, address _to, bool _stable) external nonReentrant {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);

        _zapInToken(_from, _amount, _to, _stable);
    }

    function zapIn(address _to, bool _stable) external payable nonReentrant {
        IWNative(WFTM).deposit{value: msg.value}();

        _zapInToken(WFTM, msg.value, _to, _stable);
    }

    // zapOut only should work to split LPs
    function zapOut(address _from, uint _amount, bool _stable) external nonReentrant {
        if (_isLP(_from)) {
            IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);

            IUniswapPair pair = IUniswapPair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();

            _approveToken(_from, _amount);

            if (token0 == WFTM || token1 == WFTM) {
                exchange.removeLiquidityFTM(
                    token0 != WFTM ? token0 : token1,
                    _stable,
                    _amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp + 60
                );
            } else {
                exchange.removeLiquidity(
                    token0,
                    token1,
                    _stable,
                    _amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp + 60
                );
            }

            _removeAllowance(_from);
        }
    }

    function estimateReceiveTokens(address _from, address _to, uint _amount, bool _stable) public view returns (uint) {
        route[] memory _route = _getRoute(_from, _to, _stable);

        uint[] memory amounts = exchange.getAmountsOut(_amount, _route);

        return amounts[amounts.length - 1];
    }

    /* ========== Private Functions ========== */
    function _approveToken(address _token, uint _amount) internal {
        IERC20(_token).safeApprove(address(exchange), _amount);
    }

    function _removeAllowance(address _token) internal {
        if (IERC20(_token).allowance(address(this), address(exchange)) > 0) {
            IERC20(_token).safeApprove(address(exchange), 0);
        }
    }

    function _isLP(address _addr) internal view returns (bool) {
        try IUniswapPair(_addr).token1() returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function _zapInToken(address _from, uint _amount, address _to, bool _stable) internal {
        if (_isLP(_to)) {
            IUniswapPair pair = IUniswapPair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            uint sellAmount = _amount / 2;

            uint amount0 = _amount - sellAmount;
            uint amount1;

            // If _from is one of the LP tokens we need to swap just 1
            if (_from == token0) {
                amount1 = _swap(_from, sellAmount, token1, address(this), _stable);
            } else if (_from == token1) {
                amount1 = amount0; // _amount - sellAmount
                amount0 = _swap(_from, sellAmount, token0, address(this), _stable);
            } else {
                // If _from isn't one of LP tokens we swap half for each one
                amount1 = _swap(_from, amount0, token1, address(this), _stable);
                amount0 = _swap(_from, sellAmount, token0, address(this), _stable);
            }
            // Double check that lp has reserves
            pair.skim(address(this));

            // Approve only needed amounts
            _approveToken(token0, amount0);
            _approveToken(token1, amount1);
            // Add liquidity to the LP
            exchange.addLiquidity(
                token0,
                token1,
                _stable,
                amount0,
                amount1,
                0,
                0,
                msg.sender,
                block.timestamp + 60
            );

            _removeAllowance(token0);
            _removeAllowance(token1);
        } else {
            _swap(_from, _amount, _to, msg.sender, _stable);
        }
    }

    function _swap(address _from, uint _amount, address _to, address _receiver, bool _stable) private returns (uint) {
        route[] memory _route = _getRoute(_from, _to, _stable);

        _approveToken(_from, _amount);
        uint[] memory amounts = exchange.swapExactTokensForTokens(_amount, 0, _route, _receiver, block.timestamp);
        _removeAllowance(_from);

        return amounts[amounts.length - 1];
    }

    function _getRoute(address _from, address _to, bool _stable) internal view returns (route[] memory _route) {
        if (
            routePairAddresses[_from].from != address(0) &&
            routePairAddresses[_from].to != address(0) &&
            routePairAddresses[_to].from != address(0) &&
            routePairAddresses[_to].to != address(0) &&
            routePairAddresses[_from].from != routePairAddresses[_to].from &&
            routePairAddresses[_from].to != routePairAddresses[_to].to
        ) {
            if (routePairAddresses[_from].from == WFTM) {
                _route = new route[](3);
                _route[0] = routePairAddresses[_from];
                _route[1] = routePairAddresses[_to];
                _route[2].from = routePairAddresses[_to].to;
                _route[2].to = _to;
                _route[2].stable = _stable;
            } else if (routePairAddresses[_to].to == WFTM) {
                _route = new route[](3);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_from].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_from];
                _route[2] = routePairAddresses[_to];
            } else {
                _route = new route[](4);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_from].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_from];
                _route[2] = routePairAddresses[_to];
                _route[3].from = routePairAddresses[_to].to;
                _route[3].to = _to;
                _route[3].stable = _stable;
            }
        } else if (routePairAddresses[_from].from != address(0) && routePairAddresses[_to].from == address(0)) {
            if (routePairAddresses[_from].from != WFTM && routePairAddresses[_from].to != WFTM) {
                _route = new route[](4);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_from].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_from];
                _route[2].from = routePairAddresses[_from].to;
                _route[2].to = WFTM;
                _route[2].stable = _stable;
                _route[3].from = WFTM;
                _route[3].to = _to;
                _route[3].stable = _stable;
            } else if (routePairAddresses[_from].from == WFTM || routePairAddresses[_from].to == WFTM) {
                _route = new route[](3);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_from].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_from];
                _route[2].from = routePairAddresses[_from].to;
                _route[2].to = _to;
                _route[2].stable = _stable;
            }
        } else if (routePairAddresses[_to].from != address(0) && routePairAddresses[_from].from == address(0)) {
            if (routePairAddresses[_to].from != WFTM && routePairAddresses[_to].to != WFTM) {
                _route = new route[](4);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_to].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_to];
                _route[2].from = routePairAddresses[_to].to;
                _route[2].to = WFTM;
                _route[2].stable = _stable;
                _route[3].from = WFTM;
                _route[3].to = _to;
                _route[3].stable = _stable;
            } else if (routePairAddresses[_to].from == WFTM || routePairAddresses[_to].to == WFTM) {
                _route = new route[](3);
                _route[0].from = _from;
                _route[0].to = routePairAddresses[_to].from;
                _route[0].stable = _stable;
                _route[1] = routePairAddresses[_to];
                _route[2].from = routePairAddresses[_to].to;
                _route[2].to = _to;
                _route[2].stable = _stable;
            }
        } else if (_from == WFTM || _to == WFTM) {
            _route = new route[](1);
            _route[0].from = _from;
            _route[0].to = _to;
            _route[0].stable = _stable;
        } else {
            _route = new route[](2);
            _route[0].from = _from;
            _route[0].to = WFTM;
            _route[0].stable = _stable;
            _route[1].from = WFTM;
            _route[1].to = _to;
            _route[1].stable = _stable;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setExchange(address _newExchange) external onlyAdmin {
        require(_newExchange != address(0), "!ZeroAddress");
        emit NewExchange(address(exchange), _newExchange);

        exchange = ISolidlyRouter(_newExchange);
    }

    function setRoutePairAddress(address _asset, route memory _route) external onlyAdmin {
        routePairAddresses[_asset] = _route;
    }

    // Sweep airdroips / remains
    function sweep(address _token) external onlyAdmin {
        if (_token == address(0)) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        } else {
            uint amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

struct route {
    address from;
    address to;
    bool stable;
}

interface ISolidlyRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityFTM(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);

    function getAmountsOut(
        uint amountIn,
        route[] memory routes
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";
import "./PiAdmin.sol";

contract TestPiToken is PiAdmin, ERC20 {
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Rates to mint per block
    uint public communityMintPerBlock;
    uint public apiMintPerBlock;

    // Keep track in which block started the current tranche
    uint internal tranchesBlock;

    // Keep track of minted per type for current tranch
    uint internal apiMintedForCurrentTranch;
    uint internal communityMintedForCurrentTranch;
    // Keep track of un-minted per type for old tranches
    uint internal apiReserveFromOldTranches;
    uint internal communityReserveFromOldTranches;

    uint internal API_TYPE = 0;
    uint internal COMMUNITY_TYPE = 1;


    constructor() ERC20('Test-P-2Pi', 'Test-P-2Pi') {
        // Shared max supply
        _mint(msg.sender, 3.14e25);
        _mint(address(this), 3.14e25);
    }

    function initRewardsOn(uint _blockNumber) external onlyAdmin {
        require(tranchesBlock <= 0, "Already set");
        tranchesBlock = _blockNumber;
    }

    // Before change api or community RatePerBlock or before mintForMultiChain is called
    // Calculate and accumulate the un-minted amounts.
    function _beforeChangeMintRate() internal {
        if (tranchesBlock > 0 && blockNumber() > tranchesBlock && (apiMintPerBlock > 0 || communityMintPerBlock > 0)) {
            // Accumulate both proportions to keep track of "un-minted" amounts
            apiReserveFromOldTranches += _leftToMintForCurrentBlock(API_TYPE);
            communityReserveFromOldTranches += _leftToMintForCurrentBlock(COMMUNITY_TYPE);
        }
    }

    function setCommunityMintPerBlock(uint _rate) external onlyAdmin {
        _beforeChangeMintRate();
        communityMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function setApiMintPerBlock(uint _rate) external onlyAdmin {
        _beforeChangeMintRate();
        apiMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function _updateCurrentTranch() internal {
        // Update variables to making calculations from this moment
        if (tranchesBlock > 0 && blockNumber() > tranchesBlock) {
            tranchesBlock = blockNumber();
        }

        // mintedForCurrentTranch = self().totalSupply();
        apiMintedForCurrentTranch = 0;
        communityMintedForCurrentTranch = 0;
    }


    function addMinter(address newMinter) external onlyAdmin {
        _setupRole(MINTER_ROLE, newMinter);
    }

    function available() public view returns (uint) {
        return IERC20(address(this)).balanceOf(address(this));
    }

    // This function checks for "most of revert scenarios" to prevent more minting than expected.
    // And keep track of minted / un-minted amounts
    function _checkMintFor(address _receiver, uint _supply, uint _type) internal {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters");
        require(_receiver != address(0), "Can't mint to zero address");
        require(_supply > 0, "Insufficient supply");
        require(tranchesBlock > 0, "Rewards not initialized");
        require(tranchesBlock < blockNumber(), "Still waiting for rewards block");
        require(available() >= _supply, "Can't mint more than available");

        uint _ratePerBlock = communityMintPerBlock;
        if (_type == API_TYPE) { _ratePerBlock = apiMintPerBlock; }

        require(_ratePerBlock > 0, "Mint ratio is 0");

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Create other variable to add to the MintedForCurrentTranch
        uint _toMint = _supply;

        // if the _supply (mint amount) is less than the expected "everything is fine" but
        // if its greater we have to check the "ReserveFromOldTranches"
        if (_toMint > _maxMintableSupply) {
            // fromReserve is the amount that will be "minted" from the old tranches reserve
            uint fromReserve = _toMint - _maxMintableSupply;

            // Drop the "reserve" amount to track only the "real" tranch minted amount
            _toMint -= fromReserve;

            // Check reserve for type
            if (_type == API_TYPE) {
                require(fromReserve <= apiReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from old tranches reserve
                apiReserveFromOldTranches -= fromReserve;
            } else {
                require(fromReserve <= communityReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from history reserve
                communityReserveFromOldTranches -= fromReserve;
            }
        }

        if (_type == API_TYPE) {
            apiMintedForCurrentTranch += _toMint;
        } else {
            communityMintedForCurrentTranch += _toMint;
        }
    }

    // This function is called mint for contract compatibility but it doesn't mint,
    // it only transfers piTokens
    function communityMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, COMMUNITY_TYPE);

        IERC20(address(this)).safeTransfer(_receiver, _supply);
    }

    function apiMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, API_TYPE);

        IERC20(address(this)).safeTransfer(_receiver, _supply);
    }

    function _leftToMintForCurrentBlock(uint _type) internal view returns (uint) {
        if (tranchesBlock <= 0 || tranchesBlock > blockNumber()) { return 0; }

       uint left = blockNumber() - tranchesBlock;

       if (_type == API_TYPE) {
           left *= apiMintPerBlock;
           left -= apiMintedForCurrentTranch;
       } else {
           left *= communityMintPerBlock;
           left -= communityMintedForCurrentTranch;
       }

       return left;
    }

    function _leftToMint(uint _type) internal view returns (uint) {
        uint totalLeft = available();
        if (totalLeft <= 0) { return 0; }

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Add the _type accumulated un-minted supply
        _maxMintableSupply += (_type == API_TYPE ? apiReserveFromOldTranches : communityReserveFromOldTranches);

        return (totalLeft <= _maxMintableSupply ? totalLeft : _maxMintableSupply);
    }

    function communityLeftToMint() public view returns (uint) {
        return _leftToMint(COMMUNITY_TYPE);
    }

    function apiLeftToMint() public view returns (uint) {
        return _leftToMint(API_TYPE);
    }


    // Implemented to be mocked in tests
    function blockNumber() internal view virtual returns (uint) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IDataProvider {
    function setATokenBalance(address _user, uint _ATokenBalance) external;
    function setDebtTokenBalance(address _user, uint _debtTokenBalance) external;
    function getUserReserveData(address _asset, address _user) external view returns (
        uint currentATokenBalance,
        uint currentStableDebt,
        uint currentVariableDebt,
        uint principalStableDebt,
        uint scaledVariableDebt,
        uint stableBorrowRate,
        uint liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

contract PoolMock {
    address public constant dataProvider = address(0xFA3bD19110d986c5e5E9DD5F69362d05035D045B);

    uint public fakeHF;

    function reset() public {
        fakeHF = 0;
    }

    function setHealthFactor(uint _hf) public {
        fakeHF = _hf;
    }

    function supplyAndBorrow() public view returns (uint, uint) {
        (uint _aTokens, ,uint _debt,,,,,,) = IDataProvider(dataProvider).getUserReserveData(msg.sender, msg.sender);

        return (_aTokens, _debt);
    }

    function deposit(address _asset, uint _amount, address /*_onBehalfOf*/, uint16 /*_referralCode*/) public {
        (uint aTokens,) = supplyAndBorrow();

        IDataProvider(dataProvider).setATokenBalance(msg.sender, aTokens + _amount);

        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _asset, uint _amount, address to) public returns (uint) {
        (uint aTokens,) = supplyAndBorrow();
        if (_amount > aTokens) {
            _amount = aTokens;
        }

        if (_amount > 0) {
            IERC20(_asset).transferFrom(address(this), to, _amount);
        }

        IDataProvider(dataProvider).setATokenBalance(msg.sender, aTokens - _amount);

        return _amount;
    }

    function borrow(
        address _asset,
        uint _amount,
        uint /*_interestRateMode*/,
        uint16 /*_referralCode*/,
        address /*_onBehalfOf*/
    ) public {
        (, uint _debt) = supplyAndBorrow();

        IDataProvider(dataProvider).setDebtTokenBalance(msg.sender, _debt + _amount);

        IERC20(_asset).transfer(msg.sender, _amount);
    }

    function repay(address _asset, uint _amount, uint /*rateMode*/, address /*onBehalfOf*/) public returns (uint) {
        (, uint _debt) = supplyAndBorrow();

        if (_debt <= _amount) {
            _amount = _debt; // to transfer only needed
            _debt = 0;
        } else {
            _debt -= _amount;
        }

        IDataProvider(dataProvider).setDebtTokenBalance(msg.sender, _debt);

        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);

        return _amount;
    }

    function getUserAccountData(address /*user*/) public view returns (
        uint totalCollateralETH,
        uint totalDebtETH,
        uint availableBorrowsETH,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor
    ) {
        (uint _aTokens, uint _debt) = supplyAndBorrow();

        if (fakeHF > 0 ) {
            healthFactor = fakeHF;
        } else if (_debt > 0 && _aTokens > 0) {
            // aTokens * 80% / _debt == 2 digits factor
            healthFactor = ((_aTokens * 80) / (_debt)) * 1e16;
        } else {
            healthFactor = 200e18;
        }

        return (0, 0, 0, 0, 0, healthFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";
import "./PiAdmin.sol";

contract PiVault is ERC20, PiAdmin, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable piToken;

    // Investor & Founders funds will be deposited but not released
    uint public immutable investorsLockTime;
    uint public immutable foundersLockTime;

    // Wallets
    mapping(address => bool) public investors;
    mapping(address => bool) public founders;

    // Individual max amount to release after the first year.
    uint public constant FOUNDERS_MAX_WITHDRAWS_AFTER_FIRST_YEAR = 1.57e24;
    mapping(address => uint) public foundersLeftToWithdraw;

    /**
     * @dev Sets the address of 2pi token, the one that the vault will hold
     * as underlying value.
     * @param _token the 2pi token.
     */
    constructor(address _token, uint _investorsLock, uint _foundersLock) ERC20('stk2Pi', 'stk2Pi') {
        piToken = IERC20(_token);

        investorsLockTime = _investorsLock;
        foundersLockTime = _foundersLock;
    }

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);

    /**
     * @dev Adds address to investors list
     */
    function addInvestor(address _wallet) external onlyAdmin {
        investors[_wallet] = true;
    }

    /**
     * @dev Adds address to founders list
     */
    function addFounder(address _wallet) external onlyAdmin {
        founders[_wallet] = true;
        foundersLeftToWithdraw[_wallet] = FOUNDERS_MAX_WITHDRAWS_AFTER_FIRST_YEAR;
    }

    /**
     * @dev It calculates the total underlying value of {piToken} held by the system.
     */
    function balance() public view returns (uint) {
        return piToken.balanceOf(address(this));
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external returns (uint) {
        return deposit(piToken.balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault.
     */
    function deposit(uint _amount) public nonReentrant returns (uint) {
        uint shares = 0;
        uint _pool = balance();

        piToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint _after = balance();
        _amount = _after - _pool; // Additional check for deflationary piToken

        if (totalSupply() <= 0) {
            shares = _amount;
        } else {
            shares = _amount * totalSupply() / _pool;
        }

        _mint(msg.sender, shares);
        emit Deposit(msg.sender, _amount);

        return shares;
    }

    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev Function to exit the system. The vault will pay up the piToken holder.
     */
    function withdraw(uint _shares) public nonReentrant {
        require(_shares <= balanceOf(msg.sender), "Amount not available");

        uint r = balance() * _shares / totalSupply();

        _checkWithdraw(r);

        _burn(msg.sender, _shares);
        piToken.safeTransfer(msg.sender, r);

        emit Withdraw(msg.sender, _shares);
    }

    function getPricePerFullShare() external view returns (uint) {
        uint _totalSupply = totalSupply();

        return _totalSupply <= 0 ? 1e18 : ((balance() * 1e18) / _totalSupply);
    }

    /**
     * @dev Check if msg.sender is an investor or a founder to release the funds.
     */
    function _checkWithdraw(uint _amount) internal {
        if (investors[msg.sender]) {
            require(block.timestamp >= investorsLockTime, "Still locked");
        } else if (founders[msg.sender]) {
            // Half of founders vesting will be release  at investorsLockTime
            require(block.timestamp >= investorsLockTime, "Still locked");

            // This branch is for the 2º year (between investors release and founders release)
            if (block.timestamp <= foundersLockTime) {
                require(_amount <= foundersLeftToWithdraw[msg.sender], "Max withdraw reached");
                // Accumulate withdrawn for founder
                // (will revert if the amount is greater than the left to withdraw)
                foundersLeftToWithdraw[msg.sender] -= _amount;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint /*amount*/) internal virtual override {
        // Ignore mint/burn
        if (from != address(0) && to != address(0)) {
            // Founders & Investors can't transfer shares before timelock
            if (investors[from]) {
                require(block.timestamp >= investorsLockTime, "Still locked");
            } else if (founders[from]) {
                require(block.timestamp >= foundersLockTime, "Still locked");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "./Swappable.sol";
import "../interfaces/IPiVault.sol";

// Swappable contract has the AccessControl module
contract FeeManager is Swappable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Tokens used
    address public constant wNative = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889); // test
    address public constant piToken = address(0x63D4D6D7D3f727EDAe0d713A1EB8E4e4Ef560430); // Test

    address public immutable piVault;
    address public treasury;
    address public exchange;

    // Fee constants
    uint public treasuryRatio = 150;
    uint public constant MAX_TREASURY_RATIO = 5000; // 50% for treasury & 50% for Stakers

    mapping(address => address[]) public routes;

    constructor(address _treasury, address _piVault, address _exchange) {
        require(_treasury != address(0), "!ZeroAddress treasury");
        require(_exchange != address(0), "!ZeroAddress exchange");
        require(IPiVault(_piVault).piToken() == piToken, "Not PiToken vault");
        treasury = _treasury;
        piVault = _piVault;
        exchange = _exchange;
    }

    event NewTreasuryRatio(uint oldRatio, uint newRatio);
    event NewTreasury(address oldTreasury, address newTreasury);
    event NewExchange(address oldExchange, address newExchange);
    event Harvest(address _token, uint _tokenAmount, uint piTokenAmount);

    function harvest(address _token) external nonReentrant {
        uint _balance = IERC20(_token).balanceOf(address(this));

        if (_balance <= 0) { return; }

        bool native = _token == wNative;
        address[] memory route;

        if (routes[_token].length > 0) {
            route = routes[_token];
        } else {
            route = new address[](native ? 2 : 3);
            route[0] = _token;

            if (native) {
                route[1] = piToken;
            } else {
                route[1] = wNative;
                route[2] = piToken;
            }
        }

        uint expected = _expectedForSwap(_balance, _token, piToken);
        IERC20(_token).safeApprove(exchange, _balance);
        IUniswapRouter(exchange).swapExactTokensForTokens(
            _balance, expected, route, address(this), block.timestamp + 60
        );

        uint piBalance = IERC20(piToken).balanceOf(address(this));
        uint treasuryPart = piBalance * treasuryRatio / RATIO_PRECISION;

        IERC20(piToken).safeTransfer(treasury, treasuryPart);
        IERC20(piToken).safeTransfer(piVault, piBalance - treasuryPart);

        emit Harvest(_token, _balance, piBalance);
    }

    function setTreasuryRatio(uint _ratio) external onlyAdmin nonReentrant {
        require(_ratio != treasuryRatio, "Same ratio");
        require(_ratio <= MAX_TREASURY_RATIO, "Can't be greater than 50%");
        emit NewTreasuryRatio(treasuryRatio, _ratio);
        treasuryRatio = _ratio;
    }

    function setTreasury(address _treasury) external onlyAdmin nonReentrant {
        require(_treasury != treasury, "Same Address");
        require(_treasury != address(0), "!ZeroAddress");
        emit NewTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    function setExchange(address _exchange) external onlyAdmin nonReentrant {
        require(_exchange != exchange, "Same Address");
        require(_exchange != address(0), "!ZeroAddress");
        emit NewExchange(exchange, _exchange);

        exchange = _exchange;
    }

    function setRoute(address _token, address[] calldata _route) external onlyAdmin {
        require(_token != address(0), "!ZeroAddress");
        require(_route.length > 2, "Invalid route");

        for (uint i = 0; i < _route.length; i++) {
            require(_route[i] != address(0), "Route with ZeroAddress");
        }

        routes[_token] = _route;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPiVault {
    function piToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

import "./Swappable.sol";

abstract contract ControllerStratAbs is Swappable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant BOOSTER_ROLE = keccak256("BOOSTER_ROLE");

    // Want
    IERC20Metadata immutable public want;
    // want "missing" decimals precision
    uint internal immutable WANT_MISSING_PRECISION;

    // Pool settings
    uint public ratioForFullWithdraw = 9000; // 90% [Min % to full withdraw
    uint public poolSlippageRatio = 20; // 0.2% [Slippage % to add/remove liquidity to/from the pool]
    // Min % to add/remove to an amount to conver BTC<=>BTCCRV
    // The virtualPrice will ALWAYS be greater than 1.0 (otherwise we're loosing BTC
    // so we only consider the decimal part)
    uint public poolMinVirtualPrice = 30; // 0.3%
    // Pool reward[s] route for Swap
    mapping(address => address[]) public rewardToWantRoute;
    // PoolRewards
    address[] public rewardTokens;

    // Fees
    uint constant public MAX_PERFORMANCE_FEE = 5000; // 50% max
    uint public performanceFee = 450; // 4.5%
    uint internal lastBalance;

    address public treasury;
    address public exchange;
    address public immutable controller; // immutable to prevent anyone to change it and withdraw

    // Deposit compensation
    address public equalizer;
    uint public offsetRatio = 0; // 0.00%

    // manual boosts
    uint public lastExternalBoost;

    // Migrate to a library or something
    function _checkIERC20(IERC20Metadata token, string memory errorMsg) internal view {
        require(address(token) != address(0), errorMsg);
        token.symbol(); // Check that want is at least an ERC20
        require(token.balanceOf(address(this)) == 0, "Invalid ERC20"); // Check that want is at least an ERC20
        require(token.allowance(msg.sender, address(this)) == 0, "Invalid ERC20"); // Check that want is at least an ERC20
    }

    constructor(IERC20Metadata _want, address _controller, address _exchange, address _treasury) {
        _checkIERC20(_want, "Want !ZeroAddress");
        require(_controller != address(0), "Controller !ZeroAddress");
        require(_exchange != address(0), "Exchange !ZeroAddress");
        require(_treasury != address(0), "Treasury !ZeroAddress");

        want = _want;
        controller = _controller;
        exchange = _exchange;
        treasury = _treasury;

        WANT_MISSING_PRECISION = (10 ** (18 - _want.decimals()));

        equalizer = msg.sender;
    }

    event NewTreasury(address oldTreasury, address newTreasury);
    event NewExchange(address oldExchange, address newExchange);
    event NewPerformanceFee(uint oldFee, uint newFee);
    event Harvested(address _want, uint _amount);
    event PerformanceFee(uint _amount);
    event Boosted(address indexed booster, uint amount);

    modifier onlyController() {
        require(msg.sender == controller, "Not from controller");
        _;
    }

    function setTreasury(address _treasury) external onlyAdmin nonReentrant {
        require(_treasury != treasury, "Same address");
        require(_treasury != address(0), "!ZeroAddress");
        emit NewTreasury(treasury, _treasury);

        treasury = _treasury;
    }

    function setExchange(address _exchange) external onlyAdmin nonReentrant {
        require(_exchange != exchange, "Same address");
        require(_exchange != address(0), "!ZeroAddress");
        emit NewExchange(exchange, _exchange);

        exchange = _exchange;
    }

    function setPerformanceFee(uint _fee) external onlyAdmin nonReentrant {
        require(_fee != performanceFee, "Same fee");
        require(_fee <= MAX_PERFORMANCE_FEE, "Can't be greater than max");
        emit NewPerformanceFee(performanceFee, _fee);

        performanceFee = _fee;
    }

    function setPoolMinVirtualPrice(uint _ratio) public onlyAdmin {
        require(_ratio != poolMinVirtualPrice, "Same ratio");
        require(_ratio <= RATIO_PRECISION, "Can't be more than 100%");

        poolMinVirtualPrice = _ratio;
    }

    function setPoolSlippageRatio(uint _ratio) public onlyAdmin {
        require(_ratio != poolSlippageRatio, "Same ratio");
        require(_ratio <= RATIO_PRECISION, "Can't be more than 100%");

        poolSlippageRatio = _ratio;
    }
    function setRatioForFullWithdraw(uint _ratio) public onlyAdmin {
        require(_ratio != ratioForFullWithdraw, "Same ratio");
        require(_ratio <= RATIO_PRECISION, "Can't be more than 100%");

        ratioForFullWithdraw = _ratio;
    }

    function setRewardToWantRoute(address _reward, address[] calldata _route) external onlyAdmin {
        require(_reward != address(0), "!ZeroAddress");
        require(_route[0] == _reward, "First route isn't reward");
        require(_route[_route.length - 1] == address(want), "Last route isn't want token");

        bool newReward = true;
        for (uint i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == _reward) {
                newReward = false;
                break;
            }
        }

        if (newReward) { rewardTokens.push(_reward); }
        rewardToWantRoute[_reward] = _route;
    }

    // Compensation
    function setOffsetRatio(uint newRatio) external onlyAdmin {
        require(newRatio != offsetRatio, "same ratio");
        require(newRatio <= RATIO_PRECISION, "greater than 100%");
        require(newRatio >= 0, "less than 0%?");

        offsetRatio = newRatio;
    }

    function setEqualizer(address _equalizer) external onlyAdmin {
        require(_equalizer != address(0), "!ZeroAddress");
        require(_equalizer != equalizer, "same address");

        equalizer = _equalizer;
    }

    function beforeMovement() external onlyController nonReentrant {
        _beforeMovement();
    }

    // Update new `lastBalance` for the next charge
    function _afterMovement() internal {
        lastBalance = balance();
    }

    function deposit() external whenNotPaused onlyController nonReentrant {
        _deposit();
        _afterMovement();
    }

    function withdraw(uint _amount) external onlyController nonReentrant returns (uint) {
        uint _balance = wantBalance();

        if (_balance < _amount) {
            uint poolBalance = balanceOfPoolInWant();

            // If the requested amount is greater than xx% of the founds just withdraw everything
            if (_amount > (poolBalance * ratioForFullWithdraw / RATIO_PRECISION)) {
                _withdrawAll();
            } else {
                _withdraw(_amount);
            }

            _balance = wantBalance();

            if (_balance < _amount) { _amount = _balance; } // solhint-disable-unreachable-code
        }

        want.safeTransfer(controller, _amount);

        // Redeposit
        if (!paused()) { _deposit(); }

        _afterMovement();

        return _amount;
    }

    function harvest() public nonReentrant virtual {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewards();

        uint harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused()) { _deposit(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), harvested);
    }

    // This function is called to "boost" the strategy.
    function boost(uint _amount) external {
        require(hasRole(BOOSTER_ROLE, msg.sender), "Not a booster");

        // Charge performance fee for earned want
        _beforeMovement();

        // transfer reward from caller
        if (_amount > 0) { want.safeTransferFrom(msg.sender, address(this), _amount); }

        // Keep track of how much is added to calc boost APY
        lastExternalBoost = _amount;

        // Deposit transfered amount
        _deposit();

        // update last_balance to exclude the manual reward from perfFee
        _afterMovement();

        emit Boosted(msg.sender, _amount);
    }

    function _beforeMovement() internal {
        uint currentBalance = balance();

        if (currentBalance > lastBalance) {
            uint perfFee = ((currentBalance - lastBalance) * performanceFee) / RATIO_PRECISION;

            if (perfFee > 0) {
                uint _balance = wantBalance();

                if (_balance < perfFee) {
                    uint _diff = perfFee - _balance;

                    _withdraw(_diff);
                }

                // Just in case
                _balance = wantBalance();
                if (_balance < perfFee) { perfFee = _balance; }

                if (perfFee > 0) {
                    want.safeTransfer(treasury, perfFee);
                    emit PerformanceFee(perfFee);
                }
            }
        }
    }

    function _deposit() internal virtual {
        // should be implemented
    }

    function _withdraw(uint) internal virtual returns (uint) {
        // should be implemented
    }

    function _withdrawAll() internal virtual returns (uint) {
        // should be implemented
    }

    function _claimRewards() internal virtual {
        // should be implemented
    }

    function _swapRewards() internal virtual {
        // should be implemented
        for (uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint _balance = IERC20Metadata(rewardToken).balanceOf(address(this));

            if (_balance > 0) {
                uint expected = _expectedForSwap(_balance, rewardToken, address(want));

                // Want price sometimes is too high so it requires a lot of rewards to swap
                if (expected > 1) {
                    IERC20Metadata(rewardToken).safeApprove(exchange, _balance);

                    IUniswapRouter(exchange).swapExactTokensForTokens(
                        _balance, expected, rewardToWantRoute[rewardToken], address(this), block.timestamp + 60
                    );
                }
            }
        }
    }

    /**
     * @dev Takes out performance fee.
     */
    function _chargeFees(uint _harvested) internal {
        uint fee = (_harvested * performanceFee) / RATIO_PRECISION;

        // Pay to treasury a percentage of the total reward claimed
        if (fee > 0) { want.safeTransfer(treasury, fee); }
    }

    function _compensateDeposit(uint _amount) internal returns (uint) {
        if (offsetRatio <= 0) { return _amount; }

        uint _comp = _amount * offsetRatio / RATIO_PRECISION;

        // Compensate only if we can...
        if (
            want.allowance(equalizer, address(this)) >= _comp &&
            want.balanceOf(equalizer) >= _comp
        ) {
            want.safeTransferFrom(equalizer, address(this), _comp);
            _amount += _comp;
        }

        return _amount;
    }

    function wantBalance() public view returns (uint) {
        return want.balanceOf(address(this));
    }

    function balance() public view returns (uint) {
        return wantBalance() + balanceOfPoolInWant();
    }

    function balanceOfPool() public view virtual returns (uint) {
        // should be implemented
    }

    function balanceOfPoolInWant() public view virtual returns (uint) {
        // should be implemented
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external onlyController {
        if (!paused()) { _pause(); }

        // max withdraw can fail if not staked (in case of panic)
        if (balanceOfPool() > 0) { _withdrawAll(); }

        // Can be called without rewards
        harvest();

        require(balanceOfPool() <= 0, "Strategy still has deposits");
        want.safeTransfer(controller, wantBalance());
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyAdmin nonReentrant {
        _withdrawAll(); // max withdraw
        pause();
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin nonReentrant {
        _unpause();

        _deposit();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";

import "../interfaces/IMasterChef.sol";
import "../interfaces/IUniswapPair.sol";

interface Swapper {
   function lp() external view returns (address);
   function strategy() external view returns (address);
   function swapWantForLpTokens(uint) external returns (uint, uint);
   function swapLpTokensForWant(uint, uint) external returns (uint);
   function lpInWant(uint) external view returns (uint);
   function lpToMinAmounts(uint) external view returns (uint, uint);
   function wantToLP(uint) external view returns (uint);
}

contract ControllerQuickSwapMaiLPStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    address constant public MAI_FARM = address(0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F); // MAI-USDC farm
    address constant public QUICKSWAP_LP = address(0x160532D2536175d65C03B97b0630A9802c274daD); // USDC-MAI
    address constant public TOKEN_0 = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // USDC
    address constant public TOKEN_1 = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1); // MAI

    uint public constant POOL_ID = 1;
    uint public minWantToRedeposit;
    uint public liquidityToleration = 200; // 2%

    Swapper public swapper;

    bool private depositMutex = false;

    constructor(
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury,
        uint _minWantToRedeposit
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {
        minWantToRedeposit = _minWantToRedeposit;
    }

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(want.symbol(), "@QuickSwapMaiLP#1.0.0"));
    }

    function setSwapper(Swapper _swapper) external onlyAdmin {
        require(address(_swapper) != address(0), "!ZeroAddress");
        require(_swapper != swapper, "Same swapper");
        require(_swapper.strategy() == address(this), "Unknown strategy");
        require(_swapper.lp() == QUICKSWAP_LP, "Unknown LP");

        swapper = _swapper;
    }


    function harvest() public nonReentrant override {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewards();

        uint _harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused() && wantBalance() > minWantToRedeposit) {
            _deposit();
        }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), _harvested);
    }

    function setMinWantToRedeposit(uint _minWantToRedeposit) external onlyAdmin {
        require(_minWantToRedeposit != minWantToRedeposit, "Same minimum value");

        minWantToRedeposit = _minWantToRedeposit;
    }

    function setLiquidityToleration(uint _liquidityToleration) external onlyAdmin {
        require(_liquidityToleration != liquidityToleration, "Same toleration");
        require(_liquidityToleration <= RATIO_PRECISION, "Toleration too big!");

        liquidityToleration = _liquidityToleration;
    }

    function balanceOfPool() public view override returns (uint) {
        (uint _amount,) = IMasterChef(MAI_FARM).userInfo(POOL_ID, address(this));

        return _amount;
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return _liquidityInWant(balanceOfPool());
    }

    function _deposit() internal override {
        uint _balance = wantBalance();

        if (_balance > 0) {
            want.safeApprove(address(swapper), _balance);

            (uint _amount0, uint _amount1) = swapper.swapWantForLpTokens(_balance);
            // just in case
            _removeAllowance(address(want), address(swapper));

            _addLiquidity(_amount0, _amount1);
        }

        if (depositMutex) { depositMutex = false; }
    }

    // amount is the want expected to be withdrawn
    function _withdraw(uint _amount) internal override returns (uint) {
        uint _balance = wantBalance();

        if (_balance < _amount) {
            uint _liquidity = swapper.wantToLP(_amount);

            _withdrawFromPool(_liquidity);
            _swapLPTokensForWant();
        }

        uint _withdrawn = wantBalance() - _balance;

        return (_withdrawn > _amount) ? _amount : _withdrawn;
    }

    function _withdrawAll() internal override returns (uint) {
        uint _balance = wantBalance();
        uint _liquidity = balanceOfPool();

        if (_liquidity > 0) {
            _withdrawFromPool(_liquidity);
            _swapLPTokensForWant();
        }

        return wantBalance() - _balance;
    }

    function _claimRewards() internal override {
        // Weird behavior, but this mean "harvest" or "claim".
        IMasterChef(MAI_FARM).deposit(POOL_ID, 0);
    }

    function _addLiquidity(uint _amount0, uint _amount1) internal {
        // Approve only needed amounts
        _approveToken(TOKEN_0, exchange, _amount0);
        _approveToken(TOKEN_1, exchange, _amount1);

        // Add liquidity to the LP
        (, , uint _liquidity) = IUniswapRouter(exchange).addLiquidity(
            TOKEN_0,
            TOKEN_1,
            _amount0,
            _amount1,
            _amount0 * (RATIO_PRECISION - liquidityToleration) / RATIO_PRECISION,
            _amount1 * (RATIO_PRECISION - liquidityToleration) / RATIO_PRECISION,
            address(this),
            block.timestamp + 60
        );

        if (_liquidity > 0) {
            uint _lpLiquidity = IERC20(QUICKSWAP_LP).balanceOf(address(this));

            _approveToken(QUICKSWAP_LP, MAI_FARM, _lpLiquidity);

            // This has a 0.5% of deposit fee
            IMasterChef(MAI_FARM).deposit(POOL_ID, _lpLiquidity);
        }

        _removeAllowance(TOKEN_0, exchange);
        _removeAllowance(TOKEN_1, exchange);

        // Some recursion is needed when swaps required for LP are "not well balanced".
        if (wantBalance() > minWantToRedeposit && !depositMutex) {
            depositMutex = true;

            _deposit();
        }
    }

    function _swapLPTokensForWant() internal {
        uint _liquidity = IERC20(QUICKSWAP_LP).balanceOf(address(this));
        (uint _amount0Min, uint _amount1Min) = swapper.lpToMinAmounts(_liquidity);

        _amount0Min = _amount0Min * (RATIO_PRECISION - liquidityToleration) / RATIO_PRECISION;
        _amount1Min = _amount1Min * (RATIO_PRECISION - liquidityToleration) / RATIO_PRECISION;

        _approveToken(QUICKSWAP_LP, exchange, _liquidity);

        (uint _amount0, uint _amount1) = IUniswapRouter(exchange).removeLiquidity(
            TOKEN_0,
            TOKEN_1,
            _liquidity,
            _amount0Min,
            _amount1Min,
            address(this),
            block.timestamp + 60
        );

        _approveToken(TOKEN_0, address(swapper), _amount0);
        _approveToken(TOKEN_1, address(swapper), _amount1);

        swapper.swapLpTokensForWant(_amount0, _amount1);

        _removeAllowance(TOKEN_0, address(swapper));
        _removeAllowance(TOKEN_1, address(swapper));
    }

    function _withdrawFromPool(uint _liquidity) internal {
        IMasterChef(MAI_FARM).withdraw(POOL_ID, _liquidity);
    }

    function _liquidityInWant(uint _liquidity) internal view returns (uint) {
        if (_liquidity <= 0) { return 0; }

        return swapper.lpInWant(_liquidity);
    }

    function _approveToken(address _token, address _dst, uint _amount) internal {
        IERC20(_token).safeApprove(_dst, _amount);
    }

    function _removeAllowance(address _token, address _dst) internal {
        if (IERC20(_token).allowance(address(this), _dst) > 0) {
            IERC20(_token).safeApprove(_dst, 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";
import "../interfaces/IMStable.sol";

contract ControllerMStableStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    address constant public MTOKEN = address(0xE840B73E5287865EEc17d250bFb1536704B43B21); // mUSD
    address constant public IMTOKEN = address(0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af); // imUSD
    address constant public VAULT = address(0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29); // imUSD Vault

    constructor(
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {}

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(want.symbol(), "@mStable#1.0.0"));
    }

    function harvest() public nonReentrant override {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewards();

        uint harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused()) { _deposit(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), harvested);
    }

    function _deposit() internal override {
        uint wantBal = _compensateDeposit(wantBalance());

        if (wantBal > 0) {
            uint expected = _wantToMusdDoubleCheck(wantBal);

            want.safeApprove(MTOKEN, wantBal);
            IMToken(MTOKEN).mint(address(want), wantBal, expected, address(this));
        }

        uint mBalance = IERC20(MTOKEN).balanceOf(address(this));

        if (mBalance > 0) {
            uint expected = _musdAmountToImusd(mBalance) * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;
            IERC20(MTOKEN).safeApprove(IMTOKEN, mBalance);
            uint credits = IIMToken(IMTOKEN).depositSavings(mBalance);

            require(credits >= expected, "less credits than expected");

            IERC20(IMTOKEN).safeApprove(VAULT, credits);
            IMVault(VAULT).stake(credits);
        }
    }

    function _claimRewards() internal override {
        IMVault(VAULT).claimReward();
    }

    // amount is the `want` expected to be withdrawn
    function _withdraw(uint _amount) internal override returns (uint) {
        uint wantBal = wantBalance();

        _withdrawFromPool(
            _wantToPoolToken(_amount)
        );

        return wantBalance() - wantBal;
    }

    function _withdrawAll() internal override returns (uint) {
        uint wantBal = wantBalance();

        _withdrawFromPool(balanceOfPool());

        return wantBalance() - wantBal;
    }

    function _withdrawFromPool(uint poolTokenAmount) internal {
        // Remove staked from vault
        IMVault(VAULT).withdraw(poolTokenAmount);

        uint _balance = IIMToken(IMTOKEN).balanceOf(address(this));

        require(_balance > 0, "redeem balance = 0");

        uint _amount = _imusdAmountToMusd(_balance);
        uint expected = _amount / WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        IIMToken(IMTOKEN).redeemUnderlying(_amount);
        IMToken(MTOKEN).redeem(address(want), _amount, expected, address(this));
    }

    function _wantToMusdDoubleCheck(uint _amount) internal view returns (uint minOut) {
        if (_amount <= 0) { return 0; }

        minOut = IMToken(MTOKEN).getMintOutput(address(want), _amount);

        // want <=> mUSD is almost 1:1
        uint expected = _amount * WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        if (expected > minOut) { minOut = expected; }
    }

    function balanceOfPool() public view override returns (uint) {
        return IMVault(VAULT).balanceOf(address(this));
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return _musdAmountToWant(
            _imusdAmountToMusd(
                balanceOfPool()
            )
        );
    }

    function _musdAmountToWant(uint _amount) internal view returns (uint) {
        if (_amount <= 0) { return 0; }

        return IMToken(MTOKEN).getRedeemOutput(address(want), _amount);
    }

    function _musdAmountToImusd(uint _amount) internal view returns (uint) {
        return _amount * (10 ** IIMToken(IMTOKEN).decimals()) / IIMToken(IMTOKEN).exchangeRate();
    }

    function _imusdAmountToMusd(uint _amount) internal view returns (uint) {
        return _amount * IIMToken(IMTOKEN).exchangeRate() / (10 ** IIMToken(IMTOKEN).decimals());
    }

    function _wantToPoolToken(uint _amount) internal view returns (uint) {
        return _musdAmountToImusd(
            _wantToMusdDoubleCheck(_amount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMToken is IERC20Metadata {
    function mint(address _input, uint256 _inputQuantity, uint256 _minOutputQuantity, address _recipient) external returns (uint256 mintOutput);
    function getMintOutput(address _input, uint256 _inputQuantity) external view  returns (uint256 mintOutput);
    function redeem(address _output, uint256 _mAssetQuantity, uint256 _minOutputQuantity, address _recipient) external returns (uint256 outputQuantity);
    function getRedeemOutput(address _output, uint256 _mAssetQuantity) external view returns (uint256 bAssetOutput);
}

interface IIMToken is IERC20Metadata {
    function exchangeRate() external view returns (uint256);
    function depositSavings(uint256 _underlying) external returns (uint256 creditsIssued);
    function redeemUnderlying(uint256 _underlying) external returns (uint256 creditsBurned);
}

interface IMVault {
    function balanceOf(address) external view returns (uint256);
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claimReward() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

import "./Swappable.sol";
import "../interfaces/IAave.sol";
import "../interfaces/IDataProvider.sol";

// Swappable contract has the AccessControl module
contract ControllerAaveStrat is Pausable, ReentrancyGuard, Swappable {
    using SafeERC20 for IERC20;

    address public constant wNative = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889); // test

    address public immutable want;
    address public immutable aToken;
    address public immutable debtToken;

    // Aave contracts (test addr)
    address public constant DATA_PROVIDER = address(0xFA3bD19110d986c5e5E9DD5F69362d05035D045B);
    address public constant INCENTIVES = address(0xd41aE58e803Edf4304334acCE4DC4Ec34a63C644);
    address public constant POOL = address(0x9198F13B08E299d85E096929fA9781A1E3d5d827);

    // Routes
    address[] public wNativeToWantRoute;

    address public treasury;

    // Profitability vars
    uint public borrowRate;
    uint public borrowRateMax;
    uint public borrowDepth;
    uint public minLeverage;
    uint constant public BORROW_DEPTH_MAX = 10;
    uint constant public INTEREST_RATE_MODE = 2; // variable
    uint constant public MIN_HEALTH_FACTOR = 1.05e18;  // Always at least 1.05 to not enter default like Arg

    // In the case of leverage we should withdraw when the
    // amount to withdraw is 50%
    uint public ratioForFullWithdraw = 5000; // 50%

    // The healthFactor value has the same representation than supply so
    // to do the math we should remove 12 places from healthFactor to get a HF
    // with only 6 "decimals" and add 6 "decimals" to supply to divide like we do IRL.
    uint public constant HF_DECIMAL_FACTOR = 1e6;
    uint public constant HF_WITHDRAW_TOLERANCE = 0.05e6;

    // Fees
    uint constant public MAX_PERFORMANCE_FEE = 2000; // 20% max
    uint public performanceFee = 450; // 4.5%
    uint internal lastBalance;

    address public exchange;
    address public immutable controller;

    constructor(
        address _want,
        uint _borrowRate,
        uint _borrowRateMax,
        uint _borrowDepth,
        uint _minLeverage,
        address _controller,
        address _exchange,
        address _treasury
    ) {
        require(_want != address(0), "want !ZeroAddress");
        require(_controller != address(0), "Controller !ZeroAddress");
        require(_treasury != address(0), "Treasury !ZeroAddress");
        require(_borrowRate <= _borrowRateMax, "!Borrow <= MaxBorrow");
        require(_borrowRateMax <= RATIO_PRECISION, "!MaxBorrow <= 100%");

        want = _want;
        borrowRate = _borrowRate;
        borrowRateMax = _borrowRateMax;
        borrowDepth = _borrowDepth;
        minLeverage = _minLeverage;
        controller = _controller;
        exchange = _exchange;
        treasury = _treasury;

        (aToken,,debtToken) = IDataProvider(DATA_PROVIDER).getReserveTokensAddresses(_want);

        wNativeToWantRoute = [wNative, _want];

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    event NewTreasury(address oldTreasury, address newTreasury);
    event NewExchange(address oldExchange, address newExchange);
    event NewPerformanceFee(uint oldFee, uint newFee);
    event Harvested(address _want, uint _amount);
    event PerformanceFee(uint _amount);

    modifier onlyController() {
        require(msg.sender == controller, "Not from controller");
        _;
    }

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(
            IERC20Metadata(want).symbol(), "@AaveV2#1.0.0"
        ));
    }

    function setTreasury(address _treasury) external onlyAdmin nonReentrant {
        require(_treasury != treasury, "Same address");
        require(_treasury != address(0), "!ZeroAddress");
        emit NewTreasury(treasury, _treasury);

        treasury = _treasury;
    }

    function setExchange(address _exchange) external onlyAdmin nonReentrant {
        require(_exchange != exchange, "Same address");
        require(_exchange != address(0), "!ZeroAddress");
        emit NewExchange(exchange, _exchange);

        exchange = _exchange;
    }

    function setSwapRoute(address[] calldata _route) external onlyAdmin nonReentrant {
        require(_route[0] == wNative, "route[0] isn't wNative");
        require(_route[_route.length - 1] == want, "Last route isn't want");
        wNativeToWantRoute = _route;
    }

    function setRatioForFullWithdraw(uint _ratio) public onlyAdmin {
        require(_ratio != ratioForFullWithdraw, "Same ratio");
        require(_ratio <= RATIO_PRECISION, "Can't be more than 100%");
        ratioForFullWithdraw = _ratio;
    }

    function setPerformanceFee(uint _fee) external onlyAdmin nonReentrant {
        require(_fee != performanceFee, "Same fee");
        require(_fee <= MAX_PERFORMANCE_FEE, "Can't be greater than max");
        emit NewPerformanceFee(performanceFee, _fee);

        performanceFee = _fee;
    }

    // Charge want auto-generation with performanceFee
    // Basically we assign `lastBalance` each time that we charge or make a movement
    function beforeMovement() external onlyController nonReentrant {
        _beforeMovement();
    }

    function _beforeMovement() internal {
        uint currentBalance = balance();

        if (currentBalance > lastBalance) {
            uint perfFee = ((currentBalance - lastBalance) * performanceFee) / RATIO_PRECISION;

            if (perfFee > 0) {
                uint _balance = wantBalance();

                if (_balance < perfFee) {
                    uint _diff = perfFee - _balance;

                    // Call partial because this fee should never be a big amount
                    _partialDeleverage(_diff);
                }

                // Just in case
                _balance = wantBalance();
                if (_balance < perfFee) { perfFee = _balance; }

                if (perfFee > 0) {
                    IERC20(want).safeTransfer(treasury, perfFee);
                    emit PerformanceFee(perfFee);
                }
            }
        }
    }

    // Update new `lastBalance` for the next charge
    function _afterMovement() internal {
        lastBalance = balance();
    }

    function deposit() external whenNotPaused onlyController nonReentrant {
        _leverage();
        _afterMovement();
    }

    function withdraw(uint _amount) external onlyController nonReentrant returns (uint) {
        uint _balance = wantBalance();

        if (_balance < _amount) {
            uint _diff = _amount - _balance;

            // If the amount is at least the half of the real deposit
            // we have to do a full deleverage, in other case the withdraw+repay
            // will looping for ever.
            if ((balanceOfPool() * ratioForFullWithdraw / RATIO_PRECISION) <= _diff) {
                _fullDeleverage();
            } else {
                _partialDeleverage(_diff);
            }

           _balance =  wantBalance();
           if (_balance < _amount) { _amount = _balance; }
        }

        IERC20(want).safeTransfer(controller, _amount);

        if (!paused() && wantBalance() > 0) { _leverage(); }

        _afterMovement();

        return _amount;
    }

    function _leverage() internal {
        uint _amount = wantBalance();

        IERC20(want).safeApprove(POOL, _amount);
        IAaveLendingPool(POOL).deposit(want, _amount, address(this), 0);

        if (_amount < minLeverage) { return; }

        // Borrow & deposit strategy
        for (uint i = 0; i < borrowDepth; i++) {
            _amount = (_amount * borrowRate) / RATIO_PRECISION;

            IAaveLendingPool(POOL).borrow(want, _amount, INTEREST_RATE_MODE, 0, address(this));
            IERC20(want).safeApprove(POOL, _amount);
            IAaveLendingPool(POOL).deposit(want, _amount, address(this), 0);

            if (_amount < minLeverage || _outOfGasForLoop()) { break; }
        }
    }

    function _fullDeleverage() internal {
        (uint supplyBal, uint borrowBal) = supplyAndBorrow();
        uint toWithdraw;
        uint toRepay;

        while (borrowBal > 0) {
            toWithdraw = _maxWithdrawFromSupply(supplyBal);

            IAaveLendingPool(POOL).withdraw(want, toWithdraw, address(this));

            // This is made mainly for the approve != 0
            toRepay = toWithdraw;
            if (toWithdraw > borrowBal) { toRepay = borrowBal; }

            IERC20(want).safeApprove(POOL, toRepay);
            // Repay only will use the needed
            IAaveLendingPool(POOL).repay(want, toRepay, INTEREST_RATE_MODE, address(this));

            (supplyBal, borrowBal) = supplyAndBorrow();
        }

        if (supplyBal > 0) {
            IAaveLendingPool(POOL).withdraw(want, type(uint).max, address(this));
        }
    }

    function _partialDeleverage(uint _needed) internal {
        // Instead of a require() to raise an exception, the fullDeleverage should
        // fix the health factor
        if (currentHealthFactor() <= MIN_HEALTH_FACTOR) {
            _fullDeleverage();

            return;
        }

        // This is because we check the wantBalance in each iteration
        // but for partialDeleverage we need to withdraw the entire
        // _needed amount
        uint toWithdraw = wantBalance() + _needed;

        while (toWithdraw > wantBalance()) { _withdrawAndRepay(toWithdraw); }
    }

    function _withdrawAndRepay(uint _needed) internal {
        (uint supplyBal, uint borrowBal) = supplyAndBorrow();
        // This amount with borrowDepth = 0 will return the entire deposit
        uint toWithdraw = _maxWithdrawFromSupply(supplyBal);

        if (toWithdraw > _needed) { toWithdraw = _needed; }

        IAaveLendingPool(POOL).withdraw(want, toWithdraw, address(this));

        // for depth > 0
        if (borrowBal > 0) {
            // Only repay the just amount
            uint toRepay = (toWithdraw * borrowRate) / RATIO_PRECISION;
            if (toRepay > borrowBal) { toRepay = borrowBal; }

            // In case the toWithdraw is really low it fails to repay 0
            if (toRepay > 0) {
                IERC20(want).safeApprove(POOL, toRepay);
                IAaveLendingPool(POOL).repay(want, toRepay, INTEREST_RATE_MODE, address(this));
            }
        }
    }

    // This function is useful to increase Aave HF (to prevent liquidation) and
    // in case of "stucked while loop for withdraws" the strategy can be paused, and then
    // use this function the N needed times to get all the resources out of the Aave pool
    function increaseHealthFactor(uint byRatio) external onlyAdmin nonReentrant {
        require(byRatio <= RATIO_PRECISION, "Can't be more than 100%");
        (uint supplyBal, uint borrowBal) = supplyAndBorrow();

        uint toWithdraw = (_maxWithdrawFromSupply(supplyBal) * byRatio) / RATIO_PRECISION;

        IAaveLendingPool(POOL).withdraw(want, toWithdraw, address(this));

        //  just in case
        if (borrowBal > 0) {
            uint toRepay = toWithdraw;
            if (toWithdraw > borrowBal) { toRepay = borrowBal; }

            IERC20(want).safeApprove(POOL, toRepay);
            IAaveLendingPool(POOL).repay(want, toRepay, INTEREST_RATE_MODE, address(this));
        }
    }

    function rebalance(uint _borrowRate, uint _borrowDepth) external onlyAdmin nonReentrant {
        require(_borrowRate <= borrowRateMax, "Exceeds max borrow rate");
        require(_borrowDepth <= BORROW_DEPTH_MAX, "Exceeds max borrow depth");

        _fullDeleverage();

        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;

        if (!paused() && wantBalance() > 0) { _leverage(); }
    }

    // Divide the supply with HF less 0.5 to finish at least with HF~=1.05
    function _maxWithdrawFromSupply(uint _supply) internal view returns (uint) {
        // The healthFactor value has the same representation than supply so
        // to do the math we should remove 12 places from healthFactor to get a HF
        // with only 6 "decimals" and add 6 "decimals" to supply to divide like we do IRL.
        uint hfDecimals = 1e18 / HF_DECIMAL_FACTOR;

        return _supply - (
            (_supply * HF_DECIMAL_FACTOR) / ((currentHealthFactor() / hfDecimals) - HF_WITHDRAW_TOLERANCE)
        );
    }

    function wantBalance() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balance() public view returns (uint) {
        return wantBalance() + balanceOfPool();
    }

    // it calculates how much 'want' the strategy has working in the controller.
    function balanceOfPool() public view returns (uint) {
        (uint supplyBal, uint borrowBal) = supplyAndBorrow();
        return supplyBal - borrowBal;
    }

    function _claimRewards() internal {
        // Incentive controller only receive aToken addresses
        address[] memory assets = new address[](2);
        assets[0] = aToken;
        assets[1] = debtToken;

        IAaveIncentivesController(INCENTIVES).claimRewards(
            assets, type(uint).max, address(this)
        );
    }

    function harvest() public nonReentrant {
        uint _balance = balance();
        _claimRewards();

        // only need swap when is different =)
        if (want != wNative) { _swapRewards(); }

        uint harvested = balance() - _balance;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused() && wantBalance() > 0) { _leverage(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(want, harvested);
    }

    function _swapRewards() internal {
        uint _balance = IERC20(wNative).balanceOf(address(this));

        if (_balance > 0) {
            // _expectedForSwap checks with oracles to obtain the minExpected amount
            uint expected = _expectedForSwap(_balance, wNative, want);

            IERC20(wNative).safeApprove(exchange, _balance);
            IUniswapRouter(exchange).swapExactTokensForTokens(
                _balance, expected, wNativeToWantRoute, address(this), block.timestamp + 60
            );
        }
    }

    /**
     * @dev Takes out performance fee.
     */
    function _chargeFees(uint _harvested) internal {
        uint fee = (_harvested * performanceFee) / RATIO_PRECISION;

        // Pay to treasury a percentage of the total reward claimed
        if (fee > 0) { IERC20(want).safeTransfer(treasury, fee); }
    }

    function userReserves() public view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    ) {
        return IDataProvider(DATA_PROVIDER).getUserReserveData(want, address(this));
    }

    function supplyAndBorrow() public view returns (uint, uint) {
        (uint supplyBal,,uint borrowBal,,,,,,) = userReserves();
        return (supplyBal, borrowBal);
    }

    // returns the user account data across all the reserves
    function userAccountData() public view returns (
        uint totalCollateralETH,
        uint totalDebtETH,
        uint availableBorrowsETH,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor
    ) {
        return IAaveLendingPool(POOL).getUserAccountData(address(this));
    }

    function currentHealthFactor() public view returns (uint) {
        (,,,,, uint healthFactor) = userAccountData();

        return healthFactor;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external onlyController {
        if (!paused()) { _pause(); }

        if (balanceOfPool() > 0) { _fullDeleverage(); }

        // Can be called without rewards
        harvest();

        require(balanceOfPool() <= 0, "Strategy still has deposits");
        IERC20(want).safeTransfer(controller, wantBalance());
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyAdmin nonReentrant {
        _fullDeleverage();
        pause();
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin nonReentrant {
        _unpause();

        if (wantBalance() > 0) { _leverage(); }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAaveIncentivesController {
  function claimRewards(
    address[] calldata assets,
    uint amount,
    address to
  ) external returns (uint);
}

interface IAaveLendingPool {
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint amount,
        uint16 indexed referral
    );

    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint amount);

    function deposit(address asset, uint amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint amount, address to) external returns (uint);
    function borrow(address asset, uint amount, uint interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function repay(address asset, uint amount, uint rateMode, address onBehalfOf) external returns (uint);

    function getUserAccountData(address user) external view returns (
        uint totalCollateralETH,
        uint totalDebtETH,
        uint availableBorrowsETH,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IDataProvider {
    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );

    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

import "./PiAdmin.sol";

// "Strategy" that only keeps the LP
contract ControllerLPWithoutStrat is PiAdmin, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable controller; // immutable to prevent anyone to change it and withdraw
    address public immutable want; // LP

    constructor(address _controller, address _lp) {
        require(_controller != address(0), "Controller !ZeroAddress");
        require(_lp != address(0), "want !ZeroAddress");

        controller = _controller;
        want = _lp;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Not from controller");
        _;
    }

    function identifier() external pure returns (string memory) {
        return string("[email protected]#1.0.0");
    }

    // @dev Just receive LPs from Controller
    function deposit() external whenNotPaused onlyController nonReentrant {
        // This function is ALWAYS called from the Controller and is used just
        // to receive the LPs.
        // As Controller implementation:
        //       want.safeTransfer(strategy, _amount);
        //       IStrategy(strategy).deposit();
        //
        // At the moment we're not investing LPs in any pool. But to keep all the
        // strategies working in the same way we keep deposit/withdraw functions without
        // anything else more than receive and return LPs.
    }

    // @dev Just return LPs to Controller
    function withdraw(uint _amount) external onlyController nonReentrant returns (uint) {
        IERC20(want).safeTransfer(controller, _amount);

        return _amount;
    }

    // @dev Just to be called from Controller for compatibility
    function beforeMovement() external nonReentrant { }

    function wantBalance() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    function balance() public view returns (uint) {
        return wantBalance();
    }
    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external onlyController {
        _pause();

        IERC20(want).safeTransfer(controller, wantBalance());
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin nonReentrant {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveRewardsGaugeMock {
    using SafeERC20 for IERC20;

    IERC20 crvToken;
    IERC20 WMATIC = IERC20(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    IERC20 CRV = IERC20(0x40bde52e6B80Ae11F34C58c14E1E7fE1f9c834C4);

    mapping(address => mapping(address => uint)) private claimable;
    mapping(address => uint) private counter;
    address[] private holders;
    address[] private claimers;

    constructor(address _crvToken) {
        crvToken = IERC20(_crvToken);
    }

    function setClaimable(address _token, address _wallet, uint _amount) external {
        claimable[_token][_wallet] += _amount;
        claimers.push(_wallet);
    }

    function reset() public {
        WMATIC.transfer(address(1), WMATIC.balanceOf(address(this)));
        CRV.transfer(address(1), CRV.balanceOf(address(this)));

        for (uint i; i < holders.length; i++) {
            counter[holders[i]] = 0;
        }

        for (uint i; i < claimers.length; i++) {
            claimable[address(CRV)][claimers[i]] = 0;
            claimable[address(WMATIC)][claimers[i]] = 0;
        }
    }

    function balanceOf(address account) public view returns (uint) {
        return counter[account];
    }

    function claimable_tokens(address wallet) public view returns (uint) {
        return claimable[address(CRV)][wallet];
    }

    function claimable_reward(address _wallet) external view returns (uint) {
        return claimable[address(CRV)][_wallet] + claimable[address(WMATIC)][_wallet];
    }

    function claimable_reward(address _wallet, address _token) external view returns (uint) {
        return claimable[_token][_wallet];
    }

    function reward_count() public pure returns (uint) {
        return 1;
    }

    function reward_tokens(uint) public view returns (address) {
        return address(WMATIC);
    }

    function claim_rewards() external {
        uint _claimable = claimable[address(WMATIC)][msg.sender];

        if (WMATIC.balanceOf(address(this)) > 0 && _claimable > 0) {
            WMATIC.safeTransfer(msg.sender, _claimable);
            claimable[address(WMATIC)][msg.sender] = 0;
        }
    }

    function claimed(address _wallet) external {
        claimable[address(CRV)][_wallet] = 0;
    }

    function deposit(uint _value) external {
        crvToken.safeTransferFrom(msg.sender, address(this), _value);
        counter[msg.sender] += _value;
        holders.push(msg.sender);
    }

    function withdraw(uint _value) external {
        crvToken.safeTransfer(msg.sender, _value);

        counter[msg.sender] -= _value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurvePoolMock is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address private gauge;
    address[] private tokens;

    constructor(
        address _token,
        address _gauge,
        address[] memory _coins,
        string memory _name
    ) ERC20(_name, _name) {
        token  = IERC20(_token);
        gauge  = _gauge;
        tokens = _coins;
    }

    function underlying_coins(int128 i) external view returns (address) {
        return tokens[uint(int256(i))];
    }

    function setGauge(address _gauge) public {
        gauge = _gauge;
    }

    function reset() public {
        _burn(gauge, balanceOf(gauge));
        token.transfer(address(1), token.balanceOf(address(this)));
    }

    function mint(uint _amount) public {
        _mint(msg.sender, _amount);
    }

    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount, bool /* _use_underlying */) external {
        token.safeTransferFrom(msg.sender, address(this), amounts[0]);
        _mint(msg.sender, min_mint_amount);
    }

    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external {
        token.safeTransferFrom(msg.sender, address(this), amounts[0]);
        _mint(msg.sender, min_mint_amount);
    }

    function remove_liquidity_one_coin(uint _token_amount, int128 /* i */, uint _min_amount, bool /* _use_underlying */) external returns (uint) {
        _burn(msg.sender, _token_amount);

        token.transfer(msg.sender, _min_amount);
        return _min_amount;
    }

    function calc_withdraw_one_coin(uint _token_amount, int128 /* i */) external view returns (uint) {
        return _token_amount / 10 ** (18 - IERC20Metadata(address(token)).decimals());
    }

    function calc_token_amount(uint[2] calldata _amounts, bool /* is_deposit */) external view returns (uint) {
        return _amounts[0] * 10 ** (18 - IERC20Metadata(address(token)).decimals());
    }

    function calc_token_amount(uint[4] calldata _amounts, bool /* is_deposit */) external pure returns (uint) {
        return _amounts[0];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenMock is ERC20 {
    uint8 private _decimals = 18;

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }

    function setDecimals(uint8 newDecimals) external {
        _decimals = newDecimals;
    }

    function decimals() override public view returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDMMRouter {
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] memory vReserveRatioBounds,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        IERC20 token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] memory vReserveRatioBounds,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        IERC20 token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory poolsPath,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory poolsPath,
        IERC20[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata poolsPath,
        IERC20[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IJarvisPool.sol";
import "../interfaces/IUniswapRouter.sol";
import "../interfaces/IDMMRouter.sol";

contract ControllerJarvisStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;


    address constant public AG_DENARIUS = address(0xbAbC2dE9cE26a5674F8da84381e2f06e1Ee017A1);
    address constant public AGEURCRV = address(0x81212149b983602474fcD0943E202f38b38d7484); // same than CurvePool
    address constant public CURVE_POOL = address(0x81212149b983602474fcD0943E202f38b38d7484); // agEUR+4eur-f
    address constant public REWARDS_STORAGE = address(0x7c22801057be8392a25D5Ad9490959BCF51F18f2); // AerariumSanctius contract
    address constant public JARVIS_POOL = address(0x1Dc366c5aC2f3Ac16af20212B46cDC0c92235A20); // ElysianFields contract

    uint constant public JARVIS_POOL_ID = 0; // agDenarius agEUR+4eur-f pool

    constructor(address _controller, address _exchange, address _kyberExchange, address _treasury)
        ControllerStratAbs(
            IERC20Metadata(0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4), // agEUR
            _controller,
            _exchange,
            _treasury
        ) {
            require(_kyberExchange != address(0), "Kyber exchange !ZeroAddress");

            kyberExchange = _kyberExchange;
        }

    function identifier() external pure returns (string memory) {
        return string("[email protected]#1.0.0");
    }

    function _deposit() internal override {
        // if pool is ended we shouldn't deposit
        if (IJarvisPool(JARVIS_POOL).endBlock() <= block.number) { return; }

        uint wantBal = wantBalance();

        if (wantBal > 0) {
            uint[2] memory amounts = [wantBal, 0];
            uint agEurCrvAmount = _agEurToAgEurCrvDoubleCheck(wantBal, true);

            want.safeApprove(CURVE_POOL, wantBal);
            ICurvePool(CURVE_POOL).add_liquidity(amounts, agEurCrvAmount);
        }

        uint _agEurCRVBalance = agEurCRVBalance();

        if (_agEurCRVBalance > 0) {
            IERC20(AGEURCRV).safeApprove(JARVIS_POOL, _agEurCRVBalance);
            IJarvisPool(JARVIS_POOL).deposit(JARVIS_POOL_ID, _agEurCRVBalance);
        }
    }

    function _withdraw(uint _amount) internal override returns (uint) {
        uint _balance = wantBalance();

        if (_balance < _amount) {
            _withdrawFromPool(
                _agEurToAgEurCrvDoubleCheck(_amount - _balance, false)
            );
        }

        uint withdrawn = wantBalance() - _balance;

        return (withdrawn > _amount) ? _amount : withdrawn;
    }

    function _withdrawAll() internal override returns (uint) {
        uint _balance = wantBalance();

        _withdrawFromPool(balanceOfPool());

        return wantBalance() - _balance;
    }

    function _withdrawFromPool(uint agEurCrvAmount) internal {
        // Remove staked from pool
        IJarvisPool(JARVIS_POOL).withdraw(JARVIS_POOL_ID, agEurCrvAmount);

        // remove_liquidity
        uint _balance = agEurCRVBalance();
        uint expected = _agEurCrvToAgEurDoubleCheck(_balance);

        require(expected > 0, "remove_liquidity expected = 0");

        ICurvePool(CURVE_POOL).remove_liquidity_one_coin(_balance, 0,  expected);
    }

    function harvest() public nonReentrant override {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewardsOnKyber(); // should be called before common swap
        _swapRewards();

        uint harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused() && wantBalance() > 0) { _deposit(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), harvested);
    }

    function _claimRewards() internal override {
        uint pending = IJarvisPool(JARVIS_POOL).pendingRwd(JARVIS_POOL_ID, address(this));

        if (pending > 0) {
            IJarvisPool(JARVIS_POOL).deposit(JARVIS_POOL_ID, 0);
        }

        // If the endBlock is reached we burn all the AG_DENARIUS tokens to get rewards
        if (IJarvisPool(JARVIS_POOL).endBlock() <= block.number) {
            uint bal = IERC20(AG_DENARIUS).balanceOf(address(this));

            if (bal > 0) {
                IERC20(AG_DENARIUS).safeApprove(REWARDS_STORAGE, bal);
                IJarvisRewards(REWARDS_STORAGE).claim(bal);
            }
        }
    }

    // Kyber doesn't solve all the tokens so we only use it when needed
    // like agDEN => USDC and then the USDC => want is swapped on
    // a regular exchange
    function _swapRewardsOnKyber() internal {
        for (uint i = 0; i < kyberRewards.length; i++) {
            address _rewardToken = kyberRewards[i];

            // just in case
            if (kyberRewardRoute[_rewardToken][0] != address(0) && kyberRewardPathRoute[_rewardToken][0] != address(0)) {
                uint _balance = IERC20(_rewardToken).balanceOf(address(this));

                if (_balance > 0) {
                    address _pseudoWant =                         kyberRewardRoute[_rewardToken][kyberRewardRoute[_rewardToken].length - 1];
                    uint expected = _expectedForSwap(
                        _balance, _rewardToken, _pseudoWant
                    );

                    if (expected > 1) {
                        IERC20(_rewardToken).safeApprove(kyberExchange, _balance);

                        IDMMRouter(kyberExchange).swapExactTokensForTokens(
                            _balance,
                            expected,
                            kyberRewardPathRoute[_rewardToken],
                            kyberRewardRoute[_rewardToken],
                            address(this),
                            block.timestamp + 60
                        );
                    }
                }
            }
        }
    }

    function _swapRewards() internal override {
        for (uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint _balance = IERC20(rewardToken).balanceOf(address(this));

            if (_balance > 0) {
                address _pseudoWant = rewardToWantRoute[rewardToken][rewardToWantRoute[rewardToken].length - 1];
                uint expected = _expectedForSwap(_balance, rewardToken, _pseudoWant);
                // Want price sometimes is too high so it requires a lot of rewards to swap
                if (expected > 1) {
                    address _rewardExchange = exchange;

                    if (rewardExchange[rewardToken] != address(0)) {
                        _rewardExchange = rewardExchange[rewardToken];
                    }

                    IERC20(rewardToken).safeApprove(_rewardExchange, _balance);
                    IUniswapRouter(_rewardExchange).swapExactTokensForTokens(
                        _balance, expected, rewardToWantRoute[rewardToken], address(this), block.timestamp + 60
                    );
                }
            }
        }
    }

    function _minAgEurToAgEurCrv(uint _amount) internal view returns (uint) {
        // Based on virtual_price (poolMinVirtualPrice) and poolSlippageRatio
        // the expected amount is represented with 18 decimals as crvAgEur token
        // so we have to add 10 decimals to the agEur balance.
        // E.g. 1e8 (1AGEUR) * 1e10 * 99.4 / 100.0 => 0.994e18 AGEURCRV tokens
        return _amount * WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio - poolMinVirtualPrice) / RATIO_PRECISION;
    }

    function _agEurToAgEurCrvDoubleCheck(uint _amount, bool _isDeposit) internal view returns (uint agEurCrvAmount) {
        uint[2] memory amounts = [_amount, 0];
        // calc_token_amount doesn't consider fee
        agEurCrvAmount = ICurvePool(CURVE_POOL).calc_token_amount(amounts, _isDeposit);
        // Remove max fee
        agEurCrvAmount = agEurCrvAmount * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        // In case the pool is unbalanced (attack), make a double check for
        // the expected amount with minExpected set ratios.
        uint agEurToAgEurCrv = _minAgEurToAgEurCrv(_amount);

        if (agEurToAgEurCrv > agEurCrvAmount) { agEurCrvAmount = agEurToAgEurCrv; }
    }

    // Calculate at least xx% of the expected. The function doesn't
    // consider the fee.
    function _agEurCrvToAgEurDoubleCheck(uint _balance) internal view returns (uint expected) {
        expected = (
            _calc_withdraw_one_coin(_balance) * (RATIO_PRECISION - poolSlippageRatio)
        ) / RATIO_PRECISION;

        // Double check for expected value
        // In this case we sum the poolMinVirtualPrice and divide by 1e10 because we want to swap AGEURCRV => agEUR
        uint minExpected = _balance *
            (RATIO_PRECISION + poolMinVirtualPrice - poolSlippageRatio) /
            RATIO_PRECISION /
            WANT_MISSING_PRECISION;

        if (minExpected > expected) { expected = minExpected; }
    }

    function _calc_withdraw_one_coin(uint _amount) internal view returns (uint) {
        if (_amount > 0) {
            return ICurvePool(CURVE_POOL).calc_withdraw_one_coin(_amount, 0);
        } else {
            return 0;
        }
    }

    function agEurCRVBalance() public view returns (uint) {
        return IERC20(AGEURCRV).balanceOf(address(this));
    }

    function balanceOfPool() public view override returns (uint) {
        (uint256 _amount,) = IJarvisPool(JARVIS_POOL).userInfo(JARVIS_POOL_ID, address(this));

        return _amount;
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return _calc_withdraw_one_coin(balanceOfPool());
    }

    // Kyber to be extract
    mapping(address => address[]) public kyberRewardPathRoute;
    mapping(address => address[]) public kyberRewardRoute;
    address public kyberExchange;
    address[] public kyberRewards;

    mapping(address => address) public rewardExchange;


    // This one is a little "hack" to bypass the want validation
    // from `setRewardToWantRoute`
    function setRewardToTokenRoute(address _reward, address[] calldata _route) external onlyAdmin nonReentrant {
        require(_reward != address(0), "!ZeroAddress");
        require(_route[0] == _reward, "First route isn't reward");

        bool newReward = true;
        for (uint i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == _reward) {
                newReward = false;
                break;
            }
        }

        if (newReward) { rewardTokens.push(_reward); }
        rewardToWantRoute[_reward] = _route;
    }

    function setRewardExchange(address _reward, address _exchange) external onlyAdmin nonReentrant {
        require(_exchange != address(0), "!ZeroAddress");
        require(_reward != address(0), "!ZeroAddress");
        require(rewardExchange[_reward] != _exchange, "!ZeroAddress");

        rewardExchange[_reward] = _exchange;
    }

    function setKyberExchange(address _kyberExchange) external onlyAdmin nonReentrant {
        require(_kyberExchange != kyberExchange, "Same address");
        require(_kyberExchange != address(0), "!ZeroAddress");

        kyberExchange = _kyberExchange;
    }

    function setKyberRewardPathRoute(address _reward, address[] calldata _path) external onlyAdmin {
        require(_reward != address(0), "!ZeroAddress");
        require(_path[0] != address(0), "!ZeroAddress path");

        bool newReward = true;
        for (uint i = 0; i < kyberRewards.length; i++) {
            if (kyberRewards[i] == _reward) {
                newReward = false;
                break;
            }
        }

        if (newReward) { kyberRewards.push(_reward); }
        kyberRewardPathRoute[_reward] = _path;
    }

    function setKyberRewardRoute(address _reward, address[] calldata _route) external onlyAdmin {
        require(_reward != address(0), "!ZeroAddress");
        require(_route[0] == _reward, "First route isn't reward");
        require(_route.length > 1, "Can't have less than 2 tokens");

        bool newReward = true;
        for (uint i = 0; i < kyberRewards.length; i++) {
            if (kyberRewards[i] == _reward) {
                newReward = false;
                break;
            }
        }

        if (newReward) { kyberRewards.push(_reward); }
        kyberRewardRoute[_reward] = _route;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ICurvePool {
    // _use_underlying If True, withdraw underlying assets instead of aTokens
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount, bool _use_underlying) external;
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;
    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount, bool _use_underlying) external;
    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount) external returns (uint);
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount, bool _use_underlying) external;
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function calc_token_amount(uint[2] calldata _amounts, bool is_deposit) external view returns (uint);
    function calc_token_amount(uint[4] calldata _amounts, bool is_deposit) external view returns (uint);
    function underlying_coins(int128 i) external view returns (address);
    function underlying_coins(uint256 i) external view returns (address);
}

interface ICurveGauge {
    // This function should be view but it's not defined as view...
    function claimable_tokens(address) external returns (uint);
    function claimable_reward(address _user) external view returns (uint);
    function claimable_reward(address _user, address _reward) external view returns (uint);
    function reward_count() external view returns (uint);
    function reward_tokens(uint) external view returns (address);
    function balanceOf(address account) external view returns (uint);

    function claim_rewards() external;
    function deposit(uint _value) external;
    function withdraw(uint _value) external;
}

interface ICurveGaugeFactory {
    function mint(address _gauge) external;
    function minted(address _arg0, address _arg1) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IJarvisPool {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function pendingRwd(uint256 _pid, address _user) external view returns (uint256);
    function endBlock() external view returns (uint256);
}

interface IJarvisRewards {
    function claim(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ICurve.sol";

interface ICurveMock is ICurveGauge {
    function claimed(address) external;
}

contract CurveGaugeFactoryMock {
    using SafeERC20 for IERC20;

    IERC20 CRV = IERC20(0x40bde52e6B80Ae11F34C58c14E1E7fE1f9c834C4);

    function mint(address _gauge) public {
        uint _Cbalance = CRV.balanceOf(address(this));
        uint _claimable = ICurveGauge(_gauge).claimable_tokens(msg.sender);

        if (_Cbalance > 0 && _claimable > 0) {
            CRV.safeTransfer(msg.sender, _claimable);
            ICurveMock(_gauge).claimed(msg.sender);
        }
    }

    function minted(address, address) public pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";
import "../interfaces/ICurve.sol";

contract ControllerCurveStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable crvToken;
    address public immutable pool;
    address public immutable swapPool;
    ICurveGauge public immutable gauge;
    ICurveGaugeFactory public immutable gaugeFactory;

    int128 private immutable poolSize;
    int128 private immutable tokenIndex; // want token index on the pool

    uint8 private immutable gaugeType;
    uint8 private constant GAUGE_TYPE_STAKING = 0;
    uint8 private constant GAUGE_TYPE_CHILD_STAKING = 1;

    constructor(
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury,
        IERC20Metadata _crvToken,
        address _pool,
        address _swapPool,
        ICurveGauge _gauge,
        ICurveGaugeFactory _gaugeFactory,
        uint8 _gaugeType
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {
        require(_pool != address(0), "pool !ZeroAddress");
        require(_swapPool != address(0), "swapPool !ZeroAddress");
        require(address(_gauge) != address(0), "gauge !ZeroAddress");
        require(address(_gaugeFactory) != address(0), "gaugeFactory !ZeroAddress");
        require(_gaugeType < 2, "gaugeType unknown");

        _checkIERC20(_crvToken, "Invalid crvToken");
        // Check gauge _behaves_ as a gauge
        _gauge.claimable_tokens(address(this));
        // Check gauge factory _behaves_ as a gauge factory
        _gaugeFactory.minted(address(this), address(this));

        crvToken = _crvToken;
        pool = _pool;
        swapPool = _swapPool;
        gauge = _gauge;
        gaugeFactory = _gaugeFactory;
        gaugeType = _gaugeType;

        (int128 _poolSize, bool _int128) = _guessPoolSize();

        require(_poolSize > 0, "poolSize is zero");

        int128 _index = _guessTokenIndex(_poolSize, _int128);

        require(_index < _poolSize, "Index out of bounds");

        poolSize = _poolSize;
        tokenIndex = _index;
    }

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(want.symbol(), "@Curve#1.0.0"));
    }

    function wantCRVBalance() public view returns (uint) {
        return crvToken.balanceOf(address(this));
    }

    function balanceOfPool() public view override returns (uint) {
        return gauge.balanceOf(address(this));
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return _calcWithdrawOneCoin(balanceOfPool());
    }

    function _deposit() internal override {
        uint _wantBal = wantBalance();

        if (_wantBal > 0) {
            _addLiquidity(_wantBal);
        }

        uint _wantCRVBalance = wantCRVBalance();

        if (_wantCRVBalance > 0) {
            crvToken.safeApprove(address(gauge), _wantCRVBalance);
            gauge.deposit(_wantCRVBalance);
        }
    }

    function _addLiquidity(uint _wantBal) internal {
        uint _expected = _wantToWantCrvDoubleCheck(_wantBal, true);

        if (poolSize == 2) {
            uint[2] memory _amounts;

            _amounts[uint(uint128(tokenIndex))] = _wantBal;

            want.safeApprove(pool, _wantBal);
            ICurvePool(pool).add_liquidity(_amounts, _expected, true);
        } else if (poolSize == 4) {
            uint[4] memory _amounts;

            _amounts[uint(uint128(tokenIndex))] = _wantBal;

            want.safeApprove(pool, _wantBal);
            ICurvePool(pool).add_liquidity(_amounts, _expected);
        }
    }

    function _withdraw(uint _amount) internal override returns (uint) {
        uint _balance = wantBalance();

        _withdrawFromPool(
            _wantToWantCrvDoubleCheck(_amount - _balance, false)
        );

        uint _withdrawn = wantBalance() - _balance;

        return (_withdrawn > _amount) ? _amount : _withdrawn;
    }

    function _withdrawAll() internal override returns (uint) {
        uint _balance = wantBalance();

        _withdrawFromPool(balanceOfPool());

        return wantBalance() - _balance;
    }

    function _withdrawFromPool(uint _wantCrvAmount) internal {
        // Remove staked from gauge
        gauge.withdraw(_wantCrvAmount);

        // remove_liquidity
        uint _balance = wantCRVBalance();
        uint _expected = _wantCrvToWantDoubleCheck(_balance);

        require(_expected > 0, "remove_liquidity expected = 0");

        if (address(pool) != address(swapPool)) {
            crvToken.safeApprove(pool, _balance);
        }

        ICurvePool(pool).remove_liquidity_one_coin(_balance, tokenIndex, _expected, true);
    }

    function _claimRewards() internal override {
        // CRV rewards
        if (gauge.claimable_tokens(address(this)) > 0) {
            gaugeFactory.mint(address(gauge));
        }

        // no-CRV rewards
        bool _claim = false;

        if (gaugeType == GAUGE_TYPE_STAKING) {
            if (gauge.claimable_reward(address(this)) > 0) {
                _claim = true;
            }
        } else if (gaugeType == GAUGE_TYPE_CHILD_STAKING) {
            for (uint i = 0; i < gauge.reward_count(); i++) {
                address _reward = gauge.reward_tokens(i);

                if (gauge.claimable_reward(address(this), _reward) > 0) {
                    _claim = true;
                    break;
                }
            }
        }

        if (_claim) { gauge.claim_rewards(); }
    }

    function _minWantToWantCrv(uint _amount) internal view returns (uint) {
        // Based on virtual_price (poolMinVirtualPrice) and poolSlippageRatio
        // the expected amount is represented with 18 decimals as crvWant token
        // so we have to add 12 decimals (on USDC and USDT for example) to the want balance.
        // E.g. 1e6 (1WANT) * 1e12 * 99.4 / 100.0 => 0.994e18 crvToken tokens
        return _amount * WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio - poolMinVirtualPrice) / RATIO_PRECISION;
    }

    function _wantToWantCrvDoubleCheck(uint _amount, bool _isDeposit) internal view returns (uint _wantCrvAmount) {
        if (poolSize == 2) {
            uint[2] memory _amounts;

            _amounts[uint(uint128(tokenIndex))] = _amount;
            // calc_token_amount doesn't consider fee
            _wantCrvAmount = ICurvePool(swapPool).calc_token_amount(_amounts, _isDeposit);
        } else if (poolSize == 4) {
            uint[4] memory _amounts;

            _amounts[uint(uint128(tokenIndex))] = _amount;
            // calc_token_amount doesn't consider fee
            _wantCrvAmount = ICurvePool(swapPool).calc_token_amount(_amounts, _isDeposit);
        }

        // Remove max fee
        _wantCrvAmount = _wantCrvAmount * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        // In case the pool is unbalanced (attack), make a double check for
        // the expected amount with minExpected set ratios.
        uint _wantToWantCrv = _minWantToWantCrv(_amount);

        if (_wantToWantCrv > _wantCrvAmount) { _wantCrvAmount = _wantToWantCrv; }
    }

    // Calculate at least xx% of the expected. The function doesn't
    // consider the fee.
    function _wantCrvToWantDoubleCheck(uint _balance) internal view returns (uint _expected) {
        _expected = (
            _calcWithdrawOneCoin(_balance) * (RATIO_PRECISION - poolSlippageRatio)
        ) / RATIO_PRECISION;

        // Double check for expected value
        // In this case we sum the poolMinVirtualPrice and divide by
        // (for example) 1e12 because we want to swap crvToken => WANT
        uint _minExpected = _balance *
            (RATIO_PRECISION + poolMinVirtualPrice - poolSlippageRatio) /
            RATIO_PRECISION /
            WANT_MISSING_PRECISION;

        if (_minExpected > _expected) { _expected = _minExpected; }
    }

    function _calcWithdrawOneCoin(uint _amount) internal view returns (uint) {
        if (_amount > 0) {
            return ICurvePool(pool).calc_withdraw_one_coin(_amount, tokenIndex);
        } else {
            return 0;
        }
    }

    // Constructor helper

    function _guessPoolSize() internal view returns (int128 _poolSize, bool _int128) {
        ICurvePool _pool = ICurvePool(pool);
        bool _loop = true;

        _int128 = true;

        while (_loop) {
            try _pool.underlying_coins(_poolSize) returns (address) {
                _poolSize += 1;
            } catch {
                try _pool.underlying_coins(uint256(int256(_poolSize))) returns (address) {
                    _int128 = false;
                    _poolSize += 1;
                } catch {
                    _loop = false;
                }
            }
        }
    }

    function _guessTokenIndex(int128 _poolSize, bool _int128) internal view returns (int128 _index) {
        address _want = address(want);
        ICurvePool _pool = ICurvePool(pool);

        for (_index; _index < _poolSize; _index++) {
            if (_int128) {
                if (_want == _pool.underlying_coins(_index)) { break; }
            } else {
                if (_want == _pool.underlying_coins(uint256(int256(_index)))) { break; }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IArchimedes.sol";
import "../interfaces/IStrategy.sol";

contract Controller is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // Address of Archimedes
    address public immutable archimedes;
    IERC20Metadata public immutable want;

    // Archimedes controller index
    uint public pid = type(uint16).max; // 65535 means unassigned

    address public strategy;
    address public treasury;

    // Fees
    uint constant public RATIO_PRECISION = 10000;
    uint constant public MAX_WITHDRAW_FEE = 100; // 1%
    uint public withdrawFee = 10; // 0.1%

    // Deposit limit a contract can hold
    // This value should be in the same decimal representation as want
    // 0 value means unlimit
    uint public depositLimit;
    uint public userDepositLimit;

    event NewStrategy(address oldStrategy, address newStrategy);
    event NewTreasury(address oldTreasury, address newTreasury);
    event NewDepositLimit(uint oldLimit, uint newLimit);
    event NewUserDepositLimit(uint oldLimit, uint newLimit);

    constructor(
        IERC20Metadata _want,
        address _archimedes,
        address _treasury,
        string memory _shareSymbol
    ) ERC20(_shareSymbol, _shareSymbol) {
        _want.symbol(); // Check that want is at least an ERC20
        require(_want.balanceOf(address(this)) == 0, "Invalid ERC20"); // Check that want is at least an ERC20
        require(_want.allowance(msg.sender, address(this)) == 0, "Invalid ERC20"); // Check that want is at least an ERC20
        require(IArchimedes(_archimedes).piToken() != address(0), "Invalid PiToken on Archimedes");
        require(_treasury != address(0), "Treasury !ZeroAddress");

        want = _want;
        archimedes = _archimedes;
        treasury = _treasury;
    }

    function decimals() override public view returns (uint8) {
        return want.decimals();
    }

    // BeforeTransfer callback to harvest the archimedes rewards for both users
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // ignore mint/burn
        if (from != address(0) && to != address(0) && amount > 0) {
            IArchimedes(archimedes).beforeSharesTransfer(uint(pid), from, to, amount);
        }
    }

    // AferTransfer callback to update the archimedes rewards for both users
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0) && amount > 0) {
            IArchimedes(archimedes).afterSharesTransfer(uint(pid), from, to, amount);
        }
    }

    modifier onlyArchimedes() {
        require(msg.sender == archimedes, "Not from Archimedes");
        _;
    }

    function setPid(uint _pid) external onlyArchimedes returns (uint) {
        require(pid >= type(uint16).max, "pid already assigned");

        pid = _pid;

        return pid;
    }

    function setTreasury(address _treasury) external onlyOwner nonReentrant {
        require(_treasury != treasury, "Same address");
        require(_treasury != address(0), "!ZeroAddress");
        emit NewTreasury(treasury, _treasury);

        treasury = _treasury;
    }

    function setStrategy(address newStrategy) external onlyOwner nonReentrant {
        require(newStrategy != strategy, "Same strategy");
        require(newStrategy != address(0), "!ZeroAddress");
        require(IStrategy(newStrategy).want() == address(want), "Not same want");
        emit NewStrategy(strategy, newStrategy);

        if (strategy != address(0)) {
            IStrategy(strategy).retireStrat();
            require(
                IStrategy(strategy).balance() <= 0,
                "Strategy still has deposits"
            );
        }

        strategy = newStrategy;

        _strategyDeposit();
    }

    function setWithdrawFee(uint _fee) external onlyOwner nonReentrant {
        require(_fee != withdrawFee, "Same fee");
        require(_fee <= MAX_WITHDRAW_FEE, "!cap");

        withdrawFee = _fee;
    }

    function setDepositLimit(uint _amount) external onlyOwner nonReentrant {
        require(_amount != depositLimit, "Same limit");
        require(_amount >= 0, "Can't be negative");

        emit NewDepositLimit(depositLimit, _amount);

        depositLimit = _amount;
    }

    function setUserDepositLimit(uint _amount) external onlyOwner nonReentrant {
        require(_amount != userDepositLimit, "Same limit");
        require(_amount >= 0, "Can't be negative");

        emit NewUserDepositLimit(userDepositLimit, _amount);

        userDepositLimit = _amount;
    }

    function deposit(address _senderUser, uint _amount) external onlyArchimedes nonReentrant {
        require(!_strategyPaused(), "Strategy paused");
        require(_amount > 0, "Insufficient amount");
        _checkDepositLimit(_senderUser, _amount);

        IStrategy(strategy).beforeMovement();

        uint _before = balance();

        want.safeTransferFrom(
            archimedes, // Archimedes
            address(this),
            _amount
        );

        uint _diff = balance() - _before;

        uint shares;
        if (totalSupply() <= 0) {
            shares = _diff;
        } else {
            shares = (_diff * totalSupply()) / _before;
        }

        _mint(_senderUser, shares);

        _strategyDeposit();
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(address _senderUser, uint _shares) external onlyArchimedes nonReentrant returns (uint) {
        require(_shares > 0, "Insufficient shares");
        IStrategy(strategy).beforeMovement();

        // This line has to be calc before burn
        uint _withdraw = (balance() * _shares) / totalSupply();

        _burn(_senderUser, _shares);

        uint _balance = wantBalance();
        uint withdrawn;

        if (_balance < _withdraw) {
            uint _diff = _withdraw - _balance;

            // withdraw will revert if anyything weird happend with the
            // transfer back but just in case we ensure that the withdraw is
            // positive
            withdrawn = IStrategy(strategy).withdraw(_diff);
            require(withdrawn > 0, "Can't withdraw from strategy...");

            _balance = wantBalance();
            if (_balance < _withdraw) { _withdraw = _balance; }
        }

        uint withdrawalFee = _withdraw * withdrawFee / RATIO_PRECISION;
        withdrawn = _withdraw - withdrawalFee;

        want.safeTransfer(archimedes, withdrawn);
        want.safeTransfer(treasury, withdrawalFee);

        if (!_strategyPaused()) { _strategyDeposit(); }

        return withdrawn;
    }

    function _strategyPaused() internal view returns (bool){
        return IStrategy(strategy).paused();
    }

    function strategyBalance() public view returns (uint){
        return IStrategy(strategy).balance();
    }

    function wantBalance() public view returns (uint) {
        return want.balanceOf(address(this));
    }

    function balance() public view returns (uint) {
        return wantBalance() + strategyBalance();
    }

    // Check whats the max available amount to deposit
    function availableDeposit() external view returns (uint _available) {
        if (depositLimit <= 0) { // without limit
            _available = type(uint).max;
        } else if (balance() < depositLimit) {
            _available = depositLimit - balance();
        }
    }

    function availableUserDeposit(address _user) public view returns (uint _available) {
        if (userDepositLimit <= 0) { // without limit
            _available = type(uint).max;
        } else {
            _available = userDepositLimit;
            // if there's no deposit yet, the totalSupply division raise
            if (totalSupply() > 0) {
                // Check the real amount in want for the user
                uint _precision = 10 ** decimals();
                uint _pricePerShare = (balance() * _precision) / totalSupply();
                uint _current = balanceOf(_user) * _pricePerShare / _precision;

                if (_current >= _available) {
                    _available = 0;
                }  else {
                    _available -= _current;
                }
            }
        }
    }

    function _strategyDeposit() internal {
        uint _amount = wantBalance();

        if (_amount > 0) {
            want.safeTransfer(strategy, _amount);

            IStrategy(strategy).deposit();
        }
    }

    function _checkDepositLimit(address _user, uint _amount) internal view {
        // 0 depositLimit means no-limit
        if (depositLimit > 0) {
            require(balance() + _amount <= depositLimit, "Max depositLimit reached");
        }

        if (userDepositLimit > 0) {
            require(_amount <= availableUserDeposit(_user), "Max userDepositLimit reached");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IArchimedes {
    function piToken() external view returns (address);
    function beforeSharesTransfer(uint _pid, address _from, address _to, uint _amount) external;
    function afterSharesTransfer(uint _pid, address _from, address _to, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

import "./PiAdmin.sol";
import { IPiToken } from "../interfaces/IPiToken.sol";

interface IPiVault is IERC20 {
    function deposit(uint amount) external returns (uint);
}

contract Distributor is PiAdmin, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPiVault;

    IPiToken public immutable piToken;
    IPiVault public immutable piVault;

    uint private lastBlock;

    // tokens per investor "ticket"
    uint public constant INVESTOR_PER_BLOCK = 0.04779e18;
    // tokens per founder
    uint public constant FOUNDER_PER_BLOCK = 0.11948e18;
    // tokens for treasury
    uint public constant TREASURY_PER_BLOCK = 0.11948e18;

    address public treasury;

    // investor wallet => investor tickets per block
    mapping(address => uint) public investorTickets;
    uint public constant INVESTORS_TICKETS = 15;
    uint public constant INVESTORS_COUNT = 10;
    address[] public investors = new address[](INVESTORS_COUNT);

    // 3 founders has the same proportion
    uint public constant FOUNDERS_COUNT = 3;
    address[] public founders = new address[](FOUNDERS_COUNT);

    uint public leftTokensForInvestors = 9.42e24; // 9.42M
    uint public leftTokensForFounders  = 9.42e24; // 9.42M
    uint public leftTokensForTreasury  = 1.57e24; // 1.57M

    constructor(address _piToken, address _piVault, address _treasury) {
        piToken = IPiToken(_piToken);
        piVault = IPiVault(_piVault);
        treasury = _treasury;
        lastBlock = _blockNumber();

        // Will be changed for the right wallets before deploy
        founders[0] = address(0x1cC86b9b67C93B8Fa411554DB761f68979E7995A);
        founders[1] = address(0xBF67C362d035e6B6e95C4F254fe359Eea8B8C7ea);
        founders[2] = address(0xc2d2fE7c1aD582723Df08e3e176762f70d7aC7eC);

        investors[0] = address(0x3181893d37BC1F89635B4dDAc5A7424d804FA9c9);
        investors[1] = address(0x610DA3A2b17a0611552E7519b804D2E554CbCE35);
        investors[2] = address(0x713C9aE2D300FE95f9778dC63DdA6B6a64E16474);
        investors[3] = address(0xD5399bE4abD48fBe728E5e20E352633a206Da795);
        investors[4] = address(0x774A1a1546Ff63135414b7394FD50779dfD0296d);
        investors[5] = address(0xc5A094F8AC2c9a51144930565Af590C51F1C1F66);
        investors[6] = address(0xe4eDB9B7b97884f37660b00aDfbB814bD4Bf1d61);
        investors[7] = address(0x75037D275A63f6449bbcAC7e971695696D6C2ce5);
        investors[8] = address(0x21E1A8CE937c0A0382ECebe687e9968c2f51731b);
        investors[9] = address(0x7341Fb8d04BE5FaEFe9152EC8Ca90908deBA1CB6);

        investorTickets[investors[0]] = 4;
        investorTickets[investors[1]] = 2;
        investorTickets[investors[2]] = 2;
        investorTickets[investors[3]] = 1;
        investorTickets[investors[4]] = 1;
        investorTickets[investors[5]] = 1;
        investorTickets[investors[6]] = 1;
        investorTickets[investors[7]] = 1;
        investorTickets[investors[8]] = 1;
        investorTickets[investors[9]] = 1;
    }

    event NewTreasury(address oldTreasury, address newTreasury);
    event InvestorsDistributed(uint amount);
    event FoundersDistributed(uint amount);
    event TreasoryDistributed(uint amount);

    function setTreasury(address _treasury) external onlyAdmin nonReentrant {
        require(_treasury != treasury, "Same address");
        require(_treasury != address(0), "!ZeroAddress");
        emit NewTreasury(treasury, _treasury);

        treasury = _treasury;
    }

    function distribute() external nonReentrant {
        require(_blockNumber() > lastBlock, "Have to wait");
        require(
            leftTokensForInvestors > 0 ||
            leftTokensForFounders > 0 ||
            leftTokensForTreasury > 0,
            "Nothing more to do"
        );

        uint multiplier = _blockNumber() - lastBlock;

        _depositToInvestors(multiplier);
        _depositToFounders(multiplier);
        _transferToTreasury(multiplier);

        lastBlock = _blockNumber();
    }

    function _depositToInvestors(uint multiplier) internal {
        if (leftTokensForInvestors <= 0) { return; }

        uint amount = multiplier * INVESTOR_PER_BLOCK * INVESTORS_TICKETS;

        // Check for limit to mint
        if (amount > leftTokensForInvestors) {
            amount = leftTokensForInvestors;
        }

        leftTokensForInvestors -= amount;

        IERC20(piToken).safeApprove(address(piVault), amount);
        uint shares = piVault.deposit(amount);

        // Calc how many shares correspond to each "ticket"
        uint sharesPerTicket = shares / INVESTORS_TICKETS;

        for (uint i = 0; i < INVESTORS_COUNT; i++) {
            address wallet = investors[i];
            uint _sharesAmount = sharesPerTicket * investorTickets[wallet];

            // send deposited stk2Pi to each investor
            piVault.safeTransfer(wallet, _sharesAmount);
        }

        emit InvestorsDistributed(amount);
    }

    function _depositToFounders(uint multiplier) internal {
        if (leftTokensForFounders <= 0) { return; }

        uint amount = multiplier * FOUNDER_PER_BLOCK * FOUNDERS_COUNT;

        // Check for limit to mint
        if (amount > leftTokensForFounders) {
            amount = leftTokensForFounders;
        }

        leftTokensForFounders -= amount;

        // Calc deposited shares
        IERC20(piToken).safeApprove(address(piVault), amount);
        uint shares = piVault.deposit(amount);

        // Calc how many shares correspond to each founder
        uint sharesPerFounder = shares / FOUNDERS_COUNT;

        for (uint i = 0; i < FOUNDERS_COUNT; i++) {
            // send deposited stk2Pi to each investor
            piVault.safeTransfer(founders[i], sharesPerFounder);
        }

        emit FoundersDistributed(amount);
    }

    function _transferToTreasury(uint multiplier) internal {
        // Just in case of division "rest"
        uint shares = piVault.balanceOf(address(this));
        if (shares > 0) { piVault.safeTransfer(treasury, shares); }

        if (leftTokensForTreasury <= 0) { return; }

        uint amount = multiplier * TREASURY_PER_BLOCK;

        // Check for limit to mint
        if (amount > leftTokensForTreasury) {
            amount = leftTokensForTreasury;
        }

        leftTokensForTreasury -= amount;

        // SuperToken transfer is safe
        piToken.transfer(treasury, amount);

        emit TreasoryDistributed(amount);
    }

    // Only to be mocked
    function _blockNumber() internal view virtual returns (uint) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../Distributor.sol";

contract DistributorMock is Distributor {
    uint private mockedBlockNumber;

    constructor(address _piToken, address _piVault, address _treasury) Distributor(_piToken, _piVault, _treasury) {}

    function setBlockNumber(uint _n) public {
        mockedBlockNumber = _n;
    }

    function _blockNumber() internal view override returns (uint) {
        return mockedBlockNumber == 0 ? block.number : mockedBlockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

import "./Swappable.sol";
import "../interfaces/IPiToken.sol";
import "../interfaces/IController.sol";
import "../interfaces/IReferral.sol";

// Swappable contract has the AccessControl module
contract ArchimedesAPI is Swappable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPiToken;

    address public handler; // 0x640bb21185093058549dFB000D566358dc40C584
    address public exchange;
    mapping(uint => address[]) public piTokenToWantRoute;

    // Info of each pool.
    struct PoolInfo {
        IERC20 want;             // Address of token contract.
        uint weighing;           // How much weighing assigned to this pool. PIes to distribute per block.
        uint lastRewardBlock;    // Last block number that PIes distribution occurs.
        uint accPiTokenPerShare; // Accumulated PIes per share, times SHARE_PRECISION. See below.
        address controller;      // Token controller
    }

    // IPiToken already have safe transfer from SuperToken
    IPiToken public immutable piToken;
    bytes private constant txData = new bytes(0); // just to support SuperToken mint

    // Used to made multiplications and divitions over shares
    uint public constant SHARE_PRECISION = 1e18;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    // Users can't transfer controller's minted tokens
    mapping(uint => mapping(address => uint)) public userPaidRewards;
    // Total weighing. Must be the sum of all pools weighing.
    uint public totalWeighing;
    // The block number when PI mining starts.
    uint public immutable startBlock;

    // PiToken referral contract address.
    IReferral public referralMgr;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 10; // 1%
    // Max referral commission rate: 5%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 50; // 5%
    uint16 public constant COMMISSION_RATE_PRECISION = 1000;

    event Deposit(uint indexed pid, address indexed user, uint amount);
    event Withdraw(uint indexed pid, address indexed user, uint amount);
    event EmergencyWithdraw(uint indexed pid, address indexed user, uint amount);
    event NewPool(uint indexed pid, address want, uint weighing);
    event PoolWeighingUpdated(uint indexed pid, uint oldWeighing, uint newWeighing);
    event Harvested(uint indexed pid, address indexed user, uint amount);
    event NewExchange(address oldExchange, address newExchange);
    event NewHandler(address oldHandler, address newHandler);

    constructor(IPiToken _piToken, uint _startBlock, address _handler) {
        require(address(_piToken) != address(0), "Pi address !ZeroAddress");
        require(_startBlock > _blockNumber(), "StartBlock must be in the future");
        require(_handler != address(0), "Handler !ZeroAddress");

        piToken = _piToken;
        startBlock = _startBlock;
        handler = _handler;
    }

    modifier onlyHandler() {
        require(msg.sender == handler, "Only handler");
        _;
    }

    function setExchange(address _newExchange) external onlyAdmin {
        require(_newExchange != exchange, "Same address");
        require(_newExchange != address(0), "!ZeroAddress");
        emit NewExchange(exchange, _newExchange);
        exchange = _newExchange;
    }

    function setRoute(uint _pid, address[] memory _route) external onlyAdmin {
        // Last address in path should be the same than pool.want
        require(_route[0] == address(piToken), "First token is not PiToken");
        require(_route[_route.length - 1] == address(poolInfo[_pid].want), "Last token is not want");
        require(poolInfo[_pid].controller != address(0), "Unknown pool");

        piTokenToWantRoute[_pid] = _route;
    }

    function setHandler(address _newHandler) external onlyAdmin {
        require(_newHandler != handler, "Same address");
        require(_newHandler != address(0), "!ZeroAddress");
        emit NewHandler(handler, _newHandler);
        handler = _newHandler;
    }

    // Add a new want token to the pool. Can only be called by the admin.
    function addNewPool(IERC20 _want, address _ctroller, uint _weighing, bool _massUpdate) external onlyAdmin {
        require(address(_want) != address(0), "Address zero not allowed");
        require(IController(_ctroller).archimedes() == address(this), "Not an Archimedes controller");
        require(IController(_ctroller).strategy() != address(0), "Controller without strategy");

        // Update pools before a weighing change
        if (_massUpdate) { massUpdatePools(); }

        uint lastRewardBlock = _blockNumber() > startBlock ? _blockNumber() : startBlock;

        totalWeighing += _weighing;

        poolInfo.push(PoolInfo({
            want: _want,
            weighing: _weighing,
            lastRewardBlock: lastRewardBlock,
            accPiTokenPerShare: 0,
            controller: _ctroller
        }));

        uint _pid = poolInfo.length - 1;
        uint _setPid = IController(_ctroller).setPid(_pid);
        require(_pid == _setPid, "Pid doesn't match");

        emit NewPool(_pid, address(_want),  _weighing);
    }

    // Update the given pool's PI rewards weighing
    function changePoolWeighing(uint _pid, uint _weighing, bool _massUpdate) external onlyAdmin {
        emit PoolWeighingUpdated(_pid, poolInfo[_pid].weighing, _weighing);
        // Update pools before a weighing change
        if (_massUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }

        totalWeighing = (totalWeighing - poolInfo[_pid].weighing) + _weighing;
        poolInfo[_pid].weighing = _weighing;
    }

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(uint _from, uint _to) internal pure returns (uint) {
        return _to - _from;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
            if (_outOfGasForLoop()) { break; }
        }
    }

    // Mint api tokens for a given pool pid
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        // If same block as last update return
        if (_blockNumber() <= pool.lastRewardBlock) { return; }
        // If community Mint is already finished
        uint apiLeftToMint = piToken.apiLeftToMint();
        if (apiLeftToMint <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        uint sharesTotal = _controller(_pid).totalSupply();

        if (sharesTotal <= 0 || pool.weighing <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        uint multiplier = _getMultiplier(pool.lastRewardBlock, _blockNumber());
        uint piTokenReward = (multiplier * piTokenPerBlock() * pool.weighing) / totalWeighing;

        // No rewards =( update lastRewardBlock
        if (piTokenReward <= 0) {
            pool.lastRewardBlock = _blockNumber();
            return;
        }

        // If the reward is greater than the left to mint
        if (piTokenReward > apiLeftToMint) {
            piTokenReward = apiLeftToMint;
        }

        piToken.apiMint(address(this), piTokenReward);

        pool.accPiTokenPerShare += (piTokenReward * SHARE_PRECISION) / sharesTotal;
        pool.lastRewardBlock = _blockNumber();
    }

    // Deposit want token to Archimedes for PI allocation.
    function deposit(uint _pid, address _user, uint _amount, address _referrer) external nonReentrant onlyHandler {
        require(_amount > 0, "Insufficient deposit");

        // Update pool rewards
        updatePool(_pid);

        // Record referral if it's needed
        _recordReferral(_pid, _user, _referrer);

        uint _before = _wantBalance(poolInfo[_pid].want);

        // Pay rewards
        _calcPendingAndSwapRewards(_pid, _user);

        // Transfer from user => Archimedes
        // This is the only line that should transfer from msg.sender to Archimedes
        // And in case of swap rewards will be included in the deposit
        poolInfo[_pid].want.safeTransferFrom(msg.sender, address(this), _amount);
        uint _balance = _wantBalance(poolInfo[_pid].want) - _before;

        // Deposit in the controller
        _depositInController(_pid, _user, _balance);
    }

    // Withdraw want token from Archimedes.
    function withdraw(uint _pid, address _user, uint _shares) external nonReentrant onlyHandler {
        require(_shares > 0, "0 shares");
        require(_userShares(_pid, _user) >= _shares, "withdraw: not sufficient founds");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];

        uint _before = _wantBalance(pool.want);

        // Pay rewards
        _calcPendingAndSwapRewards(_pid, _user);

        // this should burn shares and control the amount
        uint withdrawn = _controller(_pid).withdraw(_user, _shares);
        require(withdrawn > 0, "Can't withdraw from controller");

        uint __wantBalance = _wantBalance(pool.want) - _before;

        pool.want.safeTransfer(_user, __wantBalance);

        // This is to "save" like the new amount of shares was paid
        _updateUserPaidRewards(_pid, _user);

        emit Withdraw(_pid, _user, _shares);
    }

    // Claim rewards for a pool
    function harvest(uint _pid, address _user) public nonReentrant {
        if (_userShares(_pid, _user) <= 0) { return; }

        updatePool(_pid);

        uint _before = _wantBalance(poolInfo[_pid].want);

        uint harvested = _calcPendingAndSwapRewards(_pid, _user);

        uint _balance = _wantBalance(poolInfo[_pid].want) - _before;

        if (_balance > 0) {
            _depositInController(_pid, _user, _balance);
        }

        if (harvested > 0) { emit Harvested(_pid, _user, harvested); }
    }

    function harvestAll(address _user) external {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            harvest(pid, _user);
            if (_outOfGasForLoop()) { break; }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid, address _user) external nonReentrant {
        require(msg.sender == _user || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == handler, "Not authorized");
        IERC20 want = poolInfo[_pid].want;

        userPaidRewards[_pid][_user] = 0;

        uint _shares = _userShares(_pid, _user);

        uint _before = _wantBalance(want);
        // this should burn shares and control the amount
        _controller(_pid).withdraw(_user, _shares);

        uint __wantBalance = _wantBalance(want) - _before;
        want.safeTransfer(_user, __wantBalance);

        emit EmergencyWithdraw(_pid, _user, _shares);
    }

    // Controller callback before transfer to harvest users rewards
    function beforeSharesTransfer(uint /*_pid*/, address /*_from*/, address /*_to*/, uint /*amount*/) external pure {
        revert("API shares are handled by handler at the moment");
    }

    // Controller callback after transfer to update users rewards
    function afterSharesTransfer(uint /*_pid*/, address /*_from*/, address /*_to*/, uint /*amount*/) external pure {
        revert("API shares are handled by handler at the moment");
    }

    function _updateUserPaidRewards(uint _pid, address _user) internal {
        userPaidRewards[_pid][_user] = (_userShares(_pid, _user) * poolInfo[_pid].accPiTokenPerShare) / SHARE_PRECISION;
    }

    function _wantBalance(IERC20 _want) internal view returns (uint) {
        return _want.balanceOf(address(this));
    }

    // Record referral in referralMgr contract if needed
    function _recordReferral(uint _pid, address _user, address _referrer) internal {
        // only if it's the first deposit
        if (_userShares(_pid, _user) <= 0 && _referrer != address(0) &&
            _referrer != _user && address(referralMgr) != address(0)) {

            referralMgr.recordReferral(_user, _referrer);
        }
    }

    function _depositInController(uint _pid, address _user, uint _amount) internal {
        // Archimedes => controller transfer & deposit
        poolInfo[_pid].want.safeIncreaseAllowance(poolInfo[_pid].controller, _amount);
        _controller(_pid).deposit(_user, _amount);
        // This is to "save" like the new amount of shares was paid
        _updateUserPaidRewards(_pid, _user);

        emit Deposit(_pid, _user, _amount);
    }

    // Pay rewards
    function _calcPendingAndSwapRewards(uint _pid, address _user) internal returns (uint pending) {
        uint _shares = _userShares(_pid, _user);

        if (_shares > 0) {
            pending = ((_shares * poolInfo[_pid].accPiTokenPerShare) / SHARE_PRECISION) - paidRewards(_pid, _user);

            if (pending > 0) {
                _swapForWant(_pid, pending);
                _payReferralCommission(_pid, _user, pending);
            }
        }
    }

    function _swapForWant(uint _pid, uint _amount) internal returns (uint swapped) {
        uint piTokenBal = piToken.balanceOf(address(this));

        if (_amount > piTokenBal) { _amount = piTokenBal; }

        if (_amount > 0) {
            uint expected = _expectedForSwap(_amount, address(piToken), address(poolInfo[_pid].want));

            require(expected > 0, "Can't swap for 0 tokens");

            piToken.safeApprove(exchange, _amount);
            uint[] memory outAmounts = IUniswapRouter(exchange).swapExactTokensForTokens(
                _amount, expected, piTokenToWantRoute[_pid], address(this), block.timestamp + 60
            );

            // Only last amount is needed
            swapped = outAmounts[outAmounts.length - 1];
        }
    }

    // Update the referral contract address by the admin
    function setReferralAddress(IReferral _newReferral) external onlyAdmin {
        require(_newReferral != referralMgr, "Same Manager");
        require(address(_newReferral) != address(0), "!ZeroAddress");
        referralMgr = _newReferral;
    }

    // Update referral commission rate by the admin
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyAdmin {
        require(_referralCommissionRate != referralCommissionRate, "Same rate");
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "rate greater than MaxCommission");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function _payReferralCommission(uint _pid, address _user, uint _pending) internal {
        if (address(referralMgr) != address(0) && referralCommissionRate > 0) {
            address referrer = referralMgr.getReferrer(_user);

            uint commissionAmount = (_pending * referralCommissionRate) / COMMISSION_RATE_PRECISION;

            if (referrer != address(0) && commissionAmount > 0) {
                // Instead of mint to the user, we call mint, swap and transfer
                uint apiLeftToMint = piToken.apiLeftToMint();
                if (apiLeftToMint < commissionAmount) {
                    commissionAmount = apiLeftToMint;
                }

                if (commissionAmount > 0) {
                    piToken.apiMint(address(this), commissionAmount);

                    uint _reward = _swapForWant(_pid, commissionAmount);

                    poolInfo[_pid].want.safeTransfer(referrer, _reward);

                    referralMgr.referralPaid(referrer, commissionAmount); // sum paid
                }
            }
        }
    }

    // View functions
    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    function _userShares(uint _pid, address _user) internal view returns (uint) {
        return _controller(_pid).balanceOf(_user);
    }

    function paidRewards(uint _pid, address _user) public view returns (uint) {
        return userPaidRewards[_pid][_user];
    }
    function _controller(uint _pid) internal view returns (IController) {
        return IController(poolInfo[_pid].controller);
    }

    // old vault functions
    function getPricePerFullShare(uint _pid) external view returns (uint) {
        uint _totalSupply = _controller(_pid).totalSupply();
        uint precision = 10 ** decimals(_pid);

        return _totalSupply <= 0 ? precision : ((_controller(_pid).balance() * precision) / _totalSupply);
    }
    function decimals(uint _pid) public view returns (uint) {
        return _controller(_pid).decimals();
    }
    function balance(uint _pid) external view returns (uint) {
        return _controller(_pid).balance();
    }
    function balanceOf(uint _pid, address _user) external view returns (uint) {
        return _controller(_pid).balanceOf(_user);
    }

    function piTokenPerBlock() public view returns (uint) {
        // Skip x% of minting per block for Referrals
        uint reserve = COMMISSION_RATE_PRECISION - referralCommissionRate;
        return piToken.apiMintPerBlock() * reserve / COMMISSION_RATE_PRECISION;
    }

    // Only to be mocked
    function _blockNumber() internal view virtual returns (uint) {
        return block.number;
    }

    // In case of stucketd 2Pi tokens after 2 years
    // check if any holder has pending tokens then call this fn
    // E.g. in case of a few EmergencyWithdraw the rewards will be stucked
    function redeemStuckedPiTokens() external onlyAdmin {
        require(piToken.totalSupply() == piToken.MAX_SUPPLY(), "PiToken still minting");
        // 2.5 years (2.5 * 365 * 24 * 3600) / 2.4s per block == 32850000
        require(_blockNumber() > (startBlock + 32850000), "Still waiting");

        uint _balance = piToken.balanceOf(address(this));

        if (_balance > 0) { piToken.safeTransfer(msg.sender, _balance); }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { ArchimedesAPI, IPiToken } from "../ArchimedesAPI.sol";

contract ArchimedesAPIMock is ArchimedesAPI {
    uint private mockedBlockNumber;

    constructor(
        IPiToken _piToken,
        uint _startBlock,
        address _handler
    ) ArchimedesAPI(_piToken, _startBlock, _handler) { }

    function setBlockNumber(uint _n) public {
        mockedBlockNumber = _n;
    }

    function _blockNumber() internal view override returns (uint) {
        return mockedBlockNumber == 0 ? block.number : mockedBlockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC1820Registry } from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "hardhat/console.sol";
import "./PiAdmin.sol";
import "../vendor_contracts/NativeSuperTokenProxy.sol";

contract PiToken is NativeSuperTokenProxy, PiAdmin {
    // mint/burn roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // ERC777 registration in ERC1820
    bytes32 internal constant ERC777Recipient = keccak256("ERC777TokensRecipient");
    IERC1820Registry constant internal _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    uint public constant MAX_SUPPLY = 6.28e25; // (2 * pi) 62.8M tokens
    uint public constant INITIAL_SUPPLY = (
        2512000 +  // Airdrop + incentives 2.512M
         942000 +  // Exchange 942K
        7536000 +  // Future rounds (investors) 7.536M
        9420000 +  // Timelock Founders 9.42M
        9420000 +  // Timelock Investors 9.42M
        1570000    // Timelock Treasury 1.57M
    ) * (10 ** 18);

    // Rates to mint per block
    uint public communityMintPerBlock;
    uint public apiMintPerBlock;

    // Keep track in which block started the current tranche
    uint internal tranchesBlock;

    // Keep track of minted per type for current tranch
    uint internal apiMintedForCurrentTranch;
    uint internal communityMintedForCurrentTranch;
    // Keep track of un-minted per type for old tranches
    uint internal apiReserveFromOldTranches;
    uint internal communityReserveFromOldTranches;

    uint internal API_TYPE = 0;
    uint internal COMMUNITY_TYPE = 1;

    // Events from SuperToken
    // Minted, Burned, Transfer, Sent

    // Should be called from a wallet
    function init() external onlyAdmin {
        require(_self().totalSupply() <= 0, "Already initialized");

        _self().initialize(IERC20(address(0x0)), 18, '2Pi', '2Pi');

        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            ERC777Recipient,
            address(this)
        );

        _self().selfMint(msg.sender, INITIAL_SUPPLY, abi.encodePacked(keccak256("Tokens for INITIAL SUPPLY")));
    }

    function addMinter(address newMinter) external onlyAdmin {
        _setupRole(MINTER_ROLE, newMinter);
    }

    function initRewardsOn(uint __blockNumber) external onlyAdmin {
        require(tranchesBlock <= 0, "Already set");
        tranchesBlock = __blockNumber;
    }

    // Before change api or community RatePerBlock or before mintForMultiChain is called
    // Calculate and accumulate the un-minted amounts.
    function _beforeChangeMintRate() internal {
        if (tranchesBlock > 0 && _blockNumber() > tranchesBlock && (apiMintPerBlock > 0 || communityMintPerBlock > 0)) {
            // Accumulate both proportions to keep track of "un-minted" amounts
            apiReserveFromOldTranches += _leftToMintForCurrentBlock(API_TYPE);
            communityReserveFromOldTranches += _leftToMintForCurrentBlock(COMMUNITY_TYPE);
        }
    }

    function setCommunityMintPerBlock(uint _rate) external onlyAdmin {
        require(_rate != communityMintPerBlock, "Same rate");

        _beforeChangeMintRate();
        communityMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function setApiMintPerBlock(uint _rate) external onlyAdmin {
        require(_rate != apiMintPerBlock, "Same rate");

        _beforeChangeMintRate();
        apiMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function _updateCurrentTranch() internal {
        // Update variables to making calculations from this moment
        if (tranchesBlock > 0 && _blockNumber() > tranchesBlock) {
            tranchesBlock = _blockNumber();
        }

        apiMintedForCurrentTranch = 0;
        communityMintedForCurrentTranch = 0;
    }

    // This function is made to mint an arbitrary amount for other chains
    function mintForMultiChain(uint _amount, bytes calldata data) external onlyAdmin {
        require(_amount > 0, "Insufficient supply");
        require(_self().totalSupply() + _amount <= MAX_SUPPLY, "Cant' mint more than cap");

        _beforeChangeMintRate();

        // Mint + transfer to skip the 777-receiver callback
        _self().selfMint(address(this), _amount, data);
        // SuperToken transfer is safe
        _self().transfer(msg.sender, _amount);

        _updateCurrentTranch();
    }

    // This function checks for "most of revert scenarios" to prevent more minting than expected.
    // And keep track of minted / un-minted amounts
    function _checkMintFor(address _receiver, uint _supply, uint _type) internal {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters");
        require(_receiver != address(0), "Can't mint to zero address");
        require(_supply > 0, "Insufficient supply");
        require(tranchesBlock > 0, "Rewards not initialized");
        require(tranchesBlock < _blockNumber(), "Still waiting for rewards block");
        require(_self().totalSupply() + _supply <= MAX_SUPPLY, "Mint capped to 62.8M");

        uint _ratePerBlock = communityMintPerBlock;
        if (_type == API_TYPE) { _ratePerBlock = apiMintPerBlock; }

        require(_ratePerBlock > 0, "Mint ratio is 0");

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Create other variable to add to the MintedForCurrentTranch
        uint _toMint = _supply;

        // if the _supply (mint amount) is less than the expected "everything is fine" but
        // if its greater we have to check the "ReserveFromOldTranches"
        if (_toMint > _maxMintableSupply) {
            // fromReserve is the amount that will be "minted" from the old tranches reserve
            uint fromReserve = _toMint - _maxMintableSupply;

            // Drop the "reserve" amount to track only the "real" tranch minted amount
            _toMint -= fromReserve;

            // Check reserve for type
            if (_type == API_TYPE) {
                require(fromReserve <= apiReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from old tranches reserve
                apiReserveFromOldTranches -= fromReserve;
            } else {
                require(fromReserve <= communityReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from history reserve
                communityReserveFromOldTranches -= fromReserve;
            }
        }

        if (_type == API_TYPE) {
            apiMintedForCurrentTranch += _toMint;
        } else {
            communityMintedForCurrentTranch += _toMint;
        }
    }

    function communityMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, COMMUNITY_TYPE);

        // Mint + transfer to skip the 777-receiver callback
        _self().selfMint(address(this), _supply, abi.encodePacked(keccak256("Tokens for Community")));
        // SuperToken transfer is safe
        _self().transfer(_receiver, _supply);
    }

    function apiMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, API_TYPE);

        // Mint + transfer to skip the 777-receiver callback
        _self().selfMint(address(this), _supply, abi.encodePacked(keccak256("Tokens for API")));
        // SuperToken transfer is safe
        _self().transfer(_receiver, _supply);
    }

    function communityLeftToMint() public view returns (uint) {
        return _leftToMint(COMMUNITY_TYPE);
    }

    function apiLeftToMint() public view returns (uint) {
        return _leftToMint(API_TYPE);
    }

    function _leftToMintForCurrentBlock(uint _type) internal view returns (uint) {
        if (tranchesBlock <= 0 || tranchesBlock > _blockNumber()) { return 0; }

       uint left = _blockNumber() - tranchesBlock;

       if (_type == API_TYPE) {
           left *= apiMintPerBlock;
           left -= apiMintedForCurrentTranch;
       } else {
           left *= communityMintPerBlock;
           left -= communityMintedForCurrentTranch;
       }

       return left;
    }

    function _leftToMint(uint _type) internal view returns (uint) {
        uint totalLeft = MAX_SUPPLY - _self().totalSupply();
        if (totalLeft <= 0) { return 0; }

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Add the _type accumulated un-minted supply
        _maxMintableSupply += (_type == API_TYPE ? apiReserveFromOldTranches : communityReserveFromOldTranches);

        return (totalLeft <= _maxMintableSupply ? totalLeft : _maxMintableSupply);
    }

    function tokensReceived(
        address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external view {
        require(msg.sender == address(this), "Invalid token");
    }


    // For future use, just in case
    function addBurner(address newBurner) external onlyAdmin {
        _setupRole(BURNER_ROLE, newBurner);
    }

    // prevent anyone can burn
    function burn(uint _amount, bytes calldata data) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Only burners");

        _self().selfBurn(msg.sender, _amount, data);
    }

    function _self() internal view returns (ISuperToken) {
        return ISuperToken(address(this));
    }

    function cap() external pure returns (uint) {
        return MAX_SUPPLY;
    }

    // Implemented to be mocked in tests
    function _blockNumber() internal view virtual returns (uint) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../PiToken.sol";

contract PiTokenMock is PiToken {
    uint private mockedBlockNumber;

    function setBlockNumber(uint _n) public {
        mockedBlockNumber = _n;
    }

    function _blockNumber() internal view override returns (uint) {
        return mockedBlockNumber == 0 ? block.number : mockedBlockNumber;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";
import "./PiAdmin.sol";

contract BridgedPiToken is PiAdmin {
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC20 public immutable piToken;

    // Rates to mint per block
    uint public communityMintPerBlock;
    uint public apiMintPerBlock;

    // Keep track in which block started the current tranche
    uint internal tranchesBlock;

    // Keep track of minted per type for current tranch
    uint internal apiMintedForCurrentTranch;
    uint internal communityMintedForCurrentTranch;
    // Keep track of un-minted per type for old tranches
    uint internal apiReserveFromOldTranches;
    uint internal communityReserveFromOldTranches;

    uint internal API_TYPE = 0;
    uint internal COMMUNITY_TYPE = 1;


    constructor(IERC20 _piToken) {
        piToken = _piToken;
    }

    function initRewardsOn(uint __blockNumber) external onlyAdmin {
        require(tranchesBlock <= 0, "Already set");
        tranchesBlock = __blockNumber;
    }

    // Before change api or community RatePerBlock or before mintForMultiChain is called
    // Calculate and accumulate the un-minted amounts.
    function _beforeChangeMintRate() internal {
        if (tranchesBlock > 0 && _blockNumber() > tranchesBlock && (apiMintPerBlock > 0 || communityMintPerBlock > 0)) {
            // Accumulate both proportions to keep track of "un-minted" amounts
            apiReserveFromOldTranches += _leftToMintForCurrentBlock(API_TYPE);
            communityReserveFromOldTranches += _leftToMintForCurrentBlock(COMMUNITY_TYPE);
        }
    }

    function setCommunityMintPerBlock(uint _rate) external onlyAdmin {
        require(_rate != communityMintPerBlock, "Same rate");

        _beforeChangeMintRate();
        communityMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function setApiMintPerBlock(uint _rate) external onlyAdmin {
        require(_rate != apiMintPerBlock, "Same rate");

        _beforeChangeMintRate();
        apiMintPerBlock = _rate;
        _updateCurrentTranch();
    }

    function _updateCurrentTranch() internal {
        // Update variables to making calculations from this moment
        if (tranchesBlock > 0 && _blockNumber() > tranchesBlock) {
            tranchesBlock = _blockNumber();
        }

        // mintedForCurrentTranch = self().totalSupply();
        apiMintedForCurrentTranch = 0;
        communityMintedForCurrentTranch = 0;
    }


    function addMinter(address newMinter) external onlyAdmin {
        _setupRole(MINTER_ROLE, newMinter);
    }

    function available() public view returns (uint) {
        return piToken.balanceOf(address(this));
    }

    // This function checks for "most of revert scenarios" to prevent more minting than expected.
    // And keep track of minted / un-minted amounts
    function _checkMintFor(address _receiver, uint _supply, uint _type) internal {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters");
        require(_receiver != address(0), "Can't mint to zero address");
        require(_supply > 0, "Insufficient supply");
        require(tranchesBlock > 0, "Rewards not initialized");
        require(tranchesBlock < _blockNumber(), "Still waiting for rewards block");
        require(available() >= _supply, "Can't mint more than available");

        uint _ratePerBlock = communityMintPerBlock;
        if (_type == API_TYPE) { _ratePerBlock = apiMintPerBlock; }

        require(_ratePerBlock > 0, "Mint ratio is 0");

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Create other variable to add to the MintedForCurrentTranch
        uint _toMint = _supply;

        // if the _supply (mint amount) is less than the expected "everything is fine" but
        // if its greater we have to check the "ReserveFromOldTranches"
        if (_toMint > _maxMintableSupply) {
            // fromReserve is the amount that will be "minted" from the old tranches reserve
            uint fromReserve = _toMint - _maxMintableSupply;

            // Drop the "reserve" amount to track only the "real" tranch minted amount
            _toMint -= fromReserve;

            // Check reserve for type
            if (_type == API_TYPE) {
                require(fromReserve <= apiReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from old tranches reserve
                apiReserveFromOldTranches -= fromReserve;
            } else {
                require(fromReserve <= communityReserveFromOldTranches, "Can't mint more than expected");

                // drop the minted "extra" amount from history reserve
                communityReserveFromOldTranches -= fromReserve;
            }
        }

        if (_type == API_TYPE) {
            apiMintedForCurrentTranch += _toMint;
        } else {
            communityMintedForCurrentTranch += _toMint;
        }
    }

    // This function is called mint for contract compatibility but it doesn't mint,
    // it only transfers piTokens
    function communityMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, COMMUNITY_TYPE);

        piToken.safeTransfer(_receiver, _supply);
    }

    function apiMint(address _receiver, uint _supply) external {
        _checkMintFor(_receiver, _supply, API_TYPE);

        piToken.safeTransfer(_receiver, _supply);
    }

    function _leftToMintForCurrentBlock(uint _type) internal view returns (uint) {
        if (tranchesBlock <= 0 || tranchesBlock > _blockNumber()) { return 0; }

       uint left = _blockNumber() - tranchesBlock;

       if (_type == API_TYPE) {
           left *= apiMintPerBlock;
           left -= apiMintedForCurrentTranch;
       } else {
           left *= communityMintPerBlock;
           left -= communityMintedForCurrentTranch;
       }

       return left;
    }

    function _leftToMint(uint _type) internal view returns (uint) {
        uint totalLeft = available();
        if (totalLeft <= 0) { return 0; }

        // Get the max mintable supply for the current tranche
        uint _maxMintableSupply = _leftToMintForCurrentBlock(_type);

        // Add the _type accumulated un-minted supply
        _maxMintableSupply += (_type == API_TYPE ? apiReserveFromOldTranches : communityReserveFromOldTranches);

        return (totalLeft <= _maxMintableSupply ? totalLeft : _maxMintableSupply);
    }

    function communityLeftToMint() public view returns (uint) {
        return _leftToMint(COMMUNITY_TYPE);
    }

    function apiLeftToMint() public view returns (uint) {
        return _leftToMint(API_TYPE);
    }


    function balanceOf(address account) public view returns (uint) {
        return piToken.balanceOf(account);
    }

    // Implemented to be mocked in tests
    function _blockNumber() internal view virtual returns (uint) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../BridgedPiToken.sol";

contract BridgedPiTokenMock is BridgedPiToken {
    uint private mockedBlockNumber;

    constructor(IERC20 _token) BridgedPiToken(_token) {}

    function setBlockNumber(uint _n) public {
        mockedBlockNumber = _n;
    }

    function _blockNumber() internal view override returns (uint) {
        return mockedBlockNumber == 0 ? block.number : mockedBlockNumber;
    }
}

// SPDX-License-Identifier: AGPLv3
// MODIFIED FROM: superfluid/ethereum-contracts/contracts/mocks/WETH9Mock.sol

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.15;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract WETHMock {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        Address.sendValue(payable(msg.sender), address(this).balance);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "hardhat/console.sol";

import "./ControllerStratAbs.sol";
import "../interfaces/IEps.sol";

contract ControllerEllipsisStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IEpsPool constant public POOL = IEpsPool(0x160CAed03795365F3A589f10C379FfA7d75d4E76);
    IERC20 constant public POOL_TOKEN = IERC20(0xaF4dE8E872131AE328Ce21D909C74705d3Aaf452);
    IEpsStaker constant public STAKE = IEpsStaker(0xcce949De564fE60e7f96C85e55177F8B9E4CF61b);
    IEpsMultiFeeDistribution constant public FEE_DISTRIBUTION = IEpsMultiFeeDistribution(0x4076CC26EFeE47825917D0feC3A79d0bB9a6bB5c);

    int128 private immutable TOKEN_INDEX; // want token index in the pool
    uint private constant TOKENS_COUNT = 3; // 3Eps pool
    uint private constant STAKE_POOL_ID = 1; // 3Eps pool

    constructor(
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {
        uint i = 0;

        for (i; i < TOKENS_COUNT; i++) {
            if (address(want) == POOL.coins(i)) { break; }
        }

        TOKEN_INDEX = int128(uint128(i));
    }

    function identifier() external pure returns (string memory) {
        return string("[email protected]#1.0.0");
    }

    function harvest() public nonReentrant override {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewards();

        uint harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused()) { _deposit(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), harvested);
    }

    function _deposit() internal override {
        uint wantBal = wantBalance();

        if (wantBal > 0) {
            uint[TOKENS_COUNT] memory amounts = _amountToAmountsList(wantBal);

            uint expected = _wantToPoolTokenDoubleCheck(wantBal, true);

            want.safeApprove(address(POOL), wantBal);
            POOL.add_liquidity(amounts, expected);
        }

        uint poolTokenBal = POOL_TOKEN.balanceOf(address(this));

        if (poolTokenBal > 0) {
            POOL_TOKEN.safeApprove(address(STAKE), poolTokenBal);
            STAKE.deposit(STAKE_POOL_ID, poolTokenBal);
        }
    }

    function _claimRewards() internal override {
        uint[] memory pids = new uint[](1);
        pids[0] = STAKE_POOL_ID;

        STAKE.claim(pids);
        FEE_DISTRIBUTION.exit();
    }

    // amount is the `want` expected to be withdrawn
    function _withdraw(uint _amount) internal override returns (uint) {
        // To know how much we have to un-stake we use the same method to
        // calculate the expected poolToken at deposit
        uint poolTokenAmount = _wantToPoolTokenDoubleCheck(_amount, false);
        uint wantBal = wantBalance();

        _withdrawFromPool(poolTokenAmount);

        return wantBalance() - wantBal;
    }

    function _withdrawAll() internal override returns (uint) {
        uint wantBal = wantBalance();

        _withdrawFromPool(balanceOfPool());

        return wantBalance() - wantBal;
    }

    function _withdrawFromPool(uint poolTokenAmount) internal {
        // Remove staked from gauge
        STAKE.withdraw(STAKE_POOL_ID, poolTokenAmount);

        // remove_liquidity
        uint _balance = POOL_TOKEN.balanceOf(address(this));
        uint expected = _poolTokenToWantDoubleCheck(_balance);

        require(expected > 0, "remove_liquidity expected = 0");

        POOL.remove_liquidity_one_coin(_balance, TOKEN_INDEX,  expected);
    }

    function _minWantToPoolToken(uint _amount) internal view returns (uint) {
        // Based on virtual_price (poolMinVirtualPrice) and poolSlippageRatio
        // the expected amount is represented with 18 decimals as POOL_TOKEN
        // so we have to add X decimals to the want balance.
        // E.g. 1e8 (1BTC) * 1e10 * 99.4 / 100.0 => 0.994e18 poolToken tokens
        return _amount * WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio - poolMinVirtualPrice) / RATIO_PRECISION;
    }

    function _minPoolTokenToWant(uint _amount) internal view returns (uint) {
        // Double check for expected value
        // In this case we sum the poolMinVirtualPrice and divide by 1e10 because we want to swap poolToken => want
        return _amount * (RATIO_PRECISION + poolMinVirtualPrice - poolSlippageRatio) / (RATIO_PRECISION * WANT_MISSING_PRECISION);
    }

    function _poolTokenToWantDoubleCheck(uint _amount) internal view returns (uint wantAmount) {
        // Calculate at least xx% of the expected. The function doesn't
        // consider the fee.
        wantAmount = (calcWithdrawOneCoin(_amount) * (RATIO_PRECISION - poolSlippageRatio)) / RATIO_PRECISION;

        uint minWant = _minPoolTokenToWant(_amount);

        if (minWant > wantAmount) { wantAmount = minWant; }
    }

    function _wantToPoolTokenDoubleCheck(uint _amount, bool _isDeposit) internal view returns (uint poolTokenAmount) {
        uint[TOKENS_COUNT] memory amounts = _amountToAmountsList(_amount);
        // calc_token_amount doesn't consider fee
        poolTokenAmount = POOL.calc_token_amount(amounts, _isDeposit);
        // Remove max fee
        poolTokenAmount = poolTokenAmount * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        // In case the pool is unbalanced (attack), make a double check for
        // the expected amount with minExpected set ratios.
        uint wantToPoolToken = _minWantToPoolToken(_amount);

        if (wantToPoolToken > poolTokenAmount) { poolTokenAmount = wantToPoolToken; }
    }

    function calcWithdrawOneCoin(uint _amount) public view returns (uint) {
        if (_amount > 0) {
            return POOL.calc_withdraw_one_coin(_amount, TOKEN_INDEX);
        } else {
            return 0;
        }
    }

    function balanceOfPool() public view override returns (uint) {
        (uint _amount, ) = STAKE.userInfo(STAKE_POOL_ID, address(this));

        return _amount;
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return calcWithdrawOneCoin(balanceOfPool());
    }

    function _amountToAmountsList(uint _amount) internal view returns (uint[TOKENS_COUNT] memory) {
        uint[TOKENS_COUNT] memory amounts; // #  = new uint[](TOKENS_COUNT);
        amounts[uint(uint128(TOKEN_INDEX))] = _amount;

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IEpsPool {
    function add_liquidity(uint[3] memory amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount) external;
    function coins(uint) external view returns (address);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function calc_token_amount(uint[3] calldata _amounts, bool is_deposit) external view returns (uint);
}

interface IEpsLPPool {
    function add_liquidity(uint[2] memory amounts, uint min_mint_amount) external payable;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount) external;
    function coins(uint) external view returns (address);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function calc_token_amount(uint[2] calldata _amounts, bool is_deposit) external view returns (uint);
}

interface IEpsStaker {
    function poolInfo(uint256 _pid) external view returns (address, uint256, uint256, uint256, uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function claimableReward(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function claim(uint256[] calldata _pids) external;
}

interface IEpsMultiFeeDistribution {
    function exit() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";
import "../interfaces/IEps.sol";
import "../interfaces/IWNative.sol";

contract ControllerEllipsisLPStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    address public constant WNATIVE = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address immutable public POOL_TOKEN; // 0x5781041F9Cf18484533F433Cb2Ea9ad42e117B3a BNB
    IEpsLPPool immutable public POOL; // 0xc377e2648E5adD3F1CB51a8B77dBEb63Bd52c874 BNB
    IEpsStaker constant public STAKE = IEpsStaker(0xcce949De564fE60e7f96C85e55177F8B9E4CF61b);
    IEpsMultiFeeDistribution constant public FEE_DISTRIBUTION = IEpsMultiFeeDistribution(0x4076CC26EFeE47825917D0feC3A79d0bB9a6bB5c);

    int128 private immutable TOKEN_INDEX; // want token index in the pool
    int128 private constant TOKENS_COUNT = 2; // LP pool
    uint private immutable STAKE_POOL_ID; // 11 BNB/BNBL (bnbEPS)

    constructor(
        IERC20Metadata _want,
        uint _stakePoolId,
        int128 _tokenIndex,
        address _poolToken,
        address _pool,
        address _controller,
        address _exchange,
        address _treasury
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {
        require(_poolToken != address(0), "poolToken !ZeroAddress");
        require(_pool != address(0), "pool !ZeroAddress");
        require(_tokenIndex >= 0 && _tokenIndex < TOKENS_COUNT, "tokenIndex out of range");

        POOL = IEpsLPPool(_pool);
        POOL_TOKEN = _poolToken;
        STAKE_POOL_ID = _stakePoolId;
        TOKEN_INDEX = _tokenIndex;
    }

    // Remove liquidity for native token
    receive() external payable { }

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(
            IERC20Metadata(POOL_TOKEN).symbol(), "@Ellipsis#1.0.0"
        ));
    }

    function harvest() public nonReentrant override {
        uint _before = wantBalance();

        _claimRewards();
        _swapRewards();

        uint harvested = wantBalance() - _before;

        // Charge performance fee for earned want + rewards
        _beforeMovement();

        // re-deposit
        if (!paused()) { _deposit(); }

        // Update lastBalance for the next movement
        _afterMovement();

        emit Harvested(address(want), harvested);
    }

    function _deposit() internal override {
        uint wantBal = wantBalance();

        if (wantBal > 0) {
            uint[TOKENS_COUNT] memory amounts = _amountToAmountsList(wantBal);

            uint expected = _wantToPoolTokenDoubleCheck(wantBal, true);

            if (address(want) == WNATIVE) {
                IWNative(address(want)).withdraw(wantBal);
                POOL.add_liquidity{value: wantBal}(amounts, expected);
            } else {
                // want.safeApprove(address(POOL), wantBal);
                // POOL.add_liquidity(amounts, expected);
            }
        }

        uint poolTokenBal = IERC20(POOL_TOKEN).balanceOf(address(this));

        if (poolTokenBal > 0) {
            IERC20(POOL_TOKEN).safeApprove(address(STAKE), poolTokenBal);
            STAKE.deposit(STAKE_POOL_ID, poolTokenBal);
        }
    }

    function _claimRewards() internal override {
        uint[] memory pids = new uint[](1);
        pids[0] = STAKE_POOL_ID;

        STAKE.claim(pids);
        FEE_DISTRIBUTION.exit();
    }

    // amount is the `want` expected to be withdrawn
    function _withdraw(uint _amount) internal override returns (uint) {
        // To know how much we have to un-stake we use the same method to
        // calculate the expected poolToken at deposit
        uint poolTokenAmount = _wantToPoolTokenDoubleCheck(_amount, false);
        uint wantBal = wantBalance();

        _withdrawFromPool(poolTokenAmount);

        return wantBalance() - wantBal;
    }

    function _withdrawAll() internal override returns (uint) {
        uint wantBal = wantBalance();

        _withdrawFromPool(balanceOfPool());

        return wantBalance() - wantBal;
    }

    function _withdrawFromPool(uint poolTokenAmount) internal {
         // Remove staked from gauge
        STAKE.withdraw(STAKE_POOL_ID, poolTokenAmount);

        // remove_liquidity
        uint _balance = IERC20(POOL_TOKEN).balanceOf(address(this));
        uint expected = _poolTokenToWantDoubleCheck(_balance);

        require(expected > 0, "remove_liquidity expected = 0");

        POOL.remove_liquidity_one_coin(_balance, TOKEN_INDEX,  expected);

        if (address(want) == WNATIVE) {
            IWNative(address(want)).deposit{value: address(this).balance}();
        }
     }

    function _minWantToPoolToken(uint _amount) internal view returns (uint) {
        // Based on virtual_price (poolMinVirtualPrice) and poolSlippageRatio
        // the expected amount is represented with 18 decimals as POOL_TOKEN
        // so we have to add X decimals to the want balance.
        // E.g. 1e8 (1BTC) * 1e10 * 99.4 / 100.0 => 0.994e18 poolToken tokens
        return _amount * WANT_MISSING_PRECISION * (RATIO_PRECISION - poolSlippageRatio - poolMinVirtualPrice) / RATIO_PRECISION;
    }

    function _minPoolTokenToWant(uint _amount) internal view returns (uint) {
        // Double check for expected value
        // In this case we sum the poolMinVirtualPrice and divide by 1e10 because we want to swap poolToken => want
        return _amount * (RATIO_PRECISION + poolMinVirtualPrice - poolSlippageRatio) / (RATIO_PRECISION * WANT_MISSING_PRECISION);
    }

    function _poolTokenToWantDoubleCheck(uint _amount) internal view returns (uint wantAmount) {
        // Calculate at least xx% of the expected. The function doesn't
        // consider the fee.
        wantAmount = (calcWithdrawOneCoin(_amount) * (RATIO_PRECISION - poolSlippageRatio)) / RATIO_PRECISION;

        uint minWant = _minPoolTokenToWant(_amount);

        if (minWant > wantAmount) { wantAmount = minWant; }
    }

    function _wantToPoolTokenDoubleCheck(uint _amount, bool _isDeposit) internal view returns (uint poolTokenAmount) {
        uint[TOKENS_COUNT] memory amounts = _amountToAmountsList(_amount);
        // calc_token_amount doesn't consider fee
        poolTokenAmount = POOL.calc_token_amount(amounts, _isDeposit);
        // Remove max fee
        poolTokenAmount = poolTokenAmount * (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION;

        // In case the pool is unbalanced (attack), make a double check for
        // the expected amount with minExpected set ratios.
        uint wantToPoolToken = _minWantToPoolToken(_amount);

        if (wantToPoolToken > poolTokenAmount) { poolTokenAmount = wantToPoolToken; }
    }

    function calcWithdrawOneCoin(uint _amount) public view returns (uint) {
        if (_amount > 0) {
            return POOL.calc_withdraw_one_coin(_amount, TOKEN_INDEX);
        } else {
            return 0;
        }
    }

    function balanceOfPool() public view override returns (uint) {
        (uint _amount, ) = STAKE.userInfo(STAKE_POOL_ID, address(this));
        return _amount;
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return calcWithdrawOneCoin(balanceOfPool());
    }

    function _amountToAmountsList(uint _amount) internal view returns (uint[TOKENS_COUNT] memory) {
        uint[TOKENS_COUNT] memory amounts; // #  = new uint[](TOKENS_COUNT);
        amounts[uint(uint128(TOKEN_INDEX))] = _amount;

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ControllerStratAbs.sol";

contract ControllerDummyStrat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    constructor(
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury) {}

    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(want.symbol(), "@2pi-dummy#1.0.0"));
    }

    function harvest() public nonReentrant override {
        emit Harvested(address(want), 0);
    }

    function _deposit() internal override {
    }

    // amount is the `want` expected to be withdrawn
    function _withdraw(uint) internal pure override returns (uint) {
        return 0;
    }

    function _withdrawAll() internal pure override returns (uint) {
        return 0;
    }

    function balanceOfPool() public pure override returns (uint) {
        return 0;
    }

    function balanceOfPoolInWant() public pure override returns (uint) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "hardhat/console.sol";

import "./ControllerStratAbs.sol";
import "../interfaces/IBalancer.sol";
import "../libraries/Bytes32Utils.sol";

contract ControllerBalancerV2Strat is ControllerStratAbs {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using Bytes32Utils for bytes32;

    bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");

    bytes32 public immutable poolId;
    IBalancerV2Vault public immutable vault;

    // Pool settings
    // JoinKind { INIT = 0, EXACT_TOKENS_IN_FOR_BPT_OUT = 1, TOKEN_IN_FOR_EXACT_BPT_OUT = 2}
    uint public constant JOIN_KIND = 1;
    // ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT = 0, EXACT_BPT_IN_FOR_TOKENS_OUT = 1, BPT_IN_FOR_EXACT_TOKENS_OUT = 2}
    uint public constant EXACT_BPT_IN_FOR_ONE_TOKEN_OUT = 0;
    uint public constant BPT_IN_FOR_EXACT_TOKENS_OUT = 2;
    uint public constant SHARES_PRECISION = 1e18; // same as BPT token
    IBalancerDistributor public immutable distributor = IBalancerDistributor(0x0F3e0c4218b7b0108a3643cFe9D3ec0d4F57c54e);

    address public constant GAUGE = address(0x72843281394E68dE5d55BCF7072BB9B2eBc24150);

    constructor(
        IBalancerV2Vault _vault,
        bytes32 _poolId,
        IERC20Metadata _want,
        address _controller,
        address _exchange,
        address _treasury
    ) ControllerStratAbs(_want, _controller, _exchange, _treasury){
        require(_poolId != "", "Empty poolId");

        vault = _vault;
        poolId = _poolId;

        require(_assets().length > 0, "Vault without tokens");
        _setupRole(HARVESTER_ROLE, msg.sender);
    }


    function identifier() external view returns (string memory) {
        return string(abi.encodePacked(
            want.symbol(),
            "-0x",
            poolId.toString(),
            "@BalancerV2#1.0.0"
        ));
    }

    function _claimRewards() internal override {
        bool _claim = false;

        for (uint i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];

            if (IBalancerGauge(GAUGE).claimable_reward(address(this), reward) > 0) {
                _claim = true;
                break;
            }
        }

        if (_claim) { IBalancerGauge(GAUGE).claim_rewards(); }
    }

    function _deposit() internal override {
        uint _balance = wantBalance();

        if (_balance > 0) {
            IAsset[] memory tokens = _assets();
            uint[] memory amounts = new uint[](tokens.length);


            amounts[_tokenIndex(tokens)] = _balance;

            uint expected = (
                _balance * WANT_MISSING_PRECISION * SHARES_PRECISION *
                (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION /
                _pricePerShare()
            );

            require(expected > 0, "Insufficient expected amount");

            bytes memory userData = abi.encode(JOIN_KIND, amounts, expected);

            IERC20(want).safeApprove(address(vault), _balance);

            vault.joinPool(
                poolId,
                address(this),
                address(this),
                IBalancerV2Vault.JoinPoolRequest({
                    assets: tokens,
                    maxAmountsIn: amounts,
                    userData: userData,
                    fromInternalBalance: false
                })
            );
        }

        // Stake
        uint _amount =  balanceOfVaultPool();
        if (_amount > 0) {
            IERC20(pool()).safeApprove(GAUGE, _amount);
            IBalancerGauge(GAUGE).deposit(_amount);
        }
    }

    // amount is the want expected to be withdrawn
    function _withdraw(uint _amount) internal override returns (uint) {
        IAsset[] memory tokens = _assets();
        uint[] memory amounts = new uint[](tokens.length);

        uint _balance = wantBalance();
        if (_balance < _amount) {
            uint diff = _amount - _balance;
            amounts[_tokenIndex(tokens)] = diff;

            // We put a little more than the expected amount because of the fees & the pool swaps
            uint expected = (
                diff * WANT_MISSING_PRECISION * SHARES_PRECISION *
                (RATIO_PRECISION + poolSlippageRatio) / RATIO_PRECISION /
                _pricePerShare()
            );

            require(expected > 0, "Insufficient expected amount");

            // In case that the calc gives a little more than the balance
            uint _balanceOfPool = balanceOfPool();
            if (expected > _balanceOfPool) { expected = _balanceOfPool; }

            //Unstake
            IBalancerGauge(GAUGE).withdraw(expected);
            require(balanceOfVaultPool() >= expected, "Gauge gave less than expected");

            bytes memory userData = abi.encode(BPT_IN_FOR_EXACT_TOKENS_OUT, amounts, expected);

            vault.exitPool(
                poolId,
                address(this),
                payable(address(this)),
                IBalancerV2Vault.ExitPoolRequest({
                    assets: tokens,
                    minAmountsOut: amounts,
                    userData: userData,
                    toInternalBalance: false
                })
            );
        }

        uint withdrawn = wantBalance() - _balance;

        return (withdrawn > _amount) ? _amount : withdrawn;
    }

    function _withdrawAll() internal override returns (uint) {
        IAsset[] memory tokens = _assets();
        uint[] memory amounts = new uint[](tokens.length);

        uint _balance = wantBalance();

        //Unstake
        uint stakedBalance = balanceOfPool();
        IBalancerGauge(GAUGE).withdraw(stakedBalance);
        require(balanceOfVaultPool() >= stakedBalance, "Gauge gave less than expected");

        uint index = 0;
        uint bptBalance = balanceOfVaultPool();

        uint expected = (
            bptBalance * _pricePerShare() *
            (RATIO_PRECISION - poolSlippageRatio) / RATIO_PRECISION /
            WANT_MISSING_PRECISION / SHARES_PRECISION
        );

        require(expected > 0, "Insufficient expected amount");

        index = _tokenIndex(tokens);
        amounts[index] = expected;

        // Withdraw all the BPT directly
        bytes memory userData = abi.encode(EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptBalance, index);

        vault.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            IBalancerV2Vault.ExitPoolRequest({
                assets: tokens,
                minAmountsOut: amounts,
                userData: userData,
                toInternalBalance: false
            })
        );

        // Not sure if the minAmountsOut are respected in this case so re-check
        uint withdrawn = wantBalance() - _balance;

        require(withdrawn >= expected, "Less tokens than expected");

        return withdrawn;
    }

    function pool() public view returns (address _pool) {
        (_pool,) = vault.getPool(poolId);
    }

    function balanceOfVaultPool() public view returns (uint) {
        return IERC20(pool()).balanceOf(address(this));
    }

    function balanceOfPool() public view override returns (uint) {
        return IERC20(GAUGE).balanceOf(address(this));
    }

    function balanceOfPoolInWant() public view override returns (uint) {
        return balanceOfPool() * _pricePerShare() / WANT_MISSING_PRECISION / SHARES_PRECISION;
    }

    function _pricePerShare() internal view returns (uint) {
        uint rate = IBalancerPool(pool()).getRate();

        require(rate > 1e18, "Under 1");

        return rate;
    }

    function _assets() internal view returns (IAsset[] memory assets) {
        (IERC20[] memory poolTokens,,) = vault.getPoolTokens(poolId);
        assets = new IAsset[](poolTokens.length);

        for (uint i = 0; i < poolTokens.length; i++) {
            assets[i] = IAsset(address(poolTokens[i]));
        }
    }

    function _tokenIndex(IAsset[] memory tokens) internal view returns (uint i) {
        for (i; i < tokens.length; i++) {
            // assign index of want
            if (address(tokens[i]) == address(want)) { break; }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerV2Vault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        IERC20[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );

    function getPool(bytes32 poolId) external view returns (address, uint8);
}

interface IBalancerPool {
    function getRate() external view returns (uint);
}

struct BalancerV2Claim {
    uint distributionId;
    uint balance;
    address distributor;
    uint tokenIndex;
    bytes32[] merkleProof;
}

interface IBalancerDistributor {
    function claimDistributions(address claimer, BalancerV2Claim[] memory claims, IERC20[] memory tokens) external;
}

interface IBalancerGauge {
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function claim_rewards() external;
    function claimable_reward(address, address) view external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Bytes32Utils {
    function toString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(64);

        for (uint8 i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i/2] >> 4);
            uint8 _l = uint8(_bytes32[i/2] & 0x0f);

            bytesArray[i] = toByte(_f);
            bytesArray[++i] = toByte(_l);
        }

        return string(bytesArray);
    }

    function toByte(uint8 _uint8) internal pure returns (bytes1) {
        if(_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapRouterMock {
    // We always handle 1% of slippage so to get 1 expected token
    // 2 * 99 / 100 => 1
    uint private expected = 2;

    function reset() public {
        expected = 2;
    }

    function setExpected(uint _amount) public {
        expected = _amount;
    }

    function getAmountsOut(uint amountIn, address[] memory /*path*/) external view returns (uint[] memory amounts) {
        amounts = new uint[](2);
        amounts[0] = amountIn; // First always the same
        amounts[1] = expected;
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint /*deadline*/
    ) external returns (uint[] memory amounts) {
        uint idx = path.length - 1;

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[idx]).transfer(to, amountOutMin);

        uint[] memory a = new uint[](1);
        a[0] = amountOutMin;

        return a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Strategy {
    function deposit(address _senderUser, uint _amount) external returns (uint);
}

contract FarmMock {
    address token;
    address strategy;

    constructor (address _token) {
        token = _token;
    }

    function setStrategy(address _strategy) public {
        strategy = _strategy;
    }

    function piToken() external view returns (address) {
        return token;
    }

    function deposit(address _senderUser, uint _amount) public returns (uint) {
        IERC20(token).approve(strategy, _amount);

        return Strategy(strategy).deposit(_senderUser, _amount);
    }
}