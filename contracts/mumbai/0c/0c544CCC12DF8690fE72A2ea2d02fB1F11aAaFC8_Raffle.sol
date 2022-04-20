// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "VRFConsumerBase.sol";
import "IERC20.sol";
import "Ownable.sol";

/// A `Raffle` is a smart contract that represents a ticketed lottery,
/// where participants can buy tickets at a given fixed price.
/// Each sold ticket has the same probabilities of being picked as winner,
/// therefore, buying more tickets increments the odds of winning the prize.
/// The prize is calculated based on the amount collected by sold tickets,
/// minus some predefined percentage, considered profits, that goes to a specific
/// beneficiary address, that is configured when creating the contract.
/// When the raffle is closed, the contract automatically picks a winner ticket
/// at random. Randomness is obtained by relying on a Chainlink's VRF node.
/// Once a winner ticket is picked, the buyer address of that ticket can
/// redeem the prize by calling a function on this smart contract.
/// This raffle works with a specific ERC-20 token that is determined when
/// deploying the contract. All amounts will be expressed in terms of such
/// token, using the number of decimals that the token specifies.
contract Raffle is VRFConsumerBase, Ownable {
    /// The amount of tokens that it costs to buy one ticket.
    uint256 public ticketPrice;

    /// The minimum ticket number (e.g. 1)
    uint256 public ticketMinNumber;

    /// The maximum ticket number (e.g. 200)
    uint256 public ticketMaxNumber;

    /// The address of the ERC-20 token contract which is used as currency for the raffle.
    address public tokenAddress;

    /// The address that can claim the collected profits from this raffle.
    address public beneficiaryAddress;

    /// A number between 0 and 100 that determines how much percentage
    /// of the gathered amount from the sold tickets goes to profits,
    /// and how much goes to the winner prize.
    /// For instance, for a `profitFactor` of 15, it means that 15% of the sales
    /// will be considered profits and can be claimed by `beneficiaryAddress`,
    /// whereas the remaining 85% goes to the prize and can be claimed
    /// by the winner of the raffle.
    uint8 public profitFactor;

    /// The current state of the raffle.
    /// 0 = `created` -> Default state when contract is deployed. Raffle is defined but tickets are not on sale yet.
    /// 1 = `sellingTickets` -> The raffle is open. Users can buy tickets.
    /// 2 = `salesFinished` -> The raffle is closed. Users can no longer buy tickets.
    /// 3 = `calculatingWinner` -> A draw is occurring. The contract is calculating a winner.
    /// 4 = `cancelled` -> The raffle has been cancelled for some reason. Users can claim refunds for any tickets they have bought.
    /// 5 = `finished` -> The raffle has finished and there is a winner. The winner can redeem the prize.
    enum RaffleState {
        created,
        sellingTickets,
        salesFinished,
        calculatingWinner,
        cancelled,
        finished
    }
    RaffleState public currentState = RaffleState.created;

    /// Maps each ticket number to the address that bought that ticket.
    mapping(uint256 => address) public ticketAddress;

    /// Maps each address to the total amount spent in tickets by that address.
    mapping(address => uint256) public addressSpentAmount;

    /// The list of ticket numbers that have been sold.
    /// They are stored in the order that they were sold.
    uint256[] public soldTickets;

    /// A value that identifies unequivocally the Chainlink's VRF node.
    bytes32 public vrfKeyHash;

    /// The amount of LINK required as gas to get a random number from Chainlink's VRF, with 18 decimals.
    uint256 public vrfLinkFee;

    /// The address of the LINK token used to pay for VRF randomness requests.
    address public vrfLinkToken;

    /// The random number that was obtained from Chainlink's VRF.
    /// -1 if random number has not been obtained yet.
    int256 public obtainedRandomNumber = -1;

    /// The winner ticket number that was picked.
    /// -1 if winner ticket has not been picked yet.
    int256 public winnerTicketNumber = -1;

    /// The address that bought the winner ticket, who can claim the prize.
    address public winnerAddress;

    /// Whether or not the prize has been transferred to the winner.
    bool public prizeTransferred;

    /// Whether or not the profits have been transferred to the beneficiary.
    bool public profitsTransferred;

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    /// Triggered when this contract requests a random number from Chainlink's VRF.
    event RequestedRandomness(bytes32 requestId);

    /// Triggered when the tickets sale is opened.
    event OpenedTicketsSale();

    /// Triggered when the tickets sale is closed.
    event ClosedTicketsSale();

    /// Triggered when a ticket is sold.
    event TicketSold(address buyer, uint256 ticketNumber);

    /// Triggered when the contract has picked a winner.
    event ObtainedWinner(address winnerAddress, uint256 winnerTicketNumber);

    /// Triggered when prize funds have been transferred to the winner.
    event PrizeTransferred(address recipient, uint256 amount);

    /// Triggered when profits have been transferred to the beneficiary.
    event ProfitsTransferred(address recipient, uint256 amount);

    /// Triggered when a refund has been transferred to the claimer.
    event RefundsTransferred(address recipient, uint256 amount);

    /// Triggered when the raffle is cancelled by the owner.
    event RaffleCancelled();

    ////////////////////////////////////////////////////////////
    // PUBLIC FUNCTIONS
    ////////////////////////////////////////////////////////////

    /// Buys a ticket for the caller, specified by `_ticketNumber`.
    function buyTicket(uint256 _ticketNumber)
        public
        onlyWhenAt(RaffleState.sellingTickets)
    {
        address buyer = msg.sender;
        require(
            _ticketNumber >= ticketMinNumber &&
                _ticketNumber <= ticketMaxNumber,
            "Invalid ticket number"
        );
        require(
            ticketAddress[_ticketNumber] == address(0),
            "Ticket number not available"
        );
        require(
            IERC20(tokenAddress).balanceOf(buyer) >= ticketPrice,
            "This address doesn't have enough balance to buy a ticket"
        );
        IERC20(tokenAddress).transferFrom(buyer, address(this), ticketPrice);
        ticketAddress[_ticketNumber] = buyer;
        addressSpentAmount[buyer] += ticketPrice;
        soldTickets.push(_ticketNumber);
        emit TicketSold(buyer, _ticketNumber);
    }

    /// Returns the current amount of tokens that the winner will obtain
    /// from this raffle.
    function getCurrentPrizeAmount() public view returns (uint256) {
        return getTotalAccumulatedAmount() - getCurrentProfitsAmount();
    }

    /// Returns the current amount of tokens that the beneficiary will obtain
    /// from this raffle in the concept of profit.
    function getCurrentProfitsAmount() public view returns (uint256) {
        return (getTotalAccumulatedAmount() * profitFactor) / 100;
    }

    /// Returns the total accumulated amounts provided by sold tickets.
    function getTotalAccumulatedAmount() public view returns (uint256) {
        return soldTickets.length * ticketPrice;
    }

    /// Returns the amount that can be returned in refunds to the caller.
    /// Refunds are only available if the caller has bought tickets and
    /// the raffle got cancelled.
    function getRefundableAmount() public view returns (uint256) {
        if (currentState != RaffleState.cancelled) {
            return 0;
        }
        return addressSpentAmount[msg.sender];
    }

    /// Claims refunds. If the caller has bought tickets and
    /// the raffle got cancelled, the total amount they spent will be
    /// returned to their account when executing this transaction.
    function claimRefunds() public {
        address recipient = msg.sender;
        uint256 amount = getRefundableAmount();
        require(amount > 0, "This address doesn't have a refundable amount");
        IERC20(tokenAddress).transfer(recipient, amount);
        addressSpentAmount[recipient] = 0;
        emit RefundsTransferred(recipient, amount);
    }

    ////////////////////////////////////////////////////////////
    // WINNER
    ////////////////////////////////////////////////////////////

    /// Redeems the raffle prize. If the caller has won the raffle,
    /// the prize amount will get transferred to their address.
    function redeemPrize()
        public
        onlyWinner
        onlyWhenAt(RaffleState.finished)
        onlyIfPrizeNotYetTransferred
    {
        address recipient = msg.sender;
        uint256 amount = getCurrentPrizeAmount();
        IERC20(tokenAddress).transfer(recipient, amount);
        prizeTransferred = true;
        emit PrizeTransferred(recipient, amount);
    }

    ////////////////////////////////////////////////////////////
    // BENEFICIARY
    ////////////////////////////////////////////////////////////

    function claimProfits()
        public
        onlyBeneficiary
        onlyWhenAt(RaffleState.finished)
        onlyIfProfitsNotYetTransferred
    {
        address recipient = msg.sender;
        uint256 amount = getCurrentProfitsAmount();
        IERC20(tokenAddress).transfer(recipient, amount);
        profitsTransferred = true;
        emit ProfitsTransferred(recipient, amount);
    }

    ////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////

    constructor(
        address _tokenAddress,
        uint256 _ticketPrice,
        uint256 _ticketMinNumber,
        uint256 _ticketMaxNumber,
        uint8 _profitFactor,
        address _beneficiaryAddress,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash,
        uint256 _vrfLinkFee,
        address _vrfLinkToken
    ) VRFConsumerBase(_vrfCoordinator, _vrfLinkToken) {
        require(
            _ticketMinNumber <= _ticketMaxNumber,
            "_ticketMaxNumber must be greater than _ticketMinNumber"
        );
        require(
            _profitFactor >= 0 && _profitFactor <= 100,
            "_profitFactor must be between 0 and 100"
        );
        tokenAddress = _tokenAddress;
        ticketPrice = _ticketPrice;
        ticketMinNumber = _ticketMinNumber;
        ticketMaxNumber = _ticketMaxNumber;
        profitFactor = _profitFactor;
        beneficiaryAddress = _beneficiaryAddress;
        vrfKeyHash = _vrfKeyHash;
        vrfLinkFee = _vrfLinkFee;
        vrfLinkToken = _vrfLinkToken;
    }

    /// Opens the raffle so participants can start buying tickets.
    function openTicketsSale()
        public
        onlyOwner
        onlyWhenAt(RaffleState.created)
    {
        currentState = RaffleState.sellingTickets;
        emit OpenedTicketsSale();
    }

    /// Closes the raffle so participants cannot buy any more tickets.
    function closeTicketsSale()
        public
        onlyOwner
        onlyWhenAt(RaffleState.sellingTickets)
    {
        currentState = RaffleState.salesFinished;
        emit ClosedTicketsSale();
    }

    /// Closes the raffle so participants cannot buy any more tickets,
    /// and also starts calcuilating a winner.
    function closeTicketsSaleAndPickWinner()
        public
        onlyOwner
        onlyWhenAt(RaffleState.sellingTickets)
    {
        closeTicketsSale();
        pickWinner();
    }

    /// Starts calculating a winner.
    function pickWinner()
        public
        onlyOwner
        onlyWhenAt(RaffleState.salesFinished)
    {
        currentState = RaffleState.calculatingWinner;
        _requestRandomNumberToPickWinner();
    }

    /// Cancels the raffle.
    function cancelRaffle()
        public
        onlyOwner
        onlyBefore(RaffleState.calculatingWinner)
    {
        currentState = RaffleState.cancelled;
        emit RaffleCancelled();
    }

    ////////////////////////////////////////////////////////////
    // Private / Internal
    ////////////////////////////////////////////////////////////

    /// Requests a random number from Chainlink's VRF in order to pick the winner ticket.
    function _requestRandomNumberToPickWinner() private returns (uint256) {
        require(
            IERC20(vrfLinkToken).balanceOf(address(this)) >= vrfLinkFee,
            "This contract doesn't have enough LINK to request randomness from Chainlink's VRF"
        );
        // We'll connect to the Chainlink VRF Node
        // using the "Request and Receive" cycle model

        // R&R -> 2 transactions:
        // 1) Request the data from the Chainlink Oracle through a function (requestRandomness)
        // 2) Callback transaction -> Chainlink node returns data to the contract into another function (fulfillRandomness)

        // requestRandomness function is provided by VRFConsumerBase parent class
        bytes32 requestId = requestRandomness(vrfKeyHash, vrfLinkFee);

        // We emit the following event to be able to retrieve the requestId in the tests.
        // Also, events work as logs for the contract.
        emit RequestedRandomness(requestId);
    }

    // We need to override fulfillRandomness from VRFConsumerBase in order to retrieve the random number.
    // This function will be called for us by the VRFCoordinator (that's why it's internal).
    // This function works asynchronously.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            currentState == RaffleState.calculatingWinner,
            "Raffle is not calculating winners yet"
        );
        require(_randomness > 0, "Random number not found");

        obtainedRandomNumber = int256(_randomness);

        uint256 winnerTicketIndex = _randomness % soldTickets.length;
        winnerTicketNumber = int256(soldTickets[winnerTicketIndex]);
        winnerAddress = ticketAddress[uint256(winnerTicketNumber)];
        require(winnerAddress != address(0), "Cannot find a winner");

        currentState = RaffleState.finished;
        emit ObtainedWinner(winnerAddress, uint256(winnerTicketNumber));
    }

    modifier onlyWhenAt(RaffleState _state) {
        require(currentState == _state, "Invalid state");
        _;
    }

    modifier onlyBefore(RaffleState _state) {
        require(currentState < _state, "Invalid state");
        _;
    }

    modifier onlyWinner() {
        require(
            msg.sender == winnerAddress,
            "Only the raffle winner can execute this function"
        );
        _;
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiaryAddress,
            "Only the raffle beneficiary can execute this function"
        );
        _;
    }

    modifier onlyIfPrizeNotYetTransferred() {
        require(
            prizeTransferred == false,
            "The prize has already been transferred"
        );
        _;
    }

    modifier onlyIfProfitsNotYetTransferred() {
        require(
            profitsTransferred == false,
            "Profits have already been transferred"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

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
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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