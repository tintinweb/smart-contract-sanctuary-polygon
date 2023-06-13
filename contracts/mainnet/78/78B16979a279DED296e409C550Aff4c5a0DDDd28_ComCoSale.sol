//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IComCo {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IUSDT {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);
}

contract ComCoSale is Ownable {
    address public comco;
    address public usdt;

    uint public fee = 572;
    uint public feeMatic = 0.000052 ether;
    uint public feeConstant = 10000000;
    uint public feeDecimal = 100;
    uint public minLimit = 0;
    uint public maxLimit = 174800000 * 1e8;
    uint public totalSale = 0;

    bool public saleEnabled = true;
    mapping(address => bool) private whitelist;

    // Roles
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event SetParams(uint256 fee, address comco, address usdt);
    event ComCoBought(uint256 indexed comcoAmount, address indexed buyer);

    constructor(address _comco, address _usdt) {
        comco = _comco;
        usdt = _usdt;
    }

    /// @notice Exchanges Zoo for USDT
    /// @param _amount Quantity of ZOO to buy
    function buyWithUSDT(uint256 _amount) external {
        require(
            IComCo(comco).balanceOf(address(this)) >= _amount,
            "Insufficient ComCo Balance For Sale"
        );
        require(saleEnabled, "No Public Sale");
        require(
            _amount >= minLimit,
            "Under Minimum Buy Limit"
        );
        require(
            whitelist[_msgSender()] ||
            IComCo(comco).balanceOf(_msgSender()) + _amount <= maxLimit,
            "Above Max Limit"
        );
        require(
            IUSDT(usdt).allowance(_msgSender(), address(this)) >=
            ((fee * _amount) / (feeConstant * feeDecimal)),
            "USDT Not Approved"
        );
        IUSDT(usdt).transferFrom(_msgSender(), address(this), ((fee * _amount) / (feeConstant * feeDecimal)));

        IComCo(comco).transfer(_msgSender(), _amount);

        totalSale += _amount;

        emit ComCoBought(_amount, _msgSender());
    }

    function buyWithMatic(uint _amount) external payable {
        require(msg.value >= (_amount * feeMatic) / (10 ** IComCo(comco).decimals()), "Not enough value");
        require(saleEnabled, "No Public Sale");
        require(
            _amount >= minLimit,
            "Under Minimum Buy Limit"
        );
        require(
            whitelist[_msgSender()] ||
            IComCo(comco).balanceOf(_msgSender()) + _amount <= maxLimit,
            "Above Max Limit"
        );

        IComCo(comco).transfer(_msgSender(), _amount);

        totalSale += _amount;

        emit ComCoBought(_amount, _msgSender());
    }

    /// @notice Withdraw the accumulated ETH/USDT to address
    /// @param _to Where the funds should be sent
    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
        IUSDT(usdt).transfer(_to, IUSDT(usdt).balanceOf(address(this)));
    }

    function withdrawToken(address _to) external onlyOwner {
        IComCo(comco).transfer(_to, IComCo(comco).balanceOf(address(this)));
    }

    function withdrawToMarketing(
        address _from,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(IUSDT(usdt).allowance(_from, address(this)) >= _amount);
        IUSDT(usdt).transferFrom(_from, _to, _amount);
    }

    /// @notice Change minting fee
    function setParams(
        uint256 _fee,
    uint256 _feeMatic,
        address _comco,
        address _usdt
    ) external onlyOwner {
        fee = _fee;
        feeMatic = (_feeMatic / feeConstant) * 1 ether;
        comco = _comco;
        usdt = _usdt;
        emit SetParams(_fee, _comco, _usdt);
    }

    function setWhitelist(address _user, bool _value) public onlyOwner {
        whitelist[_user] = _value;
    }

    function checkMintable(address _user, uint256 _amount)
    public
    view
    returns (string memory)
    {
        if (whitelist[_user] == true && _amount >= minLimit) {
            return "Mintable";
        } else {
            if (
                _amount >= minLimit &&
                IUSDT(comco).balanceOf(_user) + _amount <= maxLimit
            ) {
                return "Mintable";
            } else {
                return "Not Mintable";
            }
        }
    }

    function getIsWhiteListed(address _user) public view returns (bool) {
        return whitelist[_user];
    }

    function setSaleEnabled(bool _value) public onlyOwner {
        saleEnabled = _value;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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