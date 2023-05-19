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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../mission_control/IAssetManager.sol";
import "../util/IGenericBurnV2.sol";
import "../util/IConditionalProvider.sol";
import "../interfaces/ITrustedMintable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

///@notice Interface used for interacting with the VRF oracle
interface IVRFConsumerBaseV2 {
    /**
     * @notice Requests a random number from the vrf oracle
     * @param draws The number of draws requested
     * @return requestID the id of the random number request
     */
    function getRandomNumber(uint32 draws) external returns (uint256 requestID);
}

/**
 * @title Gravity Grade Generic Burn
 * @author Jourdan
 * @notice This contract manages burning and custom rewards for any Gravity Grade token
 */
contract GenericBurnV2 is IGenericBurnV2, OwnableUpgradeable {
    event PIXAssetsSet(address _address);
    event AvatarClaimed(address _address, address _pack, uint256 _tokenId, uint256 _amount);

    /*------------------- STATE VARIABLES -------------------*/

    /// @notice All category ids belonging to a tokenId, (tokenId => categoryIds)
    mapping(address => mapping(uint256 => uint256[])) public s_tokenCategoryIds;
    /// @notice Total categories belonging to a tokenId, (tokenId => total categories)
    mapping(address => mapping(uint256 => uint256)) private s_tokenTotalCategories;
    /// @notice All categories belonging to a tokenId, (tokenId => ContentCategory[])
    mapping(address => mapping(uint256 => ContentCategory[])) public s_tokenCategories;
    /// @notice Shows whether a category is active, (tokenId => categoryId => bool)
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) private s_tokenCategoryActive;
    /// @notice Shows the index where a category can be found, (tokenId => categoryId => index)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private s_tokenCategoryIndex;
    /// @notice Contract with eligibility requirements for category, (tokenId => categoryId => eligibility)
    mapping(address => mapping(uint256 => mapping(uint256 => IConditionalProvider))) public s_tokenEligibility;
    /// @notice Max number of draws any category can have for a particular token (tokenId => maxDraws)
    mapping(address => mapping(uint256 => uint32)) maxDrawsPerCategory;

    /// @notice Oracle being used for randomness
    IVRFConsumerBaseV2 private s_randNumOracle;

    mapping(uint256 => address) s_requestToken;
    /// @notice TokenId for a VRF request
    mapping(uint256 => uint256) s_requestTokenId;
    /// @notice User for a VRF request
    mapping(uint256 => address) private s_requestUser;
    /// @notice Ids of categories a user didn't qualify for on a VRF request
    mapping(uint256 => uint256[]) private s_requestExcludedIds;
    /// @notice Number of openings for a VRF request
    mapping(uint256 => uint256) private s_requestOpenings;
    /// @notice Number of random words needed
    mapping(uint256 => uint256) private s_requestRandWords;

    /// @notice TokenIds which are whitelisted for burning
    mapping(address => mapping(uint256 => bool)) private s_whitelistedTokens;
    /// @notice Gravity Grade Contract
    address private pixAssets;
    /// @notice Governance
    address private s_governance;

    mapping(address => mapping(uint256 => mapping(uint256 => uint256[]))) largeContentWeights;
    mapping(address => uint256) userAvatarSeed;
    mapping(address => RequestInputs) userVRFRequestParams;
    address avatarPack;

    mapping(address => mapping(uint256 => uint256)) tokenBurnLimit;
    mapping(address => mapping(uint256 => GuaranteedReward[])) public s_guaranteedRewards; // tokenId => guaranteed rewards

    uint256 constant AVATAR_PACK_ID = 32;

    /*------------------- MODIFIERS -------------------*/

    /// @notice Makes sure function is called only by governance
    modifier onlyGov() {
        if (msg.sender != owner() && msg.sender != s_governance) revert GB__NotGov(msg.sender);
        _;
    }

    /// @notice Makes sure function is called only by vrf oracle
    modifier onlyOracle() {
        if (msg.sender != address(s_randNumOracle)) revert GB__NotOracle();
        _;
    }

    /*------------------- INITIALIZER -------------------*/

    ///@notice Initializer
    function initialize() public initializer {
        __Ownable_init();
    }

    /*------------------- ADMIN - ONLY FUNCTIONS -------------------*/

    /// @inheritdoc IGenericBurnV2
    function whitelistToken(address _token, uint256 _tokenId, bool _isWhitelisted) external onlyGov {
        s_whitelistedTokens[_token][_tokenId] = _isWhitelisted;
        emit TokenWhitelisted(_tokenId, _isWhitelisted);
    }

    /**
     * @notice Sets VRF consumer to be used
     * @param _vrfOracle The address of the oracle
     */
    function setVRFOracle(address _vrfOracle) external onlyOwner {
        if (_vrfOracle == address(0)) revert GB__ZeroAddress();
        s_randNumOracle = IVRFConsumerBaseV2(_vrfOracle);
    }

    function setPixAssets(address _pixAssets) external onlyGov {
        pixAssets = _pixAssets;
        emit PIXAssetsSet(_pixAssets);
    }

    function setAvatarPack(address _avatarPack) external onlyGov {
        avatarPack = _avatarPack;
    }

    /**
     * @notice Sets governace
     * @param _governance The address of the oracle
     */
    function setGovernance(address _governance) external onlyGov {
        s_governance = _governance;
    }

    function setTokenBurnLimit(address _token, uint256 _tokenId, uint256 _limit) external onlyGov {
        tokenBurnLimit[_token][_tokenId] = _limit;
    }

    /// @inheritdoc IGenericBurnV2
    function setContentEligibility(
        address _token,
        uint256 _tokenId,
        uint256 _categoryId,
        address _conditionalProvider
    ) external onlyGov {
        if (
            !ERC165CheckerUpgradeable.supportsInterface(_conditionalProvider, type(IERC165Upgradeable).interfaceId) ||
            !ERC165CheckerUpgradeable.supportsInterface(_conditionalProvider, type(IConditionalProvider).interfaceId)
        ) {
            revert GB__NotConditionalProvider(_conditionalProvider);
        }
        if (!s_tokenCategoryActive[_token][_tokenId][_categoryId]) revert GB__InvalidCategoryId(_categoryId);
        s_tokenEligibility[_token][_tokenId][_categoryId] = IConditionalProvider(_conditionalProvider);
        emit CategoryEligibilitySet(_tokenId, _categoryId, _conditionalProvider);
    }

    /// @inheritdoc IGenericBurnV2
    function createContentCategory(address _token, uint256 _tokenId) external onlyGov returns (uint256 _categoryId) {
        unchecked {
            _categoryId = ++s_tokenTotalCategories[_token][_tokenId];
        }

        s_tokenCategories[_token][_tokenId].push(
            ContentCategory({
                id: _categoryId,
                contentAmountsTotalWeight: 0,
                contentsTotalWeight: 0,
                contentAmounts: new uint256[](0),
                contentAmountsWeights: new uint256[](0),
                tokenAmounts: new uint256[](0),
                tokenWeights: new uint256[](0),
                tokens: new address[](0),
                tokenIds: new uint256[](0)
            })
        );
        s_tokenCategoryIds[_token][_tokenId].push(_categoryId);
        s_tokenCategoryIndex[_token][_tokenId][_categoryId] = s_tokenCategories[_token][_tokenId].length - 1;
        s_tokenCategoryActive[_token][_tokenId][_categoryId] = true;

        emit CategoryCreated(_tokenId, _categoryId);
    }

    /// @inheritdoc IGenericBurnV2
    function deleteContentCategory(address _token, uint256 _tokenId, uint256 _categoryId) external onlyGov {
        if (!s_tokenCategoryActive[_token][_tokenId][_categoryId]) revert GB__InvalidCategoryId(_categoryId);

        uint256 index = s_tokenCategoryIndex[_token][_tokenId][_categoryId];
        for (uint256 i = index; i < s_tokenCategories[_token][_tokenId].length - 1; ) {
            s_tokenCategories[_token][_tokenId][i] = s_tokenCategories[_token][_tokenId][i + 1];
            s_tokenCategoryIds[_token][_tokenId][i] = s_tokenCategoryIds[_token][_tokenId][i + 1];
            s_tokenCategoryIndex[_token][_tokenId][s_tokenCategories[_token][_tokenId][i].id] = i;

            unchecked {
                ++i;
            }
        }
        s_tokenCategoryActive[_token][_tokenId][_categoryId] = false;
        s_tokenCategoryIds[_token][_tokenId].pop();
        s_tokenCategories[_token][_tokenId].pop();

        emit CategoryDeleted(_tokenId, _categoryId);
    }

    /// @inheritdoc IGenericBurnV2
    function setContentAmounts(
        address _token,
        uint256 _tokenId,
        uint256 _categoryId,
        uint256[] calldata _amounts,
        uint256[] calldata _weights
    ) external onlyGov {
        if (!s_tokenCategoryActive[_token][_tokenId][_categoryId]) revert GB__InvalidCategoryId(_categoryId);
        if (_amounts.length != _weights.length) revert GB__ArraysNotSameLength();

        uint256 sum;
        for (uint256 i = 0; i < _weights.length; i++) {
            if (_weights[i] == 0) revert GB__ZeroWeight();
            if (_amounts[i] > maxDrawsPerCategory[_token][_tokenId]) revert GB__MaxDrawsExceeded(_amounts[i]);
            sum += _weights[i];
        }

        uint256 index = s_tokenCategoryIndex[_token][_tokenId][_categoryId];

        s_tokenCategories[_token][_tokenId][index].contentAmounts = _amounts;
        s_tokenCategories[_token][_tokenId][index].contentAmountsWeights = _arrayToCumulative(_weights);
        s_tokenCategories[_token][_tokenId][index].contentAmountsTotalWeight = sum;

        emit ContentAmountsUpdated(_tokenId, _categoryId, _amounts, _weights);
    }

    /// @inheritdoc IGenericBurnV2
    function setContents(SetContentInputs calldata args) external onlyGov {
        if (!s_tokenCategoryActive[args.token][args.tokenId][args.categoryId])
            revert GB__InvalidCategoryId(args.categoryId);
        if (
            args.amounts.length != args.weights.length ||
            args.amounts.length != args.tokens.length ||
            args.amounts.length != args.tokenIds.length
        ) revert GB__ArraysNotSameLength();

        uint256 sum;
        for (uint256 i = 0; i < args.weights.length; i++) {
            if (args.weights[i] == 0) revert GB__ZeroWeight();
            if (args.amounts[i] == 0) revert GB_ZeroAmount();

            sum += args.weights[i];
        }

        uint256 index = s_tokenCategoryIndex[args.token][args.tokenId][args.categoryId];

        s_tokenCategories[args.token][args.tokenId][index].tokenAmounts = args.amounts;
        s_tokenCategories[args.token][args.tokenId][index].tokenWeights = _arrayToCumulative(args.weights);
        s_tokenCategories[args.token][args.tokenId][index].contentsTotalWeight = sum;
        s_tokenCategories[args.token][args.tokenId][index].tokens = args.tokens;
        s_tokenCategories[args.token][args.tokenId][index].tokenIds = args.tokenIds;

        emit ContentsUpdated(args.tokenId, args.categoryId, args.tokens, args.tokenIds, args.amounts, args.weights);
    }

    function setContentLarge(
        address _token,
        uint256 _tokenId,
        uint256 _categoryId,
        address _tokens,
        uint256 _tokenIds,
        uint256 _amounts,
        uint256 _weights
    ) external onlyGov {
        if (!s_tokenCategoryActive[_token][_tokenId][_categoryId]) revert GB__InvalidCategoryId(_categoryId);

        if (_weights == 0) revert GB__ZeroWeight();
        if (_amounts == 0) revert GB_ZeroAmount();

        uint256 index = s_tokenCategoryIndex[_token][_tokenId][_categoryId];

        largeContentWeights[_token][_tokenId][index].push(_weights);

        s_tokenCategories[_token][_tokenId][index].tokens.push(_tokens);
        s_tokenCategories[_token][_tokenId][index].tokenIds.push(_tokenIds);
        s_tokenCategories[_token][_tokenId][index].tokenAmounts.push(_amounts);

        // emit ContentsUpdated(_tokenId, _categoryId, _tokens, _tokenIds, _amounts, _weights);
    }

    function setContentLargeWeights(address _token, uint256 _tokenId, uint256 _categoryId) external onlyGov {
        if (!s_tokenCategoryActive[_token][_tokenId][_categoryId]) revert GB__InvalidCategoryId(_categoryId);
        uint256 index = s_tokenCategoryIndex[_token][_tokenId][_categoryId];

        uint256 sum;
        for (uint256 i = 0; i < largeContentWeights[_token][_tokenId][index].length; i++) {
            sum += largeContentWeights[_token][_tokenId][index][i];
        }

        s_tokenCategories[_token][_tokenId][index].tokenWeights = _arrayToCumulative(
            largeContentWeights[_token][_tokenId][index]
        );
        s_tokenCategories[_token][_tokenId][index].contentsTotalWeight = sum;
    }

    /**
     * @notice Function for setting the maximum # of draws any category can have
     * @param _maxDraws The max number of draws any category can have
     */
    function setMaxDraws(address _token, uint256 _tokenId, uint32 _maxDraws) external onlyGov {
        maxDrawsPerCategory[_token][_tokenId] = _maxDraws;
    }

    function setGuaranteedRewards(
        address _token,
        uint256 _tokenId,
        GuaranteedReward[] memory _rewards
    ) external onlyGov {
        for (uint256 i; i < _rewards.length; i++) {
            s_guaranteedRewards[_token][_tokenId].push(_rewards[i]);
        }
        emit GuaranteedRewardSet(_tokenId, _rewards);
    }

    function deleteGuaranteedRewards(address _token, uint256 _tokenId, uint256 _position) external onlyGov {
        uint256 last = s_guaranteedRewards[_token][_tokenId].length - 1;
        s_guaranteedRewards[_token][_tokenId][_position] = s_guaranteedRewards[_token][_tokenId][last];
        s_guaranteedRewards[_token][_tokenId].pop();
    }

    function deleteAllGuaranteedRewards(address _token, uint256 _tokenId) external onlyGov {
        delete s_guaranteedRewards[_token][_tokenId];
    }

    /*------------------- END - USER FUNCTIONS -------------------*/

    /// @inheritdoc IGenericBurnV2
    function burnPack(address _token, uint256 _tokenId, uint32 _amount, bool _optInConditionals) external {
        require(_amount <= tokenBurnLimit[_token][_tokenId], "PIX BURN: BURN_LIMIT_EXCEEDED");

        if (_tokenId == AVATAR_PACK_ID)
            require(userAvatarSeed[msg.sender] == 0, "PIX_BURN: USER HAS AN AVATAR TO CLAIM");

        if (!s_whitelistedTokens[_token][_tokenId]) revert GB__TokenNotWhitelisted(_tokenId);

        _burnTokens(_token, _tokenId, _amount);

        if (s_tokenCategories[_token][_tokenId].length != 0) {
            uint256[] memory tokenCategoryIds = s_tokenCategoryIds[_token][_tokenId];
            uint256[] memory excludedIds = new uint256[](tokenCategoryIds.length);
            uint256 numRequests;

            for (uint256 i; i < tokenCategoryIds.length; i++) {
                if (address(s_tokenEligibility[_token][_tokenId][tokenCategoryIds[i]]) != address(0)) {
                    IConditionalProvider conditionalProvider = s_tokenEligibility[_token][_tokenId][
                        tokenCategoryIds[i]
                    ];
                    if (!_optInConditionals || !conditionalProvider.isEligible(msg.sender)) {
                        excludedIds[numRequests] = tokenCategoryIds[i];
                        unchecked {
                            ++numRequests;
                        }
                    }
                }
            }
            uint32 randWordsRequest = _amount > maxDrawsPerCategory[_token][_tokenId]
                ? _amount
                : maxDrawsPerCategory[_token][_tokenId];
            uint256 requestId = s_randNumOracle.getRandomNumber(1);
            s_requestUser[requestId] = msg.sender;
            s_requestToken[requestId] = _token;
            s_requestTokenId[requestId] = _tokenId;
            s_requestOpenings[requestId] = _amount;
            s_requestRandWords[requestId] = randWordsRequest;

            for (uint256 i; i < excludedIds.length; i++) {
                if (excludedIds[i] != 0) {
                    s_requestExcludedIds[requestId].push(excludedIds[i]);
                }
            }
        }

        GuaranteedReward[] memory rewards = s_guaranteedRewards[_token][_tokenId];
        for (uint256 i; i < rewards.length; i++) {
            ITrustedMintable(rewards[i].token).trustedMint(msg.sender, rewards[i].tokenId, rewards[i].tokenAmount);
            emit RewardGranted(rewards[i].token, rewards[i].tokenId, rewards[i].tokenAmount);
        }

        emit PackOpened(msg.sender, _token, _tokenId, _amount);
    }

    /// @inheritdoc IGenericBurnV2
    function getContentCategories(
        address _token,
        uint256 _tokenId
    ) external view returns (ContentCategory[] memory _categories) {
        _categories = s_tokenCategories[_token][_tokenId];
    }

    function getGuaranteedRewards(
        address _token,
        uint256 _tokenId
    ) external view returns (GuaranteedReward[] memory _rewards) {
        _rewards = s_guaranteedRewards[_token][_tokenId];
    }

    function getAvatarClaimStatus(address _user) external view returns (uint256) {
        return userAvatarSeed[_user];
    }

    function claimAvatar() external {
        require(userAvatarSeed[msg.sender] != 0, "PIX_BURN: USER HAS NO RANDOM NUMBER");
        uint256 randomSeed = userAvatarSeed[msg.sender];
        userAvatarSeed[msg.sender] = 0;

        RequestInputs memory req = userVRFRequestParams[msg.sender];
        delete userVRFRequestParams[msg.sender];

        uint256[] memory expandedValues = new uint256[](req.randWordsCount);
        for (uint256 i = 0; i < req.randWordsCount; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomSeed, i)));
        }

        uint256 contentAmountsTotalWeight = s_tokenCategories[pixAssets][req.tokenId][0].contentAmountsTotalWeight;
        uint256 contentsTotalWeight = s_tokenCategories[pixAssets][req.tokenId][0].contentsTotalWeight;

        uint256[] memory contentAmounts = s_tokenCategories[pixAssets][req.tokenId][0].contentAmounts;
        uint256[] memory contentAmountsWeights = s_tokenCategories[pixAssets][req.tokenId][0].contentAmountsWeights;
        uint256[] memory tokenWeights = s_tokenCategories[pixAssets][req.tokenId][0].tokenWeights;
        uint256[] memory tokenIds = s_tokenCategories[pixAssets][req.tokenId][0].tokenIds;

        for (uint256 j; j < req.openings; j++) {
            uint256 target = expandedValues[j] % contentAmountsTotalWeight;
            uint256 index = _binarySearch(contentAmountsWeights, target);
            uint256 draws = contentAmounts[index];
            for (uint256 k; k < draws; k++) {
                uint256 targetContent = expandedValues[k] % contentsTotalWeight;
                uint256 indexContent = _binarySearch(tokenWeights, targetContent);
                ITrustedMintable(avatarPack).trustedMint(msg.sender, tokenIds[indexContent], 1);
                emit AvatarClaimed(msg.sender, avatarPack, tokenIds[indexContent], 1);
            }
        }
    }

    /*------------------- INTERNAL FUNCTIONS -------------------*/

    /**
     * @notice Function for satisfying randomness requests from burnPack
     * @param requestId The particular request being serviced
     * @param randomWords Array of the random numbers requested
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external onlyOracle {
        RequestInputs memory req = RequestInputs({
            user: s_requestUser[requestId],
            token: s_requestToken[requestId],
            tokenId: s_requestTokenId[requestId],
            openings: s_requestOpenings[requestId],
            randWordsCount: s_requestRandWords[requestId],
            excludedIds: s_requestExcludedIds[requestId]
        });

        if (s_requestTokenId[requestId] == AVATAR_PACK_ID) {
            userAvatarSeed[s_requestUser[requestId]] = randomWords[0];
            userVRFRequestParams[s_requestUser[requestId]] = req;
            delete s_requestUser[requestId];
            delete s_requestTokenId[requestId];
            delete s_requestOpenings[requestId];
            delete s_requestRandWords[requestId];
            delete s_requestExcludedIds[requestId];
            return;
        }

        ContentCategory[] memory categories = s_tokenCategories[req.token][req.tokenId];
        uint256 expandedValue;
        for (uint256 j; j < req.openings; j++) {
            for (uint256 i; i < categories.length; i++) {
                bool categoryExcluded;
                for (uint256 z; z < req.excludedIds.length; z++) {
                    if (categories[i].id == req.excludedIds[z]) {
                        categoryExcluded = true;
                        break;
                    }
                }
                if (categoryExcluded) continue;
                expandedValue = uint256(keccak256(abi.encode(randomWords[0], i, j)));
                uint256 target = expandedValue % categories[i].contentAmountsTotalWeight;
                uint256 index = _binarySearch(categories[i].contentAmountsWeights, target);
                uint256 draws = categories[i].contentAmounts[index];
                for (uint256 k; k < draws; k++) {
                    expandedValue = uint256(keccak256(abi.encode(randomWords[0], i, j, k)));
                    uint256 targetContent = expandedValue % categories[i].contentsTotalWeight;
                    uint256 indexContent = _binarySearch(categories[i].tokenWeights, targetContent);
                    _mintReward(req.user, categories[i], indexContent);
                }
            }
        }

        delete s_requestUser[requestId];
        delete s_requestTokenId[requestId];
        delete s_requestOpenings[requestId];
        delete s_requestRandWords[requestId];
        delete s_requestExcludedIds[requestId];
    }

    /**
     * @notice Burns a given amount of Gravity Grade tokens
     * @param _tokenId The id of the token to burn
     * @param _amount Amount of the token to burn
     */
    function _burnTokens(address _token, uint256 _tokenId, uint256 _amount) internal {
        IAssetManager(_token).trustedBurn(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Mints appropriate rewards for the user
     * @param _user The address of the user
     * @param _category The category from which the reward should come
     * @param _index Index of the particular contents to mint
     */
    function _mintReward(address _user, ContentCategory memory _category, uint256 _index) internal {
        ITrustedMintable(_category.tokens[_index]).trustedMint(
            _user,
            _category.tokenIds[_index],
            _category.tokenAmounts[_index]
        );
        emit RewardGranted(_category.tokens[_index], _category.tokenIds[_index], _category.tokenAmounts[_index]);
    }

    /**
     * @notice Converts an array of weights into a cumulative array
     * @param _arr The array to convert
     * @return _cumulativeArr The resultant cumulative array
     */
    function _arrayToCumulative(uint256[] memory _arr) private pure returns (uint256[] memory _cumulativeArr) {
        _cumulativeArr = new uint256[](_arr.length);
        _cumulativeArr[0] = _arr[0];
        for (uint256 i = 1; i < _arr.length; i++) {
            _cumulativeArr[i] = _cumulativeArr[i - 1] + _arr[i];
        }
    }

    /**
     * @notice Runs a binary search on an array
     * @param _arr The array to search
     * @param _target The target value
     * @return _location Index of the result
     */
    function _binarySearch(uint256[] memory _arr, uint256 _target) private pure returns (uint256 _location) {
        uint256 left;
        uint256 mid;
        uint256 right = _arr.length;

        while (left < right) {
            mid = Math.average(left, right);

            if (_target < _arr[mid]) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }

        if (left > 0 && _arr[left - 1] == _target) {
            return left - 1;
        } else {
            return left;
        }
    }
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

pragma solidity ^0.8.0;

/**
* @title Interface used to check eligibility of an address for something
*/
interface IConditionalProvider {
    /**
    * @notice Returns whether the address is eligible
    * @param _address The address
    * @return _isEligible Whether the address is eligible
    */
    function isEligible(address _address) external view returns (bool _isEligible);
}

pragma solidity ^0.8.0;

// @title Interface for a generic burn contract
interface IGenericBurnV2 {
    /**
    This interface is a little complex.

    When a player burns a token, they are guaranteed one draw from each content category for that token id.

    For a content category, first the amount of contents are drawn. Then, each content is drawn until the drawn amount
    has been reached.

    Here is an example of how it should be used

    The admin wants to players to burn GG token id 18. When they burn it, they have a 50% chance of getting a tokenID 19
    on GG and are guaranteed to get 2-5 additional goodies from the PIX Assets. Further, if you own a gold badge you also
    get 100 Astro Credits

    First, he calls

        let newID = contract.createContentCategory(18);

    Now, he wants there to be a 50% chance of nothing and a 50% chance of 1 token id 19 on GG, so he calls

        contract.setContentAmounts(18, newId, [1, 0], [10,10]);

    Since there is only one possibility for the contents, he calls

        contract.setContents(18, newId, [GG_address], [19], [1], [1]);

    Next, he configures the PIX asset goodies. Thus, he creates a content category

        let newID2 = contract.createContentCategory(18);

    Then, he sets the content amounts

        contract.setContentAmounts(18, newId2, [2, 3, 4, 5], [10,20, 20,10]);

    Finally, he sets the possible contents

        contract.setContents(18, newId2,
                        [asset_address,
                         asset_address,
                         asset_address],
                         [astro_credit_id
                          biomod_legendary_id
                          blueprint_id],
                         [100, 1, 1],
                         [100, 20, 10]);

    For the gold badge = astro credits, the admin has created a conditional provider along the lines of

        function isEligible(address _address) external view returns (bool _isEligible){
            _isEligible = IERC1555(pixAssets).balanceOf(_address, gold_badge_id) > 0;
        }

   He creates a new category with the contents as previously described, then he calls

       contract.setContentEligibility(18, id3, conditionalProvider.address);

    Finally, the admin whitelists the token for burning

        contract.whitelistToken(18, true);

    */

    error GB__ZeroWeight();
    error GB_ZeroAmount();
    error GB__TokenNotWhitelisted(uint256 _tokenId);
    error GB__InvalidCategoryId(uint256 _categoryId);
    error GB__NotTrustedMintable(address _tokenAddress);
    error GB__ArraysNotSameLength();
    error GB__NotConditionalProvider(address _address);
    error GB__NotGov(address _address);
    error GB__NotEligible(address _address);
    error GB__NotOracle();
    error GB__ZeroAddress();
    error GB__MaxDrawsExceeded(uint256 _amount);
    /**
     * @notice Event emitted upon opening packs
     * @param _opener The address of the opener
     * @param _tokenId The tokenid that was "opened"
     * @param _numPacks The number of tokens that were "opened"
     */
    event PackOpened(address _opener, address _token, uint256 _tokenId, uint256 _numPacks);
    /**
     * @notice Event emitted when a category is whitelisted
     * @param _tokenId The id of the token
     * @param _isWhitelisted Whether it's burnable
     */
    event TokenWhitelisted(uint256 _tokenId, bool _isWhitelisted);
    /**
     * @notice Event emitted when a category is created
     * @param _tokenId The token id a category has been created for
     * @param _categoryId The id of the new category
     */
    event CategoryCreated(uint256 _tokenId, uint256 _categoryId);
    /**
     * @notice Event emitted when a category is deleted
     * @param _tokenId The token id a category has been deleted for
     * @param _categoryId The id of the deleted category
     */
    event CategoryDeleted(uint256 _tokenId, uint256 _categoryId);
    /**
     * @notice Event emitted when a category has its eligibility updated
     * @param _tokenId The token id which the category belongs to
     * @param _categoryId The id of the category
     * @param _provider The address of the eligibility provider
     */
    event CategoryEligibilitySet(uint256 _tokenId, uint256 _categoryId, address _provider);
    /**
     * @notice Event emitted when a categories content amounts are updated
     * @param _tokenId The token id of the token
     * @param _categoryId The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentAmountsUpdated(uint256 _tokenId, uint256 _categoryId, uint256[] _amounts, uint256[] _weights);

    /**
     * @notice Event emitted when the contents of a category are updated
     * @param _tokenId The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _tokens Array of addresses to the content tokens.
     * @param _tokenIds Tokens ids of contents. Will be ignored if the token is an ERC721
     * @param _amounts Array containing the amounts of each tokens
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentsUpdated(
        uint256 _tokenId,
        uint256 _contentCategory,
        address[] _tokens,
        uint256[] _tokenIds,
        uint256[] _amounts,
        uint256[] _weights
    );

    /**
     * @notice Event emitted when the user gains a reward from opening a pack.
     * @param _token Address of the reward token
     * @param _tokenId The token id of the token
     * @param _amount amount of the token being rewarded
     */
    event RewardGranted(address _token, uint256 _tokenId, uint256 _amount);

    event GuaranteedRewardSet(uint256 _tokenId, GuaranteedReward[] _rewards);

    struct ContentCategory {
        uint256 id;
        uint256 contentAmountsTotalWeight;
        uint256 contentsTotalWeight;
        uint256[] contentAmounts;
        uint256[] contentAmountsWeights;
        uint256[] tokenAmounts;
        uint256[] tokenWeights;
        address[] tokens;
        uint256[] tokenIds;
    }

    struct GuaranteedReward {
        address token;
        uint256 tokenId;
        uint256 tokenAmount;
    }

    struct RequestInputs {
        address user;
        address token;
        uint256 tokenId;
        uint256 openings;
        uint256 randWordsCount;
        uint256[] excludedIds;
    }

    struct SetContentInputs {
        address token;
        uint256 tokenId;
        uint256 categoryId;
        address[] tokens;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256[] weights;
    }

    /**
     * @notice Burns the "pack" thus "opening" it
     * @param _tokenId The tokenId of the pack to burn
     * @param _amount The amount of tokens to burn
     * @param _optIn whether or not the user wants to check eligibility for categories with such requirements
     *
     * Throws GB__TokenNotWhitelisted on non whitelisted token
     *
     */
    function burnPack(address _token, uint256 _tokenId, uint32 _amount, bool _optIn) external;

    /**
     * @notice Used to set whether a token is burnable by this contract
     * @param _tokenId The id of the token
     * @param _isWhitelisted Whether it's burnable
     *
     * Throws GB__NotGov on non gov call
     *
     * Emits TokenWhitelisted
     */
    function whitelistToken(address _token, uint256 _tokenId, bool _isWhitelisted) external;

    /**
     * @notice Used to create a content category
     * @param _tokenId The token id to create a category for
     * @return _categoryId The new ID of the content category
     *
     * Throws GB__NotGov on non gov call
     *
     * Emits CategoryCreated
     */
    function createContentCategory(address _token, uint256 _tokenId) external returns (uint256 _categoryId);

    /**
     * @notice Deletes a content category
     * @param _tokenId The token id
     * @param _contentCategory The content category ID
     *
     * Throws GB__NotGov on non gov call
     * Throws GB__InvalidCategoryId on invalid category ID
     *
     * Emits CategoryDeleted
     */
    function deleteContentCategory(address _token, uint256 _tokenId, uint256 _contentCategory) external;

    /**
     * @notice Used to set eligibility conditions for a content category
     * @param _tokenId The token id
     * @param _categoryId The category id
     * @param _conditionalProvider Address to contract implementing ConditionalProvider
     *
     * Throws GB__NotGov on non gov call
     * Throws GB__NotConditionalProvider on _conditionalProvider not implementing ConditionalProvider or erc165
     *
     * Emits CategoryEligibilitySet
     */
    function setContentEligibility(
        address _token,
        uint256 _tokenId,
        uint256 _categoryId,
        address _conditionalProvider
    ) external;

    /**
     * @notice Used to get the content categories for a token
     * @param _tokenId The token id
     * @return _categories Array of ContentCategory structs corresponding to the given id
     */
    function getContentCategories(
        address _token,
        uint256 _tokenId
    ) external view returns (ContentCategory[] calldata _categories);

    /**
     * @notice Used to edit the content amounts for a content category
     * @param _tokenId The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     *
     * Throws GB__NotGov on non gov call.
     * Throws GB__ZeroWeight on any weight being zero
     * @dev Does not throw anything on zero amounts
     * Throws GB__InvalidCategoryId on invalid category ID
     * Throws GB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentAmountsUpdated
     */
    function setContentAmounts(
        address _token,
        uint256 _tokenId,
        uint256 _contentCategory,
        uint256[] memory _amounts,
        uint256[] memory _weights
    ) external;

    /**
     * @notice Used to edit the contents for a content category
     * @dev _tokens needs to be implementing ITrustedMintable
     *
     * Throws GB__NotGov on non gov call.
     * Throws GB__ZeroWeight on any weight being zero
     * Throws GB__ZeroAmount on any amount being zero
     * Throws GB__InvalidCategoryId on invalid category ID
     * Throws GB__NotTrustedMintable on any address not implementing ITrustedMintable
     * Throws GB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentsUpdated
     */
    function setContents(SetContentInputs calldata args) external;
}