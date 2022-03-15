/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract OpList {

    address payable public immutable OWNER;
    address private immutable PARENT;
    uint public immutable createdTime;
    uint public opId;
    Post[] public posts;
    Post public lastPost;
    struct Post{
        uint id;
        string opinion;
        uint opTime;
    }
//event
    event OpCreated(address creator, string op, uint opTime);
    event TipReceived(address tipper, uint tipAmount, bytes32 tip);
    event ReOpCreated(address OWNER, string op, uint reOpTime);
    event Rugged(address user, uint amount);

//constructor
    constructor(address creator) {
        OWNER = payable(creator);
        PARENT = msg.sender;
        createdTime = block.timestamp;
        posts.push(Post({id: 0, opinion: "Hello World", opTime: createdTime}));
        emit OpCreated(OWNER, "Hello World", createdTime);
    }

    /**
     * @dev Repost to msg.senders OpList
     * @return data of delegateCall
     */
    function ReOp() public payable returns (bytes memory) {
        
        string memory _op = posts[opId].opinion;
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = PARENT.delegatecall(
            abi.encodeWithSignature("TheOpListList", msg.sender )
        );
        require(success = true, "Call did not succeed");
        emit OpCreated(OWNER, _op, block.timestamp);
        emit ReOpCreated(OWNER, _op, block.timestamp);
        return data;
    }

    
    /**
     * @dev Create a post to Post array
     * @param _op Post of the new owner
     */
    function postOp(string calldata _op) public {
        require(OWNER==msg.sender, "Post your opinions on your own list");
        opId++; // Added before creation so that the id can be used to call the last post function.
        posts.push(Post({id: opId, opinion: _op, opTime: block.timestamp }));
        emit OpCreated(OWNER, _op, block.timestamp);
    }

    /**
     * @dev Withdraw funds sent to the contract
     */
    function Rug() external{
        require(OWNER==msg.sender, "You may not withdraw from this contract");
        uint _amt = address(this).balance;
        (bool sent, ) = OWNER.call{value: _amt}("");
        require(sent, "Failed to withdraw Ether");
        emit Rugged(OWNER, _amt);
    }

    fallback() external payable {
         if(msg.value>1){
        emit TipReceived(msg.sender, msg.value, bytes32(msg.data));
    }}

    receive() external payable {
        if(msg.value>1){
        emit TipReceived(msg.sender, msg.value, bytes32(block.timestamp));        
    }}
}


contract TheOpList{

    mapping(address => OpList) public TheOpListList;
    mapping(address => bool) public created;
    OpList public oplists;

//events

    /**
     * @dev Create a List Contract for the user interacting with the contract
     * @return address of new OpList contract
     */
    function create() public returns (OpList) {
        require(created[msg.sender]==false, "You have a list.");
        OpList oplist = OpList(payable(msg.sender));
        created[msg.sender] = true;
        return oplist;
    }
    
    /**
    * @dev Gets the list of the wallet address provided
    * @param wallet address of owner being looked up
    * @return listAddress Address of Lookup
    * @return timeCreated The time that the OpList was created
    * @return txnTime The time of the call.
    */
    function getList(address wallet) public view returns (address listAddress, uint timeCreated, uint txnTime) {
        OpList oplist = TheOpListList[wallet];
        return (oplist.OWNER(), oplist.createdTime(), block.timestamp);
    }
}