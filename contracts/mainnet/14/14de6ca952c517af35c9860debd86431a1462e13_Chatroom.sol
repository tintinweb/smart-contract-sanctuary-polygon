/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// File contracts/Chatroom.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


/**
  core contract for initialising a chat
  current version only handles one to one chats
  
  the starting procedure of a chat is as follows:
  assuming two persons: Sender and Recipient.
  assumimg Sender knows the wallet address of the Recipient.

  1. Senders calls {requestPeerToPeerChat} to initalise a chat
  , the function should include the following parameters:
    a. recipient => recipient wallet address
    b. streamId => the streamId which Sender will write the message data on
    , (Recipient should listen to this stream for incoming message)
    c. encryptionStreamId => the streamId which the encryption keys file will be written to
    , a end-to-end encryption will be applied on all message
    , for more details of the implementation, please refers to [...]

  2. Recipient call {getChatRequests} to get a list of pending chat request
  , an array of chatId will be returned

  3. Recipient call {acceptPeerToPeerChat} to accept the request
  , the function should include the following parameters:
    a. chatId => the chat Recipient wants to join
    , (can only join a chat that is being invited)
    b. steramId => the streamId which Recipient will write to
    , see streamId of point 1.

  Miscellaneous:
  - the get the metadata of a chat, call {getChatById}
  - if chatId is unknowned, only has the address of the counterpart, use {getChatByAddress}
  - to receive a list of chat a user joined, call {getContactList}
 */
contract Chatroom {
  string private chatAlreadyExist = "Chatroom: Chat already exists";
  string private cannotCreateChatWithSelf = "Chatroom: Cannot create chat with self";
  string private onlyRecipientCanAcceptRequest = "Chatroom: You are not the recipient of this chat";

  struct StreamId {
    address member;
    string streamId;
  }

  struct Chat {
    uint256 chatId;
    address[] members;
    string encryptionStreamId;
    StreamId[] streamIds;
  }

  using Counters for Counters.Counter;
  // counter to keep track of the chatId
  Counters.Counter private _chatIdCounter;

  // mapping of the combination of peer A address => peer B address => chatId
  // two way mappings will be set
  // , chat Id can be accessed in both direction
  mapping(address => mapping(address => uint256)) private _chatIds;
  // mapping of chatId => address[]
  // this mapping is for reverse lookup of member address by a chat id
  mapping(uint256 => address[]) private _chatMembers;
  // mapping of chatId => address => streamId
  // this mapping store the streamId of each members writing to
  mapping(uint256 => mapping(address => string)) private _streamIds;
  // mapping of chatId => encryptionStreamId
  // the contnet on the stream should be used for message end-to-end encryption
  mapping(uint256 => string) private _encryptionStreamIds;
  // mapping of address => address[]
  // this mapping keeps a contact list of a user
  mapping(address => address[]) private _contactList;
  // mapping of address => chatId[]
  // this mapping keeps an array of chat request of each user
  mapping(address => uint256[]) private _chatRequests;
  // mapping of address => chatId => (index of chatId in {_chatRequests})
  // this mapping looks up the index by chatId in the chatRequest
  // for example: address A => chatid A => 1 means the chatid A is on index 1 of {_chatRequests => address A}
  mapping(address => mapping(uint256 => uint256)) private _chatRequestMap;
  
  // function to create chatId by sender and recipient
  // a two way mapping will be set
  function _createChatId(
    address sender,
    address recipient
  ) private returns (uint256) {
    _chatIdCounter.increment();
    uint256 _chatId = _chatIdCounter.current();

    // set the chatId for both sender and recipient
    _chatIds[sender][recipient] = _chatId;
    _chatIds[recipient][sender] = _chatId;

    return _chatId;
  }

  // private function to create chat
  // it creats the chatId for the chat
  // and set the chatMembers mapping
  function _createChats(
    address sender,
    address recipient
  ) private returns (uint256) {
    uint256 _chatId = _createChatId(sender, recipient);
    _chatMembers[_chatId] = [ sender, recipient ];

    return _chatId;
  }

  // function to get chatId by sender and recipient
  function _getChatIdByPeers(
    address sender,
    address recipient
  ) private view returns (uint256) {
    return _chatIds[sender][recipient];
  }

  // function to update the _streamIds mapping
  function _setStreamIds(
    uint256 chatId,
    address sender,
    string memory streamId
  ) private {
    _streamIds[chatId][sender] = streamId;

    return;
  }

  // function to append a new address to the contract list address
  function _setContactList(
    address sender,
    address recipient
  ) private {
    _contactList[sender].push(recipient);

    return;
  }

  // function to append the new chatId to the chatRequest data
  // it first appends the new chatId to the chatRequest array
  // then set the index of the newly appended chatId to the _chatRequestMap
  function _appendChatRequest(
    address recipient,
    uint256 chatId
  ) private {
    // append the chatId to the _chatRequests mapping in specific array idx
    if (_chatRequests[recipient].length == 0) {
      // if the array is empty, append a 0 chatId in the front
      _chatRequests[recipient].push(0);
    }
    _chatRequestMap[recipient][chatId] = _chatRequests[recipient].length;
    _chatRequests[recipient].push(chatId);

    return;
  }

  // function to initialise p2p chat 
  // a chat id will be assigned to each chat
  function requestPeerToPeerChat(
    address recipient,
    string memory streamId,
    string memory encryptionStreamId
  ) public {
    // reject if the user is creating a chat with self
    require(recipient != msg.sender, cannotCreateChatWithSelf);
    // get the userId from both sender and recipient
    require(_getChatIdByPeers(msg.sender, recipient) == 0, chatAlreadyExist);
    // create chat
    uint256 chatId = _createChats(msg.sender, recipient);

    // set streamId
    _setStreamIds(chatId, msg.sender, streamId);
    // set encryption stream
    _encryptionStreamIds[chatId] = encryptionStreamId;
    // add the recipient to the contractList of the sender
    _setContactList(msg.sender, recipient);
    // set chat invitation
    _appendChatRequest(recipient, chatId);

    return;
  }

  function _updateRequestList(
    uint256 chatId
  ) private {
    // find teh index of the chatId in the {_chatRequests} array from {_chatRequestMap}
    uint256 targetIdx = _chatRequestMap[msg.sender][chatId];
    // raise exception if the chatId is not found in the mapping
    require(targetIdx != 0, onlyRecipientCanAcceptRequest);

    // if the chatId is not the last item
    // move the last item to replace the target index
    // then pop the last item
    if (targetIdx < _chatRequests[msg.sender].length - 1) {
      uint256 lastIdx = _chatRequests[msg.sender].length - 1;
      uint256 lastChatId = _chatRequests[msg.sender][lastIdx];
      // replace target from mapping
      _chatRequestMap[msg.sender][lastChatId] = targetIdx;
      // replace chatId from array
      _chatRequests[msg.sender][targetIdx] = lastChatId;
    }
    // pop the last item from the array
    _chatRequests[msg.sender].pop();
    // delete the accept request from teh mapping
    delete _chatRequestMap[msg.sender][chatId];
  }

  function acceptPeerToPeerChat(
    uint256 chatId,
    string memory streamId
  ) public {
    _updateRequestList(chatId);
    _setStreamIds(chatId, msg.sender, streamId);
    address[] memory chatMembers = _chatMembers[chatId];
    for (uint256 index = 0; index < chatMembers.length; index++) {
      if (msg.sender == chatMembers[index]) continue;
      // append all chat members to the contact list
      _setContactList(msg.sender, chatMembers[index]);
    }

    return;
  }


  function _getStreamId(
    uint256 chatId,
    address member
  ) private view returns (StreamId memory) {
    StreamId memory streamId = StreamId(member, _streamIds[chatId][member]);
    
    return streamId;
  }

  function _getStreamIds(
    uint256 chatId,
    address[] memory members
  ) private view returns (StreamId[] memory) {
    // init a empty array of streamId and push by iteration
    StreamId[] memory streamIds = new StreamId[](members.length);

    for (uint256 index = 0; index < members.length; index++) {
      StreamId memory streamId = _getStreamId(chatId, members[index]);
      streamIds[index] = streamId;
    }

    return streamIds;
  }

  // get chat section

  // view function to get data
  // this function provide a lookup by recipient address
  // and return all parameter of a chat
  function getChatByAddresses(
    address sender,
    address recipient
  ) public view returns (Chat memory)  {
    uint256 chatId = _getChatIdByPeers(sender, recipient);
    
    return getChatById(chatId);
  }

  function getChatById(
    uint256 chatId
  ) public view returns (Chat memory) {
    address[] memory members = _chatMembers[chatId];
    StreamId[] memory streamIds = _getStreamIds(chatId, members);
    Chat memory chat = Chat(chatId, members, _encryptionStreamIds[chatId], streamIds);

    return chat;
  }

  // contact list section
  
  function _getContactList(
    address sender
  ) private view returns (address[] memory) {
    return _contactList[sender];
  }

  // public get call to return the user contact list
  // the contact list is only an address of address
  // to get the metadata of a chat, see {getChatByAddress}
  function getContactList() public view returns (address[] memory) {
    return _getContactList(msg.sender);
  }

  // chat invitation section

  function getChatRequests() public view returns (uint256[] memory) {
    return _chatRequests[msg.sender];
  }
}


// File contracts/Chatroom.flatten.sol