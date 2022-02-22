/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: VCMock.sol

library VCMock {
    function getColors(address _adr, bytes3[16] memory _palette)
        external
        pure
        returns (bytes3[40] memory)
    {
        uint256 index = 0;
        bytes20 adr = bytes20(_adr);
        bytes3[40] memory colors;
        for (uint8 i = 0; i <= 19; i++) {
            colors[index] = _palette[
                (
                    (uint256(
                        keccak256(abi.encodePacked(_adr, _rightShift(adr[i])))
                    ) % 16)
                )
            ];
            index++;
            colors[index] = _palette[
                (
                    (uint256(
                        keccak256(abi.encodePacked(_adr, (_leftShift(adr[i]))))
                    ) % 16)
                )
            ];
            index++;
        }
        return colors;
    }

    function _leftShift(bytes1 _byte) private pure returns (bytes1) {
        return (_byte << 4) >> 4;
    }

    function _rightShift(bytes1 _byte) private pure returns (bytes1) {
        return _byte >> 4;
    }
}