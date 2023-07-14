//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract message{
    string private newMsg = "Naqeeb is my best friend";

    function displayMessage() public view returns(string memory) {
        return newMsg;
    }

    function changeMsg(string memory _msg) public {
        newMsg = _msg;
    }
}

contract codeMsg{

    function encodeCallA(
        string memory _msg
        ) external pure returns (bytes memory) {
        // Typo and type errors will not compile
        return abi.encodeCall(message.changeMsg, (_msg));
    }
}