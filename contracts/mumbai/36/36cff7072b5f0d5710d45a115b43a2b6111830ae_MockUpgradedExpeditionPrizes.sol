// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../ExpeditionPrizes.sol";

contract MockUpgradedExpeditionPrizes is ExpeditionPrizes {
    function test(Asset[] memory assets) public {
        for (uint256 i = 0; i < assets.length; i++) {
            userClaimablePrizes[msg.sender].push(assets[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ExpeditionMeta.sol";
import "./StakeAssetMeta.sol";
import "./NebulaExpedition.sol";
import "./ExpeditionStakingAndKeys.sol";

contract ExpeditionPrizes is
    Initializable,
    AccessProtectedUpgradable,
    UUPSUpgradeable,
    ExpeditionMeta,
    StakeAssetMeta
{
    using AddressUpgradeable for address;

    mapping(address => Asset[]) public userClaimablePrizes;

    event ClaimablePrizes(
        uint256 indexed expeditionId,
        address indexed user,
        uint256 burnKeyAmount,
        Asset[] prizes
    );

    event ClaimedPrize(
        address indexed user,
        address indexed prizeAddress,
        uint256 tokenId,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setUserExpeditionPrizes(
        address _user,
        address _expeditionAddress,
        uint256 _expeditionId,
        uint256 _burnKeyAmount,
        Asset[] memory _prizes
    ) external onlyAdmin {
        require(
            _expeditionAddress.isContract(),
            "Expedition address is not a contract"
        );

        NebulaExpedition expedition = NebulaExpedition(_expeditionAddress);
        ExpeditionStakingAndKeys stakingAndKeys = ExpeditionStakingAndKeys(
            expedition.stakingAndKeys()
        );

        //verify expedition is valid (state should be FINISHED)
        require(
            expedition.getExpeditionState(_expeditionId) == STATE_FINISHED,
            "expedition should be finished"
        );

        //burn user keys
        stakingAndKeys.burnUserKeys(_user, _burnKeyAmount);

        for (uint256 i = 0; i < _prizes.length; i++) {
            userClaimablePrizes[_user].push(_prizes[i]);
        }

        emit ClaimablePrizes(_expeditionId, _user, _burnKeyAmount, _prizes);
    }

    function claimExpeditionPrize(address _user, uint256 _index) external {
        require(
            userClaimablePrizes[_user][_index].assetType != ASSET_TYPE_NONE,
            "User has no expedition prizes"
        );

        Asset memory prize = userClaimablePrizes[_user][_index];

        if (prize.assetType == ASSET_TYPE_ERC20) {
            IERC20 token = IERC20(prize.addr);

            token.transfer(msg.sender, prize.amount);
        } else if (prize.assetType == ASSET_TYPE_ERC721) {
            IERC721 token = IERC721(prize.addr);

            token.safeTransferFrom(address(this), msg.sender, prize.tokenId);
        } else if (prize.assetType == ASSET_TYPE_ERC1155) {
            IERC1155 token = IERC1155(prize.addr);

            token.safeTransferFrom(
                address(this),
                msg.sender,
                prize.tokenId,
                prize.amount,
                ""
            );
        }

        delete userClaimablePrizes[_user][_index];

        emit ClaimedPrize(_user, prize.addr, prize.tokenId, prize.amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract ExpeditionMeta {
    struct StakeInfo {
        string name;
        address addr;
        uint256 tokenId;
        uint256 minAmount;
        uint256 maxAmount;
    }

    uint256 internal constant STATE_NOT_STARTED = 0;
    uint256 internal constant STATE_STARTED = 1;
    uint256 internal constant STATE_FINISHED = 2;
    uint256 internal constant STATE_CLAIMABLE = 3;

    struct ExpeditionInfo {
        uint256 startFrom;
        uint256 endTo;
        StakeInfo requiredPlanet;
        StakeInfo optionalAsset;
        uint256 requiredKeyAmount;
        bool isClaimableNow;
    }

    struct JoinExpedition {
        uint256 joinedAt;
        uint256[] planetIds;
        uint256[] optionalAssetIds;
        uint256 keyAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract StakeAssetMeta {
    uint256 internal constant ASSET_TYPE_NONE = 0;
    uint256 internal constant ASSET_TYPE_ERC20 = 1;
    uint256 internal constant ASSET_TYPE_ERC721 = 2;
    uint256 internal constant ASSET_TYPE_ERC1155 = 3;

    struct Asset {
        uint256 assetType;
        address addr;
        uint256 tokenId;
        uint256 amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "./ExpeditionMeta.sol";
import "./ExpeditionStakingAndKeys.sol";
import "./StakeAssetMeta.sol";

import "./interfaces/IApeironPlanet.sol";

contract NebulaExpedition is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable,
    ExpeditionMeta,
    StakeAssetMeta
{
    using AddressUpgradeable for address;

    ExpeditionStakingAndKeys public stakingAndKeys;

    mapping(uint256 => ExpeditionInfo) public expeditionInfoList;
    mapping(address => mapping(uint256 => JoinExpedition))
        public userExpeditions;
    mapping(address => uint256[]) public userExpeditionIds;

    event UpdatedExpedition(
        uint256 expeditionId,
        uint256 startFrom,
        uint256 endTo,
        StakeInfo requiredPlanets,
        StakeInfo optionalAsset,
        uint256 requiredKeyAmount
    );

    event JoinedExpedition(
        address indexed user,
        uint256 expeditionId,
        uint256 joinedAt,
        uint256[] planetIds,
        uint256[] optionalAssetIds,
        uint256 keyAmount
    );

    modifier isExpeditionPeriod(uint256 _id) {
        require(
            getExpeditionState(_id) == STATE_STARTED,
            "Expedition is not in period"
        );
        _;
    }

    modifier notJoinedExpedition(uint256 _id) {
        require(
            userExpeditions[msg.sender][_id].joinedAt == 0,
            "User is joined to expedition"
        );
        _;
    }

    modifier isStakedAssets(
        uint256 _expeditionId,
        uint256[] memory _planetIds,
        uint256[] memory _assetIds,
        uint256 _keyAmount
    ) {
        require(
            _checkStakedAssets(
                msg.sender,
                expeditionInfoList[_expeditionId].requiredPlanet,
                _planetIds
            ) &&
                _checkStakedAssets(
                    msg.sender,
                    expeditionInfoList[_expeditionId].optionalAsset,
                    _assetIds
                ) &&
                _keyAmount <= stakingAndKeys.userKeys(msg.sender),
            "Not enough staked assets"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setStakingAndKeys(address _address) external onlyOwner {
        require(_address.isContract(), "address must be contract");

        stakingAndKeys = ExpeditionStakingAndKeys(_address);
    }

    function setupExpeditionInfo(uint256 _id, ExpeditionInfo memory _info)
        external
        onlyAdmin
    {
        expeditionInfoList[_id] = _info;

        emit UpdatedExpedition(
            _id,
            _info.startFrom,
            _info.endTo,
            _info.requiredPlanet,
            _info.optionalAsset,
            _info.requiredKeyAmount
        );
    }

    function setExpeditionClaimable(uint256 _id) external onlyAdmin {
        require(
            getExpeditionState(_id) == STATE_FINISHED,
            "Expedition is not finished"
        );

        expeditionInfoList[_id].isClaimableNow = true;
    }

    function joinExpedition(
        uint256 _id,
        uint256[] memory _planetIds,
        uint256[] memory _assetIds,
        uint256 _keyAmount
    )
        external
        isExpeditionPeriod(_id)
        isStakedAssets(_id, _planetIds, _assetIds, _keyAmount)
    {
        userExpeditions[msg.sender][_id] = JoinExpedition(
            block.timestamp,
            _planetIds,
            _assetIds,
            _keyAmount
        );
        userExpeditionIds[msg.sender].push(_id);

        emit JoinedExpedition(
            msg.sender,
            _id,
            block.timestamp,
            _planetIds,
            _assetIds,
            _keyAmount
        );
    }

    function getExpeditionState(uint256 _id) public view returns (uint256) {
        if (expeditionInfoList[_id].startFrom > block.timestamp) {
            return STATE_NOT_STARTED;
        } else if (
            expeditionInfoList[_id].startFrom <= block.timestamp &&
            block.timestamp <= expeditionInfoList[_id].endTo
        ) {
            return STATE_STARTED;
        } else if (expeditionInfoList[_id].isClaimableNow) {
            return STATE_CLAIMABLE;
        }

        return STATE_FINISHED;
    }

    //staking functions

    function stakeNFTForExpedition(
        uint256 _id,
        address _assetAddress,
        uint256[] memory _tokenIds
    ) external isExpeditionPeriod(_id) notJoinedExpedition(_id) {
        //verify tokenIds must be different
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            for (uint256 j = i + 1; j < _tokenIds.length; j++) {
                require(
                    _tokenIds[i] != _tokenIds[j],
                    "tokenIds must be different"
                );
            }
        }

        uint256 maxAmount = 0;
        if (_assetAddress == expeditionInfoList[_id].requiredPlanet.addr) {
            //verify planets are already born
            IApeironPlanet planet = IApeironPlanet(_assetAddress);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                (IApeironPlanet.PlanetData memory planetData, ) = planet
                    .getPlanetData(_tokenIds[i]);
                require(planetData.bornTime > 0, "planet is not born");
            }

            maxAmount = expeditionInfoList[_id].requiredPlanet.maxAmount;
        } else if (
            _assetAddress == expeditionInfoList[_id].optionalAsset.addr
        ) {
            maxAmount = expeditionInfoList[_id].optionalAsset.maxAmount;
        }

        Asset[] memory assets = stakingAndKeys.getStakedAssets(
            msg.sender,
            _assetAddress
        );

        require(
            _tokenIds.length + assets.length <= maxAmount,
            "Too many assets"
        );

        uint256[] memory _amounts = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _amounts[i] = 1;
        }
        stakingAndKeys.stakeAssets(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _amounts
        );
    }

    function unstakeNFTForExpedition(
        uint256 _id,
        address _assetAddress,
        uint256[] memory _tokenIds
    ) external isExpeditionPeriod(_id) notJoinedExpedition(_id) {
        bool enough = false;
        if (_assetAddress == expeditionInfoList[_id].requiredPlanet.addr) {
            enough = _checkStakedAssets(
                msg.sender,
                expeditionInfoList[_id].requiredPlanet,
                _tokenIds
            );
        } else if (
            _assetAddress == expeditionInfoList[_id].optionalAsset.addr
        ) {
            enough = _checkStakedAssets(
                msg.sender,
                expeditionInfoList[_id].optionalAsset,
                _tokenIds
            );
        }

        require(enough, "Not enough staked assets");

        uint256[] memory _amounts = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _amounts[i] = 1;
        }
        stakingAndKeys.unstakeAssets(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _amounts
        );
    }

    function stakeFT(address _assetAddress, uint256 _amount) external {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        stakingAndKeys.stakeAssets(
            msg.sender,
            _assetAddress,
            tokenIds,
            amounts
        );
    }

    function unstakeFT(address _assetAddress, uint256 _amount) external {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        stakingAndKeys.unstakeAssets(
            msg.sender,
            _assetAddress,
            tokenIds,
            amounts
        );
    }

    //private functions

    function _checkStakedAssets(
        address _stakeholder,
        StakeInfo memory _require,
        uint256[] memory _ids
    ) internal view returns (bool) {
        if (
            _ids.length < _require.minAmount || _ids.length > _require.maxAmount
        ) {
            return false;
        }

        //verify that all ids are staked
        Asset[] memory assets = stakingAndKeys.getStakedAssets(
            _stakeholder,
            _require.addr
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < assets.length; j++) {
                if (assets[j].tokenId == _ids[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./StakeAssetMeta.sol";

contract ExpeditionStakingAndKeys is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable,
    StakeAssetMeta
{
    using AddressUpgradeable for address;

    mapping(address => uint256) public assetTypes;
    mapping(address => Asset[]) public stakedAssets;

    IERC20 public exchangeToken;
    uint256 public exchangeRateForKey; // exchange rate for 1 key, it should be based on 18 decimals of the token

    mapping(address => uint256) public userKeys;
    uint256 public totalKeys;

    event StakedAssets(
        address indexed user,
        address indexed assetAddress,
        uint256[] tokenIds,
        uint256[] amounts
    );

    event UnstakedAssets(
        address indexed user,
        address indexed assetAddress,
        uint256[] tokenIds,
        uint256[] amounts
    );

    event SetupExchangeConfig(
        address exchangeTokenAddress,
        uint256 exchangeRateForKey
    );

    event TransferKeys(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setAssetType(address _assetAddress, uint256 _assetType)
        external
        onlyOwner
    {
        require(_assetAddress.isContract(), "assetAddress must be a contract");
        require(
            _assetType >= ASSET_TYPE_ERC20 && _assetType <= ASSET_TYPE_ERC1155,
            "assetType must be between 0 and 3"
        );

        assetTypes[_assetAddress] = _assetType;
    }

    function getStakedAssets(address _stakeholder, address _assetAddress)
        external
        view
        returns (Asset[] memory)
    {
        uint256 totalAssets = 0;
        for (uint256 i = 0; i < stakedAssets[_stakeholder].length; i++) {
            if (stakedAssets[_stakeholder][i].addr == _assetAddress) {
                totalAssets += 1;
            }
        }

        Asset[] memory assets = new Asset[](totalAssets);
        uint256 assetIndex = 0;
        for (uint256 i = 0; i < stakedAssets[_stakeholder].length; i++) {
            if (stakedAssets[_stakeholder][i].addr == _assetAddress) {
                assets[assetIndex] = stakedAssets[_stakeholder][i];
                assetIndex += 1;
            }
        }
        return assets;
    }

    function stakeAssets(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            _assetAddress.isContract() &&
                assetTypes[_assetAddress] != ASSET_TYPE_NONE,
            "assetAddress must be a contract that has been set"
        );

        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts must have the same length"
        );

        if (assetTypes[_assetAddress] == ASSET_TYPE_ERC20) {
            IERC20 asset = IERC20(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                //check the allowance & balance
                require(
                    asset.allowance(_stakeholder, address(this)) >=
                        _amounts[i] &&
                        asset.balanceOf(_stakeholder) >= _amounts[i],
                    "Not enough allowance or balance for tokens"
                );
            }

            for (uint i = 0; i < _tokenIds.length; i++) {
                //stake the asset
                asset.transferFrom(_stakeholder, address(this), _amounts[i]);
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE_ERC721) {
            IERC721 asset = IERC721(_assetAddress);

            //check the approval of the token
            require(
                asset.isApprovedForAll(_stakeholder, address(this)),
                "Not approved"
            );

            //check the ownership of the token
            for (uint i = 0; i < _tokenIds.length; i++) {
                require(
                    asset.ownerOf(_tokenIds[i]) == _stakeholder &&
                        _amounts[i] == 1,
                    "Not owner"
                );
            }

            //stake the asset
            for (uint i = 0; i < _tokenIds.length; i++) {
                asset.safeTransferFrom(
                    _stakeholder,
                    address(this),
                    _tokenIds[i]
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE_ERC1155) {
            IERC1155 asset = IERC1155(_assetAddress);

            //check the approval of the token
            require(
                asset.isApprovedForAll(_stakeholder, address(this)),
                "Not approved"
            );

            //check the balance of the token
            for (uint i = 0; i < _tokenIds.length; i++) {
                require(
                    asset.balanceOf(_stakeholder, _tokenIds[i]) >= _amounts[i],
                    "Not enough balance"
                );
            }

            //stake the asset
            asset.safeBatchTransferFrom(
                _stakeholder,
                address(this),
                _tokenIds,
                _amounts,
                ""
            );
        }

        //add the asset to the stakedAssets
        for (uint i = 0; i < _tokenIds.length; i++) {
            bool found = false;

            //append to existing staked assets
            for (uint j = 0; j < stakedAssets[_stakeholder].length; j++) {
                if (
                    stakedAssets[_stakeholder][j].addr == _assetAddress &&
                    stakedAssets[_stakeholder][j].tokenId == _tokenIds[i]
                ) {
                    stakedAssets[_stakeholder][j].amount += _amounts[i];

                    found = true;
                    break;
                }
            }

            //add new staked asset
            if (!found) {
                stakedAssets[_stakeholder].push(
                    Asset(
                        assetTypes[_assetAddress],
                        _assetAddress,
                        _tokenIds[i],
                        _amounts[i]
                    )
                );
            }
        }

        emit StakedAssets(_stakeholder, _assetAddress, _tokenIds, _amounts);
    }

    function unstakeAssets(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            _assetAddress.isContract() &&
                assetTypes[_assetAddress] != ASSET_TYPE_NONE,
            "assetAddress must be a contract that has been set"
        );

        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts must have the same length"
        );

        //check the staked assets
        for (uint i = 0; i < _tokenIds.length; i++) {
            bool found = false;
            for (uint j = 0; j < stakedAssets[_stakeholder].length; j++) {
                if (
                    stakedAssets[_stakeholder][j].addr == _assetAddress &&
                    stakedAssets[_stakeholder][j].tokenId == _tokenIds[i] &&
                    stakedAssets[_stakeholder][j].amount >= _amounts[i]
                ) {
                    found = true;
                }
            }

            require(found, "Not staked");
        }

        //unstakes the asset
        if (assetTypes[_assetAddress] == ASSET_TYPE_ERC20) {
            IERC20 asset = IERC20(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                asset.transfer(address(this), _amounts[i]);
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE_ERC721) {
            IERC721 asset = IERC721(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                asset.safeTransferFrom(
                    address(this),
                    _stakeholder,
                    _tokenIds[i]
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE_ERC1155) {
            IERC1155 asset = IERC1155(_assetAddress);

            asset.safeBatchTransferFrom(
                address(this),
                _stakeholder,
                _tokenIds,
                _amounts,
                ""
            );
        }

        //deduce the asset from the stakedAssets
        for (uint i = 0; i < _tokenIds.length; i++) {
            for (uint j = 0; j < stakedAssets[_stakeholder].length; j++) {
                if (
                    stakedAssets[_stakeholder][j].addr == _assetAddress &&
                    stakedAssets[_stakeholder][j].tokenId == _tokenIds[i]
                ) {
                    stakedAssets[_stakeholder][j].amount -= _amounts[i];
                    break;
                }
            }
        }

        emit UnstakedAssets(_stakeholder, _assetAddress, _tokenIds, _amounts);
    }

    //exchange key functions

    function setupExchangeConfig(
        address _exchangeTokenAddress,
        uint256 _exchangeRateForKey
    ) external onlyOwner {
        require(
            _exchangeTokenAddress.isContract(),
            "_exchangeTokenAddress must be a contract"
        );

        exchangeToken = IERC20(_exchangeTokenAddress);
        exchangeRateForKey = _exchangeRateForKey;

        emit SetupExchangeConfig(_exchangeTokenAddress, _exchangeRateForKey);
    }

    function exchangeKeys(bool tokenToKey, uint256 _keyAmount) external {
        require(exchangeRateForKey != 0, "Exchange config is not set");

        uint256 tokenAmount = _keyAmount * exchangeRateForKey;

        if (tokenToKey) {
            require(
                exchangeToken.allowance(msg.sender, address(this)) >=
                    tokenAmount,
                "Not enough allowance for tokens"
            );

            exchangeToken.transferFrom(msg.sender, address(this), tokenAmount);
            userKeys[msg.sender] += _keyAmount;
            totalKeys += _keyAmount;

            emit TransferKeys(address(this), msg.sender, _keyAmount);
        } else {
            require(userKeys[msg.sender] >= _keyAmount, "Not enough keys");

            userKeys[msg.sender] -= _keyAmount;
            totalKeys -= _keyAmount;
            exchangeToken.transfer(msg.sender, tokenAmount);

            emit TransferKeys(msg.sender, address(this), _keyAmount);
        }
    }

    function burnUserKeys(address _user, uint256 _amount) external onlyAdmin {
        require(userKeys[_user] >= _amount, "Not enough keys");

        userKeys[_user] -= _amount;
        totalKeys -= _amount;

        emit TransferKeys(_user, address(0), _amount);
    }

    function withdrawFunds(uint256 _amount, address _wallet)
        external
        onlyOwner
    {
        //make sure that reminder is enough to exchange keys
        require(
            exchangeToken.balanceOf(address(this)) >=
                _amount + totalKeys * exchangeRateForKey,
            "Not enough tokens"
        );

        exchangeToken.transfer(_wallet, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironPlanet is IERC721 {
    struct PlanetData {
        uint256 gene;
        uint256 baseAge;
        uint256 evolve;
        uint256 breedCount;
        uint256 breedCountMax;
        uint256 createTime; // before hatch
        uint256 bornTime; // after hatch
        uint256 lastBreedTime;
        uint256[] relicsTokenIDs;
        uint256[] parents; //parent token ids
        uint256[] children; //children token ids
    }

    function getPlanetData(uint256 tokenId)
        external
        view
        returns (
            PlanetData memory, //planetData
            bool //isAlive
        );
}