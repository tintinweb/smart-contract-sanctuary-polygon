// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol"; // ChainLink Automation
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // ChainLink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // ChainLink VRF
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol"; // Ownership

/**
 * @title Verifiable Draws Coordinator
 * @author Lancelot Chardonnet
 *
 * @notice You can use this contract to create random draws
 * using the protocol defined at verifiabledraws.com/protocol
 */
contract VerifiableDraws is AutomationCompatibleInterface, VRFConsumerBaseV2, ConfirmedOwner {

    error DrawDoesNotExist(string cid);
    error DrawTooEarly(string cid);

    struct Draw {
        uint64 publishedAt; // block number at which the draw was published on the contract
        uint64 scheduledAt; // timestamp at which the draw should be triggered
        uint256 occuredAt; // block number at which the draw has occurred
        uint32 entropyNeeded; // number of bytes of information needed to compute winners
        bool entropyPending;
        bytes entropy; // entropy used to pick winners
        bool completed;
    }
   
    // Draws 
    mapping(string => Draw) private draws; // Content Identifier (CID) => Draw
    string[] private pendingDraws;

    // Events
    event DrawLaunched(string cid, uint64 publishedAt, uint64 scheduledAt, uint32 entropyNeeded);
    event DrawsTriggered(string[] performData);
    event RequestSent(
        uint256 requestId,
        string[] cids,
        uint32 numWords,
        bytes32 keyHash,
        uint64 s_subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    );
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event DrawCompleted(string cid, bytes extractedEntropy);

    struct RequestStatus {
        bool exists; // whether a requestId exists
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
        string[] cids;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    VRFCoordinatorV2Interface COORDINATOR;

    // Polygon
    // For other networks see https://docs.chain.link/docs/vrf-contracts/#configurations
    address link_token_contract = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    // Gas lane to use, which specifies the maximum gas price to bump to
    bytes32 keyHash = 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
    

    // Your subscription ID.
    uint64 private s_subscriptionId;
    

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;


    constructor (
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function launchDraw(
        string memory cid,
        uint64 scheduledAt,
        uint32 entropyNeeded
    )
        external
        onlyOwner
    {
        require(draws[cid].publishedAt == 0, "Draw already exists");
        uint64 publishedAt = uint64(block.number);
        uint256 occuredAt = 0;
        bytes memory entropy = "";
        draws[cid] = Draw(publishedAt, scheduledAt, occuredAt, entropyNeeded, false, entropy, false);
        pendingDraws.push(cid);
        emit DrawLaunched(cid, publishedAt, scheduledAt, entropyNeeded);
    }
    
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        string[] memory tempDraws = new string[](pendingDraws.length);
        uint32 count = 0;

        for (uint64 i = 0; i < pendingDraws.length; i++) {
            string memory cid = pendingDraws[i];
            if (block.timestamp >= draws[cid].scheduledAt && !draws[cid].entropyPending) {
                if (!upkeepNeeded) {
                    upkeepNeeded = true;
                }

                tempDraws[i] = cid;
                count++;
            }
        }

        if (upkeepNeeded) {
            uint32 j = 0;
            string[] memory finalDraws = new string[](count);
            for (uint64 i = 0; i < tempDraws.length; i++) {
                if (bytes(tempDraws[i]).length != 0) {
                    finalDraws[j] = tempDraws[i];
                    j++;
                }
            }
            performData = abi.encode(finalDraws);
        }

        return (upkeepNeeded, performData);
    }


    function performUpkeep(
        bytes calldata performData
    )
        external
        override
    {
        string[] memory requestedDraws = abi.decode(performData, (string[]));

        for (uint64 i = 0; i < requestedDraws.length; i++) {
            string memory cid = requestedDraws[i];
            if (draws[cid].publishedAt == 0) {
                revert DrawDoesNotExist(cid);
            }

            // We revalidate the upkeep in the performUpkeep function to prevent malicious actors
            // from triggering draws which have not yet reached their scheduled date
            if (block.timestamp < draws[cid].scheduledAt) {
                revert DrawTooEarly(cid);
            }
        }

        emit DrawsTriggered(requestedDraws);
        generateEntropyFor(requestedDraws);
    }

    function setSubscription(uint64 subscriptionId) external onlyOwner {
        s_subscriptionId = subscriptionId;
    }


    // Assumes the subscription is funded sufficiently.
    function generateEntropyFor(string[] memory triggerDraws)
        private
        returns (uint256 requestId)
    {
        
        uint32 totalEntropyNeeded = 0;
        for (uint64 i = 0; i < triggerDraws.length; i++) {
            totalEntropyNeeded += draws[triggerDraws[i]].entropyNeeded;
            draws[triggerDraws[i]].entropyPending = true;
        }
 
        // Each word gives an entropy of 256 bits (see _randomWords in fulfillRandomWords)
        // i.e. 32 bytes
        uint32 entropyPerWord = 32;
        // Number of random words to generate
        uint32 numWords = divisionRoundUp(totalEntropyNeeded, entropyPerWord);

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
            cids: triggerDraws,
            exists: true,
            fulfilled: false
        });

        emit RequestSent(
            requestId,
            triggerDraws,
            numWords,
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit
        );

        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        RequestStatus memory request = s_requests[_requestId];
        require(request.exists, "request not found");
        request.fulfilled = true;
        request.randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        bytes memory totalEntropy = abi.encodePacked(_randomWords);
        uint32 from = 0;
        uint32 bytesNeeded = 0;

        for (uint64 i = 0; i < request.cids.length; i++) {
            string memory cid = request.cids[i];

            if (draws[cid].completed == false) {

                bytesNeeded = draws[cid].entropyNeeded;
                bytes memory extractedEntropy = extractBytes(totalEntropy, from, bytesNeeded);
                draws[cid].entropy = extractedEntropy;
                draws[cid].occuredAt = block.number;
                draws[cid].completed = true;
                from += bytesNeeded;
                removePending(cid);
                emit DrawCompleted(cid, draws[cid].entropy);
            }
        }
    }


    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getEntropy(string memory cid) external view returns (bytes memory) {
        return draws[cid].entropy;
    }

    // Division rounds down by default in Solidity, this function rounds up
    function divisionRoundUp(uint32 a, uint32 m) private pure returns (uint32) {
        return (a + m - 1) / m;
    }

    function extractBytes(bytes memory data, uint32 from, uint32 n) private pure returns(bytes memory) {
      bytes memory returnValue = new bytes(n);
      for (uint32 i = 0; i < n + from; i++) {
        returnValue[i] = data[i + from]; 
      }
      return returnValue;
    }

    function removePending(string memory searchFor) internal {
        for (uint256 i = 0; i < pendingDraws.length; i++) {
            if (keccak256(bytes(pendingDraws[i])) == keccak256(bytes(searchFor))) {
                pendingDraws[i] = pendingDraws[pendingDraws.length-1];
                pendingDraws.pop();
            }
        }
    }
}