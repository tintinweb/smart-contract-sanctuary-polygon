/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// File: @opengsn/contracts/src/interfaces/IERC2771Recipient.sol


pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// File: @opengsn/contracts/src/ERC2771Recipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;


/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts/Suit3StorageV2.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


// Struct & Interface

enum MessageType{
    INBOX, // 0
    SENT, // 1
    IMPORTANT, // 2
    ARCHIVE // 3
}

// Structure of messages
struct Message {
    uint256 index; // Index of the message
    string cid; // CID of the encrypted data
    uint256[] files; // Index of the files
    uint256 date; // Date of the delivery
    uint256 expire; // Date of the expiration
    address sender; // The sender
    address[] recipients; // The recipients
}

// Structure of files to upload
struct File {
    uint256 index; // Index of the file
    string cid; // CID of the encrypted data
    string extension; // The extension of the file
    string name; // The name of the file
    uint256 date; // Date of the upload
    uint256 expire; // Date of the expiration
    uint256 size; // The size of the file
    address owner; // Owner of the file
    address[] recipients; // The recipients
}



contract Suit3Storage is ERC2771Recipient {

    // Event when a message is sent
    event SendMessage(address indexed owner, address[] indexed to, string cid, string cidKeys, uint256 expire);

    // Event when a file is stored
    event StoreFile(address indexed owner, address[] indexed to, string cid, string cidKeys, string name, string extension, uint256 size, uint256 expire);

    // Size of the storage per address
    mapping (address => uint256) private storageSize;

    // Owner
    address private owner;

    constructor(address _forwarder){
        owner = _msgSender();
        _setTrustedForwarder(_forwarder);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(getOwner() == _msgSender(), "Caller of the function is not the owner.");
        _;
    }

    /*
    * Function to send message
    * @param _cid
    * @param _cidKeys
    * @param _files
    * @param _expires
    * @param _recipients
    */
    function sendMessage(string memory _cid, string memory _cidKeys, File[] memory _files, uint _expires, address[] memory _recipients) public {

        // Send message to every recipient
        emit SendMessage(_msgSender(), _recipients, _cid, _cidKeys, _expires);

        //for (uint i = 0; i < _recipients.length; i++) {
            //emit SendMessage(_msgSender(), _recipients[i], _cid, _cidKeys, _expires);
        //}

        // Send file
        for (uint i = 0; i < _files.length; i++) {
            emit StoreFile(_msgSender(), _recipients, _files[i].cid, _cidKeys, _files[i].name, _files[i].extension, _files[i].size, _files[i].expire);
            storageSize[_msgSender()] += _files[i].size;
        }

    }

    /*
    * Function to store a file
    * @param _message
    * @param _title
    * @param _dateExpire
    * @param _walletRecipient
    */
    function storeFile(string memory _cidKeys, File[] memory _files, address[] memory _recipients) public {

        // Loop over the files to upload
        for (uint i = 0; i < _files.length; i++) {
            emit StoreFile(_msgSender(), _recipients, _files[i].cid, _cidKeys, _files[i].name, _files[i].extension, _files[i].size, _files[i].expire);
            storageSize[_msgSender()] += _files[i].size;
        }
    }


    /*
    * Function to get the total storage of files
    */
    function getStorage() public view returns (uint256) {
        return storageSize[_msgSender()];
    }
}