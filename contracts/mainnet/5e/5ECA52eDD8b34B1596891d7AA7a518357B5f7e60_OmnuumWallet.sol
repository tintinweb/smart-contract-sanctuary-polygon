// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @title OmnuumWallet Allows multiple owners to agree to withdraw money, add/remove/change owners before execution
/// @notice This contract is not managed by Omnuum admin, but for owners
/// @author Omnuum Dev Team <[email protected]>

import '@openzeppelin/contracts/utils/math/Math.sol';

contract OmnuumWallet {
    /// @notice consensusRatio Ratio of votes to reach consensus as a percentage of total votes
    uint256 public immutable consensusRatio;

    /// @notice Minimum limit of required number of votes for consensus
    uint8 public immutable minLimitForConsensus;

    /// @notice Withdraw = 0
    /// @notice Add = 1
    /// @notice Remove = 2
    /// @notice Change = 3
    /// @notice Cancel = 4
    enum RequestTypes {
        Withdraw,
        Add,
        Remove,
        Change,
        Cancel
    }

    /// @notice F = 0 (F-Level Not owner)
    /// @notice D = 1 (D-Level own 1 vote)
    /// @notice C = 2 (C-Level own 2 votes)
    enum OwnerVotes {
        F,
        D,
        C
    }
    struct OwnerAccount {
        address addr;
        OwnerVotes vote;
    }
    struct Request {
        address requester;
        RequestTypes requestType;
        OwnerAccount currentOwner;
        OwnerAccount newOwner;
        uint256 withdrawalAmount;
        mapping(address => bool) voters;
        uint256 votes;
        bool isExecute;
    }

    Request[] public requests;
    mapping(OwnerVotes => uint8) public ownerCounter;
    mapping(address => OwnerVotes) public ownerVote;

    constructor(
        uint256 _consensusRatio,
        uint8 _minLimitForConsensus,
        OwnerAccount[] memory _initialOwnerAccounts
    ) {
        consensusRatio = _consensusRatio;
        minLimitForConsensus = _minLimitForConsensus;
        for (uint256 i; i < _initialOwnerAccounts.length; i++) {
            OwnerVotes vote = _initialOwnerAccounts[i].vote;
            ownerVote[_initialOwnerAccounts[i].addr] = vote;
            ownerCounter[vote]++;
        }

        _checkMinConsensus();
    }

    event PaymentReceived(address indexed sender, address indexed target, string topic, string description, uint256 value);
    event MintFeeReceived(address indexed nftContract, uint256 value);
    event EtherReceived(address indexed sender, uint256 value);
    event Requested(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);
    event Approved(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Revoked(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Canceled(address indexed owner, uint256 indexed requestId);
    event Executed(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);

    modifier onlyOwner(address _address) {
        /// @custom:error (004) - Only the owner of the wallet is allowed
        require(isOwner(_address), 'OO4');
        _;
    }

    modifier notOwner(address _address) {
        /// @custom:error (005) - Already the owner of the wallet
        require(!isOwner(_address), 'OO5');
        _;
    }

    modifier isOwnerAccount(OwnerAccount memory _ownerAccount) {
        /// @custom:error (NX2) - Non-existent wallet account
        address _addr = _ownerAccount.addr;
        require(isOwner(_addr) && uint8(ownerVote[_addr]) == uint8(_ownerAccount.vote), 'NX2');
        _;
    }

    modifier onlyRequester(uint256 _reqId) {
        /// @custom:error (OO6) - Only the requester is allowed
        require(requests[_reqId].requester == msg.sender, 'OO6');
        _;
    }

    modifier reachConsensus(uint256 _reqId) {
        /// @custom:error (NE2) - Not reach consensus
        require(requests[_reqId].votes >= requiredVotesForConsensus(), 'NE2');
        _;
    }

    modifier reqExists(uint256 _reqId) {
        /// @custom:error (NX3) - Non-existent owner request
        require(_reqId < requests.length, 'NX3');
        _;
    }

    modifier notExecutedOrCanceled(uint256 _reqId) {
        /// @custom:error (SE1) - Already executed
        require(!requests[_reqId].isExecute, 'SE1');

        /// @custom:error (SE2) - Request canceled
        require(requests[_reqId].requestType != RequestTypes.Cancel, 'SE2');
        _;
    }

    modifier notVoted(address _owner, uint256 _reqId) {
        /// @custom:error (SE3) - Already voted
        require(!isOwnerVoted(_owner, _reqId), 'SE3');
        _;
    }

    modifier voted(address _owner, uint256 _reqId) {
        /// @custom:error (SE4) - Not voted
        require(isOwnerVoted(_owner, _reqId), 'SE4');
        _;
    }

    modifier isValidAddress(address _address) {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_address != address(0), 'AE1');
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }

        /// @notice It's not perfect filtering against CA, but the owners can handle it cautiously.
        /// @custom:error (AE2) - Contract address not acceptable
        require(codeSize == 0, 'AE2');
        _;
    }

    function mintFeePayment(address _nftContract) external payable {
        /// @custom:error (NE3) - A zero payment is not acceptable
        require(msg.value > 0, 'NE3');
        emit MintFeeReceived(_nftContract, msg.value);
    }

    function makePayment(
        address _target,
        string calldata _topic,
        string calldata _description
    ) external payable {
        /// @custom:error (NE3) - A zero payment is not acceptable
        require(msg.value > 0, 'NE3');
        emit PaymentReceived(msg.sender, _target, _topic, _description, msg.value);
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice requestOwnerManage
    /// @dev Allows an owner to request for an agenda that wants to proceed
    /// @dev The owner can make multiple requests even if the previous one is unresolved
    /// @dev The requester is automatically voted for the request
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _currentAccount Tuple[address, OwnerVotes] for current exist owner account (use for Request Type as Remove or Change)
    /// @param _newAccount Tuple[address, OwnerVotes] for new owner account (use for Request Type as Add or Change)

    function requestOwnerManagement(
        RequestTypes _requestType,
        OwnerAccount calldata _currentAccount,
        OwnerAccount calldata _newAccount
    ) external onlyOwner(msg.sender) {
        address requester = msg.sender;

        Request storage request_ = requests.push();
        request_.requester = requester;
        request_.requestType = _requestType;
        request_.currentOwner = OwnerAccount({ addr: _currentAccount.addr, vote: _currentAccount.vote });
        request_.newOwner = OwnerAccount({ addr: _newAccount.addr, vote: _newAccount.vote });
        request_.voters[requester] = true;
        request_.votes = uint8(ownerVote[requester]);

        emit Requested(msg.sender, requests.length - 1, _requestType);
    }

    /// @notice requestWithdrawal
    /// @dev Allows an owner to request withdrawal
    /// @dev The owner can make multiple requests even if the previous one is unresolved
    /// @dev The requester is automatically voted for the request
    /// @param _withdrawalAmount Amount of Ether to be withdrawal (use for Request Type as Withdrawal)
    function requestWithdrawal(uint256 _withdrawalAmount) external onlyOwner(msg.sender) {
        address requester = msg.sender;

        Request storage request_ = requests.push();
        request_.withdrawalAmount = _withdrawalAmount;
        request_.requester = requester;
        request_.requestType = RequestTypes.Withdraw;
        request_.voters[requester] = true;
        request_.votes = uint8(ownerVote[requester]);

        emit Requested(msg.sender, requests.length - 1, RequestTypes.Withdraw);
    }

    /// @notice approve
    /// @dev Allows owners to approve the request
    /// @dev The owner can revoke the approval whenever the request is still in progress (not executed or canceled)
    /// @param _reqId Request id that the owner wants to approve

    function approve(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        notVoted(msg.sender, _reqId)
    {
        OwnerVotes _vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        request_.voters[msg.sender] = true;
        request_.votes += uint8(_vote);

        emit Approved(msg.sender, _reqId, _vote);
    }

    /// @notice revoke
    /// @dev Allow an approver(owner) to revoke the approval
    /// @param _reqId Request id that the owner wants to revoke

    function revoke(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        voted(msg.sender, _reqId)
    {
        OwnerVotes vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        delete request_.voters[msg.sender];
        request_.votes -= uint8(vote);

        emit Revoked(msg.sender, _reqId, vote);
    }

    /// @notice cancel
    /// @dev Allows a requester(owner) to cancel the own request
    /// @dev After proceeding, it cannot revert the cancellation. Be cautious
    /// @param _reqId Request id requested by the requester

    function cancel(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) {
        requests[_reqId].requestType = RequestTypes.Cancel;

        emit Canceled(msg.sender, _reqId);
    }

    /// @notice execute
    /// @dev Allow an requester(owner) to execute the request
    /// @dev After proceeding, it cannot revert the execution. Be cautious
    /// @param _reqId Request id that the requester wants to execute

    function execute(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) reachConsensus(_reqId) {
        Request storage request_ = requests[_reqId];
        uint8 type_ = uint8(request_.requestType);
        request_.isExecute = true;

        if (type_ == uint8(RequestTypes.Withdraw)) {
            _withdraw(request_.withdrawalAmount, request_.requester);
        } else if (type_ == uint8(RequestTypes.Add)) {
            _addOwner(request_.newOwner);
        } else if (type_ == uint8(RequestTypes.Remove)) {
            _removeOwner(request_.currentOwner);
        } else if (type_ == uint8(RequestTypes.Change)) {
            _changeOwner(request_.currentOwner, request_.newOwner);
        }
        emit Executed(msg.sender, _reqId, request_.requestType);
    }

    /// @notice totalVotes
    /// @dev Allows users to see how many total votes the wallet currently have
    /// @return votes The total number of voting rights the owners have

    function totalVotes() public view returns (uint256 votes) {
        return ownerCounter[OwnerVotes.D] + 2 * ownerCounter[OwnerVotes.C];
    }

    /// @notice isOwner
    /// @dev Allows users to verify registered owners in the wallet
    /// @param _owner Address of the owner that you want to verify
    /// @return isVerified Verification result of whether the owner is correct

    function isOwner(address _owner) public view returns (bool isVerified) {
        return uint8(ownerVote[_owner]) > 0;
    }

    /// @notice isOwnerVoted
    /// @dev Allows users to check which owner voted
    /// @param _owner Address of the owner
    /// @param _reqId Request id that you want to check
    /// @return isVoted Whether the owner voted

    function isOwnerVoted(address _owner, uint256 _reqId) public view returns (bool isVoted) {
        return requests[_reqId].voters[_owner];
    }

    /// @notice requiredVotesForConsensus
    /// @dev Allows users to see how many votes are needed to reach consensus.
    /// @return votesForConsensus The number of votes required to reach a consensus

    function requiredVotesForConsensus() public view returns (uint256 votesForConsensus) {
        return Math.ceilDiv((totalVotes() * consensusRatio), 100);
    }

    /// @notice getRequestIdsByExecution
    /// @dev Allows users to see the array of request ids filtered by execution
    /// @param _isExecuted Whether the request was executed or not
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByExecution(
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if (requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if (!requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByOwner
    /// @dev Allows users to see the array of request ids filtered by owner address
    /// @param _owner The address of owner
    /// @param _isExecuted If you want to see only for that have not been executed, input this argument into true
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByOwner(
        address _owner,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requester == _owner) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requester == _owner) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByType
    /// @dev Allows users to see the array of request ids filtered by request type
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByType(
        RequestTypes _requestType,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requestType == _requestType) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requestType == _requestType) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getLastRequestNo
    /// @dev Allows users to get the last request number
    /// @return requestNo The last request number

    function getLastRequestNo() public view returns (uint256 requestNo) {
        return requests.length - 1;
    }

    /// @notice _withdraw
    /// @dev Withdraw Ethers from the wallet
    /// @param _value Withdraw amount
    /// @param _to Withdrawal recipient

    function _withdraw(uint256 _value, address _to) private {
        /// @custom:error (NE4) - Insufficient balance
        require(_value <= address(this).balance, 'NE4');
        (bool withdrawn, ) = payable(_to).call{ value: _value }('');

        /// @custom:error (SE5) - Address: unable to send value, recipient may have reverted
        require(withdrawn, 'SE5');
    }

    /// @notice _addOwner
    /// @dev Add a new Owner to the wallet
    /// @param _newAccount New owner account to be added

    function _addOwner(OwnerAccount memory _newAccount) private notOwner(_newAccount.addr) isValidAddress(_newAccount.addr) {
        OwnerVotes vote = _newAccount.vote;
        ownerVote[_newAccount.addr] = vote;
        ownerCounter[vote]++;
    }

    /// @notice _removeOwner
    /// @dev Remove existing owner form the wallet
    /// @param _removalAccount Current owner account to be removed

    function _removeOwner(OwnerAccount memory _removalAccount) private isOwnerAccount(_removalAccount) {
        ownerCounter[_removalAccount.vote]--;
        _checkMinConsensus();
        delete ownerVote[_removalAccount.addr];
    }

    /// @notice _changeOwner
    /// @dev Allows changing the existing owner to the new one. It also includes the functionality to change the existing owner's level
    /// @param _currentAccount Current owner account to be changed
    /// @param _newAccount New owner account to be applied

    function _changeOwner(OwnerAccount memory _currentAccount, OwnerAccount memory _newAccount) private {
        OwnerVotes _currentVote = _currentAccount.vote;
        OwnerVotes _newVote = _newAccount.vote;
        ownerCounter[_currentVote]--;
        ownerCounter[_newVote]++;
        _checkMinConsensus();

        if (_currentAccount.addr != _newAccount.addr) {
            delete ownerVote[_currentAccount.addr];
        }
        ownerVote[_newAccount.addr] = _newVote;
    }

    /// @notice _checkMinConsensus
    /// @dev It is the verification function to prevent a dangerous situation in which the number of votes that an owner has
    /// @dev is equal to or greater than the number of votes required for reaching consensus so that the owner achieves consensus by himself or herself.

    function _checkMinConsensus() private view {
        /// @custom:error (NE5) - Violate min limit for consensus
        require(requiredVotesForConsensus() >= minLimitForConsensus, 'NE5');
    }

    function _compactUintArray(uint256[] memory targetArray, uint256 length) internal pure returns (uint256[] memory array) {
        uint256[] memory compactArray = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            compactArray[i] = targetArray[i];
        }
        return compactArray;
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