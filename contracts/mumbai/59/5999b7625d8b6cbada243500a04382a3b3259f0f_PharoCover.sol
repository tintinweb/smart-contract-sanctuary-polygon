pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

// Open Zeppelin
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces
import "./interfaces/pharo/IPharoCover.sol";
import "./interfaces/pharo/IPharoMarket.sol";
import "./interfaces/pharo/IPharoPhinance.sol";
import "./interfaces/pharo/IPHROToken.sol";

// Pharo Libraries
import "./utility/PharoConstants.sol";
import "./utility/PharoEmits.sol";

/// @title Pharo Cover Contract
/// @author Jaxcoder, Aphilos
/// @notice Creates a new Cover Policy for a Cover Buyer
///         PharoPhactory will call the functions from this contract
///         in the future ...
contract PharoCover is IPharoCover, PharoEmits, Ownable, AccessControl
{
    using Counters for Counters.Counter;
    Counters.Counter public policyIdsCount;
    Counters.Counter public sPolicyIdsCount;
    IPharoMarket public pharoMarket;
    IPharoPhinance public pharoPhinance;

    IPHROToken public phroToken;
    address public phroTokenAddress;

    mapping(uint256 => PharoConstants.SignedPolicy[]) public rejPolicies;

    mapping(uint256 => uint256[]) public policy_ids;
    mapping(uint256 => address) private policyIdToBuyerWallet;
    mapping(uint256 => mapping(uint256 => PharoConstants.CoverPolicy))
        private pharoIdToPolicyIdToCoverPolicy;

    uint256 Collection_deadline;

    modifier onlyKeeper(address keeperAddress) {
        require(msg.sender == keeperAddress, "You are not the keeper");
        _;
    }

    // ReentrancyGuard()
    constructor(address _phroTokenAddress, address _pharoPhinanceAddress, address _newOwner) {
        phroToken = IPHROToken(_phroTokenAddress);
        phroTokenAddress = _phroTokenAddress;
        pharoPhinance = IPharoPhinance(_pharoPhinanceAddress);
        _setupRole(PharoConstants.OPERATOR_ROLE, msg.sender);
        _transferOwnership(_newOwner);
    }

    function getNrOfRejPoliciesByPharoId(
        uint256 pharoId
    ) public view returns (uint256) {
        return rejPolicies[pharoId].length;
    }


    // PharoConstants.SignedObelisk memory sObelisk,
    // PharoConstants.SignedWoC memory sWoC
    /// @notice This binds a cover policy to a cover buyer
    function createCoverPolicy(address token,
                               uint128 pharo_id,
                               PharoConstants.SignedPolicy memory sPolicy)
        public returns(bool)
    {
        bool policy_approved = _testPolicy(pharo_id, sPolicy);
        if (policy_approved)
        {
            bool pharo_exists = pharoMarket.confirmPharo(pharo_id);
            if (pharo_exists)
            {
                PharoConstants.CoverPolicy memory policy = _mapSignedData2Policy(pharo_id, sPolicy); //, sObelisk);
                bool cb_approved = pharoPhinance.getCBApproval(pharo_id, token, policy.premium * policy.length_of_cover, _msgSender());
                
                if (cb_approved)
                {
                    sPolicyIdsCount.increment();
                    uint256 pid = sPolicyIdsCount.current();
                    policy_ids[pharo_id].push(pid);
                    policyIdToBuyerWallet[pid] = msg.sender;
                    pharoIdToPolicyIdToCoverPolicy[pharo_id][pid] = policy;

                    _initializePolicy(pharo_id, pid, msg.sender);
                    return true;
                } else {
                    emit InsufficientFunds(
                        _msgSender(),
                        block.timestamp,
                        pharo_id,
                        "Funds were not approved by user."
                    );
                }
            } else {
                emit BadPharo(_msgSender(), pharo_id);
            }
        }

        return false;
    }

    function updatePolicyPremiumPaid(uint256 pharo_id, uint256 policy_id, uint256 new_premium) external returns(bool success)
    {
        pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].premium_paid += new_premium;
        pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].premium = new_premium;
    }

    function verifyPolicyFunds(uint256 pharo_id) external returns(bool rebalance_market)
    {
        bool enough_funds;
        rebalance_market = false;

        for (uint256 pid=0; pid < policy_ids[pharo_id].length; pid++) {
            if (pharoIdToPolicyIdToCoverPolicy[pharo_id][pid].status == PharoConstants.CoverPolicyStatus.ACTIVE) {
                enough_funds = pharoPhinance.verifyFinancials(phroTokenAddress, 
                                                              pharoIdToPolicyIdToCoverPolicy[pharo_id][pid].premium, 
                                                              policyIdToBuyerWallet[pid]);
                if (!enough_funds)
                {
                    emit InsufficientFunds(policyIdToBuyerWallet[pid], block.timestamp, pharo_id, "Policy Cannot Be Paid");
                    closePolicy(pharo_id, pid, policyIdToBuyerWallet[pid]);
                    rebalance_market = true;
                    break; //IARO: instead of breaking from the loop on the first policy with failed premium payment,
                    //we should also parse the rest of them, in order to close them all together -
                    //and not enter the loop of closing a policy - rebalancing the market - closing another policy -
                    //rebalancing the market again - and so on...
                }
                //IARO: the else branch shouldn't exist
                else {
                    rebalance_market = false;
                }
            }
        }

        return rebalance_market;
    }

    function payPremiums(uint256 pharo_id) external returns(bool success)
    {
        for (uint256 px=0; px < policy_ids[pharo_id].length; px++)
        {
            if (pharoIdToPolicyIdToCoverPolicy[pharo_id][px].status == PharoConstants.CoverPolicyStatus.ACTIVE)
            {
                pharoIdToPolicyIdToCoverPolicy[pharo_id][px].premium_paid += pharoIdToPolicyIdToCoverPolicy[pharo_id][px].premium;
                success = pharoPhinance.executeCBFinancials(pharo_id, phroTokenAddress, 
                                                            pharoIdToPolicyIdToCoverPolicy[pharo_id][px].premium, 
                                                            policyIdToBuyerWallet[px]);
                if (!success) 
                {
                    emit ExecuteCBFinancialsError(policyIdToBuyerWallet[px], block.timestamp, pharo_id, "Execution Failed");
                    return success;
                }
            }
        }

        return success;
    }

    function updatePolicyInstancesCoverReward(uint256 pharo_id, uint256 policy_id, uint256 cover_bought, uint256 reward)
        internal returns(bool success)
    {
        pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].cover_bought = cover_bought;
        pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].reward = reward;
    }

    function updatePolicyEvent(uint256 pharo_id, uint256 policy_id, 
                               uint256 reward, uint256 cover_bought, 
                               uint256 true_event_time) 
        external returns(bool success)
    {
        success = updatePolicyInstancesCoverReward(pharo_id, policy_id, cover_bought, reward);
        pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].true_event_time = true_event_time;
        return true;
    }
    
    function collectCover(uint256 pharo_id) external returns(bool success)
    {
        success = true;
        bool paid;
        for (uint256 pid = 0; pid < policy_ids[pharo_id].length; pid++) {
            PharoConstants.CoverPolicy
                memory coverPolicy = pharoIdToPolicyIdToCoverPolicy[pharo_id][
                    pid
                ];
            if (
                coverPolicy.status == PharoConstants.CoverPolicyStatus.ACTIVE &&
                coverPolicy.timestamp < coverPolicy.true_event_time
            ) {
                address policyBuyer = policyIdToBuyerWallet[pid];
                paid = pharoPhinance.payoutCoverPolicy(pharo_id,
                                                       payable(policyBuyer),
                                                       /*phroTokenAddress,*/
                                                       coverPolicy.cover_bought);
                if (!paid)
                {
                    emit ExecuteCoverPaymentError(pharo_id, coverPolicy.cover_bought, policyBuyer, "Execution Failed");
                    success = false;
                }
            }
        }
    }

    // PharoConstants.SignedObelisk memory sObelisk
    function _mapSignedData2Policy(
        uint256 pharo_id,
        PharoConstants.SignedPolicy memory sPolicy
    ) internal view returns (PharoConstants.CoverPolicy memory policy) {
        policy.timestamp = block.timestamp;
        policy.id = policyIdsCount.current();
        policy.owner = msg.sender;
        policy.status = PharoConstants.CoverPolicyStatus.ACTIVE;
        policy.pharo_id = pharo_id; // id of the Pharo they are buying cover under

        policy.cover_bought = 0; // Must be updated by PharoMarket?
        policy.premium_paid = 0; // Must be updated by PharoMarket?
        // policy.stake = sPolicy.stake;
        policy.rate_estimate = sPolicy.rate_estimate;
        policy.min_cover = sPolicy.min_cover;

        policy.length_of_cover = sPolicy.length_of_cover;
        policy.reward = 0;

        // pharoIdToPolicyIdToCoverPolicy[pharo_id].push(policy);

        return policy;
    }

    function _testPolicy(
        uint256 pharo_id,
        PharoConstants.SignedPolicy memory sPolicy
    ) internal returns (bool policy_approved) {
        policy_approved = true;

        if (sPolicy.min_cover <= 0) revert MustBeGreaterThanZero();
        if (sPolicy.length_of_cover <= 0) revert MustBeGreaterThanZero();
        if (sPolicy.rate_estimate <= 0) revert MustBeGreaterThanZero();

        if (sPolicy.min_cover > (sPolicy.rate_estimate * sPolicy.stake)) {
            policy_approved = false;
        }

        if (policy_approved == false) {
            // policy.status = PharoConstants.CoverPolicyStatus.REJECTED;
            _rejectPolicy(pharo_id, sPolicy);
            revert(
                "Gotta meet basic requirements to participate in the market!"
            );
        } else {
            emit CoverPolicyAccepted(msg.sender, block.timestamp);
        }

        return policy_approved;
    }

    // todo: 
    function updatePolicy(uint256 pharo_id, uint256 policy_id, uint256 cover_bought, uint256 reward) external pure returns(bool updated)
    {
        return true;
    }

    /// @notice Not sure if we even need this yet, doing the same as the acceptPolicy()
    function _initializePolicy(uint256 pharo_id, uint256 policy_id, address coverBuyerAddress) internal
    {
        //require(hasRole(PharoConstants.OPERATOR_ROLE, msg.sender), "Need to be an operator");
        PharoConstants.CoverPolicy storage policy = pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id];
        
        // if (policy.status != PharoConstants.CoverPolicyStatus.ACTIVE) revert AlreadyActive();
        if (policy.status == PharoConstants.CoverPolicyStatus.REJECTED)
            revert RejectedStatus();

        policy.status = PharoConstants.CoverPolicyStatus.ACTIVE;

        emit CoverPolicyInitialized(
            pharo_id,
            policy_id,
            coverBuyerAddress,
            block.timestamp
        );
    }

    /// @dev rejects a policy and records it
    function _rejectPolicy(
        uint256 pharo_id,
        PharoConstants.SignedPolicy memory sPolicy
    ) internal {
        if (msg.sender == address(0)) revert ZeroAddressNotAllowed();

        rejPolicies[pharo_id].push(sPolicy);

        // if (policy.status == PharoConstants.CoverPolicyStatus.REJECTED) revert RejectedStatus();

        emit CoverPolicyRejected(msg.sender, block.timestamp);
    }

    /// @dev used to close a policy:
    /// 1: after the event has been triggered, or
    /// 2: time ran out for that Pharo, or
    /// 3: the user cancels their policy.
    function closePolicy(
        uint256 pharo_id,
        uint256 policy_id,
        address coverBuyerAddress
    ) public {
        if (!hasRole(PharoConstants.OPERATOR_ROLE, msg.sender))
            revert WrongRole();

        PharoConstants.CoverPolicy
            storage policy = pharoIdToPolicyIdToCoverPolicy[pharo_id][
                policy_id
            ];
        require(
            policy.owner == coverBuyerAddress,
            "The policy owner must equal the given coverBuyerAddress"
        );

        policy.status = PharoConstants.CoverPolicyStatus.CLOSED;
        emit CoverPolicyClosed(policy_id, coverBuyerAddress, block.timestamp);
    }

    function getActiveMarketPolicies(uint256 pharo_id) external view 
        returns(PharoConstants.CoverPolicy[] memory active_policies) 
    {
        uint256 activePoliciesCount = getActiveMarketPoliciesCount(pharo_id);
        active_policies = new PharoConstants.CoverPolicy[](activePoliciesCount);
        uint256[] memory policyIdsForPharo = policy_ids[pharo_id];
        for (uint256 i = 0; i < policyIdsForPharo.length; i++)
        {
            uint256 policy_id = policyIdsForPharo[i];
            PharoConstants.CoverPolicy memory policy = pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id];
            if (policy.status == PharoConstants.CoverPolicyStatus.ACTIVE)
                active_policies[i] = policy;
        }

        return active_policies;
    }

    function getActiveMarketPoliciesCount(uint256 pharo_id) private view returns(uint256 count) 
    {
        uint256[] memory policyIdsForPharo = policy_ids[pharo_id];
        for (uint256 i = 0; i < policyIdsForPharo.length; i++)
        {
            uint256 policy_id = policyIdsForPharo[i];
            PharoConstants.CoverPolicy memory policy = pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id];
            if (policy.status == PharoConstants.CoverPolicyStatus.ACTIVE)
                count++;
        }

        return count;
    }

    /// @dev get cover policies for a specified user
    /// @param user the address of the user
    function getBuyerPolicies(address user) public
        returns(PharoConstants.CoverPolicy[] memory policies)
    {
        uint256[] memory pharoIds = pharoMarket.getPharoIds();
        uint256 count = getBuyerPoliciesCount(user, pharoIds);
        policies = new PharoConstants.CoverPolicy[](count);
        uint256 k = 0;

        for (uint256 i = 0; i < pharoIds.length; i++)
        {
            uint256 pharo_id = pharoIds[i];
            uint256[] memory policyIdsForPharo = policy_ids[pharo_id];
            for (uint256 j = 0; j < policyIdsForPharo.length; j++) {
                uint256 policy_id = policyIdsForPharo[j];
                if (
                    pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].owner ==
                    user
                )
                    policies[k++] = pharoIdToPolicyIdToCoverPolicy[pharo_id][
                        policy_id
                    ];
            }
        }

        return policies;
    }

    function getBuyerPoliciesCount(address user, uint256[] memory pharoIds) public view returns(uint256 count)
    {
        for (uint256 i = 0; i < pharoIds.length; i++)
        {
            uint256 pharo_id = pharoIds[i];
            uint256[] memory policyIdsForPharo = policy_ids[pharo_id];
            for (uint256 j = 0; j < policyIdsForPharo.length; j++) {
                uint256 policy_id = policyIdsForPharo[j];
                if (
                    pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id].owner ==
                    user
                ) count++;
            }
        }

        return count;
    }

    // todo: FIXME - this is just a placeholder for now
    function discoverPharoMarket(address marketAddress) external view returns (bool discovered)
    {
        discovered = true;
    }

    /// @dev verify a policy
    function verifyPolicy(uint256 pharo_id,
                          uint256 policy_id, 
                          uint256 premium,
                          uint256 rate_estimate,
                          uint256 min_cover) 
        public view returns(bool verified)
    {
        PharoConstants.CoverPolicy memory policy = pharoIdToPolicyIdToCoverPolicy[pharo_id][policy_id];
        verified = policy.premium == premium 
                   && policy.rate_estimate == rate_estimate
                   && policy.min_cover == min_cover;
        return verified;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.13;

//SPDX-License-Identifier: MIT

/// @dev PharoCover Interface
interface IPharoCover
{
    function verifyPolicy(uint256 pharo_id, uint256 policy_id, uint256 stake, uint256 rate_estimate, uint256 min_cover) external view returns(bool verified);
    function updatePolicy(uint256 pharo_id, uint256 policy_id, uint256 cover_bought, uint256 reward) external pure returns(bool success);
    function collectCover(uint256 pharo_id) external returns(bool success);
    function updatePolicyEvent(uint256 pharo_id, uint256 policy_id, uint256 reward, uint256 cover_bought, uint256 true_event_time) external returns(bool success);
    function payPremiums(uint256 pharo_id) external returns (bool success);
    function updatePolicyPremiumPaid(uint256 pharo_id, uint256 policy_id, uint256 new_premium) external returns(bool success);
    function verifyPolicyFunds(uint256 pharo_id) external returns(bool rebalance_market);
}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "../../utility/PharoConstants.sol";

/// @dev PharoMarket Interface
interface IPharoMarket
{
    function createPharo(uint256 lifetime,
                         string memory name,
                         string memory description/*,
                         string memory tokenAddress*/) external returns(bool success, uint256 pharoId);

    function confirmPharo(uint256 pharoId) external returns(bool confirmed);

    function getPharoIds() external returns(uint256[] memory);
    
    function updateMarkets(uint256 pharoId,
                           PharoConstants.SignedObelisk memory cbObelisk,
                           PharoConstants.SignedWoC memory sWoC) external returns(bool success);

    function pharoEventTriggered(uint256 pharo_id,
                                 uint32 trueEventTime) external returns(bool success);
}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

// Pharo Libraries
import "../../utility/PharoConstants.sol";

/// @dev PharoPhinance Interface
interface IPharoPhinance
{
    // function deposit(uint256 poolId, uint256 pharoId, address asset, uint256 amount) external;
    // function withdraw(uint256 poolId, uint256 pharoId, uint256 amount, string memory memo) external;
    // function allocate(uint256 poolId, uint256 pharoId, uint256 amount, string memory memo) external;
    // function getContractTokenBalance(address asset) external view returns(uint256);
    // function getLiquidityBalanceForPharo(uint256 pharoId) external returns(uint256);

    function getCBApproval(uint256 pharoId, address token, uint256 approvalAmount, address coverBuyer) external returns(bool);
    function verifyFinancials(/*uint256 pharo_id,*/ address token, uint256 amount_req, address wallet_id) external returns(bool);
    function executeCBFinancials(uint256 pharoId, address token, uint256 stakeAmount, address coverBuyer) external returns(bool);
    function executeLPFinancials(address providerAddress, uint256 stakeAmount, address asset, /*uint256 poolId,*/ uint256 pharoId) external;
    function payoutCoverPolicy(uint256 pharo_id, address payable wallet_id, /*address tokenAddress,*/ uint256 amount) external returns(bool paid);
    function removeLiquidityFromPharo(/*uint256 poolId,*/ uint256 pharoId, address payable wallet_id, /*address tokenAddress,*/ uint256 amount, address providerAddress) external;
}

pragma solidity ^0.8.13;

//SPDX-License-Identifier: MIT

interface IPHROToken {
    function mintTokens(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;

    function mint(uint256 amount) external;

    function mintForContract(address contractAddress, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns(uint256);
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns(uint256);
    function lock(bytes32 _reason, uint256 _amount, uint256 _time) external returns(bool);
    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time) external returns(bool);
    function tokensLocked(address _of, bytes32 _reason) external view returns(uint256);
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns(uint256);
    function totalBalanceOf(address _of, bytes32 _reason) external view returns(uint256);
    function extendLock(bytes32 _reason, uint256 _time) external returns(bool);
    function increaseLockAmount(bytes32 _reason, uint256 _amount) external  returns(bool);
    function tokensUnlockable(address _of, bytes32 _reason) external view returns(uint256);
    function unlock(address _of) external returns(uint256 unlockableTokens);
    function getUnlockableTokens(address _of) external returns(uint256 unlockableTokens);
}

pragma solidity ^0.8.13;

//SPDX-License-Identifier: MIT

/// @title Pharo Constants Contract
/// @author Jaxcoder, Aphilos
/// @notice holds contants and mappings
/// @dev moonmoon
// abstract contract PharoConstants {
library PharoConstants
{
    // address payable feeReceiverAddress;
    // uint256 fee1 = 1200; // 1200 Basis Points or 12%

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    struct SignedPolicy
    {
        uint128 min_cover;
        uint128 stake;
        uint128 rate_estimate;
        uint128 length_of_cover; // sent in seconds
    }

    struct SignedPosition
    {
        uint128 max_risk;
        uint128 stakeAmount;
        uint128 rateEstimate;
    }

    struct SignedWoC
    {
        uint32 pharo_id;
        uint32 alpha;
        uint32 beta;
        uint32 rateProbable;
        uint32 min_confidence;
        uint32 max_confidence;
        uint32 gof;
        uint32[] gamma_x;
        uint32[] gamma_y;
    }

    struct SignedObelisk {
        uint256 timestamp;
        uint32 pharo_id;
        address[] cb_wallet_id;
        uint256[] cb_policy_id;
        uint256[] cb_premium;
        uint256[] cb_reward;
        uint32[] cb_rate_estimate;
        uint256[] cb_min_cover;
        uint256[] cb_funds_avail;
        uint256[] cb_cover_bought;
        uint256[] cb_cover_mult;
        uint16[] cb_percentile;
        address[][] cb_srvd_wallet_id;
        uint256[][] cb_srvd_product_id;
        uint256[][] cb_srvd_value;
        uint256[][] cb_incompatible_LPs;
        address[] lp_wallet_id;
        uint256[] lp_product_id;
        uint256[] lp_stake;
        uint256[] lp_reward;
        uint32[] lp_rate_estimate;
        uint32[] lp_max_risk;
        uint256[] lp_cover_avail;
        uint32[] lp_breakeven_rate;
        address[][] lp_srvd_wallet_id;
        uint256[][] lp_srvd_policy_id;
        uint256[][] lp_srvd_value;
        uint256[][] lp_incompatible_CBs;
    }

    struct CoverPolicy {
        uint256 timestamp;
        uint256 id;
        address owner;
        CoverPolicyStatus status;
        uint256 pharo_id;
        uint256 cover_bought;
        uint256 length_of_cover;
        uint256 reward;
        uint256 premium_paid;
        uint256 premium;
        uint256 rate_estimate;
        uint256 min_cover;
        uint256 true_event_time;
    }

    struct LiquidityProduct {
        address providerAddress;
        uint256 maximumRisk;
        uint256 breakevenRate;
        uint256 staked;
        address asset;
        uint256 premium_collected;
        uint256 coverPaid;
        uint256 coverAvailable;
        uint256 reward;
        uint256 rateEstimate;
    }

    enum EventStatus
    {
        Active, // fully capitalized Pharo
        Pending, // Imhotep, awaiting full capitalization
        Closed, // Obelisk NFT has been minted
        Cancelled, // All assets returned
        Triggered, // Oracle has triggered the event
        Executed // Anubis has paid out all parties
    }

    /// @dev CoverPolicy statuses
    enum CoverPolicyStatus {
        INITIALIZING,
        ACTIVE,
        INACTIVE,
        PENDING,
        CLOSED,
        OPEN,
        REJECTED
    }

    // make sure any condition is met before access to function
    modifier condition(bool _condition)
    {
		require(_condition);
		_;
	}
}

pragma solidity ^0.8.13;
import "./PharoConstants.sol";

abstract contract PharoEmits {
    // TEST EVENT
    event TestEmit(uint256 pharo_id);

    // Events //
    /// @dev events for buying and paying out cover policies
    event ObeliskCopied();
    event CoverBuyerCreated(
        uint256 pharo_id,
        address coverBuyer,
        uint256 cover
    );
    event CoverPolicyCreated(); //address coverBuyer); //, uint256 cover, uint256 policyId, uint256 rateEsitmate, uint256 stakeAmount, uint256 lengthOfCover);
    event CoverPolicyClosed(
        uint256 policyId,
        address coverBuyer,
        uint256 timestamp
    );
    event CoverPolicyRejected(address coverBuyer, uint256 timestamp);
    event CoverPolicyAccepted(address coverBuyer, uint256 timestamp);
    event CoverPolicyInitialized(
        uint256 pharo_id,
        uint256 policy_id,
        address coverBuyer,
        uint256 timestamp
    );
    event InsufficientFunds(
        address actor,
        uint256 timestamp,
        uint256 pharo_id,
        string reason
    );
    event PoliciesPaid(uint256 pharo_id, uint256 timestamp);
    event BadPharo(address actor, uint256 pharo_id);

    event APIOutOfSync();
    event PolicyUpdateError();
    event ProductUpdateError();
    event MarketUpdateError();
    event UpdatePolicyPremiumPaidError(
        uint256 pharo_id,
        uint256 policy_id,
        uint256 premium2pay,
        string reason
    );
    event UpdateProductPremiumReceivedError(
        uint256 pharo_id,
        uint256 policy_id,
        uint256 premium2pay,
        string reason
    );
    event RewardCalculationError(uint256 pharo_id, uint256 trueEventTime);
    event ExecuteCoverPaymentError(
        uint256 pharo_id,
        uint256 cover_amount,
        address wallet_id,
        string reason
    );
    event ExecuteCBFinancialsError(
        address wallet_id,
        uint256 timestamp,
        uint256 pharo_id,
        string reason
    );

    event PolicyUpdateError(
        uint256 pharo_id,
        uint256 policy_id,
        uint256 reward,
        uint256 cover_bought,
        uint256 trueEventTime
    );

    event RiskPoolApproved(uint256 amount, uint256 pharo_id);
    event RiskPoolDeposit(uint256 amount, address indexed from);
    event ReservePoolDeposit(uint256 amount, address indexed from);
    event ReservePoolWithdraw(
        uint256 amount,
        address indexed from,
        string memo
    );
    event TreasuryDeposit(uint256 amount, string reason);
    event MarketMakerPaid(uint256 amount, address indexed marketMaker);
    event PayoutsComplete();

    event Time2Collect(uint256 collection_time);

    event LiquidityAdded(
        uint256 pharo_id,
        address indexed provider,
        uint256 amount
    );
    event LiquidityRemoved(
        uint256 pharo_id,
        address indexed provider,
        uint256 amount
    );

    event PharoCreated(address pharoAddress, uint256 pharo_id);
    event PharoBurned(address pharoAddress, uint256 pharo_id);
    event BuyerCreated(address buyer, uint256 balance);
    event MummyCreated(string eventHash, string name, uint256 birtday);
    event ProviderCreated(address provider, uint amount, uint odds);
    event EventCreated(
        string eventType,
        PharoConstants.EventStatus eventStatus,
        uint256 pharo_id,
        string eventHash
    );

    // event UserReward(uint256 reward); defined in PharoRewards contract.
    event CoverCalculation(uint256 coverAwarded);

    /// @notice error messages
    error ZeroAddressNotAllowed();
    error MustBeGreaterThanZero();
    error RejectedStatus();
    error WrongRole();
    error AlreadyActive();
    error AlreadyPaid();
    error BadId();
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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