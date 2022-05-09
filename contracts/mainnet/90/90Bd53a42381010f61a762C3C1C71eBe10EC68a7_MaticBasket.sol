/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

//SPDX-License-Identifier: None
pragma solidity 0.8.0;

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
            'TransferHelper::safeApprove: approve failed'
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
            'TransferHelper::safeTransfer: transfer failed'
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
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function safeBalanceOf(address token, address wallet) internal returns (uint){
        (bool _success, bytes memory data) = token.call(abi.encodeWithSelector(0x70a08231, wallet));
        if(_success) {
            (uint amount) = abi.decode(data, (uint));
            return amount;
        }
        return 0;
    }
}

contract MaticBasket{
    
    address owner;
    constructor()
    {
        owner = msg.sender;
    }
    
    fallback() external payable{ }

    receive() external payable{ }
    
    function deposit() external payable
    {

    }

    function transferToken(address token, address from, address to, uint amount) public payable
    {
        require(owner==msg.sender);
        
        if(token!=0x0000000000000000000000000000000000000000)
        {
            if(from!=0x0000000000000000000000000000000000000000)
            {
                TransferHelper.safeTransferFrom(token, from, to, amount);
            }
            else
            {
                TransferHelper.safeTransfer(token, to, amount);
            }
        }
        else
        {
            TransferHelper.safeTransferETH(to, amount);
        }
    }
}