pragma solidity ^0.8.6;

import "./interfaces/ParaswapIntefaces.sol";
import "../interfaces/IParaswapBridge.sol";

contract ParaswapBridge is IParaswapBridge {
    function simpleSwap(
        address paraswapAddress,
        address approveAddress,
        SimpleData calldata paraswapParams,
        uint256 amountInPercentage
    ) external override {
        uint256 amount = IERC20(paraswapParams.fromToken).balanceOf(address(this))*amountInPercentage/100000;
        IERC20(paraswapParams.fromToken).approve(approveAddress, amount);

        SimpleData memory updatedDescription = SimpleData({
            fromToken: paraswapParams.fromToken,
            toToken: paraswapParams.toToken,
            fromAmount: amount,
            toAmount: 1,
            expectedAmount: 1,
            callees: paraswapParams.callees,
            exchangeData: paraswapParams.exchangeData,
            startIndexes: paraswapParams.startIndexes,
            values: paraswapParams.values,
            beneficiary: payable(address(this)),
            partner: paraswapParams.partner,
            feePercent: paraswapParams.feePercent,
            permit: paraswapParams.permit,
            deadline: paraswapParams.deadline,
            uuid: paraswapParams.uuid
        });

        ParaswapInterface paraswap = ParaswapInterface(paraswapAddress);

        paraswap.simpleSwap(
            updatedDescription
        );

        emit DEFIBASKET_PARASWAP_SWAP();
    }

    function complexSwap(
        address fromToken,
        address toToken,
        address paraswapAddress,
        address approveAddress,
        bytes memory paraswapData,
        uint256 amountInPercentage
    ) external override {
        uint256 amount = IERC20(fromToken).balanceOf(address(this)) * amountInPercentage / 100000;
        IERC20(fromToken).approve(approveAddress, amount);    

        // Modify paraswapParams in memory
        assembly {
            // Update fromAmount
            let dataPointer := add(paraswapData, 32) // Skip the length field of 'bytes' type
            mstore(add(dataPointer, 68), amount)
            // Update toAmount
            mstore(add(dataPointer, 100), 1)
            // Update expectedAmount
            mstore(add(dataPointer, 132), 115792089237316195423570985008687907853269984665640564039457584007913129639935) // MAX_UINT
            // Update beneficiary
            mstore(add(dataPointer, 176), shl(96, address()))
        }         

        (bool isSuccess, ) = paraswapAddress.call(paraswapData);
        if (!isSuccess) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }        

        emit DEFIBASKET_PARASWAP_SWAP();
    }

    function readBytesFromPosition(bytes memory data, uint256 position) public pure returns (bytes32 result) {
        require(position + 32 <= data.length, "Position out of bounds");

        assembly {
            // Get a pointer to the data location
            let dataPointer := add(data, 32) // Skip the length field of 'bytes' type

            // Calculate the pointer to the starting position
            let startPointer := add(dataPointer, position)

            // Load 32 bytes from the start pointer
            result := mload(startPointer)
        }
    }

    function bytes32ToAddress(bytes32 b) public pure returns (address) {
        return address(uint160(uint256(b)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

interface ParaswapInterface{
    function simpleSwap(
        SimpleData calldata data
    ) external returns (uint256 receivedAmount);

    function multiSwap(SellData memory data) external payable returns (uint256);
}

struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }   
    
struct Path {
    address to;
    uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
    Adapter[] adapters;
}

struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

struct Route {
    uint256 index; //Adapter at which index needs to be used
    address targetExchange;
    uint256 percent;
    bytes payload;
    uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
}

struct SimpleData {
    address fromToken;
    address toToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address[] callees;
    bytes exchangeData;
    uint256[] startIndexes;
    uint256[] values;
    address payable beneficiary;
    address payable partner;
    uint256 feePercent;
    bytes permit;
    uint256 deadline;
    bytes16 uuid;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../Paraswap/interfaces/ParaswapIntefaces.sol";

interface IParaswapBridge{
    event DEFIBASKET_PARASWAP_SWAP();

    function simpleSwap(
        address paraswapAddress,
        address approveAddress,
        SimpleData calldata paraswapParams,
        uint256 amountInPercentage
    ) external;

    function complexSwap(
        address fromToken,
        address toToken,
        address paraswapAddress,
        address approveAddress,
        bytes memory paraswapParams,
        uint256 amountInPercentage
    ) external;
}

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