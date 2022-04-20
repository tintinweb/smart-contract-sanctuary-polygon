/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// File: contracts/interfaces/tokens/IWETH.sol

pragma solidity 0.8.4;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File: contracts/Converter.sol

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;


library Converter {

    /**
    * @dev converts uint256 to a bytes(32) object
    */
    function _uintToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
    * @dev converts address to a bytes(32) object
    */
    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function ethToWeth(uint256 amount) external {
        bytes memory _data = abi.encodeWithSelector(IWETH.deposit.selector);
        (bool success, ) = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270).call{value:amount}(_data);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function wethToEth(uint256 amount) external {
        IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270).withdraw(amount);
    }
}