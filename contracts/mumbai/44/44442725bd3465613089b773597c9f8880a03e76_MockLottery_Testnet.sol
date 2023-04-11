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

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';

interface IOwnable is IOwnableInternal, IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable } from './IOwnable.sol';
import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';

interface ISafeOwnable is ISafeOwnableInternal, IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {
    error SafeOwnable__NotNomineeOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Ownable } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnableInternal) {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    modifier onlyNomineeOwner() {
        if (msg.sender != _nomineeOwner())
            revert SafeOwnable__NotNomineeOwner();
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        _setOwner(msg.sender);
        delete SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().nomineeOwner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

import {Mock_Lottery} from "../../test/foundry/lottery/setUp/Mock_Lottery.sol";
import {RandomsUtils} from "../../test/foundry/lottery/setUp/RandomsUtils.sol";

contract MockLottery_Testnet is Mock_Lottery, RandomsUtils {
    string public constant IGO_ID = "igoId";

    uint256 public participants;
    uint256 public winners;

    constructor(address addr)
        Mock_Lottery(VRFCoordinatorV2Interface(addr), 3545, bytes32("testnet"))
    {}

    function produceFakeRandoms_ByBatchesOf500(
        string memory igoId,
        uint256 batchesBy_500
    ) public {
        uint256[] memory requestIds = new uint256[](batchesBy_500);

        for (uint256 i; i < batchesBy_500; ++i) {
            requestIds[i] = _requestId(
                bytes32("keyHash"),
                msg.sender,
                2435,
                uint64(i)
            );

            workaround_fulfillRandomWords(
                igoId,
                requestIds[i],
                _randomsBy(35) // by 500
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

import {OwnableInternal} from "solidstate-solidity/access/ownable/Ownable.sol";
import {SafeOwnable} from "solidstate-solidity/access/ownable/SafeOwnable.sol";

import {Randomness} from "./randomness/Randomness.sol";
import {Whitelist} from "./whitelist/Whitelist.sol";

contract Lottery is Randomness, Whitelist, SafeOwnable {
    constructor(
        VRFCoordinatorV2Interface COORDINATOR,
        uint64 s_subscriptionId,
        bytes32 keyHash
    ) Randomness(COORDINATOR, s_subscriptionId, keyHash) {}

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnable)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

// libraries
import {RandomnessStorage} from "./RandomnessStorage.sol";
// contracts
import {RandomnessFallback} from "./fallback/RandomnessFallback.sol";
import {RandomnessReadable} from "./readable/RandomnessReadable.sol";
import {RandomnessWritable} from "./writable/RandomnessWritable.sol";

abstract contract Randomness is
    RandomnessFallback,
    RandomnessReadable,
    RandomnessWritable
{
    constructor(
        VRFCoordinatorV2Interface COORDINATOR,
        uint64 s_subscriptionId,
        bytes32 keyHash
    ) {
        _setOwner(msg.sender);

        RandomnessStorage.SharedVRFSetUp storage sharedSetup = RandomnessStorage
            .layout()
            .sharedSetup;

        sharedSetup.COORDINATOR = COORDINATOR;
        sharedSetup.s_subscriptionId = s_subscriptionId;
        sharedSetup.keyHash = keyHash;

        sharedSetup.requestConfirmations = 3;
        /*
         * @dev max gas limit defined in chainlink doc
         * https://docs.chain.link/vrf/v2/subscription/supported-networks/#bnb-chain-testnet
         */
        sharedSetup.callbackGasLimit = 2_500_000;
        sharedSetup.randPerRequest = 500;
    }
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

interface IRandomnessFallback {
    event RequestFulfilled(uint256 indexed requestId, uint256[] randomWords);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFConsumerBaseV2} from "chainlink/vrf/VRFConsumerBaseV2.sol";

// interfaces
import {IRandomnessFallback} from "./IRandomnessFallback.sol";
// libraries
import {RandomnessStorage} from "../RandomnessStorage.sol";

abstract contract RandomnessFallback is IRandomnessFallback, VRFConsumerBaseV2 {
    constructor()
        VRFConsumerBaseV2(0x6A2AAd07396B36Fe02a22b33cf443582f682c82f)
    {}

    /**
     * @dev Used by `VRFConsumerBaseV2` to fulfill randomness requests on
     *      fallback.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        RandomnessStorage.RandomnessStruct storage strg = RandomnessStorage
            .layout();

        require(strg.s_requests[_requestId].exists, "request not found");

        string memory igoId = strg.s_requests[_requestId].igoId;

        strg.requestsOf[igoId].fulfilledRequests.push(_requestId);

        strg.s_requests[_requestId].fulfilled = true;
        strg.s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRandomnessReadable {
    function sharedSetUp()
        external
        view
        returns (
            address COORDINATOR,
            uint64 s_subscriptionId,
            bytes32 keyHash,
            uint8 requestConfirmations,
            uint32 callbackGasLimit,
            uint32 randPerRequest
        );

    function requestsOf(string memory igoId)
        external
        view
        returns (
            uint256[] memory requestIds,
            uint256 lastRequestId,
            uint256 lastReqTime,
            uint256[] memory fulfilledRequests
        );

    function requestStatus(uint256 requestId)
        external
        view
        returns (
            bool exists,
            string memory igoId,
            bool fulfilled,
            uint256[] memory randomWords
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// interfaces
import {IRandomnessReadable} from "./IRandomnessReadable.sol";
// libraries
import {RandomnessStorage} from "../RandomnessStorage.sol";

abstract contract RandomnessReadable is IRandomnessReadable {
    function sharedSetUp()
        external
        view
        override
        returns (
            address COORDINATOR,
            uint64 s_subscriptionId,
            bytes32 keyHash,
            uint8 requestConfirmations,
            uint32 callbackGasLimit,
            uint32 randPerRequest
        )
    {
        RandomnessStorage.SharedVRFSetUp
            storage sharedSetUp_ = RandomnessStorage.layout().sharedSetup;

        COORDINATOR = address(sharedSetUp_.COORDINATOR);
        s_subscriptionId = sharedSetUp_.s_subscriptionId;
        keyHash = sharedSetUp_.keyHash;
        requestConfirmations = sharedSetUp_.requestConfirmations;
        callbackGasLimit = sharedSetUp_.callbackGasLimit;
        randPerRequest = sharedSetUp_.randPerRequest;
    }

    function requestsOf(string memory igoId)
        external
        view
        override
        returns (
            uint256[] memory requestIds,
            uint256 lastRequestId,
            uint256 lastReqTime,
            uint256[] memory fulfilledRequests
        )
    {
        RandomnessStorage.VRFRequestId storage ids_ = RandomnessStorage
            .layout()
            .requestsOf[igoId];

        requestIds = ids_.requestIds;
        lastRequestId = ids_.lastRequestId;
        lastReqTime = ids_.lastReqTime;
        fulfilledRequests = ids_.fulfilledRequests;
    }

    function requestStatus(uint256 requestId)
        external
        view
        override
        returns (
            bool exists,
            string memory igoId,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        RandomnessStorage.RandomnessStruct storage strg = RandomnessStorage
            .layout();

        exists = strg.s_requests[requestId].exists;
        igoId = strg.s_requests[requestId].igoId;
        fulfilled = strg.s_requests[requestId].fulfilled;
        randomWords = strg.s_requests[requestId].randomWords;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRandomnessWritable {
    /// @dev Assumes the subscription is funded sufficiently.
    function requestRandomWords(string memory igoId)
        external
        returns (uint256 requestId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRandomnessWritableInternal {
    event RequestSent(uint256 indexed requestId, uint32 indexed randPerRequest);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OwnableInternal} from "solidstate-solidity/access/ownable/OwnableInternal.sol";

// interfaces
import {IRandomnessWritable} from "./IRandomnessWritable.sol";
// contracts
import {RandomnessWritableInternal} from "./RandomnessWritableInternal.sol";

abstract contract RandomnessWritable is
    IRandomnessWritable,
    RandomnessWritableInternal,
    OwnableInternal
{
    function requestRandomWords(string memory igoId)
        external
        override
        onlyOwner
        returns (uint256 requestId)
    {
        return _requestRandomWords(igoId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IRandomnessWritableInternal} from "./IRandomnessWritableInternal.sol";
import {RandomnessStorage} from "../RandomnessStorage.sol";

abstract contract RandomnessWritableInternal is IRandomnessWritableInternal {
    function _requestRandomWords(string memory igoId)
        internal
        returns (uint256 requestId)
    {
        RandomnessStorage.RandomnessStruct storage strg = RandomnessStorage
            .layout();

        RandomnessStorage.SharedVRFSetUp memory sharedSetup = strg.sharedSetup;

        requestId = sharedSetup.COORDINATOR.requestRandomWords(
            sharedSetup.keyHash,
            sharedSetup.s_subscriptionId,
            sharedSetup.requestConfirmations,
            sharedSetup.callbackGasLimit,
            sharedSetup.randPerRequest
        );

        strg.s_requests[requestId] = RandomnessStorage.RequestStatus({
            exists: true,
            igoId: igoId,
            fulfilled: false,
            randomWords: new uint256[](0)
        });

        strg.requestsOf[igoId].requestIds.push(requestId);
        strg.requestsOf[igoId].lastRequestId = requestId;
        strg.requestsOf[igoId].lastReqTime = block.timestamp;

        emit RequestSent(requestId, sharedSetup.randPerRequest);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// contracts
import {WhitelistReadable} from "./readable/WhitelistReadable.sol";
import {WhitelistWritable} from "./writable/WhitelistWritable.sol";

abstract contract Whitelist is WhitelistReadable, WhitelistWritable {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

library WhitelistStorage {
    struct WhitelistStruct {
        // igoId => last request index
        mapping(string => uint256) lastIndexProcessed;
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
    function lastIndexProcessed(string memory igoId)
        external
        view
        returns (uint256)
    {
        return WhitelistStorage.layout().lastIndexProcessed[igoId];
    }
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

    error WhitelistWritableInternal__MaxWinnersReached();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OwnableInternal} from "solidstate-solidity/access/ownable/OwnableInternal.sol";

// interfaces
import {IWhitelistWritable} from "./IWhitelistWritable.sol";
// libraries
import {RandomnessStorage} from "../../randomness/RandomnessStorage.sol";
import {WhitelistStorage} from "../WhitelistStorage.sol";
// contracts
import {WhitelistWritableInternal} from "./WhitelistWritableInternal.sol";

contract WhitelistWritable is
    IWhitelistWritable,
    WhitelistWritableInternal,
    OwnableInternal
{
    // TODO: gas optimise this function
    // TODO: fuzz test
    function transformRandomsAndPickWinners(
        string calldata igoId,
        address[] calldata addrs,
        uint256 batchesBy_500
    ) external override onlyOwner {
        emit Winners(
            igoId,
            _transformRandomsAndPickWinners(igoId, addrs, batchesBy_500)
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
        string memory igoId,
        address[] calldata addrs,
        uint256 batchesBy_500
    ) internal returns (address[] memory winners) {
        uint256 participants = addrs.length;
        uint256 amountWinners = batchesBy_500 * 500; // better with or without var ?
        require(amountWinners < participants, "winners >= participants");
        // saves gas, instead of passing as memory directly
        address[] memory addresses = addrs;

        winners = new address[](amountWinners);

        ////////// Fetch Randoms Words Received For an IGO //////////
        RandomnessStorage.RandomnessStruct storage rdmStr = RandomnessStorage
            .layout();
        uint256[] memory fulfilledRequests = rdmStr
            .requestsOf[igoId]
            .fulfilledRequests;
        // saves ~5,500 gas
        uint256[] memory randoms_;

        /** @dev Last index from `fulfilledRequests` processed. Helps to avoid
         *       re-processing the same request of randoms
         */
        uint256 lastIndexProcessed = WhitelistStorage
            .layout()
            .lastIndexProcessed[igoId];
        // if all requests processed revert, to avoid wasting gas
        if (lastIndexProcessed == fulfilledRequests.length) {
            revert WhitelistWritableInternal__MaxWinnersReached();
        }

        for (uint256 index; index < batchesBy_500; ++index) {
            randoms_ = rdmStr
                .s_requests[fulfilledRequests[lastIndexProcessed]]
                .randomWords;

            // yul saves ~10M gas
            assembly {
                let memoryPos
                let newWinnerPos
                let newLength

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
                } lt(i, 500) {
                    i := add(i, 1)
                } {
                    // memory array:
                    //  - index at 0 is array.length
                    //  - index of data stored starts at 1
                    memoryPos := shl(5, add(i, 1))

                    // add 1 to index as addresses[] is in memory
                    newWinnerPos := shl(
                        5,
                        add(
                            // randoms_[memoryPos] % participants
                            mod(mload(add(randoms_, memoryPos)), participants),
                            1
                        )
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
                    // winners deleted, then update with new amount of participants
                    mstore(participants, mload(addresses))
                }
            }
            ++lastIndexProcessed;
        }
        WhitelistStorage.layout().lastIndexProcessed[
            igoId
        ] = lastIndexProcessed;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VRFCoordinatorV2Interface} from "chainlink/interfaces/VRFCoordinatorV2Interface.sol";

import {Lottery} from "../../../../src/lottery/Lottery.sol";

import {Randomness} from "../../../../src/lottery/randomness/Randomness.sol";
import {RandomnessStorage} from "../../../../src/lottery/randomness/RandomnessStorage.sol";

contract Mock_Lottery is Lottery {
    constructor(
        VRFCoordinatorV2Interface COORDINATOR,
        uint64 s_subscriptionId,
        bytes32 keyHash
    ) Lottery(COORDINATOR, s_subscriptionId, keyHash) {}

    /*//////////////////////////////////////////////////////////////
                                    MOCK - RANDOMNESS
    //////////////////////////////////////////////////////////////*/
    function workaround_fulfillRandomWords(
        string memory igoId,
        uint256 requestId,
        uint256[] memory randomWords
    ) public {
        RandomnessStorage.RandomnessStruct storage strg = RandomnessStorage
            .layout();

        //////////////// request randoms ////////////////
        strg.s_requests[requestId] = RandomnessStorage.RequestStatus({
            exists: true,
            igoId: igoId,
            fulfilled: false,
            randomWords: new uint256[](0)
        });
        strg.requestsOf[igoId].requestIds.push(requestId);
        strg.requestsOf[igoId].lastRequestId = requestId;
        strg.requestsOf[igoId].lastReqTime = block.timestamp;

        //////////////// fulfill randoms ////////////////
        require(strg.s_requests[requestId].exists, "request not found");
        strg.requestsOf[igoId].fulfilledRequests.push(requestId);
        strg.s_requests[requestId].fulfilled = true;
        strg.s_requests[requestId].randomWords = randomWords;
    }

    function exposed_requestRandomWords(string memory igoId)
        external
        returns (uint256 requestId)
    {
        return _requestRandomWords(igoId);
    }

    function setAmountOfMadeRequests(string memory igoId, uint256 amount)
        external
    {
        uint256[] memory requestIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; ++i) requestIds[i] = i;
        RandomnessStorage.layout().requestsOf[igoId].requestIds = requestIds;
    }

    function setLastRequestTime(string memory igoId, uint256 time) external {
        RandomnessStorage.layout().requestsOf[igoId].lastReqTime = time;
    }

    function manuallyFulfillRandomWords(
        uint256 requestId,
        string memory igoId,
        uint256[] memory randomWords
    ) external {
        RandomnessStorage
            .layout()
            .s_requests[requestId]
            .randomWords = randomWords;

        RandomnessStorage.layout().requestsOf[igoId].fulfilledRequests.push(
            requestId
        );
    }

    /*//////////////////////////////////////////////////////////////
                                    MOCK - WHITELIST
    //////////////////////////////////////////////////////////////*/
    function exposed_transformRandomsAndPickWinners(
        string memory igoId,
        address[] calldata addrs,
        uint256 batchesBy_500
    ) public returns (address[] memory) {
        return _transformRandomsAndPickWinners(igoId, addrs, batchesBy_500);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract RandomsUtils {
    uint256 batchSize = 500;

    function _randomsBy(uint256 fakeSalt)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory mockedRandom = new uint256[](batchSize);
        for (uint256 i; i < batchSize; ++i) {
            mockedRandom[i] = 78409760153098889520 * (fakeSalt + i);
        }

        return mockedRandom;
    }

    /// @dev based on `VRFCoordinatorV2.sol`
    function _requestId(
        bytes32 keyHash,
        address sender,
        uint64 subId,
        uint64 nonce
    ) internal pure returns (uint256) {
        uint256 preSeed = uint256(
            keccak256(abi.encode(keyHash, sender, subId, nonce))
        );
        return uint256(keccak256(abi.encode(keyHash, preSeed)));
    }
}