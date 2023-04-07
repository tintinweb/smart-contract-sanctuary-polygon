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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

library RandomnessStorage {
    struct SharedVRFSetUp {
        VRFCoordinatorV2Interface COORDINATOR;
        uint64 s_subscriptionId;
        bytes32 keyHash; // Gas lane to use (chainlink subscriptions docs)
        uint8 requestConfirmations;
        /**
         * @dev Storing each word costs about 20,000 gas. Adjust this limit based on
         *     the selected network, the size of the request and the processing of
         *     the callback request in the `fulfillRandomWords()`.
         */
        uint32 callbackGasLimit;
        uint32 randPerRequest; // up to `VRFCoordinatorV2.MAX_NUM_WORDS`
    }

    struct VRFRequestId {
        // requests made but some migt not be fulfilled
        uint256[] requestIds;
        uint256 lastRequestId;
        uint256 lastReqTime;
        // only fulfilled by callback
        uint256[] fulfilledRequests;
    }

    struct RequestStatus {
        // whether a requestId exists
        bool exists;
        string igoId;
        // fulfilled by callback
        bool fulfilled;
        uint256[] randomWords;
    }

    /*//////////////////////////////////////////////////////////////
                        WHOLE RANDOMNESS STORAGE
    //////////////////////////////////////////////////////////////*/
    struct RandomnessStruct {
        SharedVRFSetUp sharedSetup;
        // igoId => IgoVRFData
        mapping(string => VRFRequestId) requestsOf;
        /**
         * @dev requestId => RequestStatus, where `requestId` is computed by
         *      the VRF Coordinator.
         */
        mapping(uint256 => RequestStatus) s_requests;
    }

    bytes32 constant RANDOMNESS_STORAGE =
        keccak256("diamond.randomness.storage");

    function layout()
        internal
        pure
        returns (RandomnessStruct storage loteryStruct)
    {
        bytes32 position = RANDOMNESS_STORAGE;
        assembly {
            loteryStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// contracts
import {WhitelistReadable} from "./readable/WhitelistReadable.sol";
import {WhitelistWritable} from "./writable/WhitelistWritable.sol";

contract Whitelist is WhitelistReadable, WhitelistWritable {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

library WhitelistStorage {
    struct Transform {
        uint256[] transformed;
        uint256 lastIndexProcessed;
    }

    struct WhitelistStruct {
        mapping(string => Transform) transform;
        mapping(string => mapping(uint256 => address[])) winners;
    }

    bytes32 constant WHITELIST_STORAGE = keccak256("diamond.whitelist.storage");

    /// @return loteryStruct Common storage mapping accross all vaults implemented by Vault0
    function layout()
        internal
        pure
        returns (WhitelistStruct storage loteryStruct)
    {
        bytes32 position = WHITELIST_STORAGE;
        assembly {
            loteryStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {RandomnessStorage} from "../../randomness/RandomnessStorage.sol";
import {WhitelistStorage} from "../WhitelistStorage.sol";

// TODO: add interface
contract WhitelistReadable {

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IWhitelistWritable {
    function transformRandomsAndPickWinners(
        string calldata igoId,
        address[] calldata addrs,
        uint256 amountOfWinners
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IWhitelistWritableInternal {
    event Winners(string igo, address[] winners);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// interfaces
import {IWhitelistWritable} from "./IWhitelistWritable.sol";
// libraries
import {RandomnessStorage} from "../../randomness/RandomnessStorage.sol";
import {WhitelistStorage} from "../WhitelistStorage.sol";
// contracts
import {WhitelistWritableInternal} from "./WhitelistWritableInternal.sol";

contract WhitelistWritable is IWhitelistWritable, WhitelistWritableInternal {
    // TODO: gas optimise this function
    // TODO: fuzz test
    function transformRandomsAndPickWinners(
        string calldata igoId,
        address[] calldata addrs,
        uint256 amountOfWinners
    ) external override {
        emit Winners(
            igoId,
            _transformRandomsAndPickWinners(addrs, amountOfWinners)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IWhitelistWritableInternal} from "./IWhitelistWritableInternal.sol";

import {RandomnessStorage} from "../../randomness/RandomnessStorage.sol";
import {WhitelistStorage} from "../WhitelistStorage.sol";

contract WhitelistWritableInternal is IWhitelistWritableInternal {
    uint256[] internal _randoms;

    function _transformRandomsAndPickWinners(
        address[] calldata addrs,
        uint256 amountOfWinners
    ) internal view returns (address[] memory winners) {
        uint256 participants = addrs.length;
        require(amountOfWinners < participants, "winners >= participants");
        // saves gas, instead of passing as memory directly
        address[] memory addresses = addrs;

        winners = new address[](amountOfWinners);
        uint256[] memory randoms_ = _randoms; // saves ~5,500 gas

        // yul saves ~10M gas
        assembly {
            let memoryPos
            let newWinnerPos

            // current data <-> last data
            function swapCurrentAndLast(currentIndexPos, array) {
                let lastElemPos := shl(5, mload(array))
                // array[i] = array[array.last]
                // array[currentIndexPos] = array[lastElemPos]
                mstore(
                    add(array, currentIndexPos),
                    mload(add(array, lastElemPos))
                )
                // array[array.last] = current
                mstore(
                    add(array, lastElemPos),
                    mload(add(array, currentIndexPos))
                )
            }

            for {
                let i := 0
            } lt(i, amountOfWinners) {
                i := add(i, 1)
            } {
                // memory array:
                //  - index at 0 is array.length
                //  - index of data stored starts at 1
                memoryPos := shl(5, add(i, 1))

                // add 1 to index as addresses[] is in memory
                newWinnerPos := shl(
                    5,
                    add(mod(mload(add(randoms_, memoryPos)), participants), 1)
                )

                // winners[i] = addresses[newWinnerPos]
                mstore(
                    add(winners, memoryPos),
                    mload(add(addresses, newWinnerPos))
                )
                // addresses[newWinnerPos] <-> addresses[array.last]
                swapCurrentAndLast(newWinnerPos, addresses)
                // addresses.pop() - deletes addresses[array.last]
                mstore(addresses, sub(mload(addresses), 1))
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Whitelist} from "../src/lottery/whitelist/Whitelist.sol";

contract MockWhitelist is Whitelist {
    // loop from i to amount while pusing at each iteration 12489031409234 + i
    function produceFakeRandoms(uint256 amount) external {
        uint256[] memory randoms_ = new uint256[](amount);
        assembly {
            // we put winners.slot into memory since we need to hash the value
            // an array is saved from keccak(winners.slot)

            let memoryPos

            for {
                let i := 0
            } lt(i, amount) {
                i := add(i, 1)
            } {
                memoryPos := shl(5, add(i, 1))

                mstore(add(randoms_, memoryPos), add(12489031409234, i))
            }
        }

        _randoms = randoms_;
    }

    function getAmountOfRandoms() external view returns (uint256) {
        return _randoms.length;
    }

    function getRandoms() external view returns (uint256[] memory) {
        return _randoms;
    }
}