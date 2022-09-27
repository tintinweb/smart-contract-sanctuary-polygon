// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/IMaster.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IFNFT.sol";
import "./interfaces/IIHO.sol";
import "./interfaces/IERC20.sol";

contract DividendsDistribution is Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _idCounter;

    address public whitelistContractAddress;
    address public treasuryAddress;

    event DividendFeeCollected(address nftContract, uint256 tokenId, uint256 fee, address tokenAddress);
    event DividendEventCreated(address nftContract, uint256 tokenId, uint256 dividendsToDist, uint256 dividendsPerWei, address tokenAddress);
    event DividendEventAdditionallyFunded(address nftContract, uint256 tokenId, uint256 dividendsToDist, uint256 dividendsPerWei);
    event DividendPaid(uint256 distributionId, address recipient, uint256 dividendsPaid, uint256 balanceAtSnapshot);
    event DistEventSetActive(uint256 distributionId);
    event DistEventSetInactive(uint256 distributionId);

    struct DistributionEvent {
        address nftContract;
        uint256 tokenId;
        address fnftContract;
        address payableToken;
        uint256 totalTokensToBeDistributed;
        uint256 leftToBeDistributed;
        uint256 dividendsPerWei;
        uint256 snapshotId;
        bool active;
    }

    // Map the FNFT address to an array of Dist Ids
    mapping(address => uint256[]) private distributionIds;

    // Map the dist id to the Dist Events
    mapping(uint256 => DistributionEvent) private distributionEvents;

    // Dist Id -> User address -> Dividends amount paid
    mapping(uint256 => mapping(address => uint256)) public dividendPayments;

    modifier onlyAdmin() {
        require(IWhitelist(whitelistContractAddress).hasRoleAdmin(msg.sender), "Not an admin");
        _;
    }

    function initialize(
        address _whitelistContractAddress,
        address _treasuryAddress
    ) public initializer {
        whitelistContractAddress = _whitelistContractAddress;
        treasuryAddress = _treasuryAddress;
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function getDistributionIds(address fnft) public view returns (uint256[] memory) {
        return distributionIds[fnft];
    }

    function getDistributionEvent(uint256 id) public view returns (DistributionEvent memory) {
        return distributionEvents[id];
    }

    function createDividendEvent(uint256 tokenId, address _nftAddress, uint256 amount) external {
        IIHO ihoInstance = IIHO(_nftAddress);
        require(msg.sender == ihoInstance.talent(tokenId), "Not a talent");
        address supportedStablecoinAddress = ihoInstance.supportedStablecoinAddress();
        address fnftToken = ihoInstance.fractionalToken(tokenId);
        uint256 fee = ihoInstance.getDividendFee(tokenId);

        uint256 netDividendsToDist = _collectFee(amount, fee, supportedStablecoinAddress);
        IERC20(supportedStablecoinAddress).transferFrom(msg.sender, address(this), netDividendsToDist);

        uint256 _dividendsPerWei = _calculateDividendPerWei(IERC20(fnftToken).totalSupply(), netDividendsToDist);

        _idCounter.increment();
        uint256 currentId = _idCounter.current();

        DistributionEvent memory _distEvent;
        _distEvent.nftContract = _nftAddress;
        _distEvent.tokenId = tokenId;
        _distEvent.fnftContract = fnftToken;
        _distEvent.payableToken = supportedStablecoinAddress;
        _distEvent.totalTokensToBeDistributed = netDividendsToDist;
        _distEvent.leftToBeDistributed = netDividendsToDist;
        _distEvent.dividendsPerWei = _dividendsPerWei;

        //Add to mappings
        distributionEvents[currentId] = _distEvent;
        uint256[] storage _existingIds = distributionIds[fnftToken];
        _existingIds.push(currentId);

        emit DividendEventCreated(_nftAddress, tokenId, netDividendsToDist, _dividendsPerWei, fnftToken);
    }
    
    function fundExistingDividendEvent(address _nftAddress, uint256 tokenId, uint256 distId, uint256 amount) external {
        IIHO ihoInstance = IIHO(_nftAddress);
        require(msg.sender == ihoInstance.talent(tokenId), "Not a talent");

        address supportedStablecoinAddress = ihoInstance.supportedStablecoinAddress();
        uint256 fee = ihoInstance.getDividendFee(tokenId);

        uint256 addNetDividendsToDist = _collectFee(amount, fee, supportedStablecoinAddress);
        IERC20(supportedStablecoinAddress).transferFrom(msg.sender, address(this), addNetDividendsToDist);

        DistributionEvent storage _distEvent = distributionEvents[distId];
        distributionEvents[distId].totalTokensToBeDistributed += addNetDividendsToDist;
        distributionEvents[distId].leftToBeDistributed += addNetDividendsToDist;

        IERC20 _fnftToken = IERC20(distributionEvents[distId].fnftContract);

        uint256 _dividendsPerWei = _calculateDividendPerWei(_fnftToken.totalSupply(), distributionEvents[distId].leftToBeDistributed);
        _distEvent.dividendsPerWei = _dividendsPerWei;

        emit DividendEventAdditionallyFunded(_nftAddress, tokenId, addNetDividendsToDist, _dividendsPerWei);
    }

    function claimDividend(uint256 distId) external nonReentrant whenNotPaused {
        DistributionEvent memory _distEvent = distributionEvents[distId];
        require(_distEvent.active, "Distribution event is not active");
        require(dividendPayments[distId][msg.sender] == 0, "Dividends already distributed for this distribution id");
       
        IFNFT _fnft = IFNFT(_distEvent.fnftContract);
        uint256 balanceAtSnapshot = _fnft.balanceOfAt(msg.sender, _distEvent.snapshotId);
        if (balanceAtSnapshot == 0) {
            revert("Address not eligible for dividend payments");
        }
        uint256 dividendsToPay = balanceAtSnapshot * _distEvent.dividendsPerWei;

        // Approve and transfer tokens on the payable token smart contract
        IERC20(_distEvent.payableToken).approve(msg.sender, dividendsToPay);
        require(IERC20(_distEvent.payableToken).transfer(msg.sender, dividendsToPay), "Dividends could not be transferred");

        // Record dividend payment
        dividendPayments[distId][msg.sender] = dividendsToPay;

        emit DividendPaid(distId, msg.sender, dividendsToPay, balanceAtSnapshot);
    }

    // Internal functions
    function _calculateDividendPerWei(uint256 totalSupply, uint256 netDividendsToDist) internal pure returns (uint256) {
        return (totalSupply/netDividendsToDist);
    }

    function _collectFee(uint256 amount, uint256 fee, address supportedStablecoinAddress) internal returns (uint256) {
        if (fee > 0) {
            IERC20(supportedStablecoinAddress).transferFrom(msg.sender, treasuryAddress, fee);
        }
        return (amount - fee);
    }

    // Admin functions
    function setSnapshotId(uint256 distId, uint256 snapshotId) external onlyAdmin {
        distributionEvents[distId].snapshotId = snapshotId;
    }

    function enableDistEvent(uint256 distId) external onlyAdmin {
        distributionEvents[distId].active = true;
        emit DistEventSetActive(distId);
    }

    function disableDistEvent(uint256 distId) external onlyAdmin {
        distributionEvents[distId].active = false;
        emit DistEventSetInactive(distId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMaster {
    
    function treasuryAddress() external view returns(address);

    function feeToCollect() external view returns(uint256);

    function whitelistContractAddress() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWhitelist {
    function hasRoleUnderwriter(address _account) external view returns (bool);

    function hasRoleInvestor(address _account) external view returns (bool);

    function hasRoleAdmin(address _account) external view returns (bool);

    function hasRoleMinter(address _account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFNFT {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function redeem(uint256 _tokens) external returns(uint256);
    function totalSupply() external returns(uint256);
    function decimals() external view returns (uint8);
    function balanceOfAt(address account, uint256 snapshotId) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IIHO {


    function talent(uint256) external view returns (address);

    function fractionalToken(uint256) external view returns (address);

    function supportedStablecoinAddress() external view returns (address);

    function rewardPerFraction() external view returns (uint);

    function getDividendFee(uint256 tokenId) external view returns (uint8); 

    function _whenNotPaused() external view returns(bool);

    function calcBuybackPriceInUSD(uint256, uint256, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

library DataTypes {
    enum Status {
        Pending,
        Active,
        PendingBuyback,
        Buyback,
        Redeemed,
        Cancelled
    }
}