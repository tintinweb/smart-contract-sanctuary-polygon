pragma solidity ^0.8.0;

error IndexError(uint256 _index);

contract AirDropMatic {
    function airdropToReceivers(
        uint256 _amount,
        uint256 _count,
        address[] memory _receivers
    ) external payable {
        require(_amount * _count == msg.value, "!value");
        require(_count == _receivers.length, "count");
        for (uint256 j = 0; j < _count; j++) {
            (bool sent, ) = _receivers[j].call{value: _amount}(""); // don't use send or xfer (gas)
            //   require(sent, "Failed to send Ether");
            if (!sent) {
                revert IndexError({_index: j});
            }
        }
    }
}