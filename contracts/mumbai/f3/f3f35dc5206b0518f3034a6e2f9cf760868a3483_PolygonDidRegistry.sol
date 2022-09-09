/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
        string did_doc;
    }

    modifier onlyController(address _id) {
        require(
            did[_id].controller == msg.sender, "message sender is not the controller of the DID Doc"
        );
        _;
    }
    mapping(address => PolyDID) did;
    mapping(uint256 => address) activeDIDs;
    mapping(address => uint256) deleteDIDs;
    event DidCreated(address id, string doc);
    event DidUpdated(address id, string doc);
    event DidDeleted(address id);
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

    modifier onlyOwner(){
        require( msg.sender == owner, "message sender is not the owner");
        _;
    }

    /**
    *@dev transfer the ownership of contract
    *@param _newOwner - Address of the new owner to whom the ownership needs to be passed
    **/

    function transferOwnership(address _newOwner) public onlyOwner() returns (string memory){
        if(owner != _newOwner){
            owner = _newOwner;
            emit TransferOwnership(owner);
            return ("Ownership transferred successfully");
        }
        else {
            return ("New Owner address is equal to original owner address");
        }
    }

    /**
     *@dev Reads contract owner from chain
     */

    function getOwner() public view returns (address _owner){
        return owner;
    }

    /**
     *@dev Register a new DID
     *@param _id - Address that will refer the DID doc
     *@param _doc - A string object that holds the DID Doc
     */

    function createDID(address _id, string memory _doc)
        public
        returns (address controller, uint256 created, uint256 updated, string memory did_doc)
    {
        did[_id].controller = msg.sender;
        did[_id].created = block.timestamp;
        did[_id].updated = block.timestamp;
        did[_id].did_doc = _doc;
        activeDIDs[totalDIDs] = msg.sender;
        deleteDIDs[_id] = totalDIDs;
        ++totalDIDs;
        emit DidCreated(_id, _doc);
        return (did[_id].controller, did[_id].created, did[_id].updated, did[_id].did_doc);
    }

    /**
     *@dev Reads DID Doc from Chain
     *@param _id - Address that refers to the DID doc position
     */

    function getDID(address _id) public view returns (string memory) {
        return did[_id].did_doc;
    }

    /**
     *@dev Reads total number of DIDs from Chain
    */

    function getTotalNumberOfDIDs() public onlyOwner() view returns (uint256 _totalDIDs, uint256 _activeDIDs){
        return (totalDIDs, (totalDIDs-deletedDID));
    }

    /**
     *@dev Reads total number of DIDs deleted from Chain
    */

    function getTotalNumberOfDeletedDIDs() public onlyOwner() view returns (uint256 _deletedDID){
        return deletedDID;
    }

    /**
     *@dev Reads one DID at a time from Chain based on index
     *@param _index - Uint256 type variable that refers to the DID position 
     *@return _did - returns the address associated with DID URI, if the DID is not deleted, else returns empty string.
     */

    function getDIDByIndex(uint256 _index) public onlyOwner() view returns (address _did){
        return activeDIDs[_index];
    }

    function getMultipleDIDsByIndex(uint256 _start, uint256 _count) public view returns (address[] memory, string[] memory){
        address [] memory multiDIDs = new address[](_count);
        string [] memory DIDDocs = new string[](_count);
        uint256 index = 0;
        for(uint256 i = _start-1; i < _start-1 + _count; ++i){
            multiDIDs[index] = activeDIDs[i];
            DIDDocs[index] = did[activeDIDs[i]].did_doc;
            ++index;
        }
        return (multiDIDs, DIDDocs);
    }

    /**
     *@dev To Update the DID doc
     *@param _id - Address that refers to the DID doc
     *@param _doc - A String that holds the DID doc
     */

    function updateDID(address _id, string memory _doc)
        public
        onlyController(_id) returns(address controller, uint256 created, uint256 updated, string memory did_doc)
    {
        did[_id].did_doc = _doc;
        did[_id].updated = block.timestamp;
        emit DidUpdated(_id, _doc);
        return (did[_id].controller, did[_id].created, did[_id].updated, did[_id].did_doc);
    }

    /**
     *@dev To delete a DID from chain
     *@param _id - Address that refers to the DID doc that need to be deleted
     */

    function deleteDID(address _id) public onlyController(_id) {
        ++deletedDID;
        delete did[_id];
        delete activeDIDs[deleteDIDs[_id]];
        emit DidDeleted(_id);
    }
}