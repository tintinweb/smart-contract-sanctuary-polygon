// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {AllowlistModifiers} from "./AllowlistModifiers.sol";
import {AllowlistStorage} from "./AllowlistStorage.sol";
import {UserInventoryStorage} from "../../libraries/LibUserInventoryStorage.sol";
import {IFundManagerFacet} from "../FundManager/IFundManagerFacet.sol";

/// @title Allowlist Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract AllowlistFacet is AllowlistModifiers {

    /// TODO check user exits
    /// @notice Purchase a Allowlist
    /// @dev revert NoStockLeft
    ///      revert AllowlistNotActive
    ///      revert QueryNonExistentAllowlist
    ///      revert UserIsFrozen
    ///      revert MaxPerWalletReached
    ///      revert ProjectNotActive
    /// @param _allowlistId the id os allowlist to buytotal slot available to sell
    function purchaseAllowlist(uint256 _allowlistId)
        external
        purchasable(_allowlistId)
    {
        uint256 projectId = s.allowlists[_allowlistId].projectId;
        uint256 allowlistsBalance = s.userInventory[msg.sender].allowlistsBalance[projectId];
        
        if (allowlistsBalance >= s.projects[projectId].maxPerWallet ) revert MaxPerWalletReached();
        if (allowlistsBalance < 1)  
            s.userInventory[msg.sender].projectIds.push(projectId); 
        s.userInventory[msg.sender].allowlistsBalance[projectId]++;
        s.userInventory[msg.sender].allowlistsPrice[projectId] = s.allowlists[_allowlistId].price;
        s.allowlists[_allowlistId].purchased++;

        _fundManagerFacet().charge(s.allowlists[_allowlistId].price, msg.sender);
        
    }

    /// @notice Create a Allowlist
    /// @dev revert with _stock = 0
    ///      revert  _startTime > _endTime
    ///      revert _projectId not exits
    ///      revert _projectId inactive
    ///      revert  _startTime < now
    /// @param _stock the total slot available to sell
    /// @param _price the price of one items
    /// @param _startTime start date of sale
    /// @param _endTime end time of sale
    /// @param _projectId project to which this allowlist belongs
    /// @param _metadataUrl Metadata URL
    /// @param _active enable/disable the allowlist
    /// @return the ID of the new Allowlist
    function createAllowlist(
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _projectId,
        string memory _metadataUrl,
        bool _active
    ) external
        projectIsActive( _projectId)
        checkNonZeroStock( _stock)
        afterDate( _startTime)
        startTimeBeforeEndTime( _startTime, _endTime)
        returns (uint256)
    {
        s.allowlistsCount += 1;
        s.projects[_projectId].allowlistsCount += 1;
        s.allowlists[s.allowlistsCount].stock = _stock;
        s.allowlists[s.allowlistsCount].price = _price;
        s.allowlists[s.allowlistsCount].startTime = _startTime;
        s.allowlists[s.allowlistsCount].endTime = _endTime;
        s.allowlists[s.allowlistsCount].projectId = _projectId;
        s.allowlists[s.allowlistsCount].allowlistMetadataUrl = _metadataUrl;
        s.allowlists[s.allowlistsCount].active = _active;
        return s.allowlistsCount;
    }

    /// @notice Update a Allowlist
    /// @dev revert when _stock < purchased
    ///      revert  _startTime > _endTime
    ///      revert non Exist projects
    /// @param _stock the total slot available to sell
    /// @param _price the price of one items
    /// @param _startTime start date of sale
    /// @param _endTime end time of sale
    /// @param _metadataUrl Metadata URL
    /// @param _active enable/disable the allowlist
    function updateAllowlist(
        uint256 _allowlistId,
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        string memory _metadataUrl,
        bool _active
    ) external 
        exists(_allowlistId) 
        checkStockOverPurchase( _allowlistId,  _stock) 
        startTimeBeforeEndTime( _startTime, _endTime)
    {
        s.allowlists[_allowlistId].stock = _stock;
        s.allowlists[_allowlistId].price = _price;
        s.allowlists[_allowlistId].startTime = _startTime;
        s.allowlists[_allowlistId].endTime = _endTime;
        s.allowlists[_allowlistId].allowlistMetadataUrl = _metadataUrl;
        s.allowlists[_allowlistId].active = _active;
    }

     /// @notice Enable/Disable a Project with projectId_
    /// @dev check that projectId_ exists
    /// @param _allowlistId Allowlits Id to enable/disable
    /// @param _active enable or disable the allowlist
    function setAllowlistActive(uint256 _allowlistId, bool _active) external exists(_allowlistId)  {
        if(_active == s.allowlists[_allowlistId].active) revert  AllowlistAlreadyInState();
        s.allowlists[_allowlistId].active = _active;
    }

     /// @notice Check that an Allowlist has stock
    /// @dev revert with Allowlist nonexits
    /// @param _id the total slot available to sell
    /// @return  true when stock > 0, false othercase
    function allowlistHasStockById(uint256 _id)
        external
        view
        exists(_id)
        returns (bool)
    {
        return (s.allowlists[_id].stock - s.allowlists[_id].purchased) > 0;
    }

    /// @notice Return All the Allowlist created
    /// @return An array of AllowlistStorage
    function getAllAllowlists() external view returns (AllowlistStorage[] memory) {
        AllowlistStorage[] memory _allowlists = new AllowlistStorage[](
            s.allowlistsCount
        );
        for (uint256 i = 0; i < s.allowlistsCount; i++) {
            _allowlists[i] = s.allowlists[i + 1];
        }
        return _allowlists;
    }

    /// @notice Return all the allowlist of a projectId_
    /// @dev Explain to a developer any extra details
    /// @param _projectId The category to gets the projects
    /// @return Array of AllowlistStorage
    function getAllowlistsForProject(uint256 _projectId) 
        external
        view
        returns (AllowlistStorage[] memory) 
    {
        if (!(_projectId > 0 && _projectId <= s.projectsCount)) revert QueryNonExistentProject();

        AllowlistStorage[] memory _allowlists = new AllowlistStorage[](
            s.projects[_projectId].allowlistsCount
        );
        uint256 j = 0;
        for (uint256 i = 1; i <= s.allowlistsCount; i++) {
            if (_projectId ==  s.allowlists[i].projectId) {
                _allowlists[j] = s.allowlists[i];
                j++;
            }
        }

        return _allowlists;
    }

    function getAllowlistById(uint256 _allowlistId)
        public
        view
        exists(_allowlistId)
        returns (AllowlistStorage memory)
    {
        return s.allowlists[_allowlistId]; 
    }

    /// @notice Return is a Allowlist is enable or disable
    /// @param _allowlistId the Allowlist id
    /// @return true for enable Allowlist, false on disable Allowlist
    function isAllowlistActiveById(uint256 _allowlistId) 
        public 
        view 
        returns (bool) 
    {
        return getAllowlistById(_allowlistId).active;
    }

   

    function _fundManagerFacet() private view returns (IFundManagerFacet fundManagerFacet) {
        fundManagerFacet = IFundManagerFacet(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IAllowlistFacet} from "./IAllowlistFacet.sol";
import {Listing} from "../../base/Listing.sol";

abstract contract AllowlistModifiers is IAllowlistFacet, Listing {

    modifier purchasable(uint256 allowlistId_) override {
        _purchasable( allowlistId_, s.allowlists[allowlistId_].projectId);
        _;
    }

    modifier exists(uint256 id_) override {
        if (id_ == 0 || id_ > s.allowlistsCount) revert QueryNonExistentAllowlist();
        _;
    }

    modifier isActive(uint256 id_) override {
        if (!s.allowlists[id_].active) revert AllowlistNotActive();
        _;
    }

    modifier hasStockAvailable(uint256 id_) override {
        if (!( (s.allowlists[id_].stock - s.allowlists[id_].purchased) > 0)) revert NoStockLeft();
        _;
    }

    modifier afterDate(uint256 date) {
        if (date < block.timestamp) revert StartTimeBeforeCurrentTime(); // solhint-disable-line not-rely-on-time
        _;
    }

    modifier checkStockOverPurchase(uint256 id_, uint256 newStock) {
        if (newStock < s.allowlists[id_].purchased) revert StockUnderPurchase(); 
        _;
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct AllowlistStorage {
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 projectId;
    string  allowlistMetadataUrl;
    bool active;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct UserInventoryStorage {
    uint256[] projectIds;
    uint256[] raffleIds;
    // project id => count of allowlist 
    mapping(uint256 => uint256) allowlistsBalance;
    // project id => price of buy
    mapping(uint256 => uint256) allowlistsPrice;
    // raffke id => count of raffle 
    mapping(uint256 => uint256) raffleBalance;
    // raffke id => price of buys
    mapping(uint256 => uint256) rafflePrice;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IFundManagerFacet {
   error CollectorNotSet();
   error TxFailed();
   error ZeroAddress();

   function charge(uint256 amount, address buyer) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {AllowlistStorage} from "./AllowlistStorage.sol";

interface IAllowlistFacet {
    error QueryNonExistentAllowlist();
    error AllowlistNotActive();
    error AllowlistAlreadyInState();
    error StartTimeBeforeCurrentTime();
    error StockUnderPurchase();
    

    function allowlistHasStockById(uint256 id_)
        external
        view
        returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Base} from "./Base.sol";

/// @title Base Contract for Facets Listing
/// @author Kfish n Chips
/// @notice Check that caller is a EoA
/// @dev revert with CallerNotEoA
/// @custom:security-contact [email protected]
abstract contract Listing is Base {

    modifier exists(uint256 id_) virtual {
        _;
    }

    modifier isActive(uint256 id_) virtual {
        _;
    }

    modifier hasStockAvailable(uint256 id_) virtual {
        _;
    }

    modifier purchasable(uint256 id_) virtual {
        _;
    }

    modifier checkNonZeroStock(uint256 stock) {
        if (stock < 1) revert CreateWithZeroStock();
        _;
    }

    modifier startTimeBeforeEndTime(uint256 startTime_, uint256 endTime_) {
        if (startTime_ > endTime_) revert EndTimeBeforeStartTime();
        _;
    }

    function _purchasable(uint256 id_, uint256 projectId_)
        public
        view
        projectIsActive( projectId_)
        exists( id_)
        isActive( id_)
        hasStockAvailable( id_)
    {
        if(s.users[msg.sender].wallet == address(0)) revert QueryNonExistentUser();
        if(s.users[msg.sender].frozen) revert UserIsFrozen();
    }
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

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {RaffleStorage} from "../facets/Raffle/RaffleStorage.sol";
import {ProjectStorage} from "../facets/Project/ProjectStorage.sol";
import {AllowlistStorage} from "../facets/Allowlist/AllowlistStorage.sol";
import {CategoryStorage} from "../facets/Category/CategoryStorage.sol";


import {UserStorage} from "./LibUserStorage.sol";
import {UserInventoryStorage} from "./LibUserInventoryStorage.sol";

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
    uint256 allowlistsCount;
    uint256 rafflesCount;
    uint256 usersCount;
    uint256 projectsCount;
    uint256 categoryCount;
    uint256 activeCategoryCount;
    address createUserSigner;
    IERC20 tokenContract;
    address collector;
    // wallet => User
    mapping(address => UserStorage) users;
    // project id => Project
    mapping(uint256 => ProjectStorage) projects;
    // listing id => Allowlist
    mapping(uint256 => AllowlistStorage) allowlists; 
    // raffle id => Raffle
    mapping(uint256 => RaffleStorage) raffles;
    // address => User Inventory
    mapping(address => UserInventoryStorage) userInventory;
    // category id => Category
    mapping(uint256 => CategoryStorage) categories;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title  Raffle AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RaffleStorage {
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 maxWinners;
    uint256 projectId;
    string  raffleMetadataUrl;
    bool active;
    bool raffled;
    address[] participants;
    address[] winners;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct ProjectStorage {
    uint256 maxPerWallet;
    bool active;
    uint256 categoryId;
    string metadataUrl;
    uint256 allowlistsCount;
    uint256 raffleCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Category AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct CategoryStorage {
    string name;
    bool active;
    string metadataUrl;
    uint256 projectsCount;
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