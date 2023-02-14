// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BentureProducedToken.sol";
import "./interfaces/IBenture.sol";
import "./interfaces/IBentureProducedToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Dividends distributing contract
contract Benture is IBenture, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeERC20 for IBentureProducedToken;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Pool to lock tokens
    /// @dev `lockers` and `lockersArray` basically store the same list of addresses
    ///       but they are used for different purposes
    struct Pool {
        // The address of the token inside the pool
        address token;
        // The list of all lockers of the pool
        EnumerableSet.AddressSet lockers;
        // The amount of locked tokens
        uint256 totalLocked;
        // Mapping from user address to the amount of tokens currently locked by the user in the pool
        // Could be 0 if user has unlocked all his tokens
        mapping(address => uint256) lockedByUser;
        // Mapping from user address to distribution ID to locked tokens amount
        // Shows "to what amount was the user's locked changed before the distribution with the given ID"
        // If the value for ID10 is 0, that means that user's lock amount did not change before that distribution
        // If the value for ID10 is 500, that means that user's lock amount changed to 500 before that distibution.
        // Amounts locked for N-th distribution (used to calculate user's dividends) can only
        // be updated since the start of (N-1)-th distribution and till the start of the N-th
        // distribution. `distributionIds.current()` is the (N-1)-th distribution in our case.
        // So we have to increase it by one to get the ID of the upcoming distribution and
        // the amount locked for that distribution.
        // For example, if distribution ID476 has started and Bob adds 100 tokens to his 500 locked tokens
        // the pool, then his lock for the distribution ID477 should be 600.
        mapping(address => mapping(uint256 => uint256)) lockHistory;
        // Mapping from user address to a list of IDs of distributions *before which* user's lock amount was changed
        // For example an array of [1, 2] means that user's lock amount changed before 1st and 2nd distributions
        // `EnumerableSet` can't be used here because it does not *preserve* the order of IDs and we need that
        mapping(address => uint256[]) lockChangesIds;
        // Mapping indicating that before the distribution with the given ID, user's lock amount was changed
        // Basically, a `true` value for `[user][ID]` here means that this ID is *in* the `lockChangesIds[user]` array
        // So it's used to check if a given ID is in the array.
        mapping(address => mapping(uint256 => bool)) changedBeforeId;
    }

    /// @dev Stores information about a specific dividends distribution
    struct Distribution {
        // ID of distributiion
        uint256 id;
        // The token owned by holders
        address origToken;
        // The token distributed to holders
        address distToken;
        // The amount of `distTokens` or native tokens paid to holders
        uint256 amount;
        // True if distribution is equal, false if it's weighted
        bool isEqual;
        // Mapping showing that holder has withdrawn his dividends
        mapping(address => bool) hasClaimed;
        // Copies the length of `lockers` set from the pool
        uint256 formulaLockers;
        // Copies the value of Pool.totalLocked when creating a distribution
        uint256 formulaLocked;
    }

    /// @notice Address of the factory used for projects creation
    address public factory;

    /// @dev All pools
    mapping(address => Pool) private pools;

    /// @dev Incrementing IDs of distributions
    Counters.Counter internal distributionIds;
    /// @dev Mapping from distribution ID to the address of the admin
    ///      who started the distribution
    mapping(uint256 => address) internal distributionsToAdmins;
    /// @dev Mapping from admin address to the list of IDs of active distributions he started
    mapping(address => uint256[]) internal adminsToDistributions;
    /// @dev Mapping from distribution ID to the distribution
    mapping(uint256 => Distribution) private distributions;

    /// @dev Checks that caller is either an admin of a project or a factory
    modifier onlyAdminOrFactory(address token) {
        // Check if token has a zero address. If so, there is no way to
        // verify that caller is admin because it's impossible to
        // call verification method on zero address
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }
        // If factory address is zero, that means that it hasn't been set
        if (factory == address(0)) {
            revert FactoryAddressNotSet();
        }
        // If caller is neither a factory nor an admin - revert
        if (
            !(msg.sender == factory) &&
            !(IBentureProducedToken(token).checkAdmin(msg.sender))
        ) {
            revert CallerNotAdminOrFactory();
        }
        _;
    }

    /// @dev The contract must be able to receive ether to pay dividends with it
    receive() external payable {}

    // ===== POOLS =====

    /// @notice Creates a new pool
    /// @param token The token that will be locked in the pool
    function createPool(address token) external onlyAdminOrFactory(token) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }

        emit PoolCreated(token);

        Pool storage newPool = pools[token];
        // Check that this pool has not yet been initialized with the token
        // There can't multiple pools of the same token
        if (newPool.token == token) {
            revert PoolAlreadyExists();
        }
        newPool.token = token;
        // Other fields are initialized with default values
    }

    /// @notice Locks the provided amount of user's tokens in the pool
    /// @param origToken The address of the token to lock
    /// @param amount The amount of tokens to lock
    function lockTokens(address origToken, uint256 amount) public {
        if (amount == 0) {
            revert InvalidLockAmount();
        }
        // Token must have npn-zero address
        if (origToken == address(0)) {
            revert InvalidTokenAddress();
        }

        Pool storage pool = pools[origToken];
        // Check that a pool to lock tokens exists
        if (pool.token == address(0)) {
            revert PoolDoesNotExist();
        }
        // Check that pool holds the same token. Just in case
        if (pool.token != origToken) {
            revert WrongTokenInsideThePool();
        }
        // User should have origTokens to be able to lock them
        if (!IBentureProducedToken(origToken).isHolder(msg.sender)) {
            revert UserDoesNotHaveProjectTokens();
        }

        // If user has never locked tokens, add him to the lockers list
        if (!isLocker(pool.token, msg.sender)) {
            pool.lockers.add(msg.sender);
        }
        // Increase the total amount of locked tokens
        pool.totalLocked += amount;

        // Get user's current lock, increase it and copy to the history
        pool.lockedByUser[msg.sender] += amount;
        pool.lockHistory[msg.sender][distributionIds.current() + 1] = pool
            .lockedByUser[msg.sender];

        // Mark that the lock amount was changed before the next distribution
        // Avoid duplicates by checking the presence of the ID in the array
        if (!pool.changedBeforeId[msg.sender][distributionIds.current() + 1]) {
            pool.lockChangesIds[msg.sender].push(distributionIds.current() + 1);
        }
        // Mark that current ID is in the array now
        pool.changedBeforeId[msg.sender][distributionIds.current() + 1] = true;

        emit TokensLocked(msg.sender, origToken, amount);

        // NOTE: User must approve transfer of at least `amount` of tokens
        //       before calling this function
        // Transfer tokens from user to the contract
        IBentureProducedToken(origToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /// @notice Locks all user's tokens in the pool
    /// @param origToken The address of the token to lock
    function lockAllTokens(address origToken) public {
        uint256 wholeBalance = IBentureProducedToken(origToken).balanceOf(
            msg.sender
        );
        lockTokens(origToken, wholeBalance);
    }

    /// @notice Shows which distributions the user took part in and hasn't claimed them
    /// @param user The address of the user to get distributions for
    /// @param token The address of the token that was distributed
    /// @return The list of IDs of distributions the user took part in
    function getParticipatedNotClaimed(
        address user,
        address token
    ) private view returns (uint256[] memory) {
        Pool storage pool = pools[token];
        // Get the list of distributions before which user's lock was changed
        uint256[] memory allIds = pool.lockChangesIds[user];
        // If the last distribution has not started yet - delete it
        // User couldn't take part in it
        if (allIds[allIds.length - 1] > distributionIds.current()) {
            // If there is only one distribution before which user has locked his tokens
            // and it has not started yet - delete it, return empty array
            if (allIds.length == 1) {
                return new uint256[](0);
            }
            uint256[] memory temp = new uint256[](allIds.length - 1);
            for (uint256 i = 0; i < temp.length; i++) {
                temp[i] = allIds[i];
            }
            allIds = temp;
        }

        // If there is only one such distribution that means that
        // this was only one distribution in total and it has started
        // Check that he hasn't claimed it and if so - return
        if (allIds.length == 1) {
            if (!distributions[allIds[0]].hasClaimed[user]) {
                return allIds;
            } else {
                // Else return an empty array
                return new uint256[](0);
            }
        }

        // If there are more than 1 IDs in the array, that means that at least
        // one distribution has started

        // Get the history of user's lock amount changes
        mapping(uint256 => uint256) storage amounts = pool.lockHistory[user];

        // First iteration: just *count* the amount of distributions the user took part in
        // Left and right borders of search

        uint256 counter;
        // If the first ID wasn't claimed, add it to the list and increase the counter
        if (hasClaimed(allIds[0], user)) {
            counter = 0;
        } else {
            counter = 1;
        }
        for (uint256 i = 1; i < allIds.length; i++) {
            if (amounts[allIds[i]] != 0) {
                if (amounts[allIds[i - 1]] != 0) {
                    // If lock for the ID is not 0 and for previous ID it's not 0 as well
                    // than means that user took part in all IDs between these two
                    for (
                        uint256 j = allIds[i - 1] + 1;
                        j < allIds[i] + 1;
                        j++
                    ) {
                        if (!hasClaimed(j, user)) {
                            counter++;
                        }
                    }
                } else {
                    // If lock for the ID is not 0, but for the previous ID it is 0, that means
                    // that user increased his lock to non-zero only now, so he didn't take part in
                    // any previous IDs
                    if (!hasClaimed(allIds[i], user)) {
                        counter++;
                    }
                }
            } else {
                if (amounts[allIds[i - 1]] != 0) {
                    // If lock for the ID is 0 and is not 0 for the previous ID, that means that
                    // user has unlocked all his tokens and didn't take part in the ID
                    for (uint256 j = allIds[i - 1] + 1; j < allIds[i]; j++) {
                        if (!hasClaimed(j, user)) {
                            counter++;
                        }
                    }
                }
            }
        }

        if (amounts[allIds[allIds.length - 1]] != 0) {
            // If lock for the last ID isn't zero, that means that the user still has lock
            // in the pool till this moment and he took part in all IDs since then
            for (
                uint256 j = allIds[allIds.length - 1] + 1;
                j < distributionIds.current() + 1;
                j++
            ) {
                if (!hasClaimed(j, user)) {
                    counter++;
                }
            }
        }

        uint256[] memory tookPart = new uint256[](counter);

        // Second iteration: actually fill the array

        if (hasClaimed(allIds[0], user)) {
            counter = 0;
        } else {
            counter = 1;
            tookPart[0] = allIds[0];
        }
        for (uint256 i = 1; i < allIds.length; i++) {
            if (amounts[allIds[i]] != 0) {
                if (amounts[allIds[i - 1]] != 0) {
                    for (
                        uint256 j = allIds[i - 1] + 1;
                        j < allIds[i] + 1;
                        j++
                    ) {
                        if (!hasClaimed(j, user)) {
                            tookPart[counter] = j;
                            counter++;
                        }
                    }
                } else {
                    if (!hasClaimed(allIds[i], user)) {
                        tookPart[counter] = allIds[i];
                        counter++;
                    }
                }
            } else {
                if (amounts[allIds[i - 1]] != 0) {
                    for (uint256 j = allIds[i - 1] + 1; j < allIds[i]; j++) {
                        if (!hasClaimed(j, user)) {
                            tookPart[counter] = j;
                            counter++;
                        }
                    }
                }
            }
        }

        if (amounts[allIds[allIds.length - 1]] != 0) {
            for (
                uint256 j = allIds[allIds.length - 1] + 1;
                j < distributionIds.current() + 1;
                j++
            ) {
                if (!hasClaimed(j, user)) {
                    tookPart[counter] = j;
                    counter++;
                }
            }
        }
        return tookPart;
    }

    /// @notice Unlocks the provided amount of user's tokens from the pool
    /// @param origToken The address of the token to unlock
    /// @param amount The amount of tokens to unlock
    function unlockTokens(
        address origToken,
        uint256 amount
    ) external nonReentrant {
        _unlockTokens(origToken, amount);
    }

    /// @notice Unlocks the provided amount of user's tokens from the pool
    /// @param origToken The address of the token to unlock
    /// @param amount The amount of tokens to unlock
    function _unlockTokens(address origToken, uint256 amount) private {
        if (amount == 0) {
            revert InvalidUnlockAmount();
        }
        // Token must have npn-zero address
        if (origToken == address(0)) {
            revert InvalidTokenAddress();
        }

        Pool storage pool = pools[origToken];
        // Check that a pool to lock tokens exists
        if (pool.token == address(0)) {
            revert PoolDoesNotExist();
        }
        // Check that pool holds the same token. Just in case
        if (pool.token != origToken) {
            revert WrongTokenInsideThePool();
        }
        // Make sure that user has locked some tokens before
        if (!isLocker(pool.token, msg.sender)) {
            revert NoLockedTokens();
        }

        // Make sure that user is trying to withdraw no more tokens than he has locked for now
        if (pool.lockedByUser[msg.sender] < amount) {
            revert WithdrawTooBig();
        }

        // Any unlock triggers claim of all dividends inside the pool for that user

        // Get the list of distributions the user took part in and hasn't claimed them
        uint256[] memory notClaimedIds = getParticipatedNotClaimed(
            msg.sender,
            origToken
        );


        // Now claim all dividends of these distributions
        _claimMultipleDividends(notClaimedIds);

        // Decrease the total amount of locked tokens in the pool
        pool.totalLocked -= amount;

        // Get the current user's lock, decrease it and copy to the history
        pool.lockedByUser[msg.sender] -= amount;
        pool.lockHistory[msg.sender][distributionIds.current() + 1] = pool
            .lockedByUser[msg.sender];

        // Mark that the lock amount was changed before the next distribution
        // Avoid duplicates by checking the presence of the ID in the array
        if (!pool.changedBeforeId[msg.sender][distributionIds.current() + 1]) {
            pool.lockChangesIds[msg.sender].push(distributionIds.current() + 1);
        }
        // Mark that current ID is in the array now
        pool.changedBeforeId[msg.sender][distributionIds.current() + 1] = true;

        // If all tokens were unlocked - delete user from lockers list
        if (pool.lockedByUser[msg.sender] == 0) {
            // Delete it from the set as well
            pool.lockers.remove(msg.sender);
        }

        emit TokensUnlocked(msg.sender, origToken, amount);

        // Transfer unlocked tokens from contract to the user
        IBentureProducedToken(origToken).safeTransfer(msg.sender, amount);
    }

    /// @notice Unlocks all locked tokens of the user in the pool
    /// @param origToken The address of the token to unlock
    function unlockAllTokens(address origToken) public {
        // Get the last lock of the user
        uint256 wholeBalance = pools[origToken].lockedByUser[msg.sender];
        // Unlock that amount (could be 0)
        _unlockTokens(origToken, wholeBalance);
    }

    // ===== DISTRIBUTIONS =====

    /// @notice Allows admin to distribute dividends among lockers
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    ///        Use zero address for native tokens
    /// @param amount The amount of ERC20 tokens that will be paid
    /// @param isEqual Indicates whether distribution will be equal
    function distributeDividends(
        address origToken,
        address distToken,
        uint256 amount,
        bool isEqual
    ) external payable nonReentrant {
        if (origToken == address(0)) {
            revert InvalidTokenAddress();
        }
        // Check that caller is an admin of `origToken`
        if (!IBentureProducedToken(origToken).checkAdmin(msg.sender)) {
            revert UserDoesNotHaveAnAdminToken();
        }
        // Amount can not be zero
        if (amount == 0) {
            revert InvalidDividendsAmount();
        }
        if (distToken != address(0)) {
            // NOTE: Caller should approve transfer of at least `amount` of tokens with `ERC20.approve()`
            // before calling this function
            // Transfer tokens from admin to the contract
            IERC20(distToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        } else {
            // Check that enough native tokens were provided
            if (msg.value < amount) {
                revert NotEnoughNativeTokens();
            }
        }

        emit DividendsStarted(origToken, distToken, amount, isEqual);

        distributionIds.increment();
        // NOTE The lowest distribution ID is 1
        uint256 distributionId = distributionIds.current();
        // Mark that this admin started a distribution with the new ID
        distributionsToAdmins[distributionId] = msg.sender;
        adminsToDistributions[msg.sender].push(distributionId);
        // Create a new distribution
        Distribution storage newDistribution = distributions[distributionId];
        newDistribution.id = distributionId;
        newDistribution.origToken = origToken;
        newDistribution.distToken = distToken;
        newDistribution.amount = amount;
        newDistribution.isEqual = isEqual;
        // `hasClaimed` is initialized with default value
        newDistribution.formulaLockers = pools[origToken].lockers.length();
        newDistribution.formulaLocked = pools[origToken].totalLocked;
    }

    /// @dev Searches for the distribution that has an ID less than the `id`
    ///      but greater than all other IDs less than `id` and before which user's
    ///      lock amount was changed the last time. Returns the ID of that distribution
    ///      or (-1) if no such ID exists.
    ///      Performs a binary search.
    /// @param user The user to find a previous distribution for
    /// @param id The ID of the distribution to find a previous distribution for
    /// @return The ID of the found distribution. Or (-1) if no such distribution exists
    function findMaxPrev(
        address user,
        uint256 id
    ) internal view returns (int256) {
        address origToken = distributions[id].origToken;

        uint256[] storage ids = pools[origToken].lockChangesIds[user];

        // If the array is empty, there can't be a correct ID we're looking for in it
        if (ids.length == 0) {
            return -1;
        }

        // Start binary search
        uint256 low = 0;
        uint256 high = pools[origToken].lockChangesIds[user].length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (pools[origToken].lockChangesIds[user][mid] > id) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // After this loop `low` is the array index of the ID that is *greater* than the `id`.
        // (and we're looking for the one that is *less* than the `id`)

        // IDs are sorted in the ascending order.
        // If `low` is 0, that means that the first ID in the array is
        //    greater than the `id`. Thus there are no any IDs in the array that may be *less* than the `id`
        if (low == 0) {
            return -1;
        }

        // If the array actually contains the `id` at index N, that means that a greater value is located at the
        // N + 1 index in the array (which is `low`) and the *smaller* value is located at the N - 1
        // index in the array (which is `low - 2`)
        if (pools[origToken].changedBeforeId[user][id]) {
            // If `low` is 1, that means that the `id` is the first element of the array (index 0).
            // Thus there are no any IDs in the array that may be *less* then `id`
            if (low == 1) {
                return -1;
            }
            // If `low` is greater then 1, that means that there can be elements of the array at indexes
            // of `low - 2` that are less than the `id`
            return int256(ids[low - 2]);
            // If the array does not contain the `id` at index N (that is also possible if user's lock was not changed before that `id`),
            // that means that a greater value is located at the N + 1 index in the array (which is `low`) and the *smaller* value is located
            // at the *N* index in the array (which is `low - 1`)
            // The lowest possible value of `low` here is 1. 0 is excluded by one of the conditions above
        } else {
            return int256(ids[low - 1]);
        }
    }

    /// @notice Calculates locker's share in the distribution
    /// @param id The ID of the distribution to calculates shares in
    /// @param user The address of the user whos share has to be calculated
    function calculateShare(
        uint256 id,
        address user
    ) internal view returns (uint256) {
        Distribution storage distribution = distributions[id];
        Pool storage pool = pools[distribution.origToken];

        uint256 share;

        // Calculate shares if equal distribution
        if (distribution.isEqual) {
            // NOTE: result gets rounded towards zero
            // If the `amount` is less than `formulaLockers` then share is 0
            share = distribution.amount / distribution.formulaLockers;
            // Calculate shares in weighted distribution
        } else {
            // Get the amount locked by the user before the given distribution
            uint256 lock = pool.lockHistory[user][id];

            // If lock is zero, that means:
            // 1) The user has unlocked all his tokens before the given distribution
            // OR
            // 2) The user hasn't called either lock or unlock functions before the given distribution
            //    and because of that his locked amount was not updated in the mapping
            // So we have to determine which option is the right one
            if (lock == 0) {
                // Check if user has changed his lock amount before the distribution
                if (pool.changedBeforeId[user][id]) {
                    // If he did, and his current lock is 0, that means that he has unlocked all his tokens and 0 is a correct lock amount
                    lock = 0;
                } else {
                    // If he didn't, that means that *we have to use his lock from the closest distribution from the past*
                    // We have to find a distribution that has an ID that is less than `id` but greater than all other
                    // IDs less than `id`
                    int256 prevMaxId = findMaxPrev(user, id);
                    if (prevMaxId != -1) {
                        lock = pool.lockHistory[user][uint256(prevMaxId)];
                    } else {
                        // If no such an ID exists (i.e. there were no distributions before the current one that had non-zero locks before them)
                        // that means that a user has *locked and unlocked* his tokens before the very first distribution. In this case 0 is a correct lock amount
                        lock = 0;
                    }
                }
            }

            share = (distribution.amount * lock) / distribution.formulaLocked;
        }

        return share;
    }

    /// @notice Allows a user to claim dividends from a single distribution
    /// @param id The ID of the distribution to claim
    function claimDividends(uint256 id) external nonReentrant {
        _claimDividends(id);
    }

    function _claimDividends(uint256 id) private {
        // Can't claim a distribution that has not started yet
        if (id > distributionIds.current()) {
            revert DistributionHasNotStartedYet();
        }

        Distribution storage distribution = distributions[id];

        // User must be a locker of the `origToken` of the distribution he's trying to claim
        if (!isLocker(distribution.origToken, msg.sender)) {
            revert UserDoesNotHaveLockedTokens();
        }

        // User can't claim the same distribution more than once
        if (distribution.hasClaimed[msg.sender]) {
            revert AlreadyClaimed();
        }

        // Calculate the share of the user
        uint256 share = calculateShare(id, msg.sender);

        // If user's share is 0, that means he doesn't have any locked tokens
        if (share == 0) {
            revert UserDoesNotHaveLockedTokens();
        }

        emit DividendsClaimed(id, msg.sender);

        distribution.hasClaimed[msg.sender] = true;

        // Send the share to the user
        if (distribution.distToken == address(0)) {
            // Send native tokens
            (bool success, ) = msg.sender.call{value: share}("");
            if (!success) {
                revert NativeTokenTransferFailed();
            }
        } else {
            // Send ERC20 tokens
            IERC20(distribution.distToken).safeTransfer(msg.sender, share);
        }
    }

    /// @notice Allows user to claim dividends from multiple distributions
    ///         WARNING: Potentially can exceed block gas limit!
    /// @param ids The array of IDs of distributions to claim
    function claimMultipleDividends(
        uint256[] memory ids
    ) external nonReentrant {
        _claimMultipleDividends(ids);
    }

    function _claimMultipleDividends(uint256[] memory ids) private {
        // Only 2/3 of block gas limit could be spent. So 1/3 should be left.
        uint256 gasThreshold = (block.gaslimit * 1) / 3;

        uint256 count;

        for (uint i = 0; i < ids.length; i++) {
            _claimDividends(ids[i]);
            // Increase the number of users who received their shares
            count++;
            // Check that no more than 2/3 of block gas limit was spent
            if (gasleft() <= gasThreshold) {
                break;
            }
        }

        emit MultipleDividendsClaimed(msg.sender, count);
    }

    /// @notice Allows admin to distribute provided amounts of tokens to the provided list of users
    /// @param token The address of the token to be distributed
    /// @param users The list of addresses of users to receive tokens
    /// @param amounts The list of amounts each user has to receive
    /// @param totalAmount The total amount of `token`s to be distributed. Sum of `amounts` array.
    function distributeDividendsCustom(
        address token,
        address[] calldata users,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) public payable nonReentrant {
        // Lists can't be empty
        if ((users.length == 0) || (amounts.length == 0)) {
            revert EmptyList();
        }
        // Lists length should be the same
        if (users.length != amounts.length) {
            revert ListsLengthDiffers();
        }
        // If dividends are to be paid in native tokens, check that enough native tokens were provided
        if ((token == address(0)) && (msg.value < totalAmount)) {
            revert NotEnoughNativeTokens();
        }
        // If dividends are to be paid in ERC20 tokens, transfer ERC20 tokens from caller
        // to this contract first
        // NOTE: Caller must approve transfer of at least `totalAmount` of tokens to this contract
        if (token != address(0)) {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                totalAmount
            );
        }

        // Only 2/3 of block gas limit could be spent. So 1/3 should be left.
        uint256 gasThreshold = (block.gaslimit * 1) / 3;

        uint256 count;

        // Distribute dividends to each of the holders
        for (uint256 i = 0; i < users.length; i++) {
            // Users cannot have zero addresses
            if (users[i] == address(0)) {
                revert InvalidUserAddress();
            }
            // Amount for any user cannot be 0
            if (amounts[i] == 0) {
                revert InvalidDividendsAmount();
            }
            if (token == address(0)) {
                // Native tokens (wei)
                (bool success, ) = users[i].call{value: amounts[i]}("");
                if (!success) {
                    revert TransferFailed();
                }
            } else {
                // Other ERC20 tokens
                IERC20(token).safeTransfer(users[i], amounts[i]);
            }
            // Increase the number of users who received their shares
            count++;
            // Check that no more than 2/3 of block gas limit was spent
            if (gasleft() <= gasThreshold) {
                break;
            }
        }

        emit CustomDividendsDistributed(token, count);
    }

    /// @notice Sets the token factory contract address
    /// @param factoryAddress The address of the factory
    /// @dev NOTICE: This address can't be set the constructor because
    ///      `Benture` is deployed *before* factory contract.
    function setFactoryAddress(address factoryAddress) external onlyOwner {
        if (factoryAddress == address(0)) {
            revert InvalidFactoryAddress();
        }
        factory = factoryAddress;
    }

    // ===== GETTERS =====

    /// @notice Returns info about the pool of a given token
    /// @param token The address of the token of the pool
    /// @return The address of the tokens in the pool.
    /// @return The number of users who locked their tokens in the pool
    /// @return The amount of locked tokens
    function getPool(
        address token
    ) public view returns (address, uint256, uint256) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }

        Pool storage pool = pools[token];
        return (pool.token, pool.lockers.length(), pool.totalLocked);
    }

    /// @notice Returns the array of lockers of the pool
    /// @param token The address of the token of the pool
    /// @return The array of lockers of the pool
    function getLockers(address token) public view returns (address[] memory) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }

        return pools[token].lockers.values();
    }

    /// @notice Checks if user is a locker of the provided token pool
    /// @param token The address of the token of the pool
    /// @param user The address of the user to check
    /// @return True if user is a locker in the pool. Otherwise - false.
    function isLocker(address token, address user) public view returns (bool) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }

        if (user == address(0)) {
            revert InvalidUserAddress();
        }
        // User is a locker if his lock is not a zero and he is in the lockers list
        return
            (pools[token].lockedByUser[user] != 0) &&
            (pools[token].lockers.contains(user));
    }

    /// @notice Returns the current lock amount of the user
    /// @param token The address of the token of the pool
    /// @param user The address of the user to check
    /// @return The current lock amount
    function getCurrentLock(
        address token,
        address user
    ) public view returns (uint256) {
        if (token == address(0)) {
            revert InvalidTokenAddress();
        }
        if (user == address(0)) {
            revert InvalidUserAddress();
        }
        return pools[token].lockedByUser[user];
    }

    /// @notice Returns the list of IDs of all distributions the admin has ever started
    /// @param admin The address of the admin
    /// @return The list of IDs of all distributions the admin has ever started
    function getDistributions(
        address admin
    ) public view returns (uint256[] memory) {
        // Do not check wheter the given address is actually an admin
        if (admin == address(0)) {
            revert InvalidAdminAddress();
        }
        return adminsToDistributions[admin];
    }

    /// @notice Returns the distribution with the given ID
    /// @param id The ID of the distribution to search for
    /// @return All information about the distribution
    function getDistribution(
        uint256 id
    ) public view returns (uint256, address, address, uint256, bool) {
        if (id < 1) {
            revert InvalidDistributionId();
        }
        if (distributionsToAdmins[id] == address(0)) {
            revert DistributionNotStarted();
        }
        Distribution storage distribution = distributions[id];
        return (
            distribution.id,
            distribution.origToken,
            distribution.distToken,
            distribution.amount,
            distribution.isEqual
        );
    }

    /// @notice Checks if user has claimed dividends of the provided distribution
    /// @param id The ID of the distribution to check
    /// @param user The address of the user to check
    /// @return True if user has claimed dividends. Otherwise - false
    function hasClaimed(uint256 id, address user) public view returns (bool) {
        if (id < 1) {
            revert InvalidDistributionId();
        }
        if (distributionsToAdmins[id] == address(0)) {
            revert DistributionNotStarted();
        }
        if (user == address(0)) {
            revert InvalidUserAddress();
        }
        return distributions[id].hasClaimed[user];
    }

    /// @notice Checks if the distribution with the given ID was started by the given admin
    /// @param id The ID of the distribution to check
    /// @param admin The address of the admin to check
    /// @return True if admin has started the distribution with the given ID. Otherwise - false.
    function checkStartedByAdmin(
        uint256 id,
        address admin
    ) public view returns (bool) {
        if (id < 1) {
            revert InvalidDistributionId();
        }
        if (distributionsToAdmins[id] == address(0)) {
            revert DistributionNotStarted();
        }
        if (admin == address(0)) {
            revert InvalidAdminAddress();
        }
        if (distributionsToAdmins[id] == admin) {
            return true;
        }
        return false;
    }

    /// @notice Returns the share of the user in a given distribution
    /// @param id The ID of the distribution to calculate share in
    function getMyShare(uint256 id) external view returns (uint256) {
        if (id > distributionIds.current() + 1) {
            revert InvalidDistribution();
        }
        // Only lockers might have shares
        if (!isLocker(distributions[id].origToken, msg.sender)) {
            revert CallerIsNotLocker();
        }
        return calculateShare(id, msg.sender);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBentureProducedToken.sol";
import "./interfaces/IBentureAdmin.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BentureProducedToken is ERC20, IBentureProducedToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    string internal _tokenName;
    string internal _tokenSymbol;
    uint8 internal _decimals;
    bool internal _mintable;
    /// @dev The address of the admin token has to be provided in order
    ///      to verify user's ownership of that token
    address internal _adminToken;
    /// @dev The maximum number of tokens to be minted
    uint256 internal _maxTotalSupply;
    /// @dev A list of addresses of tokens holders
    EnumerableSet.AddressSet internal _holders;

    /// @dev Checks if mintability is activated
    modifier WhenMintable() {
        if (!_mintable) {
            revert TheTokenIsNotMintable();
        }
        _;
    }

    /// @dev Checks if caller is an admin token holder
    modifier hasAdminToken() {
        if (
            !IBentureAdmin(_adminToken).verifyAdminToken(
                msg.sender,
                address(this)
            )
        ) {
            revert UserDoesNotHaveAnAdminToken();
        }
        _;
    }

    /// @dev Creates a new controlled ERC20 token.
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    /// @param decimals_ Number of decimals of the token
    /// @param mintable_ Token may be either mintable or not. Can be changed later.
    /// @param maxTotalSupply_ Maximum amount of tokens to be minted
    ///        Use `0` to create a token with no maximum amount
    /// @param adminToken_ Address of the admin token for controlled token
    /// @dev Only the factory can initialize controlled tokens
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool mintable_,
        uint256 maxTotalSupply_,
        address adminToken_
    ) ERC20(name_, symbol_) {
        if (bytes(name_).length == 0) {
            revert EmptyTokenName();
        }
        if (bytes(symbol_).length == 0) {
            revert EmptyTokenSymbol();
        }
        if (decimals_ == 0) {
            revert EmptyTokenDecimals();
        }
        if (adminToken_ == address(0)) {
            revert InvalidAdminTokenAddress();
        }
        if (mintable_) {
            // If token is mintable it could either have a fixed maxTotalSupply or
            // have an "infinite" supply
            // ("infinite" up to max value of `uint256` type)
            if (maxTotalSupply_ == 0) {
                // If 0 value was provided by the user, that means he wants to create
                // a token with an "infinite" max total supply
                maxTotalSupply_ = type(uint256).max;
            }
        } else {
            if (maxTotalSupply_ != 0) {
                revert NotZeroMaxTotalSupply();
            }
        }
        _tokenName = name_;
        _tokenSymbol = symbol_;
        _decimals = decimals_;
        _mintable = mintable_;
        _maxTotalSupply = maxTotalSupply_;
        _adminToken = adminToken_;
    }

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name()
        public
        view
        override(ERC20, IBentureProducedToken)
        returns (string memory)
    {
        return _tokenName;
    }

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol()
        public
        view
        override(ERC20, IBentureProducedToken)
        returns (string memory)
    {
        return _tokenSymbol;
    }

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals()
        public
        view
        override(ERC20, IBentureProducedToken)
        returns (uint8)
    {
        return _decimals;
    }

    /// @notice Indicates whether the token is mintable or not
    /// @return True if the token is mintable. False - if it is not
    function mintable() external view override returns (bool) {
        return _mintable;
    }

    /// @notice Returns the array of addresses of all token holders
    /// @return The array of addresses of all token holders
    function holders() external view returns (address[] memory) {
        return _holders.values();
    }

    /// @notice Returns the max total supply of the token
    /// @return The max total supply of the token
    function maxTotalSupply() external view returns (uint256) {
        return _maxTotalSupply;
    }

    /// @notice Checks if the address is a holder
    /// @param account The address to check
    /// @return True if address is a holder. False if it is not
    function isHolder(address account) public view returns (bool) {
        return _holders.contains(account);
    }

    /// @notice Checks if user is an admin of this token
    /// @param account The address to check
    /// @return True if user has admin token. Otherwise - false.
    function checkAdmin(address account) public view returns (bool) {
        // This reverts. Does not return boolean.
        return
            IBentureAdmin(_adminToken).verifyAdminToken(account, address(this));
    }

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    /// @dev Can only be called by the owner of the admin NFT
    /// @dev Can only be called when token is mintable
    function mint(
        address to,
        uint256 amount
    ) external override hasAdminToken WhenMintable {
        if (to == address(0)) {
            revert InvalidUserAddress();
        }
        if (totalSupply() + amount > _maxTotalSupply) {
            revert SupplyExceedsMaximumSupply();
        }
        emit ControlledTokenCreated(to, amount);
        // Add receiver of tokens to holders list if he isn't there already
        _holders.add(to);
        // Mint tokens to the receiver anyways
        _mint(to, amount);
    }

    /// @notice Burns user's tokens
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) external override {
        address caller = msg.sender;
        if (amount == 0) {
            revert InvalidBurnAmount();
        }
        if (balanceOf(caller) == 0) {
            revert NoTokensToBurn();
        }
        emit ControlledTokenBurnt(caller, amount);
        _burn(caller, amount);
        // If caller does not have any tokens - remove the address from holders
        if (balanceOf(msg.sender) == 0) {
            bool removed = _holders.remove(caller);
            if (!removed) {
                revert DeletingHolderFailed();
            }
        }
    }

    /// @notice Moves tokens from one account to another account
    /// @param from The address to transfer from
    /// @param to The address to transfer to
    /// @param amount The amount of tokens to be transferred
    /// @dev It is called by high-level functions. That is why it is necessary to override it
    /// @dev Transfers are permitted for everyone - not just admin token holders
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0)) {
            revert InvalidUserAddress();
        }
        if (to == address(0)) {
            revert InvalidUserAddress();
        }
        if (to == from) {
            revert SenderCanNotBeAReceiver();
        }
        if (!isHolder(from)) {
            revert NoTokensToTransfer();
        }
        emit ControlledTokenTransferred(from, to, amount);
        // If the receiver is not yet a holder, he becomes a holder
        _holders.add(to);
        // If all tokens of the holder get transferred - he is no longer a holder
        uint256 fromBalance = balanceOf(from);
        if (amount >= fromBalance) {
            bool removed = _holders.remove(from);
            if (!removed) {
                revert DeletingHolderFailed();
            }
        }
        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./errors/IBentureErrors.sol";

/// @title Dividend-Paying Token Interface

/// @dev An interface for dividends distributing contract
interface IBenture is IBentureErrors {
    /// @notice Creates a new pool
    /// @param token The token that will be locked in the pool
    function createPool(address token) external;

    /// @notice Locks the provided amount of user's tokens in the pool
    /// @param origToken The address of the token to lock
    /// @param amount The amount of tokens to lock
    function lockTokens(address origToken, uint256 amount) external;

    /// @notice Locks all user's tokens in the pool
    /// @param origToken The address of the token to lock
    function lockAllTokens(address origToken) external;

    /// @notice Unlocks the provided amount of user's tokens from the pool
    /// @param origToken The address of the token to unlock
    /// @param amount The amount of tokens to unlock
    function unlockTokens(address origToken, uint256 amount) external;

    /// @notice Unlocks all locked tokens of the user in the pool
    /// @param origToken The address of the token to unlock
    function unlockAllTokens(address origToken) external;

    /// @notice Allows admin to distribute dividends among lockers
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    ///        Use zero address for native tokens
    /// @param amount The amount of ERC20 tokens that will be paid
    /// @param isEqual Indicates whether distribution will be equal
    function distributeDividends(
        address origToken,
        address distToken,
        uint256 amount,
        bool isEqual
    ) external payable;

    /// @notice Allows user to claim dividends from a single distribution
    /// @param id The ID of the distribution to claim
    function claimDividends(uint256 id) external;

    /// @notice Allows user to claim dividends from multiple distributions
    ///         WARNING: Potentially can exceed block gas limit!
    /// @param ids The array of IDs of distributions to claim
    function claimMultipleDividends(uint256[] calldata ids) external;

    /// @notice Allows admin to distribute provided amounts of tokens to the provided list of users
    /// @param token The address of the token to be distributed
    /// @param users The list of addresses of users to receive tokens
    /// @param amounts The list of amounts each user has to receive
    /// @param totalAmount The total amount of `token`s to be distributed. Sum of `amounts` array.
    function distributeDividendsCustom(
        address token,
        address[] calldata users,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external payable;

    /// @notice Sets the token factory contract address
    /// @param factoryAddress The address of the factory
    /// @dev NOTICE: This address can't be set the constructor because
    ///      `Benture` is deployed *before* factory contract.
    function setFactoryAddress(address factoryAddress) external;

    /// @notice Returns info about the pool of a given token
    /// @param token The address of the token of the pool
    /// @return The address of the tokens in the pool.
    /// @return The number of users who locked their tokens in the pool
    /// @return The amount of locked tokens
    function getPool(
        address token
    ) external view returns (address, uint256, uint256);

    /// @notice Returns the array of lockers of the pool
    /// @param token The address of the token of the pool
    /// @return The array of lockers of the pool
    function getLockers(address token) external view returns (address[] memory);

    /// @notice Checks if user is a locker of the provided token pool
    /// @param token The address of the token of the pool
    /// @param user The address of the user to check
    /// @return True if user is a locker in the pool. Otherwise - false.
    function isLocker(address token, address user) external view returns (bool);

    /// @notice Returns the current lock amount of the user
    /// @param user The address of the user to check
    /// @param token The address of the token of the pool
    /// @return The current lock amount
    function getCurrentLock(
        address user,
        address token
    ) external view returns (uint256);

    /// @notice Returns the list of IDs of all active distributions the admin has started
    /// @param admin The address of the admin
    /// @return The list of IDs of all active distributions the admin has started
    function getDistributions(
        address admin
    ) external view returns (uint256[] memory);

    /// @notice Returns the distribution with the given ID
    /// @param id The ID of the distribution to search for
    /// @return All information about the distribution
    function getDistribution(
        uint256 id
    ) external view returns (uint256, address, address, uint256, bool);

    /// @notice Checks if user has claimed dividends of the provided distribution
    /// @param id The ID of the distribution to check
    /// @param user The address of the user to check
    /// @return True if user has claimed dividends. Otherwise - false
    function hasClaimed(uint256 id, address user) external view returns (bool);

    /// @notice Checks if the distribution with the given ID was started by the given admin
    /// @param id The ID of the distribution to check
    /// @param admin The address of the admin to check
    /// @return True if admin has started the distribution with the given ID. Otherwise - false.
    function checkStartedByAdmin(
        uint256 id,
        address admin
    ) external view returns (bool);

    /// @notice Returns the share of the user in a given distribution
    /// @param id The ID of the distribution to calculate share in
    /// @return The share of the caller
    function getMyShare(uint256 id) external view returns (uint256);

    /// @dev Indicates that a new pool has been created
    event PoolCreated(address indexed token);

    /// @dev Indicates that a pool has been deleted
    event PoolDeleted(address indexed token);

    /// @dev Indicated that tokens have been locked
    event TokensLocked(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @dev Indicated that tokens have been locked
    event TokensUnlocked(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @dev Indicates that new dividends distribution was started
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    /// @param amount The amount of tokens that will be paid
    /// @param isEqual Indicates whether distribution will be equal
    event DividendsStarted(
        address indexed origToken,
        address indexed distToken,
        uint256 indexed amount,
        bool isEqual
    );

    /// @dev Indicates that dividends were claimed by a user
    /// @param id The ID of the distribution that was claimed
    /// @param user The address of the user who claimed the distribution
    event DividendsClaimed(uint256 indexed id, address user);

    /// @dev Indicates that multiple dividends were claimed by a user
    /// @param user The address of the user who claimed the distributions
    /// @param count The total number of claimed dividends
    event MultipleDividendsClaimed(address user, uint256 count);

    /// @dev Indicates that custom dividends were sent to the list of users
    /// @param token The token distributed
    /// @param count The total number of users who received their shares
    ///              Counting starts from the first user and does not skip any users
    event CustomDividendsDistributed(address indexed token, uint256 count);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./errors/IBentureProducedTokenErrors.sol";

/// @title An interface for a custom ERC20 contract used in the bridge
interface IBentureProducedToken is IERC20, IBentureProducedTokenErrors {
    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals() external view returns (uint8);

    /// @notice Indicates whether the token is mintable or not
    /// @return True if the token is mintable. False - if it is not
    function mintable() external view returns (bool);

    /// @notice Returns the array of addresses of all token holders
    /// @return The array of addresses of all token holders
    function holders() external view returns (address[] memory);

    /// @notice Returns the max total supply of the token
    /// @return The max total supply of the token
    function maxTotalSupply() external view returns (uint256);

    /// @notice Checks if the address is a holder
    /// @param account The address to check
    /// @return True if address is a holder. False if it is not
    function isHolder(address account) external view returns (bool);

    /// @notice Checks if user is an admin of this token
    /// @param account The address to check
    /// @return True if user has admin token. Otherwise - false.
    function checkAdmin(address account) external view returns (bool);

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    /// @dev Can only be called by the owner of the admin NFT
    /// @dev Can only be called when token is mintable
    function mint(address to, uint256 amount) external;

    /// @notice Burns user's tokens
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) external;

    /// @notice Indicates that a new ERC20 was created
    event ControlledTokenCreated(address indexed account, uint256 amount);

    /// @notice Indicates that a new ERC20 was burnt
    event ControlledTokenBurnt(address indexed account, uint256 amount);

    /// @notice Indicates that a new ERC20 was transferred
    event ControlledTokenTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./errors/IBentureAdminErrors.sol";

/// @title An interface of a factory of custom ERC20 tokens;
interface IBentureAdmin is IBentureAdminErrors {
    /// @notice Checks it the provided address owns any admin token
    function checkOwner(address user) external view;

    /// @notice Checks if the provided user owns an admin token controlling the provided ERC20 token
    /// @param user The address of the user that potentially controls ERC20 token
    /// @param ERC20Address The address of the potentially controlled ERC20 token
    /// @return True if user has admin token. Otherwise - false.
    function verifyAdminToken(
        address user,
        address ERC20Address
    ) external view returns (bool);

    /// @notice Returns the address of the controlled ERC20 token
    /// @param tokenId The ID of ERC721 token to check
    /// @return The address of the controlled ERC20 token
    function getControlledAddressById(
        uint256 tokenId
    ) external view returns (address);

    /// @notice Returns the list of all admin tokens of the user
    /// @param admin The address of the admin
    function getAdminTokenIds(
        address admin
    ) external view returns (uint256[] memory);

    /// @notice Returns the address of the factory that mints admin tokens
    /// @return The address of the factory
    function getFactory() external view returns (address);

    /// @notice Mints a new ERC721 token with the address of the controlled ERC20 token
    /// @param to The address of the receiver of the token
    /// @param ERC20Address The address of the controlled ERC20 token
    function mintWithERC20Address(address to, address ERC20Address) external;

    /// @notice Burns the token with the provided ID
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external;

    /// @dev Indicates that a new ERC721 token got minted
    event AdminTokenCreated(
        uint256 indexed tokenId,
        address indexed ERC20Address
    );

    /// @dev Indicates that an ERC721 token got burnt
    event AdminTokenBurnt(uint256 indexed tokenId);

    /// @dev Indicates that an ERC721 token got transferred
    event AdminTokenTransferred(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
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

pragma solidity ^0.8.9;

interface IBentureProducedTokenErrors {
    error TheTokenIsNotMintable();
    error UserDoesNotHaveAnAdminToken();
    error EmptyTokenName();
    error EmptyTokenSymbol();
    error EmptyTokenDecimals();
    error InvalidAdminTokenAddress();
    error NotZeroMaxTotalSupply();
    error InvalidUserAddress();
    error SupplyExceedsMaximumSupply();
    error InvalidBurnAmount();
    error NoTokensToBurn();
    error DeletingHolderFailed();
    error SenderCanNotBeAReceiver();
    error NoTokensToTransfer();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBentureAdminErrors {
    error CallerIsNotAFactory();
    error InvalidFactoryAddress();
    error InvalidUserAddress();
    error InvalidAdminAddress();
    error UserDoesNotHaveAnAdminToken();
    error InvalidTokenAddress();
    error NoControlledToken();
    error FailedToDeleteTokenID();
    error MintToZeroAddressNotAllowed();
    error OnlyOneAdminTokenForProjectToken();
    error NotAnOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBentureErrors {
    error NativeTokenTransferFailed();
    error InvalidTokenAddress();
    error PoolAlreadyExists();
    error CallerNotAdminOrFactory();
    error InvalidLockAmount();
    error CallerIsNotLocker();
    error PoolDoesNotExist();
    error EmptyList();
    error ListsLengthDiffers();
    error WrongTokenInsideThePool();
    error UserDoesNotHaveProjectTokens();
    error UserDoesNotHaveAnAdminToken();
    error TransferFailed();
    error InvalidUnlockAmount();
    error NoLockedTokens();
    error WithdrawTooBig();
    error InvalidDividendsAmount();
    error NotEnoughNativeTokens();
    error DistributionHasNotStartedYet();
    error InvalidDistribution();
    error UserDoesNotHaveLockedTokens();
    error AlreadyClaimed();
    error InvalidUserAddress();
    error InvalidAdminAddress();
    error InvalidDistributionId();
    error DistributionNotStarted();
    error FactoryAddressNotSet();
    error InvalidFactoryAddress();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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