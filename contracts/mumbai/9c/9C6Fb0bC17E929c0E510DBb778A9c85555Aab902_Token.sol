// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";

contract Token is ERC20 {

    uint256 private constant MulByDec = 10**18;
    
    // tokenomics wallets
    address public constant main_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;

    // tokenomics supply
    uint public constant main_supply = 21000000 * MulByDec;

    constructor() ERC20("TOKEN NONAME", "NONAME") {
        // set tokenomics balances
        _mint(main_wallet, main_supply);
    }
    
    // ********************************************************************
    // ********************************************************************
    // BURNEABLE FUNCTIONS

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

}