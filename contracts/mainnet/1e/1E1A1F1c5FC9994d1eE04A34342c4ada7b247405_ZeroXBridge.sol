pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

interface ZeroXERC20 {
      function transformERC20(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    ) external payable returns (uint256 outputTokenAmount);
}

pragma solidity ^0.8.6;
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "./interfaces/ZeroXERC20.sol";

struct ZeroXParams {
    address fromToken;
    address toToken;
    uint256 amountInPercentage;
    uint256 minAmountOut;
    Transformation[] transformations;
}

contract ZeroXBridge {
    event DEFIBASKET_ZEROX_SWAP(uint256 receivedAmount);

    function swap(
        address zeroXaddress,
        address approveAddress,
        ZeroXParams calldata params        
    ) external {
        uint256 amount = IERC20(params.fromToken).balanceOf(address(this))*params.amountInPercentage/100000;
        IERC20(params.fromToken).approve(approveAddress, amount);

        ZeroXERC20 zerox = ZeroXERC20(zeroXaddress);

        uint256 receivedAmount = zerox.transformERC20(
            params.fromToken,
            params.toToken,
            amount,
            params.minAmountOut,
            params.transformations
        );

        emit DEFIBASKET_ZEROX_SWAP(receivedAmount);
    }
}