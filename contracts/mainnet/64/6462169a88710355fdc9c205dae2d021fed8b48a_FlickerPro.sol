/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: contracts/FLICKER.sol


contract FlickerPro {

    // The keyword "public" makes variables accessible from outside a contract
    // and creates a function that other contracts or SDKs can call to access the value
    string public message;

    // A special function only run during the creation of the contract
    constructor(string memory initMessage) public {
        // Takes a string value and stores the value in the memory data storage area,
        // setting `message` to that value
        message = initMessage;
    }

    // A publicly accessible function that takes a string as a parameter
    // and updates `message`
    function update(string memory newMessage) public {
        message = newMessage;
    }
}