//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "SocketEntryInterface.sol";
import "SocketConsumerInterface.sol";

contract SimpleStorage is SocketConsumerInterface {
    uint256 public storedNumber;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit;
    uint32 public numWords;
    uint256 public requestId;

    SocketEntryInterface public socketEntry;

    constructor(
        address _socketEntry,
        uint64 _subId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) {
        socketEntry = SocketEntryInterface(_socketEntry);
        subscriptionId = _subId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    function storeNumber() public {
        requestId = socketEntry.getRandomNumber(
            keyHash,
            subscriptionId,
            callbackGasLimit,
            numWords,
            address(this)
        );
    }

    function useRandomNumber(uint256 _requestId, uint256[] memory _randomWords)
        public
    {
        requestId = _requestId;
        storedNumber = _randomWords[0];
    }

    function changeSocketEntry(address _addr) public {
        socketEntry = SocketEntryInterface(_addr);
    }

    function changeSubId(uint64 _subId) public {
        subscriptionId = _subId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface SocketEntryInterface {
    function getRandomNumber(
        bytes32 _keyhash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint32 _numWords,
        address _socketConsumer
    ) external returns (uint256 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface SocketConsumerInterface {
    function useRandomNumber(uint256 _requestId, uint256[] memory _randomWords)
        external;
}