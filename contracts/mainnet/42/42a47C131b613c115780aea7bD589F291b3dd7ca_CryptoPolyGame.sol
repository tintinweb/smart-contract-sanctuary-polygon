/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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
// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



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

// File: contracts/CryptoPolyGame.sol


pragma solidity ^0.8.7;





contract CryptoPolyGame is VRFConsumerBase,Ownable,ReentrancyGuard {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal totalAmountToBePaid; //  total amount owed by the contract. Only rent for NFT owners is added to this variable
    uint256 private MIN_BET;
    uint256 private MAX_BET;
    uint256 private BONUS_X = 1;// amount to be paid when user passes the starting point
    uint256 private tokenRatio = 3;//for every matic spent get 3X tokens
    address private nftaddress;
    address private rewarderAddress;// address of the contract that rewards token holders
    uint256 private MAX_STEPS_POSSIBLE = 10; //Roll multiple limit
    uint256 private HOUSE_EDGE_PERCENT = 3;    
    uint256 private HOUSE_EDGE_MINIMUM_AMOUNT;
    uint256 private NFT_PERCENT = 10;    
    uint256 private NFT_MINIMUM_AMOUNT;
    uint private lockedInBets;
    uint constant MAXPROFIT_X = 4;
    
    int constant SINGLE_X = 1; // 1x
    int constant ONEANDHALF_X = 9; // 1.5x
    int constant DOUBLE_X = 2; // 2x
    int constant TRIPLE_X = 3; // 3x
    int constant FOUR_X = 4; // 3x
    int constant ONE_FOURTH = -1; // 1/4x
    int constant TWO_FOURTH = -2;// 1/2x
    int constant THREE_FOURTH = -3;// 3/4x
    bool constant live_mode = true;
    
    struct Chance{
        // Chance type.
        bytes32 chanceType;
        // This defines the amount of reward or tax.
        int choice; 
        // order.
        uint order;         
    }

    struct CommunityChest{
        // Chance type.
        bytes32 ccType;
        // This defines the amount of reward or tax.
        int choice;  
        // order.
         uint order;             
    }
    struct Game {
        // Game amount in wei.
        uint amount;
        // tax amount to be paid. It is either 0 or non zero when the person has to pay tax.
        uint taxTobePaid;   
        // If player has selected multiple_bet, this variable stores the multiple amount bet.
        uint multiple_bet;   
        // chances of the player
        Chance[] chances;
        // chances of the player
        CommunityChest[] cchest;        
    }
    struct Position {
        // Position type.
        bytes32 positionType;
        // This is used to decide the tax or reward
        int choice;       
    }
    
    // this is mainly used we need the ability to refund bets 
    //(in the rare case when Chainlink does not respond with the random number)
    struct Bet {
        // Wager amount in wei.
        uint amount;    
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Status of bet settlement.
        bool isSettled;
        // Win amount.
        uint winAmount;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;        
    }

    // Mapping requestId returned by Chainlink VRF to bet Id.
    mapping(bytes32 => Bet) private betMap;

    // Mapping from games by address
    mapping (address => Game) private games;
    // Mapping of current position
    mapping (address => uint) private current_positions;
    // Mapping of event numbers
    mapping (address => uint) private address_events;    
    // Mapping of requestId
    mapping (address => bytes32) private address_requestid;
    // Mapping of addresses
    mapping (bytes32 => address) private requestid_address;
    // Mapping of positions
    mapping (uint => Position) private game_positions;

    // Chance and Community Chest array
    CommunityChest[10] private chestArray;
    Chance[10] private chanceArray;
    
    enum GAMESTAT{ RUNNING, PAUSED }
    GAMESTAT private gameStatus;

    event RewardWon(bytes32 indexed requestId,uint256 amountWon,address indexed _address,uint _current_position);
    event BonusWon(bytes32 indexed requestId,uint256 amountWon,address indexed _address);
    event PositionChanged(bytes32 indexed requestId,uint256 random_number,uint256 current_position,address indexed _address,uint256 event_no,bytes32[] event_details,uint256 pending_tax,uint256 time_stamp);
    event notEnoughBalance(uint256 first,address indexed _address);
    event requestIDGenerated(bytes32 indexed requestId,address indexed _address);
    event taxPaidSucess(bytes32 indexed requestId,uint256 amountPaid,address indexed _address,uint256 event_no);
    event taxPaidPartial(bytes32 indexed requestId,uint256 taxTobePaid,address indexed _address);
    event balanceMultipleBetPaid(bytes32 indexed requestId,uint256 amountPaid,address indexed _address);
    event rentPaid(address indexed _receiver_address,uint256 amountPaid,address indexed _address);
    event BetRefunded(bytes32 indexed requestId, address indexed gambler, uint amount);

    // this is the payment owed to NFT owners
    mapping(address => uint256) private nft_payments_list;

    //polygon
      constructor()
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        )
    {
        MIN_BET = 2 ether;
        MAX_BET = 100 ether;    
        HOUSE_EDGE_MINIMUM_AMOUNT = 0.05 ether;
        NFT_MINIMUM_AMOUNT = 0.1 ether;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)
        gameStatus = GAMESTAT.RUNNING;
        initializeBoard();
    }

    // board
    function initializeBoard() private {
        nftaddress = 0xB66e622E11D5102Fb0c797A67aEB92504B71ebe4;
        //possible positions start,reward,tax,chance,community chest

       //1 - 10 positions
        game_positions[0] = Position("start",0);
        game_positions[1] = Position("rent",0);
        game_positions[2] = Position("communitychest",0);
        game_positions[3] = Position("tax",SINGLE_X);
        game_positions[4] = Position("reward",DOUBLE_X);
        game_positions[5] = Position("rent",0);
        game_positions[6] = Position("rent",0);
        game_positions[7] = Position("chance",0);
        game_positions[8] = Position("reward",SINGLE_X);
        game_positions[9] = Position("rent",0);

        //11 - 20 positions
        game_positions[10] = Position("reward",DOUBLE_X);
        game_positions[11] = Position("rent",0);
        game_positions[12] = Position("reward",ONEANDHALF_X);
        game_positions[13] = Position("rent",0);
        game_positions[14] = Position("rent",0);
        game_positions[15] = Position("rent",0);
        game_positions[16] = Position("reward",DOUBLE_X);
        game_positions[17] = Position("communitychest",0);
        game_positions[18] = Position("rent",0);
        game_positions[19] = Position("rent",0);

        //21 - 30 positions
        game_positions[20] = Position("reward",TRIPLE_X);
        game_positions[21] = Position("rent",0);
        game_positions[22] = Position("chance",0);
        game_positions[23] = Position("rent",0);
        game_positions[24] = Position("reward",SINGLE_X);
        game_positions[25] = Position("rent",0);
        game_positions[26] = Position("rent",0);
        game_positions[27] = Position("rent",0);
        game_positions[28] = Position("reward",DOUBLE_X);
        game_positions[29] = Position("rent",0);

        //31 - 40 positions        
        game_positions[30] = Position("reward",FOUR_X);
        game_positions[31] = Position("rent",0);
        game_positions[32] = Position("reward",SINGLE_X);
        game_positions[33] = Position("communitychest",0);
        game_positions[34] = Position("rent",0);
        game_positions[35] = Position("rent",0);
        game_positions[36] = Position("chance",0);
        game_positions[37] = Position("reward",DOUBLE_X);
        game_positions[38] = Position("tax",SINGLE_X);
        game_positions[39] = Position("rent",0);

        chanceArray[0]=Chance("reward",ONE_FOURTH,0);
        chanceArray[1]=Chance("reward",ONE_FOURTH,1);
        chanceArray[2]=Chance("reward",TWO_FOURTH,2);
        chanceArray[3]=Chance("reward",ONE_FOURTH,3);
        chanceArray[4]=Chance("reward",TWO_FOURTH,4);
        chanceArray[5]=Chance("reward",ONE_FOURTH,5);
        chanceArray[6]=Chance("reward",TWO_FOURTH,6);
        chanceArray[7]=Chance("reward",ONE_FOURTH,7);
        chanceArray[8]=Chance("reward",TWO_FOURTH,8);
        chanceArray[9]=Chance("reward",ONE_FOURTH,9);


        chestArray[0]=CommunityChest("reward",ONE_FOURTH,0);
        chestArray[1]=CommunityChest("reward",TWO_FOURTH,1);
        chestArray[2]=CommunityChest("reward",TWO_FOURTH,2);
        chestArray[3]=CommunityChest("reward",ONE_FOURTH,3);
        chestArray[4]=CommunityChest("reward",ONE_FOURTH,4);
        chestArray[5]=CommunityChest("reward",TWO_FOURTH,5);
        chestArray[6]=CommunityChest("reward",ONE_FOURTH,6);
        chestArray[7]=CommunityChest("reward",TWO_FOURTH,7);
        chestArray[8]=CommunityChest("reward",TWO_FOURTH,8);
        chestArray[9]=CommunityChest("reward",ONE_FOURTH,9);   

  

    }
    
	receive() external payable {
    }

    /**
     * Requests randomness
     */
    function playGame(address _referrer,uint _multiple_bet,uint _betAmount,uint _firstTime) public payable returns (bytes32 requestId)  {

        //check for different conditions
        _validateGame();
        // for multiple bet, check if the parameter passed is greter than the paid amount
        if (_multiple_bet ==1 && _betAmount >= msg.value) {revert();} 

        uint amount = msg.value;
        //referer should not be registered if player has played before
        if (amount > 0 && _referrer != address(0) && _referrer != msg.sender && address_requestid[msg.sender] == 0) {
            if(live_mode)Rewarder(rewarderAddress).recordReferral(msg.sender, _referrer);
        }        

        requestId = requestRandomness(keyHash, fee); 
        // mappings
        address_requestid[msg.sender] = requestId;
        requestid_address[requestId] = msg.sender;
        Game storage game = games[msg.sender];

        // starting the game, initialize the variables
        if(_firstTime==1){
            current_positions[msg.sender] = 0;
            address_events[msg.sender] = 0;
            game.taxTobePaid = 0;
        }
        require(game.taxTobePaid == 0, "Tax needs to be paid in order to proceed");
	    game.amount = amount;
        game.multiple_bet = 0 ;

        // when multiple bet is selected
        if(_multiple_bet ==1){
            game.amount = _betAmount;
            game.multiple_bet = msg.value;
            require(msg.value >= game.amount, "Amount should be greater or equal than bet amount for multiple bets!");
        }

        // Winning amount.
        uint possibleWinAmount = amount * MAXPROFIT_X; // this is the max profit possible

        betMap[requestId] = Bet(
            {
                placeBlockNumber: block.number,
                isSettled: false,
                amount: msg.value,
                gambler: payable(msg.sender),
                winAmount: possibleWinAmount
            }
        );        


        // Check whether contract has enough funds to accept this bet.
        if(live_mode)
            require(lockedInBets + possibleWinAmount <= address(this).balance, "Insufficient funds");  

        // Update lock funds.
        lockedInBets += possibleWinAmount;              

        //if game start, then initialize the chance and community chest arrays
        if(_firstTime==1){
            delete game.chances;
            delete game.cchest;

            for(uint i = 0; i < chanceArray.length; i++) {
                game.chances.push(Chance(chanceArray[i].chanceType,chanceArray[i].choice,chanceArray[i].order));
            }    

            for(uint i = 0; i < chestArray.length; i++) {
                game.cchest.push(CommunityChest(chestArray[i].ccType,chestArray[i].choice,chestArray[i].order));
            }   
        }

        emit requestIDGenerated(requestId,msg.sender);
        return requestId;
    }   
    function markBetSettled(bytes32 requestId) private{
        Bet storage bet = betMap[requestId];
	    require(bet.isSettled == false, "Bet is settled already");
        bet.isSettled = true;
    }  
    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        markBetSettled(requestId);
        address player = requestid_address[requestId];
        
	    // retrieve MAX_STEPS_POSSIBLE random numbers 
        uint256[] memory return_values = expand(randomness,MAX_STEPS_POSSIBLE); 
        uint possibleWinAmount = 0;
        uint iterator = 1;
        
        
        // if it is a multiple bet then the possible win amount should be calculated accordingly
        if(games[player].multiple_bet > 0)
            possibleWinAmount = games[player].multiple_bet * MAXPROFIT_X; // this is the max profit possible
        else
            possibleWinAmount = games[player].amount * MAXPROFIT_X; // this is the max profit possible

     
        //while loop start
        while(iterator > 0){
            // fetch the random number between 1 - 6
             uint random_number = (return_values[iterator - 1] % 6) + 1; 
             bytes32[] memory event_details  = new bytes32[](4);
             uint amount_to_pay= 0;
            
            // now we need to move the player's position
            current_positions[player] += random_number;
            if(current_positions[player] >= 40){
                //if this is above 40, then it means it needs to go around amd start from 0
                current_positions[player] = current_positions[player] - 40; 
                //user also receives a bonus if they start again
                payBonus(games[player].amount,player,requestId);
            }

            // now find what kind of property this is. 
            // based on it, decide what to do


            if(game_positions[current_positions[player]].positionType == "rent"){
                // if this is rent, then we need to pay the amount to the people who owns the property
                event_details[0]="rent";
                event_details[1]="";
                payTheRent(games[player].amount,current_positions[player],player);
                // send the tokens to the user
                addTokenReward(games[player].amount,player);
            }else if(game_positions[current_positions[player]].positionType == "reward"){
                // pay reward to the user
                amount_to_pay = payReward(games[player].amount,game_positions[current_positions[player]].choice,player,requestId,current_positions[player]);
                event_details[0]="reward";
                event_details[1]=bytes32(amount_to_pay);
            }else if(game_positions[current_positions[player]].positionType == "tax"){
                // ok the user needs to pay the tax, emit the event
                games[player].taxTobePaid = getTaxPaymentAmount(games[player].amount,game_positions[current_positions[player]].choice);
                address_events[player]++;
                event_details[0]="tax";
                event_details[1]=bytes32(games[player].taxTobePaid);   
                // send the tokens to the user
                addTokenReward(games[player].amount,player);
            }else if(game_positions[current_positions[player]].positionType == "chance"){
                
                // now we need to pick one from the list and then remove it from the list so that it does not appear again
                
                uint index = return_values[iterator - 1] % games[player].chances.length; // take a random pick from the stack
                if(index > games[player].chances.length) index = 0;
   
                event_details[0]="chance";
                event_details[1]="undefined";
                // now see what "Chance" was picked
                if(games[player].chances[index].chanceType == "reward"){
                    //pay the reward
                    amount_to_pay = payReward(games[player].amount,games[player].chances[index].choice,player,requestId,current_positions[player]);
                    event_details[0]="chance";
                    event_details[1]="reward";
                    event_details[2]=bytes32(amount_to_pay);                      
                    event_details[3]=bytes32(games[player].chances[index].order);     
                }else if(games[player].chances[index].chanceType == "tax"){
                    // ok the user needs to pay the tax, emit the event 
                    games[player].taxTobePaid = getTaxPaymentAmount(games[player].amount,games[player].chances[index].choice);
                    address_events[player]++;
                    event_details[0]="chance";
                    event_details[1]="tax";
                    event_details[2]=bytes32(games[player].taxTobePaid);    
                    event_details[3]=bytes32(games[player].chances[index].order);      
                    addTokenReward(games[player].amount,player);
                }

                // the code below will remove the selected element from the array // 
                games[player].chances[index] = games[player].chances[games[player].chances.length-1];
                games[player].chances.pop();
                // the code above will remove the selected element from the array // 
                if(games[player].chances.length == 0){
                    // if all chance cards have finished, load them again and fire an event
                    for(uint i = 0; i < chanceArray.length; i++) {
                        games[player].chances.push(Chance(chanceArray[i].chanceType,chanceArray[i].choice,chanceArray[i].order));
                    }    
                    // all chance cards needs to be refilled
                }
                

            }else if(game_positions[current_positions[player]].positionType == "communitychest"){
                // now we need to pick one from the list and then remove it from the list so that it does not appear again
                
                
                uint index = return_values[iterator - 1] % games[player].cchest.length; // take a random pick from the stack
                if(index > games[player].cchest.length) index = 0;
                event_details[0]="community";
                event_details[1]="undefined";
                
                // now see what "Community Chest" was picked
                if(games[player].cchest[index].ccType == "reward"){
                    //pay the reward
                    amount_to_pay = payReward(games[player].amount,games[player].cchest[index].choice,player,requestId,current_positions[player]);
                    event_details[0]="community";
                    event_details[1]="reward";
                    event_details[2]=bytes32(amount_to_pay);        
                    event_details[3]=bytes32(games[player].cchest[index].order); 

                }else if(games[player].cchest[index].ccType == "tax"){
                    // ok the user needs to pay the tax, emit the event
                    games[player].taxTobePaid = getTaxPaymentAmount(games[player].amount,games[player].cchest[index].choice);
                    address_events[player]++;
                    event_details[0]="community";
                    event_details[1]="tax";
                    event_details[2]=bytes32(games[player].taxTobePaid);  
                    event_details[3]=bytes32(games[player].cchest[index].order);  
                    addTokenReward(games[player].amount,player);
                }

                // the code below will remove the selected element from the array // 
                games[player].cchest[index] = games[player].cchest[games[player].cchest.length-1];
                games[player].cchest.pop();
                // the code above will remove the selected element from the array // 
                if(games[player].cchest.length == 0){
                    // if all community chance cards have finished, load them again and fire an event
                    for(uint i = 0; i < chestArray.length; i++) {
                        games[player].cchest.push(CommunityChest(chestArray[i].ccType,chestArray[i].choice,chestArray[i].order));
                    }  
                }
                

            }

            
            //emit this event

            // while loop ending conditions
            iterator++;
            // if it is a multiple bet, then reduce the amount
            if(games[player].multiple_bet > 0){
                
                if(games[player].taxTobePaid > 0){
                    // if there is pending tax to be paid, then reduce it from the amount in store
                    if(games[player].taxTobePaid > games[player].multiple_bet){
                        // if we do not have enough balance then stop the loop
                        //repay the balance and let the user know that tax wasn't used
                        games[player].taxTobePaid = games[player].taxTobePaid - games[player].multiple_bet;                       
                        emit taxPaidPartial(requestId,games[player].taxTobePaid,player);
                        games[player].multiple_bet = 0;
                        iterator = 0;                         
                    }else{
                        // user has enough balance, then reduce it from user.
                        games[player].multiple_bet = games[player].multiple_bet - games[player].taxTobePaid;
                        games[player].taxTobePaid = 0;
                        address_events[player]++;
                    }
                }
                if(games[player].multiple_bet >= games[player].amount)games[player].multiple_bet = games[player].multiple_bet - games[player].amount;
                if(games[player].multiple_bet < games[player].amount){
                    //repay the balance to the user
                    iterator = 0;
                    if(games[player].multiple_bet > 0){
                        emit balanceMultipleBetPaid(requestId,games[player].multiple_bet,player);
                        (bool success, /* bytes memory data */) = player.call{value: games[player].multiple_bet}("");
                        require(success, "receiver rejected balance transfer");
                    }
                    games[player].multiple_bet = 0;

                }              
            }
            address_events[player]++;
            emit PositionChanged(requestId, random_number, current_positions[player],player,address_events[player],event_details,games[player].taxTobePaid,block.timestamp);
            if(games[player].multiple_bet == 0)iterator = 0; // if it is not a multiple bet
            if(iterator > MAX_STEPS_POSSIBLE)iterator = 0;// MAX_STEPS_POSSIBLE random numbers picked
        }
        // while loop end
        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;
        
    }

   
    function addTokenReward(uint amount,address player) private {
        uint newTokens = amount * tokenRatio;
        // only do this if it is live mode
        if(live_mode)Rewarder(rewarderAddress).addReward(player, newTokens);
    }

    function payTax() public payable  {

        //check for different conditions
        if (msg.value > msg.sender.balance) {revert();}

        bytes32 requestId = address_requestid[msg.sender];
        require(requestId > 0 , "RequestID is 0");

        Game storage game = games[msg.sender];
        require(msg.value == game.taxTobePaid, "Please pay the applicable tax!");
        require(game.taxTobePaid > 0, "No Tax to be paid!");
        uint event_no = address_events[msg.sender];
        event_no++;
        emit taxPaidSucess(requestId,game.taxTobePaid, msg.sender,event_no);
        game.taxTobePaid = 0;
        address_events[msg.sender] = event_no;
    }

    function payTheRent(uint amount,uint current_position,address player) private  {
        uint256 nftCharges = getNFTCharges(amount);
        uint amountToPay = 0;// 
        if(nftCharges < amount)
            amountToPay = amount - nftCharges;
        else 
            amountToPay = 0;

        address nft_owner = 0xB1c71C6c9AB9748f24720c8A8aaeF3Aee4460698; //temp address
        address _contractOwner = owner();
        //find the owner of the NFT
        if(live_mode)
        {
            nft_owner = NFTToken(nftaddress).ownerOf(current_position);//change this and make this live
            // check if the NFTS are owned by the owner of the contract. If yes, rent need not be paid.
            if(nft_owner != _contractOwner){
                nft_payments_list[nft_owner] = nft_payments_list[nft_owner] + amountToPay;            
                totalAmountToBePaid += amountToPay;
                emit rentPaid(nft_owner,amountToPay,player);
            }else{
                emit rentPaid(nft_owner,0,player);
            }        
        }
        
    }

    function getTaxPaymentAmount(uint amount,int text) private pure returns(uint)  {
        uint taxAmount = 0;
        if(text == SINGLE_X){
            taxAmount = amount;// 1x
        }else if(text == DOUBLE_X){
            taxAmount = amount * 2;// 1x
        }else if(text == TRIPLE_X){
            taxAmount = amount * 3;// 1x
        }
        return taxAmount;
    }

    function payReward(uint amount,int text,address player,bytes32 requestId,uint _current_position) private returns(uint)  {
        uint position_amount = 0;
        uint amountToPay = 0;
        uint256 houseEdge = getHouseEdge(amount);
        if(text == SINGLE_X){
            amountToPay = amount;// 1x
        }
        else if(text == DOUBLE_X || text == TRIPLE_X || text == FOUR_X){
            position_amount = uint256(text);
            amountToPay = amount * position_amount;// 2x, 3x, 4x
        }else if(text == ONEANDHALF_X){
            amountToPay = amount + (amount / 100)* 50;// 1.5
        }
        else if(text == ONE_FOURTH){
            amountToPay = (amount / 100)* 25;// .25
        }else if(text == TWO_FOURTH){
            amountToPay = (amount / 100)* 50;// .5
        }else if(text == THREE_FOURTH){
            amountToPay = (amount / 100)* 75;// .75
        }
        if(houseEdge < amountToPay)
            amountToPay = amountToPay - houseEdge;
        else 
            amountToPay = 0;
        (bool success, /* bytes memory data */) = player.call{value: amountToPay}("");
        require(success, "receiver rejected reward transfer");
        emit RewardWon(requestId, amountToPay,player,_current_position);
        return amountToPay;
    }

    // this is called when the player finishes a round
    function payBonus(uint amount,address player,bytes32 requestId)  private{
        uint amountToPay = 0;
        uint256 houseEdge = getHouseEdge(amount);
        amountToPay = amount * BONUS_X;
        if(houseEdge < amountToPay)
            amountToPay = amountToPay - houseEdge;
        else 
            amountToPay = 0;
        (bool success, /* bytes memory data */) = player.call{value: amountToPay}("");
        require(success, "receiver rejected bonus transfer");
        emit BonusWon(requestId, amountToPay,player);
    }


    function _validateGame() private {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(msg.value >= MIN_BET, "Need an amount greater than minimum bet amount");
        require(msg.value <= (MAX_BET*10), "Bet amount should not be greater than the MAX bet amount");
        require(gameStatus == GAMESTAT.RUNNING,"Game is presently paused!");
    }
    

    function getHouseEdge(uint256 amount) private view returns (uint256){
        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        return houseEdge;
    }
    function getNFTCharges(uint256 amount) private view returns (uint256){
        uint nftCharges = amount * NFT_PERCENT / 100;

        if (nftCharges < NFT_MINIMUM_AMOUNT) {
            nftCharges = NFT_MINIMUM_AMOUNT;
        }
        return nftCharges;
    }    
    function expand(uint256 randomValue, uint256 n) private pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function withdraw() public nonReentrant{
        require(nft_payments_list[msg.sender] != 0, "No funds to withdraw");
		uint amount = nft_payments_list[msg.sender];
		uint256 balanceContract = address(this).balance;
		if(balanceContract < amount){
		    emit notEnoughBalance(balanceContract,msg.sender);
		}else{
    		nft_payments_list[msg.sender] = 0;
    		totalAmountToBePaid -= amount;
    		(bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed.");
		}
	}
    function getMyBalance() public view returns (uint256,uint256)  {
        uint256 _balance = nft_payments_list[msg.sender];
        uint256 balanceContract = address(this).balance;
		return (_balance,balanceContract);
	}
    function getPendingTax() public view returns (uint256)  {
        Game memory game = games[msg.sender];
		return (game.taxTobePaid);
	}

    


    // Return the bet in the very unlikely scenario it was not settled by Chainlink VRF. 
    // In case you find yourself in a situation like this, just contact support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(bytes32 requestId) external nonReentrant {
        
        Bet storage bet = betMap[requestId];
        uint amount = bet.amount;

        // Validation checks
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(block.number > bet.placeBlockNumber + 21600, "Wait before requesting refund");

        uint possibleWinAmount = bet.winAmount;

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(requestId, bet.gambler, amount);
    }    

    // below are admin functions 
	function withdrawAmount(uint256 amount) public onlyOwner {
        address _contractOwner = owner();
		payable(_contractOwner).transfer(amount);
	}

	function transferToRewarder(uint256 amount) public onlyOwner {
		payable(rewarderAddress).transfer(amount);
	}
	function getTotalAmountOwed() public view onlyOwner returns(uint256)  {
		return totalAmountToBePaid;
	}


    function withdrawForUser(address addr)  public onlyOwner {
        require(nft_payments_list[addr] != 0, "No funds to withdraw");
		uint amount = nft_payments_list[addr];
		uint256 balanceContract = address(this).balance;
		if(balanceContract < amount){
		    emit notEnoughBalance(balanceContract,msg.sender);
		}else{
    		nft_payments_list[addr] = 0;
    		totalAmountToBePaid -= amount;
    		(bool success, ) = addr.call{value: amount}("");
            require(success, "Transfer failed.");
		}
	}
	// withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner 
    {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
    
    function getLockedInBets() public view onlyOwner returns (uint256) {
        return lockedInBets;
    }

    function getLinkBalance() public view onlyOwner  returns (uint256)  {
        //LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        return LINK.balanceOf(address(this));
    }
    function pauseGame() public onlyOwner  {
        gameStatus = GAMESTAT.PAUSED;
    }
    
    function restartGame() public onlyOwner  {
        gameStatus = GAMESTAT.RUNNING;
    }

    function changeMinBet(uint256 _minBet) public onlyOwner  {
        MIN_BET = _minBet;
    }

    function changeMaxBet(uint256 _maxBet) public onlyOwner  {
        MAX_BET = _maxBet;
    }
    function changeLockedInBets(uint256 _lockedBets) public onlyOwner  {
        lockedInBets = _lockedBets;
    }

    function changeChainLinkKeyHash(bytes32 _keyHash) public onlyOwner  {
        keyHash = _keyHash;
    }

    function changeChainLinkFeee(uint256 _fee) public onlyOwner  {
        fee = _fee;
    }

    function changeNFTAddress(address _nftaddress) public onlyOwner  {
        nftaddress = _nftaddress;
    }
    function changeRewarderAddress(address _rewarderAddress) public onlyOwner  {
        rewarderAddress = _rewarderAddress;
    }

    function changeHouseEdge(uint256 _houseEdge) public onlyOwner  {
        HOUSE_EDGE_PERCENT = _houseEdge;
    }

    function changeNftPercent(uint256 _nftpercent) public onlyOwner  {
        NFT_PERCENT = _nftpercent;
    }

    function changeMaxStepsPossible(uint256 _maxStepsPossible) public onlyOwner  {
        MAX_STEPS_POSSIBLE = _maxStepsPossible;
    }

    function changeBonus(uint256 _bonus) public onlyOwner  {
        BONUS_X = _bonus;
    }

    function changeTokenRatio(uint256 _tokenRatio) public onlyOwner  {
        tokenRatio = _tokenRatio;
    }

    function changeHouseEdgeMinimum(uint256 _houseEdgeMinimum) public onlyOwner  {
        HOUSE_EDGE_MINIMUM_AMOUNT = _houseEdgeMinimum;
    }
    function changeNFTMinimum(uint256 _nftMinimum) public onlyOwner  {
        NFT_MINIMUM_AMOUNT = _nftMinimum;
    }    
    function changeGamePositionArray(uint256 _index,bytes32 _positionType,int _choice) public onlyOwner  {
        game_positions[_index] = Position(_positionType,_choice);
    }    
    
    function changeChanceArray(uint256 _index,bytes32 _chanceType,int _choice,uint _order) public onlyOwner  {
	    chanceArray[_index]=Chance(_chanceType,_choice,_order);
    }    


    function changeCCArray(uint256 _index,bytes32 _ccType,int _choice,uint _order) public onlyOwner  {
	    chestArray[_index]=CommunityChest(_ccType,_choice,_order);
    }   


}
interface NFTToken {
    function ownerOf(uint) external view returns (address);
}
interface Rewarder {
    function addReward(address, uint) external;
    function recordReferral(address, address) external;
}