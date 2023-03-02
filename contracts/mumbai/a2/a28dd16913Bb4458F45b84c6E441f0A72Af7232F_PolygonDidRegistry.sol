/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// https://mumbai.polygonscan.com/address/0x8b335a167da81ccef19c53ee629cf2f6291f2255#code

/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 *@title PolygonDidRegistry
 *@dev Smart Contract for Polygon DID Method
 */
contract PolygonDidRegistry {
    uint256 totalDIDs;
    address owner;
    uint256 deletedDID;
    struct PolyDID {
        address controller;
        uint256 created;
        uint256 updated;
        string didDoc;
    }

    // this effectively restricts the modified function
    // only to the specified condition
    // https://www.tutorialspoint.com/solidity/solidity_function_modifiers.htm
    //
    // note that the CONTROLLER is a property of the DID,
    // not of the contract
    modifier onlyController(address _id) {
        require(
            polyDIDs[_id].controller == msg.sender,
            "message sender is not the controller of the DID Doc"
        );
        _;
    }
    // "mapping(k => v) mapName; is .sol for dictionary with
    //  key type k and value type v
    // https://www.geeksforgeeks.org/solidity-mappings/"
    mapping(address => PolyDID) polyDIDs;
    mapping(uint256 => address) activeDIDs;
    mapping(address => uint256) activeAddress;
    event DIDCreated(address id, string doc);
    event DIDUpdated(address id, string doc);
    event DIDDeleted(address id);
    event TransferOwnership(address newOwner);
    bool private initialized;

    /**
     *@dev initializes the ownership of contract
     **/

    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        owner = msg.sender;
        totalDIDs = 0;
        deletedDID = 0;
    }

    function aboutMe() pure public returns (string memory) {
        return ("This is my smart contract, v 1.0\n");
    }

    // only owner OF THIS CONTRACT
    // note that "owner" is a state variable of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "message sender is not the owner");
        _;
    }

    /**
     *@dev transfer the ownership of contract
     *@param _newOwner - Address of the new owner to whom the ownership needs to be passed
     **/

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        returns (string memory)
    {
        if (owner != _newOwner) {
            owner = _newOwner;
            emit TransferOwnership(owner);
            return ("Ownership transferred successfully");
        } else {
            return ("Ownership cannot be transferred to the same account");
        }
    }

    /**
     *@dev Reads contract owner from chain
     */

    function getOwner() public view returns (address _owner) {
        return owner;
    }

    /**
     *@dev Register a new DID
     *@param _id - Address that will refer the DID doc
     *@param _doc - A string object that holds the DID Doc
     */

    // memory is a keyword used to store data for the execution of a contract.
    // It holds functions argument data and is wiped after execution.
    // https://www.educative.io/answers/storage-vs-memory-in-solidity
    function createDID(address _id, string memory _doc)
        public
        returns (
            address controller,
            uint256 created,
            uint256 updated,
            string memory didDoc
        )
    {
        polyDIDs[_id].controller = msg.sender;
        polyDIDs[_id].created = block.timestamp;
        polyDIDs[_id].updated = block.timestamp;
        // assuming deep copy, aka copy by value
        polyDIDs[_id].didDoc = _doc;
        activeDIDs[totalDIDs] = msg.sender;
        activeAddress[_id] = totalDIDs;
        ++totalDIDs;
        emit DIDCreated(_id, _doc);
        return (
            polyDIDs[_id].controller,
            polyDIDs[_id].created,
            polyDIDs[_id].updated,
            polyDIDs[_id].didDoc
        );
    }

    /**
     *@dev Reads DID Doc from Chain
     *@param _id - Address that refers to the DID doc position
     */

    function getDIDDoc(address _id) public view returns (string memory) {
        return polyDIDs[_id].didDoc;
    }

    /**
     *@dev Reads total number of DIDs and total number of active DIDs from Chain
     */

    function getTotalNumberOfDIDs()
        public
        view
        returns (uint256 _totalDIDs, uint256 _activeDIDs)
    {
        return (totalDIDs, (totalDIDs - deletedDID));
    }

    /**
     *@dev Reads total number of DIDs deleted from Chain
     */

    function getTotalNumberOfDeletedDIDs()
        public
        view
        returns (uint256 _deletedDID)
    {
        return deletedDID;
    }

    /**
     *@dev Reads one DID at a time from Chain based on index
     *@param _index - Uint256 type variable that refers to the DID position
     *@return _did - returns the DID Doc assciated with the index. Returns null if the DID Doc is deleted.
     */

    function getDIDDOcByIndex(uint256 _index)
        public
        view
        returns (string memory)
    {
        return polyDIDs[activeDIDs[_index]].didDoc;
    }

    /**
     *@dev To Update the DID doc
     *@param _id - Address that refers to the DID doc
     *@param _doc - A String that holds the DID doc
     */

    function updateDIDDoc(address _id, string memory _doc)
        public
        onlyController(_id)
        returns (
            address controller,
            uint256 created,
            uint256 updated,
            string memory didDoc
        )
    {
        polyDIDs[_id].didDoc = _doc;
        polyDIDs[_id].updated = block.timestamp;
        emit DIDUpdated(_id, _doc);
        return (
            polyDIDs[_id].controller,
            polyDIDs[_id].created,
            polyDIDs[_id].updated,
            polyDIDs[_id].didDoc
        );
    }

    /**
     *@dev To delete a DID from chain
     *@param _id - Address that refers to the DID doc that need to be deleted
     */

    function deleteDIDDoc(address _id) public onlyController(_id) {
        delete polyDIDs[_id];
        delete activeDIDs[activeAddress[_id]];
        ++deletedDID;
        emit DIDDeleted(_id);
    }
}