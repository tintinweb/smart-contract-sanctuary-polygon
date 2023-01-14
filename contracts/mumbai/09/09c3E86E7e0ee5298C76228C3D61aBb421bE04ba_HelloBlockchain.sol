// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;
pragma experimental ABIEncoderV2;

contract HelloBlockchain {
    enum StateType { Request, Respond }

    StateType public  State;
    address public  Requestor;
    address public  Responder;

    string public RequestMessage;
    string public ResponseMessage;

    constructor(string memory message) {
        Requestor = msg.sender;
        RequestMessage = message;
        State = StateType.Request;
    }

    // call this function to send a request
    function SendRequest(string memory requestMessage) public {

        if (Requestor != msg.sender) {
            revert();
        }

        RequestMessage = requestMessage;
        State = StateType.Request;
    }

    // call this function to send a response
    function SendResponse(string memory responseMessage) public {

        Responder = msg.sender;
        ResponseMessage = responseMessage;
        State = StateType.Respond;
    }

    struct MyStruct {
        uint8 uint8Value;
        uint256 uint256Value;
        string stringValue;
    }

    // call this function to send a struct
    //function SendStruct(MyStruct memory myStruct) public pure returns (uint8 val1, uint256 val2, string memory val3) {
    function SendStruct(MyStruct memory myStruct) public pure returns (uint256 arg2) {
        //val1 = myStruct.uint8Value;
        //val2 = myStruct.uint256Value;
        arg2 = myStruct.uint256Value;
        //val3 = myStruct.stringValue;
    }

    // call this function to send a struct array
    function SendStruct(MyStruct[] memory data) public pure returns (uint256 numOfEntries) {
        numOfEntries = data.length;
    }
}