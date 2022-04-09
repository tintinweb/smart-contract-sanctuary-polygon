// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SKPContext.sol";
import "./SafeMath.sol";

contract SKPERC20 is SKPContext, ERC20 {
    using SafeMath for uint256;

    constructor() ERC20("SKY PLAY", "SKP"){
        _mint(_msgSender(), 1e10 * (10 ** uint256(decimals())));
    }

    /**
     * @dev Prevention of deposit errors
     */
    function deposit() payable public {
        require(msg.value == 0, "Cannot deposit ether.");
    }

    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.transfer(to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.approve(spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.transferFrom(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.increaseAllowance(spender, addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.decreaseAllowance(spender, subtractedValue);
        return true;
    }
}