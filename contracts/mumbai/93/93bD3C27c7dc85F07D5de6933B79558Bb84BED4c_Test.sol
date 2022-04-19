pragma solidity ^0.8.5;

contract Test{

    string _name;

      constructor(
        string memory name
    )
    {
        _name = name;
    }

    function version() public pure returns (uint256) {
        return 1;
    }
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}