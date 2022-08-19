// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./BlackList.sol";

contract DRGRS is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable, ReentrancyGuard, BlackList {

    ERC20 public tokenDividend;
    ERC20 tokenSwap;

    uint256 public MAX_SUPPLY;
    uint32 constant private MULTIPLIER = 1e3;

    uint256 dividendPerToken;
    bool public locked_withdraw;

    mapping(address => uint256) xDividendPerToken;
    mapping (address => uint256) credit;

    event ReceivedDividends(uint256 amount, uint256 dividendPerToken);
    event SwapToken(address indexed account, uint256 amount);
    event WithdrawalDividends(address indexed account, uint256 amount);

    constructor() ERC20("DebtRepaymentGRcoinSwap", "DRGRS") {
        locked_withdraw = false;
        _grantRole(ROLE_ADMIN, _msgSender());
        setDecimals(6);
        tokenDividend = ERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        tokenSwap = ERC20(0x7e22535A83AFeFa54C9c67Fa8655Bc9b6C0EA5DC);
    }

    //=================================== MINTER ==============================================

    function burnOnlyAdmin(address to, uint256 amount) public virtual onlyRole(ROLE_ADMIN) {
        _burn(to, amount);
    }

    function swapToken(uint256 amount) external {
        require(tokenSwap.allowance(_msgSender(), address(this)) >= amount, "Token: no permission to transfer tokens");
        tokenSwap.transferFrom(_msgSender(), address(this), amount);
        _withdrawToCredit(_msgSender());
        uint256 swap_amount = amount / 1e12;
        _mint(_msgSender(), swap_amount);
        MAX_SUPPLY += swap_amount;
        emit SwapToken(_msgSender(), swap_amount);
    }

    //=================================== BLACKLIST ==============================================

    function addBlackList(address account_) external virtual onlyRole(ROLE_ADMIN) {
        _addBlackList(account_);
    }
    function removeBlackList(address account_) external virtual onlyRole(ROLE_ADMIN) {
        _removeBlackList(account_);
    }
    function setPause() external virtual onlyRole(ROLE_ADMIN) {
        _pause();
    }
    function setUnpause() external virtual onlyRole(ROLE_ADMIN) {
        _unpause();
    }

    //=================================== DEPOSIT ==============================================

    function getTokenBalanceDividends() external view returns (uint256) {
        return tokenDividend.balanceOf(address(this));
    }
    function getUserBalanceDividends(address to) public view returns (uint256) {
        uint256 holderBalance_ = balanceOf(to);
        uint256 amount_ = 0;
        if (holderBalance_ != 0){
            amount_ = ( (dividendPerToken - xDividendPerToken[to]) * holderBalance_ / MULTIPLIER);
            amount_ += credit[to];
            }
        return amount_;
    }
    function withdrawAllDividendsUser() external nonReentrant {
        require(!locked_withdraw, "Token: contract is currently locked withdraw dividend");
        require(!isBlackListed[_msgSender()], "Token: User in black list");
        uint256 amount = getUserBalanceDividends(_msgSender());
        require(amount != 0, "Token: caller possess no shares");
        credit[_msgSender()] = 0;
        xDividendPerToken[_msgSender()] = dividendPerToken;
        tokenDividend.transfer(_msgSender(), amount);
        emit WithdrawalDividends(_msgSender(), amount);
    }
    function withdrawAllDividendsAdmin(address to) external onlyRole(ROLE_ADMIN) {
        require(to != address(0), "Token: to is the zero address");
        tokenDividend.transfer(to, tokenDividend.balanceOf(address(this)));
    }
    function withdrawDividendsAdmin(address from, address to) external onlyRole(ROLE_ADMIN) {
        require(to != address(0), "Token: to is the zero address");
        uint256 amount = getUserBalanceDividends(from);
        require(amount != 0, "Token: caller possess no shares");
        credit[from] = 0;
        xDividendPerToken[from] = dividendPerToken;
        tokenDividend.transfer(to, amount);
        emit WithdrawalDividends(from, amount);
    }
    function depositDividends(uint256 _amount) external {
        require(totalSupply() != 0, "Token: No tokens minted");
        require(tokenDividend.allowance(_msgSender(), address(this)) >= _amount, "Token: amount token allowance");
        tokenDividend.transferFrom(_msgSender(), address(this), _amount);
        dividendPerToken += _amount * MULTIPLIER / totalSupply();
        emit ReceivedDividends(_amount, dividendPerToken);
    }

    //=================================== TOKEN ==============================================

    function changeName(string memory name_) external onlyRole(ROLE_ADMIN) {
        setName(name_);
    }
    function changeTokenDividend(address token_address) external onlyRole(ROLE_ADMIN) {
        tokenDividend = ERC20(token_address);
    }
    function changeLock() external onlyRole(ROLE_ADMIN) {
        locked_withdraw = !locked_withdraw;
    }
    function getSymbolTokenDividend() external view returns(string memory) {
        return tokenDividend.symbol();
    }

    //=================================== PRIVATE ==============================================

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        require(!isBlackListed[_msgSender()], "Token: User in black list");
        super._beforeTokenTransfer(from, to, amount);
        if(from == address (0) || to == address(0)) return;
        // receiver first withdraw funds to credit
        _withdrawToCredit(to);
        _withdrawToCredit(from);
    }

    function _withdrawToCredit(
        address to_
    ) private
    {
        uint256 recipientBalance = balanceOf(to_);
        if(recipientBalance != 0) {
            uint256 amount = ( (dividendPerToken - xDividendPerToken[to_]) * recipientBalance / MULTIPLIER);
            credit[to_] += amount;
        }
        xDividendPerToken[to_] = dividendPerToken;
    }
}