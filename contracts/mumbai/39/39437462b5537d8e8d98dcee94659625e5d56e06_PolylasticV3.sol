// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IERC20 } from "./ERC20.sol";
import "./SafeERC20.sol";
import { ERC20 } from "./ERC20.sol";
import { Ownable } from "./Ownable.sol";
import "./Address.sol";

contract PolylasticV3 is Ownable, ERC20 {
    using Address for address;
    using SafeERC20 for IERC20;

    address public bridgeContract;

    address public treasury;

    uint8 burnPercentage = 3;

    uint8 treasuryPercentage = 6;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _treasury
    ) ERC20(_name, _symbol) {
        treasury = _treasury;
        _mint(_msgSender(), _totalSupply * (10**18));
    }

    function updateBurnPercentage(uint8 _percent) external onlyOwner {
        require(_percent <= 100);
        burnPercentage = _percent;
    }

    function updateTreasuryPercentage(uint8 _percent) external onlyOwner {
        require(_percent <= 100);
        treasuryPercentage = _percent;
    }

    function setBridgeContractAddress(address _bridgeContract) external onlyOwner {
        require(_bridgeContract.isContract(), "Bridge Address should be a contract address");
        bridgeContract = _bridgeContract;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (
            _msgSender() != bridgeContract &&
            recipient != bridgeContract &&
            _msgSender() != treasury &&
            recipient != treasury
        ) {
            uint256 burnableTokens = (amount * burnPercentage) / 100;
            uint256 treasuryTokens = (amount * treasuryPercentage) / 100;
            uint256 taxedTokens = burnableTokens + treasuryTokens;
            _burn(_msgSender(), burnableTokens);
            super.transfer(treasury, treasuryTokens);
            super.transfer(recipient, (amount - taxedTokens));
            return true;
        }
        super.transfer(recipient, amount);
        return true;
    }

    function withdrawERC20(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), balance);
    }
}