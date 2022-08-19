// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./BlackList.sol";

contract DTPBST is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable, ReentrancyGuard, BlackList {

    ERC20 public tokenDividend;

    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

    uint256 constant public MAX_SUPPLY = 3e9;
    uint32 constant private MULTIPLIER = 1e3;   // in gwei

    /// @notice Eth share of each token in gwei
    uint256 dividendPerToken;
    mapping(address => uint256) xDividendPerToken;
    /// @notice Amount that should have been withdrawn
    mapping (address => uint256) credit;

    /// @notice State variable representing amount withdrawn by account in ETH
    mapping (address => uint256) debt;

    /// @notice If locked is true, users are not allowed to withdraw funds
    bool public locked_withdraw;

    event FundsReceived(uint256 amount, uint256 dividendPerToken);

    modifier mintable(uint256 amount) {
        require(amount + totalSupply() <= MAX_SUPPLY, "Token: amount surpasses max supply");
        _;
    }

    constructor() ERC20("DividendToken", "DT") {
        locked_withdraw = false;
        _grantRole(ROLE_ADMIN, _msgSender());
        _grantRole(ROLE_MINTER, _msgSender());
        setDecimals(6);
        tokenDividend = ERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    }

    function getSymbolTokenDividend() external view returns(string memory) {
        return tokenDividend.symbol();
    }

    function setTokenDividend(address token_address) external onlyRole(ROLE_ADMIN) {
        tokenDividend = ERC20(token_address);
    }

    function mint(address to, uint256 amount) public virtual onlyRole(ROLE_MINTER) mintable(amount) {
        require(!paused(), "Token: token mint while paused");
        require(!isBlackListed[to], "Token: User in black list");
        _withdrawToCredit(to);
        _mint(to, amount);
    }

    function burnOwner(address to, uint256 amount) public virtual onlyRole(ROLE_ADMIN) {
        _burn(to, amount);
    }

    function addBlackList(address account_) external virtual onlyRole(ROLE_ADMIN) {
        _addBlackList(account_);
    }

    function removeBlackList(address account_) external virtual onlyRole(ROLE_ADMIN) {
        _removeBlackList(account_);
    }

    function pause() external virtual onlyRole(ROLE_ADMIN) {
        _pause();
    }

    function unpause() external virtual onlyRole(ROLE_ADMIN) {
        _unpause();
    }

    function toggleLock() external onlyRole(ROLE_ADMIN) {
        locked_withdraw = !locked_withdraw;
    }

    function getContractBalanceDividends() external view returns (uint256) {
        return tokenDividend.balanceOf(address(this));
    }

    function getUserBalanceDividends(address to) external view returns (uint256) {
        require(!isBlackListed[to], "Token: User in black list");
        uint256 holderBalance_ = balanceOf(to);
        uint256 amount_ = 0;
        if (holderBalance_ != 0){
            amount_ = ( (dividendPerToken - xDividendPerToken[to]) * holderBalance_ / MULTIPLIER);
            amount_ += credit[to];
            }
        return amount_;
    }

    function withdrawDividends() external nonReentrant {
        require(!locked_withdraw, "Token: contract is currently locked withdraw dividend");
        require(!isBlackListed[_msgSender()], "Token: User in black list");

        uint256 holderBalance = balanceOf(_msgSender());
        require(holderBalance != 0, "Token: caller possess no shares");

        uint256 amount = ( (dividendPerToken - xDividendPerToken[_msgSender()]) * holderBalance / MULTIPLIER);
        amount += credit[_msgSender()];
        credit[_msgSender()] = 0;
        xDividendPerToken[_msgSender()] = dividendPerToken;
        tokenDividend.transfer(_msgSender(), amount);
    }

    function emergencyWithdraw(address to) external onlyRole(ROLE_ADMIN) {
        require(to != address(0), "Token: to is the zero address");
        tokenDividend.transfer(to, tokenDividend.balanceOf(address(this)));
    }

    function depositDividends(uint256 _amount) external {
        require(totalSupply() != 0, "Token: No tokens minted");
        require(tokenDividend.allowance(_msgSender(), address(this)) >= _amount, "Token: amount token allowance");
        tokenDividend.transferFrom(_msgSender(), address(this), _amount);
        dividendPerToken += _amount * MULTIPLIER / totalSupply();
        emit FundsReceived(_amount, dividendPerToken);
    }

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