// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FakeWethGiveawayV2 is Ownable {
    address token;
    uint256 requiredBalance;

    constructor(address _tokenAddress, uint256 _requiredBalance) {
        token = _tokenAddress;
        requiredBalance = _requiredBalance;
    }

    function claimCoinbase() public payable {
        bool shouldDoTransfer = checkCoinbase();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    function claimDifficulty() public payable {
        bool shouldDoTransfer = checkDifficulty();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    function claimBlockBasefee() public payable {
        bool shouldDoTransfer = checkBlockBasefee();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    function claimTxGasprice() public payable {
        bool shouldDoTransfer = checkTxGasprice();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }


    function claimValidatorBalance() public payable {
        bool shouldDoTransfer = checkValidatorBalance();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    function checkCoinbase() private view returns (bool result) {
        assembly {
            result := eq(coinbase(), 0x0000000000000000000000000000000000000000)
        }
    }

    function checkDifficulty() private view returns (bool result) {
        assembly {
            result := eq(difficulty(), 0)
        }
    }

    function checkBlockBasefee() private view returns (bool result) {
        assembly {
            result := eq(basefee(), 1)
        }
    }

    function checkTxGasprice() private view returns (bool result) {
        assembly {
            result := eq(gasprice(), 0)
        }
    }

    function checkValidatorBalance() private view returns (bool result) {
        assembly {
            result := lt(balance(coinbase()), sload(requiredBalance.slot))
        }
    }

    function testBlockDifficulty() public payable onlyOwner {
        IERC20(token).transfer(msg.sender, block.difficulty + 1);
    }

    function testBlockBasefee() public payable onlyOwner {
        IERC20(token).transfer(msg.sender, block.basefee + 1);
    }

    function testBlockValidatorBalance() public payable onlyOwner {
        IERC20(token).transfer(msg.sender, address(block.coinbase).balance + 1);
    }

    function testBlockCoinbase() public payable onlyOwner {
        for (uint256 i; i < 20; i++) {
            bytes1 coinbasebytes = bytes20(address(block.coinbase))[i];
            uint256 amount = uint256(uint8(coinbasebytes));
            IERC20(token).transfer(msg.sender, amount + 1);
        }
    }

    function testBlockCoinbase1() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[0];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase2() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[1];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase3() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[2];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase4() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[3];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase5() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[4];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase6() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[5];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase7() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[6];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase8() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[7];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase9() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[8];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase10() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[9];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase11() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[10];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase12() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[11];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase13() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[12];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase14() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[13];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase15() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[14];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase16() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[15];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase17() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[16];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase18() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[17];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase19() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[18];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testBlockCoinbase20() public payable onlyOwner {
        bytes1 coinbasebytes = bytes20(address(block.coinbase))[19];
        uint256 amount = uint256(uint8(coinbasebytes));
        IERC20(token).transfer(msg.sender, amount + 1);
    }

    function testTxGasPrice() public payable onlyOwner {
        IERC20(token).transfer(msg.sender, tx.gasprice + 1);
    }

    function withdraw() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function updateTestingToken(address _newTokenAddress) public onlyOwner {
        token = _newTokenAddress;
    }

    function updateRequiredBalance(uint256 _newRequiredBalance) public onlyOwner {
        requiredBalance = _newRequiredBalance;
    }

    receive() external payable {}
    fallback() external payable {}
}