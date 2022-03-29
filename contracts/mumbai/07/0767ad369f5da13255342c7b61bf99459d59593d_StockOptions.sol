//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Types.sol";
import "./interfaces/ICertificate.sol";
import "./libraries/VestingCalculator.sol";
import "./libraries/TokenPools.sol";
import "./libraries/Participants.sol";
import "./libraries/Claims.sol";
import "./libraries/Admins.sol";
import "./libraries/AddressArray.sol";
import "./libraries/Balances.sol";
import "./libraries/Intervals.sol";

/// @title Stock options token pool contract
contract StockOptions is ReentrancyGuardUpgradeable {
  /**
   * @notice Token pool created event
   * @param id Token pool identifier
   */
  event TokenPoolCreated(uint256 id);

  /**
   * @notice Admin added event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the admin
   */
  event AdminAdded(uint256 tokenPoolId, address _address);

  /**
   * @notice Admin removed event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the admin
   */
  event AdminRemoved(uint256 tokenPoolId, address _address);

  /**
   * @notice Participant created event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the new participant
   * @param issueDate Issue date of the vesting plan as timestamps
   * @param tokenAmount Token amount to be vested
   * @param intervals Vesting intervals
   * @param certificateId NFT certificate ID
   */
  event ParticipantCreated(
    uint256 tokenPoolId,
    address indexed _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] intervals,
    uint256 certificateId
  );

  /**
   * Participant removed
   * @notice Participant removed from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantRemoved(uint256 tokenPoolId, address indexed _address);

  /**
   * Participant removed
   * @notice Participant removed from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param tokensTransfered Tokens transfered to the participant
   * @param tokensReverted Tokens revered back
   */
  event ParticipantTerminated(
    uint256 tokenPoolId,
    address indexed _address,
    uint256 tokensTransfered,
    uint256 tokensReverted
  );

  /**
   * @notice Participant vesting paused event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantVestingPaused(uint256 tokenPoolId, address _address);

  /**
   * @notice Participant vesting unpaused event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantVestingUnPaused(uint256 tokenPoolId, address _address);

  /**
   * @notice Tokens claimed by participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param amount Token amount that was claimed
   */
  event TokensClaimed(
    uint256 tokenPoolId,
    address indexed _address,
    uint256 amount
  );

  mapping(uint256 => TokenPools.TokenPool) private tokenPools;
  mapping(uint256 => mapping(address => Participants.Participant))
    private participants;
  mapping(uint256 => address[]) private registerAddresses;
  mapping(address => Claims.Claim[]) private claims;
  mapping(uint256 => mapping(address => bool)) private admins;
  mapping(uint256 => mapping(address => uint256)) private balances;

  ICertificate certificate;

  using TokenPools for TokenPools.TokenPool;
  using Participants for Participants.Participant;
  using Intervals for Intervals.Interval;
  using Claims for mapping(address => Claims.Claim[]);
  using Admins for mapping(uint256 => mapping(address => bool));
  // using SafeERC20Upgradeable for Token;
  using AddressArray for address[];
  using Balances for mapping(address => uint256);

  using SafeMath for uint256;

  modifier onlyAdmin(uint256 tokenPoolId) {
    require(admins.has(tokenPoolId, msg.sender), "Unauthorized");
    _;
  }

  function initialize(ICertificate _certificate) public initializer {
    certificate = _certificate;
    __ReentrancyGuard_init();
  }

  /**
   * @notice Create a new token pool
   * @param tokenPoolId Token pool ID
   * @param name Name of the token
   * @param description Symbol of the token
   * @param amount Token amount
   */
  function createTokenPool(
    uint256 tokenPoolId,
    string memory name,
    string memory description,
    uint256 amount
  ) external nonReentrant {
    require(
      !tokenPools[tokenPoolId].exists,
      "Token pool with provided ID already exists"
    );

    tokenPools[tokenPoolId] = TokenPools.TokenPool({
      name: name,
      description: description,
      tokens: amount,
      reservedTokens: 0,
      claimedTokens: 0,
      exists: true
    });

    balances[tokenPoolId].mint(address(this), amount);

    admins.add(tokenPoolId, msg.sender);

    emit TokenPoolCreated(tokenPoolId);
  }

  /**
   * @notice Get token pool data
   * @param tokenPoolId Token pool identifier
   * @return name Token pool name
   * @return description Token pool description
   * @return tokens Token total supply
   * @return reservedTokens Reserved tokens
   * @return claimedTokens Claimed tokens
   */
  function getTokenPool(uint256 tokenPoolId)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (
      string memory name,
      string memory description,
      uint256 tokens,
      uint256 reservedTokens,
      uint256 claimedTokens
    )
  {
    return (
      tokenPools[tokenPoolId].name,
      tokenPools[tokenPoolId].description,
      tokenPools[tokenPoolId].tokens,
      tokenPools[tokenPoolId].reservedTokens,
      tokenPools[tokenPoolId].claimedTokens
    );
  }

  /**
   * @notice Add admin
   * @param tokenPoolId Token pool identifier
   * @param _address Address of new admin
   */
  function addAdmin(uint256 tokenPoolId, address _address)
    external
    onlyAdmin(tokenPoolId)
  {
    admins.add(tokenPoolId, _address);
    emit AdminAdded(tokenPoolId, _address);
  }

  /**
   * @notice Remove admin
   * @param tokenPoolId Token pool identifier
   * @param _address Address of admin to remove
   */
  function removeAdmin(uint256 tokenPoolId, address _address)
    external
    onlyAdmin(tokenPoolId)
  {
    require(msg.sender != _address, "Can't remove yourself from admins");

    admins.remove(tokenPoolId, _address);
    emit AdminRemoved(tokenPoolId, _address);
  }

  /**
   * @notice Add participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param issueDate Date when vesting plan starts as timestamp
   * @param tokenAmount Token amount to be vested
   * @param intervals Vesting intervals
   * @param uri NFT URI
   */
  function addParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] memory intervals,
    string memory uri
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(
      tokenPools[tokenPoolId].areTokensAvailable(
        balances[tokenPoolId].balanceOf(address(this)),
        tokenAmount
      )
    );

    _addParticipant(
      tokenPoolId,
      _address,
      issueDate,
      tokenAmount,
      intervals,
      uri
    );
  }

  /**
   * @notice Add multiple participants
   * @param tokenPoolId Token pool identifiers as array
   * @param _addresses Addresses of the participants as array
   * @param issueDates Dates when vesting plan starts as timestamp in array
   * @param intervals Vesting intervals
   * @param certFileIds Certificate file IDs
   */
  function addParticipants(
    uint256 tokenPoolId,
    address[] memory _addresses,
    uint256[] memory issueDates,
    uint256[] memory tokenAmounts,
    Intervals.Interval[][] memory intervals,
    string[] memory certFileIds
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(
      _addresses.length == issueDates.length,
      "Not correct data passed in!"
    );
    require(
      _addresses.length == tokenAmounts.length,
      "Not correct data passed in!"
    );
    require(
      _addresses.length == intervals.length,
      "Not correct data passed in!"
    );
    require(
      _addresses.length == certFileIds.length,
      "Not correct data passed in!"
    );

    for (uint256 i = 0; i < _addresses.length; i++) {
      _addParticipant(
        tokenPoolId,
        _addresses[i],
        issueDates[i],
        tokenAmounts[i],
        intervals[i],
        certFileIds[i]
      );
    }
  }

  /**
   * @notice Remove participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  function removeParticipant(uint256 tokenPoolId, address _address)
    external
    nonReentrant
    onlyAdmin(tokenPoolId)
  {
    require(participants[tokenPoolId][_address].exists, "No participant");

    require(claims.getClaimedAmount(_address) == 0, "Claimed tokens");

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(participants[tokenPoolId][_address].tokenAmount);

    delete participants[tokenPoolId][_address];

    for (uint256 i = 0; i < registerAddresses[tokenPoolId].length - 1; i++) {
      if (registerAddresses[tokenPoolId][i] == _address) {
        registerAddresses[tokenPoolId] = registerAddresses[tokenPoolId].remove(
          i
        );
        break;
      }
    }

    emit ParticipantRemoved(tokenPoolId, _address);
  }

  /**
   * @notice Pause participant vesting plan
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param pauseDate Pause date as timestamp
   */
  function pauseParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 pauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(participants[tokenPoolId][_address].exists, "No participant");

    participants[tokenPoolId][_address].pause(pauseDate);

    emit ParticipantVestingPaused(tokenPoolId, _address);
  }

  /**
   * @notice Un-pause participant vesting plan
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param unPauseDate Unpause date as timestamp
   */
  function unPauseParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 unPauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(participants[tokenPoolId][_address].exists, "No participant");

    participants[tokenPoolId][_address].unPause(unPauseDate);

    emit ParticipantVestingUnPaused(tokenPoolId, _address);
  }

  /**
   * @notice Terminate participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param terminationDate Termination date as timestamp
   */
  function terminateParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 terminationDate
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(participants[tokenPoolId][_address].exists, "No participant");

    uint256 tokensToClaim;

    if (participants[tokenPoolId][_address].canClaim(terminationDate)) {
      // get tokens that can be vested with termination date
      uint256 claimableTokens = participants[tokenPoolId][_address]
        .getClaimableTokens(terminationDate);
      // get claimed tokens
      uint256 claimedTokens = claims.getClaimedAmount(_address);
      // calculate tokens that are claimable
      tokensToClaim = claimableTokens.sub(claimedTokens);
      if (tokensToClaim > 0) {
        _claimTokens(tokenPoolId, _address, terminationDate, tokensToClaim);
      }
    }

    uint256 tokensReverted = participants[tokenPoolId][_address].tokenAmount -
      claims.getClaimedAmount(_address);

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(tokensReverted);

    require(
      terminationDate > participants[tokenPoolId][_address].issueDate,
      "Issue date before termination date"
    );
    participants[tokenPoolId][_address].terminatedDate = terminationDate;

    emit ParticipantTerminated(
      tokenPoolId,
      _address,
      tokensToClaim,
      tokensReverted
    );
  }

  /**
   * @notice Get participant data
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @return ParticipantData structure
   */
  function getParticipant(uint256 tokenPoolId, address _address)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (ParticipantData memory)
  {
    require(participants[tokenPoolId][_address].exists, "No participant");

    return (
      ParticipantData(
        _address,
        participants[tokenPoolId][_address].issueDate,
        participants[tokenPoolId][_address].tokenAmount,
        participants[tokenPoolId][_address].terminatedDate,
        participants[tokenPoolId][_address].getIntervals(),
        participants[tokenPoolId][_address].claimedTokens
      )
    );
  }

  /**
   * @notice Get participants data
   * @param tokenPoolId Token pool identifier
   * @return participantsData Array of ParticipantData structure
   */
  function getParticipants(uint256 tokenPoolId)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (ParticipantData[] memory participantsData)
  {
    uint256 len = registerAddresses[tokenPoolId].length;
    ParticipantData[] memory _participants = new ParticipantData[](len);

    for (uint256 i = 0; i <= len - 1; i++) {
      address _address = registerAddresses[tokenPoolId][i];
      _participants[i] = ParticipantData(
        _address,
        participants[tokenPoolId][_address].issueDate,
        participants[tokenPoolId][_address].tokenAmount,
        participants[tokenPoolId][_address].terminatedDate,
        participants[tokenPoolId][_address].getIntervals(),
        participants[tokenPoolId][_address].claimedTokens
      );
    }

    return _participants;
  }

  /**
   * @notice Get tokens balance of the address
   * @param tokenPoolId Token pool identifier
   * @param _address Address
   * @return amount Current balance of the address
   */
  function balanceOf(uint256 tokenPoolId, address _address)
    external
    view
    returns (uint256 amount)
  {
    return balances[tokenPoolId].balanceOf(_address);
  }

  /**
   * @notice Get participant vesting schedule
   * @param tokenPoolId Token pool identifier
   * @return issueDate Issue date as timestamp
   * @return tokenAmount Token amount
   * @return terminatedDate Terminated date as timestamp
   * @return intervals Intervals
   * @return claimedTokens Claimed tokens
   * @return claimableTokens Claimable tokens
   */
  function getMyVestingSchedule(uint256 tokenPoolId)
    external
    view
    returns (
      uint256 issueDate,
      uint256 tokenAmount,
      uint256 terminatedDate,
      Intervals.Interval[] memory intervals,
      uint256 claimedTokens,
      uint256 claimableTokens
    )
  {
    require(participants[tokenPoolId][msg.sender].exists, "No participant");

    return (
      participants[tokenPoolId][msg.sender].issueDate,
      participants[tokenPoolId][msg.sender].tokenAmount,
      participants[tokenPoolId][msg.sender].terminatedDate,
      participants[tokenPoolId][msg.sender].getIntervals(),
      participants[tokenPoolId][msg.sender].claimedTokens,
      calculateClaimableTokens(tokenPoolId, msg.sender)
    );
  }

  /**
   * @notice Get participant claims
   * @param tokenPoolId Token pool identifier
   * @return date Dates of claims in array
   * @return amount Token amount claimed in array
   */
  function getMyClaims(uint256 tokenPoolId)
    external
    view
    returns (uint256[] memory date, uint256[] memory amount)
  {
    require(participants[tokenPoolId][msg.sender].exists, "No participant");

    uint256 len = claims[msg.sender].length;
    uint256[] memory _date = new uint256[](len);
    uint256[] memory _amount = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      _date[i] = claims[msg.sender][i].date;
      _amount[i] = claims[msg.sender][i].amount;
    }

    return (_date, _amount);
  }

  /**
   * @notice Claim tokens
   * @param tokenPoolId Token pool identifier
   * @param _uri New URI for the certificate
   */
  function claimTokens(uint256 tokenPoolId, string memory _uri)
    external
    nonReentrant
  {
    checkIfParticipantCanClaim(tokenPoolId);

    uint256 amount = calculateClaimableTokens(tokenPoolId, msg.sender);

    require(amount > 0, "Nothing to claim");

    require(
      participants[tokenPoolId][msg.sender].canClaim(block.timestamp),
      "Can not claim"
    );

    _claimTokens(tokenPoolId, msg.sender, block.timestamp, amount);
    setParticipantCertificate(tokenPoolId, msg.sender, _uri);
  }

  function _addParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] memory intervals,
    string memory uri
  ) private {
    uint256 certId = certificate.print(_address, uri);

    uint256 len = intervals.length;
    uint256[] memory intervalsEndDate = new uint256[](len);
    uint256[] memory intervalsAmount = new uint256[](len);
    bool[] memory intervalsClaimed = new bool[](len);

    for (uint256 i = 0; i < len; i++) {
      (
        intervalsEndDate[i],
        intervalsAmount[i],
        intervalsClaimed[i]
      ) = intervals[i].serialize();
    }

    participants[tokenPoolId][_address] = Participants.Participant({
      issueDate: issueDate,
      tokenAmount: tokenAmount,
      terminatedDate: 0,
      exists: true,
      intervalsEndDate: intervalsEndDate,
      intervalsAmount: intervalsAmount,
      intervalsClaimed: intervalsClaimed,
      lastPausedAt: 0,
      claimedTokens: 0,
      certificateId: certId
    });

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .add(tokenAmount);

    registerAddresses[tokenPoolId].push(_address);

    emit ParticipantCreated(
      tokenPoolId,
      _address,
      issueDate,
      tokenAmount,
      intervals,
      certId
    );
  }

  function calculateClaimableTokens(uint256 tokenPoolId, address _address)
    private
    view
    returns (uint256)
  {
    uint256 claimableTokens = participants[tokenPoolId][_address]
      .getClaimableTokens(block.timestamp);
    return claimableTokens.sub(claims.getClaimedAmount(_address));
  }

  function checkIfParticipantCanClaim(uint256 tokenPoolId) private view {
    require(participants[tokenPoolId][msg.sender].exists, "No participant");
    require(
      participants[tokenPoolId][msg.sender].terminatedDate == 0,
      "Participant Terminated"
    );
  }

  function _claimTokens(
    uint256 tokenPoolId,
    address _address,
    uint256 claimDate,
    uint256 amount
  ) private {
    participants[tokenPoolId][_address].claimedTokens = participants[
      tokenPoolId
    ][_address].claimedTokens.add(amount);

    tokenPools[tokenPoolId].claimedTokens = tokenPools[tokenPoolId]
      .claimedTokens
      .add(amount);

    claims[_address].push(Claims.Claim({date: claimDate, amount: amount}));

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(amount);

    balances[tokenPoolId].transfer(address(this), _address, amount);

    emit TokensClaimed(tokenPoolId, _address, amount);
  }

  function setParticipantCertificate(
    uint256 tokenPoolId,
    address _address,
    string memory _uri
  ) private {
    require(participants[tokenPoolId][_address].exists, "No participant");

    uint256 certificateId = participants[tokenPoolId][_address].certificateId;
    require(certificateId != 0, "No certificate");

    certificate.setUri(certificateId, _uri);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./libraries/Intervals.sol";

struct ParticipantData {
  address _address;
  uint256 issueDate;
  uint256 tokenAmount;
  uint256 terminatedDate;
  Intervals.Interval[] intervals;
  uint256 claimedTokens;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {IERC1155MetadataURIUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

interface ICertificate is IERC1155MetadataURIUpgradeable {
  function print(address to, string memory _uri) external returns (uint256);

  function setUri(uint256 id, string memory _uri) external;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Intervals.sol";

library VestingCalculator {
  using SafeMath for uint256;

  function calculateClaimableTokens(
    uint256 time,
    uint256 issueDate,
    Intervals.Interval[] memory intervals
  ) internal pure returns (uint256) {
    if (time <= issueDate) {
      return 0;
    }

    uint256 claimableTokens;

    for (uint256 i = 0; i < intervals.length; i++) {
      if (!intervals[i].claimed && intervals[i].endDate <= time) {
        claimableTokens = claimableTokens.add(intervals[i].amount);
      }
    }

    return claimableTokens;
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library TokenPools {
  using SafeMath for uint256;

  struct TokenPool {
    string name;
    string description;
    uint256 tokens;
    uint256 reservedTokens;
    uint256 claimedTokens;
    bool exists;
  }

  function areTokensAvailable(
    TokenPool storage self,
    uint256 balance,
    uint256 tokenAmount
  ) internal view returns (bool) {
    return balance.sub(self.reservedTokens) >= tokenAmount;
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./VestingCalculator.sol";
import "./Intervals.sol";

library Participants {
  using SafeMath for uint256;

  struct Participant {
    uint256 issueDate;
    // total tokens to be vested
    uint256 tokenAmount;
    // termination date as timestamp, if not specified then 0
    uint256 terminatedDate;
    // convenience for checking if a participant exists
    bool exists;
    // Interval end date
    uint256[] intervalsEndDate;
    // Interval token amount
    uint256[] intervalsAmount;
    // Interval has been claimed
    bool[] intervalsClaimed;
    // when was participant last paused as timestamp
    uint256 lastPausedAt;
    // claimed tokens total
    uint256 claimedTokens;
    // certificate id
    uint256 certificateId;
  }

  function getClaimableTokens(
    Participants.Participant storage self,
    uint256 claimDate
  ) internal view returns (uint256) {
    uint256 len = self.intervalsEndDate.length;
    Intervals.Interval[] memory intervals = new Intervals.Interval[](len);

    for (uint256 i = 0; i < len; i++) {
      intervals[i] = Intervals.Interval({
        endDate: self.intervalsEndDate[i],
        amount: self.intervalsAmount[i],
        claimed: self.intervalsClaimed[i]
      });
    }

    return
      VestingCalculator.calculateClaimableTokens(
        claimDate,
        self.issueDate,
        intervals
      );
  }

  function getIntervals(Participants.Participant storage self)
    internal
    view
    returns (Intervals.Interval[] memory)
  {
    uint256 len = self.intervalsEndDate.length;
    Intervals.Interval[] memory intervals = new Intervals.Interval[](len);

    for (uint256 i = 0; i < len; i++) {
      intervals[i] = Intervals.Interval({
        endDate: self.intervalsEndDate[i],
        amount: self.intervalsAmount[i],
        claimed: self.intervalsClaimed[i]
      });
    }

    return intervals;
  }

  function canClaim(Participants.Participant storage self, uint256 atDate)
    internal
    view
    returns (bool)
  {
    // Terminated participant's can't claim
    if (self.terminatedDate > 0) {
      return false;
    }

    // When paused can't claim when last paused is less than cliff period
    if (self.lastPausedAt > 0) {
      return false;
    }

    return atDate >= getIntervals(self)[0].endDate;
  }

  function pause(Participants.Participant storage self, uint256 pauseDate)
    internal
  {
    require(self.lastPausedAt == 0, "Already paused");
    self.lastPausedAt = pauseDate;
  }

  function unPause(Participants.Participant storage self, uint256 unpauseDate)
    internal
  {
    require(self.lastPausedAt > 0, "Not paused");

    uint256 pausedFor = unpauseDate.sub(self.lastPausedAt);

    uint256 len = self.intervalsEndDate.length;

    for (uint256 i; i < len; i++) {
      if (self.intervalsEndDate[i] >= self.lastPausedAt) {
        self.intervalsEndDate[i] = self.intervalsEndDate[i].add(pausedFor);
      }
    }

    self.lastPausedAt = 0;
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Claims {
  using SafeMath for uint256;

  struct Claim {
    uint256 date;
    uint256 amount;
  }

  function getClaimedAmount(
    mapping(address => Claims.Claim[]) storage self,
    address participantAddress
  ) internal view returns (uint256) {
    uint256 claimedAmount;

    for (uint32 i = 0; i < self[participantAddress].length; i++) {
      claimedAmount = claimedAmount.add(self[participantAddress][i].amount);
    }

    return claimedAmount;
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Admins {
  function add(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal {
    self[tokenPoolId][adminAddress] = true;
  }

  function remove(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal {
    self[tokenPoolId][adminAddress] = false;
  }

  function has(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal view returns (bool) {
    return self[tokenPoolId][adminAddress];
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library AddressArray {
  function remove(address[] storage self, uint256 index)
    internal
    returns (address[] memory)
  {
    if (index >= self.length) {
      return self;
    }

    for (uint256 i = index; i < self.length - 1; i++) {
      self[i] = self[i + 1];
    }
    self.pop();

    return self;
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Balances {
  using SafeMath for uint256;

  function balanceOf(mapping(address => uint256) storage self, address account)
    internal
    view
    returns (uint256)
  {
    return self[account];
  }

  function mint(
    mapping(address => uint256) storage self,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "mint to the zero address");

    self[account] = self[account].add(amount);
  }

  function transfer(
    mapping(address => uint256) storage self,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != address(0), "transfer from the zero address");
    require(to != address(0), "transfer to the zero address");

    uint256 fromBalance = self[from];
    require(fromBalance >= amount, "transfer amount exceeds balance");
    unchecked {
      self[from] = fromBalance.sub(amount);
    }
    self[to] = self[to].add(amount);
  }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Intervals {
  struct Interval {
    uint256 endDate;
    uint256 amount;
    bool claimed;
  }

  function serialize(Intervals.Interval memory self)
    internal
    pure
    returns (
      uint256 endDate,
      uint256 amount,
      bool claimed
    )
  {
    return (self.endDate, self.amount, self.claimed);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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