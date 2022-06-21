// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Utils.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";
import {MERC1155 as PremiumPass} from "./rewards/MERC1155.sol";

/** @dev handle all level data together;
xpToCompleteLevel: xp required to go from level x->x+1
freeReward: free reward given at level x
premiumReward: premium reward given at level x
*/
struct LevelInfo {
    uint256 xpToCompleteLevel;
    ERC1155Reward freeReward;
    ERC1155Reward premiumReward;
}

/** @dev
xp: how much xp the user has
claimedPremium: has the user claimed a premium reward,   
claimed: has user claimed reward for given level and prem status
*/
struct User {
    uint256 xp;
    bool claimedPremium;
    mapping(uint256 => mapping(bool => bool)) claimed;
}

error IncorrectSeasonDetails(address admin);
error NotAtLevelNeededToClaimReward(
    uint256 seasonId,
    address user,
    uint256 actualLevel,
    uint256 requiredLevel
);
error NeedPremiumPassToClaimPremiumReward(uint256 seasonId, address user);
error RewardAlreadyClaimed(uint256 seasonId, address user);

/**
@notice Pass contract representing a battle pass as used in games
@dev 
1. starts at level 0 for a user, 
2. can have multiple seasons, 
3. deploy 1 per creator
4. mint id=season id to giver premium pass for a particular season to a user
5. pass rewards are usually lootboxes
@author rayquaza
*/
contract Pass is PremiumPass, ReentrancyGuard, Utils {
    event NewSeason(address indexed admin, uint256 seasonId);

    /// @dev upgradeable by the admin
    address public oracleAddress;
    /// @dev current season id
    uint256 public seasonId;

    /// @dev seasonId->level->LevelInfo
    mapping(uint256 => mapping(uint256 => LevelInfo)) public seasonInfo;
    /// @dev seasonId->max lv in season
    mapping(uint256 => uint256) public maxLevelInSeason;
    /// @dev user->seasonId->User, store user info for each season
    mapping(address => mapping(uint256 => User)) public userInfo;

    /** 
    @dev recipe is given the minter role because it can mint/burn a prem pass based on recipes,
    msg.sender is admin, 
    msg.sender, pass contract, recipe have the minter role
    */
    constructor(string memory uri, address recipe) PremiumPass(uri, address(this), recipe) {
        oracleAddress = 0x744C907a37f4f595605E6FdE8cb5C3A022594D0a;
        _grantRole(ORACLE_ROLE, oracleAddress);
    }

    /*//////////////////////////////////////////////////////////////////////
                        NEW SEASONS AND ORACLE (ADMIN)
    //////////////////////////////////////////////////////////////////////*/

    /**
     @notice create a new season
     @dev 
     @param maxLevel max levels in season, maxLevel = 5 means last reward is given out at level 5
     u could technically remove this param and have a function to calculate this: a loop that breaks when it sees a 0 xptocompletelevel;
     refer lootbox, left as a todo for later
     @param levelInfo info about each level, levelInfo[0] corresponds to info on level 0
     @return current season id
     */
    function newSeason(uint256 maxLevel, LevelInfo[] calldata levelInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        seasonId++;
        maxLevelInSeason[seasonId] = maxLevel;

        /**
        checks to prevent FE/scripting mistakes
        1. error if levelInfo does not have info on each level, therefore needs size to be equal to maxLevel+1 since 0 indexed
        2. cannot have xpToCompleteLevel to be non zero at max level since that would mean that there is another level
        3. max level cannot be 0
         */
        if (
            maxLevel + 1 != levelInfo.length ||
            levelInfo[maxLevel].xpToCompleteLevel != 0 ||
            maxLevel == 0
        ) revert IncorrectSeasonDetails(_msgSender());

        for (uint256 x; x <= maxLevel; x++) {
            seasonInfo[seasonId][x].xpToCompleteLevel = levelInfo[x].xpToCompleteLevel;
            addReward(seasonId, x, false, levelInfo[x].freeReward);
            addReward(seasonId, x, true, levelInfo[x].premiumReward);
        }
        emit NewSeason(_msgSender(), seasonId);
        return seasonId;
    }

    ///@dev can add reward after season has been created
    /// if you're passing the 0 address then it means that u dont want to give anything at that level
    function addReward(
        uint256 _seasonId,
        uint256 _level,
        bool premium,
        ERC1155Reward calldata bundle
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(0) == bundle.token) return;
        deposit(bundle.token);
        if (premium) {
            seasonInfo[_seasonId][_level].premiumReward = bundle;
        } else {
            seasonInfo[_seasonId][_level].freeReward = bundle;
        }
    }

    ///@dev can set xp after season has been created
    function setXp(
        uint256 _seasonId,
        uint256 _level,
        uint256 xp
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        seasonInfo[_seasonId][_level].xpToCompleteLevel = xp;
    }

    ///@dev give xp to user, only callable from oracle
    function giveXp(
        uint256 _seasonId,
        uint256 xp,
        address user
    ) external onlyRole(ORACLE_ROLE) {
        userInfo[user][_seasonId].xp += xp;
    }

    function changeOracle(address newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ORACLE_ROLE, oracleAddress);
        oracleAddress = newOracle;
        _grantRole(ORACLE_ROLE, oracleAddress);
    }

    /*//////////////////////////////////////////////////////////////////////
                                USER
    //////////////////////////////////////////////////////////////////////*/

    ///@dev break when xpToCompleteLevel is 0 since that means that the user is at last level
    function level(address user, uint256 _seasonId) public view returns (uint256 userLevel) {
        uint256 currentXp = userInfo[user][_seasonId].xp;
        uint256 xpToNext;
        for (uint256 x; x <= maxLevelInSeason[_seasonId]; x++) {
            xpToNext += seasonInfo[_seasonId][x].xpToCompleteLevel;
            if (xpToNext > currentXp || seasonInfo[_seasonId][x].xpToCompleteLevel == 0) break;
            userLevel++;
        }
        return userLevel;
    }

    /// @dev refer to claim reward to understand why this is the way it is
    function isUserPremium(address user, uint256 _seasonId) public view returns (bool) {
        if (userInfo[user][_seasonId].claimedPremium || balanceOf[user][_seasonId] >= 1) {
            return true;
        } else {
            return false;
        }
    }

    ///@dev is reward claimed by user for given season id, level and prem status
    function isRewardClaimed(
        address user,
        uint256 _seasonId,
        uint256 _level,
        bool premium
    ) public view returns (bool) {
        return userInfo[user][_seasonId].claimed[_level][premium];
    }

    /**
    @dev
    1. revert if trying to claim reward for level at which the user is not
    2. revert if reward is already claimed
    3. revert if trying to redeem premium reward and user is not eligible for it
    3. prem reward:
     - in order to mint a premium pass for a given season, the mint id MUST be equal to the seasonId
    - a user has a premium status if for a given seasonId, user.claimedPremium == true || balanceOf(user) >= 1,
    - this is because when the user is minted a premium pass for a season, they are free to buy/sell or claim it for a premium reward,
    - RESTRICTIONS: it is not allowed for a user to claim a premium reward for a season and then sell the pass.
        - user.claimedPremium == false and balanceOf(user) == 0, not eligible to claim premium reward
        - user.claimedPremium == false and balanceOf(user) >= 1, eligible to claim prem reward. burn pass when prem reward is claimed and set premiumClaimed = true
        - user.claimedPremium == true and balanceOf(user) >= 0; redeem prem reward normally
     */
    function claimReward(
        uint256 _seasonId,
        address user,
        uint256 _level,
        bool premium
    ) external nonReentrant {
        if (level(user, _seasonId) < _level) {
            revert NotAtLevelNeededToClaimReward(_seasonId, user, level(user, _seasonId), _level);
        }

        User storage tempUserInfo = userInfo[user][_seasonId];

        if (tempUserInfo.claimed[_level][premium]) {
            revert RewardAlreadyClaimed(_seasonId, user);
        }
        tempUserInfo.claimed[_level][premium] = true;

        if (premium) {
            if (isUserPremium(user, _seasonId)) {
                if (!tempUserInfo.claimedPremium) {
                    tempUserInfo.claimedPremium = true;
                    _burn(user, _seasonId, 1);
                }
                withdrawERC1155(seasonInfo[_seasonId][_level].premiumReward, user);
            } else {
                revert NeedPremiumPassToClaimPremiumReward(_seasonId, user);
            }
        } else {
            withdrawERC1155(seasonInfo[_seasonId][_level].freeReward, user);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./rewards/interfaces/IMERC20.sol";
import "./rewards/interfaces/IMERC721.sol";
import "./rewards/interfaces/IMERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

/// @dev constants used throughout our contracts
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

error TokenNotGivenMinterRole(address minter, address token);
/**
@dev
token: address of MERC20
qty: how much to give out
 */
struct ERC20Reward {
    address token;
    uint256 qty;
}

/**
@dev
token: address of MERC721
id: (IMPORTANT)what id to mint, handle vvv carefully, vv dependent on implementation
if using autoid, then id will be passed to mint function but ignored
else id will be minted, however, only the first person to mint it will be able to redeem it regardless of bundle qty
therefore, we will always use auto id
However, this becomes imp for crafting recipes u might want to burn a specific id to create one off recipes
 */
struct ERC721Reward {
    address token;
    uint256 id;
}

/**
@dev ignoring batch mint since not needed rn
token: address of MERC1155
qty: how much to give
id: what id to give
 */
struct ERC1155Reward {
    address token;
    uint256 qty;
    uint256 id;
}

///@dev helpers for deposits and withdrawls
abstract contract Utils {
    function deposit(address token) internal view {
        if (!IAccessControl(token).hasRole(MINTER_ROLE, address(this))) {
            revert TokenNotGivenMinterRole(address(this), token);
        }
    }

    function withdrawERC20(ERC20Reward memory reward, address user) internal {
        IMERC20(reward.token).mint(user, reward.qty);
    }

    function withdrawERC721(ERC721Reward memory reward, address user) internal {
        IMERC721(reward.token).mint(user);
    }

    function withdrawERC1155(ERC1155Reward memory reward, address user) internal {
        IMERC1155(reward.token).mint(user, reward.id, reward.qty, "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC1155.sol";
import "lib/solmate/src/tokens/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

///@dev default 1155 token
contract MERC1155 is ERC1155, AccessControl, IMERC1155 {
    string public tokenURI;

    ///@dev give minter role to sender, pass/lootbox and recipe
    constructor(
        string memory _uri,
        address passOrLootbox,
        address recipe
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
        tokenURI = _uri;
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(MINTER_ROLE) {
        _burn(from, id, amount);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    URI
    //////////////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(tokenURI, "/", Strings.toString(id), ".json");
    }

    function setURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC20 is IAccessControl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC721 is IAccessControl {
    function mint(address to) external;

    function burn(address from, uint256 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IMERC1155 is IAccessControl {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity >=0.8.0;

import "./MERC1155.sol";

error TicketIdDoesNotExist(address user, string ticketId);

enum Status {
    REDEEMED,
    PROCESSING,
    REJECTED
}

struct Redemption {
    string ticketId;
    uint256 itemId;
    Status status;
}

// hypothesis: will increase creator accountability
contract Redeemable is MERC1155 {
    ///@dev u can see for a given addresses all the redeemed items
    mapping(address => Redemption[]) public redeemed;

    constructor(
        string memory uri,
        address passOrLootbox,
        address recipe
    ) MERC1155(uri, passOrLootbox, recipe) {}

    ///@dev will revert if user does not own id; called by web3-service when item is redeemed
    function redeemReward(
        string calldata ticketId,
        address user,
        uint256 id
    ) external {
        burn(user, id, 1);
        redeemed[user].push(Redemption(ticketId, id, Status.PROCESSING));
    }

    ///@dev called when redemption process is either fullfilled or rejected
    function updateStatus(
        address user,
        string calldata ticketId,
        Status status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Redemption[] storage redeemedByUser = redeemed[user];
        bool found = false;
        for (uint256 x; x < redeemedByUser.length; x++) {
            if (
                keccak256(abi.encodePacked(redeemedByUser[x].ticketId)) ==
                keccak256(abi.encodePacked(ticketId))
            ) {
                redeemedByUser[x].status = status;
                found = true;
            }
        }
        if (!found) revert TicketIdDoesNotExist(user, ticketId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MERC1155.sol";
import "../Utils.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";
import "lib/chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

///@dev rarity ranges means that if one token bundle added has 0-1, means it has a 10% prob of giving out, 0-10, random number is from 0-9
//am able to copy a list of structs in a struct to storage. but am not able to add that thing to another list
struct LootboxBundle {
    uint256[2] rarityRange;
    ERC20Reward[] erc20s;
    ERC721Reward[] erc721s;
    ERC1155Reward[] erc1155s;
}

error HowDidYouGetHere(uint256 lootboxId, address user, uint256 randomWord);
error ProbabilityRangeIncorrect(address admin);

//for matic mainnetØ
contract Lootbox is VRFConsumerBaseV2, MERC1155, ReentrancyGuard, Utils {
    event NewLootbox(address indexed admin, uint256 indexed lootboxId);
    event LootboxOpened(address indexed user, uint256 indexed lootboxId, uint256 index);
    event RequestedRandomWords(address indexed user, uint256 indexed id, uint256 requestId);

    uint256 public lootboxId;
    mapping(uint256 => LootboxBundle[]) internal rewards;

    uint64 public subscriptionId;
    VRFCoordinatorV2Interface internal coordinator;

    //optimization: use bytes to encode both
    mapping(uint256 => address) public requestIdToUser;
    mapping(uint256 => uint256) public requestIdToLootboxId;
    mapping(uint256 => uint256) public requestIdToIndexOpened;

    uint16 public constant requestConfirmations = 3;
    uint32 public constant numWords = 1;
    uint32 public callbackGasLimit = 10_000_000;

    // address public constant vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    //200gwei hash
    // bytes32 public constant keyHash =
    //     0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
    bytes32 public keyHash;

    ///@dev create and topup subscription from dashboard, adds as consumer
    ///@dev pass can mint it, recipe can do something w it too
    constructor(
        string memory uri,
        address pass,
        address recipe,
        uint64 subId,
        address vrfCoordinator,
        bytes32 _keyHash
    ) MERC1155(uri, pass, recipe) VRFConsumerBaseV2(vrfCoordinator) {
        subscriptionId = subId;
        keyHash = _keyHash;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function adjustCallBackGasLimit(uint32 newLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callbackGasLimit = newLimit;
    }

    function newLootbox(LootboxBundle[] calldata bundles)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        lootboxId++;

        uint256 cumulativeProbability;
        for (uint256 x = 0; x < bundles.length; x++) {
            for (uint256 y; y < bundles[x].erc20s.length; y++) {
                deposit(bundles[x].erc20s[y].token);
            }
            for (uint256 y; y < bundles[x].erc721s.length; y++) {
                deposit(bundles[x].erc721s[y].token);
            }
            for (uint256 y; y < bundles[x].erc1155s.length; y++) {
                deposit(bundles[x].erc1155s[y].token);
            }
            cumulativeProbability += (bundles[x].rarityRange[1] - bundles[x].rarityRange[0]);
            rewards[lootboxId].push(bundles[x]);
        }

        //probabilities should add to 1
        if (cumulativeProbability != 10 || bundles[bundles.length - 1].rarityRange[1] != 10)
            revert ProbabilityRangeIncorrect(_msgSender());

        emit NewLootbox(_msgSender(), lootboxId);
        return lootboxId;
    }

    /*//////////////////////////////////////////////////////////////////////
                            OPEN A LOOTBOX
    //////////////////////////////////////////////////////////////////////*/

    function openLootbox(uint256 id, address user) public returns (uint256 requestId) {
        _burn(user, id, 1);
        requestId = requestRandomWords();
        requestIdToUser[requestId] = user;
        requestIdToLootboxId[requestId] = id;
        emit RequestedRandomWords(user, id, requestId);
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
        nonReentrant
    {
        uint256 id = requestIdToLootboxId[requestId];
        address user = requestIdToUser[requestId];
        uint256 bundleRewardIdx = calculateIndexFromRandom(id, randomWords[0], user);
        requestIdToIndexOpened[requestId] = bundleRewardIdx;
        LootboxBundle memory bundle = rewards[id][bundleRewardIdx];
        for (uint256 y; y < bundle.erc20s.length; y++) {
            withdrawERC20(bundle.erc20s[y], user);
        }
        for (uint256 y; y < bundle.erc721s.length; y++) {
            withdrawERC721(bundle.erc721s[y], user);
        }
        for (uint256 y; y < bundle.erc1155s.length; y++) {
            withdrawERC1155(bundle.erc1155s[y], user);
        }
        emit LootboxOpened(user, id, bundleRewardIdx);
    }

    function calculateIndexFromRandom(
        uint256 id,
        uint256 randomWord,
        address user
    ) public view returns (uint256) {
        //0-9
        uint256 rangeNumber = randomWord % 10;
        LootboxBundle[] memory bundles = rewards[id];

        for (uint256 x; x < bundles.length; x++) {
            if (
                rangeNumber >= bundles[x].rarityRange[0] && rangeNumber < bundles[x].rarityRange[1]
            ) {
                return x;
            }
        }
        revert HowDidYouGetHere(id, user, randomWord);
    }

    function getLootboxBundleSize(uint256 id) public view returns (uint256) {
        return rewards[id].length;
    }

    function getLootboxBundle(uint256 id, uint256 index)
        public
        view
        returns (LootboxBundle memory)
    {
        return rewards[id][index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Utils.sol";
import "./rewards/MERC1155.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";

error RecipeNotActive(uint256 recipeId, address user);

struct Ingredients {
    ERC721Reward[] erc721s;
    ERC1155Reward[] erc1155s;
}

/** 
@notice a recipe is just a list of input and output tokens
a user that has all the input tokens required by a recipe can 'craft' new items
for ex: there exists a recipe that takes input token X and gives output token Y
- user wants item Y and has item X
- they 'craft' the recipe, i.e., their X token is burned and Y token is minted to them

You can also specify multiple qtys, ids of tokens
premium passes, lootbox,redeemable items, and recipe token itself can be in a recipe

Recipe is an MERC1155, so if u want to give someone the right to craft an item, right to create a recipe etc, you'll have to mint a recipe token to them
*/

contract Recipe is ReentrancyGuard, MERC1155, Utils {
    event Crafted(address indexed user, uint256 indexed recipeId);
    event NewRecipe(address indexed admin, uint256 recipeId);

    //current number of recipes created
    uint256 public recipeId;
    //since there is no primitve var, the getter will have nothing to return
    //but a custom defined getter says explicityly what to return, idk why the custom one works tho
    mapping(uint256 => Ingredients) internal inputIngredients;
    mapping(uint256 => Ingredients) internal outputIngredients;
    mapping(uint256 => bool) public isActive;

    ///@dev give minter role to this address
    ///cant give pass minter role here since one has to be deployed first
    constructor(string memory uri) MERC1155(uri, address(this), address(this)) {}

    function givePassMinterRole(address pass) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, pass);
    }

    function addRecipe(Ingredients calldata input, Ingredients calldata output)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        unchecked {
            recipeId++;
        }

        inputIngredients[recipeId] = input;
        outputIngredients[recipeId] = output;
        isActive[recipeId] = true;
        for (uint256 x; x < output.erc721s.length; x++) {
            deposit(output.erc721s[x].token);
        }
        for (uint256 x; x < output.erc1155s.length; x++) {
            deposit(output.erc1155s[x].token);
        }
        emit NewRecipe(_msgSender(), recipeId);
        return recipeId;
    }

    ///@dev revert if recipe is not active
    function craft(uint256 _recipeId) external nonReentrant {
        if (!isActive[_recipeId]) revert RecipeNotActive(_recipeId, _msgSender());
        burnIngredients(inputIngredients[_recipeId]);
        Ingredients memory output = outputIngredients[_recipeId];
        for (uint256 x; x < output.erc721s.length; x++) {
            withdrawERC721(output.erc721s[x], _msgSender());
        }
        for (uint256 x; x < output.erc1155s.length; x++) {
            withdrawERC1155(output.erc1155s[x], _msgSender());
        }
        emit Crafted(_msgSender(), _recipeId);
    }

    function toggleRecipe(uint256 _recipeId, bool toggle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isActive[_recipeId] = toggle;
    }

    function burnIngredients(Ingredients memory input) private {
        for (uint256 x; x < input.erc721s.length; x++) {
            IMERC721(input.erc721s[x].token).burn(_msgSender(), input.erc721s[x].id);
        }
        for (uint256 x; x < input.erc1155s.length; x++) {
            IMERC1155(input.erc1155s[x].token).burn(
                _msgSender(),
                input.erc1155s[x].id,
                input.erc1155s[x].qty
            );
        }
    }

    function getInputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return inputIngredients[_recipeId];
    }

    function getOutputIngredients(uint256 _recipeId) public view returns (Ingredients memory) {
        return outputIngredients[_recipeId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC721.sol";
import "lib/solmate/src/tokens/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

error NotOwnedByUser(address user, uint256 id);

/// @dev default ERC721 reward with metadata support and minting access control, extremely basic, customize on top of this
contract MERC721 is ERC721, AccessControl, IMERC721 {
    string public uri;
    uint256 public currentId;

    //minter role to recipe,sender and pass/lootbox ctr
    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        address passOrLootbox,
        address recipe
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
        uri = _uri;
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    ///@dev id can be used if current id isnt, implementation specific
    function mint(address _to) public onlyRole(MINTER_ROLE) {
        unchecked {
            currentId++;
        }
        _mint(_to, currentId);
    }

    function burn(address from, uint256 id) public onlyRole(MINTER_ROLE) {
        if (_ownerOf[id] != from) revert NotOwnedByUser(from, id);
        _burn(id);
    }

    /*//////////////////////////////////////////////////////////////////////
                                    URI 
    //////////////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(uri, "/", Strings.toString(id), ".json");
    }

    function setURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uri = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils.sol";
import "./interfaces/IMERC20.sol";
import "lib/solmate/src/tokens/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @dev ERC20 reward with minting access control, extremely basic, customize on top of this
contract MERC20 is ERC20, AccessControl, IMERC20 {
    // minter role to recipe and pass/lootbox ctr
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address passOrLootbox,
        address recipe
    ) ERC20(name, symbol, decimals) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, passOrLootbox);
        _grantRole(MINTER_ROLE, recipe);
    }

    /*//////////////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////////////*/

    /// @notice edit this contract according to req
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    //will underflow if not owned
    function burn(address from, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}