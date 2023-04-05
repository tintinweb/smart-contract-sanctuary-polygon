pragma solidity 0.8.17;


contract Executor {

    function execute(address to, uint256 _value, bytes calldata data) external {

        (bool success, bytes memory result) = to.call{value : _value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

    }


}