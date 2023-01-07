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
        exists( id_)
        projectIsActive( projectId_)
        isActive( id_)
        hasStockAvailable( id_)
    {
        uint256 projectBalance = s.userInventory[msg.sender].projectBalance[projectId_];
        if (projectBalance >= s.projects[projectId_].maxPerWallet ) revert MaxPerWalletReached();
        if(s.users[msg.sender].wallet == address(0)) revert QueryNonExistentUser();
        if(s.users[msg.sender].frozen) revert UserIsFrozen();
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {DirectBuyModifiers} from "./DirectBuyModifiers.sol";
import {DirectBuyStorage} from "./DirectBuyStorage.sol";
import {UserInventoryStorage} from "../../facets/UserInventory/UserInventoryStorage.sol";
import {IFundManagerFacet} from "../FundManager/IFundManagerFacet.sol";

/// @title DirectBuy Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract DirectBuyFacet is DirectBuyModifiers {

    /// @notice Purchase a DirectBuy
    /// @dev revert NoStockLeft
    ///      revert DirectBuyNotActive
    ///      revert QueryNonExistentDirectBuy
    ///      revert UserIsFrozen
    ///      revert MaxPerWalletReached
    ///      revert ProjectNotActive
    ///      revert DirectBuyNotStarted
    ///      revert DirectBuyFinished
    /// @param _directBuyId the id of directBuy to buy
    function purchaseDirectBuy(uint256 _directBuyId)
        external
        purchasable(_directBuyId)
    {
        uint256 projectId = s.directBuys[_directBuyId].projectId;
        uint256 directBuysBalance = s.userInventory[msg.sender].directBuysBalance[_directBuyId];
        
        _fundManagerFacet().charge(s.directBuys[_directBuyId].price, msg.sender);

        if (directBuysBalance < 1)  
            s.userInventory[msg.sender].directBuysIds.push(_directBuyId);
        s.userInventory[msg.sender].directBuysBalance[_directBuyId]++;
        s.userInventory[msg.sender].projectBalance[projectId]++;
        s.directBuys[_directBuyId].buyers.push(msg.sender);
        s.directBuys[_directBuyId].purchased++;
    }

    /// @notice Create a DirectBuy
    /// @dev revert with _stock = 0
    ///      revert  _startTime > _endTime
    ///      revert _projectId not exits
    ///      revert _projectId inactive
    ///      revert  _startTime < now
    /// @param _stock the total slot available to sell
    /// @param _price the price of one items
    /// @param _startTime start date of sale
    /// @param _endTime end time of sale
    /// @param _projectId project to which this directBuy belongs
    /// @param _metadataUrl Metadata URL
    /// @param _active enable/disable the directBuy
    /// @return the ID of the new DirectBuy
    function createDirectBuy(
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
        s.directBuysCount += 1;
        s.projects[_projectId].directBuysCount += 1;
        s.directBuys[s.directBuysCount].id = s.directBuysCount;
        s.directBuys[s.directBuysCount].stock = _stock;
        s.directBuys[s.directBuysCount].price = _price;
        s.directBuys[s.directBuysCount].startTime = _startTime;
        s.directBuys[s.directBuysCount].endTime = _endTime;
        s.directBuys[s.directBuysCount].projectId = _projectId;
        s.directBuys[s.directBuysCount].directBuyMetadataUrl = _metadataUrl;
        s.directBuys[s.directBuysCount].active = _active;
        return s.directBuysCount;
    }

    /// @notice Update a DirectBuy
    /// @dev revert when _stock < purchased
    ///      revert  _startTime > _endTime
    ///      revert non Exist projects
    /// @param _stock the total slot available to sell
    /// @param _price the price of one items
    /// @param _startTime start date of sale
    /// @param _endTime end time of sale
    /// @param _metadataUrl Metadata URL
    /// @param _active enable/disable the directBuy
    function updateDirectBuy(
        uint256 _directBuyId,
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        string memory _metadataUrl,
        bool _active
    ) external 
        exists(_directBuyId) 
        checkStockOverPurchase( _directBuyId,  _stock) 
        startTimeBeforeEndTime( _startTime, _endTime)
    {
        s.directBuys[_directBuyId].stock = _stock;
        s.directBuys[_directBuyId].price = _price;
        s.directBuys[_directBuyId].startTime = _startTime;
        s.directBuys[_directBuyId].endTime = _endTime;
        s.directBuys[_directBuyId].directBuyMetadataUrl = _metadataUrl;
        s.directBuys[_directBuyId].active = _active;
    }

     /// @notice Enable/Disable a Project with projectId_
    /// @dev check that projectId_ exists
    /// @param _directBuyId Allowlits Id to enable/disable
    /// @param _active enable or disable the directBuy
    function setDirectBuyActive(uint256 _directBuyId, bool _active) external exists(_directBuyId)  {
        if(_active == s.directBuys[_directBuyId].active) revert  DirectBuyAlreadyInState();
        s.directBuys[_directBuyId].active = _active;
    }

     /// @notice Check that an DirectBuy has stock
    /// @dev revert with DirectBuy nonexits
    /// @param _id the total slot available to sell
    /// @return  true when stock > 0, false othercase
    function directBuyHasStockById(uint256 _id)
        external
        view
        exists(_id)
        returns (bool)
    {
        return (s.directBuys[_id].stock - s.directBuys[_id].purchased) > 0;
    }

    /// @notice Return All the DirectBuy created
    /// @return An array of DirectBuyStorage
    function getAllDirectBuys() external view returns (DirectBuyStorage[] memory) {
        DirectBuyStorage[] memory _directBuys = new DirectBuyStorage[](
            s.directBuysCount
        );
        for (uint256 i = 0; i < s.directBuysCount; i++) {
            _directBuys[i] = s.directBuys[i + 1];
        }
        return _directBuys;
    }

    /// @notice Return all the directBuy of a projectId_
    /// @dev Explain to a developer any extra details
    /// @param _projectId The category to gets the projects
    /// @return Array of DirectBuyStorage
    function getDirectBuysForProject(uint256 _projectId) 
        external
        view
        returns (DirectBuyStorage[] memory) 
    {
        if (!(_projectId > 0 && _projectId <= s.projectsCount)) revert QueryNonExistentProject();

        DirectBuyStorage[] memory _directBuys = new DirectBuyStorage[](
            s.projects[_projectId].directBuysCount
        );
        uint256 j = 0;
        for (uint256 i = 1; i <= s.directBuysCount; i++) {
            if (_projectId ==  s.directBuys[i].projectId) {
                _directBuys[j] = s.directBuys[i];
                j++;
            }
        }

        return _directBuys;
    }

    /// @notice Return a DirectBuy by ID
    /// @param _directBuyId the DirectBuy id
    /// @return the DirectBuy with _directBuyId ID
    function getDirectBuyById(uint256 _directBuyId)
        public
        view
        exists(_directBuyId)
        returns (DirectBuyStorage memory)
    {
        return s.directBuys[_directBuyId]; 
    }

    /// @notice Return is a DirectBuy is enable or disable
    /// @param _directBuyId the DirectBuy id
    /// @return true for enable DirectBuy, false on disable DirectBuy
    function isDirectBuyActiveById(uint256 _directBuyId) 
        public 
        view 
        returns (bool) 
    {
        return getDirectBuyById(_directBuyId).active;
    } 

    function _fundManagerFacet() private view returns (IFundManagerFacet fundManagerFacet) {
        fundManagerFacet = IFundManagerFacet(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IDirectBuyFacet} from "./IDirectBuyFacet.sol";
import {Listing} from "../../base/Listing.sol";

/// @title DirectBuy Modifiers Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
abstract contract DirectBuyModifiers is IDirectBuyFacet, Listing {

    /// @notice Check if DirectBuy can be purchase
    /// @dev Revert with:
    ///     DirectBuyNotStarted
    ///     DirectBuyFinished
    /// @param _directBuyId the ID of DirectBuy
    modifier purchasable(uint256 _directBuyId) override {
        uint256 projectId = s.directBuys[_directBuyId].projectId;
        _purchasable( _directBuyId, projectId);
        if (s.directBuys[_directBuyId].startTime > block.timestamp) revert  DirectBuyNotStarted(); // solhint-disable-line not-rely-on-time
        if (s.directBuys[_directBuyId].endTime < block.timestamp) revert  DirectBuyFinished(); // solhint-disable-line not-rely-on-time
        _;
    }

    /// @notice Check if an DirectBuy exits with ID _directBuyId
    /// @dev Revert QueryNonExistentDirectBuy
    /// @param _directBuyId The Id of DirectBuy
    modifier exists(uint256 _directBuyId) override {
        if (_directBuyId == 0 || _directBuyId > s.directBuysCount) revert QueryNonExistentDirectBuy();
        _;
    }

    /// @notice Check if an DirectBuy is active with ID _directBuyId
    /// @dev Revert DirectBuyNotActive
    /// @param _directBuyId The Id of DirectBuy
    modifier isActive(uint256 _directBuyId) override {
        if (!s.directBuys[_directBuyId].active) revert DirectBuyNotActive();
        _;
    }

    // @notice Check if an DirectBuy is active with ID _directBuyId
    /// @dev Revert DirectBuyNotActive
    /// @param _directBuyId The Id of DirectBuy
    modifier hasStockAvailable(uint256 _directBuyId) override {
        if (!( (s.directBuys[_directBuyId].stock - s.directBuys[_directBuyId].purchased) > 0)) revert NoStockLeft();
        _;
    }

    // @notice Check if _date is 
    /// @dev Revert StartTimeBeforeCurrentTime
    /// @param _date The Id of DirectBuy
    modifier afterDate(uint256 _date) {
        if (_date < block.timestamp) revert StartTimeBeforeCurrentTime(); // solhint-disable-line not-rely-on-time
        _;
    }

    // @notice Check if _newStock is greater than DirectBuy purchased
    /// @dev Revert StockUnderPurchase
    /// @param _directBuyId The Id of DirectBuy
    /// @param _newStock The new Stock
    modifier checkStockOverPurchase(uint256 _directBuyId, uint256 _newStock) {
        if (_newStock < s.directBuys[_directBuyId].purchased) revert StockUnderPurchase(); 
        _;
    }
    

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

import {DirectBuyStorage} from "./DirectBuyStorage.sol";

interface IDirectBuyFacet {
    error QueryNonExistentDirectBuy();
    error DirectBuyNotActive();
    error DirectBuyAlreadyInState();
    error StartTimeBeforeCurrentTime();
    error StockUnderPurchase();
    error DirectBuyFinished();
    error DirectBuyNotStarted();
    

    function directBuyHasStockById(uint256 id_)
        external
        view
        returns (bool);

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