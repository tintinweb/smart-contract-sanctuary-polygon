/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/[email protected]/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: Lottery/IFortunaNFT.sol


pragma solidity ^0.8.2;

interface IFortunaNFT {
    function raffleMint (address to, string memory uri) external;
}
// File: Lottery/IStable.sol


pragma solidity ^0.8.2;

interface IStable {
    function approve (address spender, uint256 amount) external;

    function transfer (address recipient, uint256 amount) external;

    function transferFrom (address sender, address recipient, uint256 amount) external;
}
// File: Lottery/Raffle.sol


pragma solidity >=0.4.22 <0.9.0;






/// @custom:security-contact [email protected]
contract Raffle is VRFConsumerBase, Ownable, Pausable {
    string public name = 'Fortuna Raffle';

    mapping(uint256 => mapping(uint256 => address)) public ticketNumberAddress;
    mapping(uint256 => mapping(address => uint256)) public depositBalance;
    mapping(uint256 => mapping(address => uint256)) public ticketBalance;
    mapping(uint256 => mapping(address => uint256)) public wonAmountByRaffleNumber;
    mapping(address => uint256) public withdrawnWinnings;
    mapping(address => uint256) public withdrawableWinnings;
    mapping(uint256 => uint256) public currentRaffleBalance;
    uint256 public currentRaffleCounter;
    uint256 public currentTicketAmount;
    address public stableCoinAddress;
    uint256 public marketingBalance;
    uint256 public charityBalance;
    uint256 public randomWinner;
    uint256 public teamBalance;
    address public winner;
    bytes32 internal keyHash;
    uint256 internal fee;
    address public nftAddress;


    struct Percentages {
        uint256 rafflePercentage;
        uint256 teamPercentage;
        uint256 charityPercentage;
    }

    struct RaffleSettings {
        uint256 maxTicketAmount;
        uint256 ticketLimitPerWallet;
        uint256 ticketPrice;
    }

    struct NFTLinks {
        string commonLink;
        string uncommonLink;
        string rareLink;
        string epicLink;
        string legendaryLink;
    }

    Percentages percentages;
    RaffleSettings settings;
    NFTLinks links;

    constructor(address _stable)
        VRFConsumerBase(
        0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)
  
        stableCoinAddress = _stable;

        settings = RaffleSettings(5000,5000,10);
        links = NFTLinks(
        "ipfs://QmZ6sbep6vBD4LQ4Tk3jcuTKzP2Jzu2deGJDy9jG5SEvpc/TylerDurdenV2.json",
        "ipfs://QmZ6sbep6vBD4LQ4Tk3jcuTKzP2Jzu2deGJDy9jG5SEvpc/SonicV2.json",
        "ipfs://QmZ6sbep6vBD4LQ4Tk3jcuTKzP2Jzu2deGJDy9jG5SEvpc/BatmanV2.json",
        "ipfs://QmZ6sbep6vBD4LQ4Tk3jcuTKzP2Jzu2deGJDy9jG5SEvpc/DeadpoolV2.json",
        "ipfs://QmZ6sbep6vBD4LQ4Tk3jcuTKzP2Jzu2deGJDy9jG5SEvpc/EminemV2.json"
        );
        percentages = Percentages(80,10,10);
        currentTicketAmount = 0;
        charityBalance = 0;
        currentRaffleBalance[currentRaffleCounter] = 0;
        teamBalance = 0;
        marketingBalance = 0;
        currentRaffleCounter = 1;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setNFTAddress(address contractAddress) public onlyOwner {
        nftAddress = contractAddress;
    }

    // Buy Tickets Function
    function getTickets(uint256 ticketAmount) public {
        uint256 totalTicketAmount = ticketBalance[currentRaffleCounter][msg.sender] + ticketAmount; // Ticket Amount After Function Finishes

        // require(totalTicketAmount >= 1 && totalTicketAmount <= settings.ticketLimitPerWallet, "You can't buy more than X tickets per wallet."); // Set the constraints for ticket amount
        require((currentTicketAmount + ticketAmount) <= settings.maxTicketAmount, "There are X tickets left to claim you can't buy more than that.");

        // Transfer tether tokens to this contract address for staking
        IStable(stableCoinAddress).transferFrom(msg.sender, address(this), ticketAmount * settings.ticketPrice * 1e6);

        // Update Ticket Balance
        ticketBalance[currentRaffleCounter][msg.sender] = ticketBalance[currentRaffleCounter][msg.sender] + ticketAmount;
        // ticketBuyers[ticketBuyers.length] = msg.sender;

        for (uint i = 0; i < ticketAmount; i++) {  //for loop example
            ticketNumberAddress[currentRaffleCounter][currentTicketAmount+i] = msg.sender;    
        }
        currentTicketAmount += ticketAmount;

        //MintNFT
        mintNFT(ticketAmount);
        // Update Deposited Tether Balance
        depositBalance[currentRaffleCounter][msg.sender] = depositBalance[currentRaffleCounter][msg.sender] + ticketAmount * settings.ticketPrice  * 1e6;

        charityBalance += ticketAmount * settings.ticketPrice * percentages.charityPercentage / 100 * 1e6;//To Charity
        teamBalance += ticketAmount * settings.ticketPrice * percentages.teamPercentage / 100 * 1e6; //To Team
        currentRaffleBalance[currentRaffleCounter] += ticketAmount * settings.ticketPrice * percentages.rafflePercentage / 100 * 1e6; //To Lottery Pool
    }

    function mintNFT(uint256 ticketAmount) internal {
        if(ticketAmount <= 2) {
            IFortunaNFT(nftAddress).raffleMint(msg.sender,links.commonLink);
        }
        else if (ticketAmount <= 4) {
            IFortunaNFT(nftAddress).raffleMint(msg.sender,links.uncommonLink);
        }
        else if (ticketAmount <= 6) {
            IFortunaNFT(nftAddress).raffleMint(msg.sender,links.rareLink);
        }
        else if (ticketAmount <= 8) {
            IFortunaNFT(nftAddress).raffleMint(msg.sender,links.epicLink);
        }
        else if (ticketAmount > 8) {
            IFortunaNFT(nftAddress).raffleMint(msg.sender,links.legendaryLink);
        }
       
    }

    // Withdraw Winnings
    function withdrawWinnings() public {
        require(withdrawableWinnings[msg.sender] > 0);

        IStable(stableCoinAddress).transfer(msg.sender, withdrawableWinnings[msg.sender]);
        withdrawnWinnings[msg.sender] = withdrawableWinnings[msg.sender];
        withdrawableWinnings[msg.sender] = 0;
    }

    // Withdraw Winnings
    function withdrawWinningsForAddress(address withdrawAddress) public onlyOwner {
        require(withdrawableWinnings[withdrawAddress] > 0);

        IStable(stableCoinAddress).transfer(withdrawAddress, withdrawableWinnings[withdrawAddress]);
        withdrawnWinnings[withdrawAddress] = withdrawableWinnings[withdrawAddress];
        withdrawableWinnings[withdrawAddress] = 0;
    }

    function updatePercentages(uint256 raffleyPerc, uint256 teamPerc, uint256 charityPerc) public onlyOwner {
        require((raffleyPerc + teamPerc + charityPerc) == 100);
        percentages.rafflePercentage = raffleyPerc;
        percentages.teamPercentage = teamPerc;
        percentages.charityPercentage = charityPerc;
    }


    function updateLottery(uint256 ticketLimit, uint256 ticketPerWalletLimit,uint256 ticketPriceUpdate) public onlyOwner {
        settings = RaffleSettings(ticketLimit, ticketPerWalletLimit, ticketPriceUpdate);
    }

    function updateNFT(string memory common, string memory uncommon, string memory rare, string memory epic, string memory legendary) public onlyOwner {
        links = NFTLinks(common,uncommon,rare,epic,legendary);
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId)  {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomWinner = (randomness % currentTicketAmount) + 1;
    }

    function expand(uint randomNumber,uint256 n, uint256 raffleTicketCount) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomNumber, i))) % raffleTicketCount;
        }
        return expandedValues;
    }

    function delegateWinners() public onlyOwner
    {
        winners(expand(randomWinner, 100, currentTicketAmount));
    }

    //Winner %62.5 1 Person
    //Secondary Winner %1.25 24 Person
    //%0.1 75 Person
    function winners(uint256[] memory randomNumbers) public onlyOwner{
        for(uint256 i = 0; i < 100; i++){
            if(i == 0){
                withdrawableWinnings[ticketNumberAddress[currentRaffleCounter][randomNumbers[i]]] += currentRaffleBalance[currentRaffleCounter] * 625 / 1000;
            } else if (i > 0 && i <= 24) {
                withdrawableWinnings[ticketNumberAddress[currentRaffleCounter][randomNumbers[i]]] += currentRaffleBalance[currentRaffleCounter] * 125 / 10000;
            } else{
                withdrawableWinnings[ticketNumberAddress[currentRaffleCounter][randomNumbers[i]]] += currentRaffleBalance[currentRaffleCounter] / 1000;
            }
        }
        resetLottery();
    }

    function resetLottery() public onlyOwner
    {
        currentRaffleCounter++;
        currentTicketAmount = 0;
        currentRaffleBalance[currentRaffleCounter] = 0;
    }

    function withdrawTeamBalance() public onlyOwner
    {
        //Send Token To Team Wallet
        IStable(stableCoinAddress).transfer(0x4aA4981f187550AbcA155C4b45C05F73b4625760, teamBalance);
    }

    function sendCharityBalance() public onlyOwner
    {
        //Send Charity Balance
        IStable(stableCoinAddress).transfer(0x4aA4981f187550AbcA155C4b45C05F73b4625760, charityBalance);
    }

    function ticketsLeft() public view returns (uint256) {
        return (settings.maxTicketAmount - currentTicketAmount);
    }

    function raffleSettings() public view returns(uint256, uint256, uint256) {
        return(settings.maxTicketAmount, settings.ticketLimitPerWallet, settings.ticketPrice);
    }

    function getPercentages() public view returns(uint256, uint256 , uint256){
        return (percentages.rafflePercentage, percentages.charityPercentage, percentages.teamPercentage);
    }

    function raffleCounter() public view returns(uint256) {
        return currentRaffleCounter;
    }

    function getCurrentRaffleBalance() public view returns(uint256) {
        return (currentRaffleBalance[currentRaffleCounter]);
    }

    function getWinningsAmount() public view returns(uint256) {
        return withdrawableWinnings[msg.sender];
    }

    function getCurrentTickets() public view returns(uint256) {
        return ticketBalance[currentRaffleCounter][msg.sender];
    }
}