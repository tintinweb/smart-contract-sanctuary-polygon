// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.13;

import {
    IBhavishRealTimePredictionERC20,
    IBhavishRealTimePrediction
} from "../../../Interface/IBhavishRealTimePredictionERC20.sol";
import { AbstractQ } from "./AbstractQ.sol";

contract LossyQ is AbstractQ {
    constructor(IBhavishRealTimePrediction _market) AbstractQ(_market) {}

    function enterMarket(
        uint256 _marketId,
        uint256 _outcomeId,
        uint256 _amount,
        address _user,
        address _provider
    ) internal override {
        IBhavishRealTimePredictionERC20(address(market)).placeBet(_marketId, _outcomeId, _amount, _user, _provider);
    }

    function enter(
        uint256 _questId,
        uint256 _totalWeigth,
        uint256[] calldata _betOutcomes,
        uint256[] calldata _weightage,
        uint256 _amount,
        address _provider
    ) external {
        _enter(_questId, _amount, _totalWeigth, _betOutcomes, _weightage, _provider);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.13;

import { IBhavishRealTimePrediction } from "../../../Interface/IBhavishRealTimePrediction.sol";
import { BaseRelayRecipient } from "../../../Integrations/Gasless/BaseRelayRecipient.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AbstractQ is AccessControl, BaseRelayRecipient {
    // mapping quest to list of markets
    struct Quest {
        uint256 id;
        uint256[] markets;
        uint256 opensAtTimestamp;
        uint256 closesAtTimestamp;
        string title;
        string category;
        string description;
        string image;
        bool active;
    }

    event QuestCreated(address indexed user, string indexed category, uint256 indexed questId, string title);
    event QuestUpdated(uint256 indexed questId, string indexed newCategory);
    event QuestEntered(address indexed user, uint256 indexed questId, uint256 indexed amount, uint256[] weightage);
    event QuestDisabled(uint256 indexed questId);
    event Claimed(address indexed user, uint256 indexed questId, uint256 amount);
    event NewOperator(address indexed operator);

    IBhavishRealTimePrediction public market;
    address public provider;
    uint256[] public questIds;
    mapping(uint256 => Quest) public quests;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Implement following vitual methods --------

    function enterMarket(
        uint256 _marketId,
        uint256 _outcomeId,
        uint256 _amount,
        address _user,
        address _provider
    ) internal virtual;

    // Modifiers go here --------

    modifier onlyAdmin(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Address not an admin");
        _;
    }

    modifier onlyOperator(address _address) {
        require(hasRole(OPERATOR_ROLE, _address), "Address not an operator");
        _;
    }

    constructor(IBhavishRealTimePrediction _market) {
        market = _market;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createQuest(
        IBhavishRealTimePrediction.MarketQuestion[] memory _questions,
        uint256 _opensAt,
        uint256 _closesAt,
        string memory _title,
        string memory _category,
        string memory _description,
        string memory _image,
        bool _arbitrator
    ) external onlyOperator(msg.sender) {
        uint256 questId = questIds.length;
        questIds.push(questId);

        uint256[] memory marketIds = new uint256[](_questions.length);
        require(bytes(_title).length > 20, "Title > 20 bytes");
        require(bytes(_description).length > 50, "desc > 50 bytes");
        require(bytes(_category).length > 0, "category can't be empty");

        // create all market via quest
        for (uint256 i = 0; i < _questions.length; i++) {
            marketIds[i] = market.createMarket(_questions[i], _opensAt, _closesAt, true, true, _arbitrator);
        }

        Quest storage quest = quests[questId];
        quest.id = questId;
        quest.markets = marketIds;
        quest.title = _title;
        quest.description = _description;
        quest.category = _category;
        quest.image = _image;
        quest.opensAtTimestamp = _opensAt;
        quest.closesAtTimestamp = _closesAt;
        quest.active = true;

        emit QuestCreated(msg.sender, _category, questId, _title);
    }

    // weigtage should be according to the markets
    function _enter(
        uint256 _questId,
        uint256 _amount,
        uint256 _totalWeigth,
        uint256[] calldata betOutcomes,
        uint256[] calldata weightage,
        address _provider
    ) internal {
        Quest storage quest = quests[_questId];
        require(quest.active == true, "quest inactive");
        require(
            quest.opensAtTimestamp <= block.timestamp && quest.closesAtTimestamp >= block.timestamp,
            "Inactive quest"
        );
        require(betOutcomes.length == quest.markets.length, "invalid betOutcomes");
        require(weightage.length == quest.markets.length, "invalid weightage");

        uint256 totalWeightage = _totalWeigth;
        uint256 amountDistributed;
        for (uint256 i = 0; i < quest.markets.length; i++) {
            // utilise remaining amount for the last market
            uint256 _mAmount;
            if (i == quest.markets.length - 1) _mAmount = _amount - amountDistributed;
            else _mAmount = (_amount * weightage[i]) / _totalWeigth;
            amountDistributed += _mAmount;

            enterMarket(quest.markets[i], betOutcomes[i], _mAmount, msgSender(), _provider);
            // validate total weightage
            totalWeightage -= weightage[i];
        }
        require(totalWeightage == 0, "invalid total weightage");

        emit QuestEntered(msgSender(), _questId, _amount, weightage);
    }

    function disableQuest(uint256 _questId) external onlyOperator(msg.sender) {
        Quest storage quest = quests[_questId];
        require(quest.active == true, "quest already inactive");

        quest.active = false;
        emit QuestDisabled(_questId);
    }

    function updateCategory(uint256 _questId, string memory _newCategory) external onlyOperator(msg.sender) {
        Quest storage quest = quests[_questId];
        require(quest.active, "invalid quest");

        quest.category = _newCategory;
        emit QuestUpdated(_questId, _newCategory);
    }

    function claim(uint256 _questId) external {
        Quest memory quest = quests[_questId];
        uint256 rewards;
        for (uint256 i = 0; i < quest.markets.length; i++) {
            IBhavishRealTimePrediction.MarketDetails memory marketDetails = market.getMarketData(quest.markets[i]);
            require(
                marketDetails.state == IBhavishRealTimePrediction.MarketState.RESOLVED ||
                    marketDetails.state == IBhavishRealTimePrediction.MarketState.CLOSED,
                "quest not resolved yet"
            );
            if (
                marketDetails.state == IBhavishRealTimePrediction.MarketState.RESOLVED &&
                !market.isClaimed(quest.markets[i], msgSender())
            ) rewards += market.claim(quest.markets[i], msgSender());
            if (
                marketDetails.state == IBhavishRealTimePrediction.MarketState.CLOSED &&
                !market.isRefunded(quest.markets[i], msgSender())
            ) market.refundUser(quest.markets[i], msgSender());
        }
        emit Claimed(msgSender(), _questId, rewards);
    }

    function getRewards(uint256 _questId, address _user) public view returns (uint256 totalRewards, uint256 unClaimed) {
        Quest memory quest = quests[_questId];
        for (uint256 i = 0; i < quest.markets.length; i++) {
            (uint256 reward, bool isClaimed) = market.getRewards(quest.markets[i], _user);
            totalRewards += reward;
            if (!isClaimed) unClaimed += reward;
        }
    }

    function isQuestResolved(uint256 _questId) external view returns (bool) {
        Quest storage quest = quests[_questId];
        require(quest.active, "invalid quest");

        for (uint256 i = 0; i < quest.markets.length; i++) {
            if (
                !(market.getMarketData(quest.markets[i]).state == IBhavishRealTimePrediction.MarketState.RESOLVED ||
                    market.getMarketData(quest.markets[i]).state == IBhavishRealTimePrediction.MarketState.CLOSED)
            ) return false;
        }
        return true;
    }

    function setTrustedForwarder(address forwarderAddress) public onlyAdmin(msg.sender) {
        require(forwarderAddress != address(0), "Forwarder Address cannot be 0");
        trustedForwarder.push(forwarderAddress);
    }

    function removeTrustedForwarder(address forwarderAddress) public onlyAdmin(msg.sender) {
        bool found = false;
        uint256 i;
        for (i = 0; i < trustedForwarder.length; i++) {
            if (trustedForwarder[i] == forwarderAddress) {
                found = true;
                break;
            }
        }
        if (found) {
            trustedForwarder[i] = trustedForwarder[trustedForwarder.length - 1];
            trustedForwarder.pop();
        }
    }

    function versionRecipient() external view virtual override returns (string memory) {
        return "1";
    }

    function setOperator(address _operator) external {
        require(_operator != address(0), "Cannot be zero address");
        grantRole(OPERATOR_ROLE, _operator);

        emit NewOperator(_operator);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.13;

import "./IBhavishRealTimePrediction.sol";

interface IBhavishRealTimePredictionERC20 is IBhavishRealTimePrediction {
    function placeBet(
        uint256 marketId,
        uint256 outcomeId,
        uint256 amount,
        address user,
        address provider
    ) external;
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */

    address[] public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(isTrustedForwarder(msg.sender), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public view override returns (bool) {
        for (uint256 i = 0; i < trustedForwarder.length; i++) if (forwarder == trustedForwarder[i]) return true;
        return false;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal view virtual override returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.13;

interface IBhavishRealTimePrediction {
    enum MarketState {
        OPEN,
        CLOSED,
        RESOLVED
    }

    /**
     * @notice Market
     * @param opensAtTimestamp market open timestamp
     * @param closesAtTimestamp market close timestamp
     * @param balance total stake in market
     * @param reward reward amount
     * @param state market state
     * @param resolution market resolution details
     * @param outcomeIds outcome ids of market
     * @param question market question
     * @param outcomes outcome details
     * @param questOperated True if Operated Quest
     */
    struct Market {
        uint256 marketId;
        uint256 opensAtTimestamp;
        uint256 closesAtTimestamp;
        uint256 balance;
        uint256 reward;
        MarketState state;
        MarketResolution resolution;
        uint256[] outcomeIds;
        string question;
        string category;
        string description;
        string resolutionSource;
        mapping(uint256 => MarketOutcome) outcomes;
        bool questOperated;
    }

    struct MarketQuestion {
        string question;
        string category;
        string description;
        string resolutionSource;
        string[] outcomes;
    }

    struct MarketResolution {
        uint256 outcomeId;
        bytes32 questionId; // realitio questionId
    }

    struct MarketOutcome {
        uint256 marketId;
        uint256 id;
        string name;
        uint256 amount;
        mapping(address => uint256) traderStakes;
        mapping(address => bool) claimed;
    }

    struct MarketDetails {
        uint256 marketId;
        MarketState state;
        uint256 opensAtTimestamp;
        uint256 closesAtTimestamp;
        uint256 balance;
        uint256 rewards;
        string question;
        string category;
        string description;
        string resolutionSource;
        string[] outcomes;
        uint256 outcome;
        bool questOperated;
    }

    event MarketCreated(address indexed user, uint256 indexed marketId, string question);
    event MarketResolved(uint256 indexed marketId, uint256 outcome, string question);
    event MarketClosed(uint256 indexed marketId);
    event BetPlaced(address indexed user, uint256 indexed marketId, uint256 outcome, uint256 amount);
    event Claimed(address indexed user, uint256 indexed marketId, uint256 amount);
    event Refund(address indexed user, uint256 indexed marketID, uint256 amount);
    event ClaimFee(address indexed user, uint256 amount);
    event ProviderInfo(address indexed provider, address indexed user, uint256 amount);

    event NewTreasuryFee(uint256 treasuryFee);
    event NewOperator(address indexed operator);
    event NewResolver(address indexed resolver);
    event NewMinBond(uint256 amount);
    event NewTimeout(uint256 timeout);
    event NewArbitrator(address indexed arbitrator);
    event NewQuest(address indexed quest);

    function createMarket(
        MarketQuestion memory _question,
        uint256 _opensAt,
        uint256 _closesAt,
        bool _singleAnswer,
        bool _questOperated,
        bool _arbitrator
    ) external returns (uint256 marketId);

    function closeMarket(uint256 _marketId) external;

    function resolveMarket(uint256 _marketId) external;

    function claim(uint256 marketId, address _user) external returns (uint256 rewards);

    function refundUser(uint256 _marketId, address _user) external;

    function getRewards(uint256 _marketId, address _user) external view returns (uint256 rewards, bool claimed);

    function getMarketData(uint256 _marketId) external view returns (MarketDetails memory details);

    function isClaimed(uint256 _marketId, address _user) external view returns (bool);

    function isRefunded(uint256 _marketId, address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal view virtual returns (address);

    function versionRecipient() external view virtual returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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