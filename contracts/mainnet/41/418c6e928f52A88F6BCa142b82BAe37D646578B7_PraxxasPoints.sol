/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (int);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract PraxxasPoints is Context {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOutBlockAdjusted(address indexed of_, uint256 blockSet);
    event LockToggled(bool status);
    event BypassBlockRecord(string indexed direction, address indexed of_);
    event SellingReceiptModified(address indexed receiptAddress);
    event TokensBought(uint256 quantity);
    event SellingTokenModified(address indexed buyToken);
    event SellingPriceModified(uint256 newPrice);
    event QuantityForSaleModified(uint256 newQuantity);
    event SellingStatusToggled(bool status);

    struct TokenSelling {
        address buyTokenAddress;
        address receiptAddress;
        uint256 price;
        uint256 quantityForSale;
        bool active;
        uint256 totalSold;
    }
    TokenSelling private _tokenSelling;

    struct TokenSettings {
        address owner;
        bool locked;
    }
    TokenSettings private _tokenSettings;

    struct TokenInformation {
        uint256 totalSupply;
        string name;
        string symbol;
        string logoURL;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }
    TokenInformation private _tokenInformation;

    struct TokenAuthorization {
        address[] approvedTransferToAddressesArray;
        mapping(address => bool) approvedTransferToAddresses;
        address[] approvedTransferFromAddressesArray;
        mapping(address => bool) approvedTransferFromAddresses;
        mapping(address => uint256) mostRecentTransferOutBlock;
    }
    TokenAuthorization private _tokenAuthorization;

    modifier zeroAddressCheck(address check_) { require(check_ != address(0), "ERC20: Involves zero address"); _; }
    modifier isOwner() { require(_msgSender() == _tokenSettings.owner, "ERC20: Not owner"); _; }
    modifier lockCheck() { if(_msgSender() != _tokenSettings.owner) { require(!_tokenSettings.locked, "ERC20: Token locked"); } _; }

    constructor(string memory name_, string memory symbol_, uint256 initialMint_) {
        _tokenSelling.active = false;

        _tokenSettings.owner = _msgSender();
        _tokenSettings.locked = false;

        _tokenInformation.name = name_;
        _tokenInformation.symbol = symbol_;

        _tokenAuthorization.approvedTransferFromAddresses[_msgSender()] = true;

        _tokenInformation.totalSupply += initialMint_;
        _tokenInformation.balances[_msgSender()] += initialMint_;

        emit Transfer(address(0), _msgSender(), initialMint_);
    }

    function owner() public view returns (address) { return _tokenSettings.owner; }
    function name() public view returns (string memory) { return _tokenInformation.name; }
    function symbol() public view returns (string memory) { return _tokenInformation.symbol; }
    function logoURL() public view returns (string memory) { return _tokenInformation.logoURL; }
    function decimals() public pure returns (uint8) { return 18; }
    function totalSupply() public view returns (uint256) { return _tokenInformation.totalSupply; }
    function balanceOf(address account_) public view returns (uint256) { return _tokenInformation.balances[account_]; }
    function allowance(address owner_, address spender_) public view returns (uint256) { return _tokenInformation.allowances[owner_][spender_]; }
    function approvedTransferToAddress(address address_) public view returns (bool) { return _tokenAuthorization.approvedTransferToAddresses[address_]; }
    function approvedTransferFromAddress(address address_) public view returns (bool) { return _tokenAuthorization.approvedTransferFromAddresses[address_]; }
    function lockStatus() public view returns (bool) { return _tokenSettings.locked; }
    function mostRecentTransferOutBlock(address address_) public view returns (uint256) { return _tokenAuthorization.mostRecentTransferOutBlock[address_]; }
    function sellingActive() public view returns (bool) { return _tokenSelling.active; }
    function sellingPrice() public view returns (uint256) { return _tokenSelling.price; }
    function sellingTokenFor() public view returns (address) { return _tokenSelling.buyTokenAddress; }
    function sellingReceipt() public view returns (address) { return _tokenSelling.receiptAddress; }
    function sellingQuantity() public view returns (uint256) { return _tokenSelling.quantityForSale; }
    function totalSold() public view returns (uint256) { return _tokenSelling.totalSold; }

    function changeOwner(address newOwner_) public isOwner zeroAddressCheck(newOwner_) {
        _tokenSettings.owner = newOwner_;
    }
    function changeLogoURL(string memory logoURL_) public isOwner {
        _tokenInformation.logoURL = logoURL_;
    }

    function buyToken(uint256 quantity_) public {
        require(quantity_ > 0, "ERC20: Quantity <= 0");
        require(balanceOf(address(this)) >= quantity_, "ERC20: Balance < Quantity");

        _tokenSelling.totalSold = _tokenSelling.totalSold + quantity_;
        unchecked {
            _tokenSelling.quantityForSale = _tokenSelling.quantityForSale - quantity_;
        }

        IERC20(_tokenSelling.buyTokenAddress).transferFrom(_msgSender(), _tokenSelling.receiptAddress, (quantity_ * _tokenSelling.price) / 10 ** decimals());

        _transfer(address(this), _msgSender(), quantity_);

        emit TokensBought(quantity_);
    }

    function depositTokensToSell(uint256 quantity_) public isOwner {
        require(quantity_ > 0, "ERC20: Quantity <= 0");

        _tokenSelling.quantityForSale = _tokenSelling.quantityForSale + quantity_;

        _transfer(_msgSender(), address(this), quantity_);
        
        emit QuantityForSaleModified(_tokenSelling.quantityForSale);
    }

    function withdrawTokensFromSelling(uint256 quantity_) public isOwner {
        require(balanceOf(address(this)) >= quantity_, "ERC20: Quantity > Balance");

        unchecked {
            _tokenSelling.quantityForSale = quantity_ > _tokenSelling.quantityForSale ? 0 : _tokenSelling.quantityForSale - quantity_;
        }

        _transfer(address(this), _msgSender(), quantity_);
        
        emit QuantityForSaleModified(_tokenSelling.quantityForSale);
    }

    function modifyReceiptAddress(address receiptAddress_) public isOwner zeroAddressCheck(receiptAddress_) {
        _tokenSelling.receiptAddress = receiptAddress_;

        emit SellingReceiptModified(receiptAddress_);
    }

    function modifySellingToken(address tokenAddress_) public isOwner zeroAddressCheck(tokenAddress_) {
        _tokenSelling.buyTokenAddress = tokenAddress_;
        
        emit SellingTokenModified(_tokenSelling.buyTokenAddress);
    }

    function modifySellingPrice(uint256 price_) public isOwner {
        require(price_ > 0, "ERC20: Price <= 0");

        _tokenSelling.price = price_;
        
        emit SellingPriceModified(_tokenSelling.price);
    }

    function toggleSellingActive() public isOwner {
        _tokenSelling.active = !_tokenSelling.active;
        
        emit SellingStatusToggled(_tokenSelling.active);
    }

    function toggleLock() public isOwner {
        _tokenSettings.locked = !_tokenSettings.locked;

        emit LockToggled(_tokenSettings.locked);
    }

    function adjustTransferOutBlock(address address_, uint256 block_) public isOwner {
        _tokenAuthorization.mostRecentTransferOutBlock[address_] = block_;

        emit TransferOutBlockAdjusted(address_, block_);
    }

    function toggleApproveTransferToAddress(address[] memory addresses_) public isOwner {
        for(uint i=0; i<addresses_.length; i++) {
            _tokenAuthorization.approvedTransferToAddresses[addresses_[i]] = !_tokenAuthorization.approvedTransferToAddresses[addresses_[i]];

            emit BypassBlockRecord("to", addresses_[i]);
        }
    }

    function toggleApproveTransferFromAddress(address[] memory addresses_) public isOwner {
        for(uint i=0; i<addresses_.length; i++) {
            _tokenAuthorization.approvedTransferFromAddresses[addresses_[i]] = !_tokenAuthorization.approvedTransferFromAddresses[addresses_[i]];

            emit BypassBlockRecord("from", addresses_[i]);
        }
    }

    function transfer(address to_, uint256 amount_) public returns (bool) {
        _transfer(_msgSender(), to_, amount_);
        return true;
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        _spendAllowance(from_, _msgSender(), amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(_msgSender(), spender_, allowance(_msgSender(), spender_) + addedValue_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        require(allowance(_msgSender(), spender_) >= subtractedValue_, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender_, allowance(_msgSender(), spender_) - subtractedValue_);
        }

        return true;
    }

    function _transfer(address from_, address to_, uint256 amount_) internal zeroAddressCheck(from_) zeroAddressCheck(to_) lockCheck {
        _beforeTokenTransfer(from_, to_, amount_);

        uint256 fromBalance = _tokenInformation.balances[from_];
        require(fromBalance >= amount_, "ERC20: transfer amount exceeds balance");
        unchecked {
            _tokenInformation.balances[from_] = fromBalance - amount_;
        }
        _tokenInformation.balances[to_] += amount_;

        if(!_tokenAuthorization.approvedTransferFromAddresses[from_] && from_ == _msgSender()) {
            if(!_tokenAuthorization.approvedTransferToAddresses[to_]) {
                _tokenAuthorization.mostRecentTransferOutBlock[from_] = block.number;
            }
        }

        emit Transfer(from_, to_, amount_);

        _afterTokenTransfer(from_, to_, amount_);
    }

    function _approve(address owner_, address spender_, uint256 amount_) internal zeroAddressCheck(owner_) zeroAddressCheck(spender_) lockCheck {
        _tokenInformation.allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function _spendAllowance(address owner_, address spender_, uint256 amount_) internal {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount_, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
            }
        }
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal {}

    function _afterTokenTransfer(address from_, address to_, uint256 amount_) internal {}
}