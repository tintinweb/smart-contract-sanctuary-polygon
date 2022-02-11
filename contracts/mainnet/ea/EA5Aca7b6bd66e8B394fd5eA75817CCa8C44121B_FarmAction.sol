/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/DeFi/Vaults/BaseSiloAction.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//swap actions should check and make sure the amount is enough to even make a swap
//if an action charges a fee, then it should take it in here
//TODO each action needs to have some fee thing worked out
//TODO each action should have a view function that allows the front end to enter the required config data(EX: input tokens, outputs tokens, farm address), then returns the abi encoded config data
abstract contract BaseSiloAction {

    bytes public configurationData;//if not set on deployment, then they use the value in the Silo
    string public name;
    uint constant public MAX_TRANSIENT_VARIABLES = 4;
    address public actionManager;
    uint constant public FEE_DECIMALS = 10000;

    function enter(address implementation, bytes memory configuration, bytes memory inputData) public virtual returns(uint[4] memory);

    function exit(address implementation, bytes memory configuration, bytes memory outputData) public virtual returns(uint[4] memory);

    function getConfig() public view returns(bytes memory){
        return configurationData;
    }

    function checkMaintain(bytes memory configuration) public view virtual returns(bool);

    function _takeFee(address _action, uint _siloId, uint _gains, address _token) internal virtual returns(uint remaining);

    //TODO add functions so that APR is automatically updated as people use the action, or even just stats? Like how much GFI has been swapped for with this action?
    function validateConfig(bytes memory configData) public view virtual returns(bool); 
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPD
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


// File contracts/interfaces/IFarmV2.sol

struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
}

struct FarmInfo {
    IERC20 lpToken;
    IERC20 rewardToken;
    uint startBlock;
    uint blockReward;
    uint bonusEndBlock;
    uint bonus;
    uint endBlock;
    uint lastRewardBlock;  // Last block number that reward distribution occurs.
    uint accRewardPerShare; // rewards per share, times 1e12
    uint farmableSupply; // total amount of tokens farmable
    uint numFarmers; // total amount of farmers
}

interface IFarmV2 {

    function initialize() external;
    function withdrawRewards(uint256 amount) external;
    function FarmFactory() external view returns(address);
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external; 
    function pendingReward(address _user) external view returns (uint256);

    function userInfo(address user) external view returns (UserInfo memory);
    function farmInfo() external view returns (FarmInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    
}


// File contracts/interfaces/IAction.sol

interface IAction{
    function getConfig() external view returns(bytes memory config);
    function checkMaintain(bytes memory configuration) external view returns(bool);
    function validateConfig(bytes memory configData) external view returns(bool); 
}


// File @openzeppelin/contracts/utils/[email protected]

// SPD
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// SPD

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


// File contracts/interfaces/IActionManager.sol

interface IActionManager{
    function getTier(uint _siloId) external view returns(uint);
    function getFeeInfo(uint _siloId, address _action) external view returns(uint fee, address recipient);
}


// File contracts/DeFi/Vaults/Actions/FarmAction.sol







/**
enter
 input the amount of deposit tokens you want to deposit
 output the amount of reward tokens harvested

exit
 input none
 output the amount of deposit tokens sent back to silo NOTE since maintain was called right before withdraw, there would be no excess reward tokens
*/
contract FarmAction is BaseSiloAction{

    constructor(string memory _name, address _actionManager, address[MAX_TRANSIENT_VARIABLES] memory _inputs, address[MAX_TRANSIENT_VARIABLES] memory _outputs, address _farm){
        name = _name;
        actionManager = _actionManager;
        //configurationData = abi.encode(_inputs, _outputs, _farm);
    }

    function enter(address implementation, bytes memory configuration, bytes memory inputData) public override returns(uint[4] memory outputAmounts){
        bytes memory storedConfig = IAction(implementation).getConfig();
        address farm;
        if(storedConfig.length > 0){//if config is set in strategy use it
            (,,farm) = abi.decode(storedConfig, (address[4],address[4],address));
        }
        else{
            (,,farm) = abi.decode(configuration, (address[4],address[4],address));
        }
        uint[4] memory inputAmounts = abi.decode(inputData, (uint[4]));
        IFarmV2 Farm = IFarmV2(farm);
        FarmInfo memory info = Farm.farmInfo();
        info.lpToken.approve(farm, inputAmounts[0]);
        uint reward = Farm.pendingReward(address(this));
        Farm.deposit(inputAmounts[0]);
        outputAmounts[0] = reward;
        //outputAmounts[0] = _takeFee(implementation, siloId, reward, address(info.rewardToken));
    }

    function exit(address implementation, bytes memory configuration, bytes memory outputData) public override returns(uint[4] memory outputAmounts){
        bytes memory storedConfig = IAction(implementation).getConfig();
        address farm;
        address[4] memory output;
        if(storedConfig.length > 0){//if config is set in strategy use it
            (,output,farm) = abi.decode(storedConfig, (address[4],address[4],address));
        }
        else{
            (,output,farm) = abi.decode(configuration, (address[4],address[4],address));
        }
        IFarmV2 Farm = IFarmV2(farm);
        UserInfo memory info = Farm.userInfo(address(this));
        uint withdrawn = info.amount;
        uint reward = Farm.pendingReward(address(this));
        Farm.withdraw(info.amount);
        //_takeFee(implementation, siloId, reward, output[0]);
        outputAmounts[0] = withdrawn;
    }

    function createConfig(address[4] memory _inputs, address[4] memory _outputs, address _farm) public pure returns(bytes memory configData){
        configData = abi.encode(_inputs, _outputs, _farm);
    }

    function validateConfig(bytes memory configData) public view override returns(bool){
        return true;
    }

    function checkMaintain(bytes memory configuration) public override view returns(bool){
        return false;
    }

    function _takeFee(address _action, uint _siloId, uint _gains, address _token) internal override returns(uint remaining){
        (uint fee, address recipient) = IActionManager(actionManager).getFeeInfo(_siloId, _action);
        uint feeToTake = _gains * fee / FEE_DECIMALS;
        SafeERC20.safeTransfer(IERC20(_token), recipient, feeToTake);
        remaining = _gains - feeToTake;
    }
}