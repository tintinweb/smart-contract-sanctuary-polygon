pragma solidity ^0.8.0;

contract NativeTokenTransfer {
    address payable public owner;

    constructor(address _owner) {
        owner = payable(_owner);
    }

    function transferNativeTokens(address payable _to, uint256 _fee) external payable {
        // Require that the user has sent enough native tokens to cover both the fee and the transfer amount
        require(
            msg.value > _fee,
            "Insufficient native token amount"
        );

        // Transfer the native token fee to the owner
        owner.transfer(_fee);

        // Transfer the remaining native tokens to the recipient
        _to.transfer(msg.value - _fee);
    }
}