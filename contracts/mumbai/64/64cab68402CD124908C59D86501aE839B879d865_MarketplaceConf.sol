// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./NFTErrors.sol";

//import "hardhat/console.sol";

string constant MARKETPLACE_CFG_VERSION = "1.2.3";

/**
 * @title MarketplaceConf
 * @dev A contract for managing non-fungible token marketplaces.
 */

contract MarketplaceConf is Initializable {
    /// @notice The address of the owner of the NFT marketplace.
    address payable private owner;
    /// @notice The address of the Marketplace.
    address payable private marketplaceAdr;
    /// @notice The percentage of royalties to be paid to the marketplace on each sale.
    uint16 private royaltiesMarketplace;
    /// @notice The listing fee for adding an NFT to the marketplace.
    uint256 private listingFees;
    /// @notice Struct for storing artist royalties and curator wallet & royalties
    struct WalletAndRoyalties {
        address curatorWalletAdr; // The wallet address of the curator
        uint16 curatorRoyalties; // The royalties as a percentage (1 % = 100)
        mapping(uint256 => uint16) nftArtistRoyalties; // Mapping of NFT IDs to corresponding royalties
    }

    /// @dev Mapping to store a wallet address and royalties for each address
    mapping(address => WalletAndRoyalties) public royaltiesInfo;

    /// @notice Constructor for creating a new NFT marketplace configuration.
    /// @dev This function sets the contract owner to the address that deployed the contract, and initializes the listing fees and royalties marketplace values.
    /// @param _listingFees The value of the listing fees to be charged for each NFT listed for sale.
    /// @param _royaltiesMarketplace The percentage of the sale price that the marketplace owner will receive as royalties.
    function initialize(uint256 _listingFees, uint16 _royaltiesMarketplace) public initializer {
        // Set the contract owner to the address that deployed the contract.
        owner = payable(msg.sender);
        // Initialize the listing fees and royalties marketplace values.
        listingFees = _listingFees;
        // Ensure that _royaltiesMarketplace are always under 100%
        require(_royaltiesMarketplace <= 10000, NFTErrors.ROYALTIES_RANGE_ERROR);
        royaltiesMarketplace = _royaltiesMarketplace;
    }

    /// @dev Event emitted when payement is received.
    /// @param sender The address that sent the payement.
    /// @param amount The amount of payement sent.
    event Received(address sender, uint256 amount);

    /// @notice Checks if themsg.sender is the marketplace owner or the NFT marketplace address.
    /// @dev This function is used to restrict access to certain functions to the marketplace owner or the NFT marketplace contract.
    function _onlyOwner() internal view {
        require(msg.sender == owner || msg.sender == marketplaceAdr, NFTErrors.ONLY_MP_OWNER);
    }

    /// @dev Modifier to check that the caller is the owner of the NFT marketplace.
    /// @notice Reverts if the caller is not the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @notice Sets the listing fees for adding an NFT to the marketplace.
    /// @param _listingFees The new listing fees.
    function setListingFees(uint256 _listingFees) public onlyOwner {
        listingFees = _listingFees;
    }

    /// @notice Gets the current listing fees for adding an NFT to the marketplace.
    /// @return The current listing fees.
    function getListingFees() public view returns (uint256) {
        return listingFees;
    }

    /// @notice Sets the percentage of royalties to be paid to the marketplace on each sale.
    /// @param _royaltiesMarketplace The new percentage of royalties for the marketplace.
    function setMarketplaceRoyalties(uint16 _royaltiesMarketplace) public onlyOwner {
        // Ensure that _royaltiesMarketplace are always under 100%
        require(_royaltiesMarketplace <= 10000, NFTErrors.ROYALTIES_RANGE_ERROR);
        royaltiesMarketplace = _royaltiesMarketplace;
    }

    /// @notice Gets the percentage of royalties currently set for the marketplace.
    /// @return The percentage of royalties for the marketplace.
    function getMarketplaceRoyalties() public view returns (uint16) {
        return royaltiesMarketplace;
    }

    /// @notice Sets the percentage of royalties to be paid to the artist for a specific NFT.
    /// @param _collectionAdr The address of the collection containing the NFT.
    /// @param _nftId The ID of the NFT.
    /// @param _artistRoyalties The new percentage of royalties for the artist.
    function setArtistRoyalties(address _collectionAdr, uint256 _nftId, uint16 _artistRoyalties) public onlyOwner {
        // Ensure that _artistRoyalties are always under 100%
        require(_artistRoyalties <= 10000, NFTErrors.ROYALTIES_RANGE_ERROR);
        royaltiesInfo[_collectionAdr].nftArtistRoyalties[_nftId] = _artistRoyalties;
    }

    /// @dev Returns the artist royalties for a specific NFT in a collection.
    /// @param _collectionAdr The address of the collection that contains the NFT.
    /// @param _nftId The ID of the NFT.
    function getArtistRoyalties(address _collectionAdr, uint256 _nftId) public view returns (uint16) {
        return royaltiesInfo[_collectionAdr].nftArtistRoyalties[_nftId];
    }

    /// @dev Sets the curator royalties for a collection.
    /// @param _collectionAdr The address of the collection for which to set the curator royalties.
    /// @param _curatorAdr Curator wallet address.
    /// @param _curatorRoyalties The percentage of royalties to be paid to the curator in basic points (1% = 100).
    function setCuratorRoyalties(
        address _collectionAdr,
        address _curatorAdr,
        uint16 _curatorRoyalties
    ) public onlyOwner {
        // Ensure that _curatorRoyalties are always under 100%
        require(_curatorRoyalties <= 10000, NFTErrors.ROYALTIES_RANGE_ERROR);
        royaltiesInfo[_collectionAdr].curatorWalletAdr = _curatorAdr;
        royaltiesInfo[_collectionAdr].curatorRoyalties = _curatorRoyalties;
    }

    /// @dev Returns the curator royalties for a specific collection.
    /// @param _collectionAdr The address of the collection for which to retrieve the curator royalties.
    function getCuratorRoyalties(address _collectionAdr) public view returns (address, uint256) {
        return (royaltiesInfo[_collectionAdr].curatorWalletAdr, royaltiesInfo[_collectionAdr].curatorRoyalties);
    }

    /// @dev Calculates and returns the shares for each party when an NFT is sold at a given price.
    /// @param _collectionAdr The address of the NFT collection.
    /// @param _nftId The ID of the NFT being sold.
    /// @param _price The sale price of the NFT.
    /// @return markeplaceShare The share of the sale price that goes to the marketplace.
    /// @return artistShare The share of the sale price that goes to the NFT artist.
    /// @return curatorAdr The wallet address of the curator
    /// @return curatorShare The share of the sale price that goes to the NFT collection curator.
    /// @return sellerShare The share of the sale price that goes to the NFT seller.
    function getAllShares(
        address _collectionAdr,
        uint256 _nftId,
        uint256 _price
    )
        public
        view
        onlyOwner
        returns (
            uint256 markeplaceShare,
            uint256 artistShare,
            address curatorAdr,
            uint256 curatorShare,
            uint256 sellerShare
        )
    {
        // Calculate the sum of all royalties.
        uint256 sumOfRoyalties = royaltiesMarketplace +
            royaltiesInfo[_collectionAdr].nftArtistRoyalties[_nftId] +
            royaltiesInfo[_collectionAdr].curatorRoyalties;
        // Ensure that the sum of royalties is less than 100%.
        require(sumOfRoyalties < 10000, NFTErrors.SUM_ROYALTIES_RANGE_ERROR);
        // Calculate the marketplace share.
        markeplaceShare = (_price * royaltiesMarketplace) / 10000;
        // Calculate the artist share.
        artistShare = (_price * royaltiesInfo[_collectionAdr].nftArtistRoyalties[_nftId]) / 10000;
        // Get the curator address
        curatorAdr = royaltiesInfo[_collectionAdr].curatorWalletAdr;
        // Calculate the curator share.
        curatorShare = (_price * royaltiesInfo[_collectionAdr].curatorRoyalties) / 10000;
        // Calculate the seller share.
        sellerShare = _price - markeplaceShare - artistShare - curatorShare;
    }

    /// @notice Returns the address of the marketplace owner.
    ///  @dev This function can be called by any user.
    ///  @return The address of the marketplace owner.
    function getOwner() public view returns (address) {
        return owner;
    }

    /// @notice Sets the address of the NFT marketplace.
    /// @dev This function can only be called by the marketplace owner.
    /// @param _marketplaceAdr The new address of the NFT marketplace.
    function setMarketplaceAdr(address payable _marketplaceAdr) public onlyOwner {
        marketplaceAdr = _marketplaceAdr;
    }

    /// @notice Returns the address of the marketplace smart contract.
    /// @dev This function can only be called by the marketplace owner.
    /// @return The address of the marketplace smart contract.
    function getMarketplaceAdr() public view onlyOwner returns (address) {
        return marketplaceAdr;
    }

    /// @dev returns the current version of the contract
    function getVersion() external pure returns (string memory) {
        return MARKETPLACE_CFG_VERSION;
    }

    /// @dev returns the current version of the contract
    function getVersion2() external pure returns (string memory) {
        return MARKETPLACE_CFG_VERSION;
    }

    /// @dev returns the current version of the contract
    function getVersion3() external pure returns (string memory) {
        return MARKETPLACE_CFG_VERSION;
    }

    /// @dev Fallback function that receives Ether and emits an event.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title NFTErrors
/// @dev A library that contains all of the possible error messages for the NFT marketplace.

library NFTErrors {
    string internal constant ONLY_MP_OWNER = "Only the Marketplace owner is allowed to perform this action";
    string internal constant ONLY_NFT_OWNER_SELL = "Only NFT owner can put it in sale";
    string internal constant ONLY_NFT_SELLER_CANCEL_SELL = "Only NFT seller can cancel the in sale";
    string internal constant ONLY_COLLECTION_CREATOR = "Only collection creator can mint NFT";
    string internal constant COLLECTION_NAME_NOT_EMPTY = "The collection name should not be an empty string";
    string internal constant COLLECTION_NOT_READY = "This collection does not exist yet";
    string internal constant NFT_URI_NOT_EMPTY = "The NFT uri should not be empty";
    string internal constant NFT_URI_NOT_UNIQUE = "The NFT uri already used in this collection";
    string internal constant NFT_PRICE_NOT_ZERO = "The sale price must be greater than 0";
    string internal constant NFT_NOT_EXIST = "NFT does not exist";
    string internal constant COLLECTION_NOT_EXIST = "Collection does not exist";
    string internal constant NFT_IS_IN_SALE = "The NFT is already in sale";
    string internal constant NFT_IS_IN_NOT_SALE = "The NFT is not in sale";
    string internal constant NFT_URI_USED = "Token URI already used";
    string internal constant LISTING_FEES_MISSING = "listing fees are missing";
    string internal constant BUY_PRICE_INCORRECT = "To complete the purchase please provide the correct price";
    string internal constant ROYALTIES_RANGE_ERROR = "Royalties percentage cannot be greater than 100%";
    string internal constant SUM_ROYALTIES_RANGE_ERROR = "Sum of all royalties cannot be greater than 100%";
    string internal constant MP_CONF_ERROR = "Marketplace configuration is net yet performed";
}