// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract GetBalances{
    
    function getBalances(address wallet, IERC20[] memory tokens) external view returns (uint256[] memory balances) {

        uint size = tokens.length;

        balances = new uint256[](size);
        for (uint i=0; i < size; i++) {

            balances[i] = IERC20(tokens[i]).balanceOf(wallet);
            
        }
        
        return balances;

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}