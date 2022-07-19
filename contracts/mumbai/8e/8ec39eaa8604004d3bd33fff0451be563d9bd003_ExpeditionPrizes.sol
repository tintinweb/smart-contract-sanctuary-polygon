// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./utils/AccessProtectedUpgradable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ExpeditionMeta.sol";
import "./NebulaExpedition.sol";
import "./ExpeditionStakingAndKeys.sol";
import "./interfaces/IApeironStar.sol";
import "./interfaces/IApeironGodiverseCollection.sol";

/// @title Contract for Expedition Prizes
/// @notice This contract is used to manage the prizes of the Expedition
contract ExpeditionPrizes is
    Initializable,
    AccessProtectedUpgradable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Receiver,
    IERC1155Receiver,
    ExpeditionMeta
{
    using AddressUpgradeable for address;

    enum PRIZE_TYPE {
        TRANSFER_NONE,
        TRANSFER_ERC20,
        TRANSFER_ERC721,
        TRANSFER_ERC1155,
        MINTABLE_STAR,
        MINTABLE_GODIVERSE_COLLECTION
    }

    struct Prize {
        PRIZE_TYPE prizeType;
        address addr;
        uint256 tokenId;
        uint256 amount;
    }

    struct Treasure {
        address user;
        uint256 burnKeyAmount;
        uint256 treasureId;
        Prize[] prizes;
    }

    NebulaExpedition private expedition;
    /// @notice Contract address for NebulaExpedition
    address public expeditionAddress;

    /// @notice Prize per treasure id, which can be empty if prize was claimed
    mapping(uint256 => Treasure) internal treasurePerId;
    /// @notice Treasure ids per user
    mapping(address => uint256[]) internal treasureIdsPerUser;

    /// @notice This event is fired when admin assign the prizes to the users
    /// @param expeditionId Expedition id
    /// @param user User address
    /// @param burnKeyAmount Burn key amount
    /// @param prizes Prizes
    event ClaimableTreasure(
        uint256 indexed expeditionId,
        address indexed user,
        uint256 burnKeyAmount,
        uint256 treasureId,
        Prize[] prizes
    );

    /// @notice This event is fired when user claim the prize
    event ClaimedPrize(
        address indexed user,
        uint256 indexed treasureId,
        address prizeAddress,
        uint256 arg1,
        uint256 arg2
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev initialize the contract
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @dev Required by IERC721Receiver
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {}

    /// @dev Required by IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Required by IERC1155Receiver
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Required by IERC1155Receiver
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Link up the NebulaExpedition contract
    function setExpedition(address _address) external onlyOwner {
        require(
            _address != address(0) && _address.isContract(),
            "address must be contract"
        );

        expedition = NebulaExpedition(_address);
        expeditionAddress = _address;
    }

    /// @notice Assign the prizes to the users
    /// @param _expeditionId Expedition id
    /// @param _treasures Treasures
    function setBatchUserExpeditionTreasures(
        uint256 _expeditionId,
        Treasure[] memory _treasures
    ) external onlyAdmin {
        require(expeditionAddress != address(0), "expedition contract not set");
        require(
            expedition.stakingAndKeysAddress() != address(0),
            "staking and keys contract not set"
        );

        //verify expedition is valid (state should be FINISHED)
        require(
            expedition.getExpeditionState(_expeditionId) == STATE_FINISHED,
            "expedition should be finished"
        );

        for (uint256 i = 0; i < _treasures.length; i++) {
            //assign the prizes by treasure id
            treasurePerId[_treasures[i].treasureId].user = _treasures[i].user;
            treasurePerId[_treasures[i].treasureId].burnKeyAmount = _treasures[
                i
            ].burnKeyAmount;
            treasurePerId[_treasures[i].treasureId].treasureId = _treasures[i]
                .treasureId;
            for (uint256 j = 0; j < _treasures[i].prizes.length; j++) {
                treasurePerId[_treasures[i].treasureId].prizes.push(
                    _treasures[i].prizes[j]
                );
            }

            //add the treasure id to the user
            treasureIdsPerUser[_treasures[i].user].push(
                _treasures[i].treasureId
            );

            emit ClaimableTreasure(
                _expeditionId,
                _treasures[i].user,
                _treasures[i].burnKeyAmount,
                _treasures[i].treasureId,
                _treasures[i].prizes
            );
        }
    }

    /// @notice Let user to claim the prize
    /// @param _treasureId Treasure index
    function claimTreasure(uint256 _treasureId) external nonReentrant {
        require(
            treasurePerId[_treasureId].user == msg.sender &&
                treasurePerId[_treasureId].prizes.length > 0,
            "no treasure to claim"
        );

        ExpeditionStakingAndKeys stakingAndKeys = ExpeditionStakingAndKeys(
            expedition.stakingAndKeysAddress()
        );

        //burn user keys
        stakingAndKeys.burnUserKeys(
            msg.sender,
            treasurePerId[_treasureId].burnKeyAmount
        );

        Prize[] memory prizes = treasurePerId[_treasureId].prizes;
        for (uint256 i = 0; i < prizes.length; i++) {
            if (prizes[i].prizeType == PRIZE_TYPE.TRANSFER_ERC20) {
                IERC20 erc20 = IERC20(prizes[i].addr);

                emit ClaimedPrize(
                    msg.sender,
                    _treasureId,
                    prizes[i].addr,
                    prizes[i].amount,
                    0
                );

                require(
                    erc20.transfer(msg.sender, prizes[i].amount),
                    "transfer failed"
                );
            } else if (prizes[i].prizeType == PRIZE_TYPE.TRANSFER_ERC721) {
                IERC721 erc721 = IERC721(prizes[i].addr);

                emit ClaimedPrize(
                    msg.sender,
                    _treasureId,
                    prizes[i].addr,
                    prizes[i].tokenId,
                    0
                );

                erc721.safeTransferFrom(
                    address(this),
                    msg.sender,
                    prizes[i].tokenId
                );
            } else if (prizes[i].prizeType == PRIZE_TYPE.TRANSFER_ERC1155) {
                IERC1155 erc1155 = IERC1155(prizes[i].addr);

                emit ClaimedPrize(
                    msg.sender,
                    _treasureId,
                    prizes[i].addr,
                    prizes[i].tokenId,
                    prizes[i].amount
                );

                erc1155.safeTransferFrom(
                    address(this),
                    msg.sender,
                    prizes[i].tokenId,
                    prizes[i].amount,
                    ""
                );
            } else if (prizes[i].prizeType == PRIZE_TYPE.MINTABLE_STAR) {
                IApeironStar star = IApeironStar(prizes[i].addr);

                emit ClaimedPrize(
                    msg.sender,
                    _treasureId,
                    prizes[i].addr,
                    prizes[i].tokenId,
                    0
                );

                star.safeMint(prizes[i].amount, msg.sender, prizes[i].tokenId);
            } else if (
                prizes[i].prizeType == PRIZE_TYPE.MINTABLE_GODIVERSE_COLLECTION
            ) {
                IApeironGodiverseCollection collection = IApeironGodiverseCollection(
                        prizes[i].addr
                    );

                emit ClaimedPrize(
                    msg.sender,
                    _treasureId,
                    prizes[i].addr,
                    prizes[i].tokenId,
                    prizes[i].amount
                );

                collection.mint(prizes[i].tokenId, prizes[i].amount, "");
                collection.safeTransferFrom(
                    address(this),
                    msg.sender,
                    prizes[i].tokenId,
                    prizes[i].amount,
                    ""
                );
            } else {
                revert("invalid prize type");
            }
        }

        delete treasurePerId[_treasureId];
    }

    /// @notice Get prize by treasure id
    /// @param _treasureId Treasure index
    /// @return Prize
    function getTreasureById(uint256 _treasureId)
        external
        view
        returns (Treasure memory)
    {
        return treasurePerId[_treasureId];
    }

    /// @notice Get all the treasure ids by user
    /// @param _user User address
    /// @return treasure ids
    function getUserTreasureIds(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return treasureIdsPerUser[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
        uint256[] optionalAssetWhitelistIds;
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "./ExpeditionMeta.sol";
import "./ExpeditionStakingAndKeys.sol";
import "./StakeAssetMeta.sol";
import "./TokenReceiptHandler.sol";

import "./interfaces/IApeironPlanet.sol";

/// @title Contract for Nebula Expedition
/// @notice You can use this contract to interact with expedition
contract NebulaExpedition is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable,
    ReentrancyGuardUpgradeable,
    ExpeditionMeta,
    StakeAssetMeta
{
    using AddressUpgradeable for address;

    ExpeditionStakingAndKeys internal stakingAndKeys;
    /// @notice Contract address for ExpeditionStakingAndKeys
    address public stakingAndKeysAddress;

    TokenReceiptHandler internal tokenReceiptHandler;

    /// @notice List of expedition info
    mapping(uint256 => ExpeditionInfo) internal expeditionInfoList;
    /// @notice last expedition id
    uint256 internal lastExpeditionId;

    /// @notice List of user's joined expedition detail
    mapping(address => mapping(uint256 => JoinExpedition))
        internal userExpeditions;
    /// @notice List of users' joined expedition id
    mapping(address => uint256[]) internal userExpeditionIds;

    /// @notice This event will be emitted when setupExpeditionInfo was executed by admin
    /// @param expeditionId Expedition id
    /// @param startFrom Expedition start time
    /// @param endTo Expedition end time
    /// @param requiredPlanets Required planets to join expedition
    /// @param optionalAsset Optional assets to join expedition
    /// @param requiredKeyAmount Required key amount to join expedition
    event UpdatedExpedition(
        uint256 expeditionId,
        uint256 startFrom,
        uint256 endTo,
        StakeInfo requiredPlanets,
        StakeInfo optionalAsset,
        uint256 requiredKeyAmount
    );

    /// @notice This event will be emitted when user join the expedition
    /// @param expeditionId Expedition id
    /// @param user User address
    /// @param planetIds Staked planet ids
    /// @param optionalAssetIds Staked optional asset ids
    /// @param keyAmount Staked key amount
    event JoinedExpedition(
        uint256 indexed expeditionId,
        address indexed user,
        uint256[] planetIds,
        uint256[] optionalAssetIds,
        uint256 keyAmount
    );

    /// @dev Determine if expedition is started and not joined
    /// @param _expeditionId Expedition id
    modifier isExpeditionPeriodAndNotJoined(uint256 _expeditionId) {
        require(
            _isExpeditionPeriodAndNotJoined(_expeditionId),
            "Expedition is not in period or User is not joined to expedition"
        );
        _;
    }

    function _isExpeditionPeriodAndNotJoined(uint256 _expeditionId)
        internal
        view
        returns (bool)
    {
        return
            getExpeditionState(_expeditionId) == STATE_STARTED &&
            userExpeditions[msg.sender][_expeditionId].joinedAt == 0;
    }

    /// @dev Determine if expedition is claimable and joined
    /// @param _expeditionId Expedition id
    modifier isExpeditionClaimableAndJoined(uint256 _expeditionId) {
        require(
            _isExpeditionClaimableAndJoined(_expeditionId),
            "Expedition is not claimable or User require to join the expedition"
        );
        _;
    }

    function _isExpeditionClaimableAndJoined(uint256 _expeditionId)
        internal
        view
        returns (bool)
    {
        return
            getExpeditionState(_expeditionId) == STATE_CLAIMABLE &&
            userExpeditions[msg.sender][_expeditionId].joinedAt > 0;
    }

    /// @dev Determine if expedition requirement is met or not
    /// @param _expeditionId Expedition id
    /// @param _planetIds Staked planet ids
    /// @param _assetIds Staked optional asset ids
    /// @param _keyAmount Staked key amount
    modifier isStakedAssets(
        uint256 _expeditionId,
        uint256[] memory _planetIds,
        uint256[] memory _assetIds,
        uint256 _keyAmount
    ) {
        require(
            expeditionInfoList[_expeditionId].requiredKeyAmount <= _keyAmount &&
                stakingAndKeys.userKeys(msg.sender) >= _keyAmount &&
                _checkStakedAssets(
                    msg.sender,
                    expeditionInfoList[_expeditionId].requiredPlanet.addr,
                    expeditionInfoList[_expeditionId].requiredPlanet.minAmount,
                    expeditionInfoList[_expeditionId].requiredPlanet.maxAmount,
                    _planetIds
                ) &&
                _checkStakedAssets(
                    msg.sender,
                    expeditionInfoList[_expeditionId].optionalAsset.addr,
                    expeditionInfoList[_expeditionId].optionalAsset.minAmount,
                    expeditionInfoList[_expeditionId].optionalAsset.maxAmount,
                    _assetIds
                ),
            "Not enough staked assets"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Link up the peer contracts
    /// @param _stakingAndKeys ExpeditionStakingAndKeys contract address
    /// @param _tokenReceipt TokenReceiptHandler contract address
    function setupPeerContracts(address _stakingAndKeys, address _tokenReceipt)
        external
        onlyOwner
    {
        require(
            _stakingAndKeys != address(0) &&
                _stakingAndKeys.isContract() &&
                _tokenReceipt != address(0) &&
                _tokenReceipt.isContract(),
            "addresses must be contract"
        );

        stakingAndKeys = ExpeditionStakingAndKeys(_stakingAndKeys);
        stakingAndKeysAddress = _stakingAndKeys;

        tokenReceiptHandler = TokenReceiptHandler(_tokenReceipt);
    }

    /// @notice Setup expedition info by admin
    /// @param _expeditionId Expedition id
    /// @param _info Expedition info
    function setupExpeditionInfo(
        uint256 _expeditionId,
        ExpeditionInfo memory _info
    ) external onlyAdmin {
        require(
            _info.startFrom <= _info.endTo,
            "startFrom must be before endTo"
        );

        require(
            //for update expedition info
            expeditionInfoList[_expeditionId].startFrom != 0 ||
                //or earlyer than the new one
                expeditionInfoList[lastExpeditionId].endTo <= _info.startFrom,
            "last expedition must be earlier than the new one"
        );

        expeditionInfoList[_expeditionId] = _info;
        lastExpeditionId = _expeditionId;

        emit UpdatedExpedition(
            _expeditionId,
            _info.startFrom,
            _info.endTo,
            _info.requiredPlanet,
            _info.optionalAsset,
            _info.requiredKeyAmount
        );
    }

    /// @notice Setup that expedition is claimable by admin
    /// @param _expeditionId Expedition id
    function setExpeditionClaimable(uint256 _expeditionId) external onlyAdmin {
        require(
            getExpeditionState(_expeditionId) == STATE_FINISHED,
            "Expedition is not finished"
        );

        expeditionInfoList[_expeditionId].isClaimableNow = true;
    }

    /// @notice Let user to join expedition
    /// @param _expeditionId Expedition id
    /// @param _planetIds Staked planet ids
    /// @param _assetIds Staked optional asset ids
    /// @param _keyAmount Staked key amount
    function joinExpedition(
        uint256 _expeditionId,
        uint256[] memory _planetIds,
        uint256[] memory _assetIds,
        uint256 _keyAmount
    )
        external
        isExpeditionPeriodAndNotJoined(_expeditionId)
        isStakedAssets(_expeditionId, _planetIds, _assetIds, _keyAmount)
    {
        userExpeditions[msg.sender][_expeditionId] = JoinExpedition(
            block.timestamp,
            _planetIds,
            _assetIds,
            _keyAmount
        );
        userExpeditionIds[msg.sender].push(_expeditionId);

        emit JoinedExpedition(
            _expeditionId,
            msg.sender,
            _planetIds,
            _assetIds,
            _keyAmount
        );
    }

    /// @notice Get the expedition status
    /// @param _expeditionId Expedition id
    /// @return Expedition status
    function getExpeditionState(uint256 _expeditionId)
        public
        view
        returns (uint256)
    {
        if (
            expeditionInfoList[_expeditionId].startFrom > block.timestamp ||
            expeditionInfoList[_expeditionId].startFrom == 0
        ) {
            return STATE_NOT_STARTED;
        } else if (
            expeditionInfoList[_expeditionId].startFrom <= block.timestamp &&
            block.timestamp <= expeditionInfoList[_expeditionId].endTo
        ) {
            return STATE_STARTED;
        } else if (expeditionInfoList[_expeditionId].isClaimableNow) {
            return STATE_CLAIMABLE;
        }

        return STATE_FINISHED;
    }

    //staking functions

    /// @notice Let user to stake NFT (planets or optional assets)
    /// @param _expeditionId Expedition id
    /// @param _assetAddress NFT address
    /// @param _tokenIds NFT token ids
    function stakeNFT(
        uint256 _expeditionId,
        address _assetAddress,
        uint256[] memory _tokenIds
    ) external nonReentrant isExpeditionPeriodAndNotJoined(_expeditionId) {
        require(_assetAddress.isContract(), "address must be contract");
        require(_tokenIds.length > 0, "tokenIds must be not empty");

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
        if (
            _assetAddress ==
            expeditionInfoList[_expeditionId].requiredPlanet.addr
        ) {
            //verify planets are already born
            IApeironPlanet planet = IApeironPlanet(_assetAddress);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                (IApeironPlanet.PlanetData memory planetData, ) = planet
                    .getPlanetData(_tokenIds[i]);
                require(planetData.bornTime > 0, "planet is not born");
            }

            maxAmount = expeditionInfoList[_expeditionId]
                .requiredPlanet
                .maxAmount;
        } else if (
            _assetAddress ==
            expeditionInfoList[_expeditionId].optionalAsset.addr
        ) {
            //verify optional assets are already whitelisted if whitelist exists
            if (
                expeditionInfoList[_expeditionId]
                    .optionalAssetWhitelistIds
                    .length > 0
            ) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    bool isExists = false;
                    for (
                        uint256 j = 0;
                        j <
                        expeditionInfoList[_expeditionId]
                            .optionalAssetWhitelistIds
                            .length;
                        j++
                    ) {
                        if (
                            expeditionInfoList[_expeditionId]
                                .optionalAssetWhitelistIds[j] == _tokenIds[i]
                        ) {
                            isExists = true;
                            break;
                        }
                    }
                    require(isExists, "tokenIds must be in whitelist");
                }
            }

            maxAmount = expeditionInfoList[_expeditionId]
                .optionalAsset
                .maxAmount;
        }

        Asset[] memory assets = stakingAndKeys.getStakedAssets(
            msg.sender,
            _assetAddress
        );

        require(
            _tokenIds.length + assets.length <= maxAmount,
            "Too many assets"
        );

        stakingAndKeys.stakeAssets(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _asDefaultValueArray(1, _tokenIds.length)
        );
        tokenReceiptHandler.createReceipts(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _asDefaultValueArray(1, _tokenIds.length)
        );
    }

    /// @notice Let user to unstake NFT (planets or optional assets) on in period or claimable
    /// @param _expeditionId Expedition id
    /// @param _assetAddress NFT address
    /// @param _tokenIds NFT token ids
    function unstakeNFT(
        uint256 _expeditionId,
        address _assetAddress,
        uint256[] memory _tokenIds
    ) external nonReentrant {
        require(
            _isExpeditionPeriodAndNotJoined(_expeditionId) ||
                _isExpeditionClaimableAndJoined(_expeditionId),
            "Period is not started or already claimable"
        );

        require(
            _expeditionId == lastExpeditionId ||
                //rejected if current expedition(lastExpeditionId) is already joined or time is up
                _isExpeditionPeriodAndNotJoined(lastExpeditionId) ||
                //rejected if current expedition(lastExpeditionId) is not joined or claimable is not ready
                _isExpeditionClaimableAndJoined(lastExpeditionId),
            "Current expedition is not started or already claimable"
        );

        require(_assetAddress.isContract(), "address must be contract");
        require(_tokenIds.length > 0, "tokenIds must be not empty");

        bool enough = false;
        if (
            _assetAddress ==
            expeditionInfoList[_expeditionId].requiredPlanet.addr
        ) {
            enough = _checkStakedAssets(
                msg.sender,
                expeditionInfoList[_expeditionId].requiredPlanet.addr,
                _tokenIds.length,
                _tokenIds.length,
                _tokenIds
            );
        } else if (
            _assetAddress ==
            expeditionInfoList[_expeditionId].optionalAsset.addr
        ) {
            enough = _checkStakedAssets(
                msg.sender,
                expeditionInfoList[_expeditionId].optionalAsset.addr,
                _tokenIds.length,
                _tokenIds.length,
                _tokenIds
            );
        }

        require(enough, "Not enough staked assets");

        stakingAndKeys.unstakeAssets(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _asDefaultValueArray(1, _tokenIds.length)
        );
        tokenReceiptHandler.burnReceipts(
            msg.sender,
            _assetAddress,
            _tokenIds,
            _asDefaultValueArray(1, _tokenIds.length)
        );
    }

    /// @notice Let user to stake FT (WETH or APRS)
    /// @param _assetAddress FT address
    /// @param _amount FT amount
    function stakeFT(address _assetAddress, uint256 _amount)
        external
        nonReentrant
    {
        stakingAndKeys.stakeAssets(
            msg.sender,
            _assetAddress,
            _asDefaultValueArray(0, 1),
            _asDefaultValueArray(_amount, 1)
        );
        tokenReceiptHandler.createReceipts(
            msg.sender,
            _assetAddress,
            _asDefaultValueArray(0, 1),
            _asDefaultValueArray(_amount, 1)
        );
    }

    /// @notice Let user to unstake FT (WETH or APRS)
    /// @param _assetAddress FT address
    /// @param _amount FT amount
    function unstakeFT(address _assetAddress, uint256 _amount)
        external
        nonReentrant
    {
        stakingAndKeys.unstakeAssets(
            msg.sender,
            _assetAddress,
            _asDefaultValueArray(0, 1),
            _asDefaultValueArray(_amount, 1)
        );
        tokenReceiptHandler.burnReceipts(
            msg.sender,
            _assetAddress,
            _asDefaultValueArray(0, 1),
            _asDefaultValueArray(_amount, 1)
        );
    }

    /// @notice Exchange key from token
    /// @param _expeditionId Expedition id
    /// @param _keyAmount To key amount
    function exchangeTokenToKey(uint256 _expeditionId, uint256 _keyAmount)
        external
        nonReentrant
        isExpeditionPeriodAndNotJoined(_expeditionId)
    {
        stakingAndKeys.exchangeKeys(msg.sender, true, _keyAmount);
    }

    /// @notice Exchange token from key
    /// @param _expeditionId Expedition id
    /// @param _keyAmount From key amount
    function exchangeKeyToToken(uint256 _expeditionId, uint256 _keyAmount)
        external
        nonReentrant
    {
        require(
            _isExpeditionPeriodAndNotJoined(_expeditionId) ||
                _isExpeditionClaimableAndJoined(_expeditionId),
            "Period is not started or already claimable"
        );

        stakingAndKeys.exchangeKeys(msg.sender, false, _keyAmount);
    }

    /// @notice Get Expedition Info by expedition id
    /// @param _expeditionId Expedition id
    /// @return Expedition info
    function getExpeditionInfoList(uint256 _expeditionId)
        external
        view
        returns (ExpeditionInfo memory)
    {
        return expeditionInfoList[_expeditionId];
    }

    /// @notice Get user's joined expedition by expedition id
    /// @param _user User address
    /// @param _expeditionId Expedition id
    /// @return Joined expedition info
    function getUserExpedition(address _user, uint256 _expeditionId)
        external
        view
        returns (JoinExpedition memory)
    {
        return userExpeditions[_user][_expeditionId];
    }

    /// @notice Get user's joined expedition ids in list
    /// @param _user User address
    /// @return Joined expedition ids list
    function getUserExpeditionIds(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userExpeditionIds[_user];
    }

    //private functions

    /// @dev Check if user is staked assets
    /// @param _stakeholder Stakeholder address
    /// @param _assetAddress Asset contract address
    /// @param _assetMinAmount Min amount of asset
    /// @param _assetMaxAmount Max amount of asset
    /// @param _ids Token ids
    function _checkStakedAssets(
        address _stakeholder,
        address _assetAddress,
        uint256 _assetMinAmount,
        uint256 _assetMaxAmount,
        uint256[] memory _ids
    ) internal view returns (bool) {
        if (_ids.length < _assetMinAmount || _ids.length > _assetMaxAmount) {
            return false;
        }

        //verify that all ids are staked
        Asset[] memory assets = stakingAndKeys.getStakedAssets(
            _stakeholder,
            _assetAddress
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < assets.length; j++) {
                if (
                    assets[j].tokenId == _ids[i] &&
                    // amount is 0 if token is already unstaked
                    assets[j].amount > 0
                ) {
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

    function _asDefaultValueArray(uint256 element, uint256 length)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = element;
        }

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./StakeAssetMeta.sol";

/// @title Contract for Expedition's Staking and Keys
/// @notice This contract is used to manage the staking and keys of the Expedition contract.
contract ExpeditionStakingAndKeys is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable,
    IERC721Receiver,
    IERC1155Receiver,
    StakeAssetMeta
{
    using AddressUpgradeable for address;

    /// @notice Mapping of asset address and type
    mapping(address => ASSET_TYPE) public assetTypes;

    mapping(address => Asset[]) internal stakedAssets;

    /// @notice Contract for exchange token
    IERC20 public exchangeToken;
    /// @notice Exchange rate for 1 key
    /// @dev It should be based on 18 decimals of the token
    uint256 public exchangeRateForKey;

    /// @notice User's keys
    mapping(address => uint256) public userKeys;
    /// @notice Total keys whose are owned by user
    uint256 public totalKeys;

    /// @notice This event will be emitted when user stakes assets
    /// @param user Address of the user who stakes the asset
    /// @param assetAddress Address of the asset
    /// @param tokenIds Array of token ids of the asset
    /// @param amounts Array of amounts of asset for this staking
    /// @param totalAmounts Array of amounts of staked asset
    event StakedAssets(
        address indexed user,
        address indexed assetAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] totalAmounts
    );

    /// @notice This event will be emitted when user unstakes assets
    /// @param user Address of the user who unstakes the asset
    /// @param assetAddress Address of the asset
    /// @param tokenIds Array of token ids of the asset
    /// @param amounts Array of amounts of asset for this unstaking
    /// @param totalAmounts Array of amounts of staked asset
    event UnstakedAssets(
        address indexed user,
        address indexed assetAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] totalAmounts
    );

    /// @notice This event will be emitted when SetupExchangeConfig was executed by admin
    /// @param exchangeTokenAddress Address of the token used to exchange keys
    /// @param exchangeRateForKey Exchange rate for 1 key
    event SetupExchangeConfig(
        address exchangeTokenAddress,
        uint256 exchangeRateForKey
    );

    /// @notice This event will be emiitted when someone transfer a key to another user
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param amount Amount of transferred key
    event TransferKeys(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @dev Required by IERC1155Receiver
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {}

    /// @dev Required by IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Required by IERC1155Receiver
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Required by IERC1155Receiver
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Map the asset address to the asset type
    /// @param _assetAddress Address of the asset
    /// @param _assetType Type of the asset
    function setAssetType(address _assetAddress, ASSET_TYPE _assetType)
        external
        onlyOwner
    {
        require(_assetAddress.isContract(), "assetAddress must be a contract");
        require(
            _assetType >= ASSET_TYPE.ERC20 && _assetType <= ASSET_TYPE.ERC1155,
            "assetType must be between 1 and 3"
        );

        assetTypes[_assetAddress] = _assetType;
    }

    /// @notice Get all staked assets for specific asset address
    /// @param _stakeholder Stakeholder address
    /// @param _assetAddress Address of the asset
    /// @return Array of assets
    function getStakedAssets(address _stakeholder, address _assetAddress)
        external
        view
        returns (Asset[] memory)
    {
        uint256 totalAssets = 0;
        for (uint256 i = 0; i < stakedAssets[_stakeholder].length; i++) {
            if (
                stakedAssets[_stakeholder][i].addr == _assetAddress &&
                stakedAssets[_stakeholder][i].amount > 0
            ) {
                totalAssets += 1;
            }
        }

        Asset[] memory assets = new Asset[](totalAssets);
        uint256 assetIndex = 0;
        for (uint256 i = 0; i < stakedAssets[_stakeholder].length; i++) {
            if (
                stakedAssets[_stakeholder][i].addr == _assetAddress &&
                stakedAssets[_stakeholder][i].amount > 0
            ) {
                assets[assetIndex] = stakedAssets[_stakeholder][i];
                assetIndex += 1;
            }
        }
        return assets;
    }

    /// @notice Stake assets through admin contract
    /// @param _stakeholder Stakeholder address
    /// @param _assetAddress Address of the asset
    /// @param _tokenIds Array of token ids of the asset
    /// @param _amounts Array of amounts of the asset
    function stakeAssets(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            _assetAddress.isContract() &&
                assetTypes[_assetAddress] != ASSET_TYPE.NONE,
            "assetAddress must be a contract that has been set"
        );

        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts must have the same length"
        );

        uint256[] memory totalAmounts = new uint256[](_amounts.length);

        //add the asset to the stakedAssets
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_amounts[i] > 0, "amount must be greater than 0");

            bool found = false;

            //append to existing staked assets
            for (uint j = 0; j < stakedAssets[_stakeholder].length; j++) {
                if (
                    stakedAssets[_stakeholder][j].addr == _assetAddress &&
                    stakedAssets[_stakeholder][j].tokenId == _tokenIds[i]
                ) {
                    stakedAssets[_stakeholder][j].amount += _amounts[i];
                    totalAmounts[i] = stakedAssets[_stakeholder][j].amount;

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
                totalAmounts[i] = _amounts[i];
            }
        }

        emit StakedAssets(
            _stakeholder,
            _assetAddress,
            _tokenIds,
            _amounts,
            totalAmounts
        );

        //do transfer stuff
        if (assetTypes[_assetAddress] == ASSET_TYPE.ERC20) {
            IERC20 erc20 = IERC20(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                //stake the asset
                require(
                    erc20.transferFrom(
                        _stakeholder,
                        address(this),
                        _amounts[i]
                    ),
                    "transfer failed"
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE.ERC721) {
            IERC721 erc721 = IERC721(_assetAddress);

            //stake the asset
            for (uint i = 0; i < _tokenIds.length; i++) {
                erc721.safeTransferFrom(
                    _stakeholder,
                    address(this),
                    _tokenIds[i]
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE.ERC1155) {
            IERC1155 erc1155 = IERC1155(_assetAddress);

            //stake the asset
            erc1155.safeBatchTransferFrom(
                _stakeholder,
                address(this),
                _tokenIds,
                _amounts,
                ""
            );
        }
    }

    /// @notice Unstake assets through admin contract
    /// @param _stakeholder Stakeholder address
    /// @param _assetAddress Address of the asset
    /// @param _tokenIds Array of token ids of the asset
    /// @param _amounts Array of amounts of the asset
    function unstakeAssets(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            _assetAddress.isContract() &&
                assetTypes[_assetAddress] != ASSET_TYPE.NONE,
            "assetAddress must be a contract that has been set"
        );

        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts must have the same length"
        );

        uint256[] memory totalAmounts = new uint256[](_amounts.length);

        //check the staked assets
        uint found = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            for (uint j = 0; j < stakedAssets[_stakeholder].length; j++) {
                if (
                    stakedAssets[_stakeholder][j].addr == _assetAddress &&
                    stakedAssets[_stakeholder][j].tokenId == _tokenIds[i] &&
                    stakedAssets[_stakeholder][j].amount >= _amounts[i]
                ) {
                    found += 1;
                    stakedAssets[_stakeholder][j].amount -= _amounts[i];
                    totalAmounts[i] = stakedAssets[_stakeholder][j].amount;
                    break;
                }
            }
        }
        require(found == _tokenIds.length, "Not staked");

        emit UnstakedAssets(
            _stakeholder,
            _assetAddress,
            _tokenIds,
            _amounts,
            totalAmounts
        );

        //unstakes the asset
        if (assetTypes[_assetAddress] == ASSET_TYPE.ERC20) {
            IERC20 erc20 = IERC20(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                require(
                    erc20.transfer(_stakeholder, _amounts[i]),
                    "transfer failed"
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE.ERC721) {
            IERC721 erc721 = IERC721(_assetAddress);

            for (uint i = 0; i < _tokenIds.length; i++) {
                erc721.safeTransferFrom(
                    address(this),
                    _stakeholder,
                    _tokenIds[i]
                );
            }
        } else if (assetTypes[_assetAddress] == ASSET_TYPE.ERC1155) {
            IERC1155 erc1155 = IERC1155(_assetAddress);

            erc1155.safeBatchTransferFrom(
                address(this),
                _stakeholder,
                _tokenIds,
                _amounts,
                ""
            );
        }
    }

    //exchange key functions

    /// @notice Setup the exchange key by owner
    /// @param _exchangeTokenAddress Address of the token used to exchange keys
    /// @param _exchangeRateForKey Exchange rate for 1 key
    function setupExchangeConfig(
        address _exchangeTokenAddress,
        uint256 _exchangeRateForKey
    ) external onlyOwner {
        require(
            _exchangeTokenAddress != address(0) &&
                _exchangeTokenAddress.isContract(),
            "exchangeTokenAddress must be a contract"
        );

        exchangeToken = IERC20(_exchangeTokenAddress);

        require(
            //0.01
            _exchangeRateForKey >= 10**16 &&
                //100
                _exchangeRateForKey <= 10**20,
            "exchangeRateForKey must be between 10**16 and 10**20"
        );

        exchangeRateForKey = _exchangeRateForKey;

        emit SetupExchangeConfig(_exchangeTokenAddress, _exchangeRateForKey);
    }

    /// @notice Let user to exchange keys (from or to)
    /// @param _stakeholder Stakeholder address
    /// @param tokenToKey Flag between token to key or key to token
    /// @param _keyAmount Amount of keys to exchange
    function exchangeKeys(
        address _stakeholder,
        bool tokenToKey,
        uint256 _keyAmount
    ) external onlyAdmin {
        require(exchangeRateForKey != 0, "Exchange config is not set");

        require(_keyAmount > 0, "amount must be greater than 0");

        uint256 tokenAmount = _keyAmount * exchangeRateForKey;

        if (tokenToKey) {
            require(
                exchangeToken.allowance(_stakeholder, address(this)) >=
                    tokenAmount,
                "Not enough allowance for tokens"
            );

            userKeys[_stakeholder] += _keyAmount;
            totalKeys += _keyAmount;

            emit TransferKeys(address(this), _stakeholder, _keyAmount);

            require(
                exchangeToken.transferFrom(
                    _stakeholder,
                    address(this),
                    tokenAmount
                ),
                "transfer failed"
            );
        } else {
            require(userKeys[_stakeholder] >= _keyAmount, "Not enough keys");

            userKeys[_stakeholder] -= _keyAmount;
            totalKeys -= _keyAmount;

            emit TransferKeys(_stakeholder, address(this), _keyAmount);

            require(
                exchangeToken.transfer(_stakeholder, tokenAmount),
                "transfer failed"
            );
        }
    }

    /// @notice Burn user keys by admin
    /// @param _user User address
    /// @param _amount Amount of keys to burn
    function burnUserKeys(address _user, uint256 _amount) external onlyAdmin {
        require(userKeys[_user] >= _amount, "Not enough keys");

        userKeys[_user] -= _amount;
        totalKeys -= _amount;

        emit TransferKeys(_user, address(0), _amount);
    }

    /// @notice Withdraw funds by owner, that amount can't be exceeded by total burn keys' values
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

        require(exchangeToken.transfer(_wallet, _amount), "transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IApeironStar {
    function safeMint(
        uint256 gene,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IApeironGodiverseCollection {
    function mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
        __Context_init_unchained();
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract StakeAssetMeta {
    enum ASSET_TYPE {
        NONE,
        ERC20,
        ERC721,
        ERC1155
    }

    struct Asset {
        ASSET_TYPE assetType;
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

import "./interfaces/ITokenReceiptable.sol";

/// @title Contract for Token Receipt Handler
/// @notice This contract is used to handle token receipts for mint or burn.
contract TokenReceiptHandler is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable
{
    using AddressUpgradeable for address;

    /// @notice The mapping of token to receipt contract
    mapping(address => ITokenReceiptable) internal tokenReceiptables;

    /// @notice This event will be emitted when token receipt was setup
    /// @param originalToken Address of the original token
    /// @param receiptToken Address of the token receipt
    event SetupTokenReceipt(address originalToken, address receiptToken);

    /// @notice This event will be emitted when receipt is created.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event CreateReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice This event will be emitted when receipt is burnt.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event BurnReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Setup token receipt
    /// @param _originalToken Address of the original token
    /// @param _receiptToken Address of the token receipt
    function setupTokenReceipt(address _originalToken, address _receiptToken)
        external
        onlyAdmin
    {
        require(
            _originalToken.isContract() && _receiptToken.isContract(),
            "Token must be a contract"
        );

        ITokenReceiptable tokenReceiptable = ITokenReceiptable(_receiptToken);
        require(
            tokenReceiptable.originalToken() == _originalToken,
            "ITokenReceiptable should be came from same original token"
        );

        tokenReceiptables[_originalToken] = tokenReceiptable;

        emit SetupTokenReceipt(_originalToken, _receiptToken);
    }

    /// @notice Create receipts as a proof for assets when stakeholder want to stake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function createReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit CreateReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].mintForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }

    /// @notice Burn receipts as a proof for assets when stakeholder want to unstake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function burnReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit BurnReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].burnForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Interface for Receipt Token
/// @notice This interface is used to extend for Receipt Token
interface ITokenReceiptable {
    /// @dev The address of the original token
    /// @return The address of the original token
    function originalToken() external view returns (address);

    /// @dev Mint function for TokenReceiptHandler
    /// @param receiptTo Create receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function mintForReceipt(
        address receiptTo,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @dev Burn function for TokenReceiptHandler
    /// @param receiptFrom Burn receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function burnForReceipt(
        address receiptFrom,
        uint256 tokenId,
        uint256 amount
    ) external;
}