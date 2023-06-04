// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./AnthiWhaleToken.sol";
import "./ERC20Base.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";


/**
 * @dev ERC20Token implementation with Burn, Pause, AntiWhale capabilities
 */
contract ERC20Token is ERC20Base, AntiWhaleToken, ERC20Burnable, ERC20Pausable, Ownable { 
    mapping(address => bool) private _excludedFromAntiWhale;

    event ExcludedFromAntiWhale(address indexed account, bool excluded);
    address payable public feeReceiver;
    constructor (
        
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        uint256 tokensMax_,
        address payable feeReceiver_
    )
        payable
        ERC20Base(name_, symbol_, decimals_)
        AntiWhaleToken(tokensMax_)
    {
        feeReceiver = feeReceiver_;
        feeReceiver.transfer(msg.value);
        require(initialSupply_ > 0, "ERC20Token: initial supply cannot be zero");
        _excludedFromAntiWhale[_msgSender()] = true;
        _mint(_msgSender(), initialSupply_);
    }
    
    
    /**
     * @dev Update the max token allowed per wallet.
     * only callable by `owner()`
     */
    
    
    function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
        _setMaxTokenPerWallet(amount);
    }

    /**
     * @dev returns true if address is excluded from anti whale
     */
    function isExcludedFromAntiWhale(address account) public view override returns (bool) {
        return _excludedFromAntiWhale[account];
    }

    /**
     * @dev Include/Exclude an address from anti whale
     * only callable by `owner()`
     */
    function setIsExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
        _excludedFromAntiWhale[account] = excluded;
        emit ExcludedFromAntiWhale(account, excluded);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by `owner()`
     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by `owner()`
     */
    function burnFrom(address account, uint256 amount) external override onlyOwner {
        _burnFrom(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable, AntiWhaleToken) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Pause the contract
     * only callable by `owner()`
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Resume the contract
     * only callable by `owner()`
     */
    function resume() external override onlyOwner {
        _unpause();
    }
}