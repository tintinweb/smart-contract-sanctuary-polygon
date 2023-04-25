/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//File: [ReentrancyGuard.sol]

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

//File: [IMigrationManager.sol]

interface IMigrationManager
{
    //========================
    // MIGRATION FUNCTIONS
    //========================

    function requestMigration(address _user, string memory _topic) external returns (uint256);
    function cancelMigration(address _user, uint256 _id) external;
    function executeMigration(address _user, uint256 _id) external returns (bool);
}

//File: [ML_TransferETH.sol]

contract ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    uint256 public transferGas = 30000;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setTransferGas(uint256 _gas) internal
    {
        require(_gas >= 30000, "Gas to low");
        require(_gas <= 250000, "Gas to high");
        transferGas = _gas;
    }

    //========================
    // TRANSFER FUNCTIONS
    //======================== 

    function transferETH(address _to, uint256 _amount) internal
    {
        (bool success, ) = payable(_to).call{ value: _amount, gas: transferGas }("");
        success; //prevent warning
    }
}

//File: [IERC20.sol]

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

//File: [Address.sol]

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

//File: [IToken.sol]

interface IToken
{
	//========================
    // EVENTS FUNCTIONS
    //========================

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//========================
    // INFO FUNCTIONS
    //========================
	
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	//========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address account) external view returns (uint256);

    //========================
    // TRANSFER / APPROVE FUNCTIONS
    //========================

    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
}

//File: [IWrappedCoin.sol]

interface IWrappedCoin is IToken
{
	function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

//File: [IBank.sol]

interface IBank
{  
    //========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(IToken _token, address _user) external view returns (uint256);
    function allowance(IToken _token, address _user, address _spender) external view returns (uint256);
    
    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositETHFor(address _user) external payable;
    function depositFor(IToken _token, address _user, uint256 _amount) external;

    //========================
    // TRANSFER FUNCTIONS
    //========================

    function transfer(IToken _token, address _from, address _to, uint256 _amount) external;
    function transferToAccount(IToken _token, address _from, address _to, uint256 _amount) external;

    //========================
    // ALLOWANCE FUNCTIONS
    //========================

    function approve(IToken _token, address _spender, uint256 _amount) external;
    function increaseAllowance(IToken _token, address _spender, uint256 _amount) external;
    function decreaseAllowance(IToken _token, address _spender, uint256 _amount) external;
}

//File: [SafeERC20.sol]

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

//File: [IVaultPoolInfo.sol]

interface IVaultPoolInfo
{
    //========================
    // POOL INFO FUNCTIONS
    //========================

    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolTotalAllocPoints() external view returns (uint256);        
    function poolRewardEmission() external view returns (uint256);
    function poolTotalRewardEmission() external view returns (uint256);

    function poolBlockOrTime() external view returns (bool);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256); 
    function poolStart() external view returns (uint256);
    function poolEnd() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);

    function isPoolFarmable() external view returns (bool);
}

//File: [ML_RecoverFunds.sol]

contract ML_RecoverFunds is ML_TransferETH
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function _recoverETH(uint256 _amount, address _to) internal
    {
        transferETH(_to, _amount);
    }

    function _recoverToken(IToken _token, uint256 _amount, address _to) internal
    {
        IERC20(address(_token)).safeTransfer(_to, _amount);
    }  
}

//File: [ML_TransferHelper.sol]

contract ML_TransferHelper
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // STRUCTS
    //========================

    struct TransferResult
    {
        uint256 fromBefore;     //balance of from-token, before transfer
        uint256 toBefore;       //balance of token, before transfer
        uint256 toAfter;        //balance of token, after transfer
        uint256 transferred;    //transferred amount 
    }

    //========================
    // FUNCTIONS
    //========================

    function safeTransferFrom(
        IToken _token,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(_from),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransferFrom(
            _from, 
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeTransfer(
        IToken _token,
        uint256 _amount,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(msg.sender),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransfer(
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeApprove(IToken _token, address _spender, uint256 _amount) internal
    {
        _token.approve(_spender, 0); //first reset to 0 to be safe
        if (_amount != 0)
        {
            _token.approve(_spender, _amount);
        }
    }
}

//File: [IVaultConfig.sol]

interface IVaultConfig
{
    //========================
    // CONSTANTS
    //========================

    function PERCENT_FACTOR() external view returns (uint256);

    //========================
    // ATTRIBUTES
    //========================
    
    //fees
    function rewardFeeReceiver() external view returns (address);
    function compoundFee() external view returns (uint256);
    function rewardFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
    function withdrawFeePeriod() external view returns (uint256);

    //contracts
    function migrationManager() external view returns (IMigrationManager);
    function bank() external view returns (IBank);

    //tokens
    function wrappedCoin() external view returns (IWrappedCoin);
    function stableCoin() external view returns (IToken);
}

//File: [IVault.sol]

interface IVault
{
    //========================
    // STRUCTS
    //========================
    
    struct UserInfo
    {
        uint256 layer; //layer the user is in
        uint256 layerShares; //user share of layer        
        uint256 lastDepositTime; //timestamp of last deposit
        uint256 lastActionAtBlock; //block at last performed action   
        uint256 payoutDebt; //reward debt for current layer
        uint256 totalClaimed; //total claimed payout across all layers
    }

    struct LayerInfo
    {
        uint256 payoutPercent; //equal to layer ID. say how much % get converted to payout on compound
        uint256 totalLayerShares; //total shares of user => layer
        uint256 poolShares; //shares of layer => pool /get adjusted each compound)
        uint256 totalClaimed; //total claimed payout
        uint256 totalPayouts; //total deposited payouts
        uint256 accPayoutPerShare; //accumulated payout per share
    }

    //========================
    // ATTRIBUTES
    //======================== 

    function config() external view returns (IVaultConfig);  

    //========================
    // USER INFO FUNCTIONS
    //======================== 

    function userRemainingWithdrawFeeTime(address _user) external view returns (uint256);

    //========================
    // INFO FUNCTIONS
    //======================== 

    function balanceOfVault() external view returns (uint256);

    //========================
    // LAYER INFO FUNCTIONS
    //======================== 

    function getLayers() external view returns (LayerInfo[] memory);
    function getTotalPayoutAndCompoundShares() external view returns (uint256 compoundShares, uint256 payoutShares);

    //========================
    // PAYOUT FUNCTIONS
    //======================== 

    function depositPayout(uint256 _amount) external;
}

//File: [IVaultStrategy.sol]

interface IVaultStrategy is
    IVaultPoolInfo
{
    //========================
    // ATTRIBUTES
    //========================

    function vault() external view returns (IVault);

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOf() external view returns (uint256);
    function rewardsContainsDepositToken() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW FUNCTIONS / COMPOUND
    //========================

    function deposit() external returns (uint256);
    function withdraw(address _user, uint256 _amount) external returns (uint256);
    function compound(address _user) external returns (bool);

    //========================
    // STRATEGY FUNCTIONS
    //========================

    function retireStrategy(IVaultStrategy _newStrategy) external;  
}

//File: [Vault_base.sol]

abstract contract Vault_base is
    IVault
{    
    //========================
    // ATTRIBUTES
    //========================

    IVaultConfig public override config; //vaultConfig for config data
}

//File: [Vault_withStrategy.sol]

abstract contract Vault_withStrategy is
    Vault_base
{
    //========================
    // ATTRIBUTES
    //========================

    IVaultStrategy public strategy; //currently used strategy    

    //========================
    // INFO FUNCTIONS
    //========================

    ///@return Total balance of strategy + pool
    function balanceOfVault() public view override returns (uint256)
    {
        return strategy.balanceOf();
    }
}

//File: [Vault_withUpgradableStrategy.sol]

abstract contract Vault_withUpgradableStrategy is
    Vault_withStrategy
{
    //========================
    // CONSTANTS
    //========================

    uint256 public constant STRATEGY_APPROVAL_DELAY = 1 days; //minimum time required before upgrade is allowed

    //========================
    // ATTRIBUTES
    //========================

    IVaultStrategy public proposedStrategy; //newly proposed strategy
    uint256 public proposedStrategyAt; 

    //========================
    // EVENTS
    //========================

    event NewStrategyCandidate(IVaultStrategy newStrategy);
    event UpgradeStrategy(IVaultStrategy newStrategy);
 
    //========================
    // STRATEGY FUNCTIONS
    //========================

    function proposeStrategy(IVaultStrategy _strategy) external
    {
        //check
        //requireDeployer();
        if (address(strategy) != address(0))
        {   
            require(strategy.depositToken() == _strategy.depositToken(), "Proposal has different deposit token");
        }
        require(address(this) == address(_strategy.vault()), "Proposal not valid for this Vault");

        //check for initial proposal
        if (address(strategy) == address(0))
        {
            strategy = _strategy;
            emit UpgradeStrategy(strategy);
            return;
        }
        
        //propose
        proposedStrategy = _strategy;
        proposedStrategyAt = block.timestamp;

        //event
        emit NewStrategyCandidate(_strategy);
    }

    function upgradeStrategy() external
    {
        //check
        require(address(proposedStrategy) != address(0), "There is no proposed strategy");
        require(proposedStrategyAt + STRATEGY_APPROVAL_DELAY < block.timestamp, "Delay has not passed");

        //upgrade
        strategy.retireStrategy(proposedStrategy);
        strategy = proposedStrategy;
        strategy.deposit();

        //disable proposal
        proposedStrategy = IVaultStrategy(address(0));
        proposedStrategyAt = 999999999999;

        //event
        emit UpgradeStrategy(strategy);
    }
}

//File: [Vault_withPoolInfo.sol]

abstract contract Vault_withPoolInfo is
    Vault_withStrategy,
    IVaultPoolInfo
{
    //========================
    // POOL INFO FUNCTIONS
    //========================

    function depositToken() public view override returns (IToken)
    {
        return strategy.depositToken(); 
    }

    function rewardToken() external view override returns (IToken)
    {
        return strategy.rewardToken(); 
    }

    function poolCompoundReward() external view override returns (uint256)
    {
        return strategy.poolCompoundReward(); 
    }

    function poolPending() public view override returns (uint256)
    {
        return strategy.poolPending(); 
    }

    function poolBlockOrTime() external view override returns (bool)
    {
        return strategy.poolBlockOrTime(); 
    }

    function poolDepositFee() external view override returns (uint256)
    {
        return strategy.poolDepositFee(); 
    }

    function poolWithdrawFee() external view override returns (uint256)
    {
        return strategy.poolWithdrawFee(); 
    }

    function poolAllocPoints() external view override returns (uint256)
    {
        return strategy.poolAllocPoints(); 
    }

    function poolTotalAllocPoints() external view override returns (uint256)
    {
        return strategy.poolTotalAllocPoints(); 
    }

    function poolRewardEmission() external view override returns (uint256)
    {
        return strategy.poolRewardEmission(); 
    }

    function poolTotalRewardEmission() external view override returns (uint256)
    {
        return strategy.poolTotalRewardEmission(); 
    }

    function poolStart() external view override returns (uint256)
    {
        return strategy.poolStart(); 
    }

    function poolEnd() external view override returns (uint256)
    {
        return strategy.poolEnd(); 
    }

    function poolHarvestLockUntil() external view override returns (uint256)
    {
        return strategy.poolHarvestLockUntil(); 
    }

    function poolHarvestLockDelay() external view override returns (uint256)
    {
        return strategy.poolHarvestLockDelay(); 
    }

    function isPoolFarmable() external view override returns (bool)
    {
        return strategy.isPoolFarmable(); 
    }
}

//File: [Vault_withPayoutLayers.sol]

abstract contract Vault_withPayoutLayers is
    Vault_withPoolInfo
{    
    //========================
    // CONSTANTS
    //========================

    uint256 public constant PAYOUT_PRECISION = 1e18;

    //========================
    // ATTRIBUTES
    //========================

    //users
    mapping(address => UserInfo) public users;

    //layers
    mapping(uint256 => LayerInfo) public layers; //layer info
    uint256 public selectableLayers; //number of selected layers. There is always layer 0 with 100% compound
    uint256 public layerStepSize; //step size from layer to layer

    //stats    
    uint256 public totalPoolShares; //total shares of all layers in pool

    //========================
    // EVENTS
    //========================

    event UgradeLayers(uint256 _oldLayers, uint256 _newLayers);

    //========================
    // CREATE
    //========================

    constructor()
    {
        selectableLayers = 2;
        layerStepSize = getLayerStepSize();
    }

    //========================
    // CONFIG FUNCTIONS
    //========================

    function upgradeLayers(uint256 _newLayers) external
    {
        //check
        checkValidLayerCount(_newLayers);
        require(_newLayers > selectableLayers, "Can't downgrade Layers");
        require((selectableLayers != 2
                || _newLayers != 5),
            "Invalid upgrade"
        ); //cant upgrade from 2 => 5 as layer 50 wouldn't be accessible
        
        //upgrade
        uint256 oldLayers = selectableLayers;
        selectableLayers = _newLayers;
        layerStepSize = getLayerStepSize();

        //init layers
        for (uint256 n = layerStepSize; n <= 100; n += layerStepSize)
        {
            layers[n].payoutPercent = n;
        }

        //event
        emit UgradeLayers(oldLayers, _newLayers);
    }

    //========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address _user) public view returns (uint256)
    {
        return getUserShare(_user, strategy.balanceOf());
    }

    function userPending(address _user) external view returns (uint256)
    {
        return getUserShare(_user, poolPending());
    }

    //========================
    // LAYER INFO FUNCTIONS
    //========================  

    function getLayerStepSize() private view returns (uint256)
    {
        return (selectableLayers == 0
            ? 0
            : 100 / selectableLayers
        );
    }

    ///@notice get list of all layers
    function getLayers() external view override returns (LayerInfo[] memory)
    {
        LayerInfo[] memory l = new LayerInfo[](1 + selectableLayers);

        l[0] = layers[0];
        if (layerStepSize > 0)
        {
            //load layers
            for (uint256 n = 1; n <= selectableLayers; n++)
            {                
                l[n] = layers[(n * layerStepSize)];
            }
        }

        return l; 
    }

    ///@notice calculate total compound and payout shares for given layer
    function getPayoutAndCompoundShare(uint256 _layer) public view returns (uint256 compoundShares, uint256 payoutShares)
    {
        uint256 poolShares = layers[_layer].poolShares;
        uint256 pShares = (poolShares * layers[_layer].payoutPercent) / 100; 
        return (
            (poolShares - pShares),
            pShares            
        );
    }

    ///@notice calculate total compound and payout shares across all layers
    function getTotalPayoutAndCompoundShares() public view override returns (uint256 compoundShares, uint256 payoutShares)
    {
        uint256 cShares;        
        uint256 pShares;

        //layer 0
        (compoundShares, payoutShares) = getPayoutAndCompoundShare(0);

        //additional layers
        if (layerStepSize > 0)
        {
            for (uint256 n = layerStepSize; n <= 100; n += layerStepSize)
            {
                (cShares, pShares) = getPayoutAndCompoundShare(n);
                payoutShares += pShares;
                compoundShares += cShares;
            }
        }
    }

    //========================
    // DEPOSIT / WITHDRAW FUNCTIONS
    //========================    

    ///@dev this function only handles shares and doesnt make transactions
    function depositToLayer(
        address _user,
        uint256 _amount,
        uint256 _vaultbalanceBefore //important as function is called AFTER deposit (taxed tokens)
    ) internal
    {
        //get data
        UserInfo storage user = users[_user];
        LayerInfo storage layer = layers[user.layer];
        uint256 layerShare = amountToLayerShare(user.layer, _amount, _vaultbalanceBefore);
        uint256 poolShare = amountToPoolShare(_amount, _vaultbalanceBefore);

        //layerShares
        user.layerShares += layerShare;
        layer.totalLayerShares += layerShare;

        //poolShares
        layer.poolShares += poolShare;
        totalPoolShares += poolShare;

        //payout debt
        user.payoutDebt = (user.layerShares * layer.accPayoutPerShare) / PAYOUT_PRECISION;
    }

    ///@dev this function only handles shares and doesnt make transactions
    function withdrawFromLayer(address _user, uint256 _shares) internal
    {
        //get data
        uint256 layer = users[_user].layer;
        uint256 amount = layerShareToAmount(layer, _shares);
        uint256 poolShare = amountToPoolShare(amount, balanceOfVault());

        //layerShares
        users[_user].layerShares -= _shares;
        layers[layer].totalLayerShares -= _shares;

        //poolShares
        layers[layer].poolShares -= poolShare;
        totalPoolShares -= poolShare;
    }

    //========================
    // COMPOUND FUNCTIONS
    //======================== 

    function adjustPoolSharesAfterCompound(
        uint256 _balanceBefore,
        uint256 _balanceGained
    ) internal
    {   
        //check if layer adjust is required
        if (layerStepSize == 0)
        {            
            return;
        }

        //calculate       
        uint256 sharesGained = (totalPoolShares * _balanceGained) / _balanceBefore;

        //spread across layers
        uint256 shares;
        uint256 layerSharesGained;
        uint256 addedShares = 0;
        (uint256 totalShares, ) = getTotalPayoutAndCompoundShares();        
        for (uint256 n = layerStepSize; n <= 100; n += layerStepSize)
        {
            //calulate
            (shares, ) = getPayoutAndCompoundShare(n);
            layerSharesGained = (sharesGained * shares) / totalShares;
            addedShares += layerSharesGained;                

            //adjust
            layers[n].poolShares += layerSharesGained;
        }            
        layers[0].poolShares += (sharesGained - addedShares); //give remaining
    }

    //========================
    // USER => LAYER CONVERSION FUNCTIONS
    //========================  

    ///@notice get share for given amount, at given vault balance
    function amountToLayerShare(
        uint256 _layer,
        uint256 _amount,
        uint256 _atVaultBalance
    ) internal view returns (uint256)
    {
        uint256 totalShares = layers[_layer].totalLayerShares;
        uint256 layerBalance = (totalPoolShares == 0
            ? 0
            : (_atVaultBalance * layers[_layer].poolShares) / totalPoolShares
        );
        return (totalShares == 0
            ? _amount
            : (totalShares * _amount) / layerBalance
        );
    }

    ///@notice get amount for given share, at given vault balance
    function layerShareToAmount(
        uint256 _layer,
        uint256 _shares
    ) internal view returns (uint256)
    {
        uint256 totalShares = layers[_layer].totalLayerShares;
        uint256 totalLayerBalance = poolShareToAmount(layers[_layer].poolShares);
        return (totalShares == 0
            ? _shares
            : (totalLayerBalance * _shares) / totalShares
        );
    }

    ///@notice get share of user (depending on his selected layer)
    function getUserShare(address _user, uint256 _total) internal view returns (uint256)
    {
        uint256 layer = users[_user].layer;
        uint256 totalShares = layers[layer].totalLayerShares;
        return getLayerShare(
            layer,
            (totalShares == 0
                ? 0
                : (_total * users[_user].layerShares) / totalShares
            )
        );
    }

    //========================
    // LAYER => POOL CONVERSION FUNCTIONS
    //========================  

    ///@notice get share for given amount
    function amountToPoolShare(
        uint256 _amount,
        uint256 _atVaultBalance
    ) internal view returns (uint256)
    {
        return (totalPoolShares == 0
            ? _amount
            : (totalPoolShares * _amount) / _atVaultBalance
        );
    }

    ///@notice get amount for given share
    function poolShareToAmount(uint256 _shares) internal view returns (uint256)
    {
        return (totalPoolShares == 0
            ? _shares
            : (balanceOfVault() * _shares) / totalPoolShares
        );
    }

    ///@notice get share of layer
    function getLayerShare(uint256 _layer, uint256 _total) internal view returns (uint256)
    {
        return (totalPoolShares == 0
            ? 0
            : (_total * layers[_layer].poolShares) / totalPoolShares
        );
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function requireValidLayer(uint256 _layer) internal view
    {
        require(_layer <= 100, "Invalid layer");
        require(_layer % getLayerStepSize() == 0, "Non-selectable layer");
    }

    function checkValidLayerCount(uint256 _layers) private pure
    {
        require(
            (_layers == 0               //1 layer => 100% compound
                || _layers == 1         //2 layers => 0/100% (100)
                || _layers == 2         //3 layers => 0/50/100 (50)
                || _layers == 5         //5 layers => 0/20/40/60/80/100 (20)
                || _layers == 10        //11 layers => 0/10/20/.../100 (10)
                || _layers == 20        //21 layers => 0/5/10/15.../100 (5)
            ),
            "Invalid Layer count"
        );
    }
}

//File: [Vault_withPayoutManager.sol]

abstract contract Vault_withPayoutManager is
    Vault_withPayoutLayers,
    ReentrancyGuard,
    ML_TransferHelper,
    ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //========================

    uint256 public totalClaimed; //total claimed payouts
    uint256 public totalPayouts; //total deposited payouts

    //========================
    // USER INFO FUNCTIONS
    //========================

    function userPendingPayouts(address _user) public view returns (uint256)
    {
        //get data
        UserInfo storage user = users[_user];
        LayerInfo storage layer = layers[user.layer];        

        //calculate
        uint256 payout = (user.layerShares * layer.accPayoutPerShare) / PAYOUT_PRECISION;
        return payout - user.payoutDebt;
    }

    //========================
    // DEPOSIT PAYOUT FUNCTIONS
    //========================

    function depositPayoutToLayers(uint256 _amount) internal
    {
        //deposit newly received payout to layers (skip layer 0)
        if (layerStepSize > 0)
        {            
            (, uint256 totalShares) = getTotalPayoutAndCompoundShares();
            for (uint256 n = layerStepSize; n <= 100; n += layerStepSize)
            {
                depositPayoutToLayer(
                    n,
                    _amount,
                    totalShares
                );
            }
        }        
        totalPayouts += _amount;
    }

    function depositPayoutToLayer(uint256 _layer, uint256 _amount, uint256 _totalShares) private
    {
        //calculate payout share
        (, uint256 shares) = getPayoutAndCompoundShare(_layer);
        uint256 layerPayout = (_amount * shares) / _totalShares;

        //adjust
        LayerInfo storage layer = layers[_layer];
        layer.totalPayouts += layerPayout;
        layer.accPayoutPerShare = (layerPayout * PAYOUT_PRECISION) / layer.totalLayerShares;
    }

    //========================
    // PAYOUT FUNCTIONS
    //========================

    function claim() public
    {
        claimFor(msg.sender);
    }

    function claimFor(address _user) public nonReentrant
    {   
        UserInfo storage user = users[_user];
        LayerInfo storage layer = layers[user.layer];        

        //claim
        uint256 pending = userPendingPayouts(_user);
        if (pending > 0)
        {
            IBank bank = config.bank();
            if (address(bank) == address(0))
            {
                //transfer directly to user
                transferETH(
                    _user,
                    pending
                );
            }
            else
            {
                bank.depositETHFor{ value: pending }(_user);
            }

            //statistics
            user.totalClaimed += pending;
            layer.totalClaimed += pending;
            totalClaimed += pending;
        }

        //payout debt
        user.payoutDebt = (user.layerShares * layer.accPayoutPerShare) / PAYOUT_PRECISION;
    }
}

contract VaultV2 is
    Vault_withPayoutManager,
    Vault_withUpgradableStrategy,
    ML_RecoverFunds
{
    //========================
    // STRUCTS
    //========================

    struct UserTransactionInfo
    {
        uint256 layer;
        uint256 movedShares;
        uint256 sharesAfter;
        uint256 amount;
        uint256 movedAmount;        
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    struct UserSwitchLayerInfo
    {
        uint256 oldLayer;
        uint256 newLayer;
    }

    //========================
    // CONSTANTS
    //========================

	string public constant VERSION = "2.0.0";
    
    //========================
    // ATTRIBUTES
    //========================

    uint256 public lastCompound; //timestamp of last compound

    //========================
    // EVENTS
    //========================

    event Deposit(
        address indexed user,
        UserTransactionInfo userTxInfo
    );
    event Withdraw(
        address indexed user,
        UserTransactionInfo userTxInfo
    );
    event SwitchLayer(
        address indexed user,
        UserSwitchLayerInfo userSwitchLayerInfo
    );
    event Compound(
        address indexed user
    ); //TODO: list of all new layer shares and total balances    
    event DepositPayout(
        address indexed payer,
        uint256 amount
    );

    //========================
    // CREATE
    //========================

    constructor(IVaultConfig _config)
    {
        //init
        config = _config;
    }

    //========================
    // USER CONFIG FUNCTIONS
    //========================

    function switchLayer(uint256 _newLayer) external
    {
        //check
        requireValidLayer(_newLayer);        
        require(_newLayer != users[msg.sender].layer, "Already in layer");

        //check if user has balance
        uint256 balance = balanceOf(msg.sender);
        if (balance == 0)
        {
            //switch layer
            users[msg.sender].layer = _newLayer;
            return;
        }

        //get data
        UserInfo storage user = users[msg.sender];  
        uint256 oldLayer = user.layer;      

        //claim
        claim();

        //withdraw => switch layer => deposit
        withdrawFromLayer(
            msg.sender, 
            user.layerShares
        );
        users[msg.sender].layer = _newLayer;
        depositToLayer(
            msg.sender, 
            balance, 
            balanceOfVault() //balance didn't change
        );

        //TODO: event
        emit SwitchLayer(
            msg.sender,
            UserSwitchLayerInfo(
            {
                oldLayer: oldLayer,
                newLayer: _newLayer                
            })
        );
    }

    //========================
    // USER INFO FUNCTIONS
    //========================

    function userRemainingWithdrawFeeTime(address _user) external view override returns (uint256)
    {
        uint256 timeSinceLastDeposit = block.timestamp - users[_user].lastDepositTime;
        if (timeSinceLastDeposit >= config.withdrawFeePeriod())
        {
            return 0;
        }

        return (config.withdrawFeePeriod() - timeSinceLastDeposit);
    }

    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function deposit(uint256 _amount) external 
    {
        depositFor(msg.sender, _amount);        
    }

    function depositFor(address _user, uint256 _amount) public nonReentrant
    {
        //check
        requireBlockLock(_user);
        require(address(strategy) != address(0), "No strategy defined");        
        require(_amount > 0, "Invalid amount");
        require(_amount <= depositToken().balanceOf(_user), "Insufficient balance");

        //compound required?
        compoundIfRewardContainsDeposit();

        //deposit into pool
        UserTransactionInfo memory userTxInfo = createUserTxInfo_deposit(_user, _amount);
        uint256 balanceBefore = balanceOfVault();
        uint256 deposited = farmUser(msg.sender, _amount); //first deposit, to get actual deposit (in case of taxes)

        //adjust shares
        depositToLayer(_user, deposited, balanceBefore);

        //user deposit time
        users[_user].lastDepositTime = block.timestamp;

        //event for frontend
        emit Deposit(
            _user,
            fillUserTxInfo(
                _user, 
                userTxInfo, 
                deposited
            )
        );
    }

    //========================
    // WITHDRAW FUNCTIONS
    //========================

    function withdraw(uint256 _shares) external nonReentrant
    {
        //check
        requireBlockLock(msg.sender);
        require(_shares > 0, "Nothing to withdraw");
        require(users[msg.sender].layerShares > 0, "Insufficient shares");        

        //limit shares
        if (_shares > users[msg.sender].layerShares)
        {
            _shares = users[msg.sender].layerShares;
        }

        //compound required?
        compoundIfRewardContainsDeposit();

        //adjust shares
        UserTransactionInfo memory userTxInfo = createUserTxInfo_withdraw(msg.sender, _shares);
        withdrawFromLayer(msg.sender, _shares);

        //withdraw from strategy
        uint256 withdrawn = strategy.withdraw(msg.sender, userTxInfo.amount);

        //event
        emit Withdraw(
            msg.sender,
            fillUserTxInfo(
                msg.sender,
                userTxInfo,
                withdrawn
            )
        );
    }

    //========================
    // COMPOUND FUNCTIONS
    //========================

    function compound() external nonReentrant
    {
        _compound(msg.sender);
    }

    function _compound(address _user) private
    {
        uint256 balanceBefore = balanceOfVault();
        (bool compounded) = strategy.compound(_user);
        if (compounded)
        {
            //stats            
            lastCompound = block.timestamp;

            //adjust pool shares
            uint256 balanceGained = balanceOfVault() - balanceBefore;
            if (balanceGained > 0)
            {
                /*
                adjustPoolSharesAfterCompound(
                    balanceBefore,
                    balanceGained
                );
                */
            }
        }
    }

    function compoundIfRewardContainsDeposit() private
    {
        //check if compound required
        if (strategy.rewardsContainsDepositToken())
        {
            _compound(msg.sender);
        }
    }    

    //========================
    // DEPOSIT PAYOUT FUNCTIONS
    //========================

    function depositPayout(uint256 _amount) external override
    {
        //transfer payout
        safeTransferFrom(
            config.wrappedCoin(),
            _amount,
            msg.sender,
            address(this)
        );

        //unwrap
        config.wrappedCoin().withdraw(_amount);

        //deposit payout
        depositPayoutToLayers(_amount);

        //event
        emit DepositPayout(
            msg.sender,
            _amount
        );
    }

    //========================
    // FARM FUNCTIONS
    //========================
    
    function farmUser(address _user, uint256 _amount) internal returns (uint256)
    {
        //from user to strategy (this way P2P tax is reduced)
        safeTransferFrom(
            depositToken(),
            _amount,
            _user,
            address(strategy)
        );
        return strategy.deposit();
    }

    //========================
    // TX INFO FUNCTIONS
    //======================== 

    function createUserTxInfo_deposit(address _user, uint256 _amount) private view returns (UserTransactionInfo memory)
    {
        return UserTransactionInfo(
        {
            layer: users[_user].layer,
            movedShares: getLayerShare(balanceOfVault(), _amount),
            sharesAfter: 0,
            amount: _amount,
            movedAmount: 0,
            balanceBefore: balanceOf(_user),
            balanceAfter: 0
        });
    }

    function createUserTxInfo_withdraw(address _user, uint256 _shares) private view returns (UserTransactionInfo memory)
    {
        return UserTransactionInfo(
        {
            layer: users[_user].layer,
            movedShares: _shares,
            sharesAfter: 0,
            amount: layerShareToAmount(users[_user].layer, _shares),
            movedAmount: 0,
            balanceBefore: balanceOf(_user),
            balanceAfter: 0
        });
    }

    function fillUserTxInfo(
        address _user, 
        UserTransactionInfo memory _data,
        uint256 _movedAmount
    ) private view returns (UserTransactionInfo memory)
    {
        _data.sharesAfter = users[_user].layerShares;
        _data.movedAmount = _movedAmount;
        _data.balanceAfter = balanceOf(_user);
        return _data;
    }

    //========================
    // SECURITY FUNCTIONS
    //======================== 

    function requireBlockLock(address _user) private
    {
        require(block.number != users[_user].lastActionAtBlock, "Block lock");
        users[_user].lastActionAtBlock = block.number;
    }

    //========================
    // HELPER FUNCTIONS
    //========================  

    receive() external payable {}

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function recoverETH(uint256 _amount, address _to) external
    {
        _recoverETH(_amount, _to);
    }

    function recoverToken(IToken _token, uint256 _amount, address _to) external
    {
        _recoverToken(_token, _amount, _to);
    } 
}