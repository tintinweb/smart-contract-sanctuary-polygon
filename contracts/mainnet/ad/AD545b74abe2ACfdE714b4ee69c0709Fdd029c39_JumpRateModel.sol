/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-28
*/

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    // 加法运算
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    // 减法
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    // 减法
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev 返回两个无符号整数的乘积，在溢出时恢复。
     *
     * 与 Solidity 的 `*` 运算符相对应。
     *
     * Requirements:
     * - 乘法不能溢出。
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        // SafeMath：乘法溢出
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    // 除法
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    // 除法
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * 默认情况下，所有者帐户将是部署合约的帐户。 这可以稍后通过 {transferOwnership} 更改。
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    // 所有者
    address private _owner;
    // 所有权转让
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev 返回当前所有者的地址。
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev 如果由所有者以外的任何帐户调用，则抛出。
     */
    modifier onlyOwner() {
        // 可拥有：调用者不是所有者
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev 离开没有所有者的合同。 将无法再调用 `onlyOwner` 函数。 只能由当前所有者调用。
     *
     * NOTE: 放弃所有权将使合同没有所有者，从而删除任何仅对所有者可用的功能。
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev 将合同的所有权转移到新帐户（`newOwner`）
     * 只能由当前所有者调用。
     */
    // 所有权转让
    function transferOwnership(address newOwner) public virtual onlyOwner {
        // 可拥有：新所有者是零地址
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // 所有权转让
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/InterestRateModel.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
  * @title wepiggy's IInterestRateModel Interface
  * @author wepiggy
  */
interface IInterestRateModel {
    /**
      * @notice 计算每个区块的当前借入利率
      * @param cash 市场拥有的现金总量
      * @param borrows 市场有未偿还的借款总额
      * @param reserves 市场拥有的储备总量
      * @return 每个区块的借用率（百分比形式，按 1e18 缩放）
      */
    // 获取借款利率
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice 计算每个区块的当前存款利率
      * @param cash 市场拥有的现金总量
      * @param borrows 市场有未偿还的借款总额
      * @param reserves 市场拥有的储备总量
      * @param reserveFactorMantissa 市场当前的储备因子
      * @return 每个区块的存款利率（百分比，按 1e18 缩放）
      */
    // 获取存款利率
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/BaseJumpRateModelV2.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
  * @title Compound 的 JumpRateModel Contract V2 的逻辑。
  * @notice 版本 2 通过启用可更新参数修改了版本 1。
  */
contract BaseJumpRateModel is IInterestRateModel, OwnableUpgradeSafe {
    using SafeMath for uint;
    // 新利息参数
    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);

    /**
     * @notice 利率模型假设的每年区块的近似数量(blocksPerYear 每年块数)
     */
    // 每年块数
    uint public constant blocksPerYear = 10512000;

    /**
     * @notice 给出利率斜率的利用率乘数
     */
    // 每块乘数
    uint public multiplierPerBlock;

    /**
     * @notice 基准年利率，即利用率为 0 时的 y 轴截距
     */
    uint public baseRatePerBlock;

    /**
     * @notice 达到指定利用率点后的 multiplierPerBlock
     */
    uint public jumpMultiplierPerBlock;

    /**
     * @notice 应用跳跃乘数的利用点
     */
    // 曲折（图形转折点）拐点值
    uint public kink;

    /**
     * @notice 更新利率模型的参数（只能由所有者调用，即 Timelock）
     * @param baseRatePerYear 基本年利率 近似目标基础 APR，作为尾数（按 1e18 缩放）
     * @param multiplierPerYear 每年乘数 利率 wrt 利用率的增长率（按 1e18 缩放）
     * @param jumpMultiplierPerYear 每年跳跃乘数 达到指定利用率点后的 multiplierPerBlock(每块乘数)
     * @param kink_ 应用跳跃乘数的利用点
     */
    // 更新跳跃率模型
    function updateJumpRateModel(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_) external {
        updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
    }

    /**
     * @notice 计算市场利用率：`借入/（现金+借入-准备金）`
     * @param cash 市场上的现金数量
     * @param borrows 市场借贷量
     * @param reserves 市场储备量（目前未使用）
     * @return 利用率为 [0, 1e18] 之间的尾数
     */
    // 利用率
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        // 无借款时利用率为0
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
     * @notice 计算每个区块的当前借入利率，以及市场预期的错误代码
     * @param cash 现金 市场上的现金数量
     * @param borrows 借贷 市场上借贷的金额
     * @param reserves 储备 市场上的储备量
     * @return 每个区块的借用利率百分比作为尾数（按 1e18 缩放）
     */
    function getBorrowRateInternal(uint cash, uint borrows, uint reserves) internal view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);

        if (util <= kink) {
            return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } else {
            uint normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
            uint excessUtil = util.sub(kink);
            return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
        }
    }

    /**
     * @notice 计算每个区块的当前借入利率
     * @param cash 市场上的现金数量
     * @param borrows 市场借贷量
     * @param reserves 市场储备量
     * @return 每个区块的借用利率百分比作为尾数（按 1e18 缩放）
     */
    // 获取借款利率
    function getBorrowRate(uint cash, uint borrows, uint reserves) external virtual override view returns (uint) {
        return getBorrowRateInternal(cash, borrows, reserves);
    }


    function getSupplyRateInternal(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) internal view returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactorMantissa);
        uint borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
    /**
     * @notice 计算每个区块的当前供应率
     * @param cash 市场上的现金数量
     * @param borrows 市场借贷量
     * @param reserves 市场储备量
     * @param reserveFactorMantissa 当前市场储备因子
     * @return 每个区块的供应率百分比作为尾数（按 1e18 缩放）
     */
    // 获取供应率(存款利率)
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external virtual override view returns (uint) {
        return getSupplyRateInternal(cash, borrows, reserves, reserveFactorMantissa);
    }

    /**
     * @notice 更新利率模型参数的内部函数
     * @param baseRatePerYear 近似目标基础 APR，作为尾数（按 1e18 缩放）
     * @param multiplierPerYear 利率 wrt 利用率的增长率（按 1e18 缩放）
     * @param jumpMultiplierPerYear 达到指定利用率点后的 multiplierPerBlock
     * @param kink_ The 应用跳跃乘数的利用点
     */
    // 基本年利率,区块斜率,拐点后斜率,拐点
    function updateJumpRateModelInternal(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_) internal onlyOwner {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = (multiplierPerYear.mul(1e18)).div(blocksPerYear.mul(kink_));
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
        kink = kink_;
        // 每块基准年利率,区块斜率,拐点后的斜updateJumpRateModelInternal率,拐点值
        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }
}

/**
  * @title Compound's JumpRateModel Contract V2 for V2 cTokens
  * @author Arr00
  * @notice 仅支持 V2 cTokens
  */
// 跳跃率模型 V2 cToken 的合约 V2
contract JumpRateModel is BaseJumpRateModel {
    // 基本年利率,每年乘数,每年跳跃乘数,
    function initialize(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_) public initializer {
        super.__Ownable_init();
        super.updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
    }
}