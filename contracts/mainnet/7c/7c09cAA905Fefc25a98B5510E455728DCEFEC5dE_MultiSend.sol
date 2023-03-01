pragma solidity ^0.8.17;

abstract contract ERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);
}

contract MultiSend {
    function multiTransfer(
        address _erc20Address,
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public {
        ERC20 erc20 = ERC20(_erc20Address);

        for (uint256 i = 0; i < _addresses.length; i++) {
            erc20.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }
}