// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/// @title A contract for decentralized audit marketplace
contract Auditor is VRFConsumerBaseV2, KeeperCompatibleInterface {
	struct Audit {
		address creator;
		address contractAddress;
		address[5] jury;
		address[] yesPoolFunders;
		address[] noPoolFunders;
		address[] bugReporters;
		uint256 createdTime;
		uint256 lastStreamTime;
		uint256 totalYesPool;
		uint256 totalNoPool;
		mapping(address => uint256) yesPool;
		mapping(address => uint256) noPool;
		mapping(address => Bug[]) reporterToBugs;
	}

	struct Bug {
		uint256 createdTime;
		bool[5] juryMemberHasVoted;
		uint256 verdict;
		uint8 status; // 0 for pending, 1 for rejected, 2 for approved
	}

	address[] public eligibleJuryMembers;
	address[] public contractsAudited;
	mapping(address => Audit) public audits;
	mapping(address => address[]) public juryMemberToAudits;

	// global variables for Chainlink VRF
	VRFCoordinatorV2Interface COORDINATOR;
	uint64 vrfSubscriptionId;
	address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; // coordinator address for Polygon Mumbai
	bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f; // keyHash for Polygon Mumbai
	uint32 callbackGasLimit = 100000;
	uint16 requestConfirmations = 3;
	uint32 numMembers = 5; // 5 jury members needed per audit
	mapping(uint256 => address) requestToAudit;

	// global variables for Chainlink Keepers
	uint256 public immutable interval = 1 days;
	uint256 public immutable timeToDrainFunds = 30 days;

	// custom events
	event AuditRequested(address indexed creator, address indexed contractAddress, uint256 timestamp);
	event AuditCompleted(
		address indexed creator,
		address indexed contractAddress,
		uint256 timestamp,
		bool verdict
	);
	event AuditCancelled(address indexed creator, address indexed contractAddress, uint256 timestamp);
	event AuditJuryUpdated(address indexed contractAddress, uint256 timestamp, address[5] jury);
	event AuditYesPoolUpdated(
		address indexed contractAddress,
		address indexed voter,
		uint256 totalYesPool
	);
	event AuditNoPoolUpdated(
		address indexed contractAddress,
		address indexed voter,
		uint256 totalNoPool
	);
	event NewBugReported(
		address indexed contractAddress,
		address indexed reporter,
		uint256 timestamp
	);
	event JuryMemberAdded(address indexed memberAddress, uint256 timestamp);
	event JuryVoteOnBug(
		address indexed contractAddress,
		address indexed reporter,
		address indexed juryMember,
		uint256 bugIndex
	);

	// custom modifiers
	modifier equallyFunded() {
		require(msg.value > 0 && msg.value % 2 == 0, "Must be equally funded!");
		_;
	}

	constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
		COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
		vrfSubscriptionId = subscriptionId;
	}

	function requestRandomWords(address contractAddress) internal {
		uint256 requestId = COORDINATOR.requestRandomWords(
			keyHash,
			vrfSubscriptionId,
			requestConfirmations,
			callbackGasLimit,
			numMembers
		);
		requestToAudit[requestId] = contractAddress;
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		address contractAddress = requestToAudit[requestId];

		for (uint8 i = 0; i < 5; i++) {
			audits[contractAddress].jury[i] = eligibleJuryMembers[
				randomWords[i] % eligibleJuryMembers.length
			];
			juryMemberToAudits[audits[contractAddress].jury[i]].push(contractAddress);
		}

		emit AuditJuryUpdated(contractAddress, block.timestamp, audits[contractAddress].jury);
	}

	function createAudit(address contractAddress) external payable equallyFunded {
		require(
			audits[contractAddress].createdTime != block.timestamp,
			"audit exists for given contract"
		);

		requestRandomWords(contractAddress);

		Audit storage newAudit = audits[contractAddress];
		contractsAudited.push(contractAddress);

		newAudit.creator = msg.sender;
		newAudit.contractAddress = contractAddress;
		newAudit.createdTime = block.timestamp;
		newAudit.lastStreamTime = block.timestamp;
		newAudit.totalYesPool = msg.value / 2;
		newAudit.totalNoPool = msg.value / 2;

		newAudit.yesPool[msg.sender] = newAudit.totalYesPool;
		newAudit.yesPoolFunders.push(msg.sender);
		newAudit.noPool[msg.sender] = newAudit.totalNoPool;
		newAudit.noPoolFunders.push(msg.sender);

		emit AuditRequested(msg.sender, contractAddress, block.timestamp);
	}

	function fundNoBugsPool(address contractAddress) external payable {
		// will have to add streaming payments
		audits[contractAddress].totalNoPool += msg.value;
		audits[contractAddress].noPool[msg.sender] = msg.value;
		audits[contractAddress].noPoolFunders.push(msg.sender);

		emit AuditNoPoolUpdated(contractAddress, msg.sender, audits[contractAddress].totalNoPool);
	}

	function reportBug(address contractAddress) external payable {
		Bug memory newBug;
		newBug.createdTime = block.timestamp;
		newBug.verdict = 0;
		newBug.status = 0;

		if (audits[contractAddress].reporterToBugs[msg.sender].length == 0) {
			audits[contractAddress].bugReporters.push(msg.sender);
		}
		audits[contractAddress].reporterToBugs[msg.sender].push(newBug);

		emit NewBugReported(contractAddress, msg.sender, block.timestamp);

		audits[contractAddress].totalYesPool += msg.value;
		audits[contractAddress].yesPool[msg.sender] += msg.value;
		audits[contractAddress].yesPoolFunders.push(msg.sender);

		emit AuditYesPoolUpdated(contractAddress, msg.sender, audits[contractAddress].totalYesPool);
	}

	function juryVote(
		address contractAddress,
		address bugReporter,
		uint16 bugIndex,
		uint8 juryIndex,
		bool vote
	) external {
		require(
			audits[contractAddress].jury[juryIndex] == msg.sender,
			"sender does not match given jury member"
		);
		require(
			!audits[contractAddress].reporterToBugs[bugReporter][bugIndex].juryMemberHasVoted[juryIndex],
			"jury member has voted"
		);

		audits[contractAddress].reporterToBugs[bugReporter][bugIndex].verdict += vote ? 1 : 0;
		audits[contractAddress].reporterToBugs[bugReporter][bugIndex].juryMemberHasVoted[
			juryIndex
		] = true;

		emit JuryVoteOnBug(
			contractAddress,
			bugReporter,
			audits[contractAddress].jury[juryIndex],
			bugIndex
		);

		uint8 totalVotes = 0;
		for (uint8 i = 0; i < 5; i++) {
			totalVotes += audits[contractAddress]
			.reporterToBugs[bugReporter][bugIndex].juryMemberHasVoted[i]
				? 1
				: 0;
		}

		bool verdict = audits[contractAddress].reporterToBugs[bugReporter][bugIndex].verdict >= 3;

		if (verdict || totalVotes == 5) {
			audits[contractAddress].reporterToBugs[bugReporter][bugIndex].status = verdict ? 2 : 1;
			juryVerdict(contractAddress, verdict);
		}
	}

	function juryVerdict(address contractAddress, bool verdict) internal {
		uint256 noPool = audits[contractAddress].totalNoPool;
		uint256 yesPool = audits[contractAddress].totalYesPool;
		uint256 totalPayout = noPool + yesPool;

		uint256 juryReward = (totalPayout * 5) / 100;

		if (verdict) {
			audits[contractAddress].totalYesPool += noPool;
			audits[contractAddress].totalNoPool = 0;

			// Paying out jury
			for (uint256 i = 0; i < audits[contractAddress].jury.length; i++) {
				payable(audits[contractAddress].jury[i]).transfer(juryReward / 5);
			}

			audits[contractAddress].totalYesPool = (audits[contractAddress].totalYesPool * 19) / 20;
			uint256 totalYesPoolValue = audits[contractAddress].totalYesPool;
			for (uint256 i = 0; i < audits[contractAddress].yesPoolFunders.length; i++) {
				address payable voter = payable(audits[contractAddress].yesPoolFunders[i]);
				voter.transfer((audits[contractAddress].yesPool[voter] * totalYesPoolValue) / yesPool);
				audits[contractAddress].totalYesPool -= ((audits[contractAddress].yesPool[voter] *
					totalYesPoolValue) / yesPool);
			}
		} else {
			if (audits[contractAddress].totalNoPool > 19 * (audits[contractAddress].totalYesPool)) {
				// totalNoPool has to be greater than 95% of sum of both pools for liquidation
				audits[contractAddress].totalNoPool += yesPool;
				audits[contractAddress].totalYesPool = 0;

				// Paying out jury
				for (uint256 i = 0; i < audits[contractAddress].jury.length; i++) {
					payable(audits[contractAddress].jury[i]).transfer(juryReward / 5);
				}

				audits[contractAddress].totalNoPool = (audits[contractAddress].totalNoPool * 19) / 20;
				uint256 totalNoPoolValue = audits[contractAddress].totalNoPool;
				for (uint256 i = 0; i < audits[contractAddress].noPoolFunders.length; i++) {
					address payable voter = payable(audits[contractAddress].noPoolFunders[i]);
					voter.transfer((audits[contractAddress].noPool[voter] * totalNoPoolValue) / noPool);
					audits[contractAddress].totalNoPool -= ((audits[contractAddress].yesPool[voter] *
						totalNoPoolValue) / noPool);
				}
			}
		}

		emit AuditCompleted(audits[contractAddress].creator, contractAddress, block.timestamp, verdict);
	}

	function addEligibleJuryMember(address memberAddress) external {
		eligibleJuryMembers.push(memberAddress);

		emit JuryMemberAdded(memberAddress, block.timestamp);
	}

	function getContractsToBeStreamed() public view returns (address[] memory) {
		address[] memory toStream = new address[](contractsAudited.length);

		for (uint256 i = 0; i < contractsAudited.length; i++) {
			if (audits[contractsAudited[i]].lastStreamTime - block.timestamp > interval) {
				toStream[i] = contractsAudited[i];
			}
		}

		return toStream;
	}

	function streamPools(address[] memory needStreaming) internal {
		for (uint256 i = 0; i < needStreaming.length; i++) {
			if (needStreaming[i] == address(0)) {
				continue;
			}
			if ((block.timestamp - audits[needStreaming[i]].lastStreamTime) / (1 days) < 1) {
				continue;
			}
			if ((block.timestamp - audits[needStreaming[i]].createdTime) / (1 days) >= 30) {
				juryVerdict(needStreaming[i], false);
			}
			uint256 totalYesPoolValue = audits[needStreaming[i]].totalYesPool;
			uint256 daysRemaining = (block.timestamp - audits[needStreaming[i]].createdTime) / (1 days);
			audits[needStreaming[i]].totalYesPool -= totalYesPoolValue / daysRemaining;
			audits[needStreaming[i]].totalNoPool += totalYesPoolValue / daysRemaining;
			audits[needStreaming[i]].lastStreamTime = block.timestamp;
		}
	}

	function checkUpkeep(
		bytes calldata /* checkData */ // checkData is unused
	) external view override returns (bool upkeepNeeded, bytes memory performData) {
		address[] memory needStreaming = getContractsToBeStreamed();
		upkeepNeeded = needStreaming.length > 0;
		performData = abi.encode(needStreaming);
		return (upkeepNeeded, performData);
	}

	function performUpkeep(bytes calldata performData) external override {
		address[] memory needStreaming = abi.decode(performData, (address[]));
		streamPools(needStreaming);
	}

	function getAuditData(address contractAddress)
		external
		view
		returns (
			address creator,
			address[5] memory jury,
			uint256 createdTime,
			uint256 totalYesPool,
			uint256 totalNoPool
		)
	{
		return (
			audits[contractAddress].creator,
			audits[contractAddress].jury,
			audits[contractAddress].createdTime,
			audits[contractAddress].totalYesPool,
			audits[contractAddress].totalNoPool
		);
	}

	function getNumberOfBugsByReporter(address contractAddress, address reporter)
		external
		view
		returns (uint256)
	{
		return audits[contractAddress].reporterToBugs[reporter].length;
	}

	function getBugByIndex(
		address contractAddress,
		address reporter,
		uint256 index
	)
		external
		view
		returns (
			uint256,
			bool[5] memory,
			uint256,
			uint8
		)
	{
		return (
			audits[contractAddress].reporterToBugs[reporter][index].createdTime,
			audits[contractAddress].reporterToBugs[reporter][index].juryMemberHasVoted,
			audits[contractAddress].reporterToBugs[reporter][index].verdict,
			audits[contractAddress].reporterToBugs[reporter][index].status
		);
	}

	function getEligibleJuryMembers() external view returns (address[] memory) {
		return eligibleJuryMembers;
	}

	function getAuditsUserIsOnJuryOf(address userAddress) external view returns (address[] memory) {
		return juryMemberToAudits[userAddress];
	}
}