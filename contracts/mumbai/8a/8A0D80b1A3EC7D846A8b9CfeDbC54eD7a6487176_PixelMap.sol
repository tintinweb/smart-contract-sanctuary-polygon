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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PixelMap {
    struct Block {
        string[2][2] colors;
        address owner;
    }

    address public tokenAddress;
    address public burningWallet;
    uint256 public costPerBlock;
    uint256 public costForMint;

    mapping(uint256 => Block) blocks;
    mapping(address => uint256[]) blockIdByOwner;

    constructor(
        address _tokenAddress,
        address _burnAddress,
        uint256 _costPerBlock,
        uint256 _costForMint
    ) {
        tokenAddress = _tokenAddress;
        burningWallet = _burnAddress;
        costPerBlock = _costPerBlock;
        costForMint = _costForMint;
    }

    event BuyBlock(address indexed buyer, uint256 x, uint256 y);
    event Mint(address indexed owner, uint256 x, uint256 y);

    function buyBlock(uint256 x, uint256 y) external {
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            burningWallet,
            costPerBlock
        );

        uint256 blockId = x * 100 + y;

        blockIdByOwner[msg.sender].push(blockId);
        blocks[blockId].owner = msg.sender;

        emit BuyBlock(msg.sender, x, y);
    }

    function mint(
        uint256 x,
        uint256 y,
        string[2][2] memory colors
    ) external {
        uint256 blockId = x * 100 + y;
        require(blocks[blockId].owner == msg.sender, "Not Owner");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            burningWallet,
            costForMint
        );

        blocks[blockId].colors = colors;

        emit Mint(msg.sender, x, y);
    }

    function getBlock(uint256 x, uint256 y) public view returns (Block memory) {
        uint256 blockId = x * 100 + y;
        return blocks[blockId];
    }

    function getBlockIdsByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return blockIdByOwner[owner];
    }
}