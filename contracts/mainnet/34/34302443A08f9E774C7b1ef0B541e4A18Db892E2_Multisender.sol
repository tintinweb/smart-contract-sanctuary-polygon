/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

contract Multisender {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function multicast(address[] memory _to, bytes[] memory _data, uint256[] memory _nativeAmount) payable public {
        require(msg.sender == owner, "!auth");

        uint256 _len = _to.length;
        uint256 _dataLen = _to.length;
        uint256 _nativeAmountLen = _nativeAmount.length;
        require(_len == _dataLen || _len == _nativeAmountLen, "!params");

        for(uint256 i = 0; i < _len;i++) {
            cast(_to[i],
                _dataLen > 0 ? _data[i] : bytes(""),
                _nativeAmountLen > 0 ? _nativeAmount[i] : 0);
        }
    }

    function cast(address _to, bytes memory _data, uint256 ethAmount) internal {
        bytes memory response;
        bool succeeded;
        assembly {
            succeeded := call(sub(gas(), 5000), _to, ethAmount, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)
        }
        require(succeeded, string(response));
    }
}