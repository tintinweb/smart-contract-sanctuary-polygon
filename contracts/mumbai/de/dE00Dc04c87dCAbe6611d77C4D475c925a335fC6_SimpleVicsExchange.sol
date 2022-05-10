// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../../common/Ownable.sol";
import "../../common/PriceOracle.sol";
import "../interfaces/IVicsExchange.sol";
import "../interfaces/IDABotManager.sol";

interface IERC20Token {
    function decimals() external view returns(uint8);
}

contract SimpleVicsExchange is IVicsExchange, Context, Ownable, Initializable {

    using SafeERC20 for IERC20;

    uint public _vicsPrice;
    PriceOracle public priceOracle;
    IERC20 public _vics;
    IDABotManager public _botManager;
    

    event Swap(address indexed asset, uint amountIn, uint amountOut);
    event VicsPriceUpdated(uint previousPrice, uint newPrice);
    event BotManagerChanged(address indexed oldManager, address indexed newManager);

    function initialize(IERC20 vics_, uint price, PriceOracle oracle) external payable initializer {
        _vicsPrice = price;
        priceOracle = oracle;
        _vics = vics_;
        _transferOwnership(_msgSender());
    }

    function setVicsPrice(uint price) external onlyOwner {
        emit VicsPriceUpdated(_vicsPrice, price);
        _vicsPrice = price;
    }

    function vicsPrice() public view returns(uint) {
        uint currentVicsPrice = priceOracle.getAssetPrice(address(_vics));
        if (currentVicsPrice == 0) 
            currentVicsPrice = _vicsPrice;
        return currentVicsPrice;
    }

    function setBotManager(address account) external onlyOwner {
        emit BotManagerChanged(address(_botManager), account);
        _botManager = IDABotManager(account);
    }

    function withdraw(IERC20 asset, uint amount) external onlyOwner {
        asset.safeTransfer(owner(), amount);
    }

    function swap(IERC20 asset, uint amountIn) external override returns(uint amountOut) { 
        uint assetPrice = priceOracle.getAssetPrice(address(asset));
        uint currentVicsPrice = vicsPrice();

        require(assetPrice > 0, "VicsExchange: cannot determine asset price");
        require(_vicsPrice > 0, "VicsExchange: vics price is not set");
        require(address(_botManager) != address(0), "VicsExchange: bot manager not set");
        require(_botManager.isRegisteredBot(_msgSender()), "VicsExchange: for registered bot only");

        asset.safeTransferFrom(_msgSender(), address(this), amountIn);

        amountOut = toWad(asset, amountIn) * assetPrice / currentVicsPrice;
        require(_vics.balanceOf(address(this)) >= amountOut, 'VicsExchange: insufficient VICS supply');
        _vics.safeTransfer(_msgSender(), amountOut);

        emit Swap(address(asset), amountIn, amountOut);
    }

    function toWad(IERC20 asset, uint amount) private view returns(uint) {
        uint8 assetDecimal = IERC20Token(address(asset)).decimals();
        if (assetDecimal < 18)
            amount = amount * 10**(18 - assetDecimal);
        return amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IPriceFeed.sol";
import "./Ownable.sol";

import "./RoboFiAddress.sol";

contract PriceOracle is Context, Ownable {

    using RoboFiAddress for address;

    IPriceFeed internal _defaultPriceFeed;
    mapping(address => IPriceFeed) internal  _priceFeedMap;

    constructor(IPriceFeed defaultPriceFeed) {
        _defaultPriceFeed = defaultPriceFeed;
    }

    function setDefaultPriceFeed(IPriceFeed priceFeed) external onlyOwner {
        _defaultPriceFeed = priceFeed;
    }

    function setPriceFeed(address asset, IPriceFeed priceFeed) external onlyOwner {
        _priceFeedMap[asset] = priceFeed;
    }

    function getPriceFeed(address asset) public view returns(IPriceFeed priceFeed) {
        priceFeed = _priceFeedMap[asset];
        if (address(priceFeed) == address(0))
            priceFeed = _defaultPriceFeed;
    }

    function getAssetPrice(address asset) public view returns(uint) {
        if (asset.isCertToken()) {
            IDABotCertToken certToken = IDABotCertToken(asset);
            uint rate = certToken.value(1e18);
            address underlyAsset = address(certToken.asset());
            return getAssetPrice(underlyAsset) * rate / 1e18;
        }

        if (asset.isGovernToken()) {
            IDABotGovernToken gToken = IDABotGovernToken(asset);
            uint rate = gToken.value(1e18);
            address underlyAsset = address(gToken.asset());
            return getAssetPrice(underlyAsset) * rate / 1e18;
        }

        if (asset.isTreasuryAsset()) {
            asset = address(ITreasuryAsset(asset).asset());
        }

        IPriceFeed priceFeed = getPriceFeed(asset);
        return priceFeed.getAssetPrice(asset);  
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IVicsExchange {
    /**
    @dev Exchanges the given input amount of a specific asset to an equivalent amount
        of VICS.
     */
    function swap(IERC20 asset, uint amountIn) external returns(uint amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBotVault.sol";
import "../DABotCommon.sol";
import "../../common/IRoboFiFactory.sol";
import "../../common/IConfigurator.sol";

interface IDABotManagerEvent {
    event BotRemoved(address indexed bot);
    event BotDeployed(uint botId, address indexed bot, BotDetail detail); 
    event TemplateRegistered(address indexed template, string name, string version, uint8 templateType);
}

interface IDABotManager is IDABotManagerEvent {
    
    function configurator() external view returns(IConfigurator);
    function vaultManager() external view returns(IBotVaultManager);
    function addTemplate(address template) external;
    function templates() external view returns(address[] memory);
    function isRegisteredTemplate(address template) external view returns(bool);
    function isRegisteredBot(address botAccount) external view returns(bool);
    function totalBots() external view returns(uint);
    function botIdOf(string calldata qualifiedName) external view returns(int);
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output);
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external;
    function snapshot(address botAccount) external;
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

pragma solidity ^0.8.0;

/**
@dev The interface for the price feed consumed by PriceOracle.
 */
interface IPriceFeed {
    
    /**
    @dev Query the latest price of the specified asset.
     */
    function getAssetPrice(address asset) external view returns(uint);
}

interface IChainLinkPriceProvider {
    function latestAnswer() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../treasury/ITreasuryAsset.sol";
import "../dabot/interfaces/IDABotCertToken.sol";
import "../dabot/interfaces/IDABotGovernToken.sol";

library RoboFiAddress {

    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    function isTreasuryAsset(address account) internal view returns(bool) {
        return account.supportsInterface(type(ITreasuryAsset).interfaceId);
    } 

    function isCertToken(address account) internal view returns(bool) {
        return account.supportsInterface(type(IDABotCertToken).interfaceId);
    }

    function isGovernToken(address account) internal view returns(bool) {
        return account.supportsInterface(type(IDABotGovernToken).interfaceId);
    }

    function safeTransferFrom(IERC20 asset, address from, address to, uint amount) internal {
        if (isNativeAsset(address(asset))) {
            // cannot do this
        } else {
            asset.safeTransferFrom(from, to, amount);
        }
    }

    function safeTransfer(IERC20 asset, address to, uint amount) internal {
        if (isNativeAsset(address(asset))) {
            payable(to).transfer(amount);
        } else {
            asset.safeTransfer(to, amount);
        }
    }

    function isNativeAsset(address asset) internal pure returns(bool) {
        return asset == NATIVE_ASSET_ADDRESS;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/IRoboFiERC20.sol";

address constant NATIVE_ASSET_ADDRESS = address(0x1E1e1E1E1e1e1e1e1e1E1E1E1E1e1e1E1e1e1E1E);

interface ITreasuryAssetEvent {
    event Lock(address indexed account, uint256 amount);
    event Unlock(address indexed caller, uint256 amount, address indexed account);
    event Slash(address indexed bot, uint256 amount);
    event FundManagerChanged(address indexed fundmanager);
}

interface ITreasuryAsset is IRoboFiERC20, ITreasuryAssetEvent {

    /**
    @dev Gets the total locked amount.
     */
    function totalLocked() external view returns(uint);

    /**
    @dev Gets the address of the underlying asset.
     */
    function asset() external view returns(IRoboFiERC20);

    /**
    @dev Deposits `amount` of original asset, and gets back an equivalent amount of token.
    **/
    function mint(address to, uint256 amount) external payable;

    /**
    @dev Burns `amount` of sToken to get back original  tokens
     */
    function burn(uint256 amount) external;

    /**
    @dev Burns `amount` of sToken WITHOUT get back the original tokens (this is for trading loss). 
    Only accept calls from registred DABot.
     */
    function slash(uint256 amount) external;

    /**
    @dev Locks `amount` of token from the caller's account. An equivalent amount of 
    original asset will be transferred to the fund manager.

    Return the locked balanced of the caller's account.
    **/    
    function lock(uint256 amount) external;

    /**
    @dev Get the locked amounts of sToken for `user`
    **/
    function lockedBalanceOf(address user) external view returns (uint256);

    /**
    @dev Gets `amount` of tocken from the caller account, and decrease the locked balance of `user`. 
    **/
    function unlock(address user, uint256 amount) external payable;

    /**
    @dev Determines if the underlying asset is native token or not.
     */
    function isNativeAsset() external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotCertTokenEvent {
    /**
    @dev Triggered when the bot owner locked an amount of certificate token for trading (or yield farming).
    @param assetAmount the amount of the underlying asset locked.
     */
    event Lock(uint assetAmount);

    /**
    @dev Triggered when the bot owner unlocked an amount of certificate token.
    @param assetAmount the amount of the underlying asset unlocked.
     */
    event Unlock(uint assetAmount);

    /**
    @dev Triggered when the amount of pegged assets of this certificate token has been changed.
    @param amount the changed amount.
    @param profitOrLoss true if the the pegged assets increase, false on otherwise.
     */
    event Compound(uint amount, bool profitOrLoss);
}

interface IDABotCertToken is IERC20, IDABotCertTokenEvent {

    /**
    @dev Gets the total deposit of the underlying asset within this certificate.
     */
    function totalStake() external view returns(uint);

    function totalLiquid() external view returns(uint);

    /**
    @dev Queries the bot who owned this certificate.
     */
    function owner() external view returns(address);
    
    /**
    @dev Gets the underlying asset of this certificate.
     */
    function asset() external view returns (IERC20);
    
    /**
    @dev Returns the equivalent amount of the underlying asset for the given amount
        of certificate tokens.
    @param certTokenAmount - the amount of certificate tokens.
     */
    function value(uint certTokenAmount) external view returns(uint);

    function lock(uint assetAmount) external;

    function unlock(uint assetAmount) external;

    /**
    @dev Mints an amount of certificate tokens to the given amount. The equivalent of
        underlying asset should be tranfered to this certificate contract by the caller.
    @param account - the address to recieve minted tokens.
    @param certTokenAmount - the amount of tokens to mint.
    @notice Only the owner bot can call this function.
     */
    function mint(address account, uint certTokenAmount) external returns(uint);

    /**
    @dev Burns an amount of certificate tokens, and returns the equivalant amount of
        the underlying asset to the specified account.
    @param account - the address holing certificate tokens to burn.
    @param certTokenAmount - the amount of certificate token to burn.
    @return the equivalent amount of underlying asset tranfered to the specified account.
    @notice Only the owner bot can call this function.
     */
    function burn(address account, uint certTokenAmount) external returns (uint);

    /**
    @dev Burns an amount of certificate tokens, and returns the equivalent amount of the 
        underlying asset to the caller.
    @param amount - the amount of certificate token to burn.
    @return the equivalent amount of underlying asset transfered to the caller.
     */
    function burn(uint amount) external returns(uint);

    /**
    @dev Burns an amount of certificate tokens without returning any underlying assets.
    @param account - the account holding certificate tokens to burn.
    @param amount - the amount of certificate tokens to burn.
    @notice Only owner bot can call this function.
     */
    function slash(address account, uint amount) external;

    /**
    @dev Compound a given amount of the underlying asset to the total deposit. 
        The compoud could be either profit or loss.
    @param amount - the compound amount.
    @param profitOrLoss - `true` to increase the total deposit, `false` to decrease.
     */
    function compound(uint amount, bool profitOrLoss) external;

    /**
    @dev Deletes this certificate token contracts.
     */
    function finalize() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotGovernToken is IERC20 {

    function owner() external view returns(address);
    function asset() external view returns (IERC20);
    function value(uint amount) external view returns(uint);
    function mint(address account, uint amount) external;
    function burn(uint amount) external returns(uint);

    function snapshot() external;
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoboFiERC20 is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/IRoboFiERC20.sol";

struct VaultData {
    address botToken;
    IERC20 asset;
    address bot;
    uint8 index;                // the index-th vault generated from botToken
                                //  0 - warmup vault, 1 - regular vault, 2 - VIP vault
    bytes4 vaultType;           // type of the vault, used to determine the vault handler
}

struct UserInfo {
    uint deposit;
    uint debtPoints;
    uint debt;
    uint lockPeriod;
    uint lastDepositTime;
}

struct VaultInfo {
    VaultData data;             
    UserInfo user;
    uint totalDeposit;          // total deposits in the vault
    uint accRewardPerShare;     // the pending reward per each unit of deposit
    uint lastRewardTime;        // the block time of the last reward transaction
    uint pendingReward;         // the pending reward for the caller
    bytes option;               // vault option
} 

struct RegularVaultOption {
    bool restricted;    // restrict deposit activity to bot only
}


interface IBotVaultEvent {
    event Deposit(uint vID, address indexed payor, address indexed account, uint amount);
    event Widthdraw(uint vID, address indexed account, uint amount);
    event RewardAdded(uint vID, uint assetAmount);
    event RewardClaimed(uint vID, address indexed account, uint amount);
    event Snapshot(uint vID, uint snapshotId);
}

interface IBotVault is IBotVaultEvent {
    function deposit(uint vID, uint amount) external;
    function delegateDeposit(uint vID, address payor, address account, uint amount, uint lockTime) external;
    function withdraw(uint vID, uint amount) external;
    function delegateWithdraw(uint vID, address account, uint amount) external;
    function pendingReward(uint vID, address account) external view returns(uint);
    function balanceOf(uint vID, address account) external view returns(uint);
    function balanceOfAt(uint vID, address account, uint blockNo) external view returns(uint);
    function updateReward(uint vID, uint assetAmount) external;
    function claimReward(uint vID, address account) external;

    /**
    @dev Queries user deposit info for the given vault.
    @param vID the vault ID to query.
    @param account the user account to query.
     */
    function getUserInfo(uint vID, address account) external view returns(UserInfo memory result);
    function getVaultInfo(uint vID, address account) external view returns(VaultInfo memory);
    function getVaultOption(uint vID) external view returns(bytes memory);
    function setVaultOption(uint vID, bytes calldata option) external;
}

interface IBotVaultManagerEvent is IBotVaultEvent {
    event OpenVault(uint vID, VaultData data);
    event DestroyVault(uint vID);
    event RegisterHandler(bytes4 vaultType, address handler);
    event BotManagerUpdated(address indexed botManager);
}

interface IBotVaultManager is IBotVault, IBotVaultManagerEvent {
    function vaultOf(uint vID) external view returns(VaultData memory result);
    function validVault(uint vID) external view returns(bool);
    function createVault(VaultData calldata data) external returns(uint);
    function destroyVault(uint vID) external;
    function vaultId(address botToken, uint8 vaultIndex) external pure returns(uint);
    function registerHandler(bytes4 vaultType, IBotVault handler) external;
    function botManager() external view returns(address);
    function setBotManager(address account) external;
    function snapshot(uint vID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IDABotComponent.sol";

enum BotStatus { PRE_IBO, IN_IBO, ACTIVE, ABANDONED }

struct BotModuleInitData {
    bytes32 moduleId;
    bytes data;
}

struct BotSetting {             // for saving storage, the meta-fields of a bot are encoded into a single uint256 byte slot.
    uint64 iboTime;             // 32 bit low: iboStartTime (unix timestamp), 
                                // 32 bit high: iboEndTime (unix timestamp)
    uint24 stakingTime;         // 8 bit low: warm-up time, 
                                // 8 bit mid: cool-down time
                                // 8 bit high: time unit (0 - day, 1 - hour, 2 - minute, 3 - second)
    uint32 pricePolicy;         // 16 bit low: price multiplier (fixed point, 2 digits for decimal)
                                // 16 bit high: commission fee in percentage (fixed point, 2 digit for decimal)
    uint128 profitSharing;      // packed of 16bit profit sharing: bot-creator, gov-user, stake-user, and robofi-game
    uint initDeposit;           // the intial deposit (in VICS) of bot-creator
    uint initFounderShare;      // the intial shares (i.e., governance token) distributed to bot-creator
    uint maxShare;              // max cap of gtoken supply
    uint iboShare;              // max supply of gtoken for IBO. Constraint: maxShare >= iboShare + initFounderShare
}

struct BotMetaData {
    string name;
    string symbol;
    string version;
    uint8 botType;
    bool abandoned;
    bool isTemplate;        // determine this module is a template, not a bot instance
    bool initialized;       // determines whether the bot has been initialized 
    address botOwner;       // the public address of the bot owner
    address botManager;
    address botTemplate;    // address of the template contract 
    address gToken;         // address of the governance token
}

struct BotDetail { // represents a detail information of a bot, merely use for bot infomation query
    uint id;                    // the unique id of a bot within its manager.
                                // note: this id only has value when calling {DABotManager.queryBots}
    address botAddress;         // the contract address of the bot.

    BotStatus status;           // 0 - PreIBO, 1 - InIBO, 2 - Active, 3 - Abandonned
    uint8 botType;              // type of the bot (inherits from the bot's template)
    string botSymbol;           // get the bot name.
    string botName;             // get the bot full name.
    address governToken;        // the address of the governance token
    address template;           // the address of the master contract which defines the behaviors of this bot.
    string templateName;        // the template name.
    string templateVersion;     // the template version.
    uint iboStartTime;          // the time when IBO starts (unix second timestamp)
    uint iboEndTime;            // the time when IBO ends (unix second timestamp)
    uint warmup;                // the duration (in days) for which the staking profit starts counting
    uint cooldown;              // the duration (in days) for which users could claim back their stake after submiting the redeem request.
    uint priceMul;              // the price multiplier to calculate the price per gtoken (based on the IBO price).
    uint commissionFee;         // the commission fee when buying gtoken after IBO time.
    uint initDeposit;           
    uint initFounderShare;
    uint144 profitSharing;
    uint maxShare;              // max supply of governance token.
    uint circulatedShare;       // the current supply of governance token.
    uint iboShare;              // the max supply of gtoken for IBO.
    uint userShare;             // the amount of governance token in the caller's balance.
    UserPortfolioAsset[] portfolio;
}

struct BotModuleInfo {
    string name;
    string version;
    address handler;
}

struct PortfolioCreationData {
    address asset;
    uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
    uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
    uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
}

struct PortfolioAsset {
    address certToken;    // the certificate asset to return to stake-users
    uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
    uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
    uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
}

struct UserPortfolioAsset {
    address asset;
    PortfolioAsset info;
    uint256 userStake;
    uint256 totalStake;     // the total stake of all users.
    uint256 certSupply;     // the total supply of the certificated token
}

/**
@dev Records warming-up certificate tokens of a DABot.
*/
struct LockerData {         
    address bot;            // the DABOT which creates this locker.
    address owner;          // the locker owner, who is albe to unlock and get tokens after the specified release time.
    address token;          // the contract of the certificate token.
    uint64 created_at;      // the moment when locker is created.
    uint64 release_at;      // the monent when locker could be unlock. 
}

/**
@dev Provides detail information of a warming-up token lock, plus extra information.
    */
struct LockerInfo {
    address locker;
    LockerData info;
    uint256 amount;         // the locked amount of cert token within this locker.
    uint256 reward;         // the accumulated rewards
    address asset;          // the stake asset beyond the certificated token
}

struct MintableShareDetail {
    address asset;
    uint stakeAmount;
    uint mintableShare;
    uint weight;
    uint iboCap;
}

struct AwardingDetail {
    address asset;
    uint compound;
    uint reward;
    uint compoundMode;  // 0 - increase, 1 - decrrease
}

struct StakingReward {
    address asset;
    uint amount;
}

struct BenefitciaryInfo {
    address account;
    string name;
    string shortName;
    uint weight;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoboFiFactory {
    function deploy(address masterContract, 
                    bytes calldata data, 
                    bool useCreate2) 
        external 
        payable 
        returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Roles {
    bytes32 constant ROLE_ADMIN = keccak256('operator.dabot.role');
    bytes32 constant ROLE_OPERATORS = keccak256('operator.dabot.role');
    bytes32 constant ROLE_TEMPLATE_CREATOR = keccak256('creator.template.dabot.role');
    bytes32 constant ROLE_BOT_CREATOR = keccak256('creator.dabot.role');
    bytes32 constant ROLE_FUND_APPROVER = keccak256('approver.fund.role');
}

library AddressBook {
    bytes32 constant ADDR_FACTORY = keccak256('factory.address');
    bytes32 constant ADDR_VICS = keccak256('vics.address');
    bytes32 constant ADDR_TAX = keccak256('tax.address');
    bytes32 constant ADDR_GOVERNANCE = keccak256('governance.address');
    bytes32 constant ADDR_GOVERNANCE_EXECUTOR = keccak256('executor.governance.address');
    bytes32 constant ADDR_BOT_MANAGER = keccak256('botmanager.address');
    bytes32 constant ADDR_VICS_EXCHANGE = keccak256('exchange.vics.address');
    bytes32 constant ADDR_TREASURY_MANAGER = keccak256('treasury-manager.address');
    bytes32 constant ADDR_CEX_FUND_MANAGER = keccak256('fund-manager.address');
    bytes32 constant ADDR_CEX_DEFAULT_MASTER_ACCOUNT = keccak256('default.master.address');
}

library Config {
    /// The amount of VICS that a proposer has to pay when create a new proposal
    bytes32 constant PROPOSAL_DEPOSIT = keccak256('deposit.proposal.config');

    /// The percentage of proposal creation fee distributed to the account that execute a propsal
    bytes32 constant PROPOSAL_REWARD_PERCENT = keccak256('reward.proposal.config');

    /// The minimum VICS a bot creator has to deposit to a newly created bot
    bytes32 constant CREATOR_DEPOSIT = keccak256('deposit.creator.config');

    /// The minim 
    bytes32 constant PROPOSAL_CREATOR_MININUM_POWER = keccak256('minpower.goverance.config');
    
    /// The minimum percentage of for-votes over total votes a proposal has to achieve to be passed
    bytes32 constant PROPOSAL_MINIMUM_QUORUM = keccak256('minquorum.governance.config');

    /// The minimum difference (in percentage) between for-votes and against-vote for a proposal to be passed
    bytes32 constant PROPOSAL_VOTE_DIFFERENTIAL = keccak256('differential.governance.config');

    /// The voting duration of a proposal
    bytes32 constant PROPOSAL_DURATION = keccak256('duration.goverance.config');

    /// The interval that a passed proposed is waiting in queue before being executed
    bytes32 constant PROPOSAL_EXECUTION_DELAY = keccak256('execdelay.governance.config');
}

interface IConfigurator {
    function addressOf(bytes32 addrId) external view returns(address);
    function configOf(bytes32 configId) external view returns(uint);
    function bytesConfigOf(bytes32 configId) external view returns(bytes memory);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant IDABotFarmingModuleID = keccak256("farming.module");
bytes32 constant IDABotFundManagerModuleID = keccak256('fundmanager.module');
bytes32 constant IDABotStakingModuleID = keccak256("staking.module");
bytes32 constant IDABotGovernModuleID = keccak256('governance.module');
bytes32 constant IDABotSettingModuleID = keccak256('setting.module');
bytes32 constant IDABotWhitelistModuleID = keccak256("whitelist.module");

bytes32 constant GovTokenHandlerID = keccak256('govtokenimpl.dabot.module');
bytes32 constant CertTokenHandlerID = keccak256('certtokenimpl.dabot.module');

bytes32 constant BOT_CERT_TOKEN_COOLDOWN_HANDLER_ID = keccak256("cooldown.dabot.module");

bytes32 constant BOT_CERT_TOKEN_TEMPLATE_ID = keccak256("certificate-token.dabot.module");
bytes32 constant BOT_GOV_TOKEN_TEMPLATE_ID = keccak256("governance-token.dabot.module");

//bytes32 constant BOT_MODULE_COOLDOWN_LOCKER = keccak256("cooldown.dabot.module");

interface IDABotComponent {   
    function moduleInfo() external view returns(string memory name, string memory version, bytes32 moduleId);
}