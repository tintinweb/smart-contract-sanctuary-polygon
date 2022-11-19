//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {SocketConsumerBase} from "SocketConsumerBase.sol";

contract SimpleStorage is SocketConsumerBase {
    uint256 public storedNumber;
    uint256 public s_requestId;

    constructor(
        address _socketEntry,
        bytes32 _keyhash,
        uint64 _socketId,
        uint32 _callbackGasLimit,
        uint32 _numWords
    )
        SocketConsumerBase(
            _socketEntry,
            _keyhash,
            _socketId,
            _callbackGasLimit,
            _numWords
        )
    {}

    function storeNumber() public {
        s_requestId = socketEntry.getRandomNumber(
            keyhash,
            socketId,
            callbackGasLimit,
            numWords,
            address(this)
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        storedNumber = randomWords[0] % 50;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {SocketEntryInterface} from "SocketEntryInterface.sol";

abstract contract SocketConsumerBase {
    SocketEntryInterface public socketEntry;
    bytes32 public keyhash;
    uint64 public socketId;
    uint32 public callbackGasLimit;
    uint32 public numWords;

    constructor(
        address _socketEntry,
        bytes32 _keyhash,
        uint64 _socketId,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) {
        socketEntry = SocketEntryInterface(_socketEntry);
        keyhash = _keyhash;
        socketId = _socketId;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        require(msg.sender == address(socketEntry), "!socket entry");
        fulfillRandomWords(requestId, randomWords);
    }

    function updateCallbackGasLimit(uint32 _callbackGasLimit) public {
        callbackGasLimit = _callbackGasLimit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface SocketEntryInterface {
    function getRandomNumber(
        bytes32 _keyhash,
        uint64 _socketId,
        uint32 _callbackGasLimit,
        uint32 _numWords,
        address _consumerContract
    ) external returns (uint256 requestId);
}