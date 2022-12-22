pragma solidity ^0.8.4;

contract Relayer {
    function relay(address relayer, bytes calldata data) external payable returns (bytes memory result)
    {
        bool success;
        (success, result) = relayer.call{value: msg.value}(data);
        require(success, "RELAYER_FAILURE");
        return result;
    }
}