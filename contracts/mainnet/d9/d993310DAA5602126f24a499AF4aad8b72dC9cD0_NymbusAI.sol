// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

contract NymbusAI is ERC20("NYMBUS AI", "NYM") {

    uint16 public transferTaxRate = 0;
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    address public TAXADDRESS;

    mapping(address => bool) public taxFreeList;
    mapping(address => bool) public blacklist;


    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event TaxFreeListUpdated(bool _isSet, address _address);
    event BlacklistUpdated(bool _isSet, address _address);

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function TAXaddress(address _TAXADDRESS) public onlyOwner {
        TAXADDRESS=_TAXADDRESS;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (blacklist[sender] == true) {
            amount = 0;
        } else if (recipient == TAXADDRESS ||
            taxFreeList[sender] == true ||
            taxFreeList[recipient] == true ||
            transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 0% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);

            // default 100% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "NYMBUSAI::transfer: Tax value invalid");

            //_balances() += taxAmount;
            super._transfer(sender, TAXADDRESS, taxAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOwner {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "NYMBUSAI::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }

    function setTaxFreeList(address _address, bool _isSet) public onlyOwner {
        taxFreeList[_address] = _isSet;
        emit TaxFreeListUpdated(_isSet, _address);
    }

    function setBlacklist(address _address, bool _isSet) public onlyOwner {
        blacklist[_address] = _isSet;
        emit BlacklistUpdated(_isSet, _address);
    }

}