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
            case 14536696576 {
                t := 1009234065016490143670642952310903348736689710286
                d := 8
            }
            case 14587029504 { t := 60383004448139467871730495694501118488243378880 }
            case 18998718059 { t := 1445520684233052507951276740538164776845236244097 }
            case 23309939817 { t := 212090706643353067814256343770035246263858375204 }
            case 19150365795 {
                t := 118030551394280563684052496165585373000582005315
                d := 6
            }
            case 19150365812 {
                t := 157226045514294423063971372220539771509152908379
                d := 6
            }
        }
        t.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), amount * 10 ** d));
    }

    function dripAll() external {
        0xB0C79Ee335f348973b0c041ff4736e1716C824cE.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(10e8)));
        0x0A93AAe58941F230551cDE0E0A8310d49C989aC0.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200e18)));
        0xfD3363A7c824318846E4c06A227Dd0286a2c0E81.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(30_000e18)));
        0x252679E8cD8C40b4bF99A50Aba47CB5880182a24.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e18)));
        0x14AcaC47f89627a8C920CdCA796f9f0a0E3F8243.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e6)));
        0x1B8a427Cc2AD01d3109F46aaC1DEABB9c45f845b.call(abi.encodePacked(bytes4(0x40c10f19), uint256(uint160(msg.sender)), uint256(200_000e6)));
    }
}