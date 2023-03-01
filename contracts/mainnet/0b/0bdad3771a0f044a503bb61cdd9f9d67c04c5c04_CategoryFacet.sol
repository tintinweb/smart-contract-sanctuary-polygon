// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IBase} from "../interfaces/IBase.sol";

/// @title Base Contract for Facets
/// @author Kfish n Chips
/// @notice Check that caller is a EoA
/// @dev revert with CallerNotEoA
/// @custom:security-contact [email protected]
abstract contract Base is IBase {
    AppStorage internal s;

    /// @notice Check that caller is a EoA
    /// @dev revert with CallerNotEoA
    modifier onlyEoA() {
        if(tx.origin != msg.sender) revert CallerNotEoA();      // solhint-disable-line avoid-tx-origin
        _;
    }

    /// @notice Check that a project with projectId_  is active
    /// @dev revert with ProjectNotActive
    modifier projectIsActive(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        if (!s.projects[projectId_].active) revert ProjectNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier projectExist(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        _;
    }

    /// @notice Check that category is Active Exist
    /// @dev 
    ///     revert with QueryNonExistentCategory
    ///     revert with CategoryNotActive
    modifier categoryIsActive(uint256 categoryId_) {
        if (!(categoryId_ > 0 && categoryId_ <= s.categoryCount)) revert QueryNonExistentCategory();
        if (!s.categories[categoryId_].active) revert CategoryNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier categoryExist(uint256 categoryId_) {
        if (categoryId_ < 1 ||  categoryId_ > s.categoryCount) revert QueryNonExistentCategory();
        _;
    }
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {CategoryStorage} from "./CategoryStorage.sol";
import {CategoryModifiers} from "./CategoryModifiers.sol";

/// @title Category Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract CategoryFacet is CategoryModifiers {
    
    /// @notice Create a category
    /// @dev 
    /// @param _name Category name
    /// @param _metadataUrl Metadata of Category
    /// @param _active Category paused/unpaused
    /// @return the ID of new Category
    function createCategory(
        string calldata _name,
        bool _active,
        string calldata _metadataUrl
    ) external 
        returns (uint256)
    {
        s.categoryCount += 1;
        s.categories[s.categoryCount].id = s.categoryCount;
        s.categories[s.categoryCount].name = _name;
        s.categories[s.categoryCount].metadataUrl = _metadataUrl;
        s.categories[s.categoryCount].active = _active;
        if (_active) s.activeCategoryCount++;
        return s.categoryCount;
    }

    /// @notice Update a category
    /// @dev Explain to a developer any extra details
    /// @param _categoryId Category ID 
    /// @param _name Category name
    /// @param _active Category paused/unpaused
    /// @param _metadataUrl Metadata of Category
    function updateCategory(
        uint256 _categoryId,
        string calldata _name,
        bool _active,
        string calldata _metadataUrl
    ) external 
        categoryExists(_categoryId) 
    {
        s.categories[_categoryId].name = _name;
        s.categories[_categoryId].metadataUrl = _metadataUrl;
        if (s.categories[_categoryId].active != _active) 
            _active ? s.activeCategoryCount++ : s.activeCategoryCount--;
        s.categories[_categoryId].active = _active;
    }

    /// @notice Pause a category
    /// @param _categoryId the category id
    /// @param _active enable or disable the category
    function setCategoryActive(uint256 _categoryId, bool _active) external categoryExists(_categoryId) {
        if(s.categories[_categoryId].active == _active) revert  CategoryAlreadyInState();
        s.categories[_categoryId].active = _active;
        _active ? s.activeCategoryCount++ : s.activeCategoryCount--;
    }

    /// @notice Return all the categories created
    /// @return Array of CategoryStorage
    function getAllCategories() external view returns (CategoryStorage[] memory) {
        CategoryStorage[] memory _categories = new CategoryStorage[](
            s.categoryCount
        );
        for (uint256 i = 0; i < s.categoryCount; i++) {
            _categories[i] = s.categories[i+1];
        }
        return _categories;
    }

    /// @notice Return all the Active Categories
    /// @return Array of CategoryStorage
    function getActiveCategories() external view returns (CategoryStorage[] memory) {
        CategoryStorage[] memory categories_ = new CategoryStorage[](
            s.activeCategoryCount
        );

        uint256 activeIndex;
        for (uint256 i = 0; i <= s.categoryCount; i++) {
            CategoryStorage memory category =  s.categories[i];
            if(category.active) {
                categories_[activeIndex++] = category;
            }
        }
        return categories_;
    }

    /// @notice Return the category with id_
    /// @dev check that id_ exists
    /// @param _categoryId of the category
    /// @return CategoryStorage of id_
    function getCategoryById(uint256 _categoryId)
        public
        view
        categoryExists(_categoryId)
        returns (CategoryStorage memory)
    {
        return s.categories[_categoryId];
    }

    /// @notice Return is a category is enable or disable
    /// @param _categoryId the category id
    /// @return true for enable category, false on disable category
    function isCategoryActiveById(uint256 _categoryId) public view returns (bool) {
        return getCategoryById(_categoryId).active;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {ICategoryFacet} from "./ICategoryFacet.sol";
import {Base} from "../../base/Base.sol";

/// @title Category Facet Modifiers
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
abstract contract CategoryModifiers is ICategoryFacet, Base {

    /// @notice Check that a Category with categoryId_  exits
    /// @dev revert with QueryNonExistentCategory
    modifier categoryExists(uint256 categoryId_) {
        if (!(categoryId_ > 0 && categoryId_ <= s.categoryCount)) revert QueryNonExistentCategory();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Category AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct CategoryStorage {
    uint256 id;
    string name;
    bool active;
    string metadataUrl;
    uint256 projectsCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {CategoryStorage} from "./CategoryStorage.sol";

/// @title Category Facet Interface
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
interface ICategoryFacet {
    error CategoryAlreadyInState();

    /// @notice Return is a category is paused or unpaused
    /// @param _categoryId the category id
    /// @return true for enable category, false on disable category
    function isCategoryActiveById(uint256 _categoryId) 
        external 
        view 
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct DirectBuyStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 projectId;
    string  directBuyMetadataUrl;
    bool active;
    address[] buyers;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct ProjectStorage {
    uint256 id;
    uint256 maxPerWallet;
    bool active;
    uint256 categoryId;
    string metadataUrl;
    uint256 directBuysCount;
    uint256 raffleCount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title  Raffle AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RaffleStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 maxWinners;
    uint256 winnersCount;
    uint256 projectId;
    string  raffleMetadataUrl;
    bool active;
    bool raffled;
    address[] participants;
    address[] winners;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct UserInventoryStorage {
    uint256[] directBuysIds;
    uint256[] raffleIds;
    uint256[] raffleWonIds;
    // project id => count of directBuy + raffle won
    mapping(uint256 => uint256) projectBalance;
    // directBuy id => count of directBuy 
    mapping(uint256 => uint256) directBuysBalance;
    // raffke id => count of raffle 
    mapping(uint256 => uint256) raffleBalance;
    // raffke id => count of raffle won
    mapping(uint256 => uint256) raffleWonBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IBase {
    error EndTimeBeforeStartTime();
    error CallerNotEoA();
    error InvalidSignature();
    error QueryNonExistentCategory();
    error CategoryNotActive();
    error UserWalletNotMatch();
    error MaxPerWalletReached();
    
    /**
        STOCK
    */
    error TotalStockLessThanSoldStock();
    error NotEnoughStock();
    error NoStockLeft();
    error CreateWithZeroStock();
    error PurchasedGreaterStock();
    /**
        USERS
    */
    error UserAlreadyExists();
    error CreateUserSignerZero();
    error AlreadyIsCreateUserSigner();
    error QueryNonExistentUser();
    error UserIsFrozen();
    
    
    /**
        PROJECTS
    */
    error QueryNonExistentProject();
    error ProjectNotActive();
    error MaxPerWalletZero();
    error ProjectAlreadyInState();
    /**
        RBAC
    */
    error CallerNotAuthorized();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {RaffleStorage} from "../facets/Raffle/RaffleStorage.sol";
import {ProjectStorage} from "../facets/Project/ProjectStorage.sol";
import {DirectBuyStorage} from "../facets/DirectBuy/DirectBuyStorage.sol";
import {CategoryStorage} from "../facets/Category/CategoryStorage.sol";
import {UserInventoryStorage} from "../facets/UserInventory/UserInventoryStorage.sol";


import {UserStorage} from "./LibUserStorage.sol";


/* AppStorage Pattern
 *
 * @dev A nicer and more convenient way to access application specific state variables that are shared among facets.
 * 
 * Keep State Variables Safe
 *   DOES
 *      1 To add new state variables to an AppStorage struct, add them to the end of the struct. This makes sense 
 *          because it is not possible for existing facets to overwrite state variables at new storage locations.
 *      2 New state variables can be added to the ends of structs that are stored in mappings.
 *      3 A trick to use inner structs and still enable them to be extended is to put them in mappings. A struct 
 *          stored in a mapping can be extended in upgrades.
 *   DONT
 *      1 If you are using AppStorage then do not declare and use state variables outside the AppStorage struct. 
 *          Except Diamond Storage can be used.
 *      2 Do not add new state variables to the beginning or middle of structs. Doing this makes the new state 
 *          variable overwrite existing state variable data and all state variables after the new state variable 
 *          reference the wrong storage location.
 *      3 Do not put structs directly in structs unless you don’t plan on ever adding more state variables to the 
 *          inner structs. You won't be able to add new state variables to inner structs in upgrades.
 *      4 Do not add new state variables to structs that are used in arrays.
 *      5 Do not allow any facet to be able to call `selfdestruct`. This is easy. Simply don’t allow the `selfdestruct` 
 *          command to exist in any facet source code and don’t allow that command to be called via a delegatecall. Because 
 *          `selfdestruct` could delete a facet that is used by a diamond, or `selfdestruct` could be used to delete a 
 *          diamond proxy contract.
 */ 
 
struct AppStorage {
    uint256 directBuysCount;
    uint256 rafflesCount;
    uint256 usersCount;
    uint256 projectsCount;
    uint256 categoryCount;
    uint256 activeCategoryCount;
    address createUserSigner;
    IERC20Metadata tokenContract;
    address collector;
    // wallet => User
    mapping(address => UserStorage) users;
    // project id => Project
    mapping(uint256 => ProjectStorage) projects;
    // listing id => DirectBuy
    mapping(uint256 => DirectBuyStorage) directBuys; 
    // raffle id => Raffle
    mapping(uint256 => RaffleStorage) raffles;
    // raffle id => address => bool)
    mapping(uint256 => mapping (address => bool)) rafflesWinners;
    // address => User Inventory
    mapping(address => UserInventoryStorage) userInventory;
    // category id => Category
    mapping(uint256 => CategoryStorage) categories;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Data Storage for User
/// wallet: address of the user
/// discordID: ID of the user on Discord
/// frozen: enable/disable user

struct UserStorage {
    address wallet;
    string discordId;
    uint256 purchaseCount;
    bool frozen;
}