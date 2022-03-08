/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

pragma solidity 0.5.0;
contract Hello {
    string text;
    event received(
        address _received
    );
    constructor(string memory _text) public {
        text = _text;
    }
    function getText() public view returns(string memory) {
        return text;
    }
    function changeText(string memory _newText) public {
        text = _newText;
    }
    function pay() public payable {
        emit received(msg.sender);
    }
}