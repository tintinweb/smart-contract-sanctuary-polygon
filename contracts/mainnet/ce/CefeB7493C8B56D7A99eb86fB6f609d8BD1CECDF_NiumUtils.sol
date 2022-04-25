pragma solidity ^0.8.4;

contract NiumUtils {
    event EchoValue(string value);

    constructor() {} // solhint-disable-line no-empty-blocks

    function echo(string memory value) public {
        emit EchoValue(value);
    }
}