// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";


contract BurnerMinterERC20 is ERC20, Ownable{
    using Address for address;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
  * @dev Method to withdraw all native currency. Only callable by owner.
      */
    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    /**
      * @dev Method to withdraw all tokens complying to ERC20 interface. Only callable by owner.
      */
    function withdrawERC20(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, "SafeERC20: Balance already 0");

        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, address(this), owner(), token.balanceOf(address(this)));
        bytes memory return_data = address(_token).functionCall(data, "SafeERC20: low-level call failed");
        if (return_data.length > 0) {
            // Return data is optional to support crappy tokens like BNB and others not complying to ERC20 interface
            require(abi.decode(return_data, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}