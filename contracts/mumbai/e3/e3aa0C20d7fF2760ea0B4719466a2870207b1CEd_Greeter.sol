// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


///////////////////////////////////////////////////////////
// IMPORTS
///////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////
// CLASS
//      *   Description:  Each Greeter instance here manages 
//                        a greeting text variable
//      *   Deployment:   XXXXXXXXXXXXXXXXXXXXXXX
///////////////////////////////////////////////////////////
contract Greeter
{

    // Methods do not return desired data to unity
    // But these events do return desired data to unity
    event OnSetGreetingCompleted(string result);

    // The user who owns the ERC721 instance
    address _owner;


    // Define variable greeting of the type string 
    string _greeting;


    ///////////////////////////////////////////////////////////
    // CONSTRUCTOR
    //      *   Runs when contract is executed
    ///////////////////////////////////////////////////////////
    constructor() 
    {
        _owner = msg.sender;
        _greeting = "Default Greeting";
    }


    ///////////////////////////////////////////////////////////
    // SETTER
    //      *   Set the greeting 
    //      *   Changes contract state, so requires 
    //          ExecuteContractFunction
    ///////////////////////////////////////////////////////////
    function setGreeting(string memory greeting) public 
    {
        // DISCLAIMER -- NOT A PRODUCTION READY CONTRACT
        // require(msg.sender == owner);

        _greeting = greeting;
        //emit OnSetGreetingCompleted(_greeting);
    }


    ///////////////////////////////////////////////////////////
    // GETTER
    // *    Get the greeting 
    // *    Changes no contract state, so requires only 
    //      RunContractFunction
    ///////////////////////////////////////////////////////////
    function getGreeting() public view returns (string memory) 
    {
        // DISCLAIMER -- NOT A PRODUCTION READY CONTRACT
        // require(msg.sender == owner);

        return _greeting;
    }
}