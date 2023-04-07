// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SafeERC20.sol";
import { IERC20 } from "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./NativeMetaTransaction.sol";

// Politixel Bridge
contract PolitixelV3Bridge is ReentrancyGuard, Pausable, NativeMetaTransaction {
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    event Lock(address indexed user, uint256 amount);
    event Release(address indexed user, uint256 amount, string parentHashProof);
    event RemoveLiquidity(address indexed triggeredBy, uint256 amount);
    mapping(string => bool) public parentHashesProof;

    constructor(IERC20 _token) {
        _initializeEIP712("PolitixelV3Bridge", "1");
        token = _token;
    }

    function removeLiquidity(uint256 _amount) external onlyOwner nonReentrant {
        token.safeTransfer(owner(), _amount);
        emit RemoveLiquidity(msg.sender, _amount);
    }

    function lockTokens(uint256 _amount) external whenNotPaused nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Lock(msg.sender, _amount);
    }

    function releaseTokens(
        address _user,
        uint256 _amount,
        string memory parentHashProof
    ) external whenNotPaused onlyOwner nonReentrant {
        require(parentHashesProof[parentHashProof] == false, "Parent Tx Hash already exists");
        parentHashesProof[parentHashProof] = true;
        token.safeTransfer(_user, _amount);
        emit Release(_user, _amount, parentHashProof);
    }

    /// Withdraw any IERC20 tokens accumulated in this contract
    function withdrawTokens(IERC20 _token) external onlyOwner nonReentrant {
        require(token != _token, "Cant withdraw the Liquidity Providing tokens");
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }

    /**
     * This is used instead of msg.sender
     */
    function _msgSender() internal view override returns (address) {
        return ContextMixin.msgSender();
    }

    //
    // IMPLEMENT PAUSABLE FUNCTIONS
    //
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}