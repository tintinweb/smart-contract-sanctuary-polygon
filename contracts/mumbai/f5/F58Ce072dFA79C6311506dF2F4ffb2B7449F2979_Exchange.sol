// SPDX-License-Identifier: AGPL-3.0-only

/*
    tpmd-smcs (team promise distributor smart contracts)
    Copyright (C) 2022 polus <https://github.com/polus-dev>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Errors {
    string constant NOT_INITED = "not initialized";

    string constant TOKEN0_SET = "token0 is already set";
    string constant TOKEN1_SET = "token1 is already set";

    string constant INV_AMOUNT = "require: amount > 0";
    string constant INV_ALLOWN = "require: allowance >= amount";

    string constant INV_BALAN0 = "insufficient balance token0";
    string constant INV_BALAN1 = "insufficient balance token1";
}

// Exchange 1:1 (_token0 -> _token1)

contract Exchange is Ownable {
    bool private token0Inited;
    bool private token1Inited;

    IERC20 public token0;
    IERC20 public token1;

    constructor(address _owner) Ownable(_owner) {}

    event SetUpToken(address _token, uint8 _type);
    event Exchanged(address indexed _from, uint256 _amount, uint256 _timestamp);

    function setToken0(address _address) external onlyOwner {
        require(address(token0) == address(0), Errors.TOKEN0_SET);

        token0 = IERC20(_address);
        token0Inited = true;

        emit SetUpToken(_address, 0);
    }

    function setToken1(address _address) external onlyOwner {
        require(address(token1) == address(0), Errors.TOKEN1_SET);

        token1 = IERC20(_address);
        token1Inited = true;

        emit SetUpToken(_address, 1);
    }

    function exchange(uint256 _amount) external {
        require(token0Inited && token1Inited, Errors.NOT_INITED);
        require(_amount > 0, Errors.INV_AMOUNT);

        require(token0.balanceOf(msg.sender) >= _amount, Errors.INV_BALAN0);
        require(token1.balanceOf(address(this)) >= _amount, Errors.INV_BALAN1);

        uint256 allowance = token0.allowance(msg.sender, address(this));
        require(allowance >= _amount, Errors.INV_ALLOWN);

        token0.transferFrom(msg.sender, address(this), _amount);
        token1.transfer(msg.sender, _amount);

        emit Exchanged(msg.sender, _amount, block.timestamp);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    tpmd-smcs (team promise distributor smart contracts)
    Copyright (C) 2022 polus <https://github.com/polus-dev>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) private {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}