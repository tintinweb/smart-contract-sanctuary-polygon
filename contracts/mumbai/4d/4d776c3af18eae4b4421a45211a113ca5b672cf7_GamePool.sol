/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/pools/Pool.sol

// 
pragma solidity ^0.8.0;

abstract contract Pool {
    // 读取其他合约的相关信息，并完成第二次记账和分账
    function distributeFT(address FT, uint64 mainType, uint64 subType, address player, uint256 amount) external virtual;
}


// File contracts/pools/lottery/GamePool.sol

// 
pragma solidity ^0.8.0;

interface IArithmetic {
    function getResult(
        uint seed,
        uint count,
        uint256 totalPool,
        uint256 jackPool
    ) external view returns (
        uint32[] memory winCount,
        uint256 totalPoolMinus,
        uint256 jackPoolMinus
    );
}

contract GamePool is Pool {
    address platform;
    IArithmetic public ARITHMETIC;
    IERC20 public FT;

    uint public jackPool; // jackPool
    uint public gamePool; // gamePool
    uint public adjustPool; // TODO
    bool openJackPool;
    mapping(address => UserAccount) public accounts;

    struct UserAccount {
        uint award; // award
        uint accumulated; // accumulated award
    }

    constructor(address _platform, address _arithmetic, address _FT) {
        platform = _platform;
        ARITHMETIC = IArithmetic(_arithmetic);
        FT = IERC20(_FT);
    }

    function setArithmetic(address _arithmetic) external {
        ARITHMETIC = IArithmetic(_arithmetic);
    }

    function distributeFT(address FT, uint64 mainType, uint64 subType, address player, uint256 amount) external override {
        if (openJackPool) { // 67% => 65% + 2%
            uint256 toJackPool = amount * 2 / 67;
            jackPool += toJackPool;
            amount -= toJackPool;
        }
        gamePool += amount;
    }

    // gameCount，比如 200注， totalWin，200注 的盈利总额，用 requestId 做关联
    // result ==> arrary[] => [(level1-13, count), (level1-13, count), (level1-13, count), (level1-13, count)....]
    event GameResult(uint indexed requestId, address player, uint256 gameCount, uint256 totalWin, bytes result);

    function settlement(uint256 random, address player, uint256 gameCount, uint256 requestId) external {
        UserAccount storage account = accounts[player];

        bytes memory result;
        uint256 totalWin;
        uint32[] memory winCount;
        uint256 gamePoolMinus;
        uint256 jackPoolMinus;

        (winCount, gamePoolMinus, jackPoolMinus) = ARITHMETIC.getResult(random, gameCount, gamePool, jackPool);

        gamePool -= gamePoolMinus;
        jackPool -= jackPoolMinus;

        totalWin = gamePoolMinus + jackPoolMinus;
        account.award += totalWin; // Cleared by withdraw
        account.accumulated += totalWin; // Not Cleared forever

        result = abi.encode(winCount, gamePoolMinus, jackPoolMinus);

        emit GameResult(requestId, player, gameCount, totalWin, result);
    }

    // TODO event
    function playerWithdraw() external {
        UserAccount storage account = accounts[msg.sender];
        require(account.award > 0, "Award is 0");
        FT.transfer(msg.sender, account.award);
        account.award = 0;
    }

}