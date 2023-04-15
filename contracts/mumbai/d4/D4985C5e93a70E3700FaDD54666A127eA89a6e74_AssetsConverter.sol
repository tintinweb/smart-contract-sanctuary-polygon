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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetManager.sol";


contract AssetsConverter is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    //Errors
    error AssetsConverter__NotAdmin(address);
    error AssetsConverter__InvalidRecipes();
    error AssetsConverter__InvalidAmount();
    error AssetsConverter__InvalidRecipeId();
    error AssetsConverter__MaximumConversionsExceeded();
    error AssetsConverter__TotalConversionSupplyExceeded();
    error AssetsConverter__RecipePaused();

    //Events
    event AssetsConverter__NewRecipe(uint[] fromToken, uint[] toToken, uint[] prices, uint id, uint maxConversionsPerWallet, uint maxTotalConversions);
    event AssetsConverter__ConversionComplete(uint recipeId, uint amount);

    struct Recipe {
        uint[] fromToken; //array of uint array. [7,8,9]
        uint[] toToken; // one of each token to get from conversion [1,2]
        uint[] prices; // price of from tokens[50,30,1]
        uint id; // id of recipe.
        uint maxConversionsPerWallet; // if 0 -> infinite
        uint maxTotalConversions; // if 0 -> infinite
        bool paused;
    }

    //Storage
    mapping(uint => mapping(address => uint)) userMintSupply; //recipe id -> user -> amounts of mints.
    mapping(uint => uint) recipeIdToConversions;
    mapping(address => bool) public admins;
    mapping(uint => Recipe) public recipes;
    IAssetManager public assetManager;
    uint public nonce;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        setAdmin(msg.sender, true);
    }

    //Admin functionality
    /** @notice Only admins can use this function.
     */
    modifier onlyAdmins {
        if (!admins[msg.sender]) revert AssetsConverter__NotAdmin(msg.sender);
        _;
    }

    /** @notice Owner can set and remove admins.
     *  @param _admin address of admin.
     *  @param _shouldBeAdmin true to add admin false to remove admin.
     */
    function setAdmin(address _admin, bool _shouldBeAdmin) public onlyOwner {
        admins[_admin] = _shouldBeAdmin;
    }

    /** @notice change the implementation address for iAssetManager.
     *  @param _assetManager implementation address
     */
    function setAssetManager(address _assetManager) external onlyAdmins {
        assetManager = IAssetManager(_assetManager);
    }

    /** @notice delete an active recipe.
     *  @param _recipeId recipe to be deleted.
     */
    function deleteAssetConversionRecipe(uint _recipeId) external onlyAdmins {
        Recipe memory recipe;
        recipes[_recipeId] = recipe;
    }

    /** @notice Pause and unpause recipe from use.
     *  @param _recipeId id of recipe to be paused/unpause.
     *  @param _paused true for paused, false to unpause.
     */
    function setRecipePausedState(uint _recipeId, bool _paused) external onlyAdmins {
        recipes[_recipeId].paused = _paused;
    }

    /** @notice creates new asset conversion recipes.
     *  @param _fromToken token that will be burned for _toToken.
     *  @param _toToken tokens that will be minted to user on conversion.
     *  @param _prices cost of x amount of _fromToken
     */
    function createAssetConversionRecipe(uint[] memory _fromToken, uint[] memory _toToken, uint[] memory _prices, uint _maxConversionsPerWallet, uint _maxTotalConversions) external onlyAdmins {
        if (_fromToken.length != _prices.length) revert AssetsConverter__InvalidRecipes();
        for (uint i; i < _prices.length; i++) {
            if (_prices[i] < 1) revert AssetsConverter__InvalidRecipes();
        }
        nonce++;
        Recipe memory recipe = Recipe({
        fromToken : _fromToken,
        toToken : _toToken,
        prices : _prices,
        id : nonce,
        maxConversionsPerWallet : _maxConversionsPerWallet,
        maxTotalConversions : _maxTotalConversions,
        paused : false
        });
        recipes[nonce] = recipe;
        emit AssetsConverter__NewRecipe(_fromToken, _toToken, _prices, nonce, _maxConversionsPerWallet, _maxTotalConversions);
    }

    //User functionality
    /** @notice Convert assets with specified recipe id.
     *  @param _recipeId recipe to used.
     *  @param _amount desired amount of uses of recipe.
     */
    function convertAsset(uint _recipeId, uint _amount) nonReentrant external {
        Recipe memory recipe = recipes[_recipeId];
        if (_amount < 1) revert AssetsConverter__InvalidAmount();
        if (recipe.prices.length < 1) revert AssetsConverter__InvalidRecipeId();
        if (recipe.paused) revert AssetsConverter__RecipePaused();

        if (recipe.maxConversionsPerWallet != 0) {
            uint userPrevConversions = userMintSupply[_recipeId][msg.sender];
            if (userPrevConversions + _amount > recipe.maxConversionsPerWallet) revert AssetsConverter__MaximumConversionsExceeded();
            userMintSupply[_recipeId][msg.sender] += _amount;
        }
        if (recipe.maxTotalConversions != 0) {
            if (_amount + recipeIdToConversions[_recipeId] > recipe.maxTotalConversions) revert AssetsConverter__TotalConversionSupplyExceeded();
            recipeIdToConversions[_recipeId] += _amount;
        }

        uint fromTokenLength = recipe.fromToken.length;
        uint[] memory tempPrices = new uint[](fromTokenLength);
        for (uint i; i < fromTokenLength; i++) {
            tempPrices[i] = (recipe.prices[i] * _amount);
        }
        assetManager.trustedBatchBurn(msg.sender, recipe.fromToken, tempPrices);
        for (uint i; i < recipe.toToken.length; i++) {
            assetManager.trustedMint(msg.sender, recipe.toToken[i], _amount);
        }
        emit AssetsConverter__ConversionComplete(_recipeId, _amount);
    }

    //View

    /** @notice get tokens and prices for recipe.
     *  @param _recipeId recipe to get info for.
     */
    function getRecipeFormula(uint _recipeId) view external returns (uint[] memory fromToken, uint[] memory toToken, uint[] memory prices) {
        fromToken = recipes[_recipeId].fromToken;
        toToken = recipes[_recipeId].toToken;
        prices = recipes[_recipeId].prices;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract responsible for minting rewards and burning payment in the context of the mission control
interface IAssetManager {
    enum AssetIds {
        UNUSED_0, // 0, unused
        GoldBadge, //1
        SilverBadge, //2
        BronzeBadge, // 3
        GenesisDrone, //4
        PiercerDrone, // 5
        YSpaceShare, //6
        Waste, //7
        AstroCredit, // 8
        Blueprint, // 9
        BioModOutlier, // 10
        BioModCommon, //11
        BioModUncommon, // 12
        BioModRare, // 13
        BioModLegendary, // 14
        LootCrate, // 15
        TicketRegular, // 16
        TicketPremium, //17
        TicketGold, // 18
        FacilityOutlier, // 19
        FacilityCommon, // 20
        FacilityUncommon, // 21
        FacilityRare, //22
        FacilityLegendary, // 23,
        Energy, // 24
        LuckyCatShare, // 25,
        GravityGradeShare, // 26
        NetEmpireShare, //27
        NewLandsShare, // 28
        HaveBlueShare, //29
        GlobalWasteSystemsShare, // 30
        EternaLabShare // 31
    }

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens
     * @param _amount Number of tokens to mint
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens
     * @param _amounts Number of tokens to mint
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenId Id of to-be-burnt tokens
     * @param _amount Number of tokens to burn
     */
    function trustedBurn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenIds Ids of to-be-burnt tokens
     * @param _amounts Number of tokens to burn
     */
    function trustedBatchBurn(
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}