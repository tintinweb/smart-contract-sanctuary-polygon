// SPDX-License-Identifier: GNU lesser General Public License
//
// Hate Race is a daily race of the most vile and ugly rats that
// parasitize on society. Our rats have nothing to do with animals,
// they are the offspring of the sewers of human passions.
//
// If you enjoy it, donate our hateteam ETH/MATIC/BNB:
// 0xd065AC4Aa521b64B1458ACa92C28642eB7278dD0

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Address.sol";


abstract contract RatReceivingContract
{
    function tokenFallback(address sender, uint256 amount) public virtual;
}

contract RatToken is ERC20
{
    using Address for address;

    constructor () ERC20("Hate Race", "HATE")
    {
        _mint(address(0xff0826D0C2def99522f8B615Ba0b32e996a7C363), 21000000 * (10 ** decimals()));
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override
    {
        super._transfer(sender, recipient, amount);
        if (recipient.isContract())
        {
            try RatReceivingContract(recipient).tokenFallback(_msgSender(), amount) {} catch {}
        }
    }

    function burn(uint256 amount) public
    {
        _burn(_msgSender(), amount);
    }
}