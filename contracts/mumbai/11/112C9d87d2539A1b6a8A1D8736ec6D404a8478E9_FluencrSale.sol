// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "./IFluencr.sol";

error FluencrAlreadyInitialised();

/**
 * @title Contract to be inherited to allow for listing and purchases through Fluencr platform
 * @author Fluencr
 * @notice More information at https://www.npmjs.com/package/@fluencr/fluencr-protocol
 */

abstract contract Fluencr is IFluencr {
    address internal affiliateContract;
    bool internal __fluncr_initialized;

    /**
     * @dev Sets the value for {affiliateContract}.
     */
    function _init(address _affiliateContract) internal {
        if (__fluncr_initialized) {
            revert FluencrAlreadyInitialised();
        }
        affiliateContract = _affiliateContract;
        __fluncr_initialized = true;
    }

    // -------------- MODIFIERS --------------

    modifier onlyAffiliate() {
        if (msg.sender != affiliateContract) {
            revert NotAffiliate();
        }
        _;
    }

    // -------------- PUBLIC FUNCTIONS --------------

    /**
     * @dev Do not override this method. Enforcing correct modifier.
     */

    function sell(address buyer, uint256 id) external override onlyAffiliate {
        _sell(buyer, id);
    }

    // -------------- INTERNAL FUNCTIONS --------------

    /**
     * @dev Can be overriden to implement functionality to allow for updates on affiliate contract address.
     * @param _affiliateContract - New address for the affiliate contract. Provided by Fluencr.
     */

    function _setAffiliateContract(address _affiliateContract) internal {
        affiliateContract = _affiliateContract;
    }

    /**
     * @dev Must be overriden to allow for purchases of NFTs.
     * Supports both fresh mints and secondary sales.
     * The buyer must receive the associated token.
     * @param buyer - address of buyer
     * @param id - id for the associated NFT listed for sale. See docs at: https://www.npmjs.com/package/@fluencr/fluencr-protocol for more information.
     */

    function _sell(address buyer, uint256 id) internal virtual;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

error NotAffiliate();
error NotFluencrDeployer();

/**
 * @title Interface for Fluencr protocol
 * @author Fluencr
 * @notice More information at https://www.npmjs.com/package/@fluencr/fluencr-protocol
 */

interface IFluencr {
    /**
     *
     * @param id - correlationId for the product
     * @param url - url for the associated token
     * @param price - price for the associated token
     */
    struct Product {
        uint256 id;
        string url;
        uint256 price;
    }

    /**
     * @dev If id is not used just return product for the only existing product
     */
    function getProduct(uint256 id) external view returns (Product memory);

    function sell(address buyer, uint256 id) external;

    /**
     * @notice
     * Return url for metadata with corresponding language tag (https://en.wikipedia.org/wiki/IETF_language_tag).
     * If language is not supported return default url.
     * @param language - language tag (https://en.wikipedia.org/wiki/IETF_language_tag)
     */
    function listProducts(
        string memory language
    ) external view returns (Product[] memory products);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

pragma solidity ^0.8.0;


// @title Watered down version of IAssetManager, to be used for Gravity Grade
interface ITrustedMintable {

    error TM__NotTrusted(address _caller);
    /**
    * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens. MUST be ignored on ERC-721
     * @param _amount Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens MUST be ignored on ERC-721
     * @param _amounts Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error NonExistentProduct();
error SaleLimitExceeded();
error ProductPriceInvalid();
error InvalidArgumetSize();

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@fluencr/fluencr-protocol/contracts/Fluencr.sol";
import "../interfaces/ITrustedMintable.sol";

/**
 * @title Fluencr Sale
 * @notice This contract is for managing PlanetIX asset sales on Fluencr
 */
contract FluencrSale is OwnableUpgradeable, PausableUpgradeable, Fluencr {
    /**
     * @param contractAddress - contract address for the product
     * @param tokenId - token id for the product
     * @param amount - amount of tokens minted for the product
     */    
    struct ContractInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }

    event ProductCreated(uint256 indexed id, string url, uint256 price);
    event ProductSold(uint256 indexed id, address buyer, address contractAddress, uint256 tokenId, uint256 amount);
    event LimitSet(uint256 productId, uint256 limit);
    event AlternativeLanguageSet(uint256 productId, string language, string uri);

    uint public totalProducts;
    mapping(uint256 => Product) public products;

    // product id => amount of tokens minted per product bought
    mapping(uint256 => ContractInfo) public contractInfos;
    mapping(uint256 => uint256) public sales;
    mapping(uint256 => uint256) public saleLimits;
    mapping(uint256 => mapping(string => string)) public alternativeLanguageUris;
    
    /**
     * @notice Initializer for this contract
     * @param _fluencrAddress Fluencr contract address
     */
    function initialize(address _fluencrAddress) public initializer {
        __Ownable_init();
        _pause();
        Fluencr._init(_fluencrAddress);
    }

    /**
     * @notice Create new product sale
     * @param _url The asset metadata url
     * @param _price Product price
     * @param _contractAddress Product contract address
     * @param _tokenId Product token id
     * @param _amount The amount of tokens minted on each sale
     */
    function createProduct(
        string memory _url,
        uint256 _price,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        if (_price == 0) {
            revert ProductPriceInvalid();
        }
        unchecked {
            ++totalProducts;
        }
        Product memory product = Product(totalProducts, _url, _price);
        products[totalProducts] = product;
        ContractInfo memory contractInfo = ContractInfo(_contractAddress, _tokenId, _amount);
        contractInfos[totalProducts] = contractInfo;

        emit ProductCreated(totalProducts, _url, _price);
    }

    /**
     * @notice Change product sale
     * @param _productId Product contract address
     * @param _url The asset metadata url
     * @param _price Product price
     */
    function changeProduct(
        uint256 _productId,
        string memory _url,
        uint256 _price,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        if (_productId > totalProducts) {
            revert NonExistentProduct();
        }
        if (_price == 0) {
            revert ProductPriceInvalid();
        }
        Product storage product = products[_productId];
        product.url = _url;
        product.price = _price;
        ContractInfo storage contractInfo = contractInfos[_productId];
        contractInfo.contractAddress = _contractAddress;
        contractInfo.tokenId = _tokenId;
        contractInfo.amount = _amount;
    }

    /**
     * @notice Sets limits for the amount of tokens that can be sold
     * @param _productId Product id
     * @param _languages Corresponding language tag (https://en.wikipedia.org/wiki/IETF_language_tag)
     * @param _uris The uri in alternative language
     */
    function setAlternativeLanguageUris(uint256 _productId, string[] calldata _languages, string[] calldata _uris) external onlyOwner {
        if (_languages.length != _uris.length) {
            revert InvalidArgumetSize();
        }
        for (uint256 i; i < _languages.length; i += 1) {
            alternativeLanguageUris[_productId][_languages[i]] = _uris[i];
            emit AlternativeLanguageSet(_productId, _languages[i], _uris[i]);
        }
    }

    /**
     * @notice Sets limits for the amount of tokens that can be sold
     * @param _productId Product id
     * @param _limit The maximum amount of tokens that could be minted
     */
    function setSaleLimits(uint256 _productId, uint256 _limit) external onlyOwner {
        saleLimits[_productId] = _limit;

        emit LimitSet(_productId, _limit);
    }

    /**
     * @notice Used to flip between paused and unpaused
     */
    function toggleStatus() external onlyOwner {
        if(paused()) _unpause();
        else _pause();
    }

    /// @inheritdoc IFluencr
    function getProduct(uint256 _productId) external view override(IFluencr) returns (Product memory) {
        Product memory product = products[_productId];
        if (_productId > totalProducts) {
            revert NonExistentProduct();
        }
        return product;
    }

    /// @inheritdoc Fluencr
    function _sell(address buyer, uint256 id) internal override(Fluencr) whenNotPaused {
        uint256 price = products[id].price;
        if (price == 0) {
            revert NonExistentProduct();
        }

        ContractInfo memory contractInfo = contractInfos[id];

        if (saleLimits[id] < sales[id] + contractInfo.amount) {
            revert SaleLimitExceeded();
        }

        sales[id] += 1;
        ITrustedMintable(contractInfo.contractAddress).trustedMint(buyer, contractInfo.tokenId, contractInfo.amount);

        emit ProductSold(id, buyer, contractInfo.contractAddress, contractInfo.tokenId, contractInfo.amount);
    }

    /// @inheritdoc IFluencr
    function listProducts(string memory language) external view override(IFluencr) returns (Product[] memory) {
        Product[] memory productList = new Product[](totalProducts);
        for (uint256 i; i < totalProducts; i++) {
            productList[i] = products[i+1];
            if (keccak256(abi.encodePacked(alternativeLanguageUris[i+1][language])) != keccak256(abi.encodePacked(""))) {
                productList[i].url = alternativeLanguageUris[i+1][language];
            }
        }
        return productList;
    }
}