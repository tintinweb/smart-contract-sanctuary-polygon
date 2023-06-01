// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Roulette is Ownable {
    IERC20 token;

    enum Color {
        BLACK,
        RED,
        GREEN
    }

    enum Zone {
        FIRST,
        SECOND,
        THIRD
    }

    enum SideBoard {
        LEFT,
        RIGHT
    }

    enum Parity {
        EVEN,
        ODD
    }

    uint public constant NUMBER_MULTIPLIER = 36;
    uint public constant SIDE_MULTIPLIER = 2;
    uint public constant ZONE_MULTIPLIER = 3;

    mapping(uint => Color) public colorNumber;

    event ResultGame(
        address player,
        uint winNumber,
        Color,
        Zone,
        SideBoard,
        Parity,
        uint totalReward
    );

    struct BetNumber {
        uint number;
        uint amount;
    }

    struct BetSide {
        SideBoard side;
        uint amount;
    }

    struct BetParity {
        Parity parity;
        uint amount;
    }

    struct BetZone {
        Zone zone;
        uint amount;
    }

    struct BetColor {
        Color color;
        uint amount;
    }

    constructor(
        address _tokenAddress,
        uint[] memory redNumber,
        uint[] memory blackNumber
    ) {
        token = IERC20(_tokenAddress);
        colorNumber[0] = Color.GREEN;
        for (uint i = 0; i < redNumber.length; i++) {
            colorNumber[redNumber[i]] = Color.RED;
        }
        for (uint i = 0; i < blackNumber.length; i++) {
            colorNumber[blackNumber[i]] = Color.BLACK;
        }
    }

    function placeBet(
        BetNumber[] memory _betNumber,
        BetSide memory _betSide,
        BetColor memory _betColor,
        BetZone memory _betZone,
        BetParity memory _betParity
    ) public {
        uint totalBetAmount = 0;
        uint totalReward = 0;
        uint userBalance = token.balanceOf(msg.sender);
        for (uint i = 0; i < _betNumber.length; i++) {
            require(
                0 <= _betNumber[i].number && _betNumber[i].number < 37,
                "Invalid bet number"
            );
            totalBetAmount += _betNumber[i].amount;
        }

        totalBetAmount += _betSide.amount;
        totalBetAmount += _betColor.amount;
        totalBetAmount += _betParity.amount;
        totalBetAmount += _betZone.amount;
        require(totalBetAmount > 0, "");
        require(totalBetAmount <= userBalance, "You don't have enought funds");
        require(
            token.transferFrom(msg.sender, address(this), totalBetAmount),
            "Transfer failed"
        );
        uint winNumber = spinWheel(totalBetAmount);

        Color winColor = getWinColor(winNumber);
        Zone winZone = getWinZone(winNumber);
        SideBoard winSide = getWinSide(winNumber);
        Parity winParity = getWinParity(winNumber);

        if (_betSide.amount > 0) {
            totalReward += getBetSideAmount(winNumber, _betSide);
        }
        if (_betColor.amount > 0) {
            totalReward += getBetColorAmount(winNumber, _betColor);
        }
        if (_betParity.amount > 0) {
            totalReward += getBetParityAmount(winNumber, _betParity);
        }
        if (_betZone.amount > 0) {
            totalReward += getBetZoneAmount(winNumber, _betZone);
        }
        totalReward += getBetNumberAmount(winNumber, _betNumber);

        if (totalReward > 0) {
            uint contractBalance = token.balanceOf(address(this));
            if (contractBalance > totalReward) {
                require(
                    token.transfer(msg.sender, totalReward),
                    "Failed payouts, please contact admin"
                );
            } else {
                revert(
                    "Balance of the contract is not enough, please contact admin"
                );
            }
        }
        emit ResultGame(
            msg.sender,
            winNumber,
            winColor,
            winZone,
            winSide,
            winParity,
            totalReward
        );
    }

    function withdraw() external onlyOwner {
        uint addrBalance = token.balanceOf(address(this));
        token.transfer(owner(), addrBalance);
    }

    function getBetNumberAmount(
        uint _winNumber,
        BetNumber[] memory _betNumber
    ) private pure returns (uint) {
        for (uint i = 0; i < _betNumber.length; i++) {
            BetNumber memory betNumber = _betNumber[i];
            if (betNumber.amount > 0 && betNumber.number == _winNumber) {
                return betNumber.amount * NUMBER_MULTIPLIER;
            }
        }
        return 0;
    }

    function getBetParityAmount(
        uint _winNumber,
        BetParity memory _betParity
    ) private pure returns (uint) {
        Parity winParity = getWinParity(_winNumber);
        if (_betParity.parity == winParity) {
            return _betParity.amount * SIDE_MULTIPLIER;
        }
        return 0;
    }

    function getBetSideAmount(
        uint _winNumber,
        BetSide memory _betSide
    ) private pure returns (uint) {
        SideBoard winSide = getWinSide(_winNumber);
        if (_betSide.side == winSide) {
            return _betSide.amount * SIDE_MULTIPLIER;
        }
        return 0;
    }

    function getBetZoneAmount(
        uint _winNumber,
        BetZone memory _betZone
    ) private pure returns (uint) {
        Zone winZone = getWinZone(_winNumber);
        if (_betZone.zone == winZone) {
            return _betZone.amount * ZONE_MULTIPLIER;
        }
        return 0;
    }

    function getBetColorAmount(
        uint _winNumber,
        BetColor memory _betColor
    ) private view returns (uint) {
        Color winColor = getWinColor(_winNumber);
        if (_betColor.color == winColor) {
            return _betColor.amount * SIDE_MULTIPLIER;
        }
        return 0;
    }

    function spinWheel(uint _amount) private view returns (uint) {
        uint randomNumber = uint(
            keccak256(abi.encode(block.timestamp, _amount, block.difficulty))
        ) % 37;
        return randomNumber;
    }

    function getWinZone(uint _winNumber) private pure returns (Zone) {
        if (1 <= _winNumber && _winNumber <= 12) {
            return Zone.FIRST;
        } else if (13 <= _winNumber && _winNumber <= 24) {
            return Zone.SECOND;
        } else {
            return Zone.THIRD;
        }
    }

    function getWinColor(uint _winNumber) private view returns (Color) {
        return colorNumber[_winNumber];
    }

    function getWinSide(uint _winNumber) private pure returns (SideBoard) {
        if (1 <= _winNumber && _winNumber <= 18) {
            return SideBoard.LEFT;
        } else {
            return SideBoard.RIGHT;
        }
    }

    function getWinParity(uint _winNumber) private pure returns (Parity) {
        uint remainder = _winNumber % 2;
        if (remainder > 0) {
            return Parity.ODD;
        } else {
            return Parity.EVEN;
        }
    }
}

// red [32,19,21,25,34,27,36,30,23,5,16,1,14,9,18,7,12,3]
// black [15,4,2,17,6,13,11,8,10,24,33,20,31,22,29,28,35,26]