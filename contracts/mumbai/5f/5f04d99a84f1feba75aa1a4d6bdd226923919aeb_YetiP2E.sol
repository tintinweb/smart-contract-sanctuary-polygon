/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeIncreaseAllowance(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x39509351, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeIncreaseAllowance: IncreaseAllowance failed"
        );
    }

    function safeDecreaseAllowance(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa457c2d7, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeDecreaseAllowance: decreaseAllowance failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

interface IERC20 {
    function allowance(address onwer , address spender) external returns(uint256);
}

contract YetiP2E{
    uint256 id;
    address constant Yetitoken = address(0x6546580BE2f83f9feF0C5C43B8B23059a339E877); 
    struct Players {
        address owner;
        address player;
        uint256 amount;
        uint8 percentage;
    }

    // mapping (address => mapping(address => Players)) public splitter;
    mapping (uint256 => Players) public splitter;
    // mapping (address => uint256) public balances;

    function _deposit(address _player, uint256 _amount) internal {
        // (bool success, bytes memory data) = Yetitoken.call(abi.encodeWithSelector(0xdd62ed3e,msg.sender,_player));

        TransferHelper.safeTransferFrom(Yetitoken,msg.sender,address(this),_amount);
        uint256 _allowance = IERC20(Yetitoken).allowance(address(this), _player);
        if(_allowance > 0 )
            TransferHelper.safeIncreaseAllowance(Yetitoken,_player,_amount);
        else
            TransferHelper.safeApprove(Yetitoken,_player,_amount);

    }

    function setSplit(address _player , uint8 _percent, uint256 _amount) public {
        require (_player != address(0),"Address should not be Zero.");
        require (msg.sender != _player ," You can't split in self address.");
        require (_percent > 0 , "Percentange should be getter than zero.");
        require (_percent <= 100 , "Percentange should be less than zero.");
        require (_amount > 0 , "Amount should be greater than zero.");
        _deposit(_player,_amount);
        Players memory player = Players(msg.sender,_player,_amount,_percent);
        splitter[id+1] = player;
    }

}