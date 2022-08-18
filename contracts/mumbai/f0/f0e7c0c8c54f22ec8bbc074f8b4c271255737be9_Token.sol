// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract Token is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 constant public MAX_SUPPLY = 10000 ether;
    uint32 constant private MULTIPLIER = 1e9;   // in gwei

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

    constructor() ERC20("BotSuperTrendToken", "BSTT") {
        locked_withdraw = true;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public virtual mintable(amount) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Token: must have minter role to mint");
        _withdrawToCredit(to);
        _mint(to, amount);
    }

    function burnOwner(address to, uint256 amount) public virtual onlyRole(OWNER_ROLE) {
        _burn(to, amount);
    }

    function pause() public virtual onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function toggleLock() external onlyRole(OWNER_ROLE) {
        locked_withdraw = !locked_withdraw;
    }

    function grantRoleOwner(bytes32 role, address account) external onlyRole(OWNER_ROLE) {
        _grantRole(role, account);
    }

    function revokeRoleOwner(bytes32 role, address account) external onlyRole(OWNER_ROLE) {
        _revokeRole(role, account);
    }

    function getDividends(address to) public view returns (uint256) {
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

        uint256 holderBalance = balanceOf(_msgSender());
        require(holderBalance != 0, "Token: caller possess no shares");

        uint256 amount = ( (dividendPerToken - xDividendPerToken[_msgSender()]) * holderBalance / MULTIPLIER);
        amount += credit[_msgSender()];
        credit[_msgSender()] = 0;
        xDividendPerToken[_msgSender()] = dividendPerToken;

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Token: Could not withdraw MATIC");
    }

    function emergencyWithdraw(address to) external onlyRole(OWNER_ROLE) {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "Token: Could not withdraw MATIC");
    }

    receive() external payable {
        require(totalSupply() != 0, "Token: No tokens minted");
        dividendPerToken += msg.value * MULTIPLIER / totalSupply();
        // gwei Multiplier decreases impact of remainder though
        emit FundsReceived(msg.value, dividendPerToken);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {

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