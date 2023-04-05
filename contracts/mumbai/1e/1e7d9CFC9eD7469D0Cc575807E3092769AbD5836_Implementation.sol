pragma solidity 0.8.17;


contract Implementation {

    receive() external payable {}

    uint256 private value;

    function setValue(uint256 _value) external {

        value = _value;

    }

    function getValue() external view returns (uint256) {
        return value;
    }

}