// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract SimpleUSD2 is ERC20, ERC20Burnable, Pausable, Ownable {   
    using SafeERC20 for IERC20;

    event userBlacklisted(address account);
    event userRemovedFromBlacklist(address account);

    mapping(address => bool) public isBlacklisted;

    constructor(address _owner) ERC20("Stable_Test2", "ST2") {
        _mint(_owner, 10_000_000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function blacklist(address account) external onlyOwner {
        require(!isBlacklisted[account], "ERC20: user is already blacklisted");
        isBlacklisted[account] = true;
        emit userBlacklisted(account);
    }

    function removeBlacklist(address account) external onlyOwner {
        require(isBlacklisted[account], "ERC20: user is not blacklisted");
        isBlacklisted[account] = false;
        emit userRemovedFromBlacklist(account);
    }

    function recoverToken(
        address tokenAddress,
        address walletAddress,
        uint256 amount
    ) external onlyOwner {
        require(walletAddress != address(0), "ERC20: Null address");
        require(
            amount <= IERC20(tokenAddress).balanceOf(address(this)),
            "ERC20: Insufficient amount"
        );
        IERC20(tokenAddress).safeTransfer(walletAddress, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!isBlacklisted[from], "ERC20: sender is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

}