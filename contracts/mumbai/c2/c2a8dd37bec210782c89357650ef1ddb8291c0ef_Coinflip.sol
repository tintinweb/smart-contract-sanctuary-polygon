/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract Random is Ownable, VRFConsumerBase {
    address public constant LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public constant VRF_COORDINATOR = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 public keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint public chainlinkFee = 0.0001 ether;

    constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) {}

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setChainlinkFee(uint _chainlinkFee) external onlyOwner {
        chainlinkFee = _chainlinkFee;
    }

    function linkBalance() public view returns (uint) {
        return LINK.balanceOf(address(this));
    }

    function isEnoughLinkForBet() public view returns (bool) {
        return linkBalance() >= chainlinkFee;
    }
}

interface IHouse {
    function placeBet(address player, uint amount, bool isBonus, uint nftHolderRewardsAmount, uint winnableAmount) payable external;
    function settleBet(address player, uint winnableAmount, bool win) external;
    function refundBet(address player, uint amount, uint winnableAmount) external;
}

abstract contract Manager is Ownable {
    IHouse house;

    // Variables
    bool public gameIsLive = true;
    uint public minBetAmount = 1 ether;
    uint public maxBetAmount = 10 ether;
    uint public maxCoinsBettable = 4;
    uint public houseEdgeBP = 200;
    uint public nftHoldersRewardsBP = 7500;

    mapping(bytes32 => uint) public betMap;

    struct Bet {
        uint8 coins;
        uint40 choice;
        uint40 outcome;
        uint168 placeBlockNumber;
        uint128 amount;
        uint128 winAmount;
        address player;
        bool isSettled;
    }

    Bet[] public bets;

    function betsLength() external view returns (uint) {
        return bets.length;
    }

    // Events
    event BetPlaced(uint indexed betId, address indexed player, uint amount, uint indexed coins, uint choice, bool isBonus);
    event BetSettled(uint indexed betId, address indexed player, uint amount, uint indexed coins, uint choice, uint outcome, uint winAmount);
    event BetRefunded(uint indexed betId, address indexed player, uint amount);

    // Setter
    function setMaxCoinsBettable(uint _maxCoinsBettable) external onlyOwner {
        maxCoinsBettable = _maxCoinsBettable;
    }

    function setMinBetAmount(uint _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount;
    }

    function setMaxBetAmount(uint _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        houseEdgeBP = _houseEdgeBP;
    }

    function setNftHoldersRewardsBP(uint _nftHoldersRewardsBP) external onlyOwner {
        nftHoldersRewardsBP = _nftHoldersRewardsBP;
    }

    function toggleGameIsLive() external onlyOwner {
        gameIsLive = !gameIsLive;
    }

    // Converters
    function amountToBettableAmountConverter(uint amount) internal view returns(uint) {
        return amount * (10000 - houseEdgeBP) / 10000;
    }

    function amountToNftHoldersRewardsConverter(uint _amount) internal view returns (uint) {
        return _amount * nftHoldersRewardsBP / 10000;
    }

    function amountToWinnableAmount(uint _amount, uint coins) internal view returns (uint) {
        uint bettableAmount = amountToBettableAmountConverter(_amount);
        return bettableAmount * 2 ** coins;
    }

    // Methods
    function destroyContract() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function initializeHouse(address _address) external onlyOwner {
        house = IHouse(_address);
    }
}

contract Coinflip is ReentrancyGuard, Random, Manager {
    function placeBet(uint betChoice, uint coins, uint bonus) external payable nonReentrant {
        require(gameIsLive, "Game is not live");
        require(coins > 0 && coins <= maxCoinsBettable, "Coins not within range");
        require(betChoice >= 0 && betChoice < 2 ** coins, "Bet mask not in range");
        require(isEnoughLinkForBet(), "Insufficient LINK token");

        uint amount = msg.value;
        bool isBonus;
        if (amount == 0) {
            isBonus = true;
            amount = bonus;
        }
        require(amount >= minBetAmount && amount <= maxBetAmount, "Bet amount not within range");

        uint winnableAmount = amountToWinnableAmount(amount, coins);
        uint bettableAmount = amountToBettableAmountConverter(amount);
        uint nftHolderRewardsAmount = amountToNftHoldersRewardsConverter(amount - bettableAmount);
        
        house.placeBet{value: msg.value}(msg.sender, amount, isBonus, nftHolderRewardsAmount, winnableAmount);
        
        bytes32 requestId = requestRandomness(keyHash, chainlinkFee);
        betMap[requestId] = bets.length;

        emit BetPlaced(bets.length, msg.sender, amount, coins, betChoice, isBonus);   
        bets.push(Bet({
            coins: uint8(coins),
            choice: uint40(betChoice),
            outcome: 0,
            placeBlockNumber: uint168(block.number),
            amount: uint128(amount),
            winAmount: 0,
            player: msg.sender,
            isSettled: false
        }));
    }

    // Callback function called by Chainlink VRF coordinator.
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        settleBet(requestId, randomness);
    }

    // Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(bytes32 requestId, uint256 randomNumber) private nonReentrant {       
        uint betId = betMap[requestId];
        Bet storage bet = bets[betId];

        uint amount = bet.amount;
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        address player = bet.player;
        uint choice = bet.choice;
        uint coins = bet.coins;

        uint outcome = randomNumber % (2 ** coins);
        uint winnableAmount = amountToWinnableAmount(amount, coins);
        uint winAmount = choice == outcome ? winnableAmount : 0;

        bet.isSettled = true;
        bet.winAmount = uint128(winAmount);
        bet.outcome = uint40(outcome);

        house.settleBet(player, winnableAmount, winAmount > 0);
        emit BetSettled(betId, player, amount, coins, choice, outcome, winAmount);
    }

    function refundBet(uint betId) external nonReentrant {
        require(gameIsLive, "Game is not live");
        Bet storage bet = bets[betId];
        uint amount = bet.amount;

        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");
        require(block.number > bet.placeBlockNumber + 21600, "Wait before requesting refund");

        uint winnableAmount = amountToWinnableAmount(amount, bet.coins);
        uint bettedAmount = amountToBettableAmountConverter(amount);
        
        bet.isSettled = true;
        bet.winAmount = uint128(bettedAmount);

        house.refundBet(bet.player, bettedAmount, winnableAmount);
        emit BetRefunded(betId, bet.player, bettedAmount);
    }
}