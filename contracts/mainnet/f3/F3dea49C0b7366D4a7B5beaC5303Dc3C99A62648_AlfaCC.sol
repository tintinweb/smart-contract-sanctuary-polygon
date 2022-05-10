// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '../interfaces/IERC20.sol';
import '../libraries/SafeMath.sol';
import '../libraries/Ownable.sol';
import './Counters.sol';

contract AlfaCC is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    enum SalePhase {
        expert,
        tutor,
        preacher,
        builder
    }

    struct PhaseCap {
        uint256 expertCap;
        uint256 tutorCap;
        uint256 preacherCap;
        uint256 builderCap;
    }
    struct PhasePrice {
        uint256 expertPrice;
        uint256 tutorPrice;
        uint256 preacherPrice;
        uint256 builderPrice;
    }

    struct PhaseCount {
        Counters.Counter expertCount;
        Counters.Counter tutorCount;
        Counters.Counter preacherCount;
        Counters.Counter builderCount;
    }

    SalePhase public state = SalePhase.expert;
    PhasePrice public phasePrice;
    PhaseCap public phaseCap;
    PhaseCount public phaseCount;

    address public addrUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public addrUSDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private beneficiaryAddress = 0x6bC0024627D7f595A5BfBFf9Bc13FB91f950EbAa;

    event Payed(address user, address token, uint256 amount, uint256 timestamp);
    mapping(address => uint256) public ccPayed;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    constructor(
        address usdt,
        address usdc,
        address benefi
    ) {
        addrUSDT = usdt;
        addrUSDC = usdc;
        beneficiaryAddress = benefi;
        setPhaseCap(199, 1000, 2000000, MAX_UINT256);
        setPhasePrice(500000000, 200000000, 0, 0);
    }

    function setPhaseCap(
        uint256 expertCap,
        uint256 tutorCap,
        uint256 preacherCap,
        uint256 builderCap
    ) public onlyOwner {
        phaseCap.expertCap = expertCap;
        phaseCap.tutorCap = tutorCap;
        phaseCap.preacherCap = preacherCap;
        phaseCap.builderCap = builderCap;
    }

    function setPhasePrice(
        uint256 expertPrice,
        uint256 tutorPrice,
        uint256 preacherPrice,
        uint256 builderPrice
    ) public onlyOwner {
        phasePrice.expertPrice = expertPrice;
        phasePrice.tutorPrice = tutorPrice;
        phasePrice.preacherPrice = preacherPrice;
        phasePrice.builderPrice = builderPrice;
    }

    function setState(SalePhase phase) public onlyOwner {
        state = phase;
    }

    function getPrice() public view returns (uint256) {
        if (state == SalePhase.expert) return phasePrice.expertPrice;
        if (state == SalePhase.tutor) return phasePrice.tutorPrice;
        if (state == SalePhase.preacher) return phasePrice.preacherPrice;
        if (state == SalePhase.builder) return phasePrice.builderPrice;
        return 0;
    }

    function incrementPayCount() internal {
        if (state == SalePhase.expert) {
            phaseCount.expertCount.increment();
            if (phaseCount.expertCount.current() >= phaseCap.expertCap) {
                state = SalePhase.tutor;
            }
        } else if (state == SalePhase.tutor) {
            phaseCount.tutorCount.increment();
            if (phaseCount.tutorCount.current() >= phaseCap.tutorCap) {
                state = SalePhase.preacher;
            }
        } else if (state == SalePhase.preacher) {
            phaseCount.preacherCount.increment();
            if (phaseCount.preacherCount.current() >= phaseCap.preacherCap) {
                state = SalePhase.builder;
            }
        } else if (state == SalePhase.builder) {
            if (phaseCount.builderCount.current() < MAX_UINT256) {
                phaseCount.builderCount.increment();
            }
        }
    }

    function pay(string memory token) public {
        uint256 amount_payed = ccPayed[msg.sender];
        uint256 price = getPrice();
        // require(amount_payed < price, 'has payed');
        require(price > 0, 'price is 0');
        require(beneficiaryAddress != address(0), 'beneficiaryAddress error');
        address feeToken = addrUSDC;
        bool checkResult = compareStr(token, 'USDT');
        if (checkResult) {
            feeToken = addrUSDT;
        }
        IERC20(feeToken).transferFrom(msg.sender, beneficiaryAddress, price);
        ccPayed[msg.sender] = price + amount_payed;
        incrementPayCount();
        emit Payed(msg.sender, feeToken, price, block.timestamp);
    }

    function setFeeToken(address usdt, address usdc) external onlyOwner {
        addrUSDT = usdt;
        addrUSDC = usdc;
    }

    function setBeneficiary(address addr) external onlyOwner {
        beneficiaryAddress = addr;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Balance should be more then zero');
        payable(beneficiaryAddress).transfer(balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawToken(address token) public onlyOwner {
        uint256 value = getTokenBalance(token);
        IERC20(token).transfer(msg.sender, value);
    }

    function toWei(uint256 amount, uint8 _decimals) public pure returns (uint256) {
        return amount * (uint256(10)**_decimals);
    }

    function compareStr(string memory _str1, string memory _str2) internal pure returns (bool) {
        if (bytes(_str1).length == bytes(_str2).length) {
            if (keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import './Context.sol';

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, 'Counter: decrement overflow');
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter, uint256 index) internal {
        counter._value = index;
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