// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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

    // The user who owns the Greeter instance
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

    function getTest() public
    {
        // DISCLAIMER -- NOT A PRODUCTION READY CONTRACT
        // require(msg.sender == owner);

        //do nothing...
    }
}