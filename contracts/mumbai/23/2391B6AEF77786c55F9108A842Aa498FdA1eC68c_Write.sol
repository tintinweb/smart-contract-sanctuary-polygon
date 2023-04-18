// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface IAccount {
    function version() external pure returns (string memory);

    function addCommunityUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function removeCommunityUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addModerator(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function removeModerator(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addCreatedPostIdForUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addCreatedCommentIdForUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function getCommunityUsersCounts(address _communityId) external view returns(
        uint256 normalUsers,
        uint256 bannedUsers,
        uint256 moderatorsUsers
    );

    function getCommunityUsers(address _communityId) external view returns(
        address[] memory normalUsers,
        address[] memory bannedUsers,
        address[] memory moderators
    );

    function isCommunityUser(address _communityId, address _user) external view returns(bool);

    function isBannedUser(address _communityId, address _user) external view returns(bool);

    function isModerator(address _communityId, address _user) external view returns(bool);

    function getCommunitiesByUser(address _user) external view returns(
        address[] memory _communities
    );

    function getPostIdsByUserAndCommunity(address _communityId, address _user) external view returns(
        uint256[] memory _withCommentPostIds,
        uint256[] memory _createdPostIds
    );

    function getCommentIdsByUserAndPost(
        address _communityId,
        address _user,
        uint256 _postId
    ) external view returns(uint256[] memory _commentIds);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface ICommentData {

    function version() external pure returns (string memory);

    function ipfsHashOf(uint256 _postId, uint256 _commentId) external view returns (string memory);

    function writeComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(uint256);

    function burnComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function setVisibility(
        DataTypes.SimpleVars calldata vars
    ) external returns(bool);

    function setGasCompensation(
        DataTypes.GasCompensationComment calldata vars
    ) external returns(
        uint256 gasConsumption,
        address creator,
        address owner
    );

    function setGasConsumption(
        DataTypes.MinSimpleVars calldata vars
    ) external returns(bool);

    function readComment(
        DataTypes.MinSimpleVars calldata vars
    ) external view returns(
        DataTypes.CommentInfo memory outData
    );

    function getCommentCount(uint256 _postId) external view returns(uint256);

    function getUpDownForComment(uint256 _postId, uint256 _commentId) external view returns(bool, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../libraries/DataTypes.sol";


interface ICommunityBlank {

    function creator() external view returns (address);

    function name() external view returns (string memory);

    function creatingTime() external view returns (uint256);

    function authorGasCompensationPercent() external view returns (uint256);

    function ownerGasCompensationPercent() external view returns (uint256);

    function linkPlugin(bytes32 _pluginName, uint256 _version) external;

    function unLinkPlugin(bytes32 _pluginName, uint256 _version) external;

    function isLinkedPlugin(bytes32 _pluginName, uint256 _version) external view returns (bool);

    function linkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function unLinkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function isLinkedRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external view returns (bool);

    function claimERC20Token(IERC20 _token, address _receiver, uint256 _amount) external;

    function setGasCompensationPercent(uint256 _authorPercent) external;

    function setPrice(DataTypes.PaymentType _paymentType, uint256 _newPrice) external;

    function getPrice(DataTypes.PaymentType _paymentType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface ICommunityData {

    function version() external pure returns (string memory);

    function isCommunity(address _community) external view returns (bool);

    function addCommunity(
        DataTypes.SimpleVars calldata vars
    ) external returns (bool);

    function addCreatedPostIdForCommunity(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function getCommunities(uint256 _startIndex, uint256 _endIndex) external view returns (address[] memory result);

    function communitiesCount() external view returns (uint256);

    function isLegalPostId(address _community, uint256 _postId) external view returns (bool);

    function getPostIds(address _community) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface IPostData {

    function version() external pure returns (string memory);

    function ipfsHashOf(uint256 _tokenId) external view returns (string memory);

    function writePost(
        DataTypes.GeneralVars calldata vars
    ) external returns(uint256);

    function burnPost(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function readPost(
        DataTypes.MinSimpleVars calldata vars
    ) external view returns(
        DataTypes.PostInfo memory outData
    );

    function getCommunityId(uint256 _postId) external view returns(address);

    function setVisibility(
        DataTypes.SimpleVars calldata vars
    ) external returns(bool);

    function setGasConsumption(
        DataTypes.MinSimpleVars calldata vars
    ) external returns(bool);

    function updatePostWhenNewComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function setGasCompensation(
        DataTypes.SimpleVars calldata vars
    ) external returns(
        uint256 price,
        address creator
    );

    function isEncrypted(uint256 _postId) external view returns(bool);

    function isCreator(uint256 _postId, address _user) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


library DataTypes {

    struct PostInfo {
        address creator;
        address currentOwner;
        address communityId;
        address repostFromCommunity;
        uint256 upCount;
        uint256 downCount;
        uint256 commentCount;
        uint256 encodingType;
        uint256 timestamp;
        uint256 gasConsumption;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
        string category;
        string[] tags;
    }

    struct CommentInfo {
        address creator;
        address owner;
        address communityId;
        uint256 timestamp;
        uint256 gasConsumption;
        bool up;
        bool down;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
    }

    struct CommunityInfo {
        string name;
        address creator;
        address owner;
        uint256 creatingTime;
        uint256[] postIds;
        address[] normalUsers;
        address[] bannedUsers;
        address[] moderators;
    }

    enum UserRatesType {
        RESERVE, FOR_POST, FOR_COMMENT, FOR_UP, FOR_DOWN,
        FOR_DEAL_GUARANTOR, FOR_DEAL_SELLER, FOR_DEAL_BUYER
    }

    enum PaymentType {
        RESERVE, FOR_COMMUNITY_JOIN, FOR_PERIODIC_ACCESS, FOR_ADS, FOR_MAKE_CONTENT
    }

    struct MinSimpleVars {
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct SimpleVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct GeneralVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        bytes data;
    }

    struct SoulBoundMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 id;
        uint256 amount;
    }

    struct SoulBoundBatchMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256[] ids;
        uint256[] amounts;
    }

    struct UserRateCount {
        uint256 commentCount;
        uint256 postCount;
        uint256 upCount;
        uint256 downCount;
    }

    struct GasCompensationComment {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        uint256 postId;
        uint256 commentId;
    }

    struct GasCompensationBank {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 gas;
    }

    struct PaymentInfo {
        uint256 startTime;
        uint256 endTime;
        address communityId;
        address owner;
        DataTypes.PaymentType paymentType;
    }

    struct DealMessage {
        string message;
        address sender;
        uint256 writeTime;
    }

    struct SafeDeal {
        string description;
        address seller;
        address buyer;
        address guarantor;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool startSellerApprove;
        bool startBuyerApprove;
        bool endSellerApprove;
        bool endBuyerApprove;
        bool isIssue;
        bool isFinished;
        DealMessage[] messages;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";

import "../registry/interfaces/IRegistry.sol";
import "../community/interfaces/ICommunityBlank.sol";


abstract contract BasePlugin is Context {

    uint256 internal PLUGIN_VERSION;
    bytes32 public PLUGIN_NAME;

    IRegistry public registry;

    modifier onlyExecutor() {
        require(registry.executor() == _msgSender(), "BasePlugin: caller is not the executor");
        _;
    }

    function version() external view returns (uint256) {
        return PLUGIN_VERSION;
    }

    function checkPlugin(uint256 _version, address _communityId) internal virtual view {
        require(_version == PLUGIN_VERSION, "BasePlugin: wrong version");
        (bool enable, address pluginContract) = registry.getPlugin(PLUGIN_NAME, PLUGIN_VERSION);
        require(enable, "BasePlugin: wrong enable plugin");
        require(pluginContract == address(this), "BaseWritePlugin: wrong plugin contract");

        if (_communityId != address(0)) {
            bool isLinked = ICommunityBlank(_communityId).isLinkedPlugin(PLUGIN_NAME, PLUGIN_VERSION);
            require(isLinked, "BasePlugin: plugin is not linked for the community");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../registry/interfaces/IRegistry.sol";
import "./BasePlugin.sol";

import "../rules/community/interfaces/IBaseRules.sol";
import "../rules/community/interfaces/IBaseRulesWithPostId.sol";
import "../rules/interfaces/IRule.sol";


abstract contract BasePluginWithRules is BasePlugin {

    function checkBaseRule(bytes32 _groupRulesName, address _communityId, address _sender) internal view {
        address rulesContract = IRule(registry.rule()).getRuleContract(
            _groupRulesName,
            PLUGIN_VERSION
        );
        require(
            IBaseRules(rulesContract).validate(_communityId, _sender),
            "BasePluginWithRules: wrong base rules validate"
        );
    }

    function checkRuleWithNftId(bytes32 _groupRulesName, address _communityId, address _sender, uint256 _tokenId) internal view {
        address rulesContract = IRule(registry.rule()).getRuleContract(
            _groupRulesName,
            PLUGIN_VERSION
        );
        require(
            IBaseRulesWithPostId(rulesContract).validate(_communityId, _sender, _tokenId),
            "BasePluginWithRules: wrong rules with postId validate"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../account/interfaces/IAccount.sol";
import "../../community/interfaces/ICommentData.sol";
import "../../community/interfaces/IPostData.sol";
import "../../community/interfaces/ICommunityData.sol";
import "../../registry/interfaces/IRegistry.sol";

import "../../rules/community/RulesList.sol";
import "../PluginsList.sol";
import "../interfaces/IExecutePlugin.sol";
import "../../libraries/DataTypes.sol";
import "../BasePluginWithRules.sol";


contract Write is IExecutePlugin, BasePluginWithRules {

    constructor(address _registry) {
        PLUGIN_VERSION = 1;
        PLUGIN_NAME = PluginsList.COMMUNITY_WRITE_COMMENT;
        registry = IRegistry(_registry);
    }

    function execute(
        bytes32 _executedId,
        uint256 _version,
        address _sender,
        bytes calldata _data
    ) external override onlyExecutor returns(bool) {
        uint256 beforeGas = gasleft();

        (address _communityId , uint256 _postId, , , , , ) =
        abi.decode(_data,(address, uint256, address, string, bool, bool, bool));

        require(_communityId != address(0), "Write: wrong community");
        checkPlugin(_version, _communityId);

        require(IAccount(registry.account()).isCommunityUser(_communityId, _sender), "Write: wrong _sender");

        checkBaseRule(RulesList.USER_VERIFICATION_RULES, _communityId, _sender);
        checkRuleWithNftId(RulesList.POST_COMMENTING_RULES, _communityId, _sender, _postId);

        DataTypes.GeneralVars memory vars;
        vars.executedId = _executedId;
        vars.pluginName = PLUGIN_NAME;
        vars.version = PLUGIN_VERSION;
        vars.user = _sender;
        vars.data = _data;

        DataTypes.MinSimpleVars memory gasVars;
        gasVars.pluginName = PLUGIN_NAME;
        gasVars.version = PLUGIN_VERSION;

        uint256 commentId = ICommentData(registry.commentData()).writeComment(vars);
        require(commentId > 0, "Write: wrong create comment");

        require(IPostData(registry.postData()).updatePostWhenNewComment(vars),
            "Write: wrong added commentId for user"
        );

        vars.data = abi.encode(_communityId, _postId, commentId);
        require(IAccount(registry.account()).addCreatedCommentIdForUser(vars),
            "Write: wrong added commentId for user"
        );

        uint256 gasPrice = beforeGas - gasleft();
        gasVars.data = abi.encode(_postId, commentId, gasPrice);
        require(
            ICommentData(registry.commentData()).setGasConsumption(gasVars),
            "Write: wrong set price"
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IExecutePlugin {

    function execute(bytes32 executedId, uint256 version, address sender, bytes calldata data) external returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Contract of Page.PluginsList
/// @notice This contract contains a list of plugin names.
/// @dev Constants from this list are used to access plugins settings.
library PluginsList {

    bytes32 public constant COMMUNITY_CREATE = keccak256(abi.encode("COMMUNITY_CREATE"));
    bytes32 public constant COMMUNITY_JOIN = keccak256(abi.encode("COMMUNITY_JOIN"));
    bytes32 public constant COMMUNITY_QUIT = keccak256(abi.encode("COMMUNITY_QUIT"));
    bytes32 public constant COMMUNITY_INFO = keccak256(abi.encode("COMMUNITY_INFO"));
    bytes32 public constant COMMUNITY_PROFIT = keccak256(abi.encode("COMMUNITY_PROFIT"));

    bytes32 public constant USER_INFO_ONE_COMMUNITY = keccak256(abi.encode("USER_INFO_ONE_COMMUNITY"));
    bytes32 public constant USER_INFO_ALL_COMMUNITIES = keccak256(abi.encode("USER_INFO_ALL_COMMUNITIES"));

    bytes32 public constant COMMUNITY_WRITE_POST = keccak256(abi.encode("COMMUNITY_WRITE_POST"));
    bytes32 public constant COMMUNITY_READ_POST = keccak256(abi.encode("COMMUNITY_READ_POST"));
    bytes32 public constant COMMUNITY_BURN_POST = keccak256(abi.encode("COMMUNITY_BURN_POST"));
    bytes32 public constant COMMUNITY_TRANSFER_POST = keccak256(abi.encode("COMMUNITY_TRANSFER_POST"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_POST = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_POST"));
    bytes32 public constant COMMUNITY_POST_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_POST_GAS_COMPENSATION"));
    bytes32 public constant COMMUNITY_EDIT_MODERATORS = keccak256(abi.encode("COMMUNITY_EDIT_MODERATORS"));
    bytes32 public constant COMMUNITY_REPOST = keccak256(abi.encode("COMMUNITY_REPOST"));

    bytes32 public constant COMMUNITY_WRITE_COMMENT = keccak256(abi.encode("COMMUNITY_WRITE_COMMENT"));
    bytes32 public constant COMMUNITY_READ_COMMENT = keccak256(abi.encode("COMMUNITY_READ_COMMENT"));
    bytes32 public constant COMMUNITY_BURN_COMMENT = keccak256(abi.encode("COMMUNITY_BURN_COMMENT"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_COMMENT = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_COMMENT"));
    bytes32 public constant COMMUNITY_COMMENT_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_COMMENT_GAS_COMPENSATION"));

    bytes32 public constant BANK_DEPOSIT = keccak256(abi.encode("BANK_DEPOSIT"));
    bytes32 public constant BANK_WITHDRAW = keccak256(abi.encode("BANK_WITHDRAW"));
    bytes32 public constant BANK_BALANCE_OF = keccak256(abi.encode("BANK_BALANCE_OF"));

    bytes32 public constant SOULBOUND_GENERATE = keccak256(abi.encode("SOULBOUND_GENERATE"));
    bytes32 public constant SOULBOUND_BALANCE_OF = keccak256(abi.encode("SOULBOUND_BALANCE_OF"));

    bytes32 public constant SUBSCRIPTION_BUY = keccak256(abi.encode("SUBSCRIPTION_BUY"));
    bytes32 public constant SUBSCRIPTION_INFO = keccak256(abi.encode("SUBSCRIPTION_INFO"));

    bytes32 public constant SAFE_DEAL_MAKE = keccak256(abi.encode("SAFE_DEAL_MAKE"));
    bytes32 public constant SAFE_DEAL_READ = keccak256(abi.encode("SAFE_DEAL_READ"));
    bytes32 public constant SAFE_DEAL_CANCEL = keccak256(abi.encode("SAFE_DEAL_CANCEL"));
    bytes32 public constant SAFE_DEAL_FINISH = keccak256(abi.encode("SAFE_DEAL_FINISH"));
    bytes32 public constant SAFE_DEAL_ADD_MESSAGE = keccak256(abi.encode("SAFE_DEAL_ADD_MESSAGE"));
    bytes32 public constant SAFE_DEAL_SET_ISSUE = keccak256(abi.encode("SAFE_DEAL_SET_ISSUE"));
    bytes32 public constant SAFE_DEAL_CLEAR_ISSUE = keccak256(abi.encode("SAFE_DEAL_CLEAR_ISSUE"));
    bytes32 public constant SAFE_DEAL_SET_APPROVE = keccak256(abi.encode("SAFE_DEAL_SET_APPROVE"));
    bytes32 public constant SAFE_DEAL_CHANGE_TIME = keccak256(abi.encode("SAFE_DEAL_CHANGE_TIME"));
    bytes32 public constant SAFE_DEAL_CHANGE_DESCRIPTION = keccak256(abi.encode("SAFE_DEAL_CHANGE_DESCRIPTION"));

    function version() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRegistry {

    function version() external pure returns (string memory);

    function bank() external view returns (address);

    function oracle() external view returns (address);

    function uniV3Pool() external view returns (address);

    function token() external view returns (address);

    function dao() external view returns (address);

    function treasury() external view returns (address);

    function executor() external view returns (address);

    function rule() external view returns (address);

    function communityData() external view returns (address);

    function postData() external view returns (address);

    function commentData() external view returns (address);

    function account() external view returns (address);

    function soulBound() external view returns (address);

    function subscription() external view returns (address);

    function nft() external view returns (address);

    function safeDeal() external view returns (address);

    function profitDistribution() external view returns (address);

    function superAdmin() external view returns (address);

    function setBank(address _contract) external;

    function setToken(address _contract) external;

    function setOracle(address _contract) external;

    function setUniV3Pool(address _contract) external;

    function setExecutor(address _executor) external;

    function setCommunityData(address _contract) external;

    function setPostData(address _contract) external;

    function setCommentData(address _contract) external;

    function setAccount(address _contract) external;

    function setSoulBound(address _contract) external;

    function setSubscription(address _contract) external;

    function setProfitDistribution(address _contract) external;

    function setRule(address _contract) external;

    function setNFT(address _contract) external;

    function setSafeDeal(address _contract) external;

    function setSuperAdmin(address _user) external;

    function setVotingContract(address _contract, bool _status) external;

    function setPlugin(
        bytes32 _pluginName,
        uint256 _version,
        address _pluginContract
    ) external;

    function changePluginStatus(
        bytes32 _pluginName,
        uint256 _version
    ) external;

    function getPlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable, address pluginContract);

    function getPluginContract(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (address pluginContract);

    function isEnablePlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable);

    function isVotingContract(
        address _contract
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBaseRules {

    function validate(address _communityId, address _user) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBaseRulesWithPostId {

    function validate(address _communityId, address _user, uint256 _postId) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Contract of Page.RulesList
/// @notice This contract contains a list of rules.
/// @dev Constants from this list are used to access rules settings.
library  RulesList {

    // Community Joining Rules
    bytes32 public constant COMMUNITY_JOINING_RULES = keccak256(abi.encode("PAGE.COMMUNITY_JOINING_RULES"));
    bytes32 public constant OPEN_TO_ALL = keccak256(abi.encode("OPEN_TO_ALL"));
    bytes32 public constant SOULBOUND_TOKENS_USING = keccak256(abi.encode("SOULBOUND_TOKENS_USING"));
    bytes32 public constant WHEN_JOINING_PAYMENT = keccak256(abi.encode("WHEN_JOINING_PAYMENT"));
    bytes32 public constant PERIODIC_PAYMENT = keccak256(abi.encode("PERIODIC_PAYMENT"));

    // Community Edit Moderators Rules
    bytes32 public constant COMMUNITY_EDIT_MODERATOR_RULES = keccak256(abi.encode("PAGE.COMMUNITY_EDIT_MODERATOR_RULES"));
    bytes32 public constant NO_EDIT_MODERATOR = keccak256(abi.encode("NO_EDIT_MODERATOR"));
    bytes32 public constant EDIT_AFTER_VOTED = keccak256(abi.encode("EDIT_AFTER_VOTED"));
    bytes32 public constant EDIT_ONLY_SUPER_ADMIN = keccak256(abi.encode("EDIT_ONLY_SUPER_ADMIN"));
    bytes32 public constant EDIT_BY_CREATOR = keccak256(abi.encode("EDIT_BY_CREATOR"));

    // Community Post Placing Rules
    bytes32 public constant POST_PLACING_RULES = keccak256(abi.encode("PAGE.POST_PLACING_RULES"));
    bytes32 public constant FREE_FOR_EVERYONE = keccak256(abi.encode("FREE_FOR_EVERYONE"));
    bytes32 public constant PAYMENT_FROM_EVERYONE = keccak256(abi.encode("PAYMENT_FROM_EVERYONE"));
    bytes32 public constant COMMUNITY_MEMBERS_ONLY = keccak256(abi.encode("COMMUNITY_MEMBERS_ONLY"));
    bytes32 public constant COMMUNITY_FOUNDERS_ONLY = keccak256(abi.encode("COMMUNITY_FOUNDERS_ONLY"));

    // Community Accepting Post Rules
    bytes32 public constant ACCEPTING_POST_RULES = keccak256(abi.encode("PAGE.ACCEPTING_POST_RULES"));
    bytes32 public constant ACCEPTING_FOR_EVERYONE = keccak256(abi.encode("ACCEPTING_FOR_EVERYONE"));
    bytes32 public constant ACCEPTING_FOR_COMMUNITY_MEMBERS_ONLY = keccak256(abi.encode("ACCEPTING_FOR_COMMUNITY_MEMBERS_ONLY"));
    bytes32 public constant ACCEPTING_AFTER_MODERATOR_APPROVED = keccak256(abi.encode("ACCEPTING_AFTER_MODERATOR_APPROVED"));
    bytes32 public constant ACCEPTING_FOR_COMMUNITY_FOUNDERS_ONLY = keccak256(abi.encode("ACCEPTING_FOR_COMMUNITY_FOUNDERS_ONLY"));

    // Community Post Reading Rules
    bytes32 public constant POST_READING_RULES = keccak256(abi.encode("PAGE.POST_READING_RULES"));
    bytes32 public constant READING_FOR_EVERYONE = keccak256(abi.encode("READING_FOR_EVERYONE"));
    bytes32 public constant READING_ENCRYPTED = keccak256(abi.encode("READING_ENCRYPTED"));

    // Community Post Commenting Rules
    bytes32 public constant POST_COMMENTING_RULES = keccak256(abi.encode("PAGE.POST_COMMENTING_RULES"));
    bytes32 public constant COMMENTING_MANY_TIMES = keccak256(abi.encode("COMMENTING_MANY_TIMES"));
    bytes32 public constant COMMENTING_ONE_TIME = keccak256(abi.encode("COMMENTING_ONE_TIME"));
    bytes32 public constant COMMENTING_WITH_SOULBOUND_TOKENS = keccak256(abi.encode("COMMENTING_WITH_SOULBOUND_TOKENS"));

    // Change Visibility Content Rules
    bytes32 public constant CHANGE_VISIBILITY_CONTENT_RULES = keccak256(abi.encode("PAGE.CHANGE_VISIBILITY_CONTENT_RULES"));
    bytes32 public constant NO_CHANGE_VISIBILITY = keccak256(abi.encode("NO_CHANGE_VISIBILITY"));
    bytes32 public constant CHANGE_VISIBILITY_USING_VOTING = keccak256(abi.encode("CHANGE_VISIBILITY_USING_VOTING"));
    bytes32 public constant CHANGE_VISIBILITY_ONLY_MODERATORS = keccak256(abi.encode("CHANGE_VISIBILITY_ONLY_MODERATORS"));
    bytes32 public constant CHANGE_VISIBILITY_ONLY_OWNER = keccak256(abi.encode("CHANGE_VISIBILITY_ONLY_OWNER"));

    // Community Moderation Rules
    bytes32 public constant MODERATION_RULES = keccak256(abi.encode("PAGE.MODERATION_RULES"));
    bytes32 public constant NO_MODERATOR = keccak256(abi.encode("NO_MODERATOR"));
    bytes32 public constant MODERATION_USING_VOTING = keccak256(abi.encode("MODERATION_USING_VOTING"));
    bytes32 public constant MODERATION_USING_MODERATORS = keccak256(abi.encode("MODERATION_USING_MODERATORS"));
    bytes32 public constant MODERATION_USING_OWNER = keccak256(abi.encode("MODERATION_USING_OWNER"));

    // User Verification Rules
    bytes32 public constant USER_VERIFICATION_RULES = keccak256(abi.encode("PAGE.USER_VERIFICATION_RULES"));
    bytes32 public constant NO_VERIFICATION = keccak256(abi.encode("NO_VERIFICATION"));
    bytes32 public constant USING_VERIFICATION = keccak256(abi.encode("USING_VERIFICATION"));

    // Community Gas Compensation Rules
    bytes32 public constant GAS_COMPENSATION_RULES = keccak256(abi.encode("PAGE.GAS_COMPENSATION_RULES"));
    bytes32 public constant NO_GAS_COMPENSATION = keccak256(abi.encode("NO_GAS_COMPENSATION"));
    bytes32 public constant GAS_COMPENSATION_FOR_COMMUNITY = keccak256(abi.encode("GAS_COMPENSATION_FOR_COMMUNITY"));
    bytes32 public constant GAS_COMPENSATION_FOR_AUTHOR = keccak256(abi.encode("GAS_COMPENSATION_FOR_AUTHOR"));
    bytes32 public constant GAS_COMPENSATION_FOR_OWNER = keccak256(abi.encode("GAS_COMPENSATION_FOR_OWNER"));
    bytes32 public constant GAS_COMPENSATION_FOR_AUTHOR_AND_OWNER = keccak256(abi.encode("GAS_COMPENSATION_FOR_AUTHOR_AND_OWNER"));

    // Community Advertising Placement Rules
    bytes32 public constant ADVERTISING_PLACEMENT_RULES = keccak256(abi.encode("PAGE.ADVERTISING_PLACEMENT_RULES"));
    bytes32 public constant NO_ADVERTISING = keccak256(abi.encode("NO_ADVERTISING"));
    bytes32 public constant ADVERTISING_BY_FOUNDERS = keccak256(abi.encode("ADVERTISING_BY_FOUNDERS"));
    bytes32 public constant ADVERTISING_BY_MODERATORS = keccak256(abi.encode("ADVERTISING_BY_MODERATORS"));
    bytes32 public constant ADVERTISING_BY_ALL = keccak256(abi.encode("ADVERTISING_BY_ALL"));
    bytes32 public constant ADVERTISING_BY_SPECIAL_USER = keccak256(abi.encode("ADVERTISING_BY_SPECIAL_USER"));

    // Community Profit Distribution Rules
    bytes32 public constant PROFIT_DISTRIBUTION_RULES = keccak256(abi.encode("PAGE.PROFIT_DISTRIBUTION_RULES"));
    bytes32 public constant DISTRIBUTION_USING_SOULBOUND_TOKENS = keccak256(abi.encode("DISTRIBUTION_USING_SOULBOUND_TOKENS"));
    bytes32 public constant DISTRIBUTION_FOR_EVERYONE = keccak256(abi.encode("DISTRIBUTION_FOR_EVERYONE"));
    bytes32 public constant DISTRIBUTION_USING_VOTING = keccak256(abi.encode("DISTRIBUTION_USING_VOTING"));
    bytes32 public constant DISTRIBUTION_FOR_FOUNDERS = keccak256(abi.encode("DISTRIBUTION_FOR_FOUNDERS"));

    // Community Reputation Management Rules
    bytes32 public constant REPUTATION_MANAGEMENT_RULES = keccak256(abi.encode("PAGE.REPUTATION_MANAGEMENT_RULES"));
    bytes32 public constant REPUTATION_NOT_USED = keccak256(abi.encode("REPUTATION_NOT_USED"));
    bytes32 public constant REPUTATION_CAN_CHANGE = keccak256(abi.encode("REPUTATION_CAN_CHANGE"));

    // Community Post Transferring Rules
    bytes32 public constant POST_TRANSFERRING_RULES = keccak256(abi.encode("PAGE.POST_TRANSFERRING_RULES"));
    bytes32 public constant TRANSFERRING_DENIED = keccak256(abi.encode("TRANSFERRING_DENIED"));
    bytes32 public constant TRANSFERRING_WITH_VOTING = keccak256(abi.encode("TRANSFERRING_WITH_VOTING"));
    bytes32 public constant TRANSFERRING_ONLY_AUTHOR = keccak256(abi.encode("TRANSFERRING_ONLY_AUTHOR"));

    function version() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IRule {

    function version() external pure returns (string memory);

    function setRuleContract(bytes32 _ruleGroupName, uint256 _version, address _ruleContract) external;

    function enableRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function disableRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function isSupportedRule(
        bytes32 _ruleGroupName,
        uint256 _version,
        bytes32 _ruleName
    ) external view returns (bool);

    function getRuleContract(
        bytes32 _ruleGroupName,
        uint256 _version
    ) external view returns (address);

}