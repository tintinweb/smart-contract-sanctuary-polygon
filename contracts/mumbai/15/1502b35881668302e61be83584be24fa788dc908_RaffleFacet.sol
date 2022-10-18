// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {RaffleStorage} from "./RaffleStorage.sol";
import {RaffleModifiers} from "./RaffleModifiers.sol";
import {IRandomFacet} from "../Random/IRandomFacet.sol";
import {IFundManagerFacet} from "../FundManager/IFundManagerFacet.sol";

/// @title Raffle Facet
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract RaffleFacet is RaffleModifiers {

    /// @notice Execute a Raffle
    /// @dev revert RaffleFinished
    ///      revert ProjectNotActive
    ///      revert QueryNonExistentRaffle
    ///      revert Not Owner
    /// @param _raffleId the Id of raffle to do
    /// @param seed a seed to random
    /// @return winners array of address
    function pickWinners(uint256 _raffleId, uint256 seed) 
        external 
        isRaffled( _raffleId)
    returns (address[] memory winners)
    {
        address[] memory participants = s.raffles[_raffleId].participants;
        uint256 length = s.raffles[_raffleId].maxWinners;
        bool random = true;
        
        if(participants.length <= length) {
            length = participants.length;
            random = false;
        }
        
        winners = _generateWinners( _raffleId,  length,  seed,  random,  participants);

        s.raffles[_raffleId].winners = winners;
        s.raffles[_raffleId].raffled = true;
    }

    /// @notice Purchase a Raffle with ID _raffleId
    /// @dev revert RaffleFinished
    ///      revert EndTimeNotReached
    ///      revert ProjectNotActive
    ///      revert QueryNonActiveRaffle
    ///      revert QueryNonExistentRaffle
    ///      revert Not Owner
    /// @param _raffleId the raffle to purchase
    /// @return true on success, revert othercase
    function purchaseRaffle( uint256 _raffleId)  external
       purchasable( _raffleId)
       returns (bool)
    {
        uint256 raffleBalance = s.userInventory[msg.sender].raffleBalance[_raffleId];
        s.raffles[_raffleId].purchased++;
        s.raffles[_raffleId].participants.push(msg.sender);
        if (raffleBalance < 1) {
            s.userInventory[msg.sender].raffleIds.push(_raffleId);
        }
        s.userInventory[msg.sender].raffleBalance[_raffleId]++;
        _fundManagerFacet().charge(s.raffles[_raffleId].price, msg.sender);
        return true;
    }

    function createRaffle(
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _projectId,
        string memory _metadataUrl,
        bool _active,
        uint256 _maxWinners
    ) external 
        projectIsActive( _projectId)
        checkNonZeroStock( _stock)
        startTimeBeforeEndTime( _startTime, _endTime)
        checkNonZeroMaxWinners(_maxWinners)
        returns (uint256)
    {
        if(_maxWinners > _stock) revert StockLessThanMaxWinners();
        s.rafflesCount += 1;
        s.projects[_projectId].raffleCount += 1;
        s.raffles[s.rafflesCount].id = s.rafflesCount;
        s.raffles[s.rafflesCount].stock = _stock;
        s.raffles[s.rafflesCount].price = _price;
        s.raffles[s.rafflesCount].startTime = _startTime;
        s.raffles[s.rafflesCount].endTime = _endTime;
        s.raffles[s.rafflesCount].projectId = _projectId;
        s.raffles[s.rafflesCount].raffleMetadataUrl = _metadataUrl;
        s.raffles[s.rafflesCount].active = _active;
        s.raffles[s.rafflesCount].maxWinners = _maxWinners;
        return s.rafflesCount;
    }

    function updateRaffle(
        uint256 _raffleId,
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _projectId,
        string memory _metadataUrl,
        bool _active,
        uint256 _maxWinners
    ) external 
        exists(_raffleId)
        projectIsActive( _projectId)
        //checkStockGreaterPurchased( _raffleId, _stock)
        startTimeBeforeEndTime( _startTime, _endTime)  
    {
        if (_stock < s.raffles[_raffleId].purchased) revert PurchasedGreaterStock();
        s.raffles[_raffleId].stock = _stock;
        s.raffles[_raffleId].price = _price;
        s.raffles[_raffleId].startTime = _startTime;
        s.raffles[_raffleId].endTime = _endTime;
        s.raffles[_raffleId].projectId = _projectId;
        s.raffles[_raffleId].raffleMetadataUrl = _metadataUrl;
        s.raffles[_raffleId].active = _active;
        s.raffles[s.rafflesCount].maxWinners = _maxWinners;
    }

    function getAllRaffles() external view returns (RaffleStorage[] memory _raffles) {
        _raffles = new RaffleStorage[](
            s.rafflesCount
        );
        for (uint256 i = 0; i < s.rafflesCount; i++) {
            _raffles[i] = s.raffles[i+1];
        }
    }

    /// @notice Return all the allowlist of a projectId_
    /// @dev Explain to a developer any extra details
    /// @param _projectId The category to gets the projects
    /// @return Array of RaffleStorage
    function getRafflesForProject(uint256 _projectId) 
        external
        view
        returns (RaffleStorage[] memory) 
    {
        if (!(_projectId > 0 && _projectId <= s.projectsCount)) revert QueryNonExistentProject();

        RaffleStorage[] memory _raffles = new RaffleStorage[](
            s.projects[_projectId].raffleCount
        );
        uint256 j = 0;

        for (uint256 i = 1; i <= s.rafflesCount; i++) {
            if (_projectId ==  s.raffles[i].projectId) {
                _raffles[j] = s.raffles[i];
                j++;
            }
                
        }

        return _raffles;
    }

    function getRaffleById(uint256 _raffleId)
        external
        view
        exists(_raffleId)
        returns (
            RaffleStorage memory
        )
    {
        return s.raffles[_raffleId];
    }

    function raffleHasStockById(uint256 _raffleId)
        public
        view
        exists(_raffleId)
        returns (bool)
    {
        return s.raffles[_raffleId].stock > 0;
    }

    function _generateWinners(uint256 _raffleId, uint256 length, uint256 seed, bool random, address[] memory participants) 
        private 
        returns (address[] memory winners) 
    {
        s.raffles[_raffleId].winnersCount = 0;
        uint256 projectId = s.raffles[_raffleId].projectId;
        address[] memory winnersTemp = new address[](length);
       
        for (uint256 index = 0; index < length; index++) {
            address winner;

            if(random) {
                winner = participants[_randomFacet().random(_raffleId,seed+index) % length];
            } else {
                winner = participants[index];
            }
            
            uint256 projectBalance = s.userInventory[winner].projectBalance[projectId];

            if ( !(s.users[winner].frozen || s.rafflesWinners[_raffleId][winner] || projectBalance >= s.projects[projectId].maxPerWallet)) {
                _addToUserInventory(winner, _raffleId, projectId);
                s.rafflesWinners[_raffleId][winner] = true;
                winnersTemp[s.raffles[_raffleId].winnersCount] = winner;
                s.raffles[_raffleId].winnersCount++;
            } 
        }

        winners = new address[](s.raffles[_raffleId].winnersCount);
        for (uint256 index = 0; index < s.raffles[_raffleId].winnersCount; index++) {
            winners[index] = winnersTemp[index];
            s.rafflesWinners[_raffleId][winnersTemp[index]] = false;
        }
    }

    function _addToUserInventory(address _user, uint256 _raffleId, uint256 projectId ) private {
        uint256 raffleWonBalance = s.userInventory[_user].raffleWonBalance[_raffleId];

        if (raffleWonBalance < 1) {
            s.userInventory[_user].raffleWonIds.push(_raffleId);
        }
        s.userInventory[_user].raffleWonBalance[_raffleId]++;
        s.userInventory[_user].projectBalance[projectId]++;
    }

    function _randomFacet() private view returns (IRandomFacet randomFacet) {
        randomFacet = IRandomFacet(address(this));
    }

    function _fundManagerFacet() private view returns (IFundManagerFacet fundManagerFacet) {
        fundManagerFacet = IFundManagerFacet(address(this));
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IRaffleFacet} from "./IRaffleFacet.sol";
import {Listing} from "../../base/Listing.sol";

contract RaffleModifiers is IRaffleFacet, Listing {

    modifier checkNonZeroMaxWinners(uint256 maxWinners) {
        if (maxWinners < 1) revert CreateWithZeroMaxWinners();
        _;
    }

    modifier exists(uint256 raffleId_) override {
        if(raffleId_ == 0 || raffleId_ > s.rafflesCount) revert QueryNonExistentRaffle();

        _;
    }

    modifier isActive(uint256 raffleId_) override {
        if(!s.raffles[raffleId_].active) revert QueryNonActiveRaffle();
        _;
    }

    modifier hasStockAvailable(uint256 raffleId_) override {
        if( !(s.raffles[raffleId_].stock > s.raffles[raffleId_].purchased)) revert NoStockLeft();
        _;
    }

    modifier purchasable(uint256 raffleId_) override {
        uint256 projectId = s.raffles[raffleId_].projectId;
        _purchasable( raffleId_, s.raffles[raffleId_].projectId);
        if (s.raffles[raffleId_].raffled) revert RaffleFinished();
        if (s.raffles[raffleId_].endTime < block.timestamp) revert  RaffleFinished(); // solhint-disable-line not-rely-on-time
        if (s.raffles[raffleId_].startTime > block.timestamp) revert  RaffleNotStarted(); // solhint-disable-line not-rely-on-time
        _;
    }

    modifier isRaffled(uint256 raffleId_)  {
        _raffable( raffleId_, s.raffles[raffleId_].projectId);
        if (s.raffles[raffleId_].raffled) revert RaffleFinished();
        _;
    }

    /// @notice Check that stock is NOT zero 
    /// @dev revert with StockZero
    modifier checkStockGreaterPurchased(uint256 raffleId_, uint256 stock_) {
        if (stock_ < s.raffles[raffleId_].purchased) revert PurchasedGreaterStock();
        _;
    }

    function _raffable(uint256 id_, uint256 projectId_)
        public
        view
        exists( id_)
        projectIsActive( projectId_)
    {
        if(s.users[msg.sender].frozen) revert UserIsFrozen();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {RandomStorage} from "./RandomStorage.sol";

interface IRandomFacet {

    function random(uint256 _raffleId, uint256 count) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IFundManagerFacet {
   error CollectorNotSet();
   error TxFailed();
   error ZeroAddress();

   function charge(uint256 amount, address buyer) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IRaffleFacet {
    /**
        RAFFLES
    */
    error QueryNonExistentRaffle();
    error QueryNonActiveRaffle();
    error RaffleFinished();
    error RaffleNotStarted();
    error EndTimeNotReached();
    error CreateWithZeroMaxWinners();
    error StockLessThanMaxWinners();
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

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RandomStorage {
    
    bool active;
   
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

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {RaffleStorage} from "../facets/Raffle/RaffleStorage.sol";
import {ProjectStorage} from "../facets/Project/ProjectStorage.sol";
import {AllowlistStorage} from "../facets/Allowlist/AllowlistStorage.sol";
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
    uint256 allowlistsCount;
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
    // listing id => Allowlist
    mapping(uint256 => AllowlistStorage) allowlists; 
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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
    uint256 allowlistsCount;
    uint256 raffleCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct AllowlistStorage {
    uint256 id;
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

struct UserInventoryStorage {
    uint256[] allowlistsIds;
    uint256[] raffleIds;
    uint256[] raffleWonIds;
    // project id => count of allowlist + raffle won
    mapping(uint256 => uint256) projectBalance;
    // allowlist id => count of allowlist 
    mapping(uint256 => uint256) allowlistsBalance;
    // raffke id => count of raffle 
    mapping(uint256 => uint256) raffleBalance;
    // raffke id => count of raffle won
    mapping(uint256 => uint256) raffleWonBalance;
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