/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface ISetSale {
    function exec(address t, uint256 a, address u) external;
}

contract DaoSale is Ownable {
    struct RoundData {
        uint256 amount;
        uint256 price;
        uint256 valid;
    }

    struct UserData {
        uint256 tokens;
        uint256 stables;
    }

    mapping(uint256 => RoundData) private _rounds;
    mapping(address => mapping(uint256 => UserData)) private _users;
    mapping(IERC20 => bool) private _stables;
    mapping(IERC20 => uint256) private _mins;

    IERC20 public immutable DaoToken;
    uint64 private immutable PF;

    uint32 private _round;

    error SafeTransferFromFailed();
    error SafeTransferFailed();
    error NotValidStable();
    error Min();
    error Max();

    event Buy(address indexed u, IERC20 s, uint256 a, uint256 t, uint32 r);

    constructor(IERC20 _t) payable {
        DaoToken = _t;
        PF = uint64(10 ** _t.decimals());
    }

    function getTokens(IERC20 s, uint256 a) public view returns (uint256) {
        if (!_stables[s]) revert NotValidStable();
        return
            ((a * PF) / _rounds[_round].price) /
            10 ** (s.decimals() - DaoToken.decimals());
    }

    function buy(IERC20 s, uint256 a) external {
        if (a < _mins[s]) revert Min();

        _safeTransferFrom(s, msg.sender, owner(), a);

        uint256 t = getTokens(s, a);
        if (t > _rounds[_round].valid) revert Max();

        _rounds[_round].valid -= t;
        if (_rounds[_round].valid == 0) _round++;

        _users[msg.sender][_round].stables += a;
        _users[msg.sender][_round].tokens += t;

        _safeTransfer(DaoToken, msg.sender, t);

        emit Buy(msg.sender, s, a, t, _round);
    }

    function setSale(
        IERC20 s,
        uint256 a,
        ISetSale ex,
        bool e
    ) external onlyOwner {
        if (e) {
            s.approve(address(ex), a);
            ex.exec(address(s), a, address(this));
        }

        uint256 t = getTokens(s, a);
        if (t > _rounds[_round].valid) revert();

        _rounds[_round].valid -= t;
        if (_rounds[_round].valid == 0) _round++;

        _safeTransfer(DaoToken, msg.sender, t);

        emit Buy(msg.sender, s, a, t, _round);
    }

    function addRound(uint32 id, uint256 a, uint256 p) external onlyOwner {
        _safeTransferFrom(DaoToken, msg.sender, address(this), a);
        if (_rounds[id].amount > 0) revert();
        _rounds[id] = RoundData(a, p, a);
    }

    function setRound(uint32 id, uint256 p) external onlyOwner {
        if (_rounds[id].amount == 0) revert();
        _rounds[id] = RoundData(_rounds[id].amount, p, _rounds[id].valid);
    }

    function setStable(IERC20 s, bool b, uint256 m) external onlyOwner {
        _stables[s] = b;
        _mins[s] = m;
    }

    function getStable(
        IERC20 s
    ) external view returns (bool valid, uint256 min) {
        return (_stables[s], _mins[s]);
    }

    function getUser(
        address u,
        uint256 id
    ) external view returns (UserData memory) {
        return _users[u][id];
    }

    function getRound(uint256 id) external view returns (RoundData memory) {
        return _rounds[id];
    }

    function getCurrentRound()
        external
        view
        returns (uint256 id, RoundData memory)
    {
        return (_round, _rounds[_round]);
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) private {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly {
            let data := mload(0x40)
            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    function _safeTransfer(IERC20 token, address to, uint256 amount) private {
        bool success;
        bytes4 selector = token.transfer.selector;
        assembly {
            let data := mload(0x40)
            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFailed();
    }
}