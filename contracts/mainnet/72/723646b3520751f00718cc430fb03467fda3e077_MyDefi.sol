/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

pragma solidity ^0.8.2;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IWormhole{
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);
    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

}

interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address{
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) { return returndata;} 
        else { if (returndata.length > 0) { assembly {
                                                        let returndata_size := mload(returndata)
                                                        revert(add(32, returndata), returndata_size)
                                                     }
                                          } 
               else { revert(errorMessage); }
            }
    }
}

library SafeERC20{
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0),
                "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }


}

contract MyDefi{

    
    IUniswap uniswap;
    IWormhole bridge;
    
    constructor(address _uniswap) public {
        uniswap = IUniswap(_uniswap);
        // bridge = IWormhole(_bridge);

    }

    function testWrapAndtransferETH(address _bridgeAddress, /*address SwappedTokenAddress,uint256 amountOut,*/ uint16 recipientChainId, bytes32 recipient, uint256 arbiterFeeValue,uint32 nonceValue ) external payable {
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        bridge = IWormhole(_bridgeAddress);
        bridge.wrapAndTransferETH{value: msg.value}(recipientChainId, recipient, arbiterFeeValue, nonceValue);
        // bridge.transferTokens(SwappedTokenAddress, amountOut, recipientChainId, recipient, arbiterFeeValue,nonceValue);
        
        

        }
    function testTransferTokens(address _bridgeAddress,IERC20 token, address CurrentContractAddress, uint256 AmountToCurrentContract,  /*uint256 AllownceValue,*/  address SwappedTokenAddress,uint256 amountOut, uint16 recipientChainId, bytes32 recipient, uint256 arbiterFeeValue,uint32 nonceValue ) external payable{
        // address[] memory path = new address[](2);
        // path[0] = uniswap.WETH();
        // path[1] = token;
        // uniswap.swapExactETHForTokens{value: msg.value}(amountOut,path,receipient,deadline);
        SafeERC20.safeTransferFrom(token, msg.sender, CurrentContractAddress, AmountToCurrentContract);
        
        // SafeERC20.safeIncreaseAllowance(token, _bridgeAddress, AllownceValue);
        bridge = IWormhole(_bridgeAddress);
        // bridge.wrapAndTransferETH(recipientChainId, recipient, arbiterFeeValue, nonceValue);
        bridge.transferTokens{value: msg.value}(SwappedTokenAddress, amountOut, recipientChainId, recipient, arbiterFeeValue,nonceValue);
        
        

        }


}



/*
0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff

0xaca654bdf148d1a5d490f5d1a44b84b4773b934c*/


// approve function --> UST