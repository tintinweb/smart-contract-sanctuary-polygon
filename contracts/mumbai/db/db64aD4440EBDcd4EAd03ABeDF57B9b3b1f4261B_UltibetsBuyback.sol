// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Interface/IUltiBetsToken.sol";

interface IUniswapV2Router02 {
    function swapETHForExactTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory);

    function WETH() external view returns (address);
}

contract UltibetsBuyback is Ownable {
    uint256 public nTokenThreshold;
    uint256 public utbetsThreshold;
    address public uniswapRouter;
    address public utbetsToken;

    event BoughtUTBETS(uint256 ethAmount);
    event BurntUTBETS(uint256 utbetsAmount);

    constructor(
        address _utbetsToken,
        address _uniswapRouter,
        uint256 _nTokenThreshold,
        uint256 _utbetsThreshold
    ) {
        require(_utbetsToken != address(0));
        require(_uniswapRouter != address(0));
        utbetsToken = _utbetsToken;
        uniswapRouter = _uniswapRouter;
        nTokenThreshold = _nTokenThreshold;
        utbetsThreshold = _utbetsThreshold;
    }

    receive() external payable {
        if (address(this).balance >= nTokenThreshold) {
            buybackUTBETS();
        }
    }

    function getPathForETHtoUTBETS() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = utbetsToken;

        return path;
    }

    function burnUTBETS() public {
        uint256 amount = IUltiBetsToken(utbetsToken).balanceOf(address(this));
        if (amount >= utbetsThreshold) {
            IUltiBetsToken(utbetsToken).burn(amount);
            emit BurntUTBETS(amount);
        }
    }

    function buybackUTBETS() public {
        uint256 amount = address(this).balance;
        uint256 deadline = block.timestamp + 15;

        IUniswapV2Router02(uniswapRouter).swapETHForExactTokens{value: amount}(
            0,
            getPathForETHtoUTBETS(),
            address(this),
            deadline
        );
        emit BoughtUTBETS(amount);

        burnUTBETS();
    }

    function withdrawUTBETS(address _receiver) public onlyOwner {
        uint256 amount = IUltiBetsToken(utbetsToken).balanceOf(address(this));
        require(amount > 0, "No UTBETS to withdraw!");
        IUltiBetsToken(utbetsToken).transfer(_receiver, amount);
    }

    function withdrawNToken(address _receiver) external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw!");
        payable(_receiver).transfer(address(this).balance);
    }

    function setThreshold(uint256 _nTokenThreshold, uint256 _utbetsThreshold)
        public
        onlyOwner
    {
        nTokenThreshold = _nTokenThreshold;
        utbetsThreshold = _utbetsThreshold;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.17;

interface IUltiBetsToken {
    
    function allowance(address, address) external view returns(uint256);

    function approveOrg(address, uint256) external;
    
    function burn(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
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