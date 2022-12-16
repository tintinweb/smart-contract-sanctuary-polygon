// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";

contract Token is ERC20, Owner {

    mapping (address => bool) private _blacklist;

    uint256 private constant MulByDec = 10**18;
    
    // tokenomics wallets
    address public constant main_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;

    // tokenomics supply
    uint public constant main_supply = 115000000 * MulByDec;

    constructor() ERC20("TOKEN LVLX", "LVLX") {
        // set tokenomics balances
        _mint(main_wallet, main_supply);
    }

    function excludeFromBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _blacklist[accounts[i]] = false;
        }
    }
    function includeInBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _blacklist[accounts[i]] = true;
        }
    }
    function isOnBlacklist(address account) external view returns(bool) {
        return _blacklist[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(!_blacklist[from] && !_blacklist[to] && !_blacklist[msg.sender], "ERC20: from, to or sender address are in blacklist");
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