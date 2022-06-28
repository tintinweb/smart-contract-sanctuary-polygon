//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiFunctionTest {
    event BroadcastStringState(string result);
    string _stringState;
    address _ogOwner;
    address _owner;

    constructor(string memory state) {
        _stringState = state;
        _owner = msg.sender;
        _ogOwner = msg.sender;
    }

    // Take a string and returns it.
    function echo(string memory _str) public pure returns (string memory) {
        return _str;
    }

    // Set the contract's _stringState variable.
    function setString(string memory _str) public {
        _stringState = _str;
    }

    // Fires the Broadcast State event with the current _stringState value.
    function fireBroadcastStringState() public {
        emit BroadcastStringState(_stringState);
    }

    // Takes two integers and returns their sum.
    function sum(int256 _a, int256 _b) public pure returns (int256 _sum) {
        return _a + _b;
    }

    // Transfers ownership to a new owner and returns true if successful; false
    // if unsuccessful (ie if someone other than the owner tried to change the
    // ownership).
    function setOwner(address _newOwner) public returns (bool success) {
        if (msg.sender != _owner && msg.sender != _ogOwner) {
            return false;
        }
        _owner = _newOwner;
        return true;
    }
}

// contract MoriaGates {
//     event CorrectPassword(bool result);
//     bytes32 private _magicPassword;

//     address owner;

//     constructor(bytes32 magicPassword) {
//         _magicPassword = magicPassword;
//         owner = msg.sender;
//     }

//     function openGates(string memory password) public {
//         //DISCLAIMER -- NOT PRODUCTION READY CONTRACT
//         //require(msg.sender == owner);

//         if (hash(password) == _magicPassword) {
//             emit CorrectPassword(true);
//         } else {
//             emit CorrectPassword(false);
//         }
//     }

//     function hash(string memory stringValue) internal pure returns (bytes32) {
//         return keccak256(abi.encodePacked(stringValue));
//     }
// }

// import "hardhat/console.sol";

// contract Greeter {
//     string private greeting;

//     constructor(string memory _greeting) {
//         console.log("Deploying a Greeter with greeting:", _greeting);
//         greeting = _greeting;
//     }

//     function greet() public view returns (string memory) {
//         return greeting;
//     }

//     function setGreeting(string memory _greeting) public {
//         console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
//         greeting = _greeting;
//     }
// }