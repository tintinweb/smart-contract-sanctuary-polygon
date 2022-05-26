//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";


import "./libraries/UserLib.sol";
import "./libraries/CommonLib.sol";
import "./libraries/AchievementLib.sol";
import "./libraries/AchievementCommonLib.sol";
import "./base/NativeMetaTransaction.sol";

import "./interfaces/IPeeranhaUser.sol";


contract PeeranhaUser is IPeeranhaUser, Initializable, NativeMetaTransaction, AccessControlEnumerableUpgradeable {
    using UserLib for UserLib.UserCollection;
    using UserLib for UserLib.UserRatingCollection;
    using AchievementLib for AchievementLib.AchievementsContainer;

    bytes32 public constant PROTOCOL_ADMIN_ROLE = bytes32(keccak256("PROTOCOL_ADMIN_ROLE"));
    
    uint256 public constant COMMUNITY_ADMIN_ROLE = uint256(keccak256("COMMUNITY_ADMIN_ROLE"));
    uint256 public constant COMMUNITY_MODERATOR_ROLE = uint256(keccak256("COMMUNITY_MODERATOR_ROLE"));

    UserLib.UserContext userContext;

    function initialize() public initializer {
        __Peeranha_init();
    }
    
    function __Peeranha_init() public onlyInitializing {
        __AccessControlEnumerable_init();
        __Peeranha_init_unchained();
        __NativeMetaTransaction_init("PeeranhaUser");
    }

    function __Peeranha_init_unchained() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PROTOCOL_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(PROTOCOL_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override(ContextUpgradeable, NativeMetaTransaction)
        virtual
        view
        returns (address sender)
    {
        return NativeMetaTransaction._msgSender();
    }

    function setContractAddresses(address communityContractAddress, address contentContractAddress, address nftContractAddress, address tokenContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        userContext.peeranhaCommunity = IPeeranhaCommunity(communityContractAddress);
        userContext.peeranhaContent = IPeeranhaContent(contentContractAddress);
        userContext.peeranhaToken = IPeeranhaToken(tokenContractAddress);
        userContext.achievementsContainer.peeranhaNFT = IPeeranhaNFT(nftContractAddress);
    }

    /**
     * @dev List of communities where user has rewards in a given period.
     *
     * Requirements:
     *
     * - Must be an existing user and valid period.
     */
    function getUserRewardCommunities(address user, uint16 rewardPeriod) public override view returns(uint32[] memory) {
        return UserLib.getUserRewardCommunities(userContext, user, rewardPeriod);
    }

    /**
     * @dev Total reward shares for a given period.
     *
     * Requirements:
     *
     * - Must be a valid period.
     */
    function getPeriodRewardShares(uint16 period) public view override returns(RewardLib.PeriodRewardShares memory) {
        return UserLib.getPeriodRewardShares(userContext, period);
    }

    /**
     * @dev Signup for user account.
     *
     * Requirements:
     *
     * - Must be a new user.
     */
    function createUser(bytes32 ipfsHash) public override {
        UserLib.create(userContext.users, _msgSender(), ipfsHash);
    }

    /**
     * @dev Edit user profile.
     *
     * Requirements:
     *
     * - Must be an existing user.  
     */
    function updateUser(bytes32 ipfsHash) public override {
        address userAddress = _msgSender();
        UserLib.createIfDoesNotExist(userContext.users, userAddress);
        UserLib.update(userContext, userAddress, ipfsHash);
    }

    /**
     * @dev Follow community.
     *
     * Requirements:
     *
     * - Must be an community.  
     */
    function followCommunity(uint32 communityId) public override {
        onlyExistingAndNotFrozenCommunity(communityId);
        address userAddress = _msgSender();
        UserLib.createIfDoesNotExist(userContext.users, userAddress);
        UserLib.followCommunity(userContext, userAddress, communityId);
    }

    /**
     * @dev Unfollow community.
     *
     * Requirements:
     *
     * - Must be follow the community.  
     */
    function unfollowCommunity(uint32 communityId) public override {
        UserLib.unfollowCommunity(userContext, _msgSender(), communityId);
    }

    /**
     * @dev Get users count.
     */
    function getUsersCount() public view returns (uint256 count) {
        return userContext.users.getUsersCount();
    }

    /**
     * @dev Get user profile by index.
     *
     * Requirements:
     *
     * - Must be an existing user.
     */
    function getUserByIndex(uint256 index) public view returns (UserLib.User memory) {
        return userContext.users.getUserByIndex(index);
    }

    /**
     * @dev Get user profile by address.
     *
     * Requirements:
     *
     * - Must be an existing user.
     */
    function getUserByAddress(address addr) public view returns (UserLib.User memory) {
        return userContext.users.getUserByAddress(addr);
    }

    /**
     * @dev Get user rating in a given community.
     *
     * Requirements:
     *
     * - Must be an existing user and existing community.
     */
    function getUserRating(address addr, uint32 communityId) public view returns (int32) {
        return userContext.userRatingCollection.getUserRating(addr, communityId);
    }

    /**
     * @dev Check user existence.
     */
    function isUserExists(address addr) public view returns (bool) {
        return userContext.users.isExists(addr);
    }

    /**
     * @dev Check if user with given address exists.
     */
    function checkUser(address addr) public view {
        require(userContext.users.isExists(addr), "user_not_found");
    }

    /**
     * @dev Give admin permission.
     *
     * Requirements:
     *
     * - Sender must global administrator.
     * - Must be an existing user. 
     */
    function giveAdminPermission(address userAddr) public {
        // revokeRole checks that sender is role admin
        // TODO uniTest can do all action
        checkUser(userAddr);
        grantRole(PROTOCOL_ADMIN_ROLE, userAddr);
    }

    /**
     * @dev Revoke admin permission.
     *
     * Requirements:
     *
     * - Sender must global administrator.
     * - Must be an existing user. 
     */

     //should do something with AccessControlUpgradeable(revoke only for default admin)
    function revokeAdminPermission(address userAddr) public {
        // revokeRole checks that sender is role admin
        revokeRole(PROTOCOL_ADMIN_ROLE, userAddr);
    }

    /**
     * @dev Init community administrator permission.
     *
     * Requirements:
     *
     * - Sender must be global administrator.
     * - Must be an existing community.
     * - Must be an existing user. 
     */
    function initCommunityAdminPermission(address userAddr, uint32 communityId) public override {
        checkUser(userAddr);
        require(_msgSender() == address(userContext.peeranhaCommunity), "unauthorized");
        
        bytes32 communityAdminRole = getCommunityRole(COMMUNITY_ADMIN_ROLE, communityId);
        bytes32 communityModeratorRole = getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId);
        
        _setRoleAdmin(communityModeratorRole, communityAdminRole);
        _setRoleAdmin(communityAdminRole, PROTOCOL_ADMIN_ROLE);

        _grantRole(communityAdminRole, userAddr);
        _grantRole(communityModeratorRole, userAddr);
    }

    /**
     * @dev Give community administrator permission.
     *
     * Requirements:
     *
     * - Sender must be global administrator.
     * - Must be an existing community.
     * - Must be an existing user. 
     */
    function giveCommunityAdminPermission(address userAddr, uint32 communityId) public override {
        checkUser(userAddr);
        onlyExistingAndNotFrozenCommunity(communityId);
        checkHasRole(_msgSender(), UserLib.ActionRole.Admin, communityId);
        
        _grantRole(getCommunityRole(COMMUNITY_ADMIN_ROLE, communityId), userAddr);
        _grantRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), userAddr);
    }

    /**
     * @dev Give community moderator permission.
     *
     * Requirements:
     *
     * - Sender must be community or global administrator.
     * - Must be an existing community.
     * - Must be an existing user. 
     */
    function giveCommunityModeratorPermission(address userAddr, uint32 communityId) public {
        checkUser(userAddr);
        onlyExistingAndNotFrozenCommunity(communityId);
        checkHasRole(_msgSender(), UserLib.ActionRole.CommunityAdmin, communityId);
        _grantRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), userAddr);
    }

    /**
     * @dev Revoke community adminisrator permission.
     *
     * Requirements:
     *
     * - Sender must be global administrator.
     * - Must be an existing community.
     * - Must be an existing user. 
     */
    function revokeCommunityAdminPermission(address userAddr, uint32 communityId) public {
        onlyExistingAndNotFrozenCommunity(communityId);
        checkHasRole(_msgSender(), UserLib.ActionRole.Admin, communityId);
        _revokeRole(getCommunityRole(COMMUNITY_ADMIN_ROLE, communityId), userAddr);
    }

    /**
     * @dev Revoke community moderator permission.
     *
     * Requirements:
     *
     * - Sender must be community or global administrator.
     * - Must be an existing community.
     * - Must be an existing user.
     */
    function revokeCommunityModeratorPermission(address userAddr, uint32 communityId) public {
        onlyExistingAndNotFrozenCommunity(communityId);
        checkHasRole(_msgSender(), UserLib.ActionRole.AdminOrCommunityAdmin, communityId);
        _revokeRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), userAddr);
    }

    /**
     * @dev Create new achievement.
     *
     * Requirements:
     *
     * - Only admin can call the action.
     */
    function configureNewAchievement(
        uint64 maxCount,
        int64 lowerBound,
        string memory achievementURI,
        AchievementCommonLib.AchievementsType achievementsType
    )   
        external
    {
        checkHasRole(_msgSender(), UserLib.ActionRole.Admin, 0);
        userContext.achievementsContainer.configureNewAchievement(maxCount, lowerBound, achievementURI, achievementsType);
    }

    /**
     * @dev Get information about achievement.
     *
     * Requirements:
     *
     * - Must be an existing achievement.
     */
    function getAchievementConfig(uint64 achievementId) public view returns (AchievementLib.AchievementConfig memory) {
        return userContext.achievementsContainer.achievementsConfigs[achievementId];
    }

    /**
     * @dev Get user reward.
     *
     * Requirements:
     *
     * - Must be an existing community.
     * - Must be an existing user.
     */
    function getRatingToReward(address user, uint16 rewardPeriod, uint32 communityId) public view override returns(int32) {
        RewardLib.PeriodRating memory periodRating = userContext.userRatingCollection.communityRatingForUser[user].userPeriodRewards[rewardPeriod].periodRating[communityId];
        return CommonLib.toInt32FromUint256(periodRating.ratingToReward) - CommonLib.toInt32FromUint256(periodRating.penalty);
    }

    /**
     * @dev Get information about user rewards. (Rating to reward and penalty)
     *
     * Requirements:
     *
     * - Must be an existing community.
     * - Must be an existing user. 
     */
    function getPeriodRating(address user, uint16 rewardPeriod, uint32 communityId) public view returns(RewardLib.PeriodRating memory) {
        return userContext.userRatingCollection.communityRatingForUser[user].userPeriodRewards[rewardPeriod].periodRating[communityId];
    }

    /**
     * @dev Get information abour sum rating to reward all users
     */
    function getPeriodReward(uint16 rewardPeriod) public view returns(uint256) {
        return userContext.periodRewardContainer.periodRewardShares[rewardPeriod].totalRewardShares;
    }
    
    /**
     * @dev Change user rating
     *
     * Requirements:
     *
     * - Must be an existing community.
     * - Must be an existing user.
     * - Contract peeranhaContent must call action
     */
    function updateUserRating(address userAddr, int32 rating, uint32 communityId) public override {
        require(msg.sender == address(userContext.peeranhaContent), "internal_call_unauthorized");
        UserLib.updateUserRating(userContext, userAddr, rating, communityId);
    }

    /**
     * @dev Change users rating
     *
     * Requirements:
     *
     * - Must be an existing community.
     * - Must be an existing users.
     * - Only contract peeranhaContent can call the action
     */
    function updateUsersRating(UserLib.UserRatingChange[] memory usersRating, uint32 communityId) public override {
        require(msg.sender == address(userContext.peeranhaContent), "internal_call_unauthorized");
        UserLib.updateUsersRating(userContext, usersRating, communityId);
    }

    /**
     * @dev Check the role/energy/rating of the user to perform some action
     *
     * Requirements:
     *
     * - Must be an existing community.
     * - Only contract peeranhaContent and peeranhaCommunity can call the action
     */
    function checkActionRole(address actionCaller, address dataUser, uint32 communityId, UserLib.Action action, UserLib.ActionRole actionRole, bool createUserIfDoesNotExist) public override {
        require(msg.sender == address(userContext.peeranhaContent) || msg.sender == address(userContext.peeranhaCommunity), "internal_call_unauthorized");
        if (createUserIfDoesNotExist) {
            UserLib.createIfDoesNotExist(userContext.users, actionCaller);
        }

        if (hasModeratorRole(actionCaller, communityId)) {
            return;
        }
                
        checkHasRole(actionCaller, actionRole, communityId);
        UserLib.checkRatingAndEnergy(userContext, actionCaller, dataUser, communityId, action);
    }

    function getActiveUserPeriods(address userAddr) public view returns (uint16[] memory) {
        return userContext.userRatingCollection.communityRatingForUser[userAddr].rewardPeriods;
    }

    function checkHasRole(address actionCaller, UserLib.ActionRole actionRole, uint32 communityId) public override view {
        if (actionRole == UserLib.ActionRole.NONE) {
            return;
        } else if (actionRole == UserLib.ActionRole.Admin) {
            require(hasRole(PROTOCOL_ADMIN_ROLE, actionCaller), 
                "not_allowed_not_admin");
        
        } else if (actionRole == UserLib.ActionRole.AdminOrCommunityModerator) {
            require(hasRole(PROTOCOL_ADMIN_ROLE, actionCaller) ||
                (hasRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), actionCaller)), 
                "not_allowed_admin_or_comm_moderator");

        } else if (actionRole == UserLib.ActionRole.AdminOrCommunityAdmin) {
            require(hasRole(PROTOCOL_ADMIN_ROLE, actionCaller) || 
                (hasRole(getCommunityRole(COMMUNITY_ADMIN_ROLE, communityId), actionCaller)), 
                "not_allowed_admin_or_comm_admin");

        } else if (actionRole == UserLib.ActionRole.CommunityAdmin) {
            require((hasRole(getCommunityRole(COMMUNITY_ADMIN_ROLE, communityId), actionCaller)), 
                "not_allowed_not_comm_admin");

        } else if (actionRole == UserLib.ActionRole.CommunityModerator) {
            require((hasRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), actionCaller)), 
                "not_allowed_not_comm_moderator");
        }
    }
    
    function hasModeratorRole(
        address user,
        uint32 communityId
    ) 
        private view
        returns (bool) 
    {
        if ((hasRole(getCommunityRole(COMMUNITY_MODERATOR_ROLE, communityId), user) ||
            hasRole(PROTOCOL_ADMIN_ROLE, user))) return true;
        return false;
    }

    function getCommunityRole(uint256 role, uint32 communityId) private pure returns (bytes32) {
        return bytes32(role + communityId);
    }

    function onlyExistingAndNotFrozenCommunity(uint32 communityId) private {
        userContext.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(communityId);
    }

    // Used for unit tests
    function addUserRating(address userAddr, int32 rating, uint32 communityId) public {
        UserLib.updateUserRating(userContext, userAddr, rating, communityId);
    }

    // Used for unit tests
    function setEnergy(address userAddr, uint16 energy) public {
        userContext.users.getUserByAddress(userAddr).energy = energy;
    }

    /**
     * @dev Get informations about contract.
     *
     * - Get deployed time.
     * - Get period length
     *
    */
    // TODO deelete?
    function getContractInformation() external pure returns (uint256 startPeriodTime, uint256 periodLength) {
        return (RewardLib.START_PERIOD_TIME, RewardLib.PERIOD_LENGTH);
    }

    /**
     * @dev Get active users in period.
    */
    function getActiveUsersInPeriod(uint16 period) external view returns (address[] memory) {
        return userContext.periodRewardContainer.periodRewardShares[period].activeUsersInPeriod;
    }

    /**
     * @dev Get current period.
    */
    function getPeriod() external view returns (uint16) {
        return RewardLib.getPeriod(CommonLib.getTimestamp());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CommonLib.sol";
import "./RewardLib.sol";
import "./AchievementLib.sol";
import "./AchievementCommonLib.sol";
import "../interfaces/IPeeranhaToken.sol";
import "../interfaces/IPeeranhaCommunity.sol";
import "../interfaces/IPeeranhaContent.sol";


/// @title Users
/// @notice Provides information about registered user
/// @dev Users information is stored in the mapping on the main contract
library UserLib {
  int32 constant START_USER_RATING = 10;
  bytes32 constant DEFAULT_IPFS = bytes32(0xc09b19f65afd0df610c90ea00120bccd1fc1b8c6e7cdbe440376ee13e156a5bc);

  int16 constant MINIMUM_RATING = -300;
  int16 constant POST_QUESTION_ALLOWED = 0;
  int16 constant POST_REPLY_ALLOWED = 0;
  int16 constant POST_COMMENT_ALLOWED = 35;

  int16 constant UPVOTE_POST_ALLOWED = 35;
  int16 constant DOWNVOTE_POST_ALLOWED = 100;
  int16 constant UPVOTE_REPLY_ALLOWED = 35;
  int16 constant DOWNVOTE_REPLY_ALLOWED = 100;
  int16 constant VOTE_COMMENT_ALLOWED = 0;
  int16 constant CANCEL_VOTE = 0;

  int16 constant UPDATE_PROFILE_ALLOWED = 0;

  uint8 constant ENERGY_DOWNVOTE_QUESTION = 5;
  uint8 constant ENERGY_DOWNVOTE_ANSWER = 3;
  uint8 constant ENERGY_DOWNVOTE_COMMENT = 2;
  uint8 constant ENERGY_UPVOTE_QUESTION = 1;
  uint8 constant ENERGY_UPVOTE_ANSWER = 1;
  uint8 constant ENERGY_VOTE_COMMENT = 1;
  uint8 constant ENERGY_FORUM_VOTE_CANCEL = 1;
  uint8 constant ENERGY_POST_QUESTION = 10;
  uint8 constant ENERGY_POST_ANSWER = 6;
  uint8 constant ENERGY_POST_COMMENT = 4;
  uint8 constant ENERGY_MODIFY_ITEM = 2;
  uint8 constant ENERGY_DELETE_ITEM = 2;

  uint8 constant ENERGY_MARK_REPLY_AS_CORRECT = 1;
  uint8 constant ENERGY_UPDATE_PROFILE = 1;
  uint8 constant ENERGY_CREATE_TAG = 75;            // only Admin
  uint8 constant ENERGY_CREATE_COMMUNITY = 125;     // only admin
  uint8 constant ENERGY_FOLLOW_COMMUNITY = 1;
  uint8 constant ENERGY_REPORT_PROFILE = 5;         //
  uint8 constant ENERGY_REPORT_QUESTION = 3;        //
  uint8 constant ENERGY_REPORT_ANSWER = 2;          //
  uint8 constant ENERGY_REPORT_COMMENT = 1;         //

  struct User {
    CommonLib.IpfsHash ipfsDoc;
    uint16 energy;
    uint16 lastUpdatePeriod;
    uint32[] followedCommunities;
    bytes32[] roles;
  }

  struct UserRatingCollection {
    mapping(address => CommunityRatingForUser) communityRatingForUser;
  }

  struct CommunityRatingForUser {
    mapping(uint32 => UserRating) userRating;   //uint32 - community id
    uint16[] rewardPeriods; // periods when the rating was changed
    mapping(uint16 => RewardLib.UserPeriodRewards) userPeriodRewards; // period
  }

  struct UserRating {
    int32 rating;
    bool isActive;
  }

  struct DataUpdateUserRating {
    uint32 ratingToReward;
    uint32 penalty;
    int32 changeRating;
    int32 ratingToRewardChange;
  }


  /// users The mapping containing all users
  struct UserContext {
    UserLib.UserCollection users;     // rename to usersCollection
    UserLib.UserRatingCollection userRatingCollection;
    RewardLib.PeriodRewardContainer periodRewardContainer;
    AchievementLib.AchievementsContainer achievementsContainer;
    
    IPeeranhaToken peeranhaToken;
    IPeeranhaCommunity peeranhaCommunity;
    IPeeranhaContent peeranhaContent;
  }
  
  struct UserCollection {
    mapping(address => User) users;
    address[] userList;
  }

  struct UserRatingChange {
    address user;
    int32 rating;
  }

  struct UserDelegationCollection {
    mapping(address => uint) userDelegations;
    address delegateUser;
  }

  enum Action {
    NONE,
    PublicationPost,
    PublicationReply,
    PublicationComment,
    EditItem,
    DeleteItem,
    UpVotePost,
    DownVotePost,
    UpVoteReply,
    DownVoteReply,
    VoteComment,
    CancelVote,
    BestReply,
    UpdateProfile,
    FollowCommunity
  }

  enum ActionRole {
    NONE,
    Admin,
    AdminOrCommunityModerator,
    AdminOrCommunityAdmin,
    CommunityAdmin,
    CommunityModerator
  }

  event UserCreated(address indexed userAddress);
  event UserUpdated(address indexed userAddress);
  event FollowedCommunity(address indexed userAddress, uint32 indexed communityId);
  event UnfollowedCommunity(address indexed userAddress, uint32 indexed communityId);


  /// @notice Create new user info record
  /// @param self The mapping containing all users
  /// @param userAddress Address of the user to create 
  /// @param ipfsHash IPFS hash of document with user information
  function create(
    UserCollection storage self,
    address userAddress,
    bytes32 ipfsHash
  ) internal {
    require(self.users[userAddress].ipfsDoc.hash == bytes32(0x0), "user_exists");

    User storage user = self.users[userAddress];
    user.ipfsDoc.hash = ipfsHash;
    user.energy = getStatusEnergy();
    user.lastUpdatePeriod = RewardLib.getPeriod(CommonLib.getTimestamp());

    self.userList.push(userAddress);

    emit UserCreated(userAddress);
  }

  /// @notice Create new user info record
  /// @param self The mapping containing all users
  /// @param userAddress Address of the user to create 
  function createIfDoesNotExist(
    UserCollection storage self,
    address userAddress
  ) internal {
    if (!UserLib.isExists(self, userAddress)) {
      UserLib.create(self, userAddress, DEFAULT_IPFS);
    }
  }

  /// @notice Update new user info record
  /// @param userContext All information about users
  /// @param userAddress Address of the user to update
  /// @param ipfsHash IPFS hash of document with user information
  function update(
    UserContext storage userContext,
    address userAddress,
    bytes32 ipfsHash
  ) internal {
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.UpdateProfile
    );
    user.ipfsDoc.hash = ipfsHash;

    emit UserUpdated(userAddress);
  }

  /// @notice User follows community
  /// @param userContext All information about users
  /// @param userAddress Address of the user to update
  /// @param communityId User follows om this community
  function followCommunity(
    UserContext storage userContext,
    address userAddress,
    uint32 communityId
  ) internal {
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.FollowCommunity
    );

    bool isAdded;
    for (uint i; i < user.followedCommunities.length; i++) {
      require(user.followedCommunities[i] != communityId, "already_followed");

      if (user.followedCommunities[i] == 0 && !isAdded) {
        user.followedCommunities[i] = communityId;
        isAdded = true;
      }
    }
    if (!isAdded)
      user.followedCommunities.push(communityId);

    emit FollowedCommunity(userAddress, communityId);
  }

  /// @notice User unfollows community
  /// @param userContext The mapping containing all users
  /// @param userAddress Address of the user to update
  /// @param communityId User follows om this community
  function unfollowCommunity(
    UserContext storage userContext,
    address userAddress,
    uint32 communityId
  ) internal {
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.FollowCommunity
    );

    for (uint i; i < user.followedCommunities.length; i++) {
      if (user.followedCommunities[i] == communityId) {
        delete user.followedCommunities[i]; //method rewrite to 0
        
        emit UnfollowedCommunity(userAddress, communityId);
        return;
      }
    }
    revert("comm_not_followed");
  }

  /// @notice Get the number of users
  /// @param self The mapping containing all users
  function getUsersCount(UserCollection storage self) internal view returns (uint256 count) {
    return self.userList.length;
  }

  /// @notice Get user info by index
  /// @param self The mapping containing all users
  /// @param index Index of the user to get
  function getUserByIndex(UserCollection storage self, uint256 index) internal view returns (User storage) {
    address addr = self.userList[index];
    return self.users[addr];
  }

  /// @notice Get user info by address
  /// @param self The mapping containing all users
  /// @param addr Address of the user to get
  function getUserByAddress(UserCollection storage self, address addr) internal view returns (User storage) {
    User storage user = self.users[addr];
    require(user.ipfsDoc.hash != bytes32(0x0), "user_not_found");
    return user;
  }

  function getUserRating(UserRatingCollection storage self, address addr, uint32 communityId) internal view returns (int32) {
    int32 rating = self.communityRatingForUser[addr].userRating[communityId].rating;
    return rating;
  }

  /// @notice Check user existence
  /// @param self The mapping containing all users
  /// @param addr Address of the user to check
  function isExists(UserCollection storage self, address addr) internal view returns (bool) {
    return self.users[addr].ipfsDoc.hash != bytes32(0x0);
  }

  function updateUsersRating(UserLib.UserContext storage userContext, UserRatingChange[] memory usersRating, uint32 communityId) internal {
    for (uint i; i < usersRating.length; i++) {
      updateUserRating(userContext, usersRating[i].user, usersRating[i].rating, communityId);
    }
  }

  function updateUserRating(UserLib.UserContext storage userContext, address userAddr, int32 rating, uint32 communityId) internal {
    if (rating == 0) return;
    updateRatingBase(userContext, userAddr, rating, communityId);
  }

  function updateRatingBase(UserContext storage userContext, address userAddr, int32 rating, uint32 communityId) internal {
    uint16 currentPeriod = RewardLib.getPeriod(CommonLib.getTimestamp());
    
    CommunityRatingForUser storage userCommunityRating = userContext.userRatingCollection.communityRatingForUser[userAddr];
    // Initialize user rating in the community if this is the first rating change
    if (!userCommunityRating.userRating[communityId].isActive) {
      userCommunityRating.userRating[communityId].rating = START_USER_RATING;
      userCommunityRating.userRating[communityId].isActive = true;
    }

    uint256 pastPeriodsCount = userCommunityRating.rewardPeriods.length;
    RewardLib.PeriodRewardShares storage periodRewardShares = userContext.periodRewardContainer.periodRewardShares[currentPeriod];
    
    // If this is the first user rating change in any community
    if (pastPeriodsCount == 0 || userCommunityRating.rewardPeriods[pastPeriodsCount - 1] != currentPeriod) {
      periodRewardShares.activeUsersInPeriod.push(userAddr);
      userCommunityRating.rewardPeriods.push(currentPeriod);
    } else {  // rewrite
      pastPeriodsCount--;
    }

    RewardLib.UserPeriodRewards storage userPeriodRewards = userCommunityRating.userPeriodRewards[currentPeriod];
    RewardLib.PeriodRating storage userPeriodCommuntiyRating = userPeriodRewards.periodRating[communityId];

    // If this is the first user rating change in this period for current community
    if (!userPeriodCommuntiyRating.isActive) {
      userPeriodRewards.rewardCommunities.push(communityId);
    }

    uint16 previousPeriod;
    if(pastPeriodsCount > 0) {
      previousPeriod = userCommunityRating.rewardPeriods[pastPeriodsCount - 1];
    } else {
      // this means that there is no other previous period
      previousPeriod = currentPeriod;
    }

    updateUserPeriodRating(userContext, userCommunityRating, userAddr, rating, communityId, currentPeriod, previousPeriod);

    userCommunityRating.userRating[communityId].rating += rating;

    if (rating > 0) {
      AchievementLib.updateUserAchievements(userContext.achievementsContainer, userAddr, AchievementCommonLib.AchievementsType.Rating, int64(userCommunityRating.userRating[communityId].rating));
    }
  }

  function updateUserPeriodRating(UserContext storage userContext, CommunityRatingForUser storage userCommunityRating, address userAddr, int32 rating, uint32 communityId, uint16 currentPeriod, uint16 previousPeriod) private {
    RewardLib.PeriodRating storage currentPeriodRating = userCommunityRating.userPeriodRewards[currentPeriod].periodRating[communityId];
    bool isFirstTransactionInPeriod = !currentPeriodRating.isActive;

    DataUpdateUserRating memory dataUpdateUserRatingCurrentPeriod;
    dataUpdateUserRatingCurrentPeriod.ratingToReward = currentPeriodRating.ratingToReward;
    dataUpdateUserRatingCurrentPeriod.penalty = currentPeriodRating.penalty;
    
    if (currentPeriod == previousPeriod) {   //first period rating?
      dataUpdateUserRatingCurrentPeriod.changeRating = rating;

    } else {
      RewardLib.PeriodRating storage previousPeriodRating = userCommunityRating.userPeriodRewards[previousPeriod].periodRating[communityId];
      
      DataUpdateUserRating memory dataUpdateUserRatingPreviousPeriod;
      dataUpdateUserRatingPreviousPeriod.ratingToReward = previousPeriodRating.ratingToReward;
      dataUpdateUserRatingPreviousPeriod.penalty = previousPeriodRating.penalty;
      
      if (previousPeriod != currentPeriod - 1) {
        if (isFirstTransactionInPeriod && dataUpdateUserRatingPreviousPeriod.penalty > dataUpdateUserRatingPreviousPeriod.ratingToReward) {
          dataUpdateUserRatingCurrentPeriod.changeRating = rating + CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
        } else {
          dataUpdateUserRatingCurrentPeriod.changeRating = rating;
        }
      } else {
        if (isFirstTransactionInPeriod && dataUpdateUserRatingPreviousPeriod.penalty > dataUpdateUserRatingPreviousPeriod.ratingToReward) {
          dataUpdateUserRatingCurrentPeriod.changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
        }

        int32 differentRatingPreviousPeriod; // name
        int32 differentRatingCurrentPeriod;
        if (rating > 0 && dataUpdateUserRatingPreviousPeriod.penalty > 0) {
          if (dataUpdateUserRatingPreviousPeriod.ratingToReward == 0) {
            differentRatingPreviousPeriod = rating - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
            if (differentRatingPreviousPeriod >= 0) {
              dataUpdateUserRatingPreviousPeriod.changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
              dataUpdateUserRatingCurrentPeriod.changeRating = differentRatingPreviousPeriod;
            } else {
              dataUpdateUserRatingPreviousPeriod.changeRating = rating;
              dataUpdateUserRatingCurrentPeriod.changeRating += rating;
            }
          } else {
            differentRatingPreviousPeriod = rating - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
            if (differentRatingPreviousPeriod >= 0) {
              dataUpdateUserRatingPreviousPeriod.changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
              dataUpdateUserRatingCurrentPeriod.changeRating = differentRatingPreviousPeriod;
            } else {
              dataUpdateUserRatingPreviousPeriod.changeRating = rating;
            }
          }
        } else if (rating < 0 && dataUpdateUserRatingPreviousPeriod.ratingToReward > dataUpdateUserRatingPreviousPeriod.penalty) {

          differentRatingCurrentPeriod = CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty) - rating;   // penalty is always positive, we need add rating to penalty
          if (differentRatingCurrentPeriod > CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward)) {
            dataUpdateUserRatingCurrentPeriod.changeRating -= CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty);  // - current ratingToReward
            dataUpdateUserRatingPreviousPeriod.changeRating = rating - dataUpdateUserRatingCurrentPeriod.changeRating;                                       // + previous penalty
            if (CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) < CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) - dataUpdateUserRatingPreviousPeriod.changeRating) {
              int32 extraPenalty = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - dataUpdateUserRatingPreviousPeriod.changeRating;
              dataUpdateUserRatingPreviousPeriod.changeRating += extraPenalty;  // - extra previous penalty
              dataUpdateUserRatingCurrentPeriod.changeRating -= extraPenalty;   // + extra current penalty
            }
          } else {
            dataUpdateUserRatingCurrentPeriod.changeRating = rating;
            // dataUpdateUserRatingCurrentPeriod.changeRating += 0;
          }
        } else {
          dataUpdateUserRatingCurrentPeriod.changeRating += rating;
        }
      }

      if (dataUpdateUserRatingPreviousPeriod.changeRating != 0) {
        if (dataUpdateUserRatingPreviousPeriod.changeRating > 0) previousPeriodRating.penalty -= CommonLib.toUInt32FromInt32(dataUpdateUserRatingPreviousPeriod.changeRating);
        else previousPeriodRating.penalty += CommonLib.toUInt32FromInt32(-dataUpdateUserRatingPreviousPeriod.changeRating);

        dataUpdateUserRatingPreviousPeriod.ratingToRewardChange = getRatingToRewardChange(CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty), CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) + dataUpdateUserRatingPreviousPeriod.changeRating);
        if (dataUpdateUserRatingPreviousPeriod.ratingToRewardChange > 0) {
          userContext.periodRewardContainer.periodRewardShares[previousPeriod].totalRewardShares += CommonLib.toUInt32FromInt32(getRewardShare(userContext, userAddr, previousPeriod, dataUpdateUserRatingPreviousPeriod.ratingToRewardChange));
        } else {
          userContext.periodRewardContainer.periodRewardShares[previousPeriod].totalRewardShares -= CommonLib.toUInt32FromInt32(-getRewardShare(userContext, userAddr, previousPeriod, dataUpdateUserRatingPreviousPeriod.ratingToRewardChange));
        }
      }
    }

    if (dataUpdateUserRatingCurrentPeriod.changeRating != 0) {
      dataUpdateUserRatingCurrentPeriod.ratingToRewardChange = getRatingToRewardChange(CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty), CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty) + dataUpdateUserRatingCurrentPeriod.changeRating);
      if (dataUpdateUserRatingCurrentPeriod.ratingToRewardChange > 0) {
        userContext.periodRewardContainer.periodRewardShares[currentPeriod].totalRewardShares += CommonLib.toUInt32FromInt32(getRewardShare(userContext, userAddr, currentPeriod, dataUpdateUserRatingCurrentPeriod.ratingToRewardChange));
      } else {
        userContext.periodRewardContainer.periodRewardShares[currentPeriod].totalRewardShares -= CommonLib.toUInt32FromInt32(-getRewardShare(userContext, userAddr, currentPeriod, dataUpdateUserRatingCurrentPeriod.ratingToRewardChange));
      }

      int32 changeRating;
      if (dataUpdateUserRatingCurrentPeriod.changeRating > 0) {
        changeRating = dataUpdateUserRatingCurrentPeriod.changeRating - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty);
        if (changeRating >= 0) {
          currentPeriodRating.penalty = 0;
          currentPeriodRating.ratingToReward += CommonLib.toUInt32FromInt32(changeRating);
        } else {
          currentPeriodRating.penalty = CommonLib.toUInt32FromInt32(-changeRating);
        }

      } else if (dataUpdateUserRatingCurrentPeriod.changeRating < 0) {
        changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) + dataUpdateUserRatingCurrentPeriod.changeRating;
        if (changeRating <= 0) {
          currentPeriodRating.ratingToReward = 0;
          currentPeriodRating.penalty += CommonLib.toUInt32FromInt32(-changeRating);
        } else {
          currentPeriodRating.ratingToReward = CommonLib.toUInt32FromInt32(changeRating);
        }
      }
    }

    // Activate period rating for community if this is the first change
    if (isFirstTransactionInPeriod) {
      currentPeriodRating.isActive = true;
    }
  }

  function getRewardShare(UserLib.UserContext storage userContext, address userAddr, uint16 period, int32 rating) private view returns (int32) { // FIX
    return CommonLib.toInt32FromUint256(userContext.peeranhaToken.getBoost(userAddr, period)) * rating;
  }

  function getRatingToRewardChange(int32 previosRatingToReward, int32 newRatingToReward) private pure returns (int32) {
    if (previosRatingToReward >= 0 && newRatingToReward >= 0) return newRatingToReward - previosRatingToReward;
    else if(previosRatingToReward > 0 && newRatingToReward < 0) return -previosRatingToReward;
    else if(previosRatingToReward < 0 && newRatingToReward > 0) return newRatingToReward;
    return 0; // from negative to negative
  }

  function checkRatingAndEnergy(
    UserContext storage userContext,
    address actionCaller,
    address dataUser,
    uint32 communityId,
    Action action
  )
    internal 
    returns (User storage)
  {
    UserLib.User storage user = UserLib.getUserByAddress(userContext.users, actionCaller);
    int32 userRating = UserLib.getUserRating(userContext.userRatingCollection, actionCaller, communityId);
        
    (int16 ratingAllowed, string memory message, uint8 energy) = getRatingAndRatingForAction(actionCaller, dataUser, action);
    require(userRating >= ratingAllowed, message);
    reduceEnergy(user, energy);

    return user;
  }

  function getRatingAndRatingForAction(
    address actionCaller,
    address dataUser,
    Action action
  ) private pure returns (int16 ratingAllowed, string memory message, uint8 energy) {
    if (action == Action.NONE) {
    } else if (action == Action.PublicationPost) {
      ratingAllowed = POST_QUESTION_ALLOWED;
      message = "low_rating_post";
      energy = ENERGY_POST_QUESTION;

    } else if (action == Action.PublicationReply) {
      ratingAllowed = POST_REPLY_ALLOWED;
      message = "low_rating_reply";
      energy = ENERGY_POST_ANSWER;

    } else if (action == Action.PublicationComment) {
      ratingAllowed = POST_COMMENT_ALLOWED;
      message = "low_rating_own_post_comment";
      energy = ENERGY_POST_COMMENT;

    } else if (action == Action.EditItem) {
      require(actionCaller == dataUser, "not_allowed_edit");
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_edit";
      energy = ENERGY_MODIFY_ITEM;

    } else if (action == Action.DeleteItem) {
      require(actionCaller == dataUser, "not_allowed_delete");
      ratingAllowed = 0;
      message = "low_rating_delete_own"; // delete own item?
      energy = ENERGY_DELETE_ITEM;

    } else if (action == Action.UpVotePost) {
      require(actionCaller != dataUser, "not_allowed_vote_post");
      ratingAllowed = UPVOTE_POST_ALLOWED;
      message = "low rating to upvote";
      energy = ENERGY_UPVOTE_QUESTION;

    } else if (action == Action.UpVoteReply) {
      require(actionCaller != dataUser, "not_allowed_vote_reply");
      ratingAllowed = UPVOTE_REPLY_ALLOWED;
      message = "low_rating_upvote_post";
      energy = ENERGY_UPVOTE_ANSWER;

    } else if (action == Action.VoteComment) {
      require(actionCaller != dataUser, "not_allowed_vote_comment");
      ratingAllowed = VOTE_COMMENT_ALLOWED;
      message = "low_rating_vote_comment";
      energy = ENERGY_VOTE_COMMENT;

    } else if (action == Action.DownVotePost) {
      require(actionCaller != dataUser, "not_allowed_vote_post");
      ratingAllowed = DOWNVOTE_POST_ALLOWED;
      message = "low_rating_downvote_post";
      energy = ENERGY_DOWNVOTE_QUESTION;

    } else if (action == Action.DownVoteReply) {
      require(actionCaller != dataUser, "not_allowed_vote_reply");
      ratingAllowed = DOWNVOTE_REPLY_ALLOWED;
      message = "low_rating_downvote_reply";
      energy = ENERGY_DOWNVOTE_ANSWER;

    } else if (action == Action.CancelVote) {
      ratingAllowed = CANCEL_VOTE;
      message = "low_rating_cancel_vote";
      energy = ENERGY_FORUM_VOTE_CANCEL;

    } else if (action == Action.BestReply) {
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_mark_best";
      energy = ENERGY_MARK_REPLY_AS_CORRECT;

    } else if (action == Action.UpdateProfile) {
      energy = ENERGY_UPDATE_PROFILE;

    } else if (action == Action.FollowCommunity) {
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_follow_comm";
      energy = ENERGY_FOLLOW_COMMUNITY;

    } else {
      revert("not_allowed_action");
    }
  }

  function reduceEnergy(UserLib.User storage user, uint8 energy) internal {    
    uint16 currentPeriod = RewardLib.getPeriod(CommonLib.getTimestamp());
    uint32 periodsHavePassed = currentPeriod - user.lastUpdatePeriod;

    uint16 userEnergy;
    if (periodsHavePassed == 0) {
      userEnergy = user.energy;
    } else {
      userEnergy = UserLib.getStatusEnergy();
      user.lastUpdatePeriod = currentPeriod;
    }

    require(userEnergy >= energy, "low_energy");
    user.energy = userEnergy - energy;
  }

  function getStatusEnergy() internal pure returns (uint16) {
    return 1000;
  }

  function getPeriodRewardShares(UserContext storage userContext, uint16 period) internal view returns(RewardLib.PeriodRewardShares memory) {
    return userContext.periodRewardContainer.periodRewardShares[period];
  }

  function getUserRewardCommunities(UserContext storage userContext, address user, uint16 rewardPeriod) internal view returns(uint32[] memory) {
    return userContext.userRatingCollection.communityRatingForUser[user].userPeriodRewards[rewardPeriod].rewardCommunities;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/// @title CommonLib
/// @notice
/// @dev
library CommonLib {
  uint16 constant QUICK_REPLY_TIME_SECONDS = 900; // 6

  struct IpfsHash {
      bytes32 hash;
      bytes32 hash2; // Not currently used and added for the future compatibility
  }

  /// @notice get timestamp in uint32 format
  function getTimestamp() internal view returns (uint32) {
    return SafeCastUpgradeable.toUint32(block.timestamp);
  }

  function toInt32(int value) internal pure returns (int32) {
    return SafeCastUpgradeable.toInt32(value);
  }

  function toInt32FromUint256(uint256 value) internal pure returns (int32) {
    int256 buffValue = SafeCastUpgradeable.toInt256(value);
    return SafeCastUpgradeable.toInt32(buffValue);
  }

  function toUInt32FromInt32(int256 value) internal pure returns (uint32) {
    uint256 buffValue = SafeCastUpgradeable.toUint256(value);
    return SafeCastUpgradeable.toUint32(buffValue);
  }

  /**
  * @dev Returns the largest of two numbers.
  */
  function maxInt32(int32 a, int32 b) internal pure returns (int32) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function minInt32(int32 a, int32 b) internal pure returns (int32) {
    return a < b ? a : b;
  }

  function minUint256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function isEmptyIpfs (
      bytes32 hash
  ) internal pure returns(bool) {
      return hash == bytes32(0x0);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPeeranhaNFT.sol";
import "./AchievementCommonLib.sol";


/// @title AchievementLib
/// @notice
/// @dev
library AchievementLib {
  struct AchievementConfig {
    uint64 factCount;
    uint64 maxCount;
    int64 lowerBound;
    AchievementCommonLib.AchievementsType achievementsType;
  }

  struct AchievementsContainer {
    mapping(uint64 => AchievementConfig) achievementsConfigs;
    mapping(address => mapping(uint64 => bool)) userAchievementsIssued;
    uint64 achievementsCount;
    IPeeranhaNFT peeranhaNFT;
  }

  function configureNewAchievement(
    AchievementsContainer storage achievementsContainer,
    uint64 maxCount,
    int64 lowerBound,
    string memory achievementURI,
    AchievementCommonLib.AchievementsType achievementsType
  ) 
    internal 
  {
    require(maxCount > 0, "invalid_max_count");

    AchievementLib.AchievementConfig storage achievementConfig = achievementsContainer.achievementsConfigs[++achievementsContainer.achievementsCount];
    achievementConfig.maxCount = maxCount;
    achievementConfig.lowerBound = lowerBound;
    achievementConfig.achievementsType = achievementsType;

    achievementsContainer.peeranhaNFT.configureNewAchievementNFT(achievementsContainer.achievementsCount, maxCount, achievementURI, achievementsType);
  }

  function updateUserAchievements(
    AchievementsContainer storage achievementsContainer,
    address user,
    AchievementCommonLib.AchievementsType achievementsType,
    int64 currentValue
  )
    internal
  {
    if (achievementsType == AchievementCommonLib.AchievementsType.Rating) {
      AchievementConfig storage achievementConfig;
      for (uint64 i = 1; i <= achievementsContainer.achievementsCount; i++) { /// optimize ??
        achievementConfig = achievementsContainer.achievementsConfigs[i];

        if (achievementConfig.maxCount <= achievementConfig.factCount) continue;    // not exit/max
        if (achievementConfig.lowerBound > currentValue) continue;
        if (achievementsContainer.userAchievementsIssued[user][i]) continue; //already issued
        achievementConfig.factCount++;
        achievementsContainer.userAchievementsIssued[user][i] = true;
        achievementsContainer.peeranhaNFT.mint(user, i);
      }
    }
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title AchievementCommonLib
/// @notice
/// @dev
library AchievementCommonLib {
  enum AchievementsType { Rating }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base, ContextUpgradeable {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function __NativeMetaTransaction_init(
        string memory name
    )
        internal
        onlyInitializing
    {
        __EIP712_init(name);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        virtual
        override
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
import "../libraries/UserLib.sol";
import "../libraries/RewardLib.sol";
pragma abicoder v2;


interface IPeeranhaUser {
    function createUser(bytes32 ipfsHash) external;
    function updateUser(bytes32 ipfsHash) external;
    function followCommunity(uint32 communityId) external;
    function unfollowCommunity(uint32 communityId) external;
    function initCommunityAdminPermission(address user, uint32 communityId) external;
    function giveCommunityAdminPermission(address user, uint32 communityId) external;
    function checkActionRole(address actionCaller, address dataUser, uint32 communityId, UserLib.Action action, UserLib.ActionRole actionRole, bool isCreate) external;
    function checkHasRole(address actionCaller, UserLib.ActionRole actionRole, uint32 communityId) external view;
    function getRatingToReward(address user, uint16 period, uint32 communityId) external view returns (int32);
    function getPeriodRewardShares(uint16 period) external view returns(RewardLib.PeriodRewardShares memory);
    function getUserRewardCommunities(address user, uint16 rewardPeriod) external view returns(uint32[] memory);
    function updateUserRating(address userAddr, int32 rating, uint32 communityId) external;
    function updateUsersRating(UserLib.UserRatingChange[] memory usersRating, uint32 communityId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CommonLib.sol";
import "./UserLib.sol";


/// @title RewardLib
/// @notice
/// @dev
library RewardLib {
  uint256 constant PERIOD_LENGTH = 3600;          // 7 day = 1 period //
  uint256 constant START_PERIOD_TIME = 1652871650;  // September 28, 2021 8:20:23 PM GMT+03:00 DST

  struct PeriodRating {
    uint32 ratingToReward;
    uint32 penalty;
    bool isActive;
  }

  struct PeriodRewardContainer {
    mapping(uint16 => PeriodRewardShares) periodRewardShares; // period
  }

  struct PeriodRewardShares {
    uint256 totalRewardShares;
    address[] activeUsersInPeriod;
  }

  struct UserPeriodRewards {
    uint32[] rewardCommunities;
    mapping(uint32 => PeriodRating) periodRating;  //communityID
  }


  /// @notice Get perion
  /// @param time Unix time. Usual now()
  function getPeriod(uint32 time) internal pure returns (uint16) {
    return uint16((time - START_PERIOD_TIME) / PERIOD_LENGTH);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;


interface IPeeranhaToken {
  function getBoost(address user, uint16 period) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;


interface IPeeranhaCommunity {
    function onlyExistingAndNotFrozenCommunity(uint32 communityId) external;
    function checkTags(uint32 communityId, uint8[] memory tags) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;

import "../libraries/PostLib.sol";

interface IPeeranhaContent {
    function createPost(uint32 communityId, bytes32 ipfsHash, PostLib.PostType postType, uint8[] memory tags) external;
    function createReply(uint256 postId, uint16 parentReplyId, bytes32 ipfsHash, bool isOfficialReply) external;
    function createComment(uint256 postId, uint16 parentReplyId, bytes32 ipfsHash) external;
    function editPost(uint256 postId, bytes32 ipfsHash, uint8[] memory tags) external;
    function editReply(uint256 postId, uint16 parentReplyId, bytes32 ipfsHash ) external;
    function editComment(uint256 postId, uint16 parentReplyId, uint8 commentId, bytes32 ipfsHash) external;
    function deletePost(uint256 postId) external;
    function deleteReply(uint256 postId, uint16 replyId) external;
    function deleteComment(uint256 postId, uint16 parentReplyId, uint8 commentId) external;
    function changeStatusOfficialReply(uint256 postId, uint16 replyId) external;
    function changeStatusBestReply(uint256 postId, uint16 replyId) external;
    function voteItem(uint256 postId, uint16 replyId, uint8 commentId, bool isUpvote) external;
    function changePostType(uint256 postId, PostLib.PostType postType) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;

import "../libraries/AchievementCommonLib.sol";


interface IPeeranhaNFT {
  function mint(address user, uint64 achievementId) external;
  function configureNewAchievementNFT(
    uint64 achievementId,
    uint64 maxCount,
    string memory achievementURI,
    AchievementCommonLib.AchievementsType achievementsType) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./VoteLib.sol";
import "./UserLib.sol";
import "./CommonLib.sol";
import "./AchievementLib.sol";
import "../interfaces/IPeeranhaUser.sol";
import "../interfaces/IPeeranhaCommunity.sol";

/// @title PostLib
/// @notice Provides information about operation with posts
/// @dev posts information is stored in the mapping on the main contract
library PostLib  {
    using UserLib for UserLib.UserCollection;
    uint256 constant DELETE_TIME = 3600;    //7 days (10)     // name??

    int8 constant directionDownVote = -2;
    int8 constant directionCancelDownVote = -1;
    int8 constant directionUpVote = 1;
    int8 constant directionCancelUpVote = 2;

    enum PostType { ExpertPost, CommonPost, Tutorial }
    enum TypeContent { Post, Reply, Comment }

    struct Comment {
        CommonLib.IpfsHash ipfsDoc;
        address author;
        int32 rating;
        uint32 postTime;
        uint8 propertyCount;
        bool isDeleted;
    }

    struct CommentContainer {
        Comment info;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct Reply {
        CommonLib.IpfsHash ipfsDoc;
        address author;
        int32 rating;
        uint32 postTime;
        uint16 parentReplyId;
        uint8 commentCount;
        uint8 propertyCount;

        bool isFirstReply;
        bool isQuickReply;
        bool isDeleted;
    }

    struct ReplyContainer {
        Reply info;
        mapping(uint8 => CommentContainer) comments;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct Post {
        PostType postType;
        address author;
        int32 rating;
        uint32 postTime;
        uint32 communityId;

        uint16 officialReply;
        uint16 bestReply;
        uint8 propertyCount;
        uint8 commentCount;
        uint16 replyCount;
        uint16 deletedReplyCount;
        bool isDeleted;

        uint8[] tags;
        CommonLib.IpfsHash ipfsDoc;
    }

    struct PostContainer {
        Post info;
        mapping(uint16 => ReplyContainer) replies;
        mapping(uint8 => CommentContainer) comments;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct PostCollection {
        mapping(uint256 => PostContainer) posts;
        uint256 postCount;
        IPeeranhaCommunity peeranhaCommunity;
        IPeeranhaUser peeranhaUser; 
    }

    event PostCreated(address indexed user, uint32 indexed communityId, uint256 indexed postId); 
    event ReplyCreated(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint16 replyId);
    event CommentCreated(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event PostEdited(address indexed user, uint256 indexed postId);
    event ReplyEdited(address indexed user, uint256 indexed postId, uint16 replyId);
    event CommentEdited(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event PostDeleted(address indexed user, uint256 indexed postId);
    event ReplyDeleted(address indexed user, uint256 indexed postId, uint16 replyId);
    event CommentDeleted(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event StatusOfficialReplyChanged(address indexed user, uint256 indexed postId, uint16 replyId);
    event StatusBestReplyChanged(address indexed user, uint256 indexed postId, uint16 replyId);
    event ForumItemVoted(address indexed user, uint256 indexed postId, uint16 replyId, uint8 commentId, int8 voteDirection);
    event ChangePostType(address indexed user, uint256 indexed postId, PostType newPostType);

    /// @notice Publication post 
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the post
    /// @param communityId Community where the post will be ask
    /// @param ipfsHash IPFS hash of document with post information
    function createPost(
        PostCollection storage self,
        address userAddr,
        uint32 communityId, 
        bytes32 ipfsHash,
        PostType postType,
        uint8[] memory tags
    ) public {
        self.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(communityId);
        self.peeranhaCommunity.checkTags(communityId, tags);
        
        self.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            communityId,
            UserLib.Action.PublicationPost,
            UserLib.ActionRole.NONE,
            true
        );

        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");
        require(tags.length > 0, "At least one tag is required.");

        PostContainer storage post = self.posts[++self.postCount];
        post.info.ipfsDoc.hash = ipfsHash;
        post.info.postType = postType;
        post.info.author = userAddr;
        post.info.postTime = CommonLib.getTimestamp();
        post.info.communityId = communityId;
        post.info.tags = tags;

        emit PostCreated(userAddr, communityId, self.postCount);
    }

    /// @notice Post reply
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the reply
    /// @param postId The post where the reply will be post
    /// @param parentReplyId The reply where the reply will be post
    /// @param ipfsHash IPFS hash of document with reply information
    /// @param isOfficialReply Flag is showing "official reply" or not
    function createReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        bytes32 ipfsHash,
        bool isOfficialReply
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(postContainer.info.postType != PostType.Tutorial, "You can not publish replies in tutorial.");

        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.PublicationReply,
            parentReplyId == 0 && isOfficialReply ? 
                UserLib.ActionRole.CommunityModerator :
                UserLib.ActionRole.NONE,
            true
        );

        /*  
            Check gas one more 
            isOfficialReply ? UserLib.Action.publicationOfficialReply : UserLib.Action.PublicationReply
            remove: require((UserLib.hasRole(userContex ...
            20k in gas contract, +20 gas in common reply (-20 in official reply), but Avg gas -20 ?
         */
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");
        require(
            parentReplyId == 0 || 
            (postContainer.info.postType != PostType.ExpertPost && postContainer.info.postType != PostType.CommonPost), 
            "User is forbidden to reply on reply for Expert and Common type of posts"
        ); // unit tests (reply on reply)

        ReplyContainer storage replyContainer;
        if (postContainer.info.postType == PostType.ExpertPost || postContainer.info.postType == PostType.CommonPost) {
          uint16 countReplies = uint16(postContainer.info.replyCount);

          for (uint16 i = 1; i <= countReplies; i++) {
            replyContainer = getReplyContainer(postContainer, i);
            require(userAddr != replyContainer.info.author || replyContainer.info.isDeleted,
                "Users can not publish 2 replies for expert and common posts.");
          }
        }

        replyContainer = postContainer.replies[++postContainer.info.replyCount];
        uint32 timestamp = CommonLib.getTimestamp();
        if (parentReplyId == 0) {
            if (isOfficialReply) {
                postContainer.info.officialReply = postContainer.info.replyCount;
            }

            if (postContainer.info.postType != PostType.Tutorial && postContainer.info.author != userAddr) {
                if (postContainer.info.replyCount - postContainer.info.deletedReplyCount == 1) {    // unit test
                    replyContainer.info.isFirstReply = true;
                    self.peeranhaUser.updateUserRating(userAddr, VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.FirstReply), postContainer.info.communityId);
                }
                if (timestamp - postContainer.info.postTime < CommonLib.QUICK_REPLY_TIME_SECONDS) {
                    replyContainer.info.isQuickReply = true;
                    self.peeranhaUser.updateUserRating(userAddr, VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.QuickReply), postContainer.info.communityId);
                }
            }
        } else {
          getReplyContainerSafe(postContainer, parentReplyId);
          replyContainer.info.parentReplyId = parentReplyId;  
        }

        replyContainer.info.author = userAddr;
        replyContainer.info.ipfsDoc.hash = ipfsHash;
        replyContainer.info.postTime = timestamp;

        emit ReplyCreated(userAddr, postId, parentReplyId, postContainer.info.replyCount);
    }

    /// @notice Post comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param parentReplyId The reply where the comment will be post
    /// @param ipfsHash IPFS hash of document with comment information
    function createComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        bytes32 ipfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");

        Comment storage comment;    ///
        uint8 commentId;            // struct ?
        address author;             ///
        if (parentReplyId == 0) {
            commentId = ++postContainer.info.commentCount;
            comment = postContainer.comments[commentId].info;
            author = postContainer.info.author;
        } else {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, parentReplyId);
            commentId = ++replyContainer.info.commentCount;
            comment = replyContainer.comments[commentId].info;
            author = replyContainer.info.author;
        }

        self.peeranhaUser.checkActionRole(
            userAddr,
            author,
            postContainer.info.communityId,
            UserLib.Action.PublicationComment,
            UserLib.ActionRole.NONE,
            true
        );

        comment.author = userAddr;
        comment.ipfsDoc.hash = ipfsHash;
        comment.postTime = CommonLib.getTimestamp();

        emit CommentCreated(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Edit post
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param ipfsHash IPFS hash of document with post information
    function editPost(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        bytes32 ipfsHash,
        uint8[] memory tags
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        self.peeranhaCommunity.checkTags(postContainer.info.communityId, tags);

        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.EditItem,
            UserLib.ActionRole.NONE,
            false
        );
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");
        require(userAddr == postContainer.info.author, "You can not edit this post. It is not your.");      // error for moderator (fix? will add new flag)

        if(!CommonLib.isEmptyIpfs(ipfsHash) && postContainer.info.ipfsDoc.hash != ipfsHash)
            postContainer.info.ipfsDoc.hash = ipfsHash;
        if (tags.length > 0)
            postContainer.info.tags = tags;

        emit PostEdited(userAddr, postId);
    }

    /// @notice Edit reply
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param replyId The reply which will be change
    /// @param ipfsHash IPFS hash of document with reply information
    function editReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        bytes32 ipfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            replyContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.EditItem,
            UserLib.ActionRole.NONE,
            false
        );
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");
        require(userAddr == replyContainer.info.author, "You can not edit this Reply. It is not your.");

        if (replyContainer.info.ipfsDoc.hash != ipfsHash)
            replyContainer.info.ipfsDoc.hash = ipfsHash;
        
        emit ReplyEdited(userAddr, postId, replyId);
    }

    /// @notice Edit comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param parentReplyId The reply where the reply will be edit
    /// @param commentId The comment which will be change
    /// @param ipfsHash IPFS hash of document with comment information
    function editComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId,
        bytes32 ipfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        CommentContainer storage commentContainer = getCommentContainerSave(postContainer, parentReplyId, commentId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            commentContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.EditItem,
            UserLib.ActionRole.NONE,
            false
        );
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid ipfsHash.");
        require(userAddr == commentContainer.info.author, "You can not edit this comment. It is not your.");

        if (commentContainer.info.ipfsDoc.hash != ipfsHash)
            commentContainer.info.ipfsDoc.hash = ipfsHash;
        
        emit CommentEdited(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Delete post
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes post
    /// @param postId Post which will be deleted
    function deletePost(
        PostCollection storage self,
        address userAddr,
        uint256 postId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );

        uint256 time = CommonLib.getTimestamp();
        if (time - postContainer.info.postTime < DELETE_TIME || userAddr == postContainer.info.author) {
            VoteLib.StructRating memory typeRating = getTypesRating(postContainer.info.postType);
            (int32 positive, int32 negative) = getHistoryInformations(postContainer.historyVotes, postContainer.votedUsers);

            int32 changeUserRating = typeRating.upvotedPost * positive + typeRating.downvotedPost * negative;
            if (changeUserRating > 0) {
                self.peeranhaUser.updateUserRating(
                    postContainer.info.author,
                    -changeUserRating,
                    postContainer.info.communityId
                );
            }
        }
        if (postContainer.info.bestReply != 0) {
            self.peeranhaUser.updateUserRating(postContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.AcceptedReply), postContainer.info.communityId);
        }

        if (time - postContainer.info.postTime < DELETE_TIME) {    
            for (uint16 i = 1; i <= postContainer.info.replyCount; i++) {
                deductReplyRating(self, postContainer.info.postType, postContainer.replies[i], postContainer.info.bestReply == i, postContainer.info.communityId);
            }
        }
        
        if (userAddr == postContainer.info.author)
            self.peeranhaUser.updateUserRating(postContainer.info.author, VoteLib.DeleteOwnPost, postContainer.info.communityId);
        else
            self.peeranhaUser.updateUserRating(postContainer.info.author, VoteLib.ModeratorDeletePost, postContainer.info.communityId);

        postContainer.info.isDeleted = true;
        emit PostDeleted(userAddr, postId);
    }

    /// @notice Delete reply
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes reply
    /// @param postId The post where will be deleted reply
    /// @param replyId Reply which will be deleted
    function deleteReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            replyContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );
        ///
        // bug
        // checkActionRole has check "require(actionCaller == dataUser, "not_allowed_delete");"
        // behind this check is "if actionCaller == moderator -> return"
        // in this step can be only a moderator or reply's owner
        // a reply owner can not delete best reply, but a moderator can
        // next require check that reply's owner can not delete best reply
        // bug if reply's owner is moderator any way error
        ///
        require(postContainer.info.bestReply != replyId || userAddr != replyContainer.info.author, "You can not delete the best reply.");


        uint256 time = CommonLib.getTimestamp();
        if (time - replyContainer.info.postTime < DELETE_TIME || userAddr == replyContainer.info.author) {
            deductReplyRating(
                self,
                postContainer.info.postType,
                replyContainer,
                replyContainer.info.parentReplyId == 0 && postContainer.info.bestReply == replyId,
                postContainer.info.communityId
            );
        }
        if (userAddr == replyContainer.info.author)
            self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.DeleteOwnReply, postContainer.info.communityId);
        else
            self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.ModeratorDeleteReply, postContainer.info.communityId);

        replyContainer.info.isDeleted = true;
        postContainer.info.deletedReplyCount++;
        emit ReplyDeleted(userAddr, postId, replyId);
    }

    /// @notice Take reply rating from the author
    /// @param postType Type post: expert, common, tutorial
    /// @param replyContainer Reply from which the rating is taken
    function deductReplyRating (
        PostCollection storage self,
        PostType postType,
        ReplyContainer storage replyContainer,
        bool isBestReply,
        uint32 communityId
    ) private {
        if (CommonLib.isEmptyIpfs(replyContainer.info.ipfsDoc.hash) || replyContainer.info.isDeleted)
            return;

        int32 changeReplyAuthorRating;
        if (replyContainer.info.rating >= 0) {
            if (replyContainer.info.isFirstReply) {
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply);
            }
            if (replyContainer.info.isQuickReply) {
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply);
            }
            if (isBestReply && postType != PostType.Tutorial) {
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply);
            }
        }

        // change user rating considering reply rating
        VoteLib.StructRating memory typeRating = getTypesRating(postType);
        (int32 positive, int32 negative) = getHistoryInformations(replyContainer.historyVotes, replyContainer.votedUsers);
        int32 changeUserRating = typeRating.upvotedReply * positive + typeRating.downvotedReply * negative;
        if (changeUserRating > 0) {
            changeReplyAuthorRating += -changeUserRating;
        }

        if (changeReplyAuthorRating != 0) {
            self.peeranhaUser.updateUserRating(
                replyContainer.info.author, 
                changeReplyAuthorRating,
                communityId
            );
        }
    }

    /// @notice Delete comment
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes comment
    /// @param postId The post where will be deleted comment
    /// @param parentReplyId The reply where the reply will be deleted
    /// @param commentId Comment which will be deleted
    function deleteComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        CommentContainer storage commentContainer = getCommentContainerSave(postContainer, parentReplyId, commentId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            commentContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );

        if (userAddr == commentContainer.info.author)
            self.peeranhaUser.updateUserRating(commentContainer.info.author, VoteLib.DeleteOwnComment, postContainer.info.communityId);
        else
            self.peeranhaUser.updateUserRating(commentContainer.info.author, VoteLib.ModeratorDeleteComment, postContainer.info.communityId);

        commentContainer.info.isDeleted = true;
        emit CommentDeleted(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Change status official reply
    /// @param self The mapping containing all posts
    /// @param userAddr Who called action
    /// @param postId Post where will be change reply status
    /// @param replyId Reply which will change status
    function changeStatusOfficialReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId
    ) public {
        // check + energy?
        PostContainer storage postContainer = getPostContainer(self, postId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            postContainer.info.communityId,
            UserLib.Action.NONE,
            UserLib.ActionRole.CommunityModerator,
            false
        );

        getReplyContainerSafe(postContainer, replyId);
         
        if (postContainer.info.officialReply == replyId)
            postContainer.info.officialReply = 0;
        else
            postContainer.info.officialReply = replyId;
        
        emit StatusOfficialReplyChanged(userAddr, postId, postContainer.info.officialReply);
    }

    /// @notice Change status best reply
    /// @param self The mapping containing all posts
    /// @param userAddr Who called action
    /// @param postId The post where will be change reply status
    /// @param replyId Reply which will change status
    function changeStatusBestReply (
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(postContainer.info.author == userAddr, "Only owner by post can change statust best reply.");
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);

        if (postContainer.info.bestReply == replyId) {
            updateRatingForBestReply(self, postContainer.info.postType, userAddr, replyContainer.info.author, false, postContainer.info.communityId);
            postContainer.info.bestReply = 0;
        } else {
            if (postContainer.info.bestReply != 0) {
                ReplyContainer storage oldBestReplyContainer = getReplyContainerSafe(postContainer, postContainer.info.bestReply);

                updateRatingForBestReply(self, postContainer.info.postType, userAddr, oldBestReplyContainer.info.author, false, postContainer.info.communityId);
            }

            updateRatingForBestReply(self, postContainer.info.postType, userAddr, replyContainer.info.author, true, postContainer.info.communityId);
            postContainer.info.bestReply = replyId;
        }
        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.BestReply,
            UserLib.ActionRole.NONE,
            false
        );  // unit test (forum)

        emit StatusBestReplyChanged(userAddr, postId, postContainer.info.bestReply);
    }

    function updateRatingForBestReply (
        PostCollection storage self,
        PostType postType,
        address authorPost,
        address authorReply,
        bool isMark,
        uint32 communityId
    ) private {
        if (authorPost != authorReply) {
            self.peeranhaUser.updateUserRating(
                authorPost, 
                isMark ?
                    VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptedReply) :
                    -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptedReply),
                communityId
            );

            self.peeranhaUser.updateUserRating(
                authorReply,
                isMark ?
                    VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply) :
                    -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply),
                communityId
            );
        }
    }

    /// @notice Vote for post, reply or comment
    /// @param self The mapping containing all posts
    /// @param userAddr Who called action
    /// @param postId Post where will be change rating
    /// @param replyId Reply which will be change rating
    /// @param commentId Comment which will be change rating
    /// @param isUpvote Upvote or downvote
    function voteForumItem(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        bool isUpvote
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        PostType postType = postContainer.info.postType;

        int8 voteDirection;
        if (commentId != 0) {
            CommentContainer storage commentContainer = getCommentContainerSave(postContainer, replyId, commentId);
            require(userAddr != commentContainer.info.author, "error_vote_comment");
            voteDirection = voteComment(self, commentContainer, postContainer.info.communityId, userAddr, isUpvote);

        } else if (replyId != 0) {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
            require(userAddr != replyContainer.info.author, "error_vote_reply");
            voteDirection = voteReply(self, replyContainer, postContainer.info.communityId, userAddr, postType, isUpvote);


        } else {
            require(userAddr != postContainer.info.author, "error_vote_post");
            voteDirection = votePost(self, postContainer, userAddr, postType, isUpvote);
        }

        emit ForumItemVoted(userAddr, postId, replyId, commentId, voteDirection);
    }

    // @notice Vote for post
    /// @param self The mapping containing all posts
    /// @param postContainer Post where will be change rating
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    function votePost(
        PostCollection storage self,
        PostContainer storage postContainer,
        address votedUser,
        PostType postType,
        bool isUpvote
    ) public returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, postContainer.historyVotes, isUpvote, postContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            postContainer.info.author,
            postContainer.info.communityId,
            isCancel ?
                UserLib.Action.CancelVote :
                (ratingChange > 0 ?
                    UserLib.Action.UpVotePost :
                    UserLib.Action.DownVotePost
                ),
            UserLib.ActionRole.NONE,
            false
        ); 

        vote(self, postContainer.info.author, votedUser, postType, isUpvote, ratingChange, TypeContent.Post, postContainer.info.communityId);
        postContainer.info.rating += ratingChange;
        
        return isCancel ?
            (ratingChange < 0 ?
                directionCancelDownVote :
                directionDownVote 
            ) :
            (ratingChange > 0 ?
                directionUpVote :
                directionCancelUpVote
            );
    }
 
    // @notice Vote for reply
    /// @param self The mapping containing all posts
    /// @param replyContainer Reply where will be change rating
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    function voteReply(
        PostCollection storage self,
        ReplyContainer storage replyContainer,
        uint32 communityId,
        address votedUser,
        PostType postType,
        bool isUpvote
    ) public returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, replyContainer.historyVotes, isUpvote, replyContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            replyContainer.info.author,
            communityId,
            isCancel ?
                UserLib.Action.CancelVote :
                (ratingChange > 0 ?
                    UserLib.Action.UpVoteReply :
                    UserLib.Action.DownVoteReply
                ),
            UserLib.ActionRole.NONE,
            false
        ); 

        vote(self, replyContainer.info.author, votedUser, postType, isUpvote, ratingChange, TypeContent.Reply, communityId);
        int32 oldRating = replyContainer.info.rating;
        replyContainer.info.rating += ratingChange;
        int32 newRating = replyContainer.info.rating; // or oldRating + ratingChange gas

        if (replyContainer.info.isFirstReply) {
            if (oldRating < 0 && newRating >= 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply), communityId);
            } else if (oldRating >= 0 && newRating < 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply), communityId);
            }
        }

        if (replyContainer.info.isQuickReply) {
            if (oldRating < 0 && newRating >= 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply), communityId);
            } else if (oldRating >= 0 && newRating < 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply), communityId);
            }
        }

        return isCancel ?
            (ratingChange < 0 ?
                directionCancelDownVote :
                directionDownVote 
            ) :
            (ratingChange > 0 ?
                directionUpVote :
                directionCancelUpVote
            );
    }

    // @notice Vote for comment
    /// @param self The mapping containing all posts
    /// @param commentContainer Comment where will be change rating
    /// @param votedUser User who voted
    /// @param isUpvote Upvote or downvote
    function voteComment(
        PostCollection storage self,
        CommentContainer storage commentContainer,
        uint32 communityId,
        address votedUser,
        bool isUpvote
    ) private returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, commentContainer.historyVotes, isUpvote, commentContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            commentContainer.info.author,
            communityId,
            isCancel ? 
                UserLib.Action.CancelVote :
                UserLib.Action.VoteComment,
            UserLib.ActionRole.NONE,
            false
        );

        commentContainer.info.rating += ratingChange;

        return isCancel ?
            (ratingChange < 0 ?
                directionCancelDownVote :
                directionDownVote 
            ) :
            (ratingChange > 0 ?
                directionUpVote :
                directionCancelUpVote
            );
    }

    // @notice Сount users' rating after voting per a reply or post
    /// @param self The mapping containing all posts
    /// @param author Author post, reply or comment where voted
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    /// @param ratingChanged The value shows how the rating of a post or reply has changed.
    /// @param typeContent Type content post, reply or comment
    function vote (
        PostCollection storage self,
        address author,
        address votedUser,
        PostType postType,
        bool isUpvote,
        int32 ratingChanged,
        TypeContent typeContent,
        uint32 communityId
    ) private {
       UserLib.UserRatingChange[] memory usersRating = new UserLib.UserRatingChange[](2);

        if (isUpvote) {
            usersRating[0].user = author;
            usersRating[0].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Upvoted, typeContent);

            if (ratingChanged == 2) {
                usersRating[0].rating += VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvoted, typeContent) * -1;

                usersRating[1].user = votedUser;
                usersRating[1].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvote, typeContent) * -1; 
            }

            if (ratingChanged < 0) {
                usersRating[0].rating *= -1;
                usersRating[1].rating *= -1;
            } 
        } else {
            usersRating[0].user = author;
            usersRating[0].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvoted, typeContent);

            usersRating[1].user = votedUser;
            usersRating[1].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvote, typeContent);

            if (ratingChanged == -2) {
                usersRating[0].rating += VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Upvoted, typeContent) * -1;
            }

            if (ratingChanged > 0) {
                usersRating[0].rating *= -1;
                usersRating[1].rating *= -1;  
            }
        }
        self.peeranhaUser.updateUsersRating(usersRating, communityId);
    }

    function changePostType(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        PostType newPostType
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            postContainer.info.communityId,
            UserLib.Action.NONE,
            UserLib.ActionRole.AdminOrCommunityModerator,       // will chech
            false
        );
        require(newPostType != postContainer.info.postType, "This post type is already set.");
        
        VoteLib.StructRating memory oldTypeRating = getTypesRating(postContainer.info.postType);
        VoteLib.StructRating memory newTypeRating = getTypesRating(newPostType);

        int32 positive;
        int32 negative;
        for (uint32 i; i < postContainer.votedUsers.length; i++) {
            if(postContainer.historyVotes[postContainer.votedUsers[i]] == 1) positive++;
            else if(postContainer.historyVotes[postContainer.votedUsers[i]] == -1) negative++;
        }
        int32 changeUserRating = (newTypeRating.upvotedPost - oldTypeRating.upvotedPost) * positive +
                                (newTypeRating.downvotedPost - oldTypeRating.downvotedPost) * negative;
        self.peeranhaUser.updateUserRating(postContainer.info.author, changeUserRating, postContainer.info.communityId);

        for (uint16 replyId = 1; replyId <= postContainer.info.replyCount; replyId++) {
            ReplyContainer storage replyContainer = getReplyContainer(postContainer, replyId);
            positive = 0;
            negative = 0;
            for (uint32 i; i < replyContainer.votedUsers.length; i++) {
                if(replyContainer.historyVotes[replyContainer.votedUsers[i]] == 1) positive++;
                else if (replyContainer.historyVotes[replyContainer.votedUsers[i]] == -1) negative++;
            }

            changeUserRating = (newTypeRating.upvotedReply - oldTypeRating.upvotedReply) * positive +
                                    (newTypeRating.downvotedReply - oldTypeRating.downvotedReply) * negative;
            if (replyContainer.info.isFirstReply) {
                changeUserRating += newTypeRating.firstReply - oldTypeRating.firstReply;
            }
            if (replyContainer.info.isQuickReply) {
                changeUserRating += newTypeRating.quickReply - oldTypeRating.quickReply;
            }

            self.peeranhaUser.updateUserRating(replyContainer.info.author, changeUserRating, postContainer.info.communityId);
        }

        if (postContainer.info.bestReply != 0) {
            self.peeranhaUser.updateUserRating(postContainer.info.author, newTypeRating.acceptedReply - oldTypeRating.acceptedReply, postContainer.info.communityId);
            self.peeranhaUser.updateUserRating(
                getReplyContainerSafe(postContainer, postContainer.info.bestReply).info.author,
                newTypeRating.acceptReply - oldTypeRating.acceptReply,
                postContainer.info.communityId
            );
        }

        postContainer.info.postType = newPostType;
        emit ChangePostType(userAddr, postId, newPostType);
    }

    function getTypesRating(        //name?
        PostType postType
    ) private pure returns (VoteLib.StructRating memory) {
        if (postType == PostType.ExpertPost)
            return VoteLib.getExpertRating();
        else if (postType == PostType.CommonPost)
            return VoteLib.getCommonRating();
        else if (postType == PostType.Tutorial)
            return VoteLib.getTutorialRating();
        
        revert("invalid_post_type");
    }

    /// @notice Return post
    /// @param self The mapping containing all posts
    /// @param postId The postId which need find
    function getPostContainer(
        PostCollection storage self,
        uint256 postId
    ) public view returns (PostContainer storage) {
        PostContainer storage post = self.posts[postId];
        require(!CommonLib.isEmptyIpfs(post.info.ipfsDoc.hash), "Post does not exist.");
        require(!post.info.isDeleted, "Post has been deleted.");
        
        return post;
    }

    /// @notice Return reply, the reply is not checked on delete one
    /// @param postContainer The post where is the reply
    /// @param replyId The replyId which need find
    function getReplyContainer(
        PostContainer storage postContainer,
        uint16 replyId
    ) public view returns (ReplyContainer storage) {
        ReplyContainer storage replyContainer = postContainer.replies[replyId];

        require(!CommonLib.isEmptyIpfs(replyContainer.info.ipfsDoc.hash), "Reply does not exist.");
        return replyContainer;
    }

    /// @notice Return reply, the reply is checked on delete one
    /// @param postContainer The post where is the reply
    /// @param replyId The replyId which need find
    function getReplyContainerSafe(
        PostContainer storage postContainer,
        uint16 replyId
    ) public view returns (ReplyContainer storage) {
        ReplyContainer storage replyContainer = getReplyContainer(postContainer, replyId);
        require(!replyContainer.info.isDeleted, "Reply has been deleted.");

        return replyContainer;
    }

    /// @notice Return comment, the comment is not checked on delete one
    /// @param postContainer The post where is the comment
    /// @param parentReplyId The parent reply
    /// @param commentId The commentId which need find
    function getCommentContainer(
        PostContainer storage postContainer,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (CommentContainer storage) {
        CommentContainer storage commentContainer;

        if (parentReplyId == 0) {
            commentContainer = postContainer.comments[commentId];  
        } else {
            ReplyContainer storage reply = getReplyContainerSafe(postContainer, parentReplyId);
            commentContainer = reply.comments[commentId];
        }
        require(!CommonLib.isEmptyIpfs(commentContainer.info.ipfsDoc.hash), "Comment does not exist.");

        return commentContainer;
    }

    /// @notice Return comment, the comment is checked on delete one
    /// @param postContainer The post where is the comment
    /// @param parentReplyId The parent reply
    /// @param commentId The commentId which need find
    function getCommentContainerSave(
        PostContainer storage postContainer,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (CommentContainer storage) {
        CommentContainer storage commentContainer = getCommentContainer(postContainer, parentReplyId, commentId);

        require(!commentContainer.info.isDeleted, "Comment has been deleted.");
        return commentContainer;
    }

    /// @notice Return post for unit tests
    /// @param self The mapping containing all posts
    /// @param postId The post which need find
    function getPost(
        PostCollection storage self,
        uint256 postId
    ) public view returns (Post memory) {        
        return self.posts[postId].info;
    }

    /// @notice Return reply for unit tests
    /// @param self The mapping containing all posts
    /// @param postId The post where is the reply
    /// @param replyId The reply which need find
    function getReply(
        PostCollection storage self, 
        uint256 postId, 
        uint16 replyId
    ) public view returns (Reply memory) {
        PostContainer storage postContainer = self.posts[postId];
        return getReplyContainer(postContainer, replyId).info;
    }

    /// @notice Return comment for unit tests
    /// @param self The mapping containing all posts
    /// @param postId Post where is the reply
    /// @param parentReplyId The parent reply
    /// @param commentId The comment which need find
    function getComment(
        PostCollection storage self, 
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (Comment memory) {
        PostContainer storage postContainer = self.posts[postId];
        return getCommentContainer(postContainer, parentReplyId, commentId).info;
    }

    /// @notice Get flag status vote (upvote/dovnvote) for post/reply/comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the vote
    /// @param postId The post where need to get flag status
    /// @param replyId The reply where need to get flag status
    /// @param commentId The comment where need to get flag status
    // return value:
    // downVote = -1
    // NONE = 0
    // upVote = 1
    function getStatusHistory(
        PostCollection storage self, 
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId
    ) public view returns (int256) {
        PostContainer storage postContainer = getPostContainer(self, postId);

        int256 statusHistory;
        if (commentId != 0) {
            CommentContainer storage commentContainer = getCommentContainerSave(postContainer, replyId, commentId);
            statusHistory = commentContainer.historyVotes[userAddr];
        } else if (replyId != 0) {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
            statusHistory = replyContainer.historyVotes[userAddr];
        } else {
            statusHistory = postContainer.historyVotes[userAddr];
        }

        return statusHistory;
    }

    /// @notice Get count upvotes and downvotes in item
    /// @param historyVotes history votes
    /// @param votedUsers Array voted users
    function getHistoryInformations(
        mapping(address => int256) storage historyVotes,
        address[] storage votedUsers
    ) private view returns (int32, int32) {
        int32 positive;
        int32 negative;
        uint256 countVotedUsers = votedUsers.length;
        for (uint256 i; i < countVotedUsers; i++) {
            if(historyVotes[votedUsers[i]] == 1) positive++;
            else if(historyVotes[votedUsers[i]] == -1) negative++;
        }
        return (positive, negative);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostLib.sol";


/// @title VoteLib
/// @notice Provides information about operation with posts                     //
/// @dev posts information is stored in the mapping on the main contract        ///
library VoteLib  {
    enum ResourceAction { Downvote, Upvoted, Downvoted, AcceptReply, AcceptedReply, FirstReply, QuickReply }

    struct StructRating {
        int32 upvotedPost;
        int32 downvotedPost;

        int32 upvotedReply;
        int32 downvotedReply;
        int32 firstReply;
        int32 quickReply;
        int32 acceptReply;
        int32 acceptedReply;
    }

    function getExpertRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedExpertPost,
           downvotedPost: DownvotedExpertPost,

           upvotedReply: UpvotedExpertReply,
           downvotedReply: DownvotedExpertReply,
           firstReply: FirstExpertReply,
           quickReply: QuickExpertReply,
           acceptReply: AcceptExpertReply,
           acceptedReply: AcceptedExpertReply
        });
    }

    function getCommonRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedCommonPost,
           downvotedPost: DownvotedCommonPost,

           upvotedReply: UpvotedCommonReply,
           downvotedReply: DownvotedCommonReply,
           firstReply: FirstCommonReply,
           quickReply: QuickCommonReply,
           acceptReply: AcceptCommonReply,
           acceptedReply: AcceptedCommonReply
        });
    }

    function getTutorialRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedTutorial,
           downvotedPost: DownvotedTutorial,

           upvotedReply: 0,
           downvotedReply: 0,
           firstReply: 0,
           quickReply: 0,
           acceptReply: 0,
           acceptedReply: 0
        });
    }

    // give proper names to constaints, e.g. DOWNVOTE_EXPERT_POST
    //expert post
    int32 constant DownvoteExpertPost = -1;
    int32 constant UpvotedExpertPost = 5;
    int32 constant DownvotedExpertPost = -2;        // -1

    //common post 
    int32 constant DownvoteCommonPost = -1;
    int32 constant UpvotedCommonPost = 1;
    int32 constant DownvotedCommonPost = -1;

    //tutorial 
    int32 constant DownvoteTutorial = -1;
    int32 constant UpvotedTutorial = 1;             // 10? !
    int32 constant DownvotedTutorial = -1 ;

    int32 constant DeleteOwnPost = -1;
    int32 constant ModeratorDeletePost = -2;

/////////////////////////////////////////////////////////////////////////////

    //expert reply
    int32 constant DownvoteExpertReply = -1;
    int32 constant UpvotedExpertReply = 10;
    int32 constant DownvotedExpertReply = -2;
    int32 constant AcceptExpertReply = 15;
    int32 constant AcceptedExpertReply = 2;
    int32 constant FirstExpertReply = 5;
    int32 constant QuickExpertReply = 5;

    //common reply 
    int32 constant DownvoteCommonReply = -1;
    int32 constant UpvotedCommonReply = 1;
    int32 constant DownvotedCommonReply = -1;
    int32 constant AcceptCommonReply = 3;
    int32 constant AcceptedCommonReply = 1;
    int32 constant FirstCommonReply = 1;
    int32 constant QuickCommonReply = 1;
    
    int32 constant DeleteOwnReply = -1;
    int32 constant ModeratorDeleteReply = -2;            // to do

/////////////////////////////////////////////////////////////////////////////////

    int32 constant DeleteOwnComment = -1;
    int32 constant ModeratorDeleteComment = -1;

    /// @notice Get value Rating for post action
    /// @param postType Type post: expertPost, commonPost, tutorial
    /// @param resourceAction Rating action: Downvote, Upvoted, Downvoted
    function getUserRatingChangeForPostAction(
        PostLib.PostType postType,
        ResourceAction resourceAction
    ) internal pure returns (int32) {
 
        if (PostLib.PostType.ExpertPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteExpertPost;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedExpertPost;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedExpertPost;

        } else if (PostLib.PostType.CommonPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteCommonPost;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedCommonPost;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedCommonPost;

        } else if (PostLib.PostType.Tutorial == postType) { // else -> check gas !
            if (ResourceAction.Downvote == resourceAction) return DownvoteTutorial;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedTutorial;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedTutorial;

        }
        
        revert("invalid_post_type");
    }

    /// @notice Get value Rating for rating action
    /// @param postType Type post: expertPost, commonPost, tutorial
    /// @param resourceAction Rating action: Downvote, Upvoted, Downvoted, AcceptReply...
    function getUserRatingChangeForReplyAction(
        PostLib.PostType postType,
        ResourceAction resourceAction
    ) internal pure returns (int32) {
 
        if (PostLib.PostType.ExpertPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteExpertReply;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedExpertReply;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedExpertReply;
            else if (ResourceAction.AcceptReply == resourceAction) return AcceptExpertReply;
            else if (ResourceAction.AcceptedReply == resourceAction) return AcceptedExpertReply;
            else if (ResourceAction.FirstReply == resourceAction) return FirstExpertReply;
            else if (ResourceAction.QuickReply == resourceAction) return QuickExpertReply;

        } else if (PostLib.PostType.CommonPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteCommonReply;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedCommonReply;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedCommonReply;
            else if (ResourceAction.AcceptReply == resourceAction) return AcceptCommonReply;
            else if (ResourceAction.AcceptedReply == resourceAction) return AcceptedCommonReply;
            else if (ResourceAction.FirstReply == resourceAction) return FirstCommonReply;
            else if (ResourceAction.QuickReply == resourceAction) return QuickCommonReply;

        } else if (PostLib.PostType.Tutorial == postType) {
            return 0;
        }
        
        revert("invalid_resource_type");
    }

    function getUserRatingChange(
        PostLib.PostType postType,
        ResourceAction resourceAction,
        PostLib.TypeContent typeContent
    ) internal pure returns (int32) {
        if (PostLib.TypeContent.Post == typeContent) {
            return getUserRatingChangeForPostAction(postType, resourceAction);
        } else if (PostLib.TypeContent.Reply == typeContent) {
            return getUserRatingChangeForReplyAction(postType, resourceAction);
        }
        return 0;
    }

    /// @notice Get vote history
    /// @param user user who voted for content
    /// @param historyVote history vote all users
    // return value:
    // downVote = -1
    // NONE = 0
    // upVote = 1
    function getHistoryVote(
        address user,
        mapping(address => int256) storage historyVote
    ) private view returns (int256) {
        return historyVote[user];
    }

    /// @notice .
    /// @param actionAddress user who voted for content
    /// @param historyVotes history vote all users
    /// @param isUpvote Upvote or downvote
    /// @param votedUsers the list users who voted
    // return value:
    // fromUpVoteToDownVote = -2
    // cancel downVote = 1  && upVote = 1       !!!!
    // cancel upVote = -1   && downVote = -1    !!!!
    // fromDownVoteToUpVote = 2
    function getForumItemRatingChange(
        address actionAddress,
        mapping(address => int256) storage historyVotes,
        bool isUpvote,
        address[] storage votedUsers
    ) internal returns (int32, bool) {
        int history = getHistoryVote(actionAddress, historyVotes);
        int32 ratingChange;
        bool isCancel;
        
        if (isUpvote) {
            if (history == -1) {
                historyVotes[actionAddress] = 1;
                ratingChange = 2;
            } else if (history == 0) {
                historyVotes[actionAddress] = 1;
                ratingChange = 1;
                votedUsers.push(actionAddress);
            } else {
                historyVotes[actionAddress] = 0;
                //clear votedUsers
                ratingChange = -1;
                isCancel = true;
            }
        } else {
            if (history == -1) {
                historyVotes[actionAddress] = 0;
                //clear votedUsers
                ratingChange = 1;
                isCancel = true;
            } else if (history == 0) {
                historyVotes[actionAddress] = -1;
                ratingChange = -1;
                votedUsers.push(actionAddress);
            } else {
                historyVotes[actionAddress] = -1;
                ratingChange = -2;
            }
        }
        return (ratingChange, isCancel);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function __EIP712_init(
        string memory name
    )
        internal
        onlyInitializing
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}