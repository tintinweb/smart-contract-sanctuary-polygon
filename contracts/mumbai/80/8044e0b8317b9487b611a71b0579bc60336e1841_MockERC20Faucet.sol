/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract MockERC20Faucet {
    function drip(string calldata, uint256 amount) external {
        address t;
        uint256 d = 18;
        assembly {
            switch calldataload(72)
            case 0x362746300 {
                t := 0xB0C79Ee335f348973b0c041ff4736e1716C824cE
                d := 8
            }
            case 0x365746800 { t := 0x0A93AAe58941F230551cDE0E0A8310d49C989aC0 }
            case 0x46c696e6b { t := 0xfD3363A7c824318846E4c06A227Dd0286a2c0E81 }
            case 0x56d617469 { t := 0x252679E8cD8C40b4bF99A50Aba47CB5880182a24 }
            case 0x475736463 {
                t := 0x14AcaC47f89627a8C920CdCA796f9f0a0E3F8243
                d := 6
            }
            case 0x475736474 {
                t := 0x1B8a427Cc2AD01d3109F46aaC1DEABB9c45f845b
                d := 6
            }
        }
        t.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(amount * 10 ** d))
        );
    }

    function dripAll() external {
        0xB0C79Ee335f348973b0c041ff4736e1716C824cE.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(10e8))
        );
        0x0A93AAe58941F230551cDE0E0A8310d49C989aC0.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200e18))
        );
        0xfD3363A7c824318846E4c06A227Dd0286a2c0E81.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(30_000e18))
        );
        0x252679E8cD8C40b4bF99A50Aba47CB5880182a24.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e18))
        );
        0x14AcaC47f89627a8C920CdCA796f9f0a0E3F8243.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e6))
        );
        0x1B8a427Cc2AD01d3109F46aaC1DEABB9c45f845b.call{gas: 60_000}(
            abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e6))
        );
    }
}