// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";

contract MiticoToken is ERC20, Owner {

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklist;

    // properties used to get fee
    uint256 private constant amountDivToGetFee = 10**4;

    uint256 public amountMulToGetAditionalFee = 0; //example: 100 = 1%

    uint256 private constant MulByDec = 10**18;
    
    // tokenomics wallets
    address public constant main_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;
    address public fees_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;

    // tokenomics supply
    uint public constant main_supply = 9999999999 * MulByDec;

    constructor() ERC20("TEST TOKEN", "MITITEST") {
        // set tokenomics balances
        _mint(main_wallet, main_supply);

        _isExcludedFromFee[main_wallet] = true;
    }

    function setPercentageToGetAditionalFee(uint256 _newValue) external isOwner {
        amountMulToGetAditionalFee = _newValue;
    }

    function excludeFromFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
             _isExcludedFromFee[accounts[i]] = true;
        }
    }
    function includeInFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = false;
        }
    }
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
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

    function getAdditionalFee(uint256 _value) private view returns(uint256){
        uint256 aditionalFee = 0;
        aditionalFee = (_value*amountMulToGetAditionalFee)/amountDivToGetFee;
        return aditionalFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "ERC20: transfer amount must be greater than 0");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(!_blacklist[from] && !_blacklist[to], "ERC20: from or to address are in blacklist");
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }else{
            uint256 aditionalFee = getAdditionalFee(amount);
            if(aditionalFee>0){
                _balances[fees_wallet] += aditionalFee;
                emit Transfer(from, fees_wallet, aditionalFee);
            }
            _balances[to] += amount-aditionalFee;
            emit Transfer(from, to, amount-aditionalFee);
        }

        unchecked {
            _balances[from] = fromBalance-amount;
        }
        _afterTokenTransfer(from, to, amount);
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