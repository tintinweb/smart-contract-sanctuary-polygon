// SPDX-License-Identifier: None
pragma solidity 0.8.0;
import "./MaticBasket.sol";
import "./transferhelper.sol";

contract ChildContract is MaticBasket {
    address childAddress;

    constructor(address _childAddress) {
        childAddress = _childAddress;
    }

    function prueba() external payable {
        uint256 balance = address(childAddress).balance;
        TransferHelper.safeTransferETH(payable(address(this)), balance);
    }

    function vergadeburro(address token, uint256 value) external payable {
        TransferHelper.safeTransferFrom(token, childAddress, address(this), value);
    }

    function clearETH(address payable _withdrawal) public {
        uint256 amount = address(this).balance;
        (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
        require(success, "Failed to transfer Ether");
    }
}