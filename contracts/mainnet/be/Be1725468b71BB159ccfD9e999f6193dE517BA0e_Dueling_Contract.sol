// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "VRFConsumerBase.sol";

contract Dueling_Contract is VRFConsumerBase, Ownable {
    // FORTUNA VARIABLES
    bool public duelingOpen = true;

    uint256 public duelFeeSolo = 994; // Fee of 0.6%
    uint256 public duelFeeDuo = 996; // Fee of 0.3%
    uint256 private safetyOffset = 99; // How many times more tokens needs to be in DAO_Supply to allow solo duel

    mapping(IERC20 => uint256) public DAO_Supply;
    mapping(IERC20 => uint256) public CLAIM_Supply;

    // DUELING VARIABLES
    mapping(address => address) private opponent;
    mapping(address => IERC20) private duelToken;
    mapping(address => uint256) private duelBalance;
    mapping(address => uint256) private duelClaim;
    mapping(address => int256) private vrfLinkBal; // needs to be greater than -10 to call VRF

    event DuelBaked(
        address indexed baker,
        IERC20 indexed token,
        uint256 indexed amount
    );

    event DuelAbandoned(
        address indexed baker,
        IERC20 indexed token,
        uint256 indexed amount
    );

    event DuelTaken(address indexed baker);

    // VRF RELATED VARIABLES
    uint256 private constant ROLL_IN_PROGRESS = 3;
    bytes32 private user_keyHash;
    uint256 private user_fee;

    mapping(bytes32 => address) private user_rollers;
    mapping(address => DUEL_OUTCOME) private user_results;
    mapping(address => uint256) private user_block_time;
    mapping(address => uint256) private user_random;

    //event DuelDecided(bytes32 indexed requestId, DUEL_OUTCOME indexed result);
    event DuelStarted(bytes32 indexed requestId, address indexed duelist);

    enum DUEL_OUTCOME {
        NOT_STARTED,
        WIN,
        LOSS,
        IN_ACTION,
        MAKER_WAITING,
        MAKER_TAKEN
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        user_keyHash = _keyhash;
        user_fee = _fee;
    }

    // ###################################################
    //                  DAO FUNCTIONS
    // ###################################################

    /**
     * @notice Set safety parameter
     * @param _value new value of safetyOffset
     */
    function set_safetyOffset(uint256 _value) external onlyOwner {
        require(_value > 2);
        require(_value < 200); // it's important to live a little
        safetyOffset = _value;
    }

    /**
     * @notice Set solo fee
     * @dev restricted to between 0 and 10%
     * @param _value new value of duelFeeSolo
     */
    function set_duelFeeSolo(uint256 _value) external onlyOwner {
        require(_value > 900);
        require(_value <= 1000);
        duelFeeSolo = _value;
    }

    /**
     * @notice Set duo fee
     * @dev restricted to between 0 and 10%
     * @param _value new value of duelFeeDuo
     */
    function set_duelFeeDuo(uint256 _value) external onlyOwner {
        require(_value > 900);
        require(_value <= 1000);
        duelFeeDuo = _value;
    }

    /**
     * @notice Close or open dueling
     * @param _value new value of duelingOpen
     */
    function set_duelingOpen(bool _value) external onlyOwner {
        duelingOpen = _value;
    }

    /**
     * @notice Transfer funds(ERC20) from contract
     * @dev require the DAO_Supply to be larger than the amount to prevent transfer of CLAIM_Supply tokens
     * @param _token token to be transfered
     * @param _amount amount to be transfered
     * @param _destination destination address
     */
    function transferFunds(
        IERC20 _token,
        uint256 _amount,
        address _destination
    ) external onlyOwner {
        require(DAO_Supply[_token] >= _amount);
        _token.transfer(_destination, _amount);
    }

    /**
     * @notice Donate funds(ERC20) to contract
     * @param _token token to be transfered
     * @param _amount amount to be transfered
     */
    function donateToPool(IERC20 _token, uint256 _amount) external {
        _token.transferFrom(msg.sender, address(this), _amount);
        DAO_Supply[_token] += _amount;
    }

    /**
     * @notice Updates the DAO to include all tokens not in CLAIM_Supply
     * @dev requires dueling to be closed as it can potentially steal duelBalance funds
     * @param _token token to update
     */
    function updateTotalTokenSupply(IERC20 _token) external {
        require(!duelingOpen);
        DAO_Supply[_token] =
            _token.balanceOf(address(this)) -
            CLAIM_Supply[_token];
    }

    /**
     * @notice Set fee for vrf call
     * @dev in case the fee is updated (or set wrong)
     * @param newFee new fee
     */
    function updateLinkFee(uint256 newFee) external {
        user_fee = newFee;
    }

    // ###################################################
    //                  DUEL GAME FUNCTIONS
    // ###################################################

    /**
     * @notice Updates claimable tokens won dueling
     * @dev requires user_result to be 0, 1 or 2
     * @param account address to update funds
     */
    modifier updateBloodMoney(address account) {
        require(
            user_results[account] != DUEL_OUTCOME.IN_ACTION,
            "Wait for duel to finish before claiming/dueling"
        );

        require(
            uint256(user_results[account]) < 3,
            "Withdraw from made duel or find a taker"
        );

        if (user_results[account] == DUEL_OUTCOME.WIN) {
            duelClaim[account] += duelBalance[account] * 2;
        }

        duelBalance[account] = 0;
        user_results[account] = DUEL_OUTCOME.NOT_STARTED;
        _;
    }

    /**
     * @notice Duel solo against DAO funds
     * @param _token token to duel for
     * @param _amount amount to duel
     */
    function duelFortuna(IERC20 _token, uint256 _amount)
        public
        updateBloodMoney(msg.sender)
    {
        require(duelingOpen, "It seems all new dueling is closed");
        require(_amount > 0);
        require(
            vrfLinkBal[msg.sender] > -10,
            "You require more vrf-tickets to play"
        );

        if (duelClaim[msg.sender] > 0) {
            require(duelToken[msg.sender] == _token);
        }

        require(
            DAO_Supply[_token] >= _amount * safetyOffset,
            "Too large stake for pool to handle"
        );

        vrfLinkBal[msg.sender] -= 1;

        _token.transferFrom(msg.sender, address(this), _amount);

        duelBalance[msg.sender] = (_amount * duelFeeSolo) / 1000;
        duelToken[msg.sender] = _token;
        DAO_Supply[_token] -= _amount;
        opponent[msg.sender] = address(this);

        duel(msg.sender);
    }

    /**
     * @notice Make (bake) a challenge for PvP
     * @param _token token to duel for
     * @param _amount amount to duel
     */
    function makeDuel(IERC20 _token, uint256 _amount)
        public
        updateBloodMoney(msg.sender)
    {
        require(duelingOpen, "It seems all dueling is closed");
        require(_amount > 0);
        require(
            vrfLinkBal[msg.sender] > -10,
            "You require more vrf-tickets to play"
        );
        require(
            duelBalance[msg.sender] == 0,
            "Finish or cancel current duel before making a new one"
        );

        vrfLinkBal[msg.sender] -= 1;
        _token.transferFrom(msg.sender, address(this), _amount);

        duelBalance[msg.sender] = _amount;
        duelToken[msg.sender] = _token;
        opponent[msg.sender] = address(0);

        user_results[msg.sender] = DUEL_OUTCOME.MAKER_WAITING;

        emit DuelBaked(msg.sender, _token, _amount);
    }

    /**
     * @notice Take a challenge for PvP
     * @dev requires the existance of an available maker with a challenge
     * @param maker address of maker
     */
    function takeDuel(address maker) public updateBloodMoney(msg.sender) {
        require(duelingOpen, "It seems all new dueling is closed");
        require(
            vrfLinkBal[msg.sender] > -10,
            "You require more vrf-tickets to play"
        );

        require(
            duelBalance[msg.sender] == 0,
            "Finish or cancel current duel before making a new one"
        );
        require(
            user_results[maker] == DUEL_OUTCOME.MAKER_WAITING,
            "Duel is closed for entry"
        );

        uint256 _amount = duelBalance[maker];
        IERC20 _token = duelToken[maker];
        _token.transferFrom(msg.sender, address(this), _amount);

        vrfLinkBal[msg.sender] -= 1;
        user_results[maker] = DUEL_OUTCOME.MAKER_TAKEN;

        duelBalance[maker] = (_amount * duelFeeDuo) / 1000;
        duelBalance[msg.sender] = duelBalance[maker];

        DAO_Supply[_token] += (_amount - duelBalance[msg.sender]) * 2;
        duelToken[msg.sender] = _token;

        opponent[maker] = msg.sender;
        opponent[msg.sender] = maker;

        emit DuelTaken(maker);
        duel(msg.sender);
    }

    /**
     * @notice Withdraw a challenge
     * @dev require the sender to have made a challenge
     */
    function abandonMadeDuel() external {
        uint256 _balance = duelBalance[msg.sender];
        require(
            user_results[msg.sender] == DUEL_OUTCOME.MAKER_WAITING,
            "Not waiting for taker, cannot abandon a duel"
        );
        duelBalance[msg.sender] = 0;
        user_results[msg.sender] = DUEL_OUTCOME.NOT_STARTED;

        duelToken[msg.sender].transfer(msg.sender, _balance);
        emit DuelAbandoned(msg.sender, duelToken[msg.sender], _balance);
    }

    /**
     * @notice Claim all token funds won dueling
     */
    function claimBloodMoney() external updateBloodMoney(msg.sender) {
        uint256 bloodMoney = duelClaim[msg.sender];
        CLAIM_Supply[duelToken[msg.sender]] -= bloodMoney;
        duelClaim[msg.sender] = 0;
        if (bloodMoney > 0) {
            duelToken[msg.sender].transfer(msg.sender, bloodMoney);
        }
    }

    /**
     * @notice Create a request id and requests randomness from VRF contract
     * @param duelist address of duelist finalizing the duel
     */
    function duel(address duelist) internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= user_fee,
            "Not enough LINK to pay fee"
        );
        require(
            user_results[duelist] == DUEL_OUTCOME.NOT_STARTED,
            "Duel outcome pending/decided!"
        );

        requestId = requestRandomness(user_keyHash, user_fee);
        user_rollers[requestId] = duelist;
        user_results[duelist] = DUEL_OUTCOME.IN_ACTION;

        if (opponent[duelist] != address(this)) {
            user_results[opponent[duelist]] = DUEL_OUTCOME.IN_ACTION;
        }

        emit DuelStarted(requestId, duelist);
    }

    /**
     * @notice Calculates winner from the random number and
     * @param requestId id of caller
     * @param randomness random number
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        bool duelistWon = (randomness % 2) == 0;
        DUEL_OUTCOME outcome;
        address duelist = user_rollers[requestId];
        IERC20 _token = duelToken[duelist];

        user_block_time[duelist] = block.timestamp;
        user_random[duelist] = randomness;

        if (duelistWon) {
            outcome = DUEL_OUTCOME.WIN;
        } else {
            outcome = DUEL_OUTCOME.LOSS;
        }

        if (opponent[duelist] != address(this)) {
            CLAIM_Supply[duelToken[duelist]] += 2 * duelBalance[duelist];
            user_block_time[opponent[duelist]] = block.timestamp;
            user_random[opponent[duelist]] = randomness;

            if (duelistWon) {
                user_results[opponent[duelist]] = DUEL_OUTCOME.LOSS;
                vrfLinkBal[duelist] += 1; // Only the loser pay for the vrf call
            } else {
                user_results[opponent[duelist]] = DUEL_OUTCOME.WIN;
            }
        } else {
            if (duelistWon) {
                CLAIM_Supply[duelToken[duelist]] += 2 * duelBalance[duelist];
            } else {
                DAO_Supply[_token] += 2 * duelBalance[duelist];
            }
        }

        user_results[duelist] = outcome;
        //emit DuelDecided(requestId, outcome);
    }

    /**
     * @notice Purchace VRF 'tickets' with link
     * @dev each player gets 10 tickets
     * @dev doesn't actually convert from ERC20 to ERC677 and relies on a third party to handle this
     * @param _user address to user
     * @param _amount of vrf tickets
     */
    function purchaceVrfTickets(address _user, uint256 _amount) external {
        LINK.transferFrom(msg.sender, address(this), _amount * user_fee * 10);
        vrfLinkBal[_user] += int256(_amount);
    }

    // ###################################################
    //                  VIEW FUNCTIONS
    // ###################################################

    /**
     * @notice View functions
     */
    function getResult() external view returns (DUEL_OUTCOME) {
        return user_results[msg.sender];
    }

    function getUserRandomNumber() external view returns (uint256) {
        return user_random[msg.sender];
    }

    function viewBloodMoney() external view returns (uint256) {
        if (user_results[msg.sender] == DUEL_OUTCOME.WIN) {
            return (duelClaim[msg.sender] + duelBalance[msg.sender]);
        }
        return duelClaim[msg.sender];
    }

    function viewToken(address duelist) external view returns (IERC20) {
        return duelToken[duelist];
    }

    function getMaxDuelSolo(IERC20 _token) external view returns (uint256) {
        return (DAO_Supply[_token] / safetyOffset);
    }

    function getMakerChallengeAmount(address maker)
        external
        view
        returns (uint256)
    {
        if (user_results[maker] == DUEL_OUTCOME.MAKER_WAITING) {
            return duelBalance[maker];
        }
        return 0;
    }

    function getMakerChallengeToken(address maker)
        external
        view
        returns (IERC20)
    {
        if (user_results[maker] == DUEL_OUTCOME.MAKER_WAITING) {
            return duelToken[maker];
        }
        return IERC20(address(0));
    }

    function getSecsSinceCall() external view returns (uint256) {
        return (block.timestamp - user_block_time[msg.sender]);
    }

    function getOpponentAddress() external view returns (address) {
        return opponent[msg.sender];
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

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
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}