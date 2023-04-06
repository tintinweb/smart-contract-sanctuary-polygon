// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//0x2d6b4449124f3f269d62101A3C31E5ed6C60f7D0
//ttps://mumbai.polygonscan.com/address/0x2d6b4449124f3f269d62101A3C31E5ed6C60f7D0#code

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract BuyMeATea {
    //Event to emit when a Memo is create 
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message

    );

    //Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of all memos recieved from friends
    Memo[] memos;

    //Address of contract deployer
    address payable owner;

    //Deploy Logic
    constructor() {
        owner = payable(msg.sender); //cast to allow for future referencing
    }
    /*
    * @dev buy a coffee for contract owner
    * @param _name name of the coffee buyer
    * @param _messafe nessage from buyer
    * Allow user to buy a single tea or box of tea might be worth creating two seperate functions one for  the box and one for the cup
    * 
    * 
    */
    function buyTea(string memory _name, string memory _message)  public payable  {
        //add money to contract

        //check value sent is not zero 
        //automatically set to the amount of ether sent with that payable function.
        require(msg.value > 0, "can't buy coffee with 0 matic");

        //create a new Memo and save into memos array
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message

        ));

        //Emit log event when memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message

        );



    }
    /*
    * @dev send the entire balance stored in this contract to the owner
    */
    function withdrawTips() public {

        //address(this).balance;
        require(owner.send(address(this).balance));
    }
    /*
    * @dev retrieve all memos on contract
    */
    function getMemos() public view returns(Memo[] memory) {
        return memos;

    }
}