//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../../interfaces/ITailorControlAccess.sol";

/**
 * @title TailorNFTLottery                   
					TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAI                                 
			TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILOR                         
		TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAI                     
		TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAI                  
	TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORT               
  TAILORTAILORTAILORTAILORTA                               TAILO                               TAILORTAILORTAILORTAILORTA              
 TAILORTAILORTAILORTAILORTAI                               TAILO                               TAILORTAILORTAILORTAILORTAI             
TAILORTAILORTAILORTAILORTAIL                               TAILO                               TAILORTAILORTAILORTAILORTAIL            
TAILORTAILORTAILORTAILORTAIL                               TAILO                               TAILORTAILORTAILORTAILORTAIL            
TAILORTAILORTAILORTAILORTAILORTAI                      TAILORTAILORTA                        TAILORTAILORTAILORTAILORTAILORTA           
TAILORTAILORTAILORTAILORTAILORTAILOR                 TAILORTAILORTAILOR                  TAILORTAILORTAILORTAILORTAILORTAILOR           
TAILORTAILORTAILORTAILORTAILORTAILORT               TAILORTAILORTAILORTAI               TAILORTAILORTAILORTAILORTAILORTAILORT           
TAILORTAILORTAILORTAILORTAILORTAILORT               TAILORTAILORTAILORTAI              TAILORTAILORTAILORTAILORTAILORTAILORTA           
TAILORTAILORTAILORTAILORTAILORTAILORT               TAILORTAILORTAILORTAI               TAILORTAILORTAILORTAILORTAILORTAILORT           
TAILORTAILORTAILORTAILORTAILORTAILOR                 TAILORTAILORTAILORT                 TAILORTAILORTAILORTAILORTAILORTAILOR           
TAILORTAILORTAILORTAILORTAILORTAIL                     TAILORTAILORTAI                     TAILORTAILORTAILORTAILORTAILORTAIL           
TAILORTAILORTAILORTAILORTAIL                               TAILO                               TAILORTAILORTAILORTAILORTAILO            
TAILORTAILORTAILORTAILORTAIL                               TAILO                               TAILORTAILORTAILORTAILORTAIL            
 TAILORTAILORTAILORTAILORTAI                               TAILO                               TAILORTAILORTAILORTAILORTAI             
  TAILORTAILORTAILORTAILORTA                               TAILO                               TAILORTAILORTAILORTAILORTA              
	TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAI               
		TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAIL                 
		TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILO                    
			TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAI                        
					TAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAILORTAIL                           
*/

contract LotteryReveal is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    ITailorControlAccess CONTROL_ACCESS;

    using Counters for Counters.Counter;

    struct ChainLinkDetails {
        address VRFAddress;
        bytes32 keyHash;
        uint64 subscriptionID;
        uint256 chainId;
    }

    enum LOTTERY_STATE {
        OPEN,
        CLOSED
    }
    LOTTERY_STATE public lottery_state;

    ChainLinkDetails public chainLinkDetails;
    Counters.Counter internal _counter;
    mapping(address => uint256) public winners;

    uint32 public numSeeds = 1;
    uint32 public callbackGasLimit = 100000;
    uint256 public randomSeed;
    uint256 public requestId;
    uint16 public requestConfirmations = 3;

    modifier onlyAdmin() {
        require(
            CONTROL_ACCESS.hasRole(
                0x3f6ce2d5571ab8f3fb1cf068a92ec99edc01aa4a757338b1f082acee66c84cb2,
                msg.sender
            ),
            "Wrong caller"
        );
        _;
    }

    modifier onlyReveal() {
        require(lottery_state == LOTTERY_STATE.OPEN, "State is Closed");
        _;
    }

    constructor(
        uint64 _subscriptionId,
        address _VRFAddress,
        bytes32 _keyHash,
        address _controlAccess
    ) VRFConsumerBaseV2(_VRFAddress) {
        setVRFDetails(_VRFAddress, _keyHash, _subscriptionId);
        lottery_state = LOTTERY_STATE.OPEN;
        CONTROL_ACCESS = ITailorControlAccess(_controlAccess);
    }

    function setVRFDetails(
        address _VRFAddress,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) internal {
        chainLinkDetails = ChainLinkDetails(
            _VRFAddress,
            _keyHash,
            _subscriptionId,
            getChainId()
        );
    }

    function revealCollection(
        uint256[] memory tokenIds,
        address[] calldata accounts
    ) external onlyReveal onlyAdmin {
        require(randomSeed != 0, "RandomSeed not called");
        tokenIds = shuffle(tokenIds, randomSeed);
        for (uint256 i; i < tokenIds.length; i++) {
            winners[accounts[i]] = tokenIds[i];
        }
        lottery_state = LOTTERY_STATE.CLOSED;
        _counter.increment();
    }

    function getRevealToken(address account) external view returns (uint256) {
        return winners[account];
    }

    function requestRandomWords() external onlyAdmin {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            chainLinkDetails.keyHash,
            chainLinkDetails.subscriptionID,
            requestConfirmations,
            callbackGasLimit,
            numSeeds
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        randomSeed = randomWords[0];
    }

    function shuffle(uint256[] memory tokenIds, uint256 entropy)
        public
        view
        returns (uint256[] memory)
    {
        bytes32 random = keccak256(abi.encodePacked(entropy));
        // Set the last item of the array which will be swapped.
        uint256 size = tokenIds.length;
        uint256 last_item = size - 1;

        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint256 i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint256 selected_item = uint256(random) % last_item;

            // Swap items `selected_item <> last_item`.
            uint256 aux = tokenIds[last_item];
            tokenIds[last_item] = tokenIds[selected_item];
            tokenIds[selected_item] = aux;

            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            last_item--;

            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }
        return tokenIds;
    }

    function getChainId() internal returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDrawnCounter() external view returns (uint256) {
        return _counter.current();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ITailorControlAccess {
    function hasRole(bytes32, address) external view returns (bool);
}