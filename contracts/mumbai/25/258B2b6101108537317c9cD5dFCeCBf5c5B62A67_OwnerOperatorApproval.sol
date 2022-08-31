// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "Address.sol";
import "EnumerableSet.sol";
import "EnumerableUint256Set.sol";

/**
 * @title OwnerOperatorApproval
 *
 * @dev This library manages ownership of items, and allows an owner to delegate
 *     other addresses as their agent.
 * @dev It can be used to manage ownership of various types of tokens, such as
 *     ERC20, ERC677, ERC721, ERC777, and ERC1155.
 * @dev For coin-type tokens such as ERC20, ERC677, or ERC721, always pass `1`
 *     as `thing`. Comments that refer to the use of this library to manage
 *     these types of tokens will use the shorthand `COINS:`.
 * @dev For NFT-type tokens such as ERC721, always pass `1` as the `amount`.
 *     Comments that refer to the use of this library to manage these types of
 *     tokens will use the shorthand `NFTS:`.
 * @dev For semi-fungible tokens such as ERC1155, use `thing` as the token ID
 *     and `amount` as the number of tokens with that ID.
 */
library OwnerOperatorApproval {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    struct OwnerOperator {
        /*
         * For ERC20 / ERC777, there will only be one item
         */
        EnumerableUint256Set.Uint256Set allItems;
        EnumerableSet.AddressSet allOwners;
        /*
         * amount of each item
         * mapping(itemId => amount)
         * for ERC721, amount will be 1 or 0
         * for ERC20 / ERC777, there will only be one key
         */
        mapping(uint256 => uint256) totalSupply;
        /*
        // which items are owned by which owners?
        // for ERC20 / ERC777, the result will have 0 or 1 elements
         */
        mapping(address => EnumerableUint256Set.Uint256Set) itemIdsByOwner;
        /*
        // which owners hold which items?
        // For ERC20 / ERC777, there will only be 1 key
        // For ERC721, result will have 0 or 1 elements
         */
        mapping(uint256 => EnumerableSet.AddressSet) ownersByItemIds;
        /*
        // for a given item id, what is the address's balance?
        // mapping(itemId => mapping(owner => amount))
        // for ERC20 / ERC777, there will only be 1 key
        // for ERC721, result is 1 or 0
         */
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(uint256 => address)) itemApprovals;
        /*
        // for a given owner, how much of each item id is an operator allowed to control?
         */
        mapping(address => mapping(uint256 => mapping(address => uint256))) allowances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    /**
     * @dev revert if the item does not exist
     */
    modifier itemExists(OwnerOperator storage oo, uint256 thing) {
        require(_exists(oo, thing), "invalid item");
        _;
    }

    /**
     * @dev revert if the user is the null address
     */
    modifier validUser(OwnerOperator storage oo, address user) {
        require(user != address(0), "invalid user");
        _;
    }

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(OwnerOperator storage oo, uint256 thing)
        public
        view
        itemExists(oo, thing)
    {}

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount(OwnerOperator storage oo)
        external
        view
        returns (uint256)
    {
        return oo.allOwners.length();
    }

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(OwnerOperator storage oo, uint256 index)
        external
        view
        returns (address)
    {
        require(oo.allOwners.length() > index, "owner index out of bounds");
        return oo.allOwners.at(index);
    }

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(OwnerOperator storage oo, uint256 thing)
        external
        view
        returns (bool)
    {
        return _exists(oo, thing);
    }

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount(OwnerOperator storage oo)
        external
        view
        returns (uint256)
    {
        return oo.allItems.length();
    }

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(OwnerOperator storage oo, uint256 index)
        external
        view
        returns (uint256)
    {
        require(oo.allItems.length() > index, "item index out of bounds");
        return oo.allItems.at(index);
    }

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(OwnerOperator storage oo, uint256 thing)
        external
        view
        returns (uint256)
    {
        return oo.totalSupply[thing];
    }

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(OwnerOperator storage oo, address owner)
        external
        view
        validUser(oo, owner)
        returns (uint256)
    {
        return oo.itemIdsByOwner[owner].length();
    }

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(
        OwnerOperator storage oo,
        address owner,
        uint256 index
    ) external view validUser(oo, owner) returns (uint256) {
        require(
            oo.itemIdsByOwner[owner].length() > index,
            "item index out of bounds"
        );
        return oo.itemIdsByOwner[owner].at(index);
    }

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(OwnerOperator storage oo, uint256 thing)
        external
        view
        itemExists(oo, thing)
        returns (uint256)
    {
        return oo.ownersByItemIds[thing].length();
    }

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(
        OwnerOperator storage oo,
        uint256 thing,
        uint256 index
    ) external view itemExists(oo, thing) returns (address owner) {
        require(
            oo.ownersByItemIds[thing].length() > index,
            "owner index out of bounds"
        );
        return oo.ownersByItemIds[thing].at(index);
    }

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function balance(
        OwnerOperator storage oo,
        address owner,
        uint256 thing
    )
        external
        view
        validUser(oo, owner)
        itemExists(oo, thing)
        returns (uint256)
    {
        return oo.balances[thing][owner];
    }

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(OwnerOperator storage oo, address user)
        external
        view
        validUser(oo, user)
        returns (uint256[] memory)
    {
        return oo.itemIdsByOwner[user].asList();
    }

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view {
        require(
            oo.balances[thing][fromAddress] >= amount &&
                _checkApproval(oo, operator, fromAddress, thing, amount),
            "not authorized"
        );
    }

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view returns (bool) {
        return _checkApproval(oo, operator, fromAddress, thing, amount);
    }

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) external {
        // can't mint and burn in same transaction
        require(
            fromAddress != address(0) || toAddress != address(0),
            "invalid transfer"
        );

        // can't transfer nothing
        require(amount > 0, "invalid transfer");

        if (fromAddress == address(0)) {
            // minting
            oo.allItems.add(thing);
            oo.totalSupply[thing] += amount;
        } else {
            enforceItemExists(oo, thing);
            if (operator != fromAddress) {
                require(
                    _checkApproval(oo, operator, fromAddress, thing, amount),
                    "not authorized"
                );
                if (oo.allowances[fromAddress][thing][operator] > 0) {
                    oo.allowances[fromAddress][thing][operator] -= amount;
                }
            }
            require(
                oo.balances[thing][fromAddress] >= amount,
                "insufficient balance"
            );

            oo.itemApprovals[fromAddress][thing] = address(0);

            if (fromAddress == toAddress) return;

            oo.balances[thing][fromAddress] -= amount;
            if (oo.balances[thing][fromAddress] == 0) {
                oo.allOwners.remove(fromAddress);
                oo.ownersByItemIds[thing].remove(fromAddress);
                oo.itemIdsByOwner[fromAddress].remove(thing);
                if (oo.itemIdsByOwner[fromAddress].length() == 0) {
                    delete oo.itemIdsByOwner[fromAddress];
                }
            }
        }

        if (toAddress == address(0)) {
            // burning
            oo.totalSupply[thing] -= amount;
            if (oo.totalSupply[thing] == 0) {
                oo.allItems.remove(thing);
                delete oo.ownersByItemIds[thing];
            }
        } else {
            oo.allOwners.add(toAddress);
            oo.itemIdsByOwner[toAddress].add(thing);
            oo.ownersByItemIds[thing].add(toAddress);
            oo.balances[thing][toAddress] += amount;
        }
    }

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(
        OwnerOperator storage oo,
        address fromAddress,
        address operator
    ) external view returns (bool) {
        return oo.operatorApprovals[fromAddress][operator];
    }

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        bool approved
    ) external validUser(oo, fromAddress) validUser(oo, operator) {
        require(operator != fromAddress, "approval to self");
        oo.operatorApprovals[fromAddress][operator] = approved;
    }

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing
    ) external view returns (uint256) {
        return oo.allowances[fromAddress][thing][operator];
    }

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) external validUser(oo, fromAddress) validUser(oo, operator) {
        require(operator != fromAddress, "approval to self");
        oo.allowances[fromAddress][thing][operator] = amount;
    }

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(
        OwnerOperator storage oo,
        address fromAddress,
        uint256 thing
    ) external view returns (address) {
        require(oo.totalSupply[thing] > 0);
        return oo.itemApprovals[fromAddress][thing];
    }

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        OwnerOperator storage oo,
        address fromAddress,
        address operator,
        uint256 thing
    ) external validUser(oo, fromAddress) {
        require(operator != fromAddress, "approval to self");
        require(oo.ownersByItemIds[thing].contains(fromAddress));
        oo.itemApprovals[fromAddress][thing] = operator;
    }

    function _exists(OwnerOperator storage oo, uint256 thing)
        internal
        view
        returns (bool)
    {
        return oo.totalSupply[thing] > 0;
    }

    function _checkApproval(
        OwnerOperator storage oo,
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) internal view returns (bool) {
        return (operator == fromAddress ||
            oo.operatorApprovals[fromAddress][operator] ||
            oo.itemApprovals[fromAddress][thing] == operator ||
            oo.allowances[fromAddress][thing][operator] >= amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
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
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
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
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }
}