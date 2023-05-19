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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { EnforcementCriteriaInterface } from '../interfaces/enforcement/EnforcementCriteriaInterface.sol';

/// @dev Helper libraries.
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract BucketEnforcement is EnforcementCriteriaInterface {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The definition how the scoring rubric is applied to a submission.
    struct Buckets {
        uint256 maxScore;
        uint256[] ranges;
        uint256[] weights;
    }

    /// @dev The scores given to a service submission.
    struct Score {
        uint256 reviewSum;
        uint256 earnings;
        uint256 remainder;
        EnumerableSet.AddressSet enforcers;
    }

    /// @dev The relevant storage data for a request.
    struct Request {
        uint256 scaledAvgSum;
        uint256 remainder;
        mapping(uint256 => Score) scores;
    }

    /// @notice The maximum score that can be provided relative to a market.
    mapping(address => uint256) public marketToMaxScore;

    /// @dev Tracks the bucket criteria for a labor market.
    mapping(address => Buckets) internal marketToBuckets;

    /// @dev Tracks the cumulative sum of average score.
    mapping(address => mapping(uint256 => Request)) internal marketToRequestIdToRequest;

    /**
     * See {EnforcementCriteriaInterface.setConfiguration}
     */
    function setConfiguration(
        uint256[] calldata _auxilaries,
        uint256[] calldata _ranges,
        uint256[] calldata _weights
    ) public virtual {
        /// @notice Pull the bucket criteria for the respective Labor Market.
        Buckets storage buckets = marketToBuckets[msg.sender];

        /// @dev Criteria can only be set once.
        require(buckets.maxScore == 0, 'ScalableEnforcement::setBuckets: Criteria already in use');

        /// @notice Ensure a value for max score has been provided.
        require(_auxilaries[0] != 0, 'ScalableEnforcement::setBuckets: Max score not set');

        /// @dev The ranges and weights must be the same length.
        require(_ranges.length == _weights.length, 'ScalableEnforcement::setBuckets: Invalid input');

        /// @dev The ranges must be in ascending order.
        for (uint256 i; i < _ranges.length - 1; i++) {
            /// @dev Confirm the ranges are sequential.
            require(_ranges[i] < _ranges[i + 1], 'ScalableEnforcement::setBuckets: Buckets not sequential');
        }

        /// @dev Set the criteria.
        buckets.maxScore = _auxilaries[0];
        buckets.ranges = _ranges;
        buckets.weights = _weights;

        /// @dev Announce the configuration to enable complex analytics.
        emit EnforcementConfigured(msg.sender, _auxilaries, _ranges, _weights);
    }

    /**
     * See {EnforcementCriteriaInterface.enforce}
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        uint256 _availableShare,
        address _enforcer
    ) public virtual returns (bool, uint24) {
        /// @notice Pull the score data for the respective Submission.
        Score storage score = marketToRequestIdToRequest[msg.sender][_requestId].scores[_submissionId];

        /// @notice Confirm that a score for this submission and enforcer is not already submitted.
        require(!score.enforcers.contains(_enforcer), 'ScalableEnforcement::review: Enforcer already submit a review');

        /// @dev Retrieve the buckets state from the storage slot.
        Buckets storage buckets = marketToBuckets[msg.sender];

        /// @notice Confirm the score stays within bounds of defintion.
        require(_score <= buckets.maxScore, 'ScalableEnforcement::review: Invalid score');

        /// @notice Add the enforcer to the list of enforcers to prevent double-reviewing.
        score.enforcers.add(_enforcer);

        /// @notice Pull the enforcement data for the respective Request.
        Request storage request = marketToRequestIdToRequest[msg.sender][_requestId];

        /// @notice Add the score to the cumulative total.
        score.reviewSum += _score;

        /// @notice Remove the scaled average from the cumulative total to prevent double-count.
        /// @dev This removes the previously set remainder for this submission because the value is
        ///      about to change and we want to update the value on request 1:1.
        request.remainder -= score.remainder;

        /// @notice Determine the bucket weight for the average score.
        uint256 bucketWeight = _getScoreToBucket(buckets, score.reviewSum / score.enforcers.length());

        /// @notice Calculate the amount owed to the Provider for their contribution.
        score.earnings = (_availableShare * bucketWeight) / buckets.maxScore;

        /// @dev Determine the amount of funding should be refunded to the Requester
        score.remainder = _availableShare - score.earnings;

        /// @notice Keep a global tracker of the total remainder available to enable Requester reclaims.
        request.remainder += score.remainder;

        /// @notice Announce the update in the reviewing status of the submission.
        emit SubmissionReviewed(msg.sender, _requestId, _submissionId, 1, score.earnings, score.remainder, true);

        /// @notice Return the intent change.
        /// @dev `newSubmission` is always `true` because editing a submission is forbidden in this module.
        return (true, 1);
    }

    /**
     * See {EnforcementCriteriaInterface.rewards}
     */
    function rewards(uint256 _requestId, uint256 _submissionId)
        public
        virtual
        returns (uint256 amount, bool requiresSubmission)
    {
        amount = _rewards(msg.sender, _requestId, _submissionId);

        /// @notice Delete their earnings that has been saved.
        /// @dev This prevents re-entrancy in this specific module.
        delete marketToRequestIdToRequest[msg.sender][_requestId].scores[_submissionId].earnings;

        /// @notice In this version of the module `requiresSubmission` remains a
        ///         helpful as it serves as a "re-entrancy guard" due to earnings
        ///         being final upon claim.
        return (amount, true);
    }

    /**
     * See {EnforcementCriteriaInterface.remainder}
     */
    function remainder(uint256 _requestId) public virtual returns (uint256 amount) {
        amount = _remainder(msg.sender, _requestId);

        /// @notice Delete their earnings that has been saved.
        /// @dev This prevents re-entrancy in this specific module.
        delete marketToRequestIdToRequest[msg.sender][_requestId].remainder;
    }

    /**
     * @notice Get the rewarded payment token amount for a submission.
     * @param _market The address of the Labor Market to check the Submission of.
     * @param _requestId The id of the Request the Submission is related to.
     * @param _submissionId The id of the Submission to check the rewards of.
     * @return The amount of payment tokens earned by the Submission.
     */
    function getRewards(
        address _market,
        uint256 _requestId,
        uint256 _submissionId
    ) public virtual returns (uint256) {
        return _rewards(_market, _requestId, _submissionId);
    }

    /**
     * @notice Get the amount of payment tokens that were unearned by participating providers.
     * @dev Does not include the remainder left over from expected submissions that were not made.
     * @param _market The address of the Labor Market to check the Request of.
     * @param _requestId The id of the request the submission is related to.
     * @return The amount of payment tokens that were unearned by participating providers.
     */
    function getRemainder(address _market, uint256 _requestId) public virtual returns (uint256) {
        return _remainder(_market, _requestId);
    }

    /**
     * @notice Get the rewards for a given market and submission.
     * @param _market The address of the Labor Market to check the Request of.
     * @param _requestId The id of the request the submission is related to.
     * @param _submissionId The id of the Provider submission.
     * @return amount The earnings available owed to the Provider.
     */
    function _rewards(
        address _market,
        uint256 _requestId,
        uint256 _submissionId
    ) internal view returns (uint256 amount) {
        /// @notice Retrieve the request data out of the storage slot.
        Request storage request = marketToRequestIdToRequest[_market][_requestId];

        /// @dev Determine how much the submission has earned.
        amount = request.scores[_submissionId].earnings;
    }

    /**
     * @notice Get the remainder for a given Market and Request.
     * @param _market The address of the Labor Market to check the Request of.
     * @param _requestId The id to check the remainder of.
     * @param amount The surprlus of funding remaining after currently calculated Provider distributions.
     */
    function _remainder(address _market, uint256 _requestId) internal view returns (uint256 amount) {
        /// @notice Retrieve the request data out of the storage slot.
        Request storage request = marketToRequestIdToRequest[_market][_requestId];

        /// @notice Determine how much the submission has earned.
        amount = request.remainder;
    }

    /**
     * @notice Determines where a score falls in the buckets and returns the weight.
     * @param _buckets The distribution buckets applied to the score.
     * @param _score The score to get the weight for.
     */
    function _getScoreToBucket(Buckets memory _buckets, uint256 _score) internal pure returns (uint256) {
        /// @dev Loop through the buckets from the end and return the first weight that the range is less than the score.
        uint256 i = _buckets.ranges.length;

        /// @dev If the buckets are not configured, default to 1.
        if (i == 0) return 1;

        /// @notice Loop down through the bucket to find the one it belongs to.
        /// @dev Elementary loop employed due to the non-standard spacing of bucket ranges.
        for (i; i > 0; i--) {
            if (_score >= _buckets.ranges[i - 1]) return _buckets.weights[i - 1];
        }

        /// @dev If the score is less than the first bucket, return the first weight.
        return _buckets.weights[0];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {
    /// @notice Announces the definition of the criteria configuration.
    event EnforcementConfigured(address indexed _market, uint256[] _auxiliaries, uint256[] _alphas, uint256[] _betas);

    /// @notice Announces change in Submission reviews.
    event SubmissionReviewed(
        address indexed _market,
        uint256 indexed _requestId,
        uint256 indexed _submissionId,
        uint256 intentChange,
        uint256 earnings,
        uint256 remainder,
        bool newSubmission
    );

    /**
     * @notice Set the configuration for a Labor Market using the generalized parameters.
     * @param _auxiliaries The auxiliary parameters for the Labor Market.
     * @param _alphas The alpha parameters for the Labor Market.
     * @param _betas The beta parameters for the Labor Market.
     */
    function setConfiguration(
        uint256[] calldata _auxiliaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) external;

    /**
     * @notice Submit a new score for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @param _score The score of the submission.
     * @param _availableShare The amount of the $pToken available for this submission.
     * @param _enforcer The individual submitting the score.
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        uint256 _availableShare,
        address _enforcer
    ) external returns (bool, uint24);

    /**
     * @notice Retrieve and distribute the rewards for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @return amount The amount of $pToken to be distributed.
     * @return requiresSubmission Whether or not the submission requires a new score.
     */
    function rewards(uint256 _requestId, uint256 _submissionId)
        external
        returns (uint256 amount, bool requiresSubmission);

    /**
     * @notice Retrieve the amount of $pToken owed back to the Requester.
     * @param _requestId The ID of the request.
     * @return amount The amount of $pToken owed back to the Requester.
     */
    function remainder(uint256 _requestId) external returns (uint256 amount);
}