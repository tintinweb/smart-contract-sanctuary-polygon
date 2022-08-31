/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
// File: contracts/IBEP20.sol


pragma solidity >=0.4.22 <0.9.0;

interface IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
}
// File: contracts/MigrationV2.sol


pragma solidity >=0.4.22 <0.9.0;


contract MigrationV2 {
    //token
    address public addressV1;
    address public addressV2;

    //track who has already migrated
    mapping(address => bool) private _migrated;

    constructor(address _addressV1, address _addressV2) {
        addressV1 = _addressV1;
        addressV2 = _addressV2;
    }

    function migrate() external {
        address sender = msg.sender;

        //require not already migrated
        require(!isMigrated(sender), "Already migrated");

        //get V1 balance
        uint256 balanceV1 = IBEP20(addressV1).balanceOf(sender);

        //set migrated true
        setMigrated(sender, true);

        //transfer V2 tokens
        IBEP20(addressV2).transfer(payable(sender), balanceV1);

        //get V2 balance (after migration)
        uint256 balanceV2 = IBEP20(addressV2).balanceOf(sender);

        //require sender has received V2 tokens 1:1
        require(balanceV2 == balanceV1, "Sender did not receive V2 tokens or balance did not match");
    }

    function isMigrated(address atAddress) public view returns (bool) {
        return _migrated[atAddress];
    }

    function setMigrated(address atAddress, bool toState) private {
        _migrated[atAddress] = toState;
    }
}