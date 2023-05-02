// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Soccerverse Ltd

pragma solidity ^0.8.19;

import "@xaya/democrit-evm/contracts/Democrit.sol";
import "@xaya/democrit-evm/contracts/VaultManager.sol";

/**
 * @dev The Democrit main contract for Soccerverse.
 */
contract DemocritSoccerverse is Democrit
{

  constructor (VaultManager v)
    Democrit(v)
  {}

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;

import "./JsonSubObject.sol";
import "./NamePermissions.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@xaya/eth-account-registry/contracts/IXayaAccounts.sol";

/**
 * @dev The main delegation contract.  It uses the permissions tree system
 * implemented in the super contracts, and links it to the actual XayaAccounts
 * contract for sending moves.  It also enables ERC2771 meta transactions.
 */
contract XayaDelegation is NamePermissions, ERC2771Context, IERC721Receiver
{

  /* ************************************************************************ */

  /** @dev The XayaAccounts contract used.  */
  IXayaAccounts public immutable accounts;

  /** @dev The WCHI token used.  */
  IERC20 public immutable wchi;

  /**
   * @dev Temporarily set to true while we expect to receive name NFTs
   * (e.g. while registering for a user).
   *
   * It allows to receive name ERC721 tokens when set.
   */
  bool private allowNameReceive;

  /**
   * @dev Constructs the contract, fixing the XayaAccounts as well as forwarder
   * contracts.
   */
  constructor (IXayaAccounts acc, address fwd)
    ERC2771Context(fwd)
  {
    accounts = acc;
    wchi = accounts.wchiToken ();
    wchi.approve (address (accounts), type (uint256).max);
  }

  /**
   * @dev We accept ERC-721 token transfers only when explicitly specified
   * that we expect one, and we only accept Xaya names at all.
   */
  function onERC721Received (address, address, uint256, bytes calldata)
      public view override returns (bytes4)
  {
    require (msg.sender == address (accounts),
             "only Xaya names can be received");
    require (allowNameReceive, "tokens cannot be received at the moment");
    return IERC721Receiver.onERC721Received.selector;
  }

  /* ************************************************************************ */

  /**
   * @dev Registers a name for a given owner.  This registers the name,
   * transfers it, and then sets operator permissions for the delegation
   * contract with the owner's prepared signature.  With this method, we
   * can enable gas-free name registration with this contract's support
   * for meta transactions.  Returns the new token's ID.
   *
   * The WCHI for the name registration is paid for by _msgSender.
   */
  function registerFor (string memory ns, string memory name,
                        address owner, bytes memory signature)
      public returns (uint256 tokenId)
  {
    uint256 fee = accounts.policy ().checkRegistration (ns, name);
    if (fee > 0)
      require (wchi.transferFrom (_msgSender (), address (this), fee),
               "failed to obtain WCHI from sender");

    allowNameReceive = true;
    tokenId = accounts.register (ns, name);
    allowNameReceive = false;
    accounts.safeTransferFrom (address (this), owner, tokenId);

    /* In theory, we could eliminate the "owner" argument and just recover
       it from the signature always.  But that runs the risk of sending names
       to an unspendable address if the user messes up the signature, so we
       are explicit here to ensure this can't happen as easily.  */
    address fromSig = accounts.permitOperator (address (this), signature);
    require (owner == fromSig, "signature did not match owner");
  }

  /**
   * @dev Takes over a name:  This transfers the name to be owned by
   * the delegation contract (which is irreversible and corresponds to
   * a provable "lock" of the name).  This can only be done by the owner
   * of the name.  The previous owner will be granted top-level permissions,
   * based on which they can then selectively restrict their access if desired.
   */
  function takeOverName (string memory ns, string memory name)
      public
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    require (_msgSender () == owner, "only the owner can request a take over");

    allowNameReceive = true;
    accounts.safeTransferFrom (owner, address (this), tokenId);
    allowNameReceive = false;

    string[] memory emptyPath;
    /* We need to do a real, external transaction here (rather than an
       internal call), so that the sender is actually the contract now,
       which is the owner and allowed to grant permissions.  */
    this.grant (tokenId, address (this), emptyPath,
                owner, type (uint256).max, false);
  }

  /**
   * @dev Sends a move for the given name that contains some JSON data at
   * the given path.  Verifies that the _msgSender is allowed to send
   * a move for that name and path at the current time.  The nonce used is
   * returned (as from XayaAccounts.move).
   *
   * Any WCHI required for the move will be paid for by _msgSender.
   */
  function sendHierarchicalMove (string memory ns, string memory name,
                                 string[] memory path, string memory mv)
      public returns (uint256)
  {
    return sendHierarchicalMove (ns, name, path, mv, type (uint256).max,
                                 0, address (0));
  }

  /**
   * @dev Sends a move for the given name as the other sendHierarchicalMove
   * method, but allows control over nonce and WCHI payments.
   */
  function sendHierarchicalMove (string memory ns, string memory name,
                                 string[] memory path, string memory mv,
                                 uint256 nonce,
                                 uint256 amount, address receiver)
      public returns (uint256)
  {
    require (hasAccess (ns, name, path, _msgSender (), block.timestamp),
             "the message sender has no permission to send moves");

    string memory fullMove = JsonSubObject.atPath (path, mv);
    uint256 cost = accounts.policy ().checkMove (ns, fullMove) + amount;
    if (cost > 0)
      require (wchi.transferFrom (_msgSender (), address (this), cost),
               "failed to obtain WCHI from sender");

    return accounts.move (ns, name, fullMove, nonce, amount, receiver);
  }

  /* ************************************************************************ */

  /**
   * @dev Computes the tokenId and looks up the current owner for a given name.
   */
  function idAndOwner (string memory ns, string memory name)
      private view returns (uint256 tokenId, address owner)
  {
    tokenId = accounts.tokenIdForName (ns, name);
    owner = accounts.ownerOf (tokenId);
  }

  /* Expose the methods for managing permissions from NamePermissions on a
     per-name basis, with automatic lookup of the tokenId and current owner.

     This is just for convenience.  All logic (and checks!) are done in the
     according methods in NamePermissions, and those could be called directly
     as well by anyone if needed.  */

  function hasAccess (string memory ns, string memory name,
                      string[] memory path,
                      address operator, uint256 atTime)
      public view returns (bool)
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    return hasAccess (tokenId, owner, path, operator, atTime);
  }

  function grant (string memory ns, string memory name, string[] memory path,
                  address operator, uint256 expiration, bool fallbackOnly)
      public
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    grant (tokenId, owner, path, operator, expiration, fallbackOnly);
  }

  function revoke (string memory ns, string memory name, string[] memory path,
                   address operator, bool fallbackOnly)
      public
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    revoke (tokenId, owner, path, operator, fallbackOnly);
  }

  function resetTree (string memory ns, string memory name,
                      string[] memory path)
      public
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    resetTree (tokenId, owner, path);
  }

  function expireTree (string memory ns, string memory name,
                       string[] memory path)
      public
  {
    (uint256 tokenId, address owner) = idAndOwner (ns, name);
    expireTree (tokenId, owner, path);
  }

  /* ************************************************************************ */

  /* Explicitly specify that we want to use the ERC2771 variants for
     _msgSender and _msgData.  */

  function _msgSender ()
      internal view override(Context, ERC2771Context) returns (address)
  {
    return ERC2771Context._msgSender ();
  }

  function _msgData ()
      internal view override(Context, ERC2771Context) returns (bytes calldata)
  {
    return ERC2771Context._msgData ();
  }

  /* ************************************************************************ */

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;

import "./MovePermissions.sol";

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev A base smart contract that stores a tree of move permissions for
 * each token ID of a Xaya name, and NFT owner.  It also implements basic
 * methods to extract the data via public view methods if desired, and
 * to modify (grant and revoke) permissions.  These methods will ensure
 * proper authorisation checks, so that only users actually permitted
 * to grant or revoke permissions can do so.
 *
 * This contract is still "abstract" in that it does not actually link
 * to the XayaAccounts registry yet (and thus does not actually query
 * or process who really owns a name at the moment), and it also does not
 * yet implement actual move functions (just the permissions handling).
 */
contract NamePermissions is Context
{

  using MovePermissions for MovePermissions.PermissionsNode;

  /* ************************************************************************ */

  /**
   * @dev The permissions tree associated to each particular name when
   * owned by a given account.
   */
  mapping (uint256 => mapping (address => MovePermissions.PermissionsNode))
      private permissions;

  /** @dev Event fired when a permission is granted.  */
  event PermissionGranted (uint256 indexed tokenId, address indexed owner,
                           string[] path, address operator, uint256 expiration,
                           bool fallbackOnly);

  /**
   * @dev Event fired when a particular permission is revoked.  Note that this
   * may or may not mean that some empty nodes in the permissions tree
   * have been pruned as well.
   */
  event PermissionRevoked (uint256 indexed tokenId, address indexed owner,
                           string[] path, address operator, bool fallbackOnly);

  /**
   * @dev Event fired when an entire tree of permissions has been reset
   * to just a single permission (for the message sender).
   */
  event PermissionTreeReset (uint256 indexed tokenId, address indexed owner,
                             string[] path);

  /**
   * @dev Event fired when permissions inside a subtree have been explicitly
   * expired.  Note that the individual permissions removed do not emit
   * any more events.
   */
  event PermissionTreeExpired (uint256 indexed tokenId, address indexed owner,
                               string[] path, uint256 atTime);

  /* ************************************************************************ */

  /**
   * @dev Retrieves the permissions node at the given position.
   */
  function retrieve (uint256 tokenId, address owner, string[] memory path)
      private view returns (MovePermissions.PermissionsNode storage)
  {
    return permissions[tokenId][owner].retrieveNode (path);
  }

  /**
   * @dev Retrieves the address permissions tied to a given place in the
   * permissions hierarchy, operator and fallback status.
   */
  function retrieve (uint256 tokenId, address owner, string[] memory path,
                     address operator, bool fallbackOnly)
      private view returns (MovePermissions.AddressPermissions storage)
  {
    MovePermissions.PermissionsNode storage node
        = retrieve (tokenId, owner, path);
    return (fallbackOnly ? node.fallbackAccess.forAddress[operator]
                         : node.fullAccess.forAddress[operator]);
  }

  /**
   * @dev Returns true if there is a node with specific permissions
   * at the given hierarchy level (i.e. it exists).
   */
  function permissionExists (uint256 tokenId, address owner,
                             string[] memory path)
      public view returns (bool)
  {
    return retrieve (tokenId, owner, path).indexAndOne != 0;
  }

  /**
   * @dev Returns true if a specific permission exists at the given
   * node and for the given operator and fallback type.
   */
  function permissionExists (uint256 tokenId, address owner,
                             string[] memory path, address operator,
                             bool fallbackOnly)
      public view returns (bool)
  {
    MovePermissions.AddressPermissions storage addrPerm
        = retrieve (tokenId, owner, path, operator, fallbackOnly);
    return addrPerm.indexAndOne != 0;
  }

  /**
   * @dev Returns the expiration timestamp for a given operator permission
   * inside the storage.
   */
  function getExpiration (uint256 tokenId, address owner, string[] memory path,
                          address operator, bool fallbackOnly)
      public view returns (uint256)
  {
    MovePermissions.AddressPermissions storage addrPerm
        = retrieve (tokenId, owner, path, operator, fallbackOnly);
    return addrPerm.expiration;
  }

  /**
   * @dev Returns all defined keys (addresses with full access, addresses
   * with fallback access, and child paths) for the node at the given position
   * in the permissions.
   */
  function getDefinedKeys (uint256 tokenId, address owner, string[] memory path)
      public view returns (string[] memory children,
                           address[] memory fullAccess,
                           address[] memory fallbackAccess)
  {
    MovePermissions.PermissionsNode storage node
        = retrieve (tokenId, owner, path);
    children = node.keys;
    fullAccess = node.fullAccess.keys;
    fallbackAccess = node.fallbackAccess.keys;
  }

  /* ************************************************************************ */

  /**
   * @dev Checks if the given address has access permissions to the
   * given token and hierarchy level.  In addition to the actual rules
   * specified in the permissions themselves, the owner address always
   * has access.
   */
  function hasAccess (uint256 tokenId, address owner, string[] memory path,
                      address operator, uint256 atTime)
      public view returns (bool)
  {
    if (operator == owner)
      return true;

    return permissions[tokenId][owner].check (path, operator, atTime);
  }

  /**
   * @dev Tries to grant a particular permission, checking that the sender
   * of the message is actually allowed to do so.
   */
  function grant (uint256 tokenId, address owner, string[] memory path,
                  address operator, uint256 expiration, bool fallbackOnly)
      public
  {
    require (hasAccess (tokenId, owner, path, _msgSender (), expiration),
             "the sender has no access");

    permissions[tokenId][owner].grant (path, operator,
                                       expiration, fallbackOnly);
    emit PermissionGranted (tokenId, owner, path, operator,
                            expiration, fallbackOnly);
  }

  /**
   * @dev Checks if the root node for the given token and owner is empty
   * (i.e. potentially set but with nothing in it) and removes it if so.
   */
  function removeIfEmpty (uint256 tokenId, address owner) private
  {
    MovePermissions.PermissionsNode storage root = permissions[tokenId][owner];
    if (root.indexAndOne != 0 && root.isEmpty ())
      delete permissions[tokenId][owner];
  }

  /**
   * @dev Revokes a particular approval, checking that the message
   * sender is actually allowed to do so.
   */
  function revoke (uint256 tokenId, address owner, string[] memory path,
                   address operator, bool fallbackOnly)
      public
  {
    address sender = _msgSender ();
    /* Any address can revoke its own access, and also any access on levels
       where it has unlimited (in time) permissions.  */
    require (sender == operator
                || hasAccess (tokenId, owner, path, sender, type (uint256).max),
             "the sender has no access");

    permissions[tokenId][owner].revoke (path, operator, fallbackOnly);
    removeIfEmpty (tokenId, owner);
    emit PermissionRevoked (tokenId, owner, path, operator, fallbackOnly);
  }

  /**
   * @dev Revokes all permissions in a given subtree, and replaces them with
   * just a single permission for the message sender.  This can be used
   * to reset an entire tree of permissions if desired, while making sure the
   * message sender retains permission (but they can explicitly revoke their
   * own as well afterwards).  Reverts if the message sender has no access
   * to the requested level.
   */
  function resetTree (uint256 tokenId, address owner, string[] memory path)
      public
  {
    address sender = _msgSender ();
    require (hasAccess (tokenId, owner, path, sender, type (uint256).max),
             "the sender has no access");

    MovePermissions.PermissionsNode storage root = permissions[tokenId][owner];
    root.revokeTree (path);

    /* If the message sender is not the owner, we add them back as only
       permission at that level now (and then the subtree is by definition
       not empty).  Otherwise, they have access in any case, and we might
       be able to prune an empty tree.  */
    if (sender != owner)
      root.grant (path, sender, type (uint256).max, false);
    else
      removeIfEmpty (tokenId, owner);

    emit PermissionTreeReset (tokenId, owner, path);
  }

  /**
   * @dev Removes all expired permissions in the given subtree.  This may
   * have an indirect effect on fallback permissions, but otherwise does not
   * alter permissions (since it only removes ones that are expired anyway at
   * the current time).  Everyone is allowed to call this if they are willing
   * to pay for the gas.
   */
  function expireTree (uint256 tokenId, address owner, string[] memory path)
      public
  {
    permissions[tokenId][owner].expireTree (path, block.timestamp);
    removeIfEmpty (tokenId, owner);
    emit PermissionTreeExpired (tokenId, owner, path, block.timestamp);
  }

  /* ************************************************************************ */

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;

/**
 * @dev Solidity library that implements the core permissions logic for moves.
 * Those permissions form hierarchical trees (with one tree for a particular
 * account (token ID) and current owner).  The trees correspond to JSON "paths"
 * to specify which bits of a full move someone has permission for (e.g.
 * just the g->tn subobject to send Taurion moves, or even just a particular
 * type of move for one game).
 *
 * Each node in the tree can specify:
 *  - addresses that have permission for moves in that subtree,
 *    potentially with an expiration time
 *  - addresses that have "fallback permission" (with optional expiration),
 *    which means that have access to any subtree (not at the current level
 *    directly) that has no explicit node in the permissions tree
 *  - child nodes that further refine permissions for JSON fields
 *    below the current level
 *
 * This library implements the core logic for operating on these permission
 * trees, without actually triggering delegated moves nor even storing the
 * actual root trees themselves and tying them to accounts.  It just exposes
 * internal methods for querying and updating the permission trees passed in
 * as storage pointers.
 */
library MovePermissions
{

  /* ************************************************************************ */

  /**
   * @dev Helper struct which represents the data stored for an address
   * with (fallback) permissions.
   */
  struct AddressPermissions
  {

    /**
     * @dev The latest timestamp when permissions are granted, or uint256.max
     * if access is "unlimited".
     */
    uint256 expiration;

    /**
     * @dev The one-based index (i.e. the actual index + 1) of the address in
     * the parent struct's array of addresses with explicit permissions.
     *
     * This has two uses:  First, it allows us to explicitly and effectively
     * delete an entry and update the list of defined addresses at the same
     * time (by swap-replacing the entry at the given index with the last one
     * and shrinking the array).  Second, if the value is non-zero, we know that
     * the entry actually exists and is explicitly set (vs. zero meaning it
     * is a missing map entry).
     */
    uint indexAndOne;

  }

  /**
   * @dev A mapping of addresses to explicit permissions (mainly expiration
   * timestamps) of them.  This also contains book-keeping data so that
   * we can iterate through all explicit addresses and remove them if
   * so desired (as well as remove individual ones).
   */
  struct PermissionsMap
  {

    /** @dev Addresses and their associated permissions.  */
    mapping (address => AddressPermissions) forAddress;

    /** @dev List of all addresses with set permissions.  */
    address[] keys;

  }

  /**
   * @dev All data stored for permissions at a particular node in the
   * tree for one account.  This also contains necessary book-keeping data
   * to iterate the entire tree and remove all entries in it if desired.
   */
  struct PermissionsNode
  {

    /**
     * @dev The one-based index (i.e. actual index + 1) of this node
     * in the parent's "keys" array (similar to the field in
     * AddressPermissions).
     *
     * For the permissions at the tree's root, this value is just something
     * non-zero to indicate the entry actually exists.
     */
    uint indexAndOne;

    /** @dev Addresses that have full access at and below the current level.  */
    PermissionsMap fullAccess;

    /** @dev Addresses with fallback access only.  */
    PermissionsMap fallbackAccess;

    /** @dev Child nodes with explicitly defined permissions.  */
    mapping (string => PermissionsNode) children;

    /** @dev All keys for which child nodes are defined.  */
    string[] keys;

  }

  /* ************************************************************************ */

  /**
   * @dev Checks if the given address should have move permissions in a
   * particular permissions tree (whose root node is passed) for a particular
   * JSON path and at a particular time.  Returns true if permissions should
   * be granted and false if not.
   */
  function check (PermissionsNode storage root, string[] memory path,
                  address operator, uint256 atTime)
      internal view returns (bool)
  {
    /* For simplicity, we check "expiration >= atTime" later on against
       the permissions entries.  If an entry does not exist at all, expiration
       will be returned as zero.  This could lead to unexpected behaviour
       if we allow atTime to be zero.  Since a zero atTime is not relevant
       in practice anyway (since that is long in the past), let's explicitly
       disallow this.  */
    require (atTime > 0, "atTime must not be zero");

    PermissionsNode storage node = root;
    uint nextPath = 0;

    while (true)
      {
        /* If there is an explicit and non-expired full-access entry
           at the current level, we're good.  */
        if (node.fullAccess.forAddress[operator].expiration >= atTime)
          return true;

        /* We can't grant access directly at the current level.  So if the
           request is not for a deeper level, we reject it.  */
        assert (nextPath <= path.length);
        if (nextPath == path.length)
          return false;

        /* See if there is an explicit node for the next path level.
           If there is, we continue with it.  */
        PermissionsNode storage child = node.children[path[nextPath]];
        if (child.indexAndOne > 0)
          {
            node = child;
            ++nextPath;
            continue;
          }

        /* Finally, we apply access based on the fallback map.  */
        return node.fallbackAccess.forAddress[operator].expiration >= atTime;
      }

    /* We can never reach here, but this silences the compiler warning
       about a missing return.  */
    assert (false);
    return false;
  }

  /* ************************************************************************ */

  /**
   * @dev Looks up and returns (as storage pointer) the ultimate
   * tree node with the permissions for the given level.  If it (or any
   * of its parents) does not exist yet and "create" is set, those will be
   * added.
   */
  function retrieveNode (PermissionsNode storage root, string[] memory path,
                         bool create)
      private returns (PermissionsNode storage)
  {
    /* If the root itself does not actually exist (is not initialised yet),
       we do so as well.  For the root, the only thing that matters is
       that indexAndOne is not zero.  We set it to max uint256 just to emphasise
       it is not an actual, valid index.  */
    if (root.indexAndOne == 0 && create)
      root.indexAndOne = type (uint256).max;

    PermissionsNode storage node = root;
    for (uint i = 0; i < path.length; ++i)
      {
        PermissionsNode storage child = node.children[path[i]];

        /* If the node does not exist yet, add it explicitly to the parent's
           keys array, and store its indexAndOne.  */
        if (child.indexAndOne == 0 && create)
          {
            node.keys.push (path[i]);
            child.indexAndOne = node.keys.length;
          }

        node = child;
      }

    return node;
  }

  /**
   * @dev Looks up and returns (as storage pointer) the ultimate tree node
   * with the given level.  This method never auto-creates entries,
   * and is available to users of the library.  It is also "view".
   */
  function retrieveNode (PermissionsNode storage root, string[] memory path)
      internal view returns (PermissionsNode storage res)
  {
    res = root;
    for (uint i = 0; i < path.length; ++i)
      res = res.children[path[i]];
  }

  /**
   * @dev Sets the expiration timestamp associated to an address in a
   * permissions map to the given value.  This function also takes care to
   * update the necessary book-keeping fields (i.e. keys) in case this
   * actually inserts a new element.  Note that this is meant for granting
   * permissions, and as such the new timestamp must be non-zero and also
   * not earlier than any existing timestamp.
   */
  function setExpiration (PermissionsMap storage map, address key,
                          uint256 expiration) private
  {
    require (expiration > 0, "cannot grant permissions with zero expiration");

    AddressPermissions storage entry = map.forAddress[key];
    require (expiration >= entry.expiration,
             "existing permission has longer validity than new grant");
    entry.expiration = expiration;

    if (entry.indexAndOne == 0)
      {
        map.keys.push (key);
        entry.indexAndOne = map.keys.length;
      }
  }

  /**
   * @dev Unconditionally grants permissions in a given tree to a given
   * operator address, potentially in the fallback map.  The expiration time
   * must be non-zero and must not be earlier than any existing entry in the
   * given map.  No other checks are performed, so callers need to make sure
   * that it is actually permitted in the current context to grant the new
   * permission.
   */
  function grant (PermissionsNode storage root, string[] memory path,
                  address operator, uint256 expiration, bool fallbackOnly)
      internal
  {
    PermissionsNode storage node = retrieveNode (root, path, true);
    setExpiration (fallbackOnly ? node.fallbackAccess : node.fullAccess,
                   operator, expiration);
  }

  /* ************************************************************************ */

  /**
   * @dev Revokes permissions for an address in a PermissionsMap (i.e. removes
   * the corresponding entry, keeping "keys" up-to-date).
   */
  function removeEntry (PermissionsMap storage map, address key) private
  {
    uint oldIndex = map.forAddress[key].indexAndOne;
    if (oldIndex == 0)
      return;

    delete map.forAddress[key];

    /* Now we need to remove the entry from keys.  If it is the last one,
       we can just pop.  Otherwise we swap the last element into its position
       and pop then.  */

    if (oldIndex < map.keys.length)
      {
        address last = map.keys[map.keys.length - 1];
        map.keys[oldIndex - 1] = last;

        AddressPermissions storage lastEntry = map.forAddress[last];
        assert (lastEntry.indexAndOne > 0);
        lastEntry.indexAndOne = oldIndex;
      }

    map.keys.pop ();
  }

  /**
   * @dev Checks if a permissions node is empty, which means that it
   * has no children and no explicit permissions set.
   */
  function isEmpty (PermissionsNode storage node) internal view returns (bool)
  {
    return node.keys.length == 0
        && node.fullAccess.keys.length == 0
        && node.fallbackAccess.keys.length == 0;
  }

  /**
   * @dev Removes the child node at the given key below parent if it
   * is empty.  This takes care to update all the book-keeping stuff, like
   * parent.keys and the other child indices.
   */
  function removeChildIfEmpty (PermissionsNode storage parent,
                               string memory key) private
  {
    PermissionsNode storage child = parent.children[key];
    if (!isEmpty (child))
      return;

    uint oldIndex = child.indexAndOne;
    delete parent.children[key];

    /* If the child didn't exist at all, nothing to do.  */
    if (oldIndex == 0)
      return;

    /* Remove the child in parent.keys by swapping in the last element
       and popping at the tail.  */
    if (oldIndex < parent.keys.length)
      {
        string memory last = parent.keys[parent.keys.length - 1];
        parent.keys[oldIndex - 1] = last;

        PermissionsNode storage lastNode = parent.children[last];
        assert (lastNode.indexAndOne > 0);
        lastNode.indexAndOne = oldIndex;
      }

    parent.keys.pop ();
  }

  /**
   * @dev Removes all "empty" tree nodes along the specified branch to clean
   * up storage.  If a node has no children and both permission maps are
   * empty (no keys with associations), then it will be removed.  This has
   * "almost" no effect on permissions, with the exception being that it may
   * grant back permissions to addresses with fallback access.
   *
   * This method is used recursively, and considers only the tail of the
   * path array starting at the given "start" index.
   */
  function removeEmptyNodes (PermissionsNode storage node,
                             string[] memory path, uint start) private
  {
    /* If the current node does not exist or is at the leaf level,
       there is nothing to do.  Deleting of empty nodes is done one
       level up (from the call on its parent node), so that the parent's
       book-keeping data can be updated as well.  */
    if (node.indexAndOne == 0 || start == path.length)
      return;
    assert (start < path.length);

    /* Process the child node first, so descendant nodes further down
       are cleared now (if any).  */
    removeEmptyNodes (node.children[path[start]], path, start + 1);

    /* If the child node is empty, remove it.  */
    removeChildIfEmpty (node, path[start]);
  }

  /**
   * @dev Revokes a particular permission at the given tree level
   * and in the fallback or full-access map (based on the flag).
   *
   * This method does not perform any checks, so callers need to ensure
   * that it is actually ok to revoke that entry (e.g. the message sender
   * has the required authorisation).
   *
   * If this leads to completely "empty" tree nodes, they will be removed
   * and cleaned up as well.  Note that this may, in special situations, lead
   * to expanded permissions of an address with fallback access.
   */
  function revoke (PermissionsNode storage root, string[] memory path,
                   address operator, bool fallbackOnly) internal
  {
    PermissionsNode storage node = retrieveNode (root, path, false);
    removeEntry (fallbackOnly ? node.fallbackAccess : node.fullAccess,
                 operator);

    removeEmptyNodes (root, path, 0);
  }

  /* ************************************************************************ */

  /**
   * @dev Clears an entire PermissionsMap completely.
   */
  function clear (PermissionsMap storage map) private
  {
    for (uint i = 0; i < map.keys.length; ++i)
      delete map.forAddress[map.keys[i]];
    delete map.keys;
  }

  /**
   * @dev Revokes all permissions in the entire hierarchy starting at
   * the given node.  If deleteNode is set, then the node itself
   * will be removed (i.e. also the indexAndOne it has as marker).  If not,
   * then it will remain.
   */
  function revokeTree (PermissionsNode storage node, bool deleteNode) private
  {
    clear (node.fullAccess);
    clear (node.fallbackAccess);

    for (uint i = 0; i < node.keys.length; ++i)
      revokeTree (node.children[node.keys[i]], true);
    delete node.keys;

    if (deleteNode)
      delete node.indexAndOne;
  }

  /**
   * @dev Revokes all permissions for a node at a given path.
   */
  function revokeTree (PermissionsNode storage root, string[] memory path)
      internal
  {
    revokeTree (retrieveNode (root, path, false), false);
  }

  /* ************************************************************************ */

  /**
   * @dev Removes all expired permissions inside a PermissionsMap.
   */
  function expire (PermissionsMap storage map, uint256 atTime) private
  {
    /* removeEntry only affects (potentially) the elements from the removed
       index onwards, since it either pops the last element if that is the
       current one, or swaps in the last element into the current position.

       Thus if we iterate in reverse order, a single pass is enough even if
       we keep removing some of the elements while we do it.  */

    for (int i = int (map.keys.length) - 1; i >= 0; --i)
      {
        address current = map.keys[uint (i)];
        if (map.forAddress[current].expiration < atTime)
          removeEntry (map, current);
      }
  }

  /**
   * @dev Revokes all expired permissions in the given subtree (i.e. permissions
   * with a time earlier than the atTime timestamp).  Any child nodes that
   * become empty will be removed as well (but not the initial node with
   * which the method is called).
   */
  function expireTree (PermissionsNode storage node, uint256 atTime) private
  {
    expire (node.fullAccess, atTime);
    expire (node.fallbackAccess, atTime);

    /* As with expire, we process the children in reverse order, so that
       we need only a single pass even if nodes are removed (swapped with
       the last one) during the process.  */
    for (int i = int (node.keys.length) - 1; i >= 0; --i)
      {
        string memory current = node.keys[uint (i)];
        expireTree (node.children[current], atTime);
        removeChildIfEmpty (node, current);
      }
  }

  /**
   * @dev Revokes all permissions expired at the given timestamp (i.e. earlier
   * than atTime) in the subtree referenced.  Afterwards, all nodes that
   * have become empty will be cleaned out up to (not including) the root.
   */
  function expireTree (PermissionsNode storage root, string[] memory path,
                       uint256 atTime) internal
  {
    expireTree (retrieveNode (root, path, false), atTime);

    /* Also remove parent nodes of the expired tree if they became empty
       (expireTree only removes empty nodes below the first node on which
       it gets called).  */
    removeEmptyNodes (root, path, 0);
  }

  /* ************************************************************************ */

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;

/**
 * @dev A Solidity library that implements building of JSON moves
 * where a user-supplied "sub object" is placed at some specified
 * path (e.g. user-supplied move for a particular game ID in Xaya).
 * This includes validation required to ensure that users cannot
 * "inject" fake JSON strings to manipulate and break out of the
 * specified path.
 */
library JsonSubObject
{

  /**
   * @dev Checks if a string is a "safe" JSON object serialisation.  This means
   * that the string is either a valid and complete JSON object, or that it
   * will certainly produce invalid JSON if concatenated with other JSON
   * strings and placed at the position for some JSON value.
   * For simplicity, this method does not accept leading or trailing
   * whitespace around the outer-most {} of the object.
   *
   * This method is at the heart of the safe sub-object construction.
   * It ensures that the user-provided string cannot lead to an "injection"
   * of JSON syntax that breaks out of the intended path it is placed at,
   * either because it is a valid and proper JSON object, or because it will
   * at least produce invalid JSON in the end which leads to invalid moves.
   * By allowing the latter, we can simplify the processing necessary in
   * Solidity to a minimum.
   */
  function isSafe (string memory str) private pure returns (bool)
  {
    /* Essentially, what this method needs to detect and reject are
       strings like:

         null},"other game":{...

       If such a string would be put as sub-object into a particular place
       by adding something like

         {"g":{"some game":

       at the front and }} at the end, it could lead to attacks actually
       injecting move data for another game into what is, in the end,
       a fully valid JSON move.

       The main thing we need to do for this is ensure that the outermost
       {} brackets of the JSON object are properly matched; the value should
       begin with { and end with }, and while processing the string, there
       should always be at least one level of {} brackets open.  Other brackets
       (i.e. []) are not relevant, because if they are mismatched, it will
       ensure the final JSON value is certainly invalid.

       In addition to that, we need to track string literals well enough to
       ignore any brackets inside of them.  For this, we need to keep track
       of whether or not a string literal is open, and also properly handle
       \" (do not close it) and \\ (if followed by ", it closes the string).

       Any other validation or processing is not necessary.  We also don't have
       to deal with UTF-8 characters in any case (those can be part of
       string literals), as those are cannot interfere with the basic
       control syntax in JSON (which is ASCII).  Any invalid UTF-8 will just
       result in invalid UTF-8 (and thus, and invalid value) in the end.  */

    bytes memory data = bytes (str);

    /* The very first character should be the opening {.  */
    if (data.length < 1 || data[0] != '{')
      return false;

    int depth = 1;
    bool openString = false;
    bool afterBackslash = false;

    for (uint i = 1; i < data.length; ++i)
      {
        /* While we have more to process, we should never leave the
           outermost layer of brackets.  This is checked when processing
           the closing bracket, but just double-check it here.  */
        assert (depth > 0);

        /* Check if we are inside a string literal.  If we are, we need to
           look for its closing ", and handle backslash escapes.  */
        if (openString)
          {
            if (afterBackslash)
              {
                /* We don't have to care whatever comes after an escape.
                   The thing that matters is that it is not a closing ".  */
                afterBackslash = false;
                continue;
              }

            if (data[i] == '"')
              openString = false;
            else if (data[i] == '\\')
              afterBackslash = true;

            continue;
          }

        /* We are not inside a string literal, so track brackets and
           watch for opening of strings.  */

        assert (!afterBackslash);

        if (data[i] == '"')
          openString = true;
        else if (data[i] == '{')
          ++depth;
        else if (data[i] == '}')
          {
            --depth;
            assert (depth >= 0);
            /* We should always have a depth larger than zero, except for
               the very last character which will be the final closing } that
               leads to depth zero.  */
            if (depth == 0 && i + 1 != data.length)
              return false;
          }
      }

    /* At the end, all brackets should indeed be closed.  */
    return (depth == 0);
  }

  /**
   * @dev Checks if a string is safe as "string literal".  This means that
   * if quotes are added around it but nothing else is done, it is sure to
   * be a valid string literal.
   */
  function isSafeKey (string memory str) private pure returns (bool)
  {
    /* This method is used to check that the keys in a path are safe,
       in a quick and simple way.  We simply check that the string does
       not contain any \ or " characters, which is enough to guarantee
       that enclosing in quotes will safely yield a valid string literal.

       This prevents some strings from ever being possible to create,
       but since those are meant for object keys anyway, the main use will
       be stuff like all-lower-case ASCII names.  */

    bytes memory data = bytes (str);

    for (uint i = 0; i < data.length; ++i)
      if (data[i] == '"' || data[i] == '\\')
        return false;

    return true;
  }

  /**
   * @dev Builds up a string representing a JSON object where the user-supplied
   * sub-object is present at the given "path" within the full object.
   * Elements of "path" are supposed to be simple field names that don't
   * need escaping inside a JSON string literal.
   *
   * If the user-supplied string is indeed a valid JSON object, then this
   * method returns valid JSON as well (for the full object).  If the
   * subobject string is not a valid JSON object, then this method may
   * either revert or return a string that is invalid JSON (but it is guaranteed
   * to not return successfully a string that is valid).
   */
  function atPath (string[] memory path, string memory subObject)
      internal pure returns (string memory res)
  {
    require (isSafe (subObject), "possible JSON injection attempt");

    res = subObject;
    for (int i = int (path.length) - 1; i >= 0; --i)
      {
        string memory key = path[uint (i)];
        require (isSafeKey (key), "invalid path key");
        res = string (abi.encodePacked ("{\"", key, "\":", res, "}"));
      }
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev A Solidity library for validating UTF-8 from strings / bytes.
 * This is based on the definition of UTF-8 in RFC 3629.
 */
library Utf8
{

  /**
   * @dev Decodes the next codepoint from a byte array of UTF-8 encoded
   * data.  The input is expected in the byte(s) following the offset
   * into the array, and the return value is the decoded codepoint as well
   * as the offset of the following bytes (if any).  If the input bytes
   * are invalid, this method throws.
   */
  function decodeCodepoint (bytes memory data, uint offset)
      internal pure returns (uint32 cp, uint newOffset)
  {
    require (offset < data.length, "no more input bytes available");

    uint8 cur = uint8 (data[offset]);

    /* Special case for ASCII characters.  */
    if (cur < 0x80)
      return (cur, offset + 1);

    if (cur < 0xC0)
      revert ("mid-sequence character at start of sequence");

    /* Process the sequence-start character.  */
    uint8 numBytes;
    uint8 state;
    if (cur < 0xE0)
      {
        numBytes = 2;
        cp = uint32 (cur & 0x1F) << 6;
        state = 6;
      }
    else if (cur < 0xF0)
      {
        numBytes = 3;
        cp = uint32 (cur & 0x0F) << 12;
        state = 12;
      }
    else if (cur < 0xF8)
      {
        numBytes = 4;
        cp = uint32 (cur & 0x07) << 18;
        state = 18;
      }
    else
      revert ("invalid sequence start byte");
    newOffset = offset + 1;

    /* Process the following bytes of this sequence.  */
    while (state > 0)
      {
        require (newOffset < data.length, "eof in the middle of a sequence");

        cur = uint8 (data[newOffset]);
        newOffset += 1;

        require (cur & 0xC0 == 0x80, "expected sequence continuation");

        state -= 6;
        cp |= uint32 (cur & 0x3F) << state;
      }

    /* Verify that the character we decoded matches the number of bytes
       we had, to prevent overlong sequences.  */
    if (numBytes == 2)
      require (cp >= 0x80 && cp < 0x800, "overlong sequence");
    else if (numBytes == 3)
      require (cp >= 0x800 && cp < 0x10000, "overlong sequence");
    else
      {
        assert (numBytes == 4);
        require (cp >= 0x10000 && cp < 0x110000, "overlong sequence");
      }

    /* Prevent characters reserved for UTF-16 surrogate pairs.  */
    require (cp < 0xD800 || cp > 0xDFFF, "surrogate-pair character decoded");
  }

  /**
   * @dev Validates that the given sequence of bytes is valid UTF-8
   * as per the definition in RFC 3629.  Throws if not.
   */
  function validate (bytes memory data) internal pure
  {
    uint offset = 0;
    while (offset < data.length)
      (, offset) = decodeCodepoint (data, offset);
    assert (offset == data.length);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Utility library for building up strings in Solidity bit-by-bit,
 * without the need to re-allocate the string for each bit.
 */
library StringBuilder
{

  /**
   * @dev A string being built.  This is just a bytes array of a given
   * allocated size, and the current length (which might be smaller than
   * the allocated size).
   */
  struct Type
  {

    /**
     * @dev The allocated data array.  The size (stored in the first slot)
     * is set to the actual (current) length, rather than the allocated one.
     */
    bytes data;

    /** @dev The maximum / allocated size of the data array.  */
    uint maxLen;

  }

  /**
   * @dev Constructs a new builder that is empty initially but has space
   * for the given number of bytes.
   */
  function create (uint maxLen) internal pure returns (Type memory res)
  {
    bytes memory data = new bytes (maxLen);

    assembly {
      mstore (data, 0)
    }

    res.data = data;
    res.maxLen = maxLen;
  }

  /**
   * @dev Extracts the current data from a builder instance as string.
   */
  function extract (Type memory b) internal pure returns (string memory)
  {
    return string (b.data);
  }

  /**
   * @dev Adds the given string to the content of the builder.  This must
   * not exceed the allocated maximum size.
   */
  function append (Type memory b, string memory str) internal pure
  {
    bytes memory buf = b.data;
    bytes memory added = bytes (str);

    uint256 oldLen = buf.length;
    uint256 newLen = oldLen + added.length;
    require (newLen <= b.maxLen, "StringBuilder maxLen exceeded");
    assembly {
      mstore (buf, newLen)
    }

    for (uint i = 0; i < added.length; ++i)
      buf[i + oldLen] = added[i];
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Interface for a contract that defines the validation and fee
 * policy for Xaya accounts, as well as the NFT metadata returned for
 * a particular name.  This contract is the "part" of the Xaya account
 * registry that can be configured by the owner.
 *
 * All fees are denominated in WCHI tokens, this is not configurable
 * by the policy (but instead coded into the non-upgradable parts
 * of the account registry).
 */
interface IXayaPolicy
{

  /**
   * @dev Returns the address to which fees should be paid.
   */
  function feeReceiver () external returns (address);

  /**
   * @dev Verifies if the given namespace/name combination is valid; if it
   * is not, the function throws.  If it is valid, the fee that should be
   * charged is returned.
   */
  function checkRegistration (string memory ns, string memory name)
      external returns (uint256);

  /**
   * @dev Verifies if the given value is valid as a move for the given
   * namespace.  If it is not, the function throws.  If it is, the fee that
   * should be charged is returned.
   *
   * Note that the function does not know the exact name.  This ensures that
   * the policy cannot be abused to censor specific names (and the associated
   * game assets) after they have already been accepted for registration.
   */
  function checkMove (string memory ns, string memory mv)
      external returns (uint256);

  /**
   * @dev Constructs the full metadata URI for a given name.
   */
  function tokenUriForName (string memory ns, string memory name)
      external view returns (string memory);

  /**
   * @dev Returns the contract-level metadata for OpenSea.
   */
  function contractUri () external view returns (string memory);

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

import "./IXayaPolicy.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for the Xaya account registry contract.  This is the base
 * component of Xaya on any EVM chain, which keeps tracks of user accounts
 * and their moves.
 */
interface IXayaAccounts is IERC721
{

  /**
   * @dev Returns the address of the WCHI token used for payments
   * of fees and in moves.
   */
  function wchiToken () external returns (IERC20);

  /**
   * @dev Returns the address of the policy contract used.
   */
  function policy () external returns (IXayaPolicy);

  /**
   * @dev Returns the next nonce that should be used for a move with
   * the given token ID.  Nonces start at zero and count up for every move
   * sent.
   */
  function nextNonce (uint256 tokenId) external returns (uint256);

  /**
   * @dev Returns the unique token ID that corresponds to a given namespace
   * and name combination.  The token ID is determined deterministically from
   * namespace and name, so it does not matter if the account has been
   * registered already or not.
   */
  function tokenIdForName (string memory ns, string memory name)
      external pure returns (uint256);

  /**
   * @dev Returns the namespace and name for a token ID, which must exist.
   */
  function tokenIdToName (uint256)
      external view returns (string memory, string memory);

  /**
   * @dev Returns true if the given namespace/name combination exists.
   */
  function exists (string memory ns, string memory name)
      external view returns (bool);

  /**
   * @dev Returns true if the given token ID exists.
   */
  function exists (uint256 tokenId) external view returns (bool);

  /**
   * @dev Registers a new name.  The newly minted account NFT will be owned
   * by the caller.  Returns the token ID of the new account.
   */
  function register (string memory ns, string memory name)
      external returns (uint256);

  /**
   * @dev Sends a move with a given name, optionally attaching a WCHI payment
   * to the given receiver.  For no payment, amount and receiver should be
   * set to zero.
   *
   * If a nonce other than uint256.max is passed, then the move is valid
   * only if it matches exactly the account's next nonce.  The nonce used
   * is returned.
   */
  function move (string memory ns, string memory name, string memory mv,
                 uint256 nonce, uint256 amount, address receiver)
      external returns (uint256);

  /**
   * @dev Computes and returns the message to be signed for permitOperator.
   */
  function permitOperatorMessage (address operator)
      external view returns (bytes memory);

  /**
   * @dev Gives approval as per setApprovalForAll to an operator via a signed
   * permit message.  The owner to whose names permission is given is recovered
   * from the signature and returned.
   */
  function permitOperator (address operator, bytes memory signature)
      external returns (address);

  /**
   * @dev Emitted when a name is registered.
   */
  event Registration (string ns, string name, uint256 indexed tokenId,
                      address owner);

  /**
   * @dev Emitted when a move is sent.  If no payment is attached,
   * then the amount and address are zero.
   */
  event Move (string ns, string name, string mv,
              uint256 indexed tokenId,
              uint256 nonce, address mover,
              uint256 amount, address receiver);

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

import "./StringBuilder.sol";

/**
 * @dev A Solidity library for escaping UTF-8 characters into
 * hex sequences, e.g. for JSON string literals.
 */
library HexEscapes
{

  /** @dev Hex characters used.  */
  bytes internal constant HEX = bytes ("0123456789ABCDEF");

  /**
   * @dev Converts a single uint16 number into a \uXXXX JSON escape
   * string.  This does not do any UTF-16 surrogate pair conversion.
   */
  function jsonUint16 (uint16 val) private pure returns (string memory)
  {
    bytes memory res = bytes ("\\uXXXX");

    for (uint i = 0; i < 4; ++i)
      {
        res[5 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

  /**
   * @dev Converts a given Unicode codepoint into a corresponding
   * escape sequence inside a JSON literal.  This takes care of encoding
   * it into either one or two \uXXXX sequences based on UTF-16.
   */
  function jsonCodepoint (uint32 val) internal pure returns (string memory)
  {
    if (val < 0xD800 || (val >= 0xE000 && val < 0x10000))
      return jsonUint16 (uint16 (val));

    require (val >= 0x10000 && val < 0x110000, "invalid codepoint");

    val -= 0x10000;
    return string (abi.encodePacked (
      jsonUint16 (0xD800 | uint16 (val >> 10)),
      jsonUint16 (0xDC00 | uint16 (val & 0x3FF))
    ));
  }

  /**
   * @dev Converts a given Unicode codepoint into an XML escape sequence.
   */
  function xmlCodepoint (uint32 val) internal pure returns (string memory)
  {
    bytes memory res = bytes ("&#x000000;");

    for (uint i = 0; val > 0; ++i)
      {
        require (i < 6, "codepoint does not fit into 24 bits");

        res[8 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

  /**
   * @dev Converts a binary string into all-hex characters.
   */
  function hexlify (string memory str) internal pure returns (string memory)
  {
    bytes memory data = bytes (str);
    StringBuilder.Type memory builder = StringBuilder.create (2 * data.length);

    for (uint i = 0; i < data.length; ++i)
      {
        bytes memory cur = bytes ("xx");

        uint8 val = uint8 (data[i]);
        cur[1] = HEX[val & 0xF];
        val >>= 4;
        cur[0] = HEX[val & 0xF];

        StringBuilder.append (builder, string (cur));
      }

    return StringBuilder.extract (builder);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "./AccountHolder.sol";
import "./IDemocritConfig.sol";
import "./JsonUtils.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is a contract that manages a set of trading vaults in a
 * Democrit application.  It keeps track of each vault's state as it should
 * be inside the GSP, with the only unknown bit being whether or not the
 * vault was created at all (due to not knowing the real GSP state on chain).
 *
 * The contract is an AccountHolder, with the owned account acting as
 * controller for the vaults.  Vaults can be created (and funded in the
 * same transaction), and assets can be sent from vaults to arbitrary users.
 *
 * This contract is deployed stand-alone, but access to write methods (creating
 * vaults and transferring assets from vaults) is restricted to the "owner".
 * This owner will in production be the Democrit trading contract, which
 * utilises the vaults and triggers vault actions.  Note that in contrast
 * to many smart contracts, this "ownership" does not mean that anyone
 * (including the Xaya team) has any special access to user funds!
 */
contract VaultManager is AccountHolder, Ownable
{

  /** @dev The contract defining the Democrit config for this app.  */
  IDemocritConfig public immutable config;

  /**
   * @dev The data stored on chain for the state of each vault controlled
   * by the contract's account.  Only the balance is mutable after creation.
   */
  struct VaultData
  {

    /* The controller of the vault will always be the name owned
       by the AccountHolder, and the ID is known as index into the
       vaults array by which this struct is accessed.  */

    /** @dev The founder / owner account of the asset inside.  */
    string founder;

    /** @dev The asset type inside the vault.  */
    string asset;

    /** @dev The current balance as we know it on chain.  */
    uint balance;

  }

  /** @dev All vaults by ID.  Emptied vaults will be deleted.  */
  VaultData[] private vaults;

  /** @dev All checkpointed blocks we have seen in the contract.  */
  mapping (bytes32 => bool) private checkpoints;

  /**
   * @dev The lowest block height of a vault that has been created but
   * not yet checkpointed.  Creating vaults auto-triggers checkpointing
   * if there are such vaults, so there will only be exactly one such block
   * height anyway (if at all).  Because if another vault is created at a
   * later height, it will trigger checkpointing of the vaults at the
   * previous heights.  Zero if none such vaults exist.
   */
  uint public uncheckpointedHeight;

  /** @dev Emitted when a new vault is created and funded.  */
  event VaultCreated (string controller, uint id, string founder,
                      string asset, uint initialBalance);

  /** @dev Emitted when funds are sent from a vault.  */
  event SentFromVault (string controller, uint id, string recipient,
                       string asset, uint amount);

  /** @dev Emitted when the balance of a vault changes.  */
  event VaultChanged (string controller, uint id, string asset, uint balance);

  /** @dev Emitted when an empty vault gets removed.  */
  event VaultEmptied (string controller, uint id);

  /** @dev Emitted when a block hash is checkpointed.  */
  event CheckpointCreated (bytes32 hash);

  constructor (XayaDelegation del, IDemocritConfig cfg)
    AccountHolder(del)
  {
    config = cfg;

    /* We want vault IDs to start at 1, so that a zero ID can be taken
       to mean some entry does not exist.  Thus we add an empty vault at
       index zero.  */
    vaults.push ();
  }

  /**
   * @dev Returns the number of vaults that have been created (even if some
   * of them might have been emptied in the mean time).
   */
  function getNumVaults () public view returns (uint)
  {
    /* The vault at index zero is a dummy one created in the constructor
       and empty right away, we do not want to count it here.  */
    return vaults.length - 1;
  }

  /**
   * @dev Returns the ID given to the next created vault.
   */
  function getNextVaultId () public view returns (uint)
  {
    return vaults.length;
  }

  /**
   * @dev Returns the data for a given vault, or a zero struct if it does
   * not exist or has been emptied.
   */
  function getVault (uint vaultId) public view returns (VaultData memory res)
  {
    if (vaultId < vaults.length)
      res = vaults[vaultId];
  }

  /**
   * @dev Creates and funds a new vault.  It is not known whether or not the
   * founding user has enough of the given asset to fund the vault, so whether
   * or not the creation succeeds.  This is something that external users
   * need to check before relying on the existence of a vault.  However, in case
   * the vault is created successfully (i.e. they can query for it and it
   * exists), it is guaranteed that the contract's state will keep matching
   * the in-game state of the vault.  Returns the vault ID.
   */
  function createVault (string memory founder, string memory asset,
                        uint initialBalance)
      public onlyOwner returns (uint)
  {
    require (config.isTradableAsset (asset), "invalid asset for vault");
    require (initialBalance > 0, "initial balance must be positive");

    /* Trigger automatic checkpointing, and afterwards mark the current height
       as having a new vault.  */
    maybeCreateCheckpoint ();
    uncheckpointedHeight = block.number;

    uint vaultId = getNextVaultId ();
    VaultData storage data = vaults.push ();
    data.founder = founder;
    data.asset = asset;
    data.balance = initialBalance;

    string memory createMv
        = config.createVaultMove (account, vaultId, founder,
                                  asset, initialBalance);
    sendGameMove (createMv);

    (string[] memory path, string memory fundMv) =
        config.fundVaultMove (account, vaultId, founder,
                              asset, initialBalance);
    string[] memory fullPath = new string[] (path.length + 2);
    fullPath[0] = "g";
    fullPath[1] = config.gameId ();
    for (uint i = 0; i < path.length; ++i)
      fullPath[i + 2] = path[i];
    delegator.sendHierarchicalMove ("p", founder, fullPath, fundMv);

    emit VaultCreated (account, vaultId, founder, asset, initialBalance);

    return vaultId;
  }

  /**
   * @dev Sends funds from a vault controlled by the contract.  If the vault
   * is emptied, it will be cleared completely in the storage.
   */
  function sendFromVault (uint vaultId, string memory recipient, uint amount)
      public onlyOwner
  {
    require (amount > 0, "trying to send zero amount");

    VaultData memory data = vaults[vaultId];
    require (data.balance >= amount, "not enough funds in vault");

    /* Trigger automatic checkpointing after the most basic checks
       (so we don't waste gas in case those revert).  */
    maybeCreateCheckpoint ();

    string memory mv
        = config.sendFromVaultMove (account, vaultId, recipient,
                                    data.asset, amount);
    sendGameMove (mv);

    emit SentFromVault (account, vaultId, recipient, data.asset, amount);

    uint newBalance = data.balance - amount;
    emit VaultChanged (account, vaultId, data.asset, newBalance);

    if (newBalance > 0)
      vaults[vaultId].balance = newBalance;
    else
      {
        delete vaults[vaultId];
        emit VaultEmptied (account, vaultId);
      }
  }

  /**
   * @dev Checks if the given address is the owner or authorised for
   * the account name specified.  This is a helper method that is used to
   * verify the link between (mostly) _msgSender() and accounts from Democrit,
   * since accounts are the main entities used for ownership of vaults
   * and orders.
   */
  function hasAccountPermission (address operator, string memory name)
      public view returns (bool)
  {
    uint256 tokenId = accountRegistry.tokenIdForName ("p", name);
    address owner = accountRegistry.ownerOf (tokenId);
    return operator == owner
        || accountRegistry.isApprovedForAll (owner, operator)
        || accountRegistry.getApproved (tokenId) == operator;
  }

  /**
   * @dev Returns the current owner of the given account name.  This is
   * a helper method used by Democrit.  The owner is for instance who
   * receives ERC-20 tokens when a limit sell order is executed.
   */
  function getAccountAddress (string memory name)
      public view returns (address)
  {
    return accountRegistry.ownerOf (accountRegistry.tokenIdForName ("p", name));
  }

  /**
   * @dev Returns true if the given block hash is known as checkpoint.
   */
  function isCheckpoint (bytes32 hash) public view returns (bool)
  {
    return checkpoints[hash];
  }

  /**
   * @dev If there are any uncheckpointed vaults, trigger a checkpoint.
   * Note that creating a checkpoint is not security critical, so this
   * is a method that anyone is allowed to call any time they want, if
   * they are willing to pay for the gas.  The only thing perhaps bad that
   * could happen is that it triggers a move and the move costs the contract
   * WCHI; but also that will only ever be the case if there are actually
   * vaults to checkpoint, in which case the move is reasonable, and this
   * behaviour cannot be spammed either.
   */
  function maybeCreateCheckpoint () public
  {
    uint h = uncheckpointedHeight;
    if (h == 0 || h >= block.number)
      return;

    uint num = block.number - 1;
    bytes32 cpHash = blockhash (num);

    sendGameMove (config.checkpointMove (account, num, cpHash));
    checkpoints[cpHash] = true;

    uncheckpointedHeight = 0;
    emit CheckpointCreated (cpHash);
  }

  /**
   * @dev Sends a move with the owned account, wrapping it into
   * {"g":{"game id": ... }} for the config's game ID.
   */
  function sendGameMove (string memory mv) private
  {
    string memory gameId = JsonUtils.escapeString (config.gameId ());
    string memory fullMove
        = string (abi.encodePacked ("{\"g\":{", gameId, ":", mv, "}}"));
    sendMove (fullMove);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "./VaultManager.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev This contract implements limit sell orders as part of Democrit
 * (the "easy part").  Limit buy orders together with liquidity pools
 * are missing, and will be added in a subcontract.
 */
contract LimitSelling is Context
{

  /** @dev The VaultManager instance owned by this contract.  */
  VaultManager public immutable vm;

  /**
   * @dev The WCHI contract used for trading.  This matches the WCHI
   * in the VaultManager, but is replicated here to give easy access.
   */
  IERC20Metadata public immutable wchi;

  /**
   * @dev The data stored on chain for an active limit sell order.
   */
  struct SellOrder
  {

    /**
     * @dev The vault holding the assets to be sold.  This implies
     * the asset, remaining quantity, and owner (founder of the vault).
     */
    uint vaultId;

    /**
     * @dev The address which owned the vault's founder name at creation
     * time.  The order is only valid to take when it still is the owner,
     * to prevent potential attacks with creating orders and
     * transferring/selling the name.
     */
    address creator;

    /**
     * @dev The amount in WCHI sats required to buy out the entire vault's
     * remaining balance.  This implies the limit price by proportion.
     */
    uint totalSats;

  }

  /**
   * @dev Complete data for a sell order, including the "implied"
   * bits of information.  This is not stored anywhere, but returned
   * from helper functions in memory.
   */
  struct CompleteSellOrder
  {

    /** @dev The ID of the order.  */
    uint orderId;

    /** @dev The vault ID associated to it.  */
    uint vaultId;

    /** @dev The owner address at creation time.  */
    address creator;

    /** @dev The seller account.  */
    string seller;

    /** @dev The asset being sold.  */
    string asset;

    /** @dev The remaining amount of asset available.  */
    uint remainingAmount;

    /** @dev The total in WCHI sats asked for the remainingAmount.  */
    uint totalSats;

  }

  /**
   * @dev The next ID given to a limit order.  The same sequence of IDs is
   * applied to limit sell and future limit buy orders.
   */
  uint public nextOrderId;

  /** @dev All active sell orders by ID.  */
  mapping (uint => SellOrder) private sellOrders;

  /** @dev Emitted when a new sell order is created.  */
  event SellOrderCreated (uint orderId, uint vaultId, address creator,
                          string seller, string asset,
                          uint amount, uint totalSats);
  /**
   * @dev Emitted when an existing sell order is updated
   * (i.e. partially taken).
   */
  event SellOrderUpdated (uint orderId, uint amount, uint totalSats);
  /**
   * @dev Emitted when a sell order is removed, either by being cancelled
   * or taken entirely.
   */
  event SellOrderRemoved (uint orderId);

  /**
   * @dev Emitted when a trade happens.  This is also emitted from the
   * subcontract doing limit buy orders.
   */
  event Trade (string asset, uint amount, uint sats,
               string seller, string buyer);

  constructor (VaultManager v)
  {
    vm = v;
    wchi = vm.wchi ();

    /* We start with ID 1, so that an ID being zero can be taken to mean
       that data does not exist.  */
    nextOrderId = 1;
  }

  /**
   * @dev Returns the amount of WCHI sats required to pay for
   * the given amount of assets from an order, based on the total remaining
   * amount and sats price for all of it.  This is a utility method which
   * can also be applied for limit buy orders.
   *
   * The amount will be linearly interpolated (i.e. just proportional),
   * rounding up to the next full sat.
   */
  function getSatsForPurchase (uint remainingAmount, uint totalSats,
                               uint amountBought) public pure returns (uint)
  {
    require (remainingAmount > 0, "expected non-zero remaining amount");
    require (amountBought > 0, "amount bought must be non-zero");
    require (amountBought <= remainingAmount, "amount exceeds remaining");

    /* If purchasing all, then the price will be just the asked total.  */
    if (amountBought == remainingAmount)
      return totalSats;

    /* Otherwise, the price will be proportional to the amount bought,
       rounded up to the next sat.  Note that if the product overflows,
       this will revert (instead of silently proceed) due to Solidity 0.8
       "safe math" semantics.  But totalSats is in a safe range anyway,
       as it will be verified against the user's WCHI balance, and
       if the amount would be out of range, then the vault would not exist
       and thus the trade should not proceed anyway.  */
    return (amountBought * totalSats + remainingAmount - 1) / remainingAmount;
  }

  /**
   * @dev Returns full data for a given sell order by ID, including the
   * fields taken from the vaults storage.
   */
  function getSellOrder (uint orderId)
      public view returns (CompleteSellOrder memory)
  {
    SellOrder storage data = sellOrders[orderId];
    uint vaultId = data.vaultId;
    if (vaultId == 0)
      {
        CompleteSellOrder memory nullOrder;
        return nullOrder;
      }

    VaultManager.VaultData memory vault = vm.getVault (vaultId);
    /* When the vault associated to an order is emptied, the order
       is removed as well.  So if the order exists, the vault must
       exist (with non-zero balance), too.  */
    assert (vault.balance > 0);

    return CompleteSellOrder ({
      orderId: orderId,
      vaultId: vaultId,
      creator: data.creator,
      totalSats: data.totalSats,
      seller: vault.founder,
      asset: vault.asset,
      remainingAmount: vault.balance
    });
  }

  /**
   * @dev Creates a new limit sell order with the given specifics.  Returns
   * the order ID of the new order.
   */
  function createSellOrder (string memory seller, string memory asset,
                            uint amount, uint totalSats)
      public returns (uint)
  {
    require (amount > 0, "non-zero amount required");
    require (vm.hasAccountPermission (_msgSender (), seller),
             "no permission to act on behalf of this account");

    uint vaultId = vm.createVault (seller, asset, amount);
    assert (vaultId > 0);
    uint orderId = nextOrderId++;
    address creator = vm.getAccountAddress (seller);

    sellOrders[orderId] = SellOrder ({
      vaultId: vaultId,
      creator: creator,
      totalSats: totalSats
    });
    emit SellOrderCreated (orderId, vaultId, creator, seller,
                           asset, amount, totalSats);

    return orderId;
  }

  /**
   * @dev Cancels an existing limit sell order, refunding the vault's
   * remaining asset balance to the owner.
   */
  function cancelSellOrder (uint orderId) public
  {
    CompleteSellOrder memory data = getSellOrder (orderId);
    require (data.orderId == orderId, "order does not exist");
    require (vm.hasAccountPermission (_msgSender (), data.seller),
             "no permission to act on behalf of the seller account");

    vm.sendFromVault (data.vaultId, data.seller, data.remainingAmount);
    delete sellOrders[orderId];
    emit SellOrderRemoved (orderId);
  }

  /**
   * @dev Arguments required for accepting a sell order (i.e. "market buy").
   * We put them into a struct, so that we can easily provide a function
   * to accept a batch of orders (when that is necessary to fill the desired
   * buy on the front-end side).
   */
  struct AcceptedSellOrder
  {

    /** The order ID being accepted.  */
    uint orderId;

    /** The amount of asset being bought.  */
    uint amountBought;

    /** The buyer's account name to send assets to.  */
    string buyer;

    /** The checkpoint against which the vault was verified in the GSP.  */
    bytes32 checkpoint;

    /* Note that the limit price of orders is immutable once the order
       is created (it may only go down marginally due to rounding up the
       prices paid by previous takers).  Thus there is no need to specify
       the expected price when taking an order.

       Even reorgs that would create a differing order are not possible,
       since the checkpoint protects against them.  */

  }

  /**
   * @dev Accepts a limit sell order, buying all or part of the offered
   * asset.  The payment is taken in WCHI from the _msgSender() and
   * forwarded to the current owner of the seller account name.
   */
  function acceptSellOrder (AcceptedSellOrder calldata args) public
  {
    CompleteSellOrder memory data = getSellOrder (args.orderId);
    require (data.orderId > 0, "order does not exist");
    require (vm.isCheckpoint (args.checkpoint), "vault checkpoint is invalid");
    /* Calculating the purchase amount of sats checks for the amount bought
       being non-zero and not exceeding the available amount already, so there
       is no need to explicitly check those here.  */
    uint sats = getSatsForPurchase (data.remainingAmount, data.totalSats,
                                    args.amountBought);

    address sellerAddress = vm.getAccountAddress (data.seller);
    require (sellerAddress == data.creator, "seller name has been transferred");

    require (wchi.transferFrom (_msgSender (), sellerAddress, sats),
             "WCHI transfer failed");
    vm.sendFromVault (data.vaultId, args.buyer, args.amountBought);

    emit Trade (data.asset, args.amountBought, sats, data.seller, args.buyer);
    if (args.amountBought == data.remainingAmount)
      {
        delete sellOrders[data.orderId];
        emit SellOrderRemoved (data.orderId);
      }
    else
      {
        uint newRemaining = data.remainingAmount - args.amountBought;
        assert (newRemaining > 0);
        uint newSats = data.totalSats - sats;

        sellOrders[data.orderId].totalSats = newSats;
        emit SellOrderUpdated (data.orderId, newRemaining, newSats);
      }
  }

  /**
   * @dev Accepts a batch of limit sell orders as per acceptSellOrder.  This
   * allows to fill a range of orders in a single transaction, as may be
   * required to fill a particular "market buy".
   */
  function acceptSellOrders (AcceptedSellOrder[] calldata orders) public
  {
    for (uint i = 0; i < orders.length; ++i)
      acceptSellOrder (orders[i]);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "./IDemocritConfig.sol";
import "./LimitSelling.sol";
import "./VaultManager.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @dev This contract adds support for limit buy orders, together with the
 * trading pools needed for it, to Democrit.
 */
contract LimitBuying is LimitSelling, EIP712
{

  string public constant EIP712_NAME = "Democrit";
  string public constant EIP712_VERSION = "1";

  /**
   * @dev The Democrit config.  This matches the config of the associated
   * VaultManager, but is duplicated here for easier access.
   */
  IDemocritConfig public immutable config;

  /* ************************************************************************ */

  /**
   * @dev The data stored for a trading pool.
   *
   * Note that this is just the "extra data" required in addition to the
   * base data in the associated vault.  The vault ID is used as key in the
   * mapping of existing pools.
   */
  struct Pool
  {

    /**
     * @dev Set to true for pools that exist.  Since the relFee might be zero
     * for an existing pool, we need this to distinguish pools from non-existing
     * data in the mapping.
     */
    bool exists;

    /**
     * @dev The relative fee charged by this pool, in a fraction relative
     * to the config's feeDenominator.
     */
    uint64 relFee;

    /* The asset inside a pool, the remaining quantity and the owner account
       of the pool are implied by the associated vault.  */

  }

  /**
   * @dev Existing trading pools.  They are indexed by a subset of existing
   * vault IDs.  A pool exists for each vault that has an index here.
   */
  mapping (uint => Pool) private pools;

  /** @dev Emitted when a pool is created.  */
  event PoolCreated (uint vaultId, string operator, string endpoint,
                     string asset, uint amount, uint64 relFee);

  /** @dev Emitted when a pool has the balance updated.  */
  event PoolUpdated (uint vaultId, uint newAmount);

  /** @dev Emitted when a pool is emptied / removed.  */
  event PoolRemoved (uint vaultId);

  /** @dev All vaults that are sell deposits.  No extra data is needed.  */
  mapping (uint => bool) private sellDeposits;

  /** @dev Emitted when a sell deposit is created.  */
  event SellDepositCreated (uint vaultId, string owner,
                            string asset, uint amount);

  /** @dev Emitted when a sell deposit changes balance.  */
  event SellDepositUpdated (uint vaultId, uint newAmount);

  /** @dev Emitted when a sell deposit is removed.  */
  event SellDepositRemoved (uint vaultId);

  /**
   * @dev The data stored for an active limit buy order.
   */
  struct BuyOrder
  {

    /**
     * @dev The trading pool to be used.  If the pool becomes emptied and
     * removed, the order itself will be seen as void (even if this struct
     * is still in storage).  If the pool's balance drops below remainingAmount
     * but is non-zero, then up to this amount can be bought.
     */
    uint poolId;

    /**
     * @dev The address which owned the buyer account name when the order
     * was created.  It can only be taken if it still owns the account.
     */
    address creator;

    /** @dev The account name owning this order.  */
    string buyer;

    /** @dev The amount of asset that is still to be bought.  */
    uint remainingAmount;

    /** @dev The total in WCHI sats offered for the remainingAmount.  */
    uint totalSats;

    /* The asset being bought is implied by the trading pool used.  */

  }

  /** @dev Existing buy orders by ID.  */
  mapping (uint => BuyOrder) private buyOrders;

  /** @dev Emitted when a buy order is created.  */
  event BuyOrderCreated (uint orderId, uint poolId, address creator,
                         string buyer, string asset,
                         uint amount, uint totalSats);
  /** @dev Emitted when a buy order is updated.  */
  event BuyOrderUpdated (uint orderId, uint amount, uint totalSats);
  /** @dev Emitted when a buy order is removed.  */
  event BuyOrderRemoved (uint orderId);

  /**
   * @dev We use "nonce" values for the EIP712 pool signatures.  They are not
   * single use, but a signature is only valid when it commits to the current
   * nonce explicitly, and the nonce can be bumped on-demand to invalidate
   * all made signatures in case that is necessary for some reason.
   *
   * The nonces are tied to the operator account name.
   */
  mapping (string => uint256) public signatureNonce;

  /* ************************************************************************ */

  constructor (VaultManager v)
    LimitSelling(v)
    EIP712(EIP712_NAME, EIP712_VERSION)
  {
    config = v.config ();
  }

  /* ************************************************************************ */

  /**
   * @dev Computes the fee in sats to be paid to a pool, based on its
   * configured relative fee, for processing a trade of the given sats.
   */
  function getPoolFee (uint64 relFee, uint totalSats) public view returns (uint)
  {
    /* We round the fee up to the next sat.  */
    uint denom = config.feeDenominator ();
    return (totalSats * uint256 (relFee) + denom - 1) / denom;
  }

  /**
   * @dev Complete data associated to a trading pool, including the
   * fields implied by the vault.  This struct is not stored on chain but
   * used to return data in memory.
   */
  struct CompletePool
  {

    /** @dev The pool's and associated vault's ID.  */
    uint vaultId;

    /** @dev The operator of the pool.  */
    string operator;

    /** @dev The asset inside the pool.  */
    string asset;

    /** @dev Amount of asset remaining in the pool.  */
    uint amount;

    /** @dev Relative fee charged by the pool.  */
    uint64 relFee;

  }

  /**
   * @dev Returns the full data associated to a given trading pool.
   * Returns a zero struct (in particular, vaultId being zero) if no such
   * pool exists.
   */
  function getPool (uint vaultId)
      public view returns (CompletePool memory)
  {
    Pool storage data = pools[vaultId];
    if (!data.exists)
      {
        CompletePool memory nullPool;
        return nullPool;
      }

    VaultManager.VaultData memory vault = vm.getVault (vaultId);
    /* When the vault is emptied, the pool is removed.  So since the pool
       exists, the vault must exist and be non-empty as well.  */
    assert (vault.balance > 0);

    return CompletePool ({
      vaultId: vaultId,
      operator: vault.founder,
      asset: vault.asset,
      amount: vault.balance,
      relFee: data.relFee
    });
  }

  /**
   * @dev Vaults the given funds into a freshly created trading pool.
   * The endpoint is an (optional) string specifying how the pool can be
   * contacted with requests to verify vaults; it will be emitted in the
   * event data, so can be retrieved from an indexer like The Graph
   * by the frontend.
   */
  function createPool (string memory operator, string memory endpoint,
                       string memory asset,
                       uint amount, uint64 relFee)
      public returns (uint)
  {
    require (amount > 0, "non-zero amount required");
    require (relFee <= config.maxRelPoolFee (), "fee too high");
    require (vm.hasAccountPermission (_msgSender (), operator),
             "no permission to act on behalf of this account");

    uint vaultId = vm.createVault (operator, asset, amount);
    assert (vaultId > 0);

    pools[vaultId] = Pool ({
      exists: true,
      relFee: relFee
    });
    emit PoolCreated (vaultId, operator, endpoint, asset, amount, relFee);

    return vaultId;
  }

  /**
   * @dev Cancels an existing trading pool, refunding all remaining asset
   * in the vault to the operator.  This will of course invalidate all
   * open buy orders based on this pool.
   */
  function cancelPool (uint vaultId) public
  {
    CompletePool memory data = getPool (vaultId);
    require (data.vaultId == vaultId, "trading pool does not exist");
    require (vm.hasAccountPermission (_msgSender (), data.operator),
             "no permission to act on behalf of the operator account");

    vm.sendFromVault (data.vaultId, data.operator, data.amount);
    delete pools[vaultId];
    emit PoolRemoved (vaultId);
  }

  /* ************************************************************************ */

  /**
   * @dev Complete data for a sell deposit, as it is returned in memory
   * when querying the contract.
   */
  struct CompleteSellDeposit
  {

    /** @dev The vault's associated ID.  */
    uint vaultId;

    /** @dev The owner of the deposit.  */
    string owner;

    /** @dev The asset inside the vault.  */
    string asset;

    /** @dev Amount of asset remaining in the vault.  */
    uint amount;

  }

  /**
   * @dev Returns the data for a sell deposit.  They are identified and
   * queried by vault ID.  If the vault does not exist or is not a sell
   * deposit, then a null struct will be returned.
   */
  function getSellDeposit (uint vaultId)
      public view returns (CompleteSellDeposit memory)
  {
    if (!sellDeposits[vaultId])
      {
        CompleteSellDeposit memory nullDeposit;
        return nullDeposit;
      }

    VaultManager.VaultData memory vault = vm.getVault (vaultId);
    assert (vault.balance > 0);

    return CompleteSellDeposit ({
      vaultId: vaultId,
      owner: vault.founder,
      asset: vault.asset,
      amount: vault.balance
    });
  }

  /**
   * @dev Vaults the given funds into a freshly created sell deposit,
   * that the user can then use to accept a buy order (or just keep
   * available / redeem later).
   */
  function createSellDeposit (string memory owner,
                              string memory asset, uint amount)
      public returns (uint)
  {
    require (amount > 0, "non-zero amount required");
    require (vm.hasAccountPermission (_msgSender (), owner),
             "no permission to act on behalf of this account");

    uint vaultId = vm.createVault (owner, asset, amount);
    assert (vaultId > 0);

    sellDeposits[vaultId] = true;
    emit SellDepositCreated (vaultId, owner, asset, amount);

    return vaultId;
  }

  /**
   * @dev Cancels an existing sell deposit, refunding all remaining asset
   * in the vault to the owner.
   */
  function cancelSellDeposit (uint vaultId) public
  {
    CompleteSellDeposit memory data = getSellDeposit (vaultId);
    require (data.vaultId == vaultId, "sell deposit does not exist");
    require (vm.hasAccountPermission (_msgSender (), data.owner),
             "no permission to act on behalf of the owner account");

    vm.sendFromVault (data.vaultId, data.owner, data.amount);
    delete sellDeposits[vaultId];
    emit SellDepositRemoved (vaultId);
  }

  /* ************************************************************************ */

  /**
   * @dev Complete data for a buy order, incorporating data from the
   * associated trading pool.
   */
  struct CompleteBuyOrder
  {

    /** @dev The ID of the buy order.  */
    uint orderId;

    /** @dev The trading pool to be used.  */
    uint poolId;

    /** @dev Data about the trading pool.  */
    CompletePool poolData;

    /**
     * @dev The address which owned the buyer account name when the order
     * was created.  It can only be taken if it still owns the account.
     */
    address creator;

    /** @dev The account name owning this order.  */
    string buyer;

    /** @dev The asset being bought.  */
    string asset;

    /** @dev The amount of asset that is still to be bought.  */
    uint remainingAmount;

    /** @dev The total in WCHI sats offered for the remainingAmount.  */
    uint totalSats;

  }

  /**
   * @dev Returns data about a buy order.
   */
  function getBuyOrder (uint orderId)
      public view returns (CompleteBuyOrder memory)
  {
    BuyOrder storage data = buyOrders[orderId];
    uint poolId = data.poolId;
    if (poolId == 0)
      {
        /* The buy order itself does not exist for this ID.  */
        CompleteBuyOrder memory nullOrder;
        return nullOrder;
      }

    CompletePool memory pool = getPool (poolId);
    if (pool.vaultId == 0)
      {
        /* The order ID exists, but the associated pool is removed.  */
        CompleteBuyOrder memory nullOrder;
        return nullOrder;
      }

    return CompleteBuyOrder ({
      orderId: orderId,
      poolId: poolId,
      poolData: pool,
      creator: data.creator,
      buyer: data.buyer,
      asset: pool.asset,
      remainingAmount: data.remainingAmount,
      totalSats: data.totalSats
    });
  }

  /**
   * @dev Creates a new limit buy order.
   */
  function createBuyOrder (string memory buyer, string memory asset,
                           uint amount, uint totalSats,
                           uint poolId, bytes32 checkpoint)
      public returns (uint)
  {
    require (amount > 0, "non-zero amount required");
    require (vm.hasAccountPermission (_msgSender (), buyer),
             "no permission to act on behalf of this account");
    /* There is no need to explicitly check the asset.  Since we only accept
       assets that have a valid trading pool and that pool's creation only
       allows valid assets, this is implied.  */

    CompletePool memory pool = getPool (poolId);
    /* This also implicitly checks that the pool exists, since otherwise
       the balance would be zero (and amount is larger than zero).  */
    require (pool.amount >= amount, "pool has insufficient balance");
    require (keccak256 (abi.encodePacked (pool.asset))
                == keccak256 (abi.encodePacked (asset)),
             "pool asset mismatch");
    require (vm.isCheckpoint (checkpoint), "pool checkpoint is invalid");

    /* We do not lock the WCHI, but at least sanity check that at the
       current moment, the buyer has a sufficient balance for the case
       of fully buying the order.  */
    address creator = vm.getAccountAddress (buyer);
    uint poolFee = getPoolFee (pool.relFee, totalSats);
    uint totalWchiCost = totalSats + poolFee;
    require (wchi.balanceOf (creator) >= totalWchiCost,
             "insufficient WCHI balance");
    require (wchi.allowance (creator, address (this)) >= totalWchiCost,
             "insufficient WCHI allowance");

    uint orderId = nextOrderId++;
    buyOrders[orderId] = BuyOrder ({
      poolId: poolId,
      creator: creator,
      buyer: buyer,
      remainingAmount: amount,
      totalSats: totalSats
    });
    emit BuyOrderCreated (orderId, poolId, creator, buyer, asset,
                          amount, totalSats);

    return orderId;
  }

  /**
   * @dev Cancels an existing buy order.
   */
  function cancelBuyOrder (uint orderId) public
  {
    /* We query the storage directly, instead of using getBuyOrder.  The
       latter does not return an order if the associated pool is removed,
       but we want to be able to cancel those as well (even if just
       for the sake of it, as it won't have any practical implications).  */

    BuyOrder storage data = buyOrders[orderId];
    require (data.poolId > 0, "order does not exist");
    require (vm.hasAccountPermission (_msgSender (), data.buyer),
             "no permission to act on behalf of the buyer account");

    /* Since no WCHI or anything else are locked, nothing needs to be
       done apart from updating the order book.  */
    delete buyOrders[orderId];
    emit BuyOrderRemoved (orderId);
  }

  /* ************************************************************************ */

  /**
   * @dev Returns the EIP712 domain separator used for signatures
   * verified by this contract.
   */
  function domainSeparator () public view returns (bytes32)
  {
    return _domainSeparatorV4 ();
  }

  /**
   * @dev The data signed by a trading pool with EIP712 when they have
   * verified a given vault.
   */
  struct VaultCheck
  {

    /** @dev The vault ID they have verified.  */
    uint256 vaultId;

    /** @dev The checkpoint at which they have verified the vault exists.  */
    bytes32 checkpoint;

    /* The EIP712 signed struct also includes a nonce here, which is implied
       by the contract state and thus not passed explicitly.  */

  }

  /**
   * @dev Verifies if a given vault check has been signed correctly by
   * the owner of the given account or an address authorised for it.
   *
   * Note that this only verifies if the signature is valid.  It does not check
   * if the vault exists, the checkpoint is valid, or anything else like that.
   */
  function isPoolSignatureValid (string memory operator,
                                 VaultCheck calldata vault,
                                 bytes calldata signature)
      public view returns (bool)
  {
    bytes memory body = abi.encode (
      keccak256 ("VaultCheck(uint256 vaultId,bytes32 checkpoint,uint256 nonce)"),
      vault.vaultId,
      vault.checkpoint,
      signatureNonce[operator]
    );
    bytes32 digest = _hashTypedDataV4 (keccak256 (body));

    address signer = ECDSA.recover (digest, signature);
    return vm.hasAccountPermission (signer, operator);
  }

  /**
   * @dev Bumps the signature nonce for the given pool.  Returns the new
   * nonce for the pool.
   */
  function bumpSignatureNonce (string memory operator) public returns (uint256)
  {
    require (vm.hasAccountPermission (_msgSender (), operator),
             "no permission to act on behalf of the pool operator");
    return ++signatureNonce[operator];
  }

  /* ************************************************************************ */

  /**
   * @dev Arguments required for accepting a buy order ("market sell").
   * They are collected into a struct so that we can provide also a method
   * for batch-accepting multiple orders easily.
   */
  struct AcceptedBuyOrder
  {

    /** The order ID being accepted.  */
    uint orderId;

    /** The amount of asset being sold.  */
    uint amountSold;

    /** Sell deposit and checkpoint at which the pool has verified it.  */
    VaultCheck deposit;

    /** The pool's signature on the vault check.  */
    bytes signature;

    /* The limit price of orders is fixed once the order is created, so that
       we do not need to explicitly specify the expected price in sats in the
       order.

       The trading pool's ID is implicit from the order accepted,
       and the seller account is fixed by the used sell deposit.  */

  }

  /**
   * @dev Accepts a limit buy order, selling all or part of the desired asset
   * utilising a sell deposit and trading pool.
   */
  function acceptBuyOrder (AcceptedBuyOrder calldata args) public
  {
    CompleteBuyOrder memory order = getBuyOrder (args.orderId);
    require (order.orderId > 0, "order does not exist");
    assert (order.poolData.vaultId > 0);
    /* Calculating the purchase amount of sats already checks the
       amount bought is non-zero and within the available limits for
       the order.  The limits for the sell deposit and trading pool balances
       are checked when we attempt to transfer from the respective vaults.  */
    uint sats = getSatsForPurchase (order.remainingAmount, order.totalSats,
                                    args.amountSold);
    uint fee = getPoolFee (order.poolData.relFee, sats);

    require (vm.isCheckpoint (args.deposit.checkpoint),
             "vault checkpoint is invalid");
    require (isPoolSignatureValid (order.poolData.operator, args.deposit,
                                   args.signature),
             "pool signature of the vault check is invalid");
    /* The order creation already verifies that the pool asset matches
       the order's asset.  */

    CompleteSellDeposit memory deposit = getSellDeposit (args.deposit.vaultId);
    require (deposit.vaultId > 0, "sell deposit does not exist");
    require (keccak256 (abi.encodePacked (deposit.asset))
                == keccak256 (abi.encodePacked (order.asset)),
             "deposit asset mismatch");
    require (vm.hasAccountPermission (_msgSender (), deposit.owner),
             "no permission to act on behalf of the deposit owner");

    address buyerAddress = vm.getAccountAddress (order.buyer);
    require (buyerAddress == order.creator, "buyer name has been transferred");
    address poolAddress = vm.getAccountAddress (order.poolData.operator);

    require (wchi.transferFrom (buyerAddress, _msgSender (), sats),
             "WCHI transfer failed");
    require (wchi.transferFrom (buyerAddress, poolAddress, fee),
             "WCHI transfer failed");
    vm.sendFromVault (deposit.vaultId, order.poolData.operator,
                      args.amountSold);
    vm.sendFromVault (order.poolData.vaultId, order.buyer, args.amountSold);

    emit Trade (order.asset, args.amountSold, sats, deposit.owner, order.buyer);

    bool poolEmptied = (order.poolData.amount == args.amountSold);
    if (poolEmptied)
      {
        delete pools[order.poolData.vaultId];
        emit PoolRemoved (order.poolData.vaultId);
      }
    else
      {
        uint newRemaining = order.poolData.amount - args.amountSold;
        assert (newRemaining > 0);
        emit PoolUpdated (order.poolData.vaultId, newRemaining);
      }

    if (args.amountSold == order.remainingAmount || poolEmptied)
      {
        /* Note that if the pool was emptied (instead of the order fulfilled
           completely), we can still delete the order since there are no
           tokens or assets locked/reserved for buy orders.  */
        delete buyOrders[order.orderId];
        emit BuyOrderRemoved (order.orderId);
      }
    else
      {
        uint newRemaining = order.remainingAmount - args.amountSold;
        assert (newRemaining > 0);
        uint newSats = order.totalSats - sats;

        BuyOrder storage ptr = buyOrders[order.orderId];
        assert (ptr.poolId > 0);
        ptr.remainingAmount = newRemaining;
        ptr.totalSats = newSats;
        emit BuyOrderUpdated (order.orderId, newRemaining, newSats);
      }

    if (args.amountSold == deposit.amount)
      {
        delete sellDeposits[deposit.vaultId];
        emit SellDepositRemoved (deposit.vaultId);
      }
    else
      {
        uint newRemaining = deposit.amount - args.amountSold;
        assert (newRemaining > 0);
        emit SellDepositUpdated (deposit.vaultId, newRemaining);
      }
  }

  /**
   * @dev Accepts a batch of limit buy orders as per acceptBuyOrder.
   */
  function acceptBuyOrders (AcceptedBuyOrder[] calldata orders) public
  {
    for (uint i = 0; i < orders.length; ++i)
      acceptBuyOrder (orders[i]);
  }

  /* ************************************************************************ */

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@xaya/eth-account-registry/contracts/HexEscapes.sol";
import "@xaya/eth-account-registry/contracts/Utf8.sol";

/**
 * @dev A basic utility library for dealing with JSON (which we need for
 * handling moves).  In particular, it supports escaping user-provided
 * account names into JSON literals, so we can use them in moves to send
 * assets to those accounts.
 */
library JsonUtils
{

  /**
   * @dev Escapes a raw string into a JSON literal representing the same
   * string (including the surrounding quotes).  If the provided string is
   * invalid UTF-8, then this method will revert.
   */
  function escapeString (string memory input)
      internal pure returns (string memory)
  {
    bytes memory data = bytes (input);

    /* ASCII characters get translated literally (i.e. just copied over).
       We escape " and \ by placing a backslash before them, and change
       control characters as well as non-ASCII Unicode codepoints to \uXXXX.
       So worst case, if all are Unicode codepoints that need a
       UTF-16 surrogate pair, we 12x the length of the data, plus
       two quotes.  */
    bytes memory out = new bytes (2 + 12 * data.length);

    uint len = 0;
    out[len++] = '"';

    /* Note that one could in theory ignore the UTF-8 parsing here, and just
       literally copy over bytes 0x80 and above.  This would also produce a
       valid JSON result (or invalid JSON if the input is invalid), but it
       fails the XayaPolicy move validation, which requires all non-ASCII
       characters to be escaped in moves.  */

    uint offset = 0;
    while (offset < data.length)
      {
        uint32 cp;
        (cp, offset) = Utf8.decodeCodepoint (data, offset);
        if (cp == 0x22 || cp == 0x5C)
          {
            out[len++] = '\\';
            out[len++] = bytes1 (uint8 (cp));
          }
        else if (cp >= 0x20 && cp < 0x7F)
          out[len++] = bytes1 (uint8 (cp));
        else
          {
            bytes memory escape = bytes (HexEscapes.jsonCodepoint (cp));
            for (uint i = 0; i < escape.length; ++i)
              out[len++] = escape[i];
          }
      }
    assert (offset == data.length);

    out[len++] = '"';

    assembly {
      mstore (out, len)
    }

    return string (out);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

/**
 * @dev This interface defines the methods, that concrete applications
 * need to provide to configure Democrit.  It defines what assets
 * are tradable and how the move formats for creating, funding and
 * sending from vaults are.
 *
 * Vaults need to be implemented in the GSP with behaviour as described
 * in the design doc:
 *
 * https://docs.google.com/document/d/16B-vPKtpjbiCl6XCQaO2-7p8xN-2o5JveYJDHVCIxAw/edit?usp=sharing
 */
interface IDemocritConfig
{

  /**
   * @dev Returns the game ID of the application this is for.
   * The game ID is automatically added to all moves generated
   * by the other functions.
   */
  function gameId () external view returns (string memory);

  /**
   * @dev The denominator amount used for specifying the pool fee fraction.
   */
  function feeDenominator () external view returns (uint64);

  /**
   * @dev The maximum allowed relative fee for a trading pool.  This is
   * enforced on chain to prevent scams with very abusive fees.  The value
   * is relative to feeDenominator.
   */
  function maxRelPoolFee () external view returns (uint64);

  /**
   * @dev Checks if the given asset is tradable.
   */
  function isTradableAsset (string memory asset) external view returns (bool);

  /**
   * @dev Returns the move for creating a vault with the given data.
   * The move should be returned as formatted JSON string, and will be
   * wrapped into {"g":{"game id": ... }} by the caller.
   */
  function createVaultMove (string memory controller, uint vaultId,
                            string memory founder,
                            string memory asset, uint amount)
      external view returns (string memory);

  /**
   * @dev Returns the move for sending assets from a vault.  The move returned
   * must be a formatted JSON string, and will be wrapped into
   * {"g":{"game id": ... }} by the caller.
   */
  function sendFromVaultMove (string memory controller, uint vaultId,
                              string memory recipient,
                              string memory asset, uint amount)
      external view returns (string memory);

  /**
   * @dev Returns the move for requesting a checkpoint.  The returned move
   * should be a JSON string.  The caller will wrap it into
   * {"g":{"game id": ... }}.
   */
  function checkpointMove (string memory controller, uint num, bytes32 hash)
      external view returns (string memory);

  /**
   * @dev Returns the move for funding a vault, which is sent from the
   * founding user (not the controller) after a vault has been created.
   * This is sent through the delegation contract, so it should return
   * both the actual move and a hierarchical path for it.  The path
   * will be extended by ["g", "game id", ...] by the caller.
   */
  function fundVaultMove (string memory controller, uint vaultId,
                          string memory founder,
                          string memory asset, uint amount)
      external view returns (string[] memory, string memory);

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "./LimitBuying.sol";
import "./VaultManager.sol";

/**
 * @dev This is the main contract for the Democrit exchange.  Most of the
 * functionality is inherited from parent contracts already and just
 * consolidated here.
 *
 * The functions added explicitly in this contract are helpers for
 * retrieving some data, which e.g. frontends can utilise.  They are not
 * used in consensus-critical state changes.
 */
contract Democrit is LimitBuying
{

  constructor (VaultManager v)
    LimitBuying(v)
  {}

  /**
   * @dev The current status of a sell order.  This has some extra bits
   * of information (like whether or not the order even exists, and
   * is valid) in addition to the basic order details.
   */
  struct SellOrderStatus
  {

    /** @dev The order data itself.  */
    CompleteSellOrder order;

    /** @dev Whether or not the order exists.  */
    bool exists;

    /**
     * @dev Whether or not it is valid, e.g. the creator address matches
     * the current account owner.
     */
    bool valid;

  }

  /**
   * @dev Given an array of order IDs for sell orders, this function
   * checks each one of them to see if they are currently valid (e.g.
   * the creator address matches the current owner of the seller account),
   * exist, and returns all the data for it.  This is meant to be used
   * by a frontend to query the state of orders in batch before displaying
   * and using them.
   */
  function checkSellOrders (uint[] calldata orderIds)
      public view returns (SellOrderStatus[] memory res)
  {
    res = new SellOrderStatus[] (orderIds.length);
    for (uint i = 0; i < orderIds.length; ++i)
      {
        res[i].order = getSellOrder (orderIds[i]);
        res[i].exists = (res[i].order.orderId == orderIds[i]);
        if (res[i].exists)
          {
            address owner = vm.getAccountAddress (res[i].order.seller);
            res[i].valid = (res[i].order.creator == owner);
          }
      }
  }

  /**
   * @dev The current status of a buy order.  This has some extra information
   * added, based on linking it to other state like the WCHI balance of the
   * buyer or the state of the trading pool.
   */
  struct BuyOrderStatus
  {

    /** @dev The order data itself.  */
    CompleteBuyOrder order;

    /** @dev Whether or not the order exists.  */
    bool exists;

    /**
     * @dev Whether or not the order is valid, e.g. the creator address
     * matches the current account owner.
     */
    bool valid;

    /** @dev The current approved WCHI balance of the buyer.  */
    uint availableSats;

    /**
     * @dev The maximum amount of asset that can be bought, taking the
     * buyer's available WCHI balance and the pool balance into account.
     * Note that this only applies if this order alone is taken!  If multiple
     * orders are taken as a batch that use the same pool or are from the same
     * buyer, then the available amount may be lower.
     */
    uint maxBuy;

  }

  /**
   * @dev Computes the total cost in WCHI sats that a given buy, taking
   * pool fees into account, will be.
   */
  function getTotalBuyCost (uint remainingAmount, uint totalSats, uint64 relFee,
                            uint amountBought)
      public view returns (uint)
  {
    if (amountBought == 0)
      return 0;

    uint sats = getSatsForPurchase (remainingAmount, totalSats, amountBought);
    uint fee = getPoolFee (relFee, sats);
    return sats + fee;
  }

  /**
   * @dev Computes the maximum amount of asset that can be bought with
   * given WCHI, taking the pool fee into account as well.
   */
  function getMaxBuy (uint remainingAmount, uint totalSats, uint64 relFee,
                      uint availableSats)
      public view returns (uint)
  {
    /* Assuming exact math, the total cost for a given buy x is:

        cost = (x * totalSats / remainingAmount) * (1 + relFee / denom)

       Solving this for x yields:

        x = (remainingAmount / totalSats) * cost / (1 + relFee / denom)
          = (remainingAmount * cost * denom) / (totalSats * (denom + relFee))

       We use this formula to calculate the max buy first, plus add one unit to
       overestimate the real value for sure (since also the fee + cost
       calculations are rounding up).  Then we use a binary search between
       zero and that value to find the real maximal value.
    */

    if (totalSats == 0)
      return remainingAmount;
    if (getTotalBuyCost (remainingAmount, totalSats, relFee, remainingAmount)
          <= availableSats)
      return remainingAmount;

    uint denom = config.feeDenominator ();
    uint maxBuy = (remainingAmount * availableSats * denom)
                    / (totalSats * (denom + uint256 (relFee))) + 1;
    /* Note that here, maxBuy may actually be larger than remainingAmount
       due to the "+1".  But we verify at the end that the value returned
       from the function is below remainingAmount.  */

    assert (getTotalBuyCost (remainingAmount, totalSats, relFee, maxBuy)
              > availableSats);

    uint upper = maxBuy;
    uint lower = 0;

    while (upper > lower + 1)
      {
        uint mid = (upper + lower) / 2;
        uint cost = getTotalBuyCost (remainingAmount, totalSats, relFee, mid);
        if (cost > availableSats)
          upper = mid;
        else
          lower = mid;
      }

    assert (upper == lower + 1);
    assert (lower < remainingAmount);

    return lower;
  }

  /**
   * @dev Given an array of order IDs for buy orders, this function retrieves
   * the relevant data and also verifies some extra things, including computing
   * the maximum amount of asset that can be bought based on the buyer's
   * current WCHI balance and the pool's available balance.
   */
  function checkBuyOrders (uint[] calldata orderIds)
      public view returns (BuyOrderStatus[] memory res)
  {
    res = new BuyOrderStatus[] (orderIds.length);
    for (uint i = 0; i < orderIds.length; ++i)
      {
        res[i].order = getBuyOrder (orderIds[i]);
        res[i].exists = (res[i].order.orderId == orderIds[i]);
        if (!res[i].exists)
          continue;

        address owner = vm.getAccountAddress (res[i].order.buyer);
        res[i].valid = (res[i].order.creator == owner);

        uint balance = wchi.balanceOf (owner);
        uint approved = wchi.allowance (owner, address (this));
        if (balance > approved)
          balance = approved;
        res[i].availableSats = balance;

        uint maxBuy = getMaxBuy (res[i].order.remainingAmount,
                                 res[i].order.totalSats,
                                 res[i].order.poolData.relFee,
                                 balance);
        if (maxBuy > res[i].order.poolData.amount)
          maxBuy = res[i].order.poolData.amount;
        res[i].maxBuy = maxBuy;
      }
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@xaya/eth-account-registry/contracts/IXayaAccounts.sol";
import "@xaya/eth-delegator-contract/contracts/XayaDelegation.sol";

/**
 * @dev This defines a contract that owns a Xaya account and is able to send
 * moves with it.
 *
 * The account name must be created externally and transferred as ERC-721
 * to the contract.  Once this is done, the name will be locked forever
 * inside the contract.  This transfer will "initialise" the contract.
 */
contract AccountHolder is IERC721Receiver
{

  /** @dev The WCHI token used.  */
  IERC20Metadata public immutable wchi;

  /** @dev The XayaAccounts registry used.  */
  IXayaAccounts public immutable accountRegistry;

  /** @dev The move delegation contract used.  */
  XayaDelegation public immutable delegator;

  /** @dev Set to true when the contract is initialised.  */
  bool public initialised;

  /**
   * @dev The Xaya account name owned by this contract.  This is set on
   * initialisation, i.e. when a name gets transferred to the contract.
   */
  string public account;

  /**
   * @dev Emitted when the contract is initialised, i.e. its Xaya account
   * name gets specified.
   */
  event Initialised (string account);

  /** @dev Emitted whenever a move is sent with the contract's account.  */
  event Move (string mv);

  constructor (XayaDelegation del)
  {
    delegator = del;
    accountRegistry = del.accounts ();
    wchi = IERC20Metadata (address (accountRegistry.wchiToken ()));

    /* We approve WCHI on the accounts registry, to make sure that we can
       send moves that may require fees.  Note that it will be the
       responsibility of someone else to top up this contract's WCHI
       balance as needed to pay for those fees.  WCHI sent to the contract
       will only be spendable on fees, and not be recoverable in any other
       way!  */
    wchi.approve (address (accountRegistry), type (uint256).max);

    /* Also approve WCHI on the delegation contract, so that we can use it
       to send moves as well.  */
    wchi.approve (address (delegator), type (uint256).max);
  }

  /**
   * @dev We accept a single ERC-721 token transfer, of Xaya accounts (no
   * other tokens).  This initialises the contract.
   */
  function onERC721Received (address, address, uint256 tokenId, bytes calldata)
      external override returns (bytes4)
  {
    require (!initialised, "contract is already initialised");
    require (msg.sender == address (accountRegistry),
             "only Xaya names can be received");

    (string memory ns, string memory name)
        = accountRegistry.tokenIdToName (tokenId);
    bytes32 nsAccountHash = keccak256 (abi.encodePacked ("p"));
    require (keccak256 (abi.encodePacked (ns)) == nsAccountHash,
             "only Xaya accounts can be received");

    initialised = true; 
    account = name;
    emit Initialised (name);

    return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev Sends a Xaya move with the owned account.
   */
  function sendMove (string memory mv) internal
  {
    require (initialised, "contract is not initialised");
    accountRegistry.move ("p", account, mv, type (uint256).max, 0, address (0));
    emit Move (mv);
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
            require(denominator > prod1);

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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