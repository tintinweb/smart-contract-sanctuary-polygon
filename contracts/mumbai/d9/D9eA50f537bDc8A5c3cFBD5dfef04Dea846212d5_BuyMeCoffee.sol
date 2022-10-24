//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BuyMeCoffee {
    // Event to emit when a Memo is created
    event NewMemo(
        address from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of all memos recieved by friends
    Memo[] memos;

    // Address of contract deployer
    address payable owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender); 
    }
    
    /**
    * @dev buy a coffee for contract owner
    * @param _name name of the coffee buyer
    * @param _message a nice message from the coffee buyer 
    */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy coffee with 0 MATIC.");
        
        // Add the memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit log event when new memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
    * @dev send the entire balance stored in this contract to the owner
    */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
    * @dev retrieve all the memos recieved and stored on the blockchain
    */
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }    
}