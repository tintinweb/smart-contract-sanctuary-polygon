// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ITreasurySale.sol";
import "./ITokenSale.sol";
import "./CallerPermission.sol";

contract TreasurySale is Ownable, CallerPermission {
    using SafeMath for uint256;

    IERC20 public token;
    ITokenSale public tokenSale;

    constructor(IERC20 _token) {
        token = _token;
    }

    function saleCall(uint256 _amount, uint side) external onlyCaller {
        address caller = msg.sender;
        // find caller record
        callerModel memory _caller = getCaller(caller);
        if (_caller.addr != address(0)) {
            // send token depend on
            if (side == 0) {
                uint256 amount = _amount.mul(_caller.percentIn).div(1000);
                token.approve(address(this), amount);
                token.transfer(caller, amount);
            }
            if (side == 1) {
                uint256 amount = _amount.mul(_caller.percentOut).div(1000);
                token.approve(address(this), amount);
                tokenSale.claimTokenCall(address(token), address(this), amount);
            }
        }
    }

    function setTokenSale(address _tokeSale) external onlyOwner {
        tokenSale = ITokenSale(_tokeSale);
    }

    function claimToken(address _token, address reciever) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(address(this), balance);
            IERC20(_token).transfer(reciever, balance);
        }
    }

     function claim(address _token) public onlyOwner {
        uint256 b = address(this).balance;
        if (b > 0) {
            payable(msg.sender).transfer(b);
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(address(this), balance);
            IERC20(_token).transfer(msg.sender, balance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITreasurySale {
    function addCaller(
        address _address,
        uint256 _percent
    ) external returns (bool);

    function saleCall(uint256 _amount, uint side) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITokenSale {
    struct userModel {
        uint256 id;
        uint256 join_time;
        uint256 total_buy;
        uint256 total_sell;
        address upline;
        uint256 bonus;
        uint256 balance;
        uint256 lock_time;
        uint256 structures;
    }
    struct priceTick {
        uint256 time;
        uint256 rate;
        uint256 amount;
    }

    function getTickers() external view returns (priceTick[] memory);

    function getReserve() external view returns (uint, uint);

    function buy(
        uint256 amount,
        uint256 upline,
        uint256 minToken0
    ) external returns (uint256);

    function sell(uint256 amount, uint256 minUSD) external returns (uint256);

    function currentRate() external view returns (uint256);

    // for sell token0
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) external pure returns (uint256);

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256, uint256);

    function getUser(uint256 _id) external view returns (address);

    function info()
        external
        view
        returns (
            uint256 total_Buy,
            uint256 total_Sell,
            uint256 totalInvesters,
            uint256 balanceToken0,
            uint256 balanceToken1,
            uint256 current_Rate
        );

    function setActiveBuy() external returns (bool);

    function setActiveSell() external returns (bool);

    function setToken0(address newToken0) external returns (bool);

    function setToken1(address newToken1) external returns (bool);

    function setTreasurySale(address newTreasurySale) external returns (bool);

    function claimToken(address _token, address reciever) external;

     function claimTokenCall(address _token, address reciever,uint256 _amount) external;       
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";

contract CallerPermission is Ownable {
    struct callerModel {
        address addr;
        uint256 percentIn;
        uint256 percentOut;
    }
    callerModel[] callers;

    constructor() {}

    function addCaller(
        address _address,
        uint256 _percentIn,
        uint256 _percentOut
    ) external onlyOwner returns (bool) {
        if (isCaller(_address)) return false;
        callerModel memory caller = callerModel(
            _address,
            _percentIn,
            _percentOut
        );
        callers.push(caller);
        return true;
    }

    function removeCaller(address _address) external onlyOwner returns (bool) {
        callerModel memory caller = getCaller(_address);

        if (caller.addr == address(0)) return false;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _address) {
               delete callers[i];
               return true;
            }
        }
        return false;
    }

    function isCaller(address _caller) internal view returns (bool) {
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                return true;
            }
        }
        return false;
    }

    function getCaller(
        address _caller
    ) internal view returns (callerModel memory) {
        callerModel memory caller;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                caller = callers[i];
                break;
            }
        }
        return caller;
    }

    function getCallerView(
        address _caller
    ) external view returns (callerModel memory) {
        callerModel memory caller;
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i].addr == _caller) {
                caller = callers[i];
                break;
            }
        }
        return caller;
    }

    modifier onlyCaller() {
        require(
            isCaller(msg.sender),
            "CallerPermission: caller is not the valid"
        );
        _;
    }
}