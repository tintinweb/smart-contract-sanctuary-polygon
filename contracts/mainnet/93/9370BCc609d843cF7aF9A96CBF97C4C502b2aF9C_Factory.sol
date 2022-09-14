// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Error } from "./interfaces/Error.sol";
import { Guild } from "./Guild.sol";
import { GuildType } from "./interfaces/IGuild.sol";

contract Factory {
  address public owner;

  event GuildCreated(address indexed from, address indexed addr);

  constructor() {
    owner = msg.sender;
  }

  function createGuild(
    address guildOwner,
    GuildType guildType,
    uint32 maxMembers
  ) external onlyOwner returns (address addr) {
    addr = address(new Guild(guildOwner, guildType, maxMembers));

    emit GuildCreated(msg.sender, addr);
  }

  function transferOwnership(address owner_) external onlyOwner {
    if ((owner = owner_) == address(0)) revert Error.ZeroAddress();
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Error.OnlyOwner();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { Role } from "./IGuild.sol";

// Error namespace
library Error {
  error ZeroAddress();

  error NotMinted();

  error InvalidAccess(Role requiredRole);

  error Unauthorized(Role requiredRole);

  error OnlyOneOwner();

  error OwnerCannotLeave();

  error CannotRemoveYourself();

  error GuildNotPublic();

  error NotMember(address account);

  error ExceedsMemberLimit();

  error AlreadyJoined(address account);

  error CannotSetToOwnerOrNonMember();

  error Blacklisted(address account);

  error MaxMembersCannotBeSmallerThanMemberCount();

  error MemberCannotBeBlacklisted(address account);

  error OnlyMetadataOperator();

  error TransactionExecutionFailed(bytes result);

  error OnlyOwner();
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Soul } from "./Soul.sol";
import { Vault } from "./utils/Vault.sol";
import { Error } from "./interfaces/Error.sol";
import { IGuild, Role, GuildType } from "./interfaces/IGuild.sol";
import { SafeCastLib } from "solmate/src/utils/SafeCastLib.sol";

// @notice Guild management contract
// @author MetaDhana Studio
contract Guild is IGuild, Vault {
  using SafeCastLib for uint256;
  using Soul for address;

  // Guild type: PUBLIC, PROTECTED, or PRIVATE
  GuildType public guildType;

  // Member limit
  uint32 public maxMembers;

  // Current member count
  uint32 public currentMembers;

  /**
   * @param owner_      Initial owner of this guild
   * @param guildType_  PUBLIC, PROTECTED, or PRIVATE
   * @param maxMembers_ Member limit
   */
  constructor(
    address owner_,
    GuildType guildType_,
    uint32 maxMembers_
  ) {
    if (maxMembers_ < 1) revert Error.MaxMembersCannotBeSmallerThanMemberCount();

    // Set the guild info
    guildType = guildType_;
    maxMembers = maxMembers_;
    currentMembers = 1;

    // Set role to OWNER
    _setRole(owner_, Role.OWNER);
  }

  /**
   * @notice Querys batch of `souls` for given `accounts`.
   *
   * @param accounts Addresses to query
   *
   * @return souls
   */
  function batchQuerySouls(address[] calldata accounts) external view returns (SoulQuery[] memory) {
    SoulQuery[] memory souls = new SoulQuery[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      souls[i] = SoulQuery({
        blacklisted: accounts[i].isBlacklisted(),
        role: accounts[i].getRole(),
        data: accounts[i].getData()
      });
    }
    return souls;
  }

  /**
   * @notice Joins this guild. Note that only NON_MEMBER can call
   *         this function and can only join PUBLIC guilds.
   */
  function joinGuild() external matchRole(Role.NON_MEMBER) {
    // Check if this guild is PUBLIC
    if (guildType != GuildType.PUBLIC) revert Error.GuildNotPublic();

    // Check if joining will exceed member limit, otherwise increment member count
    if (maxMembers - currentMembers++ < 1) revert Error.ExceedsMemberLimit();

    // Check if caller is blacklisted
    if (msg.sender.isBlacklisted()) revert Error.Blacklisted(msg.sender);

    // Set caller role to MEMBER
    _setRole(msg.sender, Role.MEMBER);
  }

  /**
   * @notice Leaves this guild. Note that only MEMBER or MANAGER can call
   *         this function.
   */
  function leaveGuild() external hasRole(Role.MEMBER) {
    // Owner cannot leave
    if (msg.sender.matchRole(Role.OWNER)) revert Error.OwnerCannotLeave();

    // Decrement member count
    --currentMembers;

    // Set sender role to NON_MEMBER
    _setRole(msg.sender, Role.NON_MEMBER);
  }

  /**
   * @notice Adds (or invite) batch of accounts to this guild. Note that only
   *         member with MANAGER role or higher can call this function and blacklisted
   *         accounts cannot be added.
   *
   * @param members Array of members to add
   */
  function addMembers(address[] calldata members) external hasRole(Role.MANAGER) {
    // Check if adding all members wil exceed member limit, otherwise increment member count
    if ((currentMembers += members.length.safeCastTo32()) > maxMembers) {
      revert Error.ExceedsMemberLimit();
    }

    // For all members...
    for (uint256 i = 0; i < members.length; ++i) {
      // Check if member to add is already a member
      if (members[i].hasRole(Role.MEMBER)) revert Error.AlreadyJoined(members[i]);

      // Check if member to add is blacklisted
      if (members[i].isBlacklisted()) revert Error.Blacklisted(members[i]);

      // Set role to MEMBER
      _setRole(members[i], Role.MEMBER);
    }
  }

  /**
   * @notice Removes (or kicks) batch of members from this guild. Note that only
   *         member with MANAGER role or higher can call this function.
   *
   * @param members Array of members to remove
   */
  function removeMembers(address[] calldata members) external hasRole(Role.MANAGER) {
    // Decrement member count by the number of members to remove
    currentMembers -= members.length.safeCastTo32();

    // For all members...
    for (uint256 i = 0; i < members.length; ++i) {
      // Check if member is OWNER. Owner cannot leave
      if (members[i].matchRole(Role.OWNER)) revert Error.OwnerCannotLeave();

      // Check if member is NON_MEMBER. Cannot remove if not member.
      if (members[i].matchRole(Role.NON_MEMBER)) revert Error.NotMember(members[i]);

      // Check if member is msg.sender.
      if (members[i] == msg.sender) revert Error.CannotRemoveYourself();

      // Set member role to NON_MEMBER
      _setRole(members[i], Role.NON_MEMBER);
    }
  }

  /**
   * @notice Adds/removes array of accounts to/from blacklist. Note that only
   *         member with MANAGER role or higher can call this function.
   *
   * @param accounts  List of accounts to set
   * @param blacklist Set `true` to add, `false` to remove
   */
  function setBlacklist(address[] calldata accounts, bool blacklist)
    external
    hasRole(Role.MANAGER)
  {
    // For all accounts...
    for (uint256 i = 0; i < accounts.length; ++i) {
      // Members of this guild cannot be blacklisted
      if (accounts[i].hasRole(Role.MEMBER) && blacklist) {
        revert Error.MemberCannotBeBlacklisted(accounts[i]);
      }

      // Set blacklist
      accounts[i].setBlacklist(blacklist);

      emit UpdateBlacklist(accounts[i], blacklist);
    }
  }

  /**
   * @notice Sets array of members to certain role. Note that only OWNER can call this function.
   *         Use this function to only promote or demote.
   *
   * @param members List of members to set
   * @param role    Role to set to
   */
  function setMemberRoles(address[] calldata members, Role role) external matchRole(Role.OWNER) {
    // Cannot set to OWNER or NON_MEMBER
    if (role == Role.OWNER || role == Role.NON_MEMBER) {
      revert Error.CannotSetToOwnerOrNonMember();
    }

    for (uint256 i = 0; i < members.length; ++i) {
      // Cannot promote or demote a NON_MEMBER
      if (members[i].matchRole(Role.NON_MEMBER)) revert Error.NotMember(members[i]);

      // Only one owner can exist
      if (members[i] == msg.sender) revert Error.OnlyOneOwner();

      // Set member role to `role`
      _setRole(members[i], role);
    }
  }

  /**
   * @notice Transfers ownership of this guild to a member.
   *
   * @param to      Address of new owner
   * @param newRole New role for the current owner
   */
  function transferOwnership(address to, Role newRole) external matchRole(Role.OWNER) {
    // Cannot set new role to OWNER or NON_MEMBER
    if (newRole == Role.OWNER || newRole == Role.NON_MEMBER) {
      revert Error.CannotSetToOwnerOrNonMember();
    }

    // Cannot transfer ownership if `to` is not a member
    if (to.matchRole(Role.NON_MEMBER)) revert Error.NotMember(to);

    // Set caller role to newRole
    _setRole(msg.sender, newRole);

    // Set `to` to OWNWR
    _setRole(to, Role.OWNER);
  }

  /**
   * @notice Changes guild type. Note that only owner can call.
   *
   * @param guildType_ Guild type to set to (PUBLIC, PRIAVTE, or PROTECTED)
   */
  function changeGuildType(GuildType guildType_) external matchRole(Role.OWNER) {
    guildType = guildType_;

    emit UpdateGuildType(guildType_);
  }

  /**
   * @notice Changes member limit. Note that only owner can call.
   *
   * @param maxMembers_ New max member count. Cannot be smaller than current member count.
   */
  function changeMaxMembers(uint32 maxMembers_) external matchRole(Role.OWNER) {
    if ((maxMembers = maxMembers_) < currentMembers) {
      revert Error.MaxMembersCannotBeSmallerThanMemberCount();
    }

    emit UpdateMaxMembers(maxMembers_);
  }

  /**
   * @notice Executes arbitary transaction. Only member with MANAGER role or higher
   *         can call this function.
   *
   * @param to Address to call
   * @param value Ether value to attach
   * @param data Data to send
   */
  function executeTransaction(
    address to,
    uint256 value,
    bytes memory data
  ) external hasRole(Role.MANAGER) returns (bytes memory) {
    // Make external call
    (bool success, bytes memory result) = to.call{ value: value }(data);

    // Throw on error
    if (!success) revert Error.TransactionExecutionFailed(result);

    emit ExecuteTransaction(msg.sender, to, value, data);

    return result;
  }

  /**
   * @dev Sets role
   *
   * @param to      Address to set to
   * @param newRole New role to set
   */
  function _setRole(address to, Role newRole) private {
    emit UpdateRole(to, to.getRole(), newRole);

    to.setRole(newRole);
  }

  /**
   * @dev Checks if sender has the same or higher role than the given `role`
   *
   * @param role Role to compare
   */
  modifier hasRole(Role role) {
    if (msg.sender.hasRole(role) == false) revert Error.Unauthorized(role);
    _;
  }

  /**
   * @dev Check if sender has the exact role of a given `role`
   *
   * @param role Role to compare
   */
  modifier matchRole(Role role) {
    if (msg.sender.matchRole(role) == false) revert Error.Unauthorized(role);
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

enum Role {
  NON_MEMBER,
  MEMBER,
  MANAGER,
  OWNER
}

enum GuildType {
  PUBLIC,
  PROTECTED,
  PRIVATE
}

interface IGuild {
  struct SoulQuery {
    bool blacklisted;
    Role role;
    uint256 data;
  }

  event UpdateRole(address indexed account, Role indexed previousRole, Role indexed role);

  event UpdateGuildType(GuildType guildType);

  event UpdateMaxMembers(uint256 maxMember);

  event ExecuteTransaction(address indexed from, address indexed to, uint256 value, bytes data);

  event UpdateBlacklist(address indexed account, bool indexed blacklist);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Role, IGuild } from "./interfaces/IGuild.sol";

// @notice Soul storage library, partially inspired by Diamond storage library
// @author MetaDhana Studio
library Soul {
  struct SoulStorage {
    /**
     * Mapping from address to soul metadata
     *
     * Bits layout:
     * - [0]      Soulbound token minted boolean
     * - [1..2]   Role enum (0: non-member, 1: member, 2: manager, 3: owner)
     * - [3]      Blacklist boolean
     * - [4..7]   Padding
     * - [8..255] 31 bytes Soul data
     */
    mapping(address => uint256) soul;
  }

  function _soulStorage() internal pure returns (SoulStorage storage ss) {
    bytes32 position = keccak256("soul.storage");
    assembly {
      ss.slot := position
    }
  }

  function setRole(address account, Role role) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & ~uint256(0x6); // Mask index 1-2 with zeros
    uint256 newSoul = masked | (uint256(role) << 1);
    ss.soul[account] = newSoul;
  }

  function matchRole(address account, Role role) internal view returns (bool) {
    SoulStorage storage ss = _soulStorage();
    return (ss.soul[account] >> 1) & 0x3 == uint256(role);
  }

  function hasRole(address account, Role role) internal view returns (bool) {
    SoulStorage storage ss = _soulStorage();
    return (ss.soul[account] >> 1) & 0x3 >= uint256(role);
  }

  function getRole(address account) internal view returns (Role) {
    SoulStorage storage ss = _soulStorage();
    uint256 role = (ss.soul[account] >> 1) & 0x3;
    return Role(role);
  }

  function setBlacklist(address account, bool blacklist) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & ~uint256(0x8);
    uint256 newSoul = masked | ((blacklist ? 0x1 : 0x0) << 3);
    ss.soul[account] = newSoul;
  }

  function isBlacklisted(address account) internal view returns (bool result) {
    SoulStorage storage ss = _soulStorage();
    uint256 value = ss.soul[account] & 0x8;

    assembly {
      result := value // Auto cast to boolean
    }
  }

  function setAsMinted(address account) internal {
    SoulStorage storage ss = _soulStorage();
    ss.soul[account] |= 0x1;
  }

  function isMinted(address account) internal view returns (bool result) {
    SoulStorage storage ss = _soulStorage();
    uint256 value = ss.soul[account] & 0x1;

    assembly {
      result := value // Auto cast to boolean
    }
  }

  function setData(address account, uint248 data) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & 0xFF;
    uint256 newSoul = masked | (uint256(data) << 8);
    ss.soul[account] = newSoul;
  }

  function getData(address account) internal view returns (uint256) {
    SoulStorage storage ss = _soulStorage();
    return ss.soul[account] >> 8;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// @notice Utility contract for receiving ethers, ERC721 and ERC1155 tokens
// @author regohiro
abstract contract Vault {
  event ReceivedEther(address indexed from, uint256 value);

  event ReceivedERC721(address indexed token, address indexed from, uint256 indexed id);

  event ReceivedERC1155(
    address indexed token,
    address indexed from,
    uint256 indexed id,
    uint256 amount
  );

  event ReceivedERC1155Batch(
    address indexed token,
    address indexed from,
    uint256[] indexed ids,
    uint256[] amounts
  );

  receive() external payable {
    emit ReceivedEther(msg.sender, msg.value);
  }

  function onERC721Received(
    address from,
    address,
    uint256 id,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC721(msg.sender, from, id);
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address from,
    address,
    uint256 id,
    uint256 amount,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC1155(msg.sender, from, id, amount);
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address from,
    address,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC1155Batch(msg.sender, from, ids, amounts);
    return this.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}