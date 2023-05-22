// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Wallet.sol";

contract WalletFactory {
    mapping(bytes => address) private deployedWallets;

    mapping(address => bool) private permitted;

    receive() external payable {}

    constructor() {
        permitted[msg.sender] = true;
    }

    modifier senderIsPermitted() {
        require(
            permitted[msg.sender],
            "You are not permitted to perfom this action"
        );
        _;
    }

    modifier addressZeroCheck(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    modifier amountIsLessThanBalance(uint amount, uint balance) {
        require(
            balance >= amount,
            "You do not have sufficient assets to make this transaction"
        );
        _;
    }

    modifier walletIsCreated(bytes memory salt, bool created) {
        require(isCreated(salt) == created, "Wallet creation state is invalid");
        _;
    }

    function isContract(address account) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        return (size > 0);
    }

    function approve(
        bytes memory salt,
        address erc20,
        address spender
    ) private senderIsPermitted returns (bool) {
        address payable account = payable(deployedWallets[salt]);
        return Wallet(account).approve(erc20, spender);
    }

    function isPermitted(address account) public view returns (bool) {
        return permitted[account];
    }

    function isCreated(bytes memory salt) public view returns (bool) {
        return deployedWallets[salt] != address(0);
    }

    function getAddress(bytes memory salt) public view returns (address) {
        bytes memory bytecode = type(Wallet).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode());

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                uint256(bytes32(salt)),
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getERC20Balance(
        bytes memory salt,
        address erc20
    ) public view returns (uint256) {
        return IERC20(erc20).balanceOf(deployedWallets[salt]);
    }

    function getETHBalance(bytes memory salt) public view returns (uint256) {
        return address(deployedWallets[salt]).balance;
    }

    function grantPermission(address account) public senderIsPermitted {
        require(!isContract(account), "Account is a smart contract");
        require(!permitted[account], "Account is already permitted");
        permitted[account] = true;
    }

    function revokePermission(address account) public senderIsPermitted {
        require(permitted[account], "Account is not permitted");
        permitted[account] = false;
    }

    function createWallet(
        bytes memory salt
    ) public senderIsPermitted walletIsCreated(salt, false) {
        bytes memory bytecode = type(Wallet).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode());
        uint256 index = uint256(bytes32(salt));

        address walletAddress;

        assembly {
            walletAddress := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                index
            )

            if iszero(extcodesize(walletAddress)) {
                revert(0, 0)
            }
        }

        deployedWallets[salt] = walletAddress;
    }

    function drainETH(
        bytes memory salt
    ) public senderIsPermitted walletIsCreated(salt, true) returns (bool) {
        address payable walletAccount = payable(deployedWallets[salt]);
        return Wallet(walletAccount).drainETH();
    }

    function drainERC20(
        bytes memory salt,
        address erc20
    ) public senderIsPermitted walletIsCreated(salt, true) returns (bool) {
        address account = deployedWallets[salt];
        IERC20 token = IERC20(erc20);

        uint256 allowance = token.allowance(account, address(this));
        uint256 balance = token.balanceOf(account);

        if (allowance < balance) {
            approve(salt, erc20, address(this));
        }

        return token.transferFrom(account, address(this), balance);
    }

    function transferERC20(
        address tracker,
        uint256 amount,
        address to
    )
        public
        senderIsPermitted
        amountIsLessThanBalance(
            amount,
            IERC20(tracker).balanceOf(address(this))
        )
        addressZeroCheck(to)
        returns (bool)
    {
        return IERC20(tracker).transfer(to, amount);
    }

    function transferETH(
        uint256 amount,
        address payable to
    )
        public
        senderIsPermitted
        amountIsLessThanBalance(amount, address(this).balance)
        addressZeroCheck(to)
        returns (bool)
    {
        (bool sent, ) = to.call{value: amount}("");
        return sent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wallet {
    address payable public owner;

    receive() external payable {}

    fallback() external payable {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "You are not permitted to perfom this action"
        );
        _;
    }

    function drainETH() public isOwner returns (bool) {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        return sent;
    }

    function approve(
        address tracker,
        address spender
    ) public isOwner returns (bool) {
        return IERC20(tracker).approve(spender, type(uint256).max);
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