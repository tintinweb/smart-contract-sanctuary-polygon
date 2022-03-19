/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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


interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}


contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


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


contract WWPRaffle is VRFConsumerBase {
    using SafeMath for uint256;

    address public admin;
    uint256 public rafflesCount;

    enum Status {
        Active,
        Drawing,
        Claimable,
        Claimed
    }

    struct Ticket {
        address owner;
        bool claimed;
        uint256 number;
        uint256 prize;
        uint256 createdAt;
    }

    struct Raffle {
        Status status;
        string name;
        uint256 startDate;
        uint256 ticketsGoal;
        uint256 ticketPrice;
        uint256 prizeBalance;
        uint256[] prizesPercentage;
        uint256 endDate;
        uint256 claimingGracePeriod;
        address prizeTokenAddress;
        Ticket[] tickets;
        Ticket[] drawnTickets;
        Ticket[] rerolledTickets;
        Ticket lastDrawnTicket;
        uint256 totalClaimedRewards;
    }

    mapping(uint256 => Raffle) private raffles;
    mapping(bytes32 => uint256) private raffleRandomnessRequest;

    bytes32 private keyHash;
    uint256 private fee;

    event RaffleCreated(uint256 id, string name);
    event TicketsCreated(
        uint256 id,
        string name,
        address receiver,
        uint256 amount,
        uint256 price
    );
    event DrawingTicket(uint256 id, string name, bytes32 requestId);
    event TicketDrawn(
        uint256 id,
        string name,
        uint256 ticketId,
        address ticketOwner,
        uint256 ticketPrize,
        uint256 randomness
    );
    event PrizeClaimed(
        uint256 id,
        string name,
        address ticketOwner,
        uint256 ticketPrize
    );
    event TicketReroll(
        uint256 id,
        string name,
        address ticketOwner,
        uint256 ticketPrize,
        uint256 ticketId
    );
    event RaffleClaimed(uint256 id, string name);
    event Donation(address from, uint256 amount);

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyhash;
        fee = _fee;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the owner");
        _;
    }

    modifier onlyActive(uint256 _raffleIdx) {
        require(
            raffles[_raffleIdx].status == Status.Active,
            "The raffle already finished"
        );
        _;
    }

    modifier whenNotDrawing(uint256 _raffleIdx) {
        require(
            raffles[_raffleIdx].status != Status.Drawing,
            "A raffle ticket is being drawn"
        );
        _;
    }

    modifier onlyClaimable(uint256 _raffleIdx) {
        require(
            raffles[_raffleIdx].status == Status.Claimable,
            "The raffle not claimable yet"
        );
        _;
    }

    modifier whenNotClaimed(uint256 _raffleIdx) {
        require(
            raffles[_raffleIdx].status != Status.Claimed,
            "Raffle already claimed"
        );
        _;
    }

    modifier whenRaffleExists(uint256 _raffleIdx) {
        require(_raffleIdx < rafflesCount, "Requested raffle dose not exist");
        _;
    }

    /* ADMIN */
    function createRaffle(
        string memory _name,
        uint256 _ticketsGoal,
        uint256 _ticketPrice,
        uint256[] memory _prizesPercentage,
        uint256 _endAfterSeconds,
        uint256 _claimingGracePeriod,
        address _prizeTokenAddress
    ) public onlyAdmin {
        require(
            _prizesPercentage.length == 2,
            "Provide exactly two percentages"
        );
        Raffle storage raffle = raffles[rafflesCount];
        raffle.status = Status.Active;
        raffle.name = _name;
        raffle.startDate = block.timestamp;
        raffle.ticketsGoal = _ticketsGoal;
        raffle.ticketPrice = _ticketPrice;
        raffle.prizeTokenAddress = _prizeTokenAddress;
        raffle.prizesPercentage = _prizesPercentage;
        raffle.endDate = block.timestamp + _endAfterSeconds;
        raffle.claimingGracePeriod = _claimingGracePeriod;
        emit RaffleCreated(rafflesCount, raffle.name);
        rafflesCount++;
    }

    function withdrawDonations() public onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    function reactivateRaffle(uint256 _raffleIdx)
        public
        onlyAdmin
        whenRaffleExists(_raffleIdx)
    {
        raffles[_raffleIdx].status = Status.Active;
    }

    function withdrawLink() public onlyAdmin {
        LINK.transfer(admin, LINK.balanceOf(address(this)));
    }

    /* PUBLIC */
    function donate() public payable {
        emit Donation(msg.sender, msg.value);
    }

    function getRaffle(uint256 _raffleIdx)
        public
        view
        whenRaffleExists(_raffleIdx)
        returns (Raffle memory)
    {
        return raffles[_raffleIdx];
    }

    function getTicketsCount(uint256 _raffleIdx)
        public
        view
        whenRaffleExists(_raffleIdx)
        returns (uint256)
    {
        return
            raffles[_raffleIdx].tickets.length +
            raffles[_raffleIdx].drawnTickets.length +
            raffles[_raffleIdx].rerolledTickets.length;
    }

    function attemptFinishing(uint256 _raffleIdx)
        public
        whenRaffleExists(_raffleIdx)
        onlyActive(_raffleIdx)
    {
        if (getTicketsCount(_raffleIdx) == raffles[_raffleIdx].ticketsGoal) {
            _drawTicket(_raffleIdx);
        } else if (raffles[_raffleIdx].endDate <= block.timestamp) {
            _drawTicket(_raffleIdx);
        }
    }

    function winningTicketsOf(uint256 _raffleIdx)
        public
        view
        whenRaffleExists(_raffleIdx)
        returns (Ticket[] memory)
    {
        return raffles[_raffleIdx].drawnTickets;
    }

    function buyTicket(uint256 _raffleIdx, uint256 _amount)
        public
        payable
        whenRaffleExists(_raffleIdx)
        onlyActive(_raffleIdx)
    {
        require(_amount >= 1, "Can not buy less than one ticket");
        require(
            _amount <=
                raffles[_raffleIdx].ticketsGoal.sub(
                    getTicketsCount(_raffleIdx)
                ),
            "Insufficient tickets available"
        );
        uint256 totalPrice = raffles[_raffleIdx].ticketPrice.mul(_amount);
        require(
            IERC20(raffles[_raffleIdx].prizeTokenAddress).balanceOf(
                msg.sender
            ) >= totalPrice,
            "Not enough tokens/coins"
        );
        IERC20(raffles[_raffleIdx].prizeTokenAddress).transferFrom(
            msg.sender,
            address(this),
            totalPrice
        );

        Raffle storage raffle = raffles[_raffleIdx];
        raffle.prizeBalance += totalPrice;
        for (uint256 i = 0; i < _amount; i++) {
            raffle.tickets.push(
                Ticket(
                    msg.sender,
                    false,
                    getTicketsCount(_raffleIdx) + 1,
                    0,
                    block.timestamp
                )
            );
        }
        emit TicketsCreated(
            _raffleIdx,
            raffle.name,
            msg.sender,
            _amount,
            totalPrice
        );
        attemptFinishing(_raffleIdx);
    }

    function claimReward(uint256 _raffleIdx)
        public
        whenNotClaimed(_raffleIdx)
        onlyClaimable(_raffleIdx)
        whenNotDrawing(_raffleIdx)
    {
        Raffle storage raffle = raffles[_raffleIdx];

        require(raffle.drawnTickets.length > 0, "No winning tickets drawn yet");

        Ticket storage ticket = raffle.lastDrawnTicket;

        require(ticket.owner == msg.sender, "Caller is not the ticket owner");
        require(ticket.claimed == false, "Ticket prize already claimed");

        _sendReward(_raffleIdx, ticket.prize);

        if (raffle.drawnTickets.length == 3) {
            raffle.status = Status.Claimed;
            delete raffle.lastDrawnTicket;
            emit RaffleClaimed(_raffleIdx, raffle.name);
        } else {
            _drawTicket(_raffleIdx);
        }
    }

    function rerollLastDrawnTicket(uint256 _raffleIdx)
        public
        whenNotClaimed(_raffleIdx)
        onlyClaimable(_raffleIdx)
        whenNotDrawing(_raffleIdx)
    {
        Raffle storage raffle = raffles[_raffleIdx];
        require(
            raffle.endDate + raffle.claimingGracePeriod <= block.timestamp,
            "Ticket claiming period not passed"
        );

        emit TicketReroll(
            _raffleIdx,
            raffle.name,
            raffle.lastDrawnTicket.owner,
            raffle.lastDrawnTicket.number,
            raffle.lastDrawnTicket.prize
        );

        raffle.rerolledTickets.push(raffle.lastDrawnTicket);
        delete raffle.lastDrawnTicket;
        raffle.drawnTickets.pop();

        _drawTicket(_raffleIdx);
    }

    /* PRIVATE */
    function _drawTicket(uint256 _raffleIdx) private {
        require(
            raffles[_raffleIdx].tickets.length > 0,
            "No tickets found for this raffle"
        );
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, fee);
        raffleRandomnessRequest[requestId] = _raffleIdx;
        raffles[_raffleIdx].status = Status.Drawing;
        emit DrawingTicket(_raffleIdx, raffles[_raffleIdx].name, requestId);
    }

    function _sendReward(uint256 _raffleIdx, uint256 _prize) private {
        Raffle storage raffle = raffles[_raffleIdx];
        Ticket storage ticket = raffle.lastDrawnTicket;

        ticket.claimed = true;
        raffle.drawnTickets[raffle.drawnTickets.length - 1].claimed = true;

        raffle.totalClaimedRewards += _prize;
        raffle.prizeBalance -= _prize;

        IERC20(raffle.prizeTokenAddress).transfer(ticket.owner, _prize);
        emit PrizeClaimed(_raffleIdx, raffle.name, ticket.owner, _prize);
    }

    /* INTERNAL OVERRIDE */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
        whenNotClaimed(raffleRandomnessRequest[requestId])
    {
        uint256 _raffleIdx = raffleRandomnessRequest[requestId];
        Raffle storage raffle = raffles[_raffleIdx];
        uint256 drawnTicketId = randomness.mod(raffle.tickets.length);

        raffle.status = Status.Claimable;

        Ticket memory drawnTicket = raffle.tickets[drawnTicketId];

        if (raffle.drawnTickets.length == 0) {
            uint256 firstWinnerPrize = raffle
                .prizeBalance
                .mul(raffle.prizesPercentage[0])
                .div(100);
            drawnTicket.prize = firstWinnerPrize;
        } else if (raffle.drawnTickets.length == 1) {
            uint256 secondWinnerPrize = raffle
                .prizeBalance
                .mul(raffle.prizesPercentage[1])
                .div(100);
            drawnTicket.prize = secondWinnerPrize;
        } else if (raffle.drawnTickets.length == 2) {
            drawnTicket.prize = raffle.prizeBalance;
        }

        raffle.lastDrawnTicket = drawnTicket;
        raffle.drawnTickets.push(drawnTicket);

        Ticket memory lastTicket = raffle.tickets[raffle.tickets.length - 1];
        raffle.tickets[drawnTicketId] = lastTicket;
        raffle.tickets[raffle.tickets.length - 1] = drawnTicket;
        raffle.tickets.pop();

        raffle.endDate = block.timestamp;
        delete raffleRandomnessRequest[requestId];
        emit TicketDrawn(
            _raffleIdx,
            raffle.name,
            drawnTicket.number,
            drawnTicket.owner,
            drawnTicket.prize,
            randomness
        );
    }
}