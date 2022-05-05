/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint256);
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}


contract Token {
    address public trace;
    event Details(address indexed tokenAddress, string name, string symbol, uint256 decimal);

    function  addAddress(address _trace) public {
        trace = _trace;
    }

    function getDetails(address _tokenAddress) public {
        if(_tokenAddress == trace) {
            emit Details(_tokenAddress,"Trace Network","trace",18);
        }
        else if(_tokenAddress!=address(0)) {
            string memory _name = IERC20(_tokenAddress).name();
            string memory _symbol = IERC20(_tokenAddress).symbol();
            uint256 _decimal = IERC20(_tokenAddress).decimals();
            emit Details(_tokenAddress,_name, _symbol, _decimal);
        }
        else {
            emit Details(_tokenAddress,"Matic", "matic",18);
        }
    }

}