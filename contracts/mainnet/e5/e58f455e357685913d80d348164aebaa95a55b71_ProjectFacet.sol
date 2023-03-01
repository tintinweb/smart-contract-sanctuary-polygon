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

import {ProjectStorage} from "./ProjectStorage.sol";

interface IProjectFacet {

    function createProject(
        uint256 maxPerWallet_,
        string memory metadataUrl_,
        bool active_,
        uint256 category_
    ) external returns (uint256);

     function updateProject(
        uint256 id_,
        uint256 maxPerWallet_,
        string memory metadataUrl_,
        bool active_,
        uint256 category_
    ) external;

    function getProjectById(uint256 id_)
        external
        view
        returns (ProjectStorage memory);

    function isProjectActiveById(uint256 id_) 
        external 
        view 
        returns (bool);

    function getAllProjects() 
        external 
        view 
        returns (ProjectStorage[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {ProjectStorage} from "./ProjectStorage.sol";
import {ProjectModifiers} from "./ProjectModifiers.sol";

/// @title Project Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract ProjectFacet is ProjectModifiers {
    
    /// @notice Create a Project
    /// @dev reverts:
    ///     _categoryId disable
    ///     _maxPerWallet Zero
    /// @param _maxPerWallet Category paused/unpaused
    /// @param _metadataUrl Metadata of Project
    /// @param _active enable or disable the Project
    /// @param _categoryId Category project belongs
    /// @return the ID of new project
    function createProject(
        uint256 _maxPerWallet,
        string memory _metadataUrl,
        bool _active,
        uint256 _categoryId
    ) external 
        categoryIsActive(_categoryId)
        maxPerWalletNotZero( _maxPerWallet)
        returns (uint256)
    {
        s.projectsCount += 1;
        s.categories[_categoryId].projectsCount += 1;

        s.projects[s.projectsCount].id = s.projectsCount;
        s.projects[s.projectsCount].maxPerWallet = _maxPerWallet;
        s.projects[s.projectsCount].metadataUrl = _metadataUrl;
        s.projects[s.projectsCount].active = _active;
        s.projects[s.projectsCount].categoryId = _categoryId;
        return s.projectsCount;
    }

    /// @notice Update a Project
    /// @dev reverts:
    ///     _categoryId disable
    ///     _maxPerWallet Zero
    /// @param _projectId Project Id to enable/disable
    /// @param _maxPerWallet Category paused/unpaused
    /// @param _metadataUrl Metadata of Project
    /// @param _active enable or disable the Project
    /// @param _categoryId Category project belongs
    function updateProject(
        uint256 _projectId,
        uint256 _maxPerWallet,
        string memory _metadataUrl,
        bool _active,
        uint256 _categoryId
    ) external 
        projectExists(_projectId)
        categoryExist( _categoryId)
        maxPerWalletNotZero( _maxPerWallet)
    {
        uint256 oldCategoryId = s.projects[_projectId].categoryId;
        s.projects[_projectId].maxPerWallet = _maxPerWallet;
        s.projects[_projectId].metadataUrl = _metadataUrl;
        s.projects[_projectId].active = _active;
        if (oldCategoryId != _categoryId) {
            s.categories[oldCategoryId].projectsCount -= 1;
            s.categories[_categoryId].projectsCount += 1;
        }
        s.projects[_projectId].categoryId = _categoryId;
    }

    /// @notice Enable/Disable a Project with projectId_
    /// @dev check that projectId_ exists
    /// @param projectId_ Project Id to enable/disable
    /// @param active_ enable or disable the project
    function setProjectActive(uint256 projectId_, bool active_) external projectExists(projectId_) {
        if(active_ == s.projects[projectId_].active) revert ProjectAlreadyInState();
        s.projects[projectId_].active = active_;
    }

    /// @notice Return all the projects created
    /// @dev Explain to a developer any extra details
    /// @return Array of ProjectStorage
    function getAllProjects() external view returns (ProjectStorage[] memory) {
        ProjectStorage[] memory _projects = new ProjectStorage[](
            s.projectsCount
        );
        for (uint256 i = 0; i < s.projectsCount; i++) {
            _projects[i] = s.projects[i+1];
        }
        return _projects;
    }

    /// @notice Return all the project of categoryId_
    /// @dev Explain to a developer any extra details
    /// @param _categoryId The category to gets the projects
    /// @return Array of ProjectStorage
    // TODO check that category exists
    function getProjectsForCategory(uint256 _categoryId) 
        external
        view
        categoryExist( _categoryId)
        returns (ProjectStorage[] memory) 
    {
       
        ProjectStorage[] memory _projects = new ProjectStorage[](
            s.categories[_categoryId].projectsCount
        );
        uint256 j = 0;

        for (uint256 i = 1; i <= s.projectsCount; i++) {
            if (_categoryId == s.projects[i].categoryId) {
                _projects[j] = s.projects[i];
                j++;
            }
        }

        return _projects;
    }

    /// @notice Return the project with id_
    /// @dev check that id_ exists
    /// @param _projectId of the projects
    /// @return ProjectStorage of id_
    function getProjectById(uint256 _projectId)
        public
        view
        projectExists(_projectId)
        returns (ProjectStorage memory)
    {
        return s.projects[_projectId];
    }

    /// @notice return is a project is enable or disable
    /// @param _projectId teh project id
    /// @return true for enable project, false on disable project
    function isProjectActiveById(uint256 _projectId) public view returns (bool) {
        return getProjectById(_projectId).active;
    }

    /// @notice check is a project exists
    /// @param _projectId the project id
    /// @return true for a valid project, false on other case
    function _projectExists(uint256 _projectId) private view returns (bool) {
        return (_projectId <= s.projectsCount && _projectId > 0);
    }
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IProjectFacet} from "./IProjectFacet.sol";
import {Base} from "../../base/Base.sol";

abstract contract ProjectModifiers is IProjectFacet, Base {

    /// @notice Check that a project with projectId_  exits
    /// @dev revert with QueryNonExistentProjects
    modifier projectExists(uint256 projectId_) {
        if (projectId_ < 1 || projectId_ > s.projectsCount) revert QueryNonExistentProject();
        _;
    }

    /// @notice Check that a maxPerWallet is abone 0
    /// @dev revert with MaxPerWalletZero
    modifier maxPerWalletNotZero(uint256 maxPerWallet) {
        if (maxPerWallet == 0) revert MaxPerWalletZero();
        _;
    }
        
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