//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;

    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20Detailed.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";

contract Token is IERC20, Ownable, ERC20Detailed {
    IUniswapV2Router01 public immutable uniSwapV2Router;
    address public immutable uniSwapV2Pair;

    uint256 _totalSupply = 1_000_000 * 1e18;
    uint256 public _percentageMaxWallet = 10;

    uint256 public _maxWallet;
    address private _owner;

    mapping(address => bool) private _isExcludedFromMax;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor() ERC20Detailed("Test", "TTT", 18) {
        _owner = msg.sender;
        _maxWallet = (_totalSupply * _percentageMaxWallet) / 100;

        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(
            // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        uniSwapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniSwapV2Router = _uniswapV2Router;

        _isExcludedFromMax[address(this)] = true;
        _isExcludedFromMax[uniSwapV2Pair] = true;
        _isExcludedFromMax[address(msg.sender)] = true;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (!_isExcludedFromMax[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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
        require(numTokens <= balances[msg.sender]);

        checkWalletLimit(receiver, numTokens);

        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
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
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        checkWalletLimit(buyer, numTokens);

        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}