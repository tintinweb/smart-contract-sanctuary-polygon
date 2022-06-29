/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
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
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
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
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

/// @title Roulette contract
/// @dev This contract based on interacting with ERC20 Tokens.
contract RouletteVRF is VRFConsumerBaseV2, Ownable {
    // ------------------------------
    //      Polygon VRF Section
    // ------------------------------
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    // vrf Coordinator for Polygon
    // testnet: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
    // mainnet: 0xAE975071Be8F8eE67addBC1A82488F1C24858067
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    // keyhash Polytgon
    // testnet (500 gwei): 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
    // mainnet (200 gwei): 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93
    //         (500 gwei): 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd
    //        (1000 gwei): 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the fulfillRandomWords() function
    uint32 callbackGasLimit = 400000;

    // Confirmations for the random request, min = 3, max = 200
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;

    uint256[] public s_randomWords;
    address s_owner;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords() internal returns(uint256){
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        UserGameData memory userData = requestToUserData[requestId];
        require(userData.user != address(0x0), "Empty data for given request id!");

        uint8 generatedNumber = uint8(randomWords[0] % ALL_ROULETTE_ITEMS);

        uint256 win = 0;

        for (uint256 i = 0; i < userData.bets.length; i++) {
            bool isWinNumber = false;
            for (uint256 j = 0; j < userData.bets[i].numbers.length; j++) {
                if (userData.bets[i].numbers[j] == generatedNumber) {
                    isWinNumber = true;
                    break;
                }
            }
            if (isWinNumber) {
                win += userData.bets[i].value * MAX_BET_NUMBERS / userData.bets[i].numbers.length;
            }
        }

        if (win > 0) {
            sendTokensToUser(userData.user, win);
        }

        SpinResult memory result;
        result.balance = allowance(userData.user);
        result.win = win;
        result.ballPosition = generatedNumber;
        result.requestId = requestId;

        emit RouletteRoundComplete(result);
    }
    // ------------------------------
    //      Roulette Section
    // ------------------------------

    uint256 USDT = 1_000_000_000;
    uint256 public minBet = 1_000_000;
    uint256 public maxBet = USDT;
    uint256 public constant MIN_BET_NUMBERS = 1;
    uint256 public constant MAX_BET_NUMBERS = 36;
    uint256 public constant ALL_ROULETTE_ITEMS = 37;

    mapping(uint256 => UserGameData) requestToUserData;
    // Owner saves a token's address here
    address public usdtErc20ContractAddress = address(0x0);

    /// Function checks how many tokens the Roulette was allowed to spend
    /// @dev This function interacts with external ERC20 contract via call
    /// @param userToCheck Address of user whose balance is checked
    /// @return Amount of tokens that the Roulette could spend
    function allowance(address userToCheck) public returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "allowance(address,address)",
            address(userToCheck),
            address(this)
        );
        (bool success, bytes memory returnData) = address(
            usdtErc20ContractAddress
        ).call(payload);

        require(success, "Can't check allowance, call was rejected!");

        return abi.decode(returnData, (uint256));
    }

    function balanceOf(address user) public returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "balanceOf(address)",
            address(user)
        );

        (bool success, bytes memory returnData) = address(
            usdtErc20ContractAddress
        ).call(payload);

        require(success, "Can't check balance, call was rejected!");

        return abi.decode(returnData, (uint256));
    }

    function takeFromBank(uint256 amountUsdt) external onlyOwner {
        uint256 rouletteBalance = balanceOf(address(this));
        require(
            amountUsdt <= rouletteBalance,
            "Roulette hasn't enough tokens to withdraw!"
        );

        bytes memory payload = abi.encodeWithSignature(
            "transfer(address,uint256)",
            _msgSender(),
            amountUsdt
        );
        (bool success, ) = address(usdtErc20ContractAddress).call(payload);
        require(success, "Transfer error: roulette can't send tokens!");
    }

    /// Function takes tokens from user balance
    /// @dev This function interacts with external ERC20 contract via call
    /// @notice Function checks contract's allowance
    /// @param user Address of user whose balance will DEcrease
    /// @param amount Amount of tokens that the user will pay
    function takeTokensFromUser(address user, uint256 amount) internal {
        uint256 currentAllowance = allowance(user);
        require(
            amount <= currentAllowance,
            "Roulette hasn't enough allowance to complete the request!"
        );

        bytes memory payload = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            user,
            address(this),
            amount
        );
        (bool success, ) = address(usdtErc20ContractAddress).call(payload);
        require(success, "Transfer error: roulette can't recieve tokens!");
    }

    /// Function transfer tokens from roulette to user
    /// @dev This function interacts with external ERC20 contract via call
    /// @param user Address of user whose balance will INcrease
    /// @param amount Amount of tokens that the roulette will pay
    function sendTokensToUser(address user, uint256 amount) internal {
        bytes memory payload = abi.encodeWithSignature(
            "transfer(address,uint256)",
            user,
            amount
        );
        (bool success, ) = address(usdtErc20ContractAddress).call(payload);
        require(success, "Roulette can't send tokens to user!");
    }

    /// Function sets address of ERC20 token that roulette should use
    /// @param newAddress New address of ERC20 token to use
    function resetTokenAddress(address newAddress) external onlyOwner {
        usdtErc20ContractAddress = newAddress;
    }

    /// Function sets min bet that user can put on one space
    /// @param newMinBet New bet to be a minimum
    function setMinBet(uint256 newMinBet) external onlyOwner {
        minBet = newMinBet;
    }

    /// Function sets max bet that user can put on one space
    /// @param newMaxBet New bet to be a maximum
    function setMaxBet(uint256 newMaxBet) external onlyOwner {
        maxBet = newMaxBet;
    }
    /// Function to play with bets
    /// @dev Emits RouletteRoundComplete event
    /// @dev This function interacts with external ERC20 contract via call
    /// @param bets array of user bets with values and numbers
    function play(Bet[] calldata bets) external {
        require(bets.length > 0, "There are no bets!");
        uint256 betTotalSum = 0;
        for (uint256 i = 0; i < bets.length; i++) {
            require(
                bets[i].value >= minBet && bets[i].value <= maxBet,
                "One of bets has unsuitable bet! Check min bet and max bet!"
            );
            require(
                bets[i].numbers.length >= MIN_BET_NUMBERS &&
                    bets[i].numbers.length <= ALL_ROULETTE_ITEMS,
                "One of bets has unsuitable numbers!"
            );
            betTotalSum += bets[i].value;
        }

        require(allowance(_msgSender()) >= betTotalSum, "Allowance is not enough to place the bets!");

        takeTokensFromUser(_msgSender(), betTotalSum);

        // saving data to wait random number
        uint256 requestId = requestRandomWords();
        UserGameData storage data = requestToUserData[requestId];
        for (uint i = 0; i < bets.length; i++) {
            data.bets.push(bets[i]);
        }

        data.user = _msgSender();
        emit RouletteRandomRequested(requestId);
    }

    function updateCallbackGasLimit(uint32 newCallbackGasLimit) external onlyOwner {
        callbackGasLimit = newCallbackGasLimit;
    }
    event RouletteRandomRequested(uint256 requestId);
    event RouletteRoundComplete(SpinResult results);

    struct RouletteItem {
        uint8 number;
        RouletteItemColor color;
    }

    enum RouletteItemColor {
        empty,
        red,
        black
    }

    struct Bet {
        uint8[] numbers;
        uint256 value;
    }

    struct SpinResult {
        uint256 requestId;
        uint256 win;
        uint8 ballPosition;
        uint256 balance;
    }
    struct UserGameData {
        address user;
        Bet[] bets;
    }
}