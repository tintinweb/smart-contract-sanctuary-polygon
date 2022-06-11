// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Family_Polygon is ERC20, Ownable, ReentrancyGuard {
    uint public feePercent = 1; /* 1 = 1 / 1000 */
    uint public feeMinimum = 100000000000000000; /* 0.1 */
    uint public feeMaximum = 5000000000000000000; /* 5 */
    address private feeRecipient;

    constructor()
    ERC20("Family", "FML") {
       feeRecipient = _msgSender();
    }

    function setFees(uint _feePercent, uint _feeMinimum, uint _feeMaximum) external onlyOwner {
        feePercent = _feePercent;
        feeMinimum = _feeMinimum;
        feeMaximum = _feeMaximum;
    }

    function mint(address _recipient, uint256 _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "ERC20: Recipient is zero address");
        feeRecipient = _recipient;
    }

    function transferWithFee(address _recipient, uint256 _amount) public nonReentrant returns (bool) {
        uint senderBalance = balanceOf(_msgSender());
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance.");

        uint percentageFee = _amount / 1000 * feePercent;

        uint _realFee = percentageFee <= feeMaximum ? percentageFee : feeMaximum;
        _realFee = percentageFee >= feeMinimum ? percentageFee : feeMinimum;

        _transfer(_msgSender(), feeRecipient, _realFee);
        _transfer(_msgSender(), _recipient, _amount - _realFee);

        return true;
    }

    /*/
     * Overrides
    /*/

    function _msgSender() internal view override(Context) returns (address) {
        return super._msgSender();
    }

    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }
}