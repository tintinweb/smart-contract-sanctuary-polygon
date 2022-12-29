// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SendERC20 {
    address payable public owner;

    event sendERC20(address indexed from, address to, uint indexed amount, bytes32 indexed wlTxId);


    function send(
        address _assetContract,
        address _to,
        uint256 _amount,
        bytes32 _wlTxId
        ) external {
        (bool success, bytes memory returnData) = _assetContract.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
        require(success, string(returnData));
        emit sendERC20(msg.sender, _to, _amount, _wlTxId);
    }
}