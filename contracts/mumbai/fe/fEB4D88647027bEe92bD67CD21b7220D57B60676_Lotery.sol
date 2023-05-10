// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/RandomGenerator.sol";

contract Lotery is Ownable, Pausable{
  uint public ticketCost;
  uint public actualNumber = 1; 
  uint public minNumber = 5;
  uint public minNumberOfAddress = 5;
  uint public loteryCounter; 
  uint public cantOfAddress;

  uint public stableFee; //in percernt  
  uint public stablePrize; //in percent
  uint public totalPrize;
  uint public totalVolumeInPrize;
  uint public totalTiketSell;
  uint public totalTiketFree;
  uint public totalFee;
  uint public time;
  uint public timePlus;

  uint[] public winersNumbers; 
  uint[] public percentForWiners;
  uint32 public cantOfNumbers = 5; //number of winers per gift

  address public caller;
  address public manager = msg.sender;
  address public house;
  address[] public LastAddressWiners; 
  address[] public referralList;
  IERC20 public ticketCoin;
  RandomGenerator public vrf;
  mapping(uint => address) public ownerOfTiket;
  mapping(address=>uint) public referralsBuys;
  mapping(address=>uint) public referralsAmount;
  mapping(address=>address) public referrer;
  mapping(address=>bool) public referrerSpecialList;
  mapping(address=>uint) public referrerSpecialListAmount;
  mapping(uint=>uint) public historicalTotalPrize; 
  mapping(uint=>uint) public historicalTotalNumbers; 
  mapping(uint=>uint[]) public historicalWinnerNumbers;
  mapping(uint=>address[]) public historicalWinnerAddress;
  mapping(uint=>mapping(address=>uint[])) public historicalTiketsOwner;
  mapping(uint=>mapping(address=>uint[])) public historicalTiketsFree;

  event BuyNumber(uint number, address buyer, address ref, uint _loteryCounter);
  event Winners(uint loteryNumber, address[] winersNumbers, uint[] winners);
 
  constructor ( 
    uint _ticketCost,
    uint _stableFee,
    address _house,
    uint[] memory _percentForWiners,
    RandomGenerator _RandomGenerator,
    IERC20 _ticketCoin
    ){     
    ticketCost = _ticketCost;
    caller = msg.sender;
    ticketCoin = _ticketCoin;
    house = _house;
    setStableFee(_stableFee);
    vrf = _RandomGenerator;
    setPercentForWiners(_percentForWiners);
  }  

  function buyNumber(address newReferrer, uint _amount) public whenNotPaused {
    require(msg.sender != newReferrer, "bad referrer");
    uint amount = ticketCost *   _amount;
    ticketCoin.transferFrom(msg.sender, address(this), amount);
    countAddress();
    _newTiket(msg.sender, _amount, false);
    address ref = referrer[msg.sender];
    if(ref != address(0) || newReferrer != address(0)){
      ref = referralSystem(newReferrer, _amount);
    }else{
      totalFee = totalFee + (amount * stableFee ) / 100;
    }        
    totalPrize = totalPrize + (amount * stablePrize) / 100;
    
    emit BuyNumber(actualNumber-1, msg.sender, ref, loteryCounter);    
  }
  
  function selectNumbers() public {
    require(msg.sender == caller, "You dont are de caller");    
    require(actualNumber >= minNumber, "actual number is down");
    require(cantOfAddress > minNumberOfAddress, "need more diferents buyers");
    
    vrf.requestRandomWords(cantOfNumbers);
  }

  function finishPlay(uint[] memory randomNumber) public {
    require(msg.sender == address(vrf), "You dont are de caller");
    require(actualNumber >= minNumber, "actual number is down");
    require(cantOfAddress > minNumberOfAddress, "need more diferents buyers");
    require(time < block.timestamp, "need more time");
    time =  block.timestamp + timePlus;
    winersNumbers = winersVerifications(randomNumber);
   
    for(uint i; i < LastAddressWiners.length; i++){       
      ticketCoin.transfer(LastAddressWiners[i], winAmount(i));
    }

    totalVolumeInPrize += totalPrize;
    historicalWinnerNumbers[loteryCounter] = winersNumbers;
    historicalWinnerAddress[loteryCounter] = LastAddressWiners;
    historicalTotalNumbers[loteryCounter] = actualNumber-1;
    historicalTotalPrize[loteryCounter] = totalPrize;
    actualNumber = 1;
    loteryCounter++;
    ticketCoin.transfer(house, totalFee);
    delete totalFee;
    delete cantOfAddress;
    delete totalPrize;
    emit Winners(loteryCounter-1, viewLastAddressWiners(), viewWinerNumbers());
  }

  // winners mustn't be repeated 
  function winersVerifications(uint[] memory randomNumber) internal returns(uint[] memory){
    delete LastAddressWiners; 
    delete winersNumbers;
    uint[]  memory subWinersNumbers = randomNumber;
    for(uint i; i < randomNumber.length; i++){
      uint subWinerNumber = (randomNumber[i] % actualNumber);
      if (subWinerNumber == 0) {
        subWinerNumber++;
      }
      if(i == 0){ 
        subWinersNumbers[i] = subWinerNumber ; 
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
      }else{
        bool change;
        for(uint j; j <= i; j++){  
          if(change){
            j=0;
            change = false;
          }
          while( LastAddressWiners[j] == ownerOfTiket[subWinerNumber]){
            subWinerNumber++;
            if (subWinerNumber == actualNumber){ subWinerNumber = 0; }
            change = true;
          }          
         
        }
        subWinersNumbers[i]=subWinerNumber;
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
      }
    }    
    return subWinersNumbers;
  }  

  function withDrawhticketCoins() public onlyOwner{
    ticketCoin.transfer(house, totalFee);
    delete totalFee;
  }

  // ------------ Set FUNCTONS --------------
  function pause() public onlyOwner {
        _pause();
    }

  function unpause() public onlyOwner {
      _unpause();
  }

  function setticketCoin(IERC20 _ticketCoin) public onlyOwner{
    ticketCoin = _ticketCoin;
  }

  function setTicketCost(uint _ticketCost) public onlyOwner{
    ticketCost = _ticketCost;
  }

  function setVRF(RandomGenerator _vrf) public onlyOwner{
    vrf = _vrf;
  }

  function setCantOfNumbers(uint32 _amountOfNumbers) public onlyOwner{
    cantOfNumbers = _amountOfNumbers;
  }

  function setPercentForWiners(uint[] memory _percentForWiners) public onlyOwner{
    percentForWiners = _percentForWiners;
    setCantOfNumbers(uint32(_percentForWiners.length));
  }

  function setCaller(address _caller) public onlyOwner {
    caller = _caller;
  }

  function setStableFee(uint newStableFee) public onlyOwner{
    stableFee = newStableFee;
    stablePrize = 100-newStableFee;
  }

  function setMinNumber(uint newMinNumber) public onlyOwner{
    minNumber = newMinNumber;
  }

  function setHouse(address _house) public onlyOwner{
    house = _house;
  }

  function setSpecialReferrers(address addressOfReferrer, uint amount) public onlyOwner{
    require(amount <= stableFee, "Amount is to high");
    require(amount > 0, "amount can not be zero");
    referrerSpecialList[addressOfReferrer] = true;
    referrerSpecialListAmount[addressOfReferrer] = amount;
  }

  function deleteSpecialReferrers(address addressOfReferrer)public onlyOwner{
    delete referrerSpecialList[addressOfReferrer];
    delete referrerSpecialListAmount[addressOfReferrer];
  }

  function setMinNumberOfAddress(uint _minNumberOfAddress) public {
    minNumberOfAddress = _minNumberOfAddress;
  }
  // ------------ VIEW FUNCTONS --------------

  function winAmount(uint i) public view returns(uint){   
    return (totalPrize * percentForWiners[i]) / 100;  
  }

  function viewLastAddressWiners() public view returns(address[] memory){
    return LastAddressWiners;
  }

  function viewWinerNumbers() public view returns(uint[] memory){
    return winersNumbers;
  }

  function viewLastWinersData() public view returns(uint[] memory, uint[] memory, address[] memory){
    uint[] memory winAmountValue = viewWinerNumbers();
    for(uint i; i < LastAddressWiners.length; i++){
      winAmountValue[i] = (historicalTotalPrize[loteryCounter-1] * percentForWiners[i]) / 100;
    }
    return (viewWinerNumbers(),winAmountValue, viewLastAddressWiners());
  }

  function viewLotery() internal view returns(uint[11] memory){
    return(
      [  
        cantOfNumbers,
        loteryCounter,
        ticketCost,
        cantOfAddress,
        actualNumber,
        totalPrize,
        historicalTotalPrize[loteryCounter-1],
        historicalTotalNumbers[loteryCounter-1],
        totalVolumeInPrize,
        totalTiketSell,
        totalTiketFree
      ]
    );
  }
  
  function viewLoteryData() public view returns(uint[11] memory, uint[31] memory ){
    return(viewLotery(),viewLastHistoricalTotalPrizes());
  }

  function viewUserData(address user) public view returns(
    bool, uint, uint, address, uint[] memory, uint[] memory
  ){
    return (
      referrerSpecialList[user], 
      referrerSpecialListAmount[user], 
      referralsAmount[user],
      referrer[user],
      historicalTiketsOwner[loteryCounter][user],
      historicalTiketsOwner[loteryCounter-1][user]
      );
  }

  function viewFreeTickets(uint n, address user) public view returns(uint[] memory, uint[] memory){
    return(
      historicalTiketsFree[loteryCounter][user],
      historicalTiketsFree[loteryCounter-n][user]
    );
  }
  
  function viewLastHistoricalTotalPrizes() public view returns(uint[31] memory){
    uint[31] memory lastPrizes;
    uint stop =30;
    if(loteryCounter < 30 ){      
       stop = loteryCounter; 
    }
    uint j;
    for(uint i=stop ; i > 0; i--){
      lastPrizes[j] = historicalTotalPrize[loteryCounter-i];
      j++;
    }
    
    return lastPrizes;
  }

  function getAmountOfList() public view returns (uint[] memory) {
    address[] memory referralListMemory= referralList;
    uint length = referralList.length;
    uint[] memory amounts = new uint[](length);
    for(uint i; i < referralListMemory.length; i++){
      amounts[i] = referralsAmount[referralListMemory[i]];
    }
    return amounts;
  }

  function getRefferalList() public view returns(address[] memory){
    return referralList;
  }

  function lastLoteryData(uint i) public view returns(uint, uint, address[] memory, uint[] memory) {
    return (
      historicalTotalNumbers[i],
      historicalTotalPrize[i],
      historicalWinnerAddress[i],
      historicalWinnerNumbers[i]
    );
  }

  // ------------ INTERNAL FUNCTONS --------------
  function _newTiket(address ticketFor, uint amount, bool freeTicket) internal {
    for(uint i; i < amount; i++){
      if(freeTicket){
        historicalTiketsFree[loteryCounter][ticketFor].push(actualNumber);
        totalTiketFree++;
      }else{
        totalTiketSell++;
      }
      ownerOfTiket[actualNumber] = ticketFor;    
      historicalTiketsOwner[loteryCounter][ticketFor].push(actualNumber);
      actualNumber++;
    }
  }  

  //function de comprar voleto automatico para referentes
  function referralSystem(address newReferrer, uint _amount) internal returns(address){
    uint amount = ticketCost * _amount;
    address realReferrer = setReferrer(newReferrer, _amount);
    uint fee = 5;
    if(referrerSpecialList[realReferrer]){
      fee = referrerSpecialListAmount[realReferrer];
    }

    totalFee = totalFee + (amount * (stableFee-fee) ) / 100; 
    ticketCoin.transfer(realReferrer, ((amount*fee)/100));

    //special list cant recive free tikets
    if((referralsBuys[realReferrer] >= 3) && !(referrerSpecialList[realReferrer])){
      uint freeAmount = referralsBuys[realReferrer]/ 3;
      _newTiket( realReferrer, freeAmount, true); 
      referralsBuys[realReferrer] = referralsBuys[realReferrer] % 3;
    }
    return realReferrer;
  }

  function countAddress() internal {
    if(historicalTiketsOwner[loteryCounter][msg.sender].length == 0 ){
      cantOfAddress++;
    }
  }
  
  //In seconds
  function setTimePlus(uint newTimePlusSeconds) public {
    timePlus = newTimePlusSeconds;
  }

  function setReferrer(address newReferrer, uint amount) internal returns(address){
    address realReferrer = referrer[msg.sender];
    
    if(realReferrer == address(0)){
      if(newReferrer != address(0) ){
        referrer[msg.sender] = newReferrer;
        if(referralsAmount[newReferrer] == 0 && !(referrerSpecialList[newReferrer])){
          referralList.push(newReferrer);
        }
        referralsBuys[newReferrer] +=amount;
        referralsAmount[newReferrer]+=amount;
        realReferrer = newReferrer;
      }
    }else{
      referralsBuys[realReferrer]+=amount;
      referralsAmount[realReferrer]+=amount;
    }
    return realReferrer;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


 interface ILotery{
    function finishPlay(uint[] memory _randomRequest) external;
 }

contract RandomGenerator is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    ILotery public code;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    mapping(address => bool) public ownersLists;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    // uint32 numWords = 2;

    /**
     * HARDCODED FOR Poligon Mainet
     * COORDINATOR: 0xAE975071Be8F8eE67addBC1A82488F1C24858067
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            	0xAE975071Be8F8eE67addBC1A82488F1C24858067
        );
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 numWords)
        external        
        returns (uint256 requestId)
    {
        require(ownersLists[msg.sender],"only owners can call this" );
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        code.finishPlay(_randomWords);
        
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function setCode(address _code) public onlyOwner{
        code = ILotery(_code);
    }
    function toggleOwnerList(address newOwner)public onlyOwner{
        ownersLists[newOwner] = !ownersLists[newOwner];
    }
}