// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Swap.sol";
import "./SwapNative.sol";
import "./helpers/Withdraw.sol";

contract TokenitySwap is  SwapNative, Swap, Withdraw  {
    constructor() {}

    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./security/ReEntrancyGuard.sol";
import "./security/Chainalysis.sol";

import "./helpers/Oracle.sol";
import "./helpers/TransferHistory.sol";

import "./factory/FactorySwap.sol";

contract Swap is
    ReEntrancyGuard,
    Chainalysis,
    FactorySwap,
    Oracle,
    TransferHistory
{
    // @dev SafeMath library
    using SafeMath for uint256;

    // Event that log buy operation
    event BuyTokens(
        address buyer,
        uint256 amountSenderTokenA,
        uint256 amountSenderTokenB,
        uint256 indexed _pairId
    );

    event SellToken(
        address seller,
        uint256 amountSenderTokenA,
        uint256 amountSenderTokenB,
        uint256 indexed _pairId
    );

    constructor() {}

    // @dev BUY
    //  Token A => Token Enviado
    //  Token B => Token que va a recibir el sender
    function BuyTokensFor(uint256 _pairId, uint256 _amountTokens)
        external
        noReentrant
        returns (bool)
    {
        // @dev is To Sanctioned
        bool isToSanctioned = Sanctions(_msgSender());
        require(
            !isToSanctioned,
            "BuyTokensFor: Transfer to sanctioned address"
        );

        require(
            _amountTokens > 0,
            "BuyTokensFor: Specify an amount of token greater than zero"
        );

        // @dev get the pair
        Pair storage pair = _PairstoSwap[_pairId];

        require(pair.active, "BuyTokensFor: Pair is not active");

        // @dev  Check that the user's token balance is enough to do the swap
        require(
            IERC20(pair.tokenA).balanceOf(_msgSender()) >= _amountTokens,
            "BuyTokensFor: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute the swap
        require(
            IERC20(pair.tokenA).allowance(_msgSender(), address(this)) >=
                _amountTokens,
            "BuyTokensFor: You don't have enough tokens to buy"
        );

        // @dev Transfer token to the sender  =>  sc
        require(
            IERC20(pair.tokenA).transferFrom(
                _msgSender(),
                address(this),
                _amountTokens
            ),
            "BuyTokensFor: Failed to transfer tokens from user to vendor"
        );

        // @dev calculate the amount of  fee services
        uint256 _amountfeeSwap = 0;
        if (pair.fee > 0) {
            _amountfeeSwap = calculateFee(_amountTokens, pair.fee);
            require(
                IERC20(pair.tokenA).transfer(vaultAddress, _amountfeeSwap),
                "BuyTokensFor: Failed to transfer token to Swap"
            );
        }

        uint256 tokenAmountToBuy = 0;
        uint256 amountTokenBuy = 0;

        // @dev  is oracle active
        if (pair.activeOracle) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(
                pair.addressOracle,
                pair.addressDecimalOracle
            );

            // @dev tranformar el token enviado a 18 decimales
            uint256 amountTo18 = transformAmountTo18Decimal(
                _amountTokens.sub(_amountfeeSwap),
                pair.decimalTokenA
            );

            // @dev calculate the amount of token to buy
            uint256 valueInUsd = amountTo18.mul(latestPrice);

            // @dev amount of token to buy
            amountTokenBuy = valueInUsd.div(pair.price);
        } else {
            // @dev calculate the amount of tokens to buy
            tokenAmountToBuy = (_amountTokens.sub(_amountfeeSwap)).mul(
                pair.amountForTokens
            );

            // transformar resultado a las decimales del tokenB
            // Se toma la decimal del TokenA ya que debemos llevar el resulto a 18
            // porque todos los calulos del arriba se hacen el base a las decimales del token enviado.
            // por ejemplo:
            // envio un token de 8 dicimales todos los calculos se haran el base de 8. pero se tiene que llevar
            // a 18 partiendo de la primera que siempre se vendera un solo TOKEN principal por ejemplo
            // envio usdt -> token1
            // envio usdc -> token1
            // envio matic -> token1
            amountTokenBuy = transformAmountTo18Decimal(
                tokenAmountToBuy,
                pair.decimalTokenA
            );
        }

        require(limitBuy(amountTokenBuy), "BuyTokensFor: Limit buy");

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        require(
            IERC20(pair.tokenB).balanceOf(address(this)) >= amountTokenBuy,
            "BuyTokensFor: Vendor contract has not enough tokens in its balance"
        );

        require(
            IERC20(pair.tokenB).transfer(_msgSender(), amountTokenBuy),
            "BuyTokensFor: Failed to transfer token to user"
        );

        emit BuyTokens(_msgSender(), _amountTokens, amountTokenBuy, _pairId);

        return true;
    }

    // @dev SELL
    // @dev Token B =>  TOKEN ENVIADO -> TOKENA
    // @dev Token A =>  TOKEN QUE  VOY A REVIBIR
    function SellTokensFor(uint256 _pairId, uint256 _amountTokens)
        external
        noReentrant
        returns (uint256 tokenAmount)
    {
        // // @dev is To Sanctioned
        bool isToSanctioned = Sanctions(_msgSender());
        require(
            !isToSanctioned,
            "BuyTokensFor: Transfer to sanctioned address"
        );

        require(
            _amountTokens > 0,
            "SellTokensFor: Specify an amount of token greater than zero"
        );

        // @dev get the pair
        Pair storage pair = _PairstoSwap[_pairId];

        require(pair.active, "SellTokensFor: Pair is not active");

        // Check that the user's token balance is enough to do the swap
        require(
            IERC20(pair.tokenB).balanceOf(_msgSender()) >= _amountTokens,
            "SellTokensFor: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute the swap
        require(
            IERC20(pair.tokenB).allowance(_msgSender(), address(this)) >=
                _amountTokens,
            "SellTokensFor: You don't have enough tokens to sell"
        );

        // Transfer token to the sender -> sc
        require(
            IERC20(pair.tokenB).transferFrom(
                _msgSender(),
                address(this),
                _amountTokens
            ),
            "SellTokensFor: Failed to transfer tokens from user to vendor"
        );

        // @dev calculate the amount of  fee services
        uint256 _amountfeeSwap = 0;
        if (pair.fee > 0) {
            _amountfeeSwap = calculateFee(_amountTokens, pair.fee);
            require(
                IERC20(pair.tokenB).transfer(vaultAddress, _amountfeeSwap),
                "SellTokensFor: Failed to transfer token to Swap"
            );
        }

        uint256 tokenAmountToSell = 0;

        // @dev  is oracle active
        if (pair.activeOracle) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(
                pair.addressOracle,
                pair.addressDecimalOracle
            );

            uint256 tokenAmountTo18Decimals = transformAmountTo18Decimal(
                _amountTokens.sub(_amountfeeSwap),
                pair.decimalTokenB
            );

            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = (tokenAmountTo18Decimals.div(latestPrice)).mul(
                pair.price
            );
        } else {
            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = _amountTokens.sub(_amountfeeSwap).div(
                pair.amountForTokens
            );
        }

        // @dev transformar resultado a las decimales del tokenA
        // todos los culculos de arriba son hechos en 18 decimales entonces se
        // tiene que llevar ese resultado a la decimal de token que el sc va a enviasr al sender
        // ejemplo:
        // envio tokenA -> usdt
        // envio tokenA -> usdc
        // envio tokenA -> matic
        uint256 _tokenAmountToSell = transformAmountToTokenDecimal(
            tokenAmountToSell,
            pair.decimalTokenA
        );

        require(limitSell(_tokenAmountToSell), "SellTokensFor: Limit buy");

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        require(
            IERC20(pair.tokenA).balanceOf(address(this)) >= _tokenAmountToSell,
            "SellTokensFor: Vendor contract has not enough tokens in its balance"
        );

        require(
            IERC20(pair.tokenA).transfer(_msgSender(), _tokenAmountToSell),
            "SellTokensFor: Failed to transfer token to user"
        );

        emit BuyTokens(
            _msgSender(),
            _amountTokens,
            _tokenAmountToSell,
            _pairId
        );

        return tokenAmountToSell;
    }

    // @dev transforma los montos a 18 decimales
    function transformAmountTo18Decimal(uint256 _amount, uint256 _decimal)
        internal
        pure
        returns (uint256)
    {
        if (_decimal == 18) {
            return _amount;
        } else if (_decimal == 8) {
            return _amount.mul(10**10);
        } else if (_decimal == 6) {
            return _amount.mul(10**12);
        } else if (_decimal == 3) {
            return _amount.mul(10**15);
        }

        return 0;
    }

    // @dev tranformas las decimales del token
    function transformAmountToTokenDecimal(uint256 _amount, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        if (decimal == 18) {
            return _amount;
        } else if (decimal == 8) {
            return _amount.div(10**10);
        } else if (decimal == 6) {
            return _amount.div(10**12);
        } else if (decimal == 3) {
            return _amount.div(10**15);
        }

        return 0;
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOf(IERC20 _token, address _address)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(_address);
    }

    // @dev fee calculation for token
    function calculateFee(uint256 amount, uint256 _fee)
        internal
        pure
        returns (uint256 fee)
    {
        return (amount.mul(_fee)).div(10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./security/ReEntrancyGuard.sol";
import "./helpers/Oracle.sol";
import "./helpers/TransferHistory.sol";
import "./security/Chainalysis.sol";
import "./factory/FactorySwap.sol";

contract SwapNative is
    ReEntrancyGuard,
    Ownable,
    Chainalysis,
    Oracle,
    TransferHistory
{
    // @dev SafeMath library
    using SafeMath for uint256;

    // Event that log buy operation
    event BuyTokensMATIC(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensbyMATIC(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    uint256 fee = 100; // fee 1%
    bool oracleActive = false;
    address oracleAddress = address(0);
    uint256 amountToken = 0;
    uint256 priceToken = 0;
    address tokenitytoken = address(0);

    constructor() {}

    // @dev  Allow users to buy tokens for MATIC by TOKENITY
    function buyToken()
        external
        payable
        noReentrant
        returns (uint256 tokenAmount)
    {
        // @dev is To Sanctioned
        bool isToSanctioned = Sanctions(_msgSender());
        require(
            !isToSanctioned,
            "BuyTokensFor: Transfer to sanctioned address"
        );

        require(msg.value > 0, "BuyToken: Send MATIC to buy some tokens");

        // @dev send fee Tokenity
        uint256 _amountfee = 0;
        if (fee > 0) {
            _amountfee = calculateFeeNative(msg.value);
            require(
                payable(vaultAddress).send(_amountfee),
                "BuyToken: Failed to transfer token to fee contract Owner"
            );
        }

        // @dev amount of tokens to buy
        uint256 _amountOfTokens = msg.value.sub(_amountfee);
        uint256 tokenAmountToBuy = 0;

        if (oracleActive) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(oracleAddress, 10);

            // @dev calculate the amount of token to buy
            uint256 valueInUsd = _amountOfTokens.mul(latestPrice);

            // @dev amount of token to buy
            tokenAmountToBuy = valueInUsd.div(priceToken);
        } else {
            tokenAmountToBuy = _amountOfTokens.mul(amountToken);
        }

        // @dev  limit the amount of tokens to buy
        require(limitBuy(tokenAmountToBuy), "BuyTokensFor: Limit buy");

        // @dev check if the Vendor Contract has enough amount of tokens for the transaction
        require(
            IERC20(tokenitytoken).balanceOf(address(this)) >= tokenAmountToBuy,
            "BuyToken: Vendor contract has not enough tokens in its balance"
        );

        // @dev Transfer token to the msg.sender
        require(
            IERC20(tokenitytoken).transfer(_msgSender(), tokenAmountToBuy),
            "BuyToken: Failed to transfer token to user"
        );

        // @dev emit the event
        emit BuyTokensMATIC(_msgSender(), msg.value, tokenAmountToBuy);

        return tokenAmountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by MATIC
    function sellTokens(uint256 _amountTokens)
        external
        noReentrant
        returns (uint256 tokenAmount)
    {
        // @dev is To Sanctioned
        bool isToSanctioned = Sanctions(_msgSender());
        require(
            !isToSanctioned,
            "BuyTokensFor: Transfer to sanctioned address"
        );

        // @dev Check that the requested amount of tokens to sell is more than 0
        require(
            _amountTokens > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        require(
            IERC20(tokenitytoken).balanceOf(_msgSender()) >= _amountTokens,
            "SellTokens: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev allowonce to execute the swap
        require(
            IERC20(tokenitytoken).allowance(_msgSender(), address(this)) >=
                _amountTokens,
            "SellTokens: You don't have enough tokens to sell"
        );

        // Transfer token to the sender -> sc
        require(
            IERC20(tokenitytoken).transferFrom(
                _msgSender(),
                address(this),
                _amountTokens
            ),
            "SellTokens: Failed to transfer tokens from user to vendor"
        );

        // @dev send fee dly
        uint256 _amountfee = 0;
        if (fee > 0) {
            _amountfee = calculateFeeNative(_amountTokens);
            require(
                payable(vaultAddress).send(_amountfee),
                "SellTokens: Failed to transfer token to fee contract Owner"
            );
        }

        // @dev  token available to send to user
        uint256 tokenSendSub = _amountTokens.sub(_amountfee);
        uint256 tokenAmountToSell = 0;

        if (oracleActive) {
            // @dev get the price
            uint256 latestPrice = getLatestPrice(oracleAddress, 10);

            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = (tokenSendSub.div(latestPrice)).mul(priceToken);
        } else {
            // @dev calculate the amount of tokens to buy
            tokenAmountToSell = tokenSendSub.div(amountToken);
        }

        // @dev limit sell
        require(limitSell(tokenAmountToSell), "SellTokens: limitSell");

        // @dev Check that the Vendor's balance is enough to do the swap
        require(
            address(this).balance >= tokenAmountToSell,
            "SellTokens Vendor has not enough funds to accept the sell request"
        );

        // @dev  we send matic to the sender
        (bool success, ) = _msgSender().call{value: tokenAmountToSell}("");
        require(success, "SellTokens: receiver rejected MATIC transfer");

        return tokenAmountToSell;
    }

    // @dev fee calculation for token
    function calculateFeeNative(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return (_amount.mul(fee)).div(10000);
    }

    // @dev fee calculation for token
    function setNewFee(uint256 _newFee) external returns (bool) {
        fee = _newFee;
        return true;
    }

    // @dev Active Oracle
    function setActiveOracle(bool _active) external returns (bool) {
        oracleActive = _active;
        return true;
    }

    // @dev Address Oracle
    function setAddressOracle(address _address) external returns (bool) {
        oracleAddress = _address;
        return true;
    }

    // @dev Amount Token
    function setAmountToken(uint256 _amountToken) external returns (bool) {
        amountToken = _amountToken;
        return true;
    }

    // @dev Price Token
    function setPriceToken(uint256 _priceToken) external returns (bool) {
        priceToken = _priceToken;
        return true;
    }

    // @dev Price Token
    function setTokenityToken(address _token) external returns (bool) {
        tokenitytoken = _token;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Withdraw is Context, Ownable {
    // event
    event WithdrawEvent(
        address indexed token,
        address indexed owner,
        uint256 amount
    );

    constructor() {}

    // @dev Withdrawal $MATIC ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawMaticOwner(uint256 amount) external payable onlyOwner {
        require(
            payable(address(_msgSender())).send(amount),
            "Failed to transfer token to fee contract"
        );

        emit WithdrawEvent(address(0), _msgSender(), amount);
    }

    // @dev Withdrawal TOKEN $USDT, $USDC, $DLY, $WETH, $WBTC  ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawTokenOnwer(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            IERC20(_token).transfer(_msgSender(), _amount),
            "Failed to transfer token to Onwer"
        );

        emit WithdrawEvent(_token, _msgSender(), _amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

// Chainalysis oracle for sanctions screening
// The Chainalysis oracle is a smart contract that validates if a cryptocurrency wallet
// address has been included in a sanctions designation.
// The smart contract is maintained by Chainalysis on a variety of popular blockchains and
// will be regularly updated to reflect the latest sanctions designations listed on economic/trade
// embargo lists from organizations including the US, EU, or UN. The smart contract is available
// for anyone to use and does not require a customer relationship with Chainalysis.
// Doc: https://go.chainalysis.com/chainalysis-oracle-docs.html

contract Chainalysis is Ownable {
    address public SANCTIONS_CONTRACT =
        0x0000000000000000000000000000000000000000;

    bool public stateSanctions = false;

    // @dev Returns the latest price
    function Sanctions(address _address) public view returns (bool) {
        if (stateSanctions) {
            require(
                _address != address(0),
                "SanctionsListContract: address must be the same as the contract address"
            );

            SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
            bool isToSanctioned = sanctionsList.isSanctioned(_address);

            return isToSanctioned;
        }

        return false;
    }

    // @dev Address Oracle
    function setAddressSanctions(address _address)
        external
        onlyOwner
        returns (bool)
    {
        SANCTIONS_CONTRACT = _address;
        return true;
    }

    // @dev set State Sanctions
    function setStateSanctions(bool _state) external onlyOwner returns (bool) {
        stateSanctions = _state;
        return true;
    }
}

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Oracle {
    // @dev Returns the latest price
    function getLatestPrice(address _oracle, uint256 _decimal)
        public
        view
        returns (uint256)
    {
        require(
            _oracle != address(0),
            "Oracle address must be the same as the contract address"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**_decimal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TransferHistory is Context, Ownable {
    // @dev Event
    event SaleLimitChange(uint256 oldSaleLimit, uint256 newSaleLimit);
    event BuyLimitChange(uint256 oldBuyLimit, uint256 newBuyLimit);
    event ChangeVaultAddress(address oldAddress, address newAddress);

    // @dev struct for sale limit
    struct SoldOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev
    uint256 public daySellLimit = 100 ether;
    mapping(address => SoldOnDay) public salesInADay;

    // @dev
    uint256 public dayBuyLimit = 100 ether;
    mapping(address => BuyOnDay) public buyInADay;

    // @dev
    address public vaultAddress = address(0);

    constructor() {
        // @dev set the vault address
        vaultAddress = _msgSender();
    }

    // @dev  Throws if you exceed the Sell limit
    function limitSell(uint256 sellAmount) internal returns (bool) {
        SoldOnDay storage soldOnDay = salesInADay[_msgSender()];
        if (block.timestamp >= soldOnDay.startOfDay + 1 days) {
            soldOnDay.amount = sellAmount;
            soldOnDay.startOfDay = block.timestamp;
        } else {
            soldOnDay.amount += sellAmount;
        }

        if (soldOnDay.amount <= daySellLimit) {
            return true;
        } else {
            return false;
        }
    }

    // @dev struct for buy limit
    struct BuyOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev  Throws if you exceed the Buy limit
    function limitBuy(uint256 buyAmount) internal returns (bool) {
        BuyOnDay storage buyOnDay = buyInADay[_msgSender()];

        if (block.timestamp >= buyOnDay.startOfDay + 1 days) {
            buyOnDay.amount = buyAmount;
            buyOnDay.startOfDay = block.timestamp;
        } else {
            buyOnDay.amount += buyAmount;
        }

        if (buyOnDay.amount <= dayBuyLimit) {
            return true;
        } else {
            return false;
        }
    }

    // @dev changes to the token sale limit
    function setSellLimit(uint256 newLimit) external onlyOwner returns (bool) {
        uint256 oldLimit = daySellLimit;
        daySellLimit = newLimit;

        emit SaleLimitChange(oldLimit, daySellLimit);
        return true;
    }

    // @dev Token purchase limit changes
    function setBuyLimit(uint256 newLimit) external onlyOwner returns (bool) {
        uint256 oldLimit = dayBuyLimit;
        dayBuyLimit = newLimit;

        emit BuyLimitChange(oldLimit, dayBuyLimit);
        return true;
    }

    // @dev Token purchase limit changes
    function setVaultAddress(address _address)
        external
        onlyOwner
        returns (bool)
    {
        address oldAddress = vaultAddress;
        vaultAddress = _address;

        emit ChangeVaultAddress(oldAddress, vaultAddress);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FactorySwap is Ownable {
    // @dev Event that log buy operation
    event EventPair(address tokenA, address tokenB);

    // @dev struct
    struct Pair {
        uint256 price; // precio en dolares
        address tokenA;
        uint256 decimalTokenA;
        address tokenB;
        uint256 decimalTokenB;
        uint256 amountForTokens;
        uint256 fee;
        bool activeOracle;
        address addressOracle;
        uint256 addressDecimalOracle;
        bool active;
    }

    // @dev mapping
    mapping(uint256 => Pair) _PairstoSwap;
    uint256 public pairCount;

    constructor() {
        pairCount = 0;
    }

    // @dev create a new pair
    function registerPair(
        uint256 _price,
        address _tokenA, // token que envia
        uint8 _decimalTokenA, // decimales del token
        address _tokenB, // token que recibe
        uint8 _decimalTokenB, // decimales del token
        uint256 _amountForTokens, // monto de token que se envian por ether cuando el oracle esta apagado
        uint256 _fee, // en que se cobra por transacion de este par
        bool _activeOracle, // activa o desactive el oracle
        address _addressOracle, // direccion de oraculo
        uint8 _addressDecimalOracle, //  los 0 que se le van a agregar al oraculo para elevarlo a la 18
        // por ejemplo: si el en 6 decimales este valor debe ser de 12 para elevarlo 18.
        bool _active // activa o descactiva el par
    ) external onlyOwner returns (bool) {
        require(
            _tokenA != _tokenB,
            "MindFactory: Token A and Token B cannot be the same"
        );

        // @dev  save the pair
        _PairstoSwap[pairCount] = Pair(
            _price, // type 1
            _tokenA, // type 2
            _decimalTokenA, // type 3
            _tokenB, // type 4
            _decimalTokenB, // type 5
            _amountForTokens, // type 6
            _fee, // type 7
            _activeOracle, // type 8
            _addressOracle, // type 9
            _addressDecimalOracle, // type 10
            _active // type 11
        );

        // @dev count the number of pairs
        pairCount++;

        // @dev Event that log buy operation
        emit EventPair(_tokenA, _tokenB);

        return true;
    }

    // @dev we return all pair registered
    function pairList() external view returns (Pair[] memory) {
        unchecked {
            Pair[] memory p = new Pair[](pairCount);
            for (uint256 i = 0; i < pairCount; i++) {
                Pair storage s = _PairstoSwap[i];
                p[i] = s;
            }
            return p;
        }
    }

    // @dev enabled oracle
    function pairChange(
        uint8 _type,
        uint8 _decimal,
        uint256 _id,
        bool _bool,
        address _address,
        uint256 _value
    ) public onlyOwner returns (bool success) {
        if (_type == 1) {
            _PairstoSwap[_id].price = _value;
        } else if (_type == 2) {
            _PairstoSwap[_id].tokenA = _address;
        } else if (_type == 3) {
            _PairstoSwap[_id].decimalTokenA = _decimal;
        } else if (_type == 4) {
            _PairstoSwap[_id].tokenB = _address;
        } else if (_type == 5) {
            _PairstoSwap[_id].decimalTokenB = _decimal;
        } else if (_type == 6) {
            _PairstoSwap[_id].amountForTokens = _value;
        } else if (_type == 7) {
            _PairstoSwap[_id].fee = _value;
        } else if (_type == 8) {
            _PairstoSwap[_id].activeOracle = _bool;
        } else if (_type == 9) {
            _PairstoSwap[_id].addressOracle = _address;
        } else if (_type == 10) {
            _PairstoSwap[_id].addressDecimalOracle = _decimal;
        } else if (_type == 11) {
            _PairstoSwap[_id].active = _bool;
        }

        return true;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}