// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./common/ERC20.sol";
import "./common/StoneData.sol";
import "./lib/SafeMath.sol";
import "./interfaces/IStoneRouter.sol";
import "./interfaces/IStoneFactory.sol";
import "./interfaces/IStone.sol";

contract IceStoneToken is ERC20 {
    using SafeMath for uint256;
    IStoneRouter public router;
    mapping(address => uint256) public tokenRewardPerSecond;
    mapping(address => mapping(uint256 => uint256)) public lastClaim;

    constructor(IStoneRouter stoneRouter, uint256 premintAmount) ERC20("IceStone", "ISC", 18, premintAmount) {
        router = stoneRouter;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        }
        _burn(from, amount);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == address(router), "mint-only-router");
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/SafeMath.sol";
import "../interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    uint256 private constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    using SafeMath for uint;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 amount) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        _mint(msg.sender, amount);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        require(balanceOf[from] >= value, "insufficient-funds");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != MAX_UINT) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct StoneData {
    uint256 unlockTime;
    uint256 value;
    uint256 createdTime;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y != 0, "ds-math-div-overflow");
        z = x / y;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStoneRouter {
    function factory() external view returns (address);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStoneFactory {
    function createStone(address token) external returns (address stone);
    function createOrGetStone(address token) external returns (address stone);
    function feeTo() external returns (address);
    function allStones(address) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../common/StoneData.sol";

interface IStone {
    function mint(address to, uint256 unlockTime) external returns (uint256 tokenId); 
    function burn(uint256 tokenId) external;
    function withdraw(address to) external returns (uint256);
    function token() external view returns (address);
    function reserve() external view returns (uint256);
    function flash(
        address borrower, 
        uint256 amount, 
        bytes calldata data
    ) external returns (bool);
    function getApproved(uint256) external view returns (address);
    function isApprovedForAll(address,address) external view returns (bool);
    function ownerOf(uint256) external view returns (address);
    function stonesInfo(uint256) external view returns (StoneData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}