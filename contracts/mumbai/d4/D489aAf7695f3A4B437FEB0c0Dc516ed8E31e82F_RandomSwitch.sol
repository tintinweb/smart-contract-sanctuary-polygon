// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "SocketEntryInterface.sol";
import "SocketConsumerInterface.sol";

contract RandomSwitch is SocketConsumerInterface {
    address[] public users;
    address public mainUser;
    address public msgSender;

    SocketEntryInterface public socketEntry;
    uint64 public subId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint32 public numWords;
    uint256 public latestRequestId;

    // TAKE IN A LIST OF ADDRESSES
    // RANDOM NUMBER TAKES THE LENGTH AND DECIDES THE SWITCH
    constructor(
        address[] memory _users,
        address _socketEntry,
        uint64 _subId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) {
        users = _users;
        socketEntry = SocketEntryInterface(_socketEntry);
        subId = _subId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    function switchMainUser() public {
        latestRequestId = socketEntry.getRandomNumber(
            keyHash,
            subId,
            callbackGasLimit,
            numWords,
            address(this)
        );
    }

    function filledRandomNumber(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) public {
        latestRequestId = _requestId;
        uint256 randomNumber = (_randomWords[0] % users.length) + 1;
        mainUser = users[randomNumber];
        msgSender = msg.sender;
    }

    function changeSocketEntry(address _addr) public {
        socketEntry = SocketEntryInterface(_addr);
    }

    function changeSubId(uint64 _subId) public {
        subId = _subId;
    }

    function changeCallbackGasLimit(uint32 _callbackgas) public {
        callbackGasLimit = _callbackgas;
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
    // REQUIRE ONLY THE VRF COORDINATOR TO CALL THIS FUNCTION
    function filledRandomNumber(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external;
}