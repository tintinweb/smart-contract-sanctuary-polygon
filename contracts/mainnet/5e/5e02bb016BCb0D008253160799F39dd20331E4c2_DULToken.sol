// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract DULToken is IERC20, Ownable {
    using SafeMath for uint256;

    string public name = "DUnilab";
    string public symbol = "DUL";
    uint8 public decimals = 6;
    uint256 totalSupply_ = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    // wallets for exclude fee
    address[] public excludes;
    uint256 transferPercentFee = 25; // 0.25%

    constructor() {
        totalSupply_ = 138000000 * 10 ** uint(decimals);
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(
        address tokenOwner
    ) public view override returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(
        address receiver,
        uint256 numTokens
    ) public override returns (bool) {
        uint256 transferFee = getTransferFee(msg.sender, numTokens);
        require(
            numTokens <=
                balances[msg.sender] + transferFee
        );
        balances[msg.sender] = balances[msg.sender].sub(
            numTokens.add(transferFee)
        );
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(
        address delegate,
        uint256 numTokens
    ) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(
        address owner,
        address delegate
    ) public view override returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(
            numTokens <= balances[owner] + getTransferFee(msg.sender, numTokens)
        );

        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens.add(getTransferFee(msg.sender, numTokens)));
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function getTransferFee(
        address sender,
        uint256 amount
    ) private view returns (uint256 feeAmount) {
        for (uint i = 0; i < excludes.length; i++) {
            if (excludes[i] == sender) {
                return 0;
            }
        }
        feeAmount = amount.mul(transferPercentFee).div(10000);
    }

    function setTransferFee(
        uint256 newFeePercent
    ) external onlyOwner returns (uint256) {
        transferPercentFee = newFeePercent;
        return (transferPercentFee);
    }

    function setAddExclude(address _address) external onlyOwner returns (bool) {
        for (uint i = 0; i < excludes.length; i++) {
            if (excludes[i] == _address) {
                return false;
            }
        }
        excludes.push(_address);
        return (true);
    }

    function setRemoveExclude(
        address _address
    ) external onlyOwner returns (bool) {
        for (uint i = 0; i < excludes.length; i++) {
            if (excludes[i] == _address) {
                delete excludes[i];
                return false;
            }
        }
        excludes.push(_address);
        return (true);
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