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
    //address
    address public addressV1;
    address public addressV2;
    address public burnAddress;
    address public admin;

    //state
    bool private _locked;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not authorized.");
        _;
    }

    constructor(address _addressV1, address _addressV2) {
        admin       = msg.sender;
        addressV1   = _addressV1;
        addressV2   = _addressV2;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
    }

    function migrate() external {
        require(!isLocked(), "Migration is locked");

        address sender = msg.sender;

        //get balance of sender
        uint256 amount = IBEP20(addressV1).balanceOf(sender);

        //transfer V1 tokens to contract
        IBEP20(addressV1).transferFrom(sender, address(this), amount);

        //transfer V2 tokens to sender
        IBEP20(addressV2).transfer(payable(sender), amount);
    }

    function setLocked(bool toState) external onlyAdmin {
        _locked = toState;
    }

    function isLocked() public view returns (bool) {
        return _locked;
    }

    function isAdmin(address atAddress) private view returns (bool) {
        return atAddress == admin;
    }
}