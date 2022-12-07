pragma solidity ^0.8.14;

contract Proxy {
    address public source;
    address public amb;

    event ProxyCall(bytes data);

    constructor(address _source, address _amb) {
        source = _source;
        amb = _amb;
    }

    function receiveSuccinct(address sender, bytes calldata _data) public {
        require(msg.sender == amb, "Only telepathy can call this function");
        require(source == sender, "Only source can call this contract");

        (
            address target,
            uint value,
            string memory signature,
            bytes memory data
        ) = abi.decode(_data, (address, uint, string, bytes));

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success,) = target.call{value: value}(callData);
        require(success, "Execution reverted");

        emit ProxyCall(data);
    }
}