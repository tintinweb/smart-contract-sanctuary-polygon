pragma solidity ^0.6.12;

import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

/**
 * @title ERC20 token with ERC-2612 extension (https://eips.ethereum.org/EIPS/eip-2612)
 * @author Mikhail Strelkov <[email protected]>
 */
contract ERC2612TokenVld is ERC20Burnable, ERC20Permit {

    /**
     * @param _totalSupply Total supply of tokens, minted to account deploying this contract
     */
    constructor(uint256 _totalSupply, string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) public {
        _mint(msg.sender, _totalSupply);
    }


}