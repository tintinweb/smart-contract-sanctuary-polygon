// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
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
pragma solidity 0.8.10;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Whitelist} from "./libraries/Whitelist.sol";
import {IAssetRouter} from "./assets/interfaces/IAssetRouter.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";
import {IMortgageVault} from "./interfaces/IMortgageVault.sol";
import {IDSProxyRegistry} from "./interfaces/IDSProxy.sol";
import {ISetupAction} from "./interfaces/ISetupAction.sol";
import {Errors} from "./utils/Errors.sol";

/// @title The implementation contract of comptroller
/// @notice Set the parameters and the permission controls of fund.
contract ComptrollerImplementation is Ownable, IComptroller {
    using Whitelist for Whitelist.ActionWList;
    using Whitelist for Whitelist.AssetWList;
    using Whitelist for Whitelist.CreatorWList;

    // Struct
    struct DenominationConfig {
        bool isPermitted;
        uint256 dust;
    }

    struct MortgageTierConfig {
        bool isSet;
        uint256 amount;
    }

    // Variable
    bool public fHalt;
    bool public fInitialAssetCheck;
    address public execAction;
    address public execFeeCollector;
    uint256 public execFeePercentage;
    uint256 public execAssetValueToleranceRate;
    address public pendingLiquidator;
    uint256 public pendingExpiration;
    uint256 public pendingPenalty;
    uint256 public assetCapacity;
    IAssetRouter public assetRouter;
    IMortgageVault public mortgageVault;
    UpgradeableBeacon public beacon;
    IDSProxyRegistry public dsProxyRegistry;
    ISetupAction public setupAction;

    // Map
    mapping(address => DenominationConfig) public denomination;
    mapping(address => bool) public bannedFundProxy;
    mapping(uint256 => MortgageTierConfig) public mortgageTier;

    // ACL
    Whitelist.CreatorWList private _creatorACL;
    Whitelist.AssetWList private _assetACL;
    Whitelist.ActionWList private _delegateCallACL;
    Whitelist.ActionWList private _contractCallACL;
    Whitelist.ActionWList private _handlerCallACL;

    // Event
    event Halted();
    event UnHalted();
    event SetMortgageVault(address indexed mortgageVault);
    event SetExecFeeCollector(address indexed collector);
    event SetExecFeePercentage(uint256 indexed percentage);
    event SetPendingLiquidator(address indexed liquidator);
    event SetPendingExpiration(uint256 expiration);
    event SetPendingPenalty(uint256 penalty);
    event SetExecAssetValueToleranceRate(uint256 tolerance);
    event SetInitialAssetCheck(bool indexed check);
    event SetDSProxyRegistry(address indexed registry);
    event SetSetupAction(address indexed action);
    event FundProxyBanned(address indexed fundProxy);
    event FundProxyUnbanned(address indexed fundProxy);
    event PermitDenomination(address indexed denomination, uint256 dust);
    event ForbidDenomination(address indexed denomination);
    event SetMortgageTier(uint256 indexed level, uint256 amount);
    event UnsetMortgageTier(uint256 indexed level);
    event SetAssetCapacity(uint256 indexed assetCapacity);
    event SetAssetRouter(address indexed assetRouter);
    event SetExecAction(address indexed action);
    event PermitCreator(address indexed to);
    event ForbidCreator(address indexed to);
    event PermitAsset(uint256 indexed level, address indexed asset);
    event ForbidAsset(uint256 indexed level, address indexed asset);
    event PermitDelegateCall(uint256 indexed level, address indexed to, bytes4 sig);
    event ForbidDelegateCall(uint256 indexed level, address indexed to, bytes4 sig);
    event PermitContractCall(uint256 indexed level, address indexed to, bytes4 sig);
    event ForbidContractCall(uint256 indexed level, address indexed to, bytes4 sig);
    event PermitHandler(uint256 indexed level, address indexed to, bytes4 sig);
    event ForbidHandler(uint256 indexed level, address indexed to, bytes4 sig);

    // Modifier
    modifier onlyUnHalted() {
        Errors._require(!fHalt, Errors.Code.COMPTROLLER_HALTED);
        _;
    }

    modifier onlyUnbannedFundProxy() {
        Errors._require(!bannedFundProxy[msg.sender], Errors.Code.COMPTROLLER_BANNED);
        _;
    }

    modifier nonZeroAddress(address newSetter_) {
        Errors._require(newSetter_ != address(0), Errors.Code.COMPTROLLER_ZERO_ADDRESS);
        _;
    }

    modifier consistentTosAndSigsLength(address[] calldata tos_, bytes4[] calldata sigs_) {
        Errors._require(tos_.length == sigs_.length, Errors.Code.COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT);
        _;
    }

    constructor() {
        // set owner to address(0) in implementation contract
        renounceOwnership();
    }

    /// @notice Initializer.
    /// @param implementation_ The fund implementation address.
    /// @param assetRouter_ The asset router address.
    /// @param execFeeCollector_ The execution fee collector address.
    /// @param execFeePercentage_ The ececute fee percentage on a 1e4 basis.
    /// @param pendingLiquidator_ The pending liquidator address.
    /// @param pendingExpiration_ The pending expiration to be set in second.
    /// @param mortgageVault_ The mortgage vault address.
    /// @param execAssetValueToleranceRate_ The exec asset value tolerance rate.
    /// @param dsProxyRegistry_ The DSProxy registry address.
    /// @param setupAction_ The setup action address.
    function initialize(
        address implementation_,
        IAssetRouter assetRouter_,
        address execFeeCollector_,
        uint256 execFeePercentage_,
        address pendingLiquidator_,
        uint256 pendingExpiration_,
        IMortgageVault mortgageVault_,
        uint256 execAssetValueToleranceRate_,
        IDSProxyRegistry dsProxyRegistry_,
        ISetupAction setupAction_
    ) external {
        Errors._require(address(beacon) == address(0), Errors.Code.COMPTROLLER_BEACON_IS_INITIALIZED);
        // transfer owner for set functions
        _transferOwnership(msg.sender);
        setAssetRouter(assetRouter_);
        setMortgageVault(mortgageVault_);
        setFeeCollector(execFeeCollector_);
        setExecFeePercentage(execFeePercentage_);
        setPendingLiquidator(pendingLiquidator_);
        setPendingExpiration(pendingExpiration_);
        setPendingPenalty(100);
        setAssetCapacity(80);
        setExecAssetValueToleranceRate(execAssetValueToleranceRate_);
        setInitialAssetCheck(true);
        setDSProxyRegistry(dsProxyRegistry_);
        setSetupAction(setupAction_);

        beacon = new UpgradeableBeacon(implementation_);
        beacon.transferOwnership(msg.sender);
    }

    /// @notice Get the implementation address.
    /// @return The implementation address.
    function implementation() external view onlyUnHalted onlyUnbannedFundProxy returns (address) {
        return beacon.implementation();
    }

    /// @inheritdoc IComptroller
    function owner() public view override(Ownable, IComptroller) returns (address) {
        return Ownable.owner();
    }

    /// @notice Halt the fund.
    function halt() external onlyOwner {
        fHalt = true;
        emit Halted();
    }

    /// @notice Unhalt the fund.
    function unHalt() external onlyOwner {
        fHalt = false;
        emit UnHalted();
    }

    /// @notice Set asset router.
    /// @param assetRouter_ The asset router address.
    function setAssetRouter(IAssetRouter assetRouter_) public nonZeroAddress(address(assetRouter_)) onlyOwner {
        assetRouter = assetRouter_;
        emit SetAssetRouter(address(assetRouter_));
    }

    /// @notice Set mortgage vault.
    /// @param mortgageVault_ The mortage vault address.
    function setMortgageVault(IMortgageVault mortgageVault_) public nonZeroAddress(address(mortgageVault_)) onlyOwner {
        mortgageVault = mortgageVault_;
        emit SetMortgageVault(address(mortgageVault_));
    }

    /// @notice Set execution fee collector.
    /// @param collector_ The collector address.
    function setFeeCollector(address collector_) public nonZeroAddress(collector_) onlyOwner {
        execFeeCollector = collector_;
        emit SetExecFeeCollector(collector_);
    }

    /// @notice Set execution fee percentage.
    /// @param percentage_ The fee percentage on a 1e4 basis.
    function setExecFeePercentage(uint256 percentage_) public onlyOwner {
        execFeePercentage = percentage_;
        emit SetExecFeePercentage(percentage_);
    }

    /// @notice Set pending liquidator.
    /// @param liquidator_ The liquidator address.
    function setPendingLiquidator(address liquidator_) public nonZeroAddress(liquidator_) onlyOwner {
        pendingLiquidator = liquidator_;
        emit SetPendingLiquidator(liquidator_);
    }

    /// @notice Set pending expiration.
    /// @param expiration_ The pending expiration to be set in second.
    function setPendingExpiration(uint256 expiration_) public onlyOwner {
        pendingExpiration = expiration_;
        emit SetPendingExpiration(expiration_);
    }

    /// @notice Set pending state redeem penalty.
    /// @param penalty_ The penalty percentage on a 1e4 basis.
    function setPendingPenalty(uint256 penalty_) public onlyOwner {
        pendingPenalty = penalty_;
        emit SetPendingPenalty(penalty_);
    }

    /// @notice Set maximum capacity of assets.
    /// @param assetCapacity_ The number of assets.
    function setAssetCapacity(uint256 assetCapacity_) public onlyOwner {
        assetCapacity = assetCapacity_;
        emit SetAssetCapacity(assetCapacity_);
    }

    /// @notice Set execution asset value tolerance rate.
    /// @param tolerance_ The tolerance rate on a 1e4 basis.
    function setExecAssetValueToleranceRate(uint256 tolerance_) public onlyOwner {
        execAssetValueToleranceRate = tolerance_;
        emit SetExecAssetValueToleranceRate(tolerance_);
    }

    /// @notice Set to check initial asset or not.
    /// @param check_ The boolean of checking initial asset.
    function setInitialAssetCheck(bool check_) public onlyOwner {
        fInitialAssetCheck = check_;
        emit SetInitialAssetCheck(check_);
    }

    /// @notice Set the DSProxy registry.
    /// @param dsProxyRegistry_ The DSProxy Registry address.
    function setDSProxyRegistry(IDSProxyRegistry dsProxyRegistry_)
        public
        nonZeroAddress(address(dsProxyRegistry_))
        onlyOwner
    {
        dsProxyRegistry = dsProxyRegistry_;
        emit SetDSProxyRegistry(address(dsProxyRegistry_));
    }

    /// @notice Set the setup action.
    /// @param setupAction_ The setup action address.
    function setSetupAction(ISetupAction setupAction_) public nonZeroAddress(address(setupAction_)) onlyOwner {
        setupAction = setupAction_;
        emit SetSetupAction(address(setupAction_));
    }

    /// @notice Permit denomination whitelist.
    /// @param denominations_ The denomination address array.
    /// @param dusts_ The denomination dust array.
    function permitDenominations(address[] calldata denominations_, uint256[] calldata dusts_) external onlyOwner {
        Errors._require(
            denominations_.length == dusts_.length,
            Errors.Code.COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT
        );

        for (uint256 i = 0; i < denominations_.length; i++) {
            denomination[denominations_[i]].isPermitted = true;
            denomination[denominations_[i]].dust = dusts_[i];
            emit PermitDenomination(denominations_[i], dusts_[i]);
        }
    }

    /// @notice Remove denominations from whitelist.
    /// @param denominations_ The denominations to be removed.
    function forbidDenominations(address[] calldata denominations_) external onlyOwner {
        for (uint256 i = 0; i < denominations_.length; i++) {
            delete denomination[denominations_[i]];
            emit ForbidDenomination(denominations_[i]);
        }
    }

    /// @notice Check if the denomination is valid.
    /// @param denomination_ The denomination address.
    /// @return True if valid otherwise false.
    function isValidDenomination(address denomination_) external view returns (bool) {
        return denomination[denomination_].isPermitted;
    }

    /// @notice Get the denomination dust.
    /// @param denomination_ The denomination address.
    /// @return The dust of denomination.
    function getDenominationDust(address denomination_) external view returns (uint256) {
        return denomination[denomination_].dust;
    }

    /// @notice Ban the fund proxy.
    /// @param fundProxy_ The fund proxy address.
    function banFundProxy(address fundProxy_) external onlyOwner {
        bannedFundProxy[fundProxy_] = true;
        emit FundProxyBanned(fundProxy_);
    }

    /// @notice Unban the fund proxy.
    /// @param fundProxy_ The fund proxy address.
    function unbanFundProxy(address fundProxy_) external onlyOwner {
        bannedFundProxy[fundProxy_] = false;
        emit FundProxyUnbanned(fundProxy_);
    }

    /// @notice Set mortgage tier.
    /// @param level_ The level of mortgage.
    /// @param amount_ The mortgage amount.
    function setMortgageTier(uint256 level_, uint256 amount_) external onlyOwner {
        mortgageTier[level_].isSet = true;
        mortgageTier[level_].amount = amount_;
        emit SetMortgageTier(level_, amount_);
    }

    /// @notice Unset mortgage tier.
    /// @param level_ The level of mortage.
    function unsetMortgageTier(uint256 level_) external onlyOwner {
        delete mortgageTier[level_];
        emit UnsetMortgageTier(level_);
    }

    /// @notice Set execution action.
    /// @param action_ The action address.
    function setExecAction(address action_) external nonZeroAddress(action_) onlyOwner {
        execAction = action_;
        emit SetExecAction(action_);
    }

    /// @notice Permit creator whitelist.
    /// @param creators_ The permit creator address array.
    function permitCreators(address[] calldata creators_) external onlyOwner {
        for (uint256 i = 0; i < creators_.length; i++) {
            _creatorACL._permit(creators_[i]);
            emit PermitCreator(creators_[i]);
        }
    }

    /// @notice Remove creators from the whitelist.
    /// @param creators_ The creators to be removed.
    function forbidCreators(address[] calldata creators_) external onlyOwner {
        for (uint256 i = 0; i < creators_.length; i++) {
            _creatorACL._forbid(creators_[i]);
            emit ForbidCreator(creators_[i]);
        }
    }

    /// @notice Check if the creator is valid.
    /// @param creator_ The creator address.
    /// @return True if valid otherwise false.
    function isValidCreator(address creator_) external view returns (bool) {
        return _creatorACL._canCall(creator_);
    }

    /// @notice Permit asset whitelist.
    /// @param level_ The permit level.
    /// @param assets_ The permit asset array of level.
    function permitAssets(uint256 level_, address[] calldata assets_) external onlyOwner {
        for (uint256 i = 0; i < assets_.length; i++) {
            _assetACL._permit(level_, assets_[i]);
            emit PermitAsset(level_, assets_[i]);
        }
    }

    /// @notice Remove the assets from whitelist.
    /// @param level_ The level to be configured.
    /// @param assets_ The assets to be removed from the given level.
    function forbidAssets(uint256 level_, address[] calldata assets_) external onlyOwner {
        for (uint256 i = 0; i < assets_.length; i++) {
            _assetACL._forbid(level_, assets_[i]);
            emit ForbidAsset(level_, assets_[i]);
        }
    }

    /// @notice Check if the dealing assets are valid.
    /// @param level_ The level to be checked.
    /// @param assets_ The assets to be checked in the given level.
    /// @return True if valid otherwise false.
    function isValidDealingAssets(uint256 level_, address[] calldata assets_) external view returns (bool) {
        for (uint256 i = 0; i < assets_.length; i++) {
            if (!isValidDealingAsset(level_, assets_[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if the dealing asset is valid.
    /// @param level_ The level to be checked.
    /// @param asset_ The asset to be checked in the given level.
    /// @return True if valid otherwise false.
    function isValidDealingAsset(uint256 level_, address asset_) public view returns (bool) {
        return _assetACL._canCall(level_, asset_);
    }

    /// @notice Check if the initial assets are valid.
    /// @param level_ The level to be checked.
    /// @param assets_ The assets to be checked in the given level.
    /// @return True if valid otherwise false.
    function isValidInitialAssets(uint256 level_, address[] calldata assets_) external view returns (bool) {
        for (uint256 i = 0; i < assets_.length; i++) {
            if (!isValidInitialAsset(level_, assets_[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if the initial asset is valid.
    /// @param level_ The level to be checked.
    /// @param asset_ The asset to be checked in the given level.
    /// @return True if valid otherwise false.
    function isValidInitialAsset(uint256 level_, address asset_) public view returns (bool) {
        // check if input check flag is true
        if (fInitialAssetCheck) {
            return _assetACL._canCall(level_, asset_);
        }
        return true;
    }

    /// @notice Permit delegate call function.
    /// @param level_ The permit level.
    /// @param tos_ The permit delegate call address array.
    /// @param sigs_ The permit function signature array.
    function permitDelegateCalls(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _delegateCallACL._permit(level_, tos_[i], sigs_[i]);
            emit PermitDelegateCall(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Remove functions from the delegate call whitelist.
    /// @param level_ The level to be configured.
    /// @param tos_ The delegate call addresses to be removed.
    /// @param sigs_ The function signatures to be removed.
    function forbidDelegateCalls(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _delegateCallACL._forbid(level_, tos_[i], sigs_[i]);
            emit ForbidDelegateCall(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Check if the function can be delegate called.
    /// @param level_ The level to be checked.
    /// @param to_ The delegate call address to be checked.
    /// @param sig_ The function signature to be checked.
    /// @return True if can call otherwise false.
    function canDelegateCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool) {
        return _delegateCallACL._canCall(level_, to_, sig_);
    }

    /// @notice Permit contract call functions.
    /// @param level_ The level to be configured.
    /// @param tos_ The contract call addresses to be permitted.
    /// @param sigs_ The function signatures to be permitted.
    function permitContractCalls(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _contractCallACL._permit(level_, tos_[i], sigs_[i]);
            emit PermitContractCall(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Remove the function from contract call whitelist.
    /// @param level_ The level to be configured.
    /// @param tos_ The contract call addresses to be removed.
    /// @param sigs_ The function signatures to be removed.
    function forbidContractCalls(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _contractCallACL._forbid(level_, tos_[i], sigs_[i]);
            emit ForbidContractCall(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Check if the function can be called.
    /// @param level_ The level to be configured.
    /// @param to_ The contract call address to be removed.
    /// @param sig_ The function signature to be removed.
    /// @return True if can call otherwise false.
    function canContractCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool) {
        return _contractCallACL._canCall(level_, to_, sig_);
    }

    /// @notice Permit the handler functions.
    /// @param level_ The level to be configured.
    /// @param tos_ The handler addresses to be permitted.
    /// @param sigs_ The function signatures to be permitted.
    function permitHandlers(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _handlerCallACL._permit(level_, tos_[i], sigs_[i]);
            emit PermitHandler(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Remove handler functions from whitelist.
    /// @param level_ The level to be configured.
    /// @param tos_ The handler addresses to be removed.
    /// @param sigs_ The function signatures to be removed.
    function forbidHandlers(
        uint256 level_,
        address[] calldata tos_,
        bytes4[] calldata sigs_
    ) external consistentTosAndSigsLength(tos_, sigs_) onlyOwner {
        for (uint256 i = 0; i < tos_.length; i++) {
            _handlerCallACL._forbid(level_, tos_[i], sigs_[i]);
            emit ForbidHandler(level_, tos_[i], sigs_[i]);
        }
    }

    /// @notice Check if the handler function can be called.
    /// @param level_ The level to be checked.
    /// @param to_ The handler address to be checked in the given level.
    /// @param sig_ The function signature to be checked in the given level.
    /// @return True if can call otherwise false.
    function canHandlerCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool) {
        return _handlerCallACL._canCall(level_, to_, sig_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetOracle {
    function calcConversionAmount(
        address base_,
        uint256 baseAmount_,
        address quote_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetRegistry {
    function bannedResolvers(address) external view returns (bool);

    function register(address asset_, address resolver_) external;

    function unregister(address asset_) external;

    function banResolver(address resolver_) external;

    function unbanResolver(address resolver_) external;

    function resolvers(address asset_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRegistry} from "./IAssetRegistry.sol";
import {IAssetOracle} from "./IAssetOracle.sol";

interface IAssetRouter {
    function oracle() external view returns (IAssetOracle);

    function registry() external view returns (IAssetRegistry);

    function setOracle(address oracle_) external;

    function setRegistry(address registry_) external;

    function calcAssetsTotalValue(
        address[] calldata bases_,
        uint256[] calldata amounts_,
        address quote_
    ) external view returns (uint256);

    function calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRouter} from "../assets/interfaces/IAssetRouter.sol";
import {IMortgageVault} from "./IMortgageVault.sol";
import {IDSProxyRegistry} from "./IDSProxy.sol";
import {ISetupAction} from "./ISetupAction.sol";

interface IComptroller {
    function owner() external view returns (address);

    function canDelegateCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canContractCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canHandlerCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function execFeePercentage() external view returns (uint256);

    function execFeeCollector() external view returns (address);

    function pendingLiquidator() external view returns (address);

    function pendingExpiration() external view returns (uint256);

    function execAssetValueToleranceRate() external view returns (uint256);

    function isValidDealingAsset(uint256 level_, address asset_) external view returns (bool);

    function isValidDealingAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function isValidInitialAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function assetCapacity() external view returns (uint256);

    function assetRouter() external view returns (IAssetRouter);

    function mortgageVault() external view returns (IMortgageVault);

    function pendingPenalty() external view returns (uint256);

    function execAction() external view returns (address);

    function mortgageTier(uint256 tier_) external view returns (bool, uint256);

    function isValidDenomination(address denomination_) external view returns (bool);

    function getDenominationDust(address denomination_) external view returns (uint256);

    function isValidCreator(address creator_) external view returns (bool);

    function dsProxyRegistry() external view returns (IDSProxyRegistry);

    function setupAction() external view returns (ISetupAction);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDSProxy {
    function execute(address _target, bytes calldata _data) external payable returns (bytes memory response);

    function owner() external view returns (address);

    function setAuthority(address authority_) external;
}

interface IDSProxyFactory {
    function isProxy(address proxy) external view returns (bool);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

interface IDSProxyRegistry {
    function proxies(address input) external view returns (address);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMortgageVault {
    function mortgageToken() external view returns (IERC20);

    function totalAmount() external view returns (uint256);

    function fundAmounts(address fund_) external view returns (uint256);

    function mortgage(uint256 amount_) external;

    function claim(address receiver_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISetupAction {
    function maxApprove(IERC20 token_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Whitelist {
    uint256 internal constant _ANY32 = type(uint256).max;
    address internal constant _ANY20 = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    bytes4 internal constant _ANY4 = bytes4(type(uint32).max);

    // Action Whitelist
    struct ActionWList {
        mapping(uint256 => mapping(address => mapping(bytes4 => bool))) acl;
    }

    function _canCall(
        ActionWList storage wl_,
        uint256 level_,
        address to_,
        bytes4 sig_
    ) internal view returns (bool) {
        return wl_.acl[level_][to_][sig_] || wl_.acl[level_][to_][_ANY4] || wl_.acl[_ANY32][to_][sig_];
    }

    function _permit(
        ActionWList storage wl_,
        uint256 level_,
        address to_,
        bytes4 sig_
    ) internal {
        wl_.acl[level_][to_][sig_] = true;
    }

    function _forbid(
        ActionWList storage wl_,
        uint256 level_,
        address to_,
        bytes4 sig_
    ) internal {
        wl_.acl[level_][to_][sig_] = false;
    }

    // Asset white list
    struct AssetWList {
        mapping(uint256 => mapping(address => bool)) acl;
    }

    function _permit(
        AssetWList storage wl_,
        uint256 level_,
        address asset_
    ) internal {
        wl_.acl[level_][asset_] = true;
    }

    function _forbid(
        AssetWList storage wl_,
        uint256 level_,
        address asset_
    ) internal {
        wl_.acl[level_][asset_] = false;
    }

    function _canCall(
        AssetWList storage wl_,
        uint256 level_,
        address asset_
    ) internal view returns (bool) {
        return wl_.acl[level_][asset_] || wl_.acl[_ANY32][asset_];
    }

    // Creator white list
    struct CreatorWList {
        mapping(address => bool) acl;
    }

    function _permit(CreatorWList storage wl_, address creator_) internal {
        wl_.acl[creator_] = true;
    }

    function _forbid(CreatorWList storage wl_, address creator_) internal {
        wl_.acl[creator_] = false;
    }

    function _canCall(CreatorWList storage wl_, address creator_) internal view returns (bool) {
        return wl_.acl[creator_] || wl_.acl[_ANY20];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error RevertCode(Code errorCode);

    enum Code {
        COMPTROLLER_HALTED, // 0: "Halted"
        COMPTROLLER_BANNED, // 1: "Banned"
        COMPTROLLER_ZERO_ADDRESS, // 2: "Zero address"
        COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT, // 3: "tos and sigs length are inconsistent"
        COMPTROLLER_BEACON_IS_INITIALIZED, // 4: "Beacon is initialized"
        COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT, // 5: "denominations and dusts length are inconsistent"
        IMPLEMENTATION_ASSET_LIST_NOT_EMPTY, // 6: "assetList is not empty"
        IMPLEMENTATION_INVALID_DENOMINATION, // 7: "Invalid denomination"
        IMPLEMENTATION_INVALID_MORTGAGE_TIER, // 8: "Mortgage tier not set in comptroller"
        IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE, // 9: "pending share is not resolvable"
        IMPLEMENTATION_PENDING_NOT_START, // 10: "Pending does not start"
        IMPLEMENTATION_PENDING_NOT_EXPIRE, // 11: "Pending does not expire"
        IMPLEMENTATION_INVALID_ASSET, // 12: "Invalid asset"
        IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION, // 13: "Insufficient total value for execution"
        FUND_PROXY_FACTORY_INVALID_CREATOR, // 14: "Invalid creator"
        FUND_PROXY_FACTORY_INVALID_DENOMINATION, // 15: "Invalid denomination"
        FUND_PROXY_FACTORY_INVALID_MORTGAGE_TIER, // 16: "Mortgage tier not set in comptroller"
        FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION, // 17: "Invalid denomination"
        FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER, // 18: "Unknown owner"
        FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE, // 19: "Wrong allowance"
        FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO, // 20: "Is not zero value or address "
        FUND_PROXY_STORAGE_UTILS_IS_ZERO, // 21: "Is zero value or address"
        MORTGAGE_VAULT_FUND_MORTGAGED, // 22: "Fund mortgaged"
        SHARE_TOKEN_INVALID_FROM, // 23: "Invalid from"
        SHARE_TOKEN_INVALID_TO, // 24: "Invalid to"
        TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT, // 25: "tos and datas length inconsistent"
        TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT, // 26: "tos and configs length inconsistent"
        TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL, // 27: "Invalid comptroller delegate call"
        TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL, // 28: "Invalid comptroller contract call"
        TASK_EXECUTOR_INVALID_DEALING_ASSET, // 29: "Invalid dealing asset"
        TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK, // 30: "Reference to out of localStack"
        TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED, // 31: "Return num and parsed return num not matched"
        TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE, // 32: "Illegal length for _parse"
        TASK_EXECUTOR_STACK_OVERFLOW, // 33: "Stack overflow"
        TASK_EXECUTOR_INVALID_INITIAL_ASSET, // 34: "Invalid initial asset"
        TASK_EXECUTOR_NON_ZERO_QUOTA, // 35: "Quota is not zero"
        AFURUCOMBO_DUPLICATED_TOKENSOUT, // 36: "Duplicated tokensOut"
        AFURUCOMBO_REMAINING_TOKENS, // 37: "Furucombo has remaining tokens"
        AFURUCOMBO_TOKENS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 38: "Token length != amounts length"
        AFURUCOMBO_INVALID_COMPTROLLER_HANDLER_CALL, // 39: "Invalid comptroller handler call"
        CHAINLINK_ASSETS_AND_AGGREGATORS_INCONSISTENT, // 40: "assets.length == aggregators.length"
        CHAINLINK_ZERO_ADDRESS, // 41: "Zero address"
        CHAINLINK_EXISTING_ASSET, // 42: "Existing asset"
        CHAINLINK_NON_EXISTENT_ASSET, // 43: "Non-existent asset"
        CHAINLINK_INVALID_PRICE, // 44: "Invalid price"
        CHAINLINK_STALE_PRICE, // 45: "Stale price"
        ASSET_REGISTRY_UNREGISTERED, // 46: "Unregistered"
        ASSET_REGISTRY_BANNED_RESOLVER, // 47: "Resolver has been banned"
        ASSET_REGISTRY_ZERO_RESOLVER_ADDRESS, // 48: "Resolver zero address"
        ASSET_REGISTRY_ZERO_ASSET_ADDRESS, // 49: "Asset zero address"
        ASSET_REGISTRY_REGISTERED_RESOLVER, // 50: "Resolver is registered"
        ASSET_REGISTRY_NON_REGISTERED_RESOLVER, // 51: "Asset not registered"
        ASSET_REGISTRY_NON_BANNED_RESOLVER, // 52: "Resolver is not banned"
        ASSET_ROUTER_ASSETS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 53: "assets length != amounts length"
        ASSET_ROUTER_NEGATIVE_VALUE, // 54: "Negative value"
        RESOLVER_ASSET_VALUE_NEGATIVE, // 55: "Resolver's asset value < 0"
        RESOLVER_ASSET_VALUE_POSITIVE, // 56: "Resolver's asset value > 0"
        RCURVE_STABLE_ZERO_ASSET_ADDRESS, // 57: "Zero asset address"
        RCURVE_STABLE_ZERO_POOL_ADDRESS, // 58: "Zero pool address"
        RCURVE_STABLE_ZERO_VALUED_ASSET_ADDRESS, // 59: "Zero valued asset address"
        RCURVE_STABLE_VALUED_ASSET_DECIMAL_NOT_MATCH_VALUED_ASSET, // 60: "Valued asset decimal not match valued asset"
        RCURVE_STABLE_POOL_INFO_IS_NOT_SET, // 61: "Pool info is not set"
        ASSET_MODULE_DIFFERENT_ASSET_REMAINING, // 62: "Different asset remaining"
        ASSET_MODULE_FULL_ASSET_CAPACITY, // 63: "Full Asset Capacity"
        MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE, // 64: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET, // 65: "Can not crystallized yet"
        PERFORMANCE_FEE_MODULE_TIME_BEFORE_START, // 66: "Time before start"
        PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE, // 67: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT, // 68: "Crystallization period too short"
        SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE, // 69: "The requesting share amount is greater than total share amount"
        SHARE_MODULE_PURCHASE_ZERO_BALANCE, // 70: "The purchased balance is zero"
        SHARE_MODULE_PURCHASE_ZERO_SHARE, // 71: "The share purchased need to greater than zero"
        SHARE_MODULE_REDEEM_ZERO_SHARE, // 72: "The redeem share is zero"
        SHARE_MODULE_INSUFFICIENT_SHARE, // 73: "Insufficient share amount"
        SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION, // 74: "Redeem in pending without permission"
        SHARE_MODULE_PENDING_ROUND_INCONSISTENT, // 75: "user pending round and current pending round are inconsistent"
        SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE // 76: "Pending redemption is not claimable"
    }

    function _require(bool condition_, Code errorCode_) internal pure {
        if (!condition_) revert RevertCode(errorCode_);
    }

    function _revertMsg(string memory functionName_, string memory reason_) internal pure {
        revert(string(abi.encodePacked(functionName_, ": ", reason_)));
    }

    function _revertMsg(string memory functionName_) internal pure {
        _revertMsg(functionName_, "Unspecified");
    }
}