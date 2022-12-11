// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "BaseStrategyRiskless.sol";


import {Math} from "Math.sol";

// CURVE META FACTORY POOL STRATEGY //
contract MockCurveMAIFarmer is BaseStrategyRiskless {
    using SafeERC20 for IERC20;

    constructor(
        address _container,
        address _stableToken,
        address _treasuryRecipient
    )
        BaseStrategyRiskless(
            msg.sender,
            msg.sender,
            _container,
            _treasuryRecipient,
            _stableToken
        )
    {
        workingToken = _stableToken;
        workingTokenDecimals = 18;
    }

    function _removeAllowances() internal override {}
    function _giveAllowances() internal override {}
    function _prepareRetirement() internal override returns (uint256){}
    function _harvest() internal override {}



    ////////////////////////////////////////////////////////////////////////////

    // GETTERS  /////////////////////////////////////////////////////////////////

    function _balanceOfToken(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // @notice Container needs to know the working positions to account
    // shares correctly.
    // @dev This function is essentially for container to call on calculating
    // shares.
    function balanceOfWorkingPositions()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(workingToken).balanceOf(address(this));
    }

    function getWorkingTokenPrice() public view override returns (uint256) {
      return 1e18;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWorkingPositions();
      }


    ////////////////////////////////////////////////////////////////////////////

    // EXTERNALS ///////////////////////////////////////////////////////////////

    function _deposit() internal override {}

    function _getInPosition(uint256 _amount)
        internal
        override
        returns (uint256 deltaPositions)
    {
        deltaPositions = _amount;
    }

    function _getOutPosition(uint256 _liquidateAmount)
        internal
        override
        returns (uint256)
    {

        return _liquidateAmount;
    }
    ////////////////////////////////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "BaseStrategy.sol";

abstract contract BaseStrategyRiskless is BaseStrategy {
    using SafeERC20 for IERC20;

    uint256 public immutable stableTokenDecimals;

    constructor(
        address _keeper,
        address _strategist,
        address _container,
        address _treasuryRecipient,
        address _stableToken
    )
        BaseStrategy(
            _keeper,
            _strategist,
            _treasuryRecipient,
            _container,
            _stableToken
        )
    {
      stableTokenDecimals = IERC20Metadata(_stableToken).decimals();
    }

    // @dev 18 decimal precised version of 'balanceOfWorkingPositions()'. Always return 18 decimals!!
    function balanceOfWorkingPositionsPrecised() public view returns (uint256) {
        if (!emergencyMode)
            return
                balanceOfWorkingPositions() * 10**(18 - workingTokenDecimals);
        return IERC20(stableToken).balanceOf(address(this)) * 10**(18-stableTokenDecimals);
    }

    // @dev Deposit all the 'stableToken' tokens to work
    function deposit() public {
        if (IERC20(stableToken).balanceOf(address(this)) != 0) {
          _deposit();
        }
    }

    // @dev Harvest the rewards, charge the fees from the rewards and redeposit
    function _harvest() internal virtual;

    // @notice Harvests the rewards and compounds
    function harvest() external onlyKeepers {
        _harvest();
    }

    // @dev This function mainly called by containers 'deposit()' function.
    // Returns the position size difference before and after the user in terms of $ 18 decimals.
    function getInPosition(uint256 _amount)
        public
        onlyContainer
        returns (uint256)
    {
        IERC20(stableToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); // take from container

        return (_getInPosition(_amount) * 10**(18-workingTokenDecimals) * getWorkingTokenPrice()) / 1e18;
    }

    // @dev This function mainly called by containers 'redeem()' function.
    // liquidates users portion of working tokens to target token and sends it to container
    // for user withdrawal.
    // @param _amount Working token amount in 18 decimals to liquidate to 'stableToken'
    // @returns liquidated 'stableToken' amount
    function getOutPosition(uint256 _amount)
        public
        onlyContainer
        returns (uint256)
    {
        // '_amount' input is always 18 decimals, in a case where the working token
        // does not have 18 decimals we need to adjust it.
        _amount = _amount / 10**(18-workingTokenDecimals);
        uint256 stableTokenFreed = _getOutPosition(_amount);
        IERC20(stableToken).safeTransfer(msg.sender, stableTokenFreed);
        return stableTokenFreed;
    }

    // @notice Retires this strategy and sends 'stableToken' to '_newStrategy'
    // @dev This function can only be used when container managers calls
    // 'switchStrategy()'.
    // @param _newStrategy New strategy to migrate
    // @return Returns the total 'stableToken' token transferred to '_newStrategy'
    function retire(address _newStrategy)
        public
        onlyContainer
        returns (uint256)
    {
        uint256 stableTokenAmount = _prepareRetirement();
        // transfer all stableToken to new strategy
        IERC20(stableToken).safeTransfer(_newStrategy, stableTokenAmount);
        return stableTokenAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "Ownable.sol";
import {SafeERC20} from "SafeERC20.sol";
import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";
import {Pausable} from "Pausable.sol";

import {IContainer} from "IContainer.sol";

abstract contract BaseStrategy is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // containers 'stableToken' token
    address public immutable stableToken;

    address public workingToken;

    address public keeper; // responsible of harvests
    address public strategist; // responsible of strategy overall
    address public container; // container that the strategy is operating with
    address public treasuryRecipient; // fee recipient

    uint256 public constant MAX_TOTAL_FEE = 2_000; // 20%

    // defaults
    uint256 public totalFee = 1_000; // 10%
    uint256 public strategistFee = 500; // %50 of total fee
    uint256 public govFee = 500; // %50 of total fee

    // Decimals of the working token.
    // this is crucial for share accounting
    // TODO: set this in the strategy constructor!
    uint256 public workingTokenDecimals;

    // when 'emergency()' called this is true, when 'unpause()' called this is false.
    // when emergency is true, share accounting will be based on 'targetToken' or 'stableToken'
    // depending on the strategy type.
    bool public emergencyMode;

    event KeeperUpdated(address indexed keeper);
    event StrategistFeeUpdated(uint256 strategistFee);
    event GovFeeUpdated(uint256 govFee);
    event StrategistUpdated(address indexed strategist);
    event TreasuryRecipientUpdated(address indexed treasuryRecipient);
    event Harvested(uint256 profit, uint256 eta, uint256 reportTime);

    constructor(
        address _keeper,
        address _strategist,
        address _treasuryRecipient,
        address _container,
        address _stableToken
    ) {
        require(
            address(IContainer(_container).stableToken()) == _stableToken,
            "!STABLE_TOKEN"
        );

        keeper = _keeper;
        strategist = _strategist;
        treasuryRecipient = _treasuryRecipient;
        container = _container;
        stableToken = _stableToken;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == strategist || msg.sender == keeper,
            "ONLY_KEEPER"
        );
        _;
    }

    modifier onlyManagers() {
        require(
            msg.sender == strategist || msg.sender == owner(),
            "ONLY_MANAGERS"
        );
        _;
    }

    modifier onlyContainer() {
        require(msg.sender == container, "ONLY_CONTAINER");
        _;
    }

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;

        emit KeeperUpdated(_keeper);
    }

    function setStrategistFee(uint256 _strategistFee) external onlyOwner {
        require(_strategistFee + govFee <= totalFee, "!TOTAL_FEE");
        strategistFee = _strategistFee;

        emit StrategistFeeUpdated(_strategistFee);
    }

    function setGovFee(uint256 _govFee) external onlyOwner {
        require(_govFee + strategistFee <= totalFee, "!TOTAL_FEE");
        govFee = _govFee;

        emit GovFeeUpdated(_govFee);
    }

    function setStrategist(address _strategist) external onlyOwner {
        require(msg.sender == strategist);
        strategist = _strategist;

        emit StrategistUpdated(_strategist);
    }

    function setTreasuryRecipient(address _treasuryRecipient)
        external
        onlyOwner
    {
        treasuryRecipient = _treasuryRecipient;

        emit TreasuryRecipientUpdated(_treasuryRecipient);
    }

    /////////************** OVERRIDE THESE METHODS *****************////////////

    // @dev total assets that the strategy is managing
    // estimated in terms of stableToken(usually dollar)
    function estimatedTotalAssets() public view virtual returns (uint256);

    // @dev balance of working tokens that in the position
    function balanceOfWorkingPositions() public view virtual returns (uint256);

    // @dev return a SAFE 'stableToken' value of 1 targetTokenPrice
    function getWorkingTokenPrice() public view virtual returns (uint256);

    // @dev Deposit 'stableToken' or 'targetToken' to position.
    // In other words, receive the working tokens.
    function _deposit() internal virtual;

    // @notice Charges treasury and strategist fees
    // @dev When withdrawals if the strategy is in profit take the fee from the profit
    // In harvests take the fee regardless of profit/loss from the reward tokens.
    // @param _amount Amount to take fee (usually it is profit)
    // @return Returns the total fees deducted from '_amount'
    function _chargeFees(uint256 _amount) internal returns (uint256) {
        uint256 totalFees = (_amount * totalFee) / 10_000;

        uint256 govFeeAmount = (totalFees * govFee) / totalFee;
        IERC20(stableToken).safeTransfer(treasuryRecipient, govFeeAmount);

        uint256 strategistFeeAmount = totalFees - govFeeAmount;
        IERC20(stableToken).safeTransfer(strategist, strategistFeeAmount);

        return totalFees;
    }

    // @dev Liquidate '_amount' working token to target token and return the liquidated amount
    // @params _amount Working token that needs to be liquidated
    // @returns Returns how much target token received after liquidating '_amount' working token
    // IMPORTANT: '_amount' can be in any decimal precision 1,8,12,18. That's why BaseStrategyRisky
    // and BaseStrategyRiskless 'getOutPosition()' functions are dividing the '_amount' to
    // 10**(18-workingTokenDecimals) to achieve the right decimal precision for the working token.
    // NOTE: There will be probably small math flaws dividing/multiplying different decimal placed kinds.
    function _getOutPosition(uint256 _amount)
        internal
        virtual
        returns (uint256 liquidated);

    // @dev Put the target tokens to work. Report the delta working positions dollar value to container
    // @params _amount Amount of target token to be taken from container
    // @returns deltaPositions How much the '_amount' deposited impact the strategy overall
    // ** working token balance after users deposit dollar value - working token balance before users deposit dollar value**
    //IMPORTANT: deltaPositions should always return in 18 decimal basis and in terms of $$!!
    function _getInPosition(uint256 _amount)
        internal
        virtual
        returns (uint256 deltaPositions);

    // @dev Free up as many as 'targetToken' or 'stableToken' depending on the strategy type.
    // Exit the 3rd party positions.
    // @returns Target/Stable token that freed and ready for swap to 'stableToken'
    function _prepareRetirement()
        internal
        virtual
        returns (uint256 targetTokenAmount);

    // @dev Remove all allowances for 3rd party contracts
    function _removeAllowances() internal virtual;

    // @dev Approve all allowances for 3rd party to maximum
    function _giveAllowances() internal virtual;

    // @dev Leave all third party contracts and stay in the strategy idle
    // Remove all allowances from third party contracts
    // pause the contract
    function emergency() external onlyOwner {
        _prepareRetirement();
        _removeAllowances();
        _pause();
        emergencyMode = true;
    }

    // @dev unpause the contract
    // give all allowances back
    // deposit all 'targetToken' or 'stableToken' to work
    function unpause() external onlyOwner {
        _unpause();
        _giveAllowances();
        _deposit();
        emergencyMode = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.10;

import "IERC20.sol";

interface IContainer is IERC20 {
  struct StrategyParams {
      uint256 debtLimit; // maximum that the strategy can take from container
      uint256 targetTokenStopPrice; // used on stop lossess and profit/loss accountant
      bool riskOn; // checks whether the strategy is stablecoin strategy or 'risky'
      bool active; // container currently using strategy or not
  }
  function stableToken() external view returns (IERC20 _stableToken);
  function targetToken() external view returns (IERC20 _targetToken);
  function getIndex() external view returns (uint256);
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
  function deposit(uint256 assets, address receiver) external returns (uint256);
  function registeredStrategies(address _strategy) external view returns (StrategyParams memory stratParams);
  function getDepositableToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}