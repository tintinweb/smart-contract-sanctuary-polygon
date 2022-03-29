// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTgiftcard {
    function mintFrom(address _to, uint256 _amount) external returns (bool);
}

contract MintNFTG {
    address admin;
    address nftGiftcard;
    uint256 public price = 360*10**18; // price of NFT in USDT
    uint256 public cardValue = 12000*10**18;
    IERC20 public USDT;

    event MintSuccess(address _to, uint256 _mintAmount);

    constructor(address _nftGiftcard, address _tokenAddress) {
        admin = msg.sender;
        nftGiftcard = _nftGiftcard;
        USDT = IERC20(_tokenAddress);
    }

    /**
     * @dev Mint MTVG for sender
     * @param _to Account to transfer NFT
     * @param _amount price of GiftCard
     */
    function mintFrom(
        address _to,
        uint256 _amount
    ) public {
        require(_to != address(0), "MintNFTG: account is the zero address");
        require(_amount >= price);
        USDT.transferFrom(msg.sender, address(this), _amount);
        bool success = INFTgiftcard(nftGiftcard).mintFrom(_to, cardValue);
        require(success, "Unable to mint");
    }

    /**
     * @dev Mint MTVG for sender
     * @param _to Account to transfer NFT
     * @param _value value of gift card in qwei
     */
    function mintByAdmin(
        address _to,
        uint256 _value
    ) public {
        require(msg.sender == admin, "MintNFTG: Only Admin can mind card for client");
        require(_to != address(0), "MintNFTG: account is the zero address");
        bool success = INFTgiftcard(nftGiftcard).mintFrom(_to, _value);
        require(success, "Unable to mint");
    }

    /**
     * @dev withdraw SHFT token from this contract
     */
    function withdraw() public {
        require(msg.sender == admin, "Only Admin can withdraw");
        uint256 _amount = USDT.balanceOf(address(this));
        bool success = USDT.transfer(msg.sender, _amount);
        require(success, "Unable to withdraw");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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