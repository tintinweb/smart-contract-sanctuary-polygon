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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import erc20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interface/IGiv3Core.sol";

contract Giv3Treasury {
    uint256 public ethBalance;
    IGiv3Core public GIV3_CORE;

    string public name;

    mapping(address => uint256) public tokenBalances;

    event ETHDeposited(uint256 amount);
    event ETHWithdrawn(uint256 amount, address to);
    event TokenDeposited(IERC20 tokenAddress, uint256 amount);
    event TokenWithdrawn(IERC20 tokenAddress, uint256 amount, address to);

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    constructor(string memory _name, IGiv3Core _giv3Core) {
        name = _name;
        GIV3_CORE = _giv3Core;
    }

    function depositETH() public payable onlyGiv3 {
        ethBalance += msg.value;
        uint256 amount = msg.value;
        emit ETHDeposited(amount);
    }

    function withdrawETH(address to, uint256 amount) public payable onlyGiv3 {
        require(amount <= ethBalance, "Not enough ETH");
        ethBalance -= amount;
        to.call{value: amount}("");
        emit ETHWithdrawn(amount, to);
    }

    function depositToken(IERC20 tokenAddress, uint256 amount) public onlyGiv3 {
        require(amount > 0, "Amount must be greater than 0");
        tokenAddress.transfer(msg.sender, amount);
        emit TokenDeposited(tokenAddress, amount);
    }

    function withdrawToken(
        IERC20 tokenAddress,
        uint256 amount,
        address to
    ) public onlyGiv3 {
        require(amount > 0, "Amount must be greater than 0");
        require(
            tokenAddress.balanceOf(msg.sender) >= amount,
            "Not enough tokens"
        );
        tokenAddress.transfer(to, amount);
        emit TokenWithdrawn(tokenAddress, amount, to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Giv3Treasury.sol";

contract Giv3TreasuryFactory {
    uint256 collectionsCounter = 0;

    // Map Id to collection
    mapping(uint256 => Giv3Treasury) treasuries;

    IGiv3Core public GIV3_CORE;

    event TreasuryCreated(uint256 id, string name);

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    constructor(IGiv3Core _giv3Core) {
        GIV3_CORE = _giv3Core;
    }

    function createTreasury(string memory name)
        public
        onlyGiv3
        returns (Giv3Treasury)
    {
        Giv3Treasury giv3Treasury = new Giv3Treasury(name, GIV3_CORE);

        treasuries[collectionsCounter] = giv3Treasury;
        collectionsCounter++;

        emit TreasuryCreated(collectionsCounter - 1, name);
        return giv3Treasury;
    }

    function getTreasury(uint256 id) public view returns (Giv3Treasury) {
        return treasuries[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGiv3Core {
    function createDAO(
        string memory name,
        string memory symbol,
        string memory metadataHash
    ) external;

    function joinDAO(uint256 _id) external;

    function getContract(uint256 _id) external view returns (address);

    function getPowerLevels(uint256 _id, uint256 _tokenId)
        external
        view
        returns (uint256);
}