/**
 *Submitted for verification at polygonscan.com on 2022-11-05
*/

// File: contracts/JsonSubObject.sol

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

// File: contracts/MovePermissions.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: contracts/NamePermissions.sol

// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;



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

// File: @openzeppelin/contracts/metatx/ERC2771Context.sol

// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @xaya/eth-account-registry/contracts/IXayaPolicy.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @xaya/eth-account-registry/contracts/IXayaAccounts.sol

// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;




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

// File: contracts/XayaDelegation.sol

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Autonomous Worlds Ltd

pragma solidity ^0.8.13;







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